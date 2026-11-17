extends PanelContainer
## Package 28: creating the pilot. Left the portrait (48 x 48, shown large) with the figure on foot, in the
## middle the construction kit (every option with ‹ ›, a random look), right name, call sign and the five
## attributes (8 points to hand out, 3 to 8 each). Modes:
##   "new"  – a new game (package 56, Luz): Dan's medical scanner – the body on the scan bed with a scan line,
##            facial reconstruction, the looks grouped, vitals, identity "for the record", the physical and
##            psychological assessment, the galaxy seed small; "Complete scan" starts the game
##   "look" – the image studio at a station: only the looks, with the price; the attributes stay as they are
## Works with the mouse and the keyboard (W/A/S/D, Enter, Escape).

signal done(data: Dictionary)          # {"name", "callsign", "look", "attrs", "seed"}
signal cancelled

const PilotArt = preload("res://scripts/core/pilot_art.gd")
const PilotData = preload("res://data/pilot.gd")
const COL := Color(0.35, 0.95, 1.0)
const ChibiArtS = preload("res://scripts/ground/chibi_art.gd")
## Package 56: the looks in the scanner's groups
const GROUPS := [["PHYSIQUE", ["body", "skin"]], ["FACE", ["eyes", "brows", "scar", "freckles", "implant", "tattoo"]],
	["HAIR", ["hair", "hair_color", "beard"]], ["CLOTHING", ["outfit", "color1", "color2", "headgear"]]]
const MAKEUP_GROUP := ["MAKE-UP", ["lipstick", "blush", "eye_makeup"]]         # in the scanner's right column

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
var _bed: Control                       # package 56: the scan bed (draws the figure itself)
var _bars := {}                         # attribute -> its bar


func setup(p_mode: String, p_look: Dictionary = {}, p_attrs: Dictionary = {}, p_name: String = "Lefty", p_price: int = 0) -> void:
	mode = p_mode
	look = PilotArt.clean(p_look) if not p_look.is_empty() else PilotArt.random_look()
	attrs = p_attrs.duplicate() if not p_attrs.is_empty() else PilotData.base_attrs()
	pilot_name = p_name
	price = p_price
	seed_text = str(randi() % 1000000)


func _ready() -> void:
	add_to_group("kbd_menu")                      # package 80: keys and controller
	if mode == "new":
		_build_scan()
		_refresh()
		return
	if mode == "look":
		_build_restyle()                          # package 56 (Luz): Visage Clinics in the scanner's style
		_refresh()
		return
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
	_sprite.custom_minimum_size = Vector2(54, 120)          # 0.8.56: the figure on foot as it is today (ChibiArt)
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.add_child(_sprite)
	r.add_child(UI.wrap_label("How you look on foot.", 11, UI.TEXT_DIM, 160))
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
	if _sprite != null:
		_sprite.texture = ChibiArtS.frame(look, 0, 0)
	if _bed != null:
		_bed.set("look", look)
		_bed.queue_redraw()
	for id in _bars:
		_bars[id].set("value", int(attrs.get(id, PilotData.START)))
		_bars[id].queue_redraw()
	for o in PilotArt.OPTIONS:
		var names: Array = o[2]
		_values[o[0]].text = String(names[int(look.get(o[0], 0)) % names.size()])
	if mode in ["new", "debug"]:
		for id in _attr_labels:
			_attr_labels[id].text = str(int(attrs[id]))
		var left := PilotData.FREE - PilotData.spent(attrs)
		_points.text = ("%d point%s open" if mode == "new" else "%d point%s left to hand out (3 to 8 each)") % [left, "" if left == 1 else "s"]
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



# ---------------------------------------------------------------- package 56: the medical scanner (a new game)

