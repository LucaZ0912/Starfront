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


func _draw() -> void:
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
	var w := 0.0
	for p in parts:
		w += font.get_string_size(String(p[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + font.get_string_size(String(p[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 30
	var x := vs.x * 0.5 - w * 0.5
	var y := vs.y - 118
	if not parts.is_empty():
		draw_rect(Rect2(x - 10, y - 20, w + 20, 22), Color(0.02, 0.04, 0.08, 0.8))
	for p2 in parts:
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
