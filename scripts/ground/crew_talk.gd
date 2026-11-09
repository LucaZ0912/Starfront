class_name CrewTalk
extends Control
## Package 49 (0.7.49.6): talking to one of the people looking for a post in the bar – just you and them. Ask what
## they do, how good they are, what they would cost, see their whole record, and sign them on.

signal closed
signal hired(index: int)

const CrewCard = preload("res://scripts/ui/crew_card.gd")
const CrewData = preload("res://data/crew.gd")
const CrewCore = preload("res://scripts/core/crew.gd")
const PilotArt = preload("res://scripts/core/pilot_art.gd")

var offer: Dictionary = {}
var index := -1
var done := false
var _you: Label
var _say: Label
var _extra: VBoxContainer
var _buttons: VBoxContainer


func setup(p_offer: Dictionary, p_index: int) -> void:
	offer = p_offer
	index = p_index
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var m: Dictionary = offer["m"]
	var q := String(m["quality"])
	var qc: Color = CrewData.QUALITY_COLORS.get(q, UI.TEXT_DIM)
	var p := UI.neon_panel(Color(qc, 0.8), Color(0.03, 0.035, 0.07, 0.97), 2)
	p.custom_minimum_size = Vector2(980, 0)
	center.add_child(p)
	var row := UI.hbox(18)
	p.add_child(row)
	# who: the portrait, the name, the trade
	var left := UI.vbox(4)
	left.custom_minimum_size = Vector2(210, 0)
	row.add_child(left)
	var por := UI.icon(PilotArt.portrait(m.get("look", {})), 200)
	left.add_child(por)
	left.add_child(UI.label(String(m["name"]), 18, Color(0.95, 0.96, 1.0)))
	left.add_child(UI.label("%s · %s" % [q, CrewData.QUALITY_NAMES.get(q, "")], 14, qc))
	left.add_child(UI.label(CrewData.role_name(String(m["role"])), 14, UI.NEON_CYAN))
	# the talk
	var right := UI.vbox(10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size = Vector2(700, 0)
	row.add_child(right)
	_you = UI.label("", 13, UI.TEXT_DIM)
	right.add_child(_you)
	_say = UI.wrap_label("", 16, Color(0.93, 0.95, 1.0), 700)
	_say.custom_minimum_size = Vector2(700, 90)
	right.add_child(_say)
	_extra = UI.vbox(4)
	right.add_child(_extra)
	_buttons = UI.vbox(5)
	right.add_child(_buttons)
	_reply("", _greeting())
	_menu()


func _ship() -> Variant:
	return GameState.active()


func _greeting() -> String:
	var m: Dictionary = offer["m"]
	var role := CrewData.role_name(String(m["role"]))
	match String(m["quality"]):
		"F":
			return "Oh – hi! Are you a captain? I'm %s. I just finished my training as a %s, and I'm ready. Really ready." % [_first(), role]
		"D":
			return "Evening, captain. %s, %s. I've done a few runs already – are you looking for hands?" % [_first(), role]
		"C":
			return "Captain. Name's %s. Word at the bar is you might need a %s – I've been around." % [_first(), role]
		"B":
			return "So you're the one with the ship. %s – %s, many years of it. I've flown with worse crews, I'm sure. What do you need?" % [_first(), role]
	return "Sit down, captain. I'm %s, and I don't come cheap – but you won't find a better %s on this station." % [_first(), role]


func _first() -> String:
	return String(offer["m"]["name"]).split(" ")[0]


func _reply(you: String, say: String) -> void:
	_you.text = ("You: " + you) if you != "" else ""
	_say.text = "„%s“" % say
	UI.clear(_extra)


func _menu() -> void:
	UI.clear(_buttons)
	if done:
		_buttons.add_child(UI.button("Welcome aboard. [Leave]", _close))
		return
	var m: Dictionary = offer["m"]
	_buttons.add_child(UI.button("What do you do on a ship?", _ask_role))
	_buttons.add_child(UI.button("How good are you?", _ask_skill))
	_buttons.add_child(UI.button("What would you cost?", _ask_price))
	_buttons.add_child(UI.button("Show me your record.", _ask_record))
	var price := int(offer["price"])
	var hr := UI.hbox(8)
	_buttons.add_child(hr)
	hr.add_child(UI.button("Sign on – crew quarters here (%s)" % GameData.fmt_credits(price), func(): _hire(false)))
	var f = _ship()
	if f != null:
		hr.add_child(UI.button("Sign on – onto the %s (%s)" % [f.ship_name, GameData.fmt_credits(price)], func(): _hire(true)))
	_buttons.add_child(UI.button("Goodbye. [Esc]", _close))


func _ask_role() -> void:
	var m: Dictionary = offer["m"]
	var r: Dictionary = CrewData.ROLES[String(m["role"])]
	var s := "I'm a %s. On your ship I'd see to %s – that's +%.1f %% for you, and it grows as I do. I learn from %s." % [
		r["name"], CrewData.bonus_label(String(m["role"]), String(m["bonus"])).to_lower(), float(m["value"]), r["learns"]]
	if String(m.get("role2", "")) != "":
		s += " And I've got a second trade: %s – %s +%.1f %%." % [CrewData.role_name(String(m["role2"])), CrewData.bonus_label(String(m["role2"]), String(m["bonus2"])).to_lower(), float(m["value2"])]
	_reply("What do you do on a ship?", s)


func _ask_skill() -> void:
	var m: Dictionary = offer["m"]
	var q := String(m["quality"])
	var s := "Right now? %s. That's %s work – %s." % [CrewCore.line(m), CrewData.QUALITY_NAMES.get(q, q).to_lower(),
		{"F": "everyone starts somewhere", "D": "solid, nothing fancy", "C": "I know my trade", "B": "few do it better", "A": "the best there is"}.get(q, "")]
	var nq := CrewCore.next_quality(q)
	if nq != "":
		s += " Give me time and %s, and I'll be %s." % [CrewData.ROLES[String(m["role"])]["learns"], CrewData.QUALITY_NAMES.get(nq, nq).to_lower()]
	var pk := String(m.get("perk", ""))
	if pk != "" and CrewData.PERKS.has(pk):
		s += " Oh – and one more thing: %s. %s" % [CrewData.PERKS[pk]["name"], CrewData.PERKS[pk]["text"]]
	_reply("How good are you?", s)


func _ask_price() -> void:
	var m: Dictionary = offer["m"]
	var s := "%s to sign on. After that %.2f %% of what the ship earns – sales, bounties, contracts." % [GameData.fmt_credits(int(offer["price"])), CrewCore.share_of(m) * 100.0]
	if GameState.credits < int(offer["price"]):
		s += " …Which, no offence, captain, looks like more than you've got right now."
	_reply("What would you cost?", s)


func _ask_record() -> void:
	_reply("Show me your record.", "Here – all of it. Read it twice if you like.")
	_extra.add_child(CrewCard.card(offer["m"], [], "", UI.TEXT_DIM, 700))


func _hire(onto_ship: bool) -> void:
	var cmd := {"type": "crew_hire", "index": index}
	var f = _ship()
	if onto_ship and f != null:
		cmd["ship"] = f.uid
	var err := Commands.execute(cmd)
	if err != "":
		_reply("You're hired.", "Not so fast, captain – %s" % err.to_lower() if err.length() > 1 else err)
		_menu()
		return
	done = true
	_reply("You're hired.", "Deal! I'll get my bag." if not onto_ship else "Deal! I'll go straight to the %s." % f.ship_name)
	_menu()
	hired.emit(index)


func _close() -> void:
	closed.emit()
	queue_free()
