extends PanelContainer
## Package 28: creating the pilot. Left the portrait (48 x 48, shown large) with the top-down figure, in the
## middle the construction kit (every option with ‹ ›, a random look), right name, call sign and the five
## attributes (8 points to hand out, 3 to 8 each). Two modes:
##   "new"  – a new game: everything, plus the galaxy seed; "Launch" starts the game
##   "look" – the image studio at a station: only the looks, with the price; the attributes stay as they are
## Works with the mouse and the keyboard (W/A/S/D, Enter, Escape).

signal done(data: Dictionary)          # {"name", "callsign", "look", "attrs", "seed"}
signal cancelled

const PilotArt = preload("res://scripts/core/pilot_art.gd")
const PilotData = preload("res://data/pilot.gd")
const COL := Color(0.35, 0.95, 1.0)

var mode := "new"
var look: Dictionary = {}
var attrs: Dictionary = {}
var price := 0
var pilot_name := "Lefty"
var callsign := ""
var seed_text := ""

var _portrait: TextureRect
var _sprite: TextureRect
var _values := {}                       # option key -> Label
var _attr_labels := {}
var _points: Label
var _go: Button
var _err: Label
var _name_edit: LineEdit
var _call_edit: LineEdit
var _seed_edit: LineEdit


func setup(p_mode: String, p_look: Dictionary = {}, p_attrs: Dictionary = {}, p_name: String = "Lefty", p_price: int = 0) -> void:
	mode = p_mode
	look = PilotArt.clean(p_look) if not p_look.is_empty() else PilotArt.random_look()
	attrs = p_attrs.duplicate() if not p_attrs.is_empty() else PilotData.base_attrs()
	pilot_name = p_name
	price = p_price
	seed_text = str(randi() % 1000000)


func _ready() -> void:
	var sb := UI.panel_style(UI.NEON_BG, COL)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(16)
	add_theme_stylebox_override("panel", sb)
	var v := UI.vbox(10)
	add_child(v)
	var head := UI.hbox(10)
	v.add_child(head)
	head.add_child(UI.label({"new": "NEW PILOT", "look": "IMAGE STUDIO", "debug": "PILOT (DEBUG)"}.get(mode, "PILOT"), 22, COL))
	head.add_child(UI.spacer())
	head.add_child(UI.button("Back", func(): cancelled.emit()))
	var cols := UI.hbox(18)
	v.add_child(cols)
	_build_looks_preview(cols)
	_build_kit(cols)
	if mode in ["new", "debug"]:
		_build_person(cols)
	_err = UI.label("", 13, UI.BAD)
	v.add_child(_err)
	var go_text: String = {"new": "Launch", "debug": "Apply"}.get(mode, "Change looks (%s)" % GameData.fmt_credits(price))
	_go = UI.menu_button(go_text, _finish, UI.GOOD, 420)
	v.add_child(_go)
	_refresh()


func _build_looks_preview(parent: Control) -> void:
	var box := UI.vbox(8)
	parent.add_child(box)
	var frame := UI.neon_panel(Color(COL, 0.5), Color(0.02, 0.01, 0.05, 1.0), 1)
	box.add_child(frame)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(240, 240)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_child(_portrait)
	var r := UI.hbox(10)
	box.add_child(r)
	_sprite = TextureRect.new()
	_sprite.custom_minimum_size = Vector2(64, 64)
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.add_child(_sprite)
	r.add_child(UI.wrap_label("From above – how you will look on foot later.", 11, UI.TEXT_DIM, 160))
	box.add_child(UI.button("Random look", func():
		look = PilotArt.random_look()
		_refresh()))


func _build_kit(parent: Control) -> void:
	var box := UI.vbox(3)
	box.custom_minimum_size = Vector2(330, 0)
	parent.add_child(box)
	box.add_child(UI.label("LOOKS", 14, COL))
	for o in PilotArt.OPTIONS:
		var key: String = o[0]
		var row := UI.hbox(6)
		box.add_child(row)
		var l := UI.label(String(o[1]), 13, UI.TEXT_DIM)
		l.custom_minimum_size = Vector2(110, 0)
		row.add_child(l)
		row.add_child(UI.button("‹", func(): _step(key, -1)))
		var val := UI.label("", 13)
		val.custom_minimum_size = Vector2(150, 0)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(val)
		_values[key] = val
		row.add_child(UI.button("›", func(): _step(key, 1)))


