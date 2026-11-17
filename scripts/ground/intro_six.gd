extends Node
## Package 56 – the intro, sequence 6, part 1 (Luz): Dan in the bar. After the flight training (or straight after the
## talk in sequence 4, the training skipped) Dan stands at the bar's window; his menu has a gold answer – "You wanted
## to talk to me." – which ends the prologue and starts the story mission "A Ticket to the Cluster": no ship, no
## licence, stuck in Beyond; a friend of his could get you to the Cluster, for a price; Dan's deal – work for him, about
## three years. Yes or no; then black, and the bar is busy again (no hands for hire). Said no: the regulars can be
## asked for work and say no; Dan's menu has "About your deal – I've thought it over" (gold). Said yes: a small ship
## waits in the hangar – part 2 (aboard it) comes next.

signal finished

const WINDOW := Vector2(20.6, 8.6)          # Dan at the bar's window (as in sequences 4 and 5)
const PATRONS := [["patron_a", Vector2(14.2, 12.6), 0], ["patron_b", Vector2(26.0, 12.6), 1], ["patron_c", Vector2(17.6, 16.4), 0]]

var main: Node
var phase := ""
var t := 0.0
var _decided := [false, false]               # [yes, no] when the talk began


func ground():
	return main.ground if main != null and main.ground != null and is_instance_valid(main.ground) else null


func _flags() -> Dictionary:
	return GameState.story.flags


func _busy() -> bool:
	return bool(_flags().get("dan_deal_yes", false)) or bool(_flags().get("dan_deal_no", false))


## The bar: quiet until Dan's deal is answered, then busy (no hands for hire); the regulars to ask only after a no.
func _mode() -> Dictionary:
	var people: Array = [{"who": "dan", "pos": WINDOW, "dir": 1, "talk": true}]
	if not _busy():
		return {"quiet": true, "keep_bartender": true, "lift_only": "commercial", "lift_label": "Bar", "levels": {"commercial": {"people": people}}}
	var ask: bool = bool(_flags().get("dan_deal_no", false)) and not bool(_flags().get("dan_deal_yes", false))
	for p in PATRONS:
		people.append({"who": p[0], "pos": p[1], "dir": p[2], "talk": ask})
	return {"no_crew": true, "lift_only": "commercial", "lift_label": "Bar",
		"lift_labels": {"hangar": "Hangar: the next part" if bool(_flags().get("dan_deal_yes", false)) else "Hangar"},
		"levels": {"commercial": {"people": people, "spawn": WINDOW + Vector2(-1.2, 2.2)}}}


## where: "bar" (on the deck already), "talk" (on the deck, Dan's menu at once) or "load" (a save opened in sequence 6).
func begin(where: String) -> void:
	var g = ground()
	if g == null:
		return
	if not g.story_talk.is_connected(_on_story_talk):
		g.story_talk.connect(_on_story_talk)
	GameState.story.set_flag("intro_stage", "six")
	g.story_mode = _mode()
	if where == "load" or g.level != "commercial":
		g.go_level("commercial", "story")
	g.input_enabled = true
	phase = "bar"
	if where == "talk":
		_talk_dan()


func _on_story_talk(who: String) -> void:
	if phase != "bar":
		return
	if who == "dan":
		_talk_dan()
	elif who.begins_with("patron_") and bool(_flags().get("dan_deal_no", false)) and not bool(_flags().get("dan_deal_yes", false)):
		GameState.story.show.emit("dialogue", {"id": who, "mission": ""})


func _talk_dan() -> void:
	_decided = [bool(_flags().get("dan_deal_yes", false)), bool(_flags().get("dan_deal_no", false))]
	GameState.story.show.emit("dialogue", {"id": "dan_help", "mission": ""})
	phase = "talking"
	t = 0.0


func _talk_done() -> bool:
	if main == null or main.story_ui == null:
		return true
	return main.story_ui.dialogue == null and main.story_ui._dlg_q.is_empty()


func _process(delta: float) -> void:
	t += delta
	var g = ground()
	if g == null:
		return
	match phase:
		"talking":
			if not _talk_done():
				return
			var now := [bool(_flags().get("dan_deal_yes", false)), bool(_flags().get("dan_deal_no", false))]
			if now != _decided:
				# Luz: the deal answered – black, and the bar is busy again
				g.input_enabled = false
				main.fade(Color(0, 0, 0, 1), 0.7)
				phase = "fade"
				t = 0.0
			else:
				phase = "bar"
		"fade":
			if t > 0.9 and t - delta <= 0.9:
				g.story_mode = _mode()
				g.go_level("commercial", "story")
				g.input_enabled = false
			if t > 1.3:
				main.fade(Color(0, 0, 0, 0), 0.9)
				g.input_enabled = true
				phase = "bar"
				if bool(_flags().get("dan_deal_yes", false)):
					GameState.log_msg("[Story] Sequence 6, part 2 (the small ship in the hangar) comes with the next part.", GameState.COL_WARN)
