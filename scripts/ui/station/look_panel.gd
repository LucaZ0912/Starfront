extends StationServicePanel
## Package 28: Visage Clinics – the image studio. The character creator in its "look" mode: every part of the
## pilot's looks can be changed for a fixed price (after the standing); name and attributes stay as they are.

const CharacterCreatorScript = preload("res://scripts/ui/character_creator.gd")

var creator


func build() -> void:
	UI.clear(self)
	standing_line()
	add_child(UI.label("Your looks now:", 13, UI.TEXT_DIM))
	creator = CharacterCreatorScript.new()
	creator.setup("look", GameState.pilot.get("look", {}), {}, GameState.pilot_name, Commands.look_price())
	creator.done.connect(func(d: Dictionary): run({"type": "pilot_look", "look": d["look"]}))
	creator.cancelled.connect(func(): ui.show_concourse(true))
	add_child(creator)