func _build_scan() -> void:
	var vs := get_viewport().get_visible_rect().size
	custom_minimum_size = Vector2(minf(1560.0, vs.x - 30.0), minf(860.0, vs.y - 30.0))
	var sb := UI.panel_style(Color(0.02, 0.04, 0.06, 0.99), Color(COL, 0.6))
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(0)
	sb.set_content_margin_all(18)
	add_theme_stylebox_override("panel", sb)
	var grid := ScanGrid.new()
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grid)
	var v := UI.vbox(8)
	add_child(v)
	var head := UI.hbox(14)
	v.add_child(head)
	head.add_child(UI.label("MEDICAL SCAN", 26, COL))
	head.add_child(UI.label("·  INFIRMARY, DAN'S DUSTY DUTY STORE  ·  PATIENT: UNKNOWN", 15, UI.TEXT_DIM))
	head.add_child(UI.spacer())
	head.add_child(UI.label("● SCAN IN PROGRESS", 15, Color(1.0, 0.4, 0.35)))
	var line := ColorRect.new()
	line.color = Color(COL, 0.4)
	line.custom_minimum_size = Vector2(0, 1)
	v.add_child(line)
	var cols := UI.hbox(26)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(cols)
	# left: facial reconstruction and the looks
	var left := UI.vbox(2)
	left.custom_minimum_size = Vector2(360, 0)
	cols.add_child(left)
	var fr := PanelContainer.new()
	fr.add_theme_stylebox_override("panel", _flat(Color(0.02, 0.06, 0.08), Color(COL, 0.7)))
	fr.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left.add_child(fr)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(190, 190)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fr.add_child(_portrait)
	var fl := UI.hbox(8)
	left.add_child(fl)
	fl.add_child(UI.label("FACIAL RECONSTRUCTION", 13, COL))
	fl.add_child(UI.spacer())
	fl.add_child(UI.button("Random", func():
		look = PilotArt.random_look()
		_refresh()))
	for g in GROUPS:
		left.add_child(UI.label(String(g[0]), 12, Color(COL, 0.8)))
		for key in g[1]:
			_kit_row(left, String(key))
	# middle: the scan bed
	_bed = ScanBed.new()
	_bed.custom_minimum_size = Vector2(340, 560)
	cols.add_child(_bed)
	# right: vitals, identity, the assessment, the button, the seed
	var right := UI.vbox(6)
	right.custom_minimum_size = Vector2(500, 0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	var vit := Vitals.new()
	vit.custom_minimum_size = Vector2(500, 110)
	right.add_child(vit)
	right.add_child(UI.label("IDENTITY  –  FOR THE RECORD", 13, COL))
	_name_edit = LineEdit.new()
	_name_edit.text = pilot_name
	_name_edit.max_length = 24
	_name_edit.placeholder_text = "Name"
	_name_edit.text_changed.connect(func(tx): pilot_name = tx)
	right.add_child(_name_edit)
	_call_edit = LineEdit.new()
	_call_edit.max_length = 16
	_call_edit.placeholder_text = "Call sign (optional)"
	_call_edit.text_changed.connect(func(tx): callsign = tx)
	right.add_child(_call_edit)
	right.add_child(UI.label("Pilot licence 12,598 HE  –  NO RECORD FOUND", 13, Color(1.0, 0.75, 0.3)))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	right.add_child(gap)
	var ah := UI.hbox(8)
	right.add_child(ah)
	ah.add_child(UI.label("PHYSICAL & PSYCHOLOGICAL ASSESSMENT", 13, COL))
	ah.add_child(UI.spacer())
	_points = UI.label("", 13, UI.GOLD)
	ah.add_child(_points)
	for at in PilotData.ATTRS:
		var id: String = at[0]
		var row := UI.hbox(8)
		right.add_child(row)
		var nl := UI.label(String(at[1]), 14, UI.TEXT_DIM)
		nl.custom_minimum_size = Vector2(110, 0)
		nl.tooltip_text = String(at[2])
		row.add_child(nl)
		row.add_child(UI.button("−", func(): _attr(id, -1)))
		var bar := AttrBar.new()
		bar.custom_minimum_size = Vector2(260, 22)
		bar.tooltip_text = String(at[2])
		bar.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(bar)
		_bars[id] = bar
		row.add_child(UI.button("+", func(): _attr(id, 1)))
		var vl := UI.label("", 15, UI.GOOD)
		vl.custom_minimum_size = Vector2(26, 0)
		row.add_child(vl)
		_attr_labels[id] = vl
	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 8)
	right.add_child(gap2)
	right.add_child(UI.label(String(MAKEUP_GROUP[0]), 12, Color(COL, 0.8)))
	for key in MAKEUP_GROUP[1]:
		_kit_row(right, String(key))
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(fill)
	_err = UI.label("", 13, UI.BAD)
	right.add_child(_err)
	_go = UI.menu_button("COMPLETE SCAN  ▸", _finish, COL, 500)
	right.add_child(_go)
	var sr := UI.hbox(6)
	right.add_child(sr)
	sr.add_child(UI.label("galaxy seed", 11, UI.TEXT_DIM))
	_seed_edit = LineEdit.new()
	_seed_edit.text = seed_text
	_seed_edit.custom_minimum_size = Vector2(110, 0)
	_seed_edit.add_theme_font_size_override("font_size", 11)
	_seed_edit.text_changed.connect(func(tx): seed_text = tx)
	sr.add_child(_seed_edit)
	sr.add_child(UI.button("Random", func():
		seed_text = str(randi() % 1000000)
		_seed_edit.text = seed_text))
	sr.add_child(UI.spacer())
	sr.add_child(UI.button("Back", func(): cancelled.emit()))