func _build_person(parent: Control) -> void:
	var box := UI.vbox(6)
	box.custom_minimum_size = Vector2(360, 0)
	parent.add_child(box)
	box.add_child(UI.label("NAME", 14, COL))
	_name_edit = LineEdit.new()
	_name_edit.text = pilot_name
	_name_edit.max_length = 24
	_name_edit.placeholder_text = "Pilot name"
	_name_edit.text_changed.connect(func(t): pilot_name = t)
	box.add_child(_name_edit)
	_call_edit = LineEdit.new()
	_call_edit.max_length = 16
	_call_edit.placeholder_text = "Call sign (optional)"
	_call_edit.text_changed.connect(func(t): callsign = t)
	box.add_child(_call_edit)
	box.add_child(UI.label("ATTRIBUTES", 14, COL))
	_points = UI.label("", 13, UI.GOLD)
	box.add_child(_points)
	for at in PilotData.ATTRS:
		var id: String = at[0]
		var row := UI.hbox(6)
		box.add_child(row)
		var nl := UI.label(String(at[1]), 14)
		nl.custom_minimum_size = Vector2(110, 0)
		nl.tooltip_text = String(at[2])
		row.add_child(nl)
		row.add_child(UI.button("−", func(): _attr(id, -1)))
		var vl := UI.label("", 15, UI.GOOD)
		vl.custom_minimum_size = Vector2(30, 0)
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(vl)
		_attr_labels[id] = vl
		row.add_child(UI.button("+", func(): _attr(id, 1)))
		box.add_child(UI.wrap_label(String(at[2]), 11, UI.TEXT_DIM, 340))
	if mode != "new":
		return
	box.add_child(UI.label("GALAXY SEED – the same seed, the same galaxy", 12, COL))
	var sr := UI.hbox(6)
	box.add_child(sr)
	_seed_edit = LineEdit.new()
	_seed_edit.text = seed_text
	_seed_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_seed_edit.text_changed.connect(func(t): seed_text = t)
	sr.add_child(_seed_edit)
	sr.add_child(UI.button("Random", func():
		seed_text = str(randi() % 1000000)
		_seed_edit.text = seed_text))
	box.add_child(UI.wrap_label("You start in the core system with a Dragonfly scout, 30,000 credits and a few spare modules in station storage.", 11, UI.TEXT_DIM, 340))


func _step(key: String, d: int) -> void:
	for o in PilotArt.OPTIONS:
		if o[0] == key:
			look[key] = posmod(int(look.get(key, 0)) + d, (o[2] as Array).size())
	_refresh()


func _attr(id: String, d: int) -> void:
	var v := int(attrs.get(id, PilotData.START)) + d
	if v < PilotData.START or v > PilotData.MAX:
		return
	if d > 0 and PilotData.spent(attrs) >= PilotData.FREE:
		return
	attrs[id] = v
	_refresh()


func _refresh() -> void:
	if _portrait == null:
		return
	_portrait.texture = PilotArt.portrait(look)
	_sprite.texture = PilotArt.sprite(look)
	for o in PilotArt.OPTIONS:
		var names: Array = o[2]
		_values[o[0]].text = String(names[int(look.get(o[0], 0)) % names.size()])
	if mode in ["new", "debug"]:
		for id in _attr_labels:
			_attr_labels[id].text = str(int(attrs[id]))
		var left := PilotData.FREE - PilotData.spent(attrs)
		_points.text = "%d point%s left to hand out (3 to 8 each)" % [left, "" if left == 1 else "s"]
		_points.add_theme_color_override("font_color", UI.GOLD if left > 0 else UI.GOOD)
	_err.text = ""


## What the creator hands back; "" error = ready.
func result() -> Dictionary:
	return {"name": pilot_name.strip_edges(), "callsign": callsign.strip_edges(), "look": look.duplicate(), "attrs": attrs.duplicate(),
		"seed": absi(seed_text.to_int())}


func error() -> String:
	if mode == "look":
		return ""
	if mode == "debug":
		return "" if pilot_name.strip_edges() != "" else "Your pilot needs a name."
	if pilot_name.strip_edges() == "":
		return "Your pilot needs a name."
	return PilotData.attrs_error(attrs)


func _finish() -> void:
	var e := error()
	if e != "":
		_err.text = e
		Audio.play("ui_error", "creator")
		return
	done.emit(result())
