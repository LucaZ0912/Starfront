extends CanvasLayer
## Package 31a: the ship is lost. Shows who made it into an escape pod and who did not, and offers to buy the ship
## back (10 % of hull, modules and drones; an Insurance Agent aboard: 5 % less; Cargo Insurance: the hold comes back
## too) – or to keep the beginner ship. The pilot is already back at the last station docked at.

signal closed

const COL := Color(1.0, 0.45, 0.35)
var offer := {}
var box: VBoxContainer


func _ready() -> void:
	add_to_group("kbd_menu")
	layer = 30
	visible = false
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center)
	var win := UI.neon_panel(COL, Color(0.07, 0.02, 0.03, 0.98))
	win.custom_minimum_size = Vector2(720, 0)
	center.add_child(win)
	box = UI.vbox(10)
	win.add_child(box)


func open(p_offer: Dictionary) -> void:
	offer = p_offer
	visible = true
	Audio.play("ui_error", "ship lost")
	_build()


func _build() -> void:
	UI.clear(box)
	if offer.is_empty():
		return
	box.add_child(UI.label("SHIP LOST", 26, COL))
	box.add_child(UI.wrap_label("The %s was destroyed (%s). Your own escape pod brought you back to %s." % [offer["name"], offer["where"], GameState.active().location_text() if GameState.active() != null else "the station"], 14, Color(0.95, 0.9, 0.9), 680))
	var alive: Array = offer.get("alive", [])
	var dead: Array = offer.get("dead", [])
	if not alive.is_empty() or not dead.is_empty():
		box.add_child(UI.label("THE CREW", 15, UI.GOLD))
		if not alive.is_empty():
			box.add_child(UI.wrap_label("In an escape pod at the wreck: %s. Fly there and pick them up before the signal fades – the pod shows in the overview of that system." % ", ".join(PackedStringArray(alive)), 13, UI.GOOD, 680))
		if not dead.is_empty():
			box.add_child(UI.wrap_label("Did not make it: %s." % ", ".join(PackedStringArray(dead)), 13, UI.BAD, 680))
	box.add_child(UI.label("AEGIS MUTUAL – REBUILD OFFER", 15, UI.GOLD))
	var lines: Array = ["Ship value with modules and drones: %s" % GameData.fmt_credits(int(offer["value"])),
		"Rebuild for 10 %% of it%s: %s" % [", 5 % off thanks to the Insurance Agent aboard" if bool(offer.get("agent", false)) else "", GameData.fmt_credits(int(offer["price"]))],
		("The cargo comes back too (Cargo Insurance aboard): %s" % GameData.fmt_credits(int(offer.get("cargo_value", 0)))) if bool(offer.get("insured", false)) else "The cargo is lost.",
		"The rebuilt ship has rookies on its required posts until your crew is back."]
	for l in lines:
		box.add_child(UI.label(l, 13, Color(0.9, 0.9, 0.95)))
	var can := GameState.credits >= int(offer["price"])
	box.add_child(UI.label("Your balance: %s" % GameData.fmt_credits(GameState.credits), 13, UI.GOLD if can else UI.BAD))
	var row := UI.hbox(12)
	box.add_child(row)
	var b1 := UI.button("Rebuild the %s – %s" % [offer["name"], GameData.fmt_credits(int(offer["price"]))], func(): _decide(true))
	b1.disabled = not can
	b1.custom_minimum_size = Vector2(0, 40)
	row.add_child(b1)
	var b2 := UI.button("Keep the beginner ship", func(): _decide(false))
	b2.custom_minimum_size = Vector2(0, 40)
	row.add_child(b2)


func _decide(accept: bool) -> void:
	var e := Commands.execute({"type": "loss_decide", "accept": accept})
	if e != "":
		_build()
		return
	visible = false
	closed.emit()


## Escape closes nothing here – a decision is needed.
func menu_tab(_step: int) -> void:
	pass