func _flat(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_content_margin_all(4)
	return sb


## One option of the looks: name, ‹, its value, ›.
func _kit_row(parent: Control, key: String) -> void:
	for o in PilotArt.OPTIONS:
		if o[0] != key:
			continue
		var row := UI.hbox(4)
		parent.add_child(row)
		var l := UI.label(String(o[1]), 12, UI.TEXT_DIM)
		l.custom_minimum_size = Vector2(108, 0)
		row.add_child(l)
		row.add_child(UI.button("‹", func(): _step(key, -1)))
		var val := UI.label("", 12)
		val.custom_minimum_size = Vector2(150, 0)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(val)
		_values[key] = val
		row.add_child(UI.button("›", func(): _step(key, 1)))


## A faint grid behind the scanner.
class ScanGrid extends Control:
	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		for x in range(0, int(size.x), 40):
			draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.35, 0.95, 1.0, 0.035), 1.0)
		for y in range(0, int(size.y), 40):
			draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.35, 0.95, 1.0, 0.035), 1.0)


## The scan bed: the figure as it will walk the decks, a scan line passing over it, the body parts ticked off, the
## progress below.
class ScanBed extends Control:
	var look: Dictionary = {}
	var t := 0.0
	var CY := Color(0.35, 0.95, 1.0)
	var projection := false                     # Visage: a hologram of the new look instead of the scan

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var bed := Rect2(Vector2.ZERO, size - Vector2(0, 40))
		draw_rect(bed, Color(0.03, 0.08, 0.11))
		draw_rect(bed, Color(CY, 0.6), false, 2.0)
		for i in int(bed.size.y / 50.0):
			draw_line(Vector2(10, 30 + i * 50), Vector2(bed.size.x - 10, 30 + i * 50), Color(CY, 0.07), 1.0)
		if look.is_empty():
			return
		var tex: Texture2D = load("res://scripts/ground/chibi_art.gd").frame(look, 0, 0)
		var sc := floorf(minf((bed.size.y - 50.0) / 40.0, (bed.size.x - 120.0) / 18.0))
		var fs := Vector2(18, 40) * sc
		var fp := Vector2(bed.size.x * 0.5 - fs.x * 0.5 - 20.0, maxf(24.0, (bed.size.y - fs.y) * 0.5))
		draw_texture_rect(tex, Rect2(fp, fs), false)
		# the scan line sweeps down and up
		var k := 0.5 - 0.5 * cos(t * 0.9)
		var sy := fp.y + fs.y * k
		draw_rect(Rect2(0, sy - 26, bed.size.x, 26), Color(CY, 0.07))
		draw_line(Vector2(-6, sy), Vector2(bed.size.x + 6, sy), Color(CY, 0.9), 3.0)
		var font := get_theme_default_font()
		if projection:
			# the projector's rings at the feet and light rising, scan lines drifting through the figure
			for i in 3:
				var rr := fs.x * (0.55 + i * 0.18)
				draw_arc(Vector2(fp.x + fs.x * 0.5, fp.y + fs.y + 6.0), rr, PI, TAU, 32, Color(CY, 0.5 - i * 0.12), 2.0)
			for i in 14:
				var yy := fp.y + fposmod(i * 37.0 + t * 30.0, fs.y)
				draw_line(Vector2(fp.x - 10, yy), Vector2(fp.x + fs.x + 10, yy), Color(CY, 0.08), 2.0)
			draw_string(font, Vector2(0, size.y - 22), "HOLO PROJECTION  ·  YOUR NEW LOOK", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, CY)
			return
		var prog := clampf(t / 9.0, 0.0, 1.0)
		for m in [[0.12, "CRANIUM"], [0.42, "THORAX"], [0.78, "LIMBS"]]:
			var yy: float = fp.y + fs.y * float(m[0])
			draw_line(Vector2(fp.x + fs.x + 6, yy), Vector2(bed.size.x - 96, yy), Color(CY, 0.4), 1.0)
			var ok := prog > float(m[0])
			draw_string(font, Vector2(bed.size.x - 92, yy + 4), String(m[1]) + (" ✓" if ok else " …"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.7, 0.8))
		draw_string(font, Vector2(0, size.y - 22), "FULL BODY SCAN  ·  %d %%" % int(prog * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, CY)
		draw_rect(Rect2(0, size.y - 12, size.x, 6), Color(CY, 0.15))
		draw_rect(Rect2(0, size.y - 12, size.x * prog, 6), CY)


## Vitals: a heartbeat line and the numbers – only for the mood.
class Vitals extends Control:
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0.02, 0.06, 0.08))
		draw_rect(r, Color(0.35, 0.95, 1.0, 0.5), false, 1.0)
		var w := size.x - 170.0
		var prev := Vector2(10, size.y * 0.6)
		for i in int(w / 3.0):
			var ph := fposmod(i - t * 40.0, 70.0)
			var yv := size.y * 0.6 - (34.0 if ph < 1.0 else (12.0 if ph < 2.0 else (-10.0 if ph < 3.0 else 0.0)))
			var p := Vector2(10 + i * 3.0, yv)
			draw_line(prev, p, Color(0.4, 1.0, 0.6), 2.0)
			prev = p
		var font := get_theme_default_font()
		draw_string(font, Vector2(size.x - 150, 30), "HR  %d bpm" % (46 + int(t * 1.5) % 6), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.4, 1.0, 0.6))
		draw_string(font, Vector2(size.x - 150, 56), "O₂  %d %%" % mini(97, 68 + int(t * 1.2)), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.75, 0.3))
		draw_string(font, Vector2(size.x - 150, 82), "TEMP 35.%d °C" % mini(9, 1 + int(t * 0.3)), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 0.7, 0.8))


