extends Control
## The Colosseum's split screen, asked for at the counter (Luz, 25 Nov 2026): you are on your own and pick "Split
## screen" as the way to play. Here the second player gets their device and their pilot (the one this game already
## has, or a new one from the creator), and the two of you go in. It is a split screen for the Colosseum: once you
## walk out of it you are on your own again (Players.guest). No class_name: preload it.

signal finished(ok: bool)

const CharacterCreatorScript = preload("res://scripts/ui/character_creator.gd")
const COL2 := Color(1.0, 0.45, 0.85)

var dev := ["kbm", ""]              # the first player's device (as they play now), the second player's
var new_pilot := {}                 # the creator's data of a second pilot made just now ({}: the one in the game)
var creating := false
var _box: Control = null


func is_split_setup() -> bool:
	return true


func setup(_cfg: Dictionary) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("kbd_menu")
	dev[0] = ("pad:%d" % Pad.device) if (Pad.using_pad and Pad.device >= 0) else Players.KBM
	dev[1] = Players.next_device("", String(dev[0]), 1) if Players.device_list().size() > 1 else ""
	Players.changed.connect(_devices_changed)
	_build()


func _devices_changed() -> void:
	if not is_inside_tree() or creating:
		return
	if not Players.device_ok(String(dev[1])):
		dev[1] = Players.next_device("", String(dev[0]), 1) if Players.device_list().size() > 1 else ""
	_build()


## What stands in the way of going in ("" nothing).
func error() -> String:
	var e := Players.devices_error(String(dev[0]), String(dev[1]))
	if e == "" and new_pilot.is_empty() and not GameState.has_pilot2():
		e = "Player 2 needs a pilot."
	return e


## The second player's next device (step +1 or -1).
func step_device(step: int) -> void:
	dev[1] = Players.next_device(String(dev[1]), String(dev[0]), step)
	_build()


## In you go: the second pilot into the game (if new), the picture for two, and the way to play is "split".
func start() -> void:
	if error() != "":
		Audio.play("ui_error", "colosseum: split screen not ready")
		return
	if not new_pilot.is_empty():
		GameState.new_pilot2(new_pilot)
	Players.start_split(String(dev[0]), String(dev[1]))
	Players.guest = true
	var e: String = Commands.execute({"type": "col_play", "seat": 0, "play": "split"})
	if e != "":
		GameState.log_msg(e, GameState.COL_WARN)
		Players.stop_split()
		return
	GameState.log_msg("Split screen for the Colosseum: %s is with you (%s). Outside you are on your own again." % [String(GameState.pilot_of(1).get("name", "Player 2")), Players.device_name(String(dev[1]))], Color(0.6, 0.9, 1.0))
	Audio.play("ui_open", "colosseum: split screen")
	finished.emit(true)


func back() -> void:
	finished.emit(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_back", false, true) and not creating:
		get_viewport().set_input_as_handled()
		back()


func _build() -> void:
	if _box != null and is_instance_valid(_box):
		_box.queue_free()
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.02, 0.07, 0.96)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_box = bg
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.add_child(centre)
	var v := UI.vbox(12)
	v.custom_minimum_size = Vector2(620, 0)
	centre.add_child(v)
	if creating:
		var cc = CharacterCreatorScript.new()
		cc.setup("p2", {}, {}, "Wingmate")
		cc.cancelled.connect(func():
			creating = false
			_build())
		cc.done.connect(func(d: Dictionary):
			new_pilot = d
			creating = false
			_build())
		v.add_child(cc)
		return
	v.add_child(UI.label("THE COLOSSEUM", 40, Color(1.0, 0.5, 0.8)))
	v.add_child(UI.label("Split screen: two at one screen", 20, Color(1.0, 0.85, 0.4)))
	v.add_child(UI.wrap_label("For the Colosseum only: in here the two of you play side by side; once you walk out you are on your own again. The second pilot stays in this game for the next time.", 13, UI.TEXT_DIM, 600))
	v.add_child(UI.label("PLAYER 1   %s" % Players.device_name(String(dev[0])), 15, Color(0.35, 0.9, 1.0)))
	v.add_child(UI.label("PLAYER 2", 22, COL2))
	var row := UI.hbox(8)
	v.add_child(row)
	row.add_child(UI.label("Device", 14, COL2))
	row.add_child(UI.button("◀", func(): step_device(-1)))
	var nm := UI.label(Players.device_name(String(dev[1])), 16, Color(0.9, 0.94, 1.0) if Players.device_ok(String(dev[1])) else UI.BAD)
	nm.custom_minimum_size = Vector2(340, 0)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(nm)
	row.add_child(UI.button("▶", func(): step_device(1)))
	v.add_child(UI.label("PILOT", 14, COL2))
	var p2: Dictionary = new_pilot if not new_pilot.is_empty() else (GameState.pilot_of(1) if GameState.has_pilot2() else {})
	var fresh := not new_pilot.is_empty()
	var to_creator := func():
		creating = true
		_build()
	if p2.is_empty():
		v.add_child(UI.wrap_label("No second pilot in this game yet. Create one: they stay in this game.", 14, UI.TEXT_DIM, 600))
		v.add_child(UI.button("Create pilot", to_creator))
	else:
		var card := UI.hbox(14)
		v.add_child(card)
		var frame := UI.neon_panel(Color(COL2, 0.5), Color(0.02, 0.01, 0.05, 1.0), 1)
		card.add_child(frame)
		var por := TextureRect.new()
		por.custom_minimum_size = Vector2(150, 150)
		por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		por.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		por.texture = GameState.PilotArt.portrait(GameState.PilotArt.clean(p2.get("look", {})))
		frame.add_child(por)
		var info := UI.vbox(6)
		card.add_child(info)
		info.add_child(UI.label(String(p2.get("name", "Wingmate")), 22))
		info.add_child(UI.label("New pilot, level 1" if fresh else "Level %d" % int(p2.get("level", 1)), 14, UI.TEXT_DIM))
		info.add_child(UI.button("New pilot instead" if not fresh else "Change", to_creator, "A new pilot takes the place of this one." if not fresh else ""))
	var e := error()
	v.add_child(UI.label(e, 14, UI.BAD))
	var btns := UI.hbox(10)
	v.add_child(btns)
	var go := UI.button("Into the Colosseum for two", start)
	go.disabled = e != ""
	btns.add_child(go)
	btns.add_child(UI.button("Back", back))
