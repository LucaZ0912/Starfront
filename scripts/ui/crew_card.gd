extends RefCounted
## Package 31: one crew member as a card – portrait, name, profession, quality, bonus, perk, experience.
## Used by the crew view of the ship menu and by the bar.

const CrewData = preload("res://data/crew.gd")
const CrewCore = preload("res://scripts/core/crew.gd")
const PilotArt = preload("res://scripts/core/pilot_art.gd")


## A card; `buttons` are added on the right ([[text, Callable, disabled], …]); `head`: a line above (post name).
static func card(m: Dictionary, buttons: Array = [], head: String = "", head_col: Color = UI.TEXT_DIM, width: float = 0.0) -> PanelContainer:
	var q := String(m["quality"])
	var qc: Color = CrewData.QUALITY_COLORS.get(q, UI.TEXT_DIM)
	var p := UI.neon_panel(Color(qc, 0.55), Color(0.04, 0.05, 0.09, 0.96), 1)
	if width > 0.0:
		p.custom_minimum_size = Vector2(width, 0)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := UI.hbox(10)
	p.add_child(row)
	var por := TextureRect.new()
	por.texture = PilotArt.portrait(m.get("look", {}))
	por.custom_minimum_size = Vector2(64, 64)
	por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	por.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(por)
	var v := UI.vbox(1)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	if head != "":
		v.add_child(UI.label(head, 11, head_col))
	var nr := UI.hbox(8)
	v.add_child(nr)
	nr.add_child(UI.label(String(m["name"]), 15, Color(0.95, 0.96, 1.0)))
	nr.add_child(UI.label("%s · %s" % [q, CrewData.QUALITY_NAMES.get(q, "")], 13, qc))
	v.add_child(UI.label(CrewData.role_name(String(m["role"])) + ("  /  " + CrewData.role_name(String(m["role2"])) if String(m.get("role2", "")) != "" else ""), 12, UI.NEON_CYAN))
	v.add_child(UI.label(CrewCore.line(m), 12, UI.GOOD))
	var pk := String(m.get("perk", ""))
	if pk != "":
		v.add_child(UI.label("★ %s – %s" % [CrewData.PERKS[pk]["name"], CrewData.PERKS[pk]["text"]], 11, UI.GOLD))
	var nq := CrewCore.next_quality(q)
	if nq != "":
		var xr := UI.hbox(6)
		v.add_child(xr)
		var bar := UI.bar(qc, 140)
		bar.max_value = float(CrewData.XP_NEED[q])
		bar.value = float(m.get("xp", 0.0))
		xr.add_child(bar)
		xr.add_child(UI.label("to %s – learns from %s" % [nq, CrewData.ROLES[String(m["role"])]["learns"]], 10, UI.TEXT_DIM))
	v.add_child(UI.label("Share of income %.2f %%" % (CrewCore.share_of(m) * 100.0), 10, UI.TEXT_DIM))
	if not buttons.is_empty():
		var bv := UI.vbox(4)
		row.add_child(bv)
		for b in buttons:
			var btn := UI.button(String(b[0]), b[1])
			btn.disabled = b.size() > 2 and bool(b[2])
			if b.size() > 3:
				btn.tooltip_text = String(b[3])
			bv.add_child(btn)
	return p


## An empty post.
static func empty_post(role: String, required: bool, buttons: Array = []) -> PanelContainer:
	var p := UI.neon_panel(Color(UI.BAD if required else UI.TEXT_DIM, 0.5), Color(0.04, 0.04, 0.06, 0.9), 1)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := UI.hbox(10)
	p.add_child(row)
	row.add_child(UI.icon(PixelArt.icon_texture(String(CrewData.ROLES[role]["icon"])), 40))
	var v := UI.vbox(1)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	v.add_child(UI.label("%s%s" % [CrewData.role_name(role), "  •  REQUIRED" if required else ""], 14, UI.BAD if required else UI.TEXT_DIM))
	v.add_child(UI.label("empty post", 12, UI.TEXT_DIM))
	for b in buttons:
		var btn := UI.button(String(b[0]), b[1])
		btn.disabled = b.size() > 2 and bool(b[2])
		row.add_child(btn)
	return p
