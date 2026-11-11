class_name CombatHud
extends Control
## Package 52: the fight on foot on the screen (after the mockup Luz approved) – the locked targets top centre as in
## space (name, T#, distance, hit chance, their weapon; shield, armour, health bars), the fight top right (how many,
## who is closing in), the cover line under the suit's bars, and the weapons bottom right (the one in hand with its
## damage type and what a shot costs, the other on Q, the skills, the dodge charges on Space).

const GearData = preload("res://data/gear.gd")
const COLS := [Color(0.35, 0.65, 1.0), Color(1.0, 0.8, 0.3), Color(0.9, 0.3, 0.3)]
const DT_COL := {"optical": Color(0.45, 0.85, 1.0), "kinetic": Color(1.0, 0.8, 0.35), "explosive": Color(1.0, 0.55, 0.25)}
var combat: GroundCombat
var suit_hud: SuitHud


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(_d: float) -> void:
	queue_redraw()


func _panel(r: Rect2, border: Color) -> void:
	draw_rect(r, Color(0.03, 0.04, 0.08, 0.88))
	draw_rect(r, border, false, 2.0)


func _bar(p: Vector2, w: float, v: float, col: Color) -> void:
	draw_rect(Rect2(p, Vector2(w, 5)), Color(0.12, 0.12, 0.15))
	draw_rect(Rect2(p, Vector2(w * clampf(v, 0.0, 1.0), 5)), col)