## An attribute as eight cells (3 to 8 filled).
class AttrBar extends Control:
	var value := 3

	func _draw() -> void:
		var n := 8
		var cw := (size.x - (n - 1) * 5.0) / n
		for i in n:
			draw_rect(Rect2(i * (cw + 5.0), 2, cw, size.y - 4), Color(0.35, 0.95, 1.0) if i < value else Color(0.35, 0.95, 1.0, 0.12))



# ---------------------------------------------------------------- package 56: Visage Clinics – restyling

func _build_restyle() -> void:
	var pink := Color(1.0, 0.55, 0.85)
	custom_minimum_size = Vector2(1080, 0)
	var sb := UI.panel_style(Color(0.04, 0.02, 0.06, 0.99), Color(pink, 0.6))
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(0)
	sb.set_content_margin_all(16)
	add_theme_stylebox_override("panel", sb)
	var v := UI.vbox(8)
	add_child(v)
	var head := UI.hbox(14)
	v.add_child(head)
	head.add_child(UI.label("VISAGE CLINICS", 24, pink))
	head.add_child(UI.label("·  RESTYLE  ·  what is under the skin stays yours", 14, UI.TEXT_DIM))
	head.add_child(UI.spacer())
	head.add_child(UI.label(GameData.fmt_credits(price), 18, UI.GOLD))
	var line := ColorRect.new()
	line.color = Color(pink, 0.4)
	line.custom_minimum_size = Vector2(0, 1)
	v.add_child(line)
	var cols := UI.hbox(22)
	v.add_child(cols)
	var left := UI.vbox(2)
	left.custom_minimum_size = Vector2(340, 0)
	cols.add_child(left)
	var fr := PanelContainer.new()
	fr.add_theme_stylebox_override("panel", _flat(Color(0.06, 0.03, 0.08), Color(pink, 0.7)))
	fr.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left.add_child(fr)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(170, 170)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fr.add_child(_portrait)
	var fl := UI.hbox(8)
	left.add_child(fl)
	fl.add_child(UI.label("YOUR NEW FACE", 13, pink))
	fl.add_child(UI.spacer())
	fl.add_child(UI.button("Random", func():
		look = PilotArt.random_look()
		_refresh()))
	for g in [GROUPS[1], GROUPS[2]]:
		left.add_child(UI.label(String(g[0]), 12, Color(pink, 0.8)))
		for key in g[1]:
			_kit_row(left, String(key))
	_bed = ScanBed.new()
	_bed.CY = pink
	_bed.projection = true
	_bed.custom_minimum_size = Vector2(280, 480)
	cols.add_child(_bed)
	var right := UI.vbox(2)
	right.custom_minimum_size = Vector2(340, 0)
	cols.add_child(right)
	for g in [GROUPS[0], GROUPS[3], MAKEUP_GROUP]:
		right.add_child(UI.label(String(g[0]), 12, Color(pink, 0.8)))
		for key in g[1]:
			_kit_row(right, String(key))
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(fill)
	_err = UI.label("", 13, UI.BAD)
	right.add_child(_err)
	_go = UI.menu_button("RESTYLE  ·  %s  ▸" % GameData.fmt_credits(price), _finish, pink, 340)
	right.add_child(_go)
	right.add_child(UI.button("Back", func(): cancelled.emit()))
