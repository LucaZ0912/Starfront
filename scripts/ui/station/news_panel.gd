extends StationServicePanel
## News archive (Lumen Newsnet, phase 0.5 package 16): every news item of the Cluster, the radio
## chatter of this system and the running bounty campaigns.

const FactionData = preload("res://data/factions.gd")
const KIND := {"alert": ["RAID", Color(1.0, 0.35, 0.3)], "radio": ["RADIO", Color(0.45, 0.85, 1.0)], "world": ["NEWS", Color(1.0, 0.8, 0.4)]}
static var filter := "all"


func build() -> void:
	UI.clear(self)
	var sid := GameState.current_system
	var camps: Dictionary = GameState.news.campaigns
	var active: Array = []
	for k in camps.keys():
		if GameState.news.bounty_mult(int(k)) > 1.0:
			active.append(int(k))
	section("BOUNTY CAMPAIGNS")
	if active.is_empty():
		add_child(UI.label("No campaign running – bounties are at their usual level.", 13, UI.TEXT_DIM))
	for k2 in active:
		var c: Dictionary = camps[k2]
		var row := UI.hbox(10)
		add_child(row)
		row.add_child(UI.icon(CrestArt.texture(String(c["faction"])), 22))
		row.add_child(UI.label("%s: +%d %% on pirate bounties in %s – %d min left" % [FactionData.short_of(String(c["faction"])), int(round((float(c["mult"]) - 1.0) * 100.0)), Universe.systems[k2]["name"], int(ceil((float(c["until"]) - GameState.play_time) / 60.0))], 13, UI.GOLD))
	var tabs := UI.hbox(4)
	add_child(tabs)
	for spec in [["all", "Everything"], ["alert", "Raids"], ["world", "Cluster news"], ["radio", "Radio (this system)"]]:
		var key: String = spec[0]
		var b := UI.button(spec[1], func(): _set_filter(key))
		b.toggle_mode = true
		b.button_pressed = filter == key
		tabs.add_child(b)
	section("NEWS FEED")
	var n := 0
	for it in GameState.news.items:
		var kind := String(it["kind"])
		if kind == "radio" and int(it["system"]) != sid:
			continue
		if filter != "all" and kind != filter:
			continue
		var row2 := UI.hbox(10)
		add_child(row2)
		var tl := UI.label(SaveGame.fmt_time(float(it["t"])), 12, UI.TEXT_DIM)
		tl.custom_minimum_size = Vector2(80, 0)
		row2.add_child(tl)
		var kl := UI.label(String(KIND[kind][0]), 12, KIND[kind][1])
		kl.custom_minimum_size = Vector2(56, 0)
		row2.add_child(kl)
		row2.add_child(UI.wrap_label(String(it["text"]), 13, Color(0.9, 0.92, 1.0), 980))
		n += 1
		if n >= 40:
			break
	if n == 0:
		add_child(UI.label("Nothing to report.", 13, UI.TEXT_DIM))


func _set_filter(k: String) -> void:
	filter = k
	build()
