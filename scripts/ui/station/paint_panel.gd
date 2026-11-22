extends StationServicePanel
## Package 61d (Luz, 22 Nov 2026): Second Skin, the paint shop in Centauria's Commercial Hall. Left: your ships that
## stand in Centauria's hangar, each with the paint it wears. Middle: the picked ship in the picked paint, the paint's
## name, a line about it, the price (by the hull's size, after the standing). Right: the fixed paints, two swatches
## each. "Paint it" costs; "Back to factory colours" is free.

const PaintData = preload("res://data/paints.gd")

var pick_uid := -1
var pick_paint := ""


## Your ships standing in this city's hangar (the active one first).
func ships() -> Array:
	var sid := String(station.get("id", ""))
	var out: Array = GameState.fleet.filter(func(f): return String(f.docked_at) == sid)
	var act = GameState.active()
	out.sort_custom(func(a, b): return a == act and b != act)
	return out


static func picture(hull_id: String, paint: String) -> Texture2D:
	if paint == "":
		return PixelArt.ship_texture(hull_id, "player")
	if paint == "pt_rust":
		return PixelArt.rust_texture(hull_id)
	if not PaintData.PAINTS.has(paint):
		return PixelArt.ship_texture(hull_id, "player")
	return PixelArt.ship_texture(hull_id, paint)


func price_of(f, paint: String) -> int:
	if paint == "":
		return 0
	return buy_price(PaintData.price(int(GameData.hulls.get(String(f.hull_id), {}).get("size", 1)), paint))


func build() -> void:
	UI.clear(self)
	standing_line()
	var list := ships()
	if list.is_empty():
		add_child(UI.label("None of your ships stands in Centauria's hangar.", 14, UI.BAD))
		return
	var cur = null
	for f0 in list:
		if int(f0.uid) == pick_uid:
			cur = f0
	if cur == null:
		cur = list[0]
		pick_uid = int(cur.uid)
		pick_paint = String(cur.paint)
	var col := corp_color()
	var row := UI.hbox(16)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(row)
	# your ships here
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(240, 0)
	left.add_theme_constant_override("separation", 6)
	row.add_child(left)
	left.add_child(UI.label("Your ships here", 13, UI.TEXT_DIM))
	for f in list:
		var sb := UI.button("%s%s\n%s" % ["›  " if f == cur else "", String(f.ship_name), PaintData.name_of(String(f.paint))],
			func(): pick_uid = int(f.uid); pick_paint = String(f.paint); refresh_all())
		sb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		sb.disabled = f == cur
		left.add_child(sb)
	# the ship in the picked paint
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 6)
	row.add_child(mid)
	var pic := TextureRect.new()
	pic.texture = picture(String(cur.hull_id), pick_paint)
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.custom_minimum_size = Vector2(0, 400)
	pic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_child(pic)
	mid.add_child(UI.label(PaintData.name_of(pick_paint), 20, col))
	mid.add_child(UI.label(PaintData.text_of(pick_paint), 13, UI.TEXT_DIM))
	var price := price_of(cur, pick_paint)
	var worn := pick_paint == String(cur.paint)
	var note := "%s wears it already." % String(cur.ship_name) if worn else ("Free" if price == 0 else GameData.fmt_credits(price))
	var broke := not worn and price > GameState.credits
	if broke:
		note += "   (not enough credits)"
	mid.add_child(UI.label(note, 14, UI.BAD if broke else UI.GOOD))
	var btns := UI.hbox(8)
	mid.add_child(btns)
	var back := UI.button("Back to factory colours", func(): pick_paint = ""; run({"type": "paint_ship", "uid": int(cur.uid), "paint": ""}))
	back.disabled = String(cur.paint) == ""
	btns.add_child(back)
	btns.add_child(UI.spacer())
	var go := UI.button("Paint it", func(): run({"type": "paint_ship", "uid": int(cur.uid), "paint": pick_paint}))
	go.disabled = worn or broke or pick_paint == ""
	btns.add_child(go)
	# the paints
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(280, 560)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(sc)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 4)
	sc.add_child(right)
	right.add_child(UI.label("Paints", 13, UI.TEXT_DIM))
	for id in [""] + PaintData.ORDER:
		var pr := UI.hbox(6)
		right.add_child(pr)
		var pd: Dictionary = PaintData.PAINTS.get(id, {})
		for sw in [pd.get("hull", Color(0.62, 0.68, 0.77)), pd.get("acc", Color(0.35, 0.8, 1.0))]:
			var cr := ColorRect.new()
			cr.color = sw
			cr.custom_minimum_size = Vector2(18, 18)
			cr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			pr.add_child(cr)
		var pb := UI.button(("›  " if id == pick_paint else "") + PaintData.name_of(id), func(): pick_paint = id; refresh_all())
		pb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pb.disabled = id == pick_paint
		pr.add_child(pb)
