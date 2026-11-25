extends Control
## Package 80 (Luz): in space with the controller – the button prompts along the bottom, and while a D-pad direction is
## held the shoulder buttons over the fire groups they switch (← : 1–4, → : 5–8).

var combo := ""                     # "left" · "right" · ""
var list := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _bt(ctx: String, id: String) -> String:
	return Pad.binding_text(Pad.binding(ctx, id))


var seat := 0                       # split screen in space: whose controller it belongs to (it is drawn as theirs)


func _draw() -> void:
	var m0 := get_tree().current_scene
	if seat == 1 and m0 != null and "view" in m0 and m0.view != null and is_instance_valid(m0.view) and "eyes_two" in m0.view and m0.view.eyes_two:
		m0.view.in_eye(1, _draw_now)                  # (their glyphs, their HUD, their view's level)
	else:
		_draw_now()


func _draw_now() -> void:
	var font := get_theme_font("font", "Label")
	var vs := get_viewport_rect().size
	var parts: Array = []
	if combo != "":
		pass                                          # (the combo's labels take the place over the bar)
	elif Pad._on_map():
		parts = [["Left stick", "pick the next one that way"], [Pad.glyph("cross"), "go there"],
			[_bt("space", "pad_wheel"), "actions"], [_bt("space", "pad_deselect"), "deselect"], [_bt("space", "pad_zoom_in"), "zoom in"], [_bt("space", "cam_center"), "back to the ship"]]
	elif list:
		parts = [["↑ ↓", "pick"], [Pad.glyph("cross"), "select"], [Pad.glyph("l1") + " " + Pad.glyph("r1"), "overview · contacts"], [Pad.glyph("circle"), "back"]]
	else:
		parts = [[_bt("space", "cmd_lock"), "lock"], [_bt("space", "pad_wheel"), "actions"], [_bt("space", "pad_deselect"), "deselect"],
			[_bt("space", "boost"), "thrust"], [_bt("space", "sel_target"), "next target"], [_bt("space", "sel_hostile"), "next hostile"],
			[Pad.glyph("left") + " / " + Pad.glyph("right"), "fire groups"], [_bt("space", "pad_list"), "list"],
			[_bt("space", "pad_options") + " hold", "ship · pilot · map"]]
	# one row, or as many as the picture's width needs (a narrow half of a split screen): each centred
	var rows: Array = [[]]
	var row_w: Array = [0.0]
	for p in parts:
		var pw: float = font.get_string_size(String(p[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + font.get_string_size(String(p[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 30
		if float(row_w[-1]) + pw > vs.x - 24.0 and not (rows[-1] as Array).is_empty():
			rows.append([])
			row_w.append(0.0)
		(rows[-1] as Array).append(p)
		row_w[-1] = float(row_w[-1]) + pw
	var y_last := vs.y - 118
	var mh := get_tree().current_scene
	if mh != null and "hud" in mh and mh.hud != null and mh.hud.has_method("narrow") and mh.hud.narrow():
		y_last = mh.hud.foot_top() - 8.0              # a narrow half: above the ship and the list, which stand over the module bar there
	for ri in rows.size():
		var w: float = row_w[ri]
		var x := vs.x * 0.5 - w * 0.5
		var y := y_last - (rows.size() - 1 - ri) * 26.0
		if not (rows[ri] as Array).is_empty():
			draw_rect(Rect2(x - 10, y - 20, w + 20, 22), Color(0.02, 0.04, 0.08, 0.8))
		for p2 in rows[ri]:
			var g := String(p2[0])
			var gw := font.get_string_size(g, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			draw_rect(Rect2(x - 3, y - 18, gw + 6, 18), Color(0.12, 0.14, 0.2))
			draw_string(font, Vector2(x, y - 4), g, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.82, 0.35))
			x += gw + 8
			draw_string(font, Vector2(x, y - 4), String(p2[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.88, 0.9, 0.98))
			x += font.get_string_size(String(p2[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 22
	if combo == "":
		return
	# the fire group combo: the shoulder buttons over the group tiles they switch
	var m := get_tree().current_scene
	if m == null or not ("hud" in m) or m.hud == null:
		return
	var g0 := 1 if combo == "left" else 5
	for i in 4:
		var t: Dictionary = m.hud._group_tiles.get(g0 + i, {})
		if t.is_empty():
			continue
		var b: Control = t["button"]
		var r := b.get_global_rect()
		var bd: Dictionary = Pad.binding("space", "module_%d" % (g0 + i))
		var lab := Pad.glyph(String(bd.get("b", ""))) if not bd.is_empty() else "–"
		var lw := font.get_string_size(lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		var pr := Rect2(Vector2(r.get_center().x - lw * 0.5 - 8, r.position.y - 30), Vector2(lw + 16, 24))
		draw_rect(pr, Color(0.03, 0.05, 0.1, 0.95))
		draw_rect(pr, (HUD.FIRE_COLORS[g0 + i - 1] as Color), false, 2.0)
		draw_string(font, pr.position + Vector2(8, 18), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