func _s(p: Vector2, t: String, col: Color, sz: int = 12) -> void:
	draw_string(ThemeDB.fallback_font, p, t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _draw() -> void:
	if combat == null or not is_instance_valid(combat):
		return
	var vs := get_viewport_rect().size
	var red := Color(1.0, 0.35, 0.3)
	var dim := Color(0.7, 0.72, 0.76)
	var font := ThemeDB.fallback_font
	# the locked targets, top centre
	var n := combat.locks.size()
	var x := vs.x * 0.5 - (n * 198.0 - 8.0) * 0.5
	for i in n:
		var f = combat.locks[i]
		var act: bool = f == combat.active
		var r := Rect2(Vector2(x, 12), Vector2(190, 62))
		_panel(r, red if act else Color(red, 0.35))
		var tcolr: Color = GroundCombat.FoeData.TIERS[String(f.get("tier", "green"))]["col"]
		draw_circle(r.position + Vector2(r.size.x - 12, 12), 5.0, tcolr)                 # 0.7.52.4: its strength
		_s(r.position + Vector2(8, 17), String(f["name"]).left(24), Color(0.95, 0.95, 0.95), 13)
		var dm := combat.pilot_pos().distance_to((f["w"] as Walker).pos) / 15.0
		var ch := combat.chance_at_foe(f)
		var info := "T%d  •  %d m  •  %s  •  %s" % [i + 1, int(round(dm)), ("hit %d%%" % int(round(ch * 100.0))) if ch > 0.0 else "no shot",
			String(GearData.base(String(f["weapon"])).get("name", ""))]
		_s(r.position + Vector2(8, 33), info, dim, 11)
		var st: Dictionary = f["st"]
		var mx: Dictionary = f["mx"]
		var k := 0
		for layer in ["shield", "armor", "health"]:
			_bar(r.position + Vector2(8, 40 + k * 7), 174, float(st[layer]) / maxf(float(mx[layer]), 0.001), COLS[k])
			k += 1
		x += 198
	# 0.7.52.2: the tactical view's line under the lock cards
	if combat.tactics != 0:
		var tred := combat.tactics == 2
		var who = combat.tac_viewer()
		var line := "TACTICS – your sight: green you can hit, red is covered from you" if not tred else 			"TACTICS – %s's sight: red it sees you, green is safe from it" % (String(who["name"]) if who != null else "?")
		var you := ""
		if tred and who != null and combat._vis.get("rays") != null:
			you = "  •  you are %s" % ("IN ITS SIGHT" if combat.lit_in(combat._vis["rays"], combat._vis["from"], combat.pilot_pos()) else "safe from it")
		var keys := "%s: %s  •  hold %s: off  •  %s / wheel: %s  •  yellow hatched: behind smoke, shots aim badly" % [Keybinds.key_text("foot_tactics"), "the target's sight" if not tred else "your sight", Keybinds.key_text("foot_tactics"), Keybinds.key_text("foot_zoom"), "zoom back in" if combat.view.tac_zoom < 1.0 else "zoom out"]
		var tcol := Color(1.0, 0.45, 0.4) if tred else Color(0.45, 1.0, 0.6)
		var tw := maxf(font.get_string_size(line + you, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x, font.get_string_size(keys, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x) + 20.0
		var tr := Rect2(Vector2(vs.x * 0.5 - tw * 0.5, 82 if n > 0 else 12), Vector2(tw, 40))
		_panel(tr, Color(tcol, 0.7))
		_s(tr.position + Vector2(10, 17), line + you, tcol, 13)
		_s(tr.position + Vector2(10, 33), keys, dim, 11)
	# the fight, top right
	if combat.fight:
		var aware: Array = combat.alive().filter(func(f): return f["aware"])
		var fr := Rect2(Vector2(vs.x - 230, 12), Vector2(216, 62))
		_panel(fr, Color(1.0, 0.75, 0.2, 0.8))
		_s(fr.position + Vector2(10, 18), "HOSTILES – %d" % aware.size(), Color(1.0, 0.8, 0.3), 14)
		var near = null
		var nd := INF
		for f2 in aware:
			var dd := combat.pilot_pos().distance_to((f2["w"] as Walker).pos)
			if dd < nd and not combat.locks.has(f2):
				nd = dd
				near = f2
		var line2 := "%s not locked, %d m" % [String(near["name"]), int(nd / 15.0)] if near != null else ("%d down" % combat.kills if combat.kills > 0 else "all of them locked")
		_s(fr.position + Vector2(10, 36), line2.left(34), Color(1.0, 0.75, 0.4), 11)
		_s(fr.position + Vector2(10, 53), "helmet sealed – fight", dim, 11)
	# the cover line under the suit's bars
	if combat.fight:
		var cy := (suit_hud.bottom_y if suit_hud != null else 190.0) + 2.0
		var txt := "OUT IN THE OPEN – find cover"
		var col := Color(1.0, 0.6, 0.45)
		if combat.in_cover == 2:
			txt = "IN COVER – incoming hits −%d%%" % int(GearData.COVER_CUT * 100.0)
			col = Color(0.45, 1.0, 0.6)
		elif combat.in_cover == 1:
			txt = "PARTLY IN COVER – not from every side"
			col = Color(0.85, 1.0, 0.45)
		var cr := Rect2(Vector2(14, cy), Vector2(font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 14, 20))
		draw_rect(cr, Color(0.0, 0.06, 0.03, 0.7))
		_s(cr.position + Vector2(7, 14), txt, col, 12)
	# the weapons, bottom right
	var ws: Array = combat.weapons()
	if ws.is_empty():
		return
	var wr := Rect2(Vector2(vs.x - 350, vs.y - 200), Vector2(336, 186))
	_panel(wr, Color(0.35, 0.85, 1.0, 0.7))
	_s(wr.position + Vector2(10, 20), "WEAPON", dim, 11)
	var wid := combat.weapon_id()
	var w := GearData.stats(wid)
	var dt := String(w.get("dtype", "kinetic"))
	draw_rect(Rect2(wr.position + Vector2(8, 28), Vector2(320, 46)), Color(DT_COL[dt], 0.12))
	draw_rect(Rect2(wr.position + Vector2(8, 28), Vector2(320, 46)), Color(DT_COL[dt], 0.8), false, 1.0)
	_s(wr.position + Vector2(16, 46), GearData.display_name(wid), Color(0.95, 0.95, 0.95), 14)
	_s(wr.position + Vector2(240, 46), dt.to_upper(), DT_COL[dt], 12)
	var cost := ("%.1f energy a shot" % float(w["energy"])) if w.has("energy") else ("%d round%s a shot  •  %d left" % [int(w.get("ammo", 1)), "" if int(w.get("ammo", 1)) == 1 else "s", GameState.gear.ammo])
	var doing := "locking…" if combat.lock_t > 0.0 else ("firing at T%d" % (combat.locks.find(combat.active) + 1) if combat.fight and combat.active != null else "ready")
	_s(wr.position + Vector2(16, 66), "%s  •  %d dmg  •  %.1f/s  •  %s" % [doing, int(round(float(w["damage"]))), float(w["rof"]), cost], dim, 11)
	if ws.size() > 1:
		var other := String(ws[(combat.weapon_i + 1) % ws.size()])
		var ow := GearData.stats(other)
		var odt := String(ow.get("dtype", "kinetic"))
		_s(wr.position + Vector2(16, 96), "%s  %s" % [Keybinds.key_text("foot_swap"), GearData.display_name(other)], Color(0.8, 0.8, 0.8), 13)
		_s(wr.position + Vector2(240, 96), odt.to_upper(), DT_COL[odt], 12)
		_s(wr.position + Vector2(16, 113), {"optical": "strong on shields", "kinetic": "strong on armour", "explosive": "strong on the body, splash"}[odt], dim, 11)
	else:
		_s(wr.position + Vector2(16, 96), "one weapon slot in use", dim, 12)
	_s(wr.position + Vector2(10, 140), "Firearms %d – aim  •  Athletics %d – dodge  •  %s target  •  %s tactics" % [GameState.skill_level("firearms"), GameState.skill_level("athletics"), Keybinds.key_text("foot_target"), Keybinds.key_text("foot_tactics")], dim, 11)
	_s(wr.position + Vector2(10, 166), "%s  dodge" % Keybinds.key_text("foot_dodge"), Color(0.95, 0.95, 0.95), 13)
	var mxd := combat.max_dodges()
	for i2 in mxd:
		var cc := Vector2(wr.position.x + 130 + i2 * 18, wr.position.y + 161)
		var fill := clampf(combat.dodge_charges - i2, 0.0, 1.0)
		if fill >= 1.0:
			draw_circle(cc, 6.0, Color(0.45, 1.0, 0.6))
		else:
			draw_arc(cc, 6.0, 0, TAU, 16, Color(0.45, 1.0, 0.6, 0.5), 1.5)
			if fill > 0.0:
				draw_arc(cc, 6.0, -PI / 2, -PI / 2 + TAU * fill, 16, Color(0.45, 1.0, 0.6), 3.0)
