class_name SuitHud
extends Control
## 0.7.51.3: the suit on foot – bars for health, shield, energy and oxygen (oxygen only where the air cannot be
## breathed), ammunition, the hazards outside and how much of each gets through, and the belt along the bottom with
## its number keys and stacks. Warnings blink when energy or air run low.

const GearData = preload("res://data/gear.gd")
const GearIcons = preload("res://scripts/ui/gear_icons.gd")
var env: Dictionary = {}                # {} = indoors / a safe place
var indoors := false
var exposure := 0.0
var _t := 0.0
var bottom_y := 0.0                      # package 52: where the bars end (the cover line goes under them)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _bar(p: Vector2, w: float, label: String, v: float, mx: float, col: Color, txt: String) -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(p, Vector2(w + 96, 20)), Color(0.0, 0.0, 0.03, 0.55))
	draw_string(font, p + Vector2(6, 15), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.82, 0.85))
	var bx := p + Vector2(70, 5)
	draw_rect(Rect2(bx, Vector2(w - 50, 10)), Color(0.1, 0.1, 0.12))
	var k := clampf(v / maxf(mx, 0.001), 0.0, 1.0)
	var low := k < 0.25
	var c := col if not (low and fposmod(_t * 3.0, 1.0) < 0.5) else col.lightened(0.5)
	draw_rect(Rect2(bx, Vector2((w - 50) * k, 10)), c)
	draw_string(font, p + Vector2(w + 26, 15), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.5, 0.4) if low else Color(0.9, 0.9, 0.9))


func _draw() -> void:
	var g = GameState.gear
	var t: Dictionary = g.totals()
	var font := ThemeDB.fallback_font
	var x := 14.0
	var y := 74.0
	var w := 200.0
	_bar(Vector2(x, y), w, "Health", g.health, GearData.HEALTH, Color(1.0, 0.35, 0.35), "%d" % int(g.health))
	y += 22
	_bar(Vector2(x, y), w, "Shield", g.shield, float(t["shield"]), Color(0.35, 0.85, 1.0), "%d" % int(g.shield))
	y += 22
	_bar(Vector2(x, y), w, "Armour", g.armor, float(t["armor"]), Color(1.0, 0.8, 0.3), "%d" % int(g.armor))       # package 52
	y += 22
	_bar(Vector2(x, y), w, "Energy", g.energy, float(t["energy"]), Color(1.0, 0.85, 0.3), "%d" % int(g.energy))
	y += 22
	var outside := not env.is_empty() and not indoors
	if outside and not bool(env.get("breathable", true)):
		_bar(Vector2(x, y), w, "Oxygen", g.oxygen, float(t["oxygen"]), Color(0.45, 0.7, 1.0), "%d min" % int(ceil(g.oxygen)))
		y += 22
	_bar(Vector2(x, y), w, "Ammo", float(g.ammo), float(t["ammo"]), Color(0.75, 0.75, 0.7), "%d" % g.ammo)
	y += 24
	if outside:
		var parts: Array = []
		for h in GearData.HAZARDS:
			if float(env.get(h, 0.0)) > 0.0:
				var through := float(env[h]) * (1.0 - (float(t["env"][h]) if g.energy > 0.0 else 0.0))
				parts.append("%s %d%%%s" % [GearData.HAZARD_NAMES[h], int(float(env[h]) * 100.0), (" – %d%% gets through" % int(through * 100.0)) if through > 0.01 else " – kept out"])
		if bool(env.get("breathable", true)) and parts.is_empty():
			parts.append("The air is good to breathe")
		elif not bool(env.get("breathable", true)):
			parts.append("No air to breathe – on the tank")
		var hc := Color(1.0, 0.55, 0.4) if exposure > 0.01 else Color(0.6, 0.95, 0.65)
		for line in parts:
			draw_rect(Rect2(Vector2(x, y), Vector2(font.get_string_size(String(line), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 14, 18)), Color(0.0, 0.0, 0.03, 0.55))
			draw_string(font, Vector2(x + 7, y + 13), String(line), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, hc)
			y += 19
		if g.energy <= 0.0:
			draw_string(font, Vector2(x + 7, y + 14), "SUIT ENERGY EMPTY – life support off", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.3, 0.3) if fposmod(_t * 2.0, 1.0) < 0.6 else Color(1.0, 0.7, 0.4))
		if g.energy <= 0.0:
			y += 20
	elif indoors and not env.is_empty():
		draw_string(font, Vector2(x + 4, y + 13), "Indoors – the suit rests", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.95, 0.65))
		y += 18
	bottom_y = y
	# the belt along the bottom left – 0.7.52.13: tiles as in space (its places on 1, 2, 3 …)
	var bx := 14.0
	var by := get_viewport_rect().size.y - 82.0
	for i in g.belt.size():
		var p: Dictionary = g.belt[i]
		var r := Rect2(Vector2(bx, by), Vector2(74, 72))
		if p.is_empty():
			tile(self, r, null, Keybinds.key_text("foot_belt_%d" % (i + 1)) if i < 4 else str(i + 1), "empty", "", Color(0.5, 0.55, 0.6, 0.35), -1.0, Color.WHITE)
		else:
			tile(self, r, GearIcons.icon(String(p["id"])), Keybinds.key_text("foot_belt_%d" % (i + 1)) if i < 4 else str(i + 1),
				String(GearData.base(String(p["id"])).get("name", "")), ("×%d" % int(p["n"])) if int(p["n"]) > 1 else "", Color(0.55, 0.9, 0.45, 0.6), -1.0, Color.WHITE)
		bx += 80
	var by2 := by + 24
	if g.stim_t > 0.0:
		draw_string(font, Vector2(bx + 6, by2), "Stimulant %ds" % int(ceil(g.stim_t)), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 1.0, 0.6))



## 0.7.52.13 (Luz): a tile like the ship's module tiles – the key top left, the picture top right, the name, a line under
## it (rounds, a count, a state) and a bar (`bar` < 0: none); framed in `border`.
static func tile(ci: CanvasItem, r: Rect2, icon: Texture2D, key: String, name: String, sub: String, border: Color, bar: float, bar_col: Color) -> void:
	var font := ThemeDB.fallback_font
	ci.draw_rect(r, Color(0.03, 0.04, 0.08, 0.9))
	ci.draw_rect(r, border, false, 2.0 if border.a > 0.8 else 1.0)
	if key != "":
		ci.draw_string(font, r.position + Vector2(5, 14), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.82, 0.35))
	if icon != null:
		ci.draw_texture_rect(icon, Rect2(r.position + Vector2(r.size.x - 36, 4), Vector2(30, 30)), false)
	var nm := name
	while nm.length() > 3 and font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x > r.size.x - 10:
		nm = nm.left(nm.length() - 1)
	ci.draw_string(font, r.position + Vector2(5, 48), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.85, 0.9, 1.0) if name != "empty" else Color(0.5, 0.5, 0.55))
	if sub != "":
		ci.draw_string(font, r.position + Vector2(5, 60), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.75, 0.78, 0.82))
	if bar >= 0.0:
		ci.draw_rect(Rect2(r.position + Vector2(5, r.size.y - 7), Vector2(r.size.x - 10, 3)), Color(0.12, 0.12, 0.15))
		ci.draw_rect(Rect2(r.position + Vector2(5, r.size.y - 7), Vector2((r.size.x - 10) * clampf(bar, 0.0, 1.0), 3)), bar_col)
