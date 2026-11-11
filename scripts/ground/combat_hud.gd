class_name CombatHud
extends Control
## Package 52: the fight on foot on the screen (after the mockup Luz approved) – the locked targets top centre as in
## space (name, T#, distance, hit chance, their weapon; shield, armour, health bars), the fight top right (how many,
## who is closing in), the cover line under the suit's bars; 0.7.52.13 (Luz): along the bottom tiles as in space – the
## weapons, the grenades, the drone – and the dodge charges above them.

const GearData = preload("res://data/gear.gd")
const GearIcons = preload("res://scripts/ui/gear_icons.gd")
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
	_draw_dodges(Vector2(14, (suit_hud.bottom_y if suit_hud != null else 190.0) + (26.0 if combat.fight else 2.0)))
	_draw_team((suit_hud.bottom_y if suit_hud != null else 190.0) + (54.0 if combat.fight else 30.0))
	if combat.wheel_open:
		_draw_wheel()
	# 0.7.52.13 (Luz): tiles along the bottom, as in space – the weapons (the one in hand framed green), a little apart
	# the grenades (the one in hand framed red), then the drone; Q, X and C go through them
	_draw_tiles(vs)


## 0.7.52.20 (Luz, package 52a): your ground team as cards under the suit's bars – portrait, name, profession and
## quality, shield and body, its order, its ability charging in a ring (green: ready). The one the orders go to framed
## bright; down: the time left to bring it back; dead: grey.
func _draw_team(y0: float) -> void:
	var green := GroundCombat.TEAM_COL
	var CD = GroundCombat.CrewData
	for i in combat.allies.size():
		var a: Dictionary = combat.allies[i]
		var m: Dictionary = a["m"]
		var r := Rect2(Vector2(14, y0 + i * 84), Vector2(320, 76))
		var sel: bool = combat.team_sel == i or combat.team_sel >= combat.allies.size()
		var col := green if not a["down"] else (Color(1.0, 0.6, 0.3) if not a["dead"] else Color(0.5, 0.5, 0.52))
		draw_rect(r, Color(0.03, 0.04, 0.08, 0.88))
		draw_rect(r, Color(col, 0.95 if sel else 0.45), false, 2.0 if sel else 1.0)
		var pr := Rect2(r.position + Vector2(6, 6), Vector2(64, 64))
		draw_texture_rect(ChibiArt.PilotArt.portrait(m.get("look", {})), pr, false, Color(1, 1, 1) if not a["dead"] else Color(0.5, 0.5, 0.5))
		draw_rect(pr, Color(0.3, 0.35, 0.4), false, 1.0)
		_s(r.position + Vector2(78, 18), String(m.get("name", "")).left(22), Color(0.92, 0.95, 1.0), 13)
		_s(r.position + Vector2(78, 32), "%s  ·  %s %s" % [CD.role_name(String(m.get("role", ""))), String(a["quality"]), String(CD.QUALITY_NAMES.get(String(a["quality"]), ""))], Color(0.7, 0.75, 0.8), 10)
		var st: Dictionary = a["st"]
		var mx: Dictionary = a["mx"]
		_bar(r.position + Vector2(78, 39), 124, float(st["shield"]) / maxf(float(mx["shield"]), 0.001), Color(0.35, 0.8, 1.0))
		_bar(r.position + Vector2(78, 47), 124, (float(st["armor"]) + float(st["health"])) / maxf(float(mx["armor"]) + float(mx["health"]), 0.001), Color(1.0, 0.35, 0.3))
		var ord := "dead – a clinic can bring them back"
		if not a["dead"] and a["down"]:
			ord = "DOWN – hold %s beside them  (%d s)" % [Keybinds.key_text("interact"), int(ceil(CD.DOWN_TIME - float(a["down_t"])))]
		elif not a["dead"]:
			match String(a["order"]):
				"hold":
					ord = "Hold position"
				"attack":
					ord = "Attack: %s" % (String(a["tgt"]["name"]) if a["tgt"] != null else "your target")
				_:
					ord = "Follow you  ·  %s" % String(CD.STANCES.get(String(a["stance"]), ""))
		_s(r.position + Vector2(78, 67), "▸ " + ord, col, 10)
		# the ability: a ring that fills, its name under it
		var ab: Dictionary = combat.ability_of(a)
		if not ab.is_empty() and not a["dead"]:
			var k := combat.ability_k(a)
			var cc := r.position + Vector2(280, 28)
			draw_circle(cc, 17.0, Color(0.08, 0.1, 0.14))
			draw_arc(cc, 15.0, -PI / 2, -PI / 2 + TAU * k, 28, Color(1.0, 0.82, 0.35) if k < 1.0 else green, 3.0)
			draw_string(ThemeDB.fallback_font, cc + Vector2(-17, 4), ("%d%%" % int(k * 100.0)) if k < 1.0 else "READY", HORIZONTAL_ALIGNMENT_CENTER, 34, 9, Color(0.9, 0.9, 0.9))
			draw_string(ThemeDB.fallback_font, cc + Vector2(-44, 33), String(ab["name"]), HORIZONTAL_ALIGNMENT_CENTER, 84, 9, Color(0.75, 0.78, 0.82))
	if not combat.allies.is_empty():
		var who := "all" if combat.team_sel >= combat.allies.size() else String(combat.allies[combat.team_sel]["name"])
		_label(Vector2(14, y0 + combat.allies.size() * 84 + 14), "%s  orders to: %s  (tap: next, hold: wheel)" % [Keybinds.key_text("foot_team"), who])


## 0.7.52.20 (Luz): the command wheel round you while V is held – four fields (follow, attack your target, hold, the
## ability); the one under the mouse lit; in its middle whom the order goes to. Letting go of V gives it.
func _draw_wheel() -> void:
	var green := GroundCombat.TEAM_COL
	var vs := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.25))
	var c: Vector2 = combat.view.wheel_centre()
	var r_in := 52.0
	var r_out := 160.0
	var pick := GroundCombat.wheel_pick(c, get_viewport().get_mouse_position(), r_in)
	var all: bool = combat.team_sel >= combat.allies.size()
	var who: Dictionary = {} if all else combat.allies[combat.team_sel]
	for si in 4:
		var kind := String(GroundCombat.WHEEL[si])
		var mid := -PI / 2 + si * PI / 2
		var on := kind == pick
		var pts := PackedVector2Array()
		for t in 13:
			pts.append(c + Vector2.from_angle(mid - PI / 4 + 0.03 + (PI / 2 - 0.06) * t / 12.0) * r_out)
		for t2 in 13:
			pts.append(c + Vector2.from_angle(mid + PI / 4 - 0.03 - (PI / 2 - 0.06) * t2 / 12.0) * r_in)
		draw_colored_polygon(pts, Color(0.1, 0.32, 0.45, 0.88) if on else Color(0.04, 0.06, 0.1, 0.72))
		pts.append(pts[0])
		draw_polyline(pts, Color(green, 0.95) if on else Color(0.45, 0.55, 0.6, 0.7), 2.0 if on else 1.0)
		var text := String(GroundCombat.WHEEL_NAMES[kind])
		if kind == "ability":
			if all:
				text = "Abilities:\nall ready ones"
			else:
				var ab: Dictionary = combat.ability_of(who)
				text = "Ability:\n%s" % String(ab.get("name", "none"))
				if not ab.is_empty() and combat.ability_k(who) < 1.0:
					text += "\n(%d s)" % int(ceil(float(who["ab"])))
		var lines := text.split("\n")
		var lp := c + Vector2.from_angle(mid) * (r_in + r_out) * 0.5
		for li in lines.size():
			draw_string(ThemeDB.fallback_font, lp + Vector2(-60, 4 + (li - (lines.size() - 1) * 0.5) * 15), lines[li], HORIZONTAL_ALIGNMENT_CENTER, 120, 13,
				Color(1, 1, 1) if on else Color(0.8, 0.85, 0.9))
	draw_circle(c, r_in - 4, Color(0.03, 0.04, 0.08, 0.95))
	if all:
		draw_string(ThemeDB.fallback_font, c + Vector2(-40, 5), "ALL", HORIZONTAL_ALIGNMENT_CENTER, 80, 16, green)
	else:
		draw_texture_rect(ChibiArt.PilotArt.portrait(who["m"].get("look", {})), Rect2(c - Vector2(28, 34), Vector2(56, 56)), false)
		draw_string(ThemeDB.fallback_font, c + Vector2(-40, 38), String(who["name"]), HORIZONTAL_ALIGNMENT_CENTER, 80, 12, green)
	draw_string(ThemeDB.fallback_font, c + Vector2(-320, -r_out - 22), "let go of %s: the order is given  ·  tap %s (wheel closed): whom" % [Keybinds.key_text("foot_team"), Keybinds.key_text("foot_team")],
		HORIZONTAL_ALIGNMENT_CENTER, 640, 13, Color(1.0, 0.82, 0.35))


## A small label on a dark plate (readable on any ground) – its bottom left at p.
func _label(p: Vector2, t: String) -> void:
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	draw_rect(Rect2(p + Vector2(-3, -13), Vector2(w + 6, 16)), Color(0.0, 0.0, 0.03, 0.7))
	_s(p, t, Color(0.82, 0.85, 0.9), 11)


const TILE := Vector2(74, 72)
const TILE_GAP := 6.0
const GROUP_GAP := 22.0


## 0.7.52.14 (Luz): the arm laser's tile – a yellow frame drawn round bit by bit as it charges; full: ready.
func _charge_frame(r: Rect2, k: float) -> void:
	var per := (r.size.x + r.size.y) * 2.0
	var left := per * clampf(k, 0.0, 1.0)
	var pts := [r.position, r.position + Vector2(r.size.x, 0), r.end, r.position + Vector2(0, r.size.y), r.position]
	var col := Color(1.0, 0.85, 0.2) if k < 1.0 else Color(1.0, 0.9, 0.3, 0.75 + 0.25 * sin(Time.get_ticks_msec() * 0.008))
	for i in 4:
		var a0: Vector2 = pts[i]
		var b0: Vector2 = pts[i + 1]
		var seg := a0.distance_to(b0)
		if left <= 0.0:
			break
		draw_line(a0, a0.lerp(b0, minf(1.0, left / seg)), col, 3.0)
		left -= seg


## 0.7.52.13: the dodge charges under the suit's bars.
func _draw_dodges(p: Vector2) -> void:
	var t := "%s  dodge" % Keybinds.key_text("foot_dodge")
	var font := ThemeDB.fallback_font
	var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	var mxd := combat.max_dodges()
	draw_rect(Rect2(p, Vector2(tw + 24 + mxd * 16, 20)), Color(0.0, 0.0, 0.03, 0.55))
	_s(p + Vector2(7, 14), t, Color(0.85, 0.88, 0.92), 12)
	for i2 in mxd:
		var cc := p + Vector2(tw + 20 + i2 * 16, 10)
		var fill := clampf(combat.dodge_charges - i2, 0.0, 1.0)
		if fill >= 1.0:
			draw_circle(cc, 5.0, Color(0.45, 1.0, 0.6))
		else:
			draw_arc(cc, 5.0, 0, TAU, 16, Color(0.45, 1.0, 0.6, 0.5), 1.5)
			if fill > 0.0:
				draw_arc(cc, 5.0, -PI / 2, -PI / 2 + TAU * fill, 16, Color(0.45, 1.0, 0.6), 2.5)


## The weapons, the grenades and the drone as tiles, centred along the bottom.
func _draw_tiles(vs: Vector2) -> void:
	var g = GameState.gear
	var ws: Array = combat.weapons()
	var gr: Array = g.grenades
	var n_dr := 0
	for di0 in combat.drone_places():
		n_dr += int(combat.drone_id(di0) != "")
	var has_drone: bool = n_dr > 0
	var n_tiles: int = ws.size() + gr.size() + n_dr
	var groups: int = int(not ws.is_empty()) + int(not gr.is_empty()) + int(has_drone)
	var width: float = n_tiles * (TILE.x + TILE_GAP) - TILE_GAP + maxf(0.0, groups - 1) * GROUP_GAP
	var x: float = vs.x * 0.5 - width * 0.5
	var y: float = vs.y - TILE.y - 10.0
	var dim := Color(0.7, 0.72, 0.76)
	# the weapons
	if not ws.is_empty():
		_label(Vector2(x, y - 4), "%s  weapon" % Keybinds.key_text("foot_swap"))
		for i in ws.size():
			var wid := String(ws[i])
			var st := GearData.stats(wid)
			var act: bool = i == combat.weapon_i % ws.size()
			var sub: String = ("%.1f en" % float(st["energy"])) if st.has("energy") else ("%d rd" % int(g.ammo))
			var arm := bool(st.get("pierce", false))
			if arm:
				sub = "READY" if combat.arm_charge_k() >= 1.0 else "charging %d %%" % int(combat.arm_charge_k() * 100.0)
			var barv: float = (g.energy / maxf(float(g.totals()["energy"]), 1.0)) if st.has("energy") else (float(g.ammo) / maxf(float(g.totals()["ammo"]), 1.0))
			SuitHud.tile(self, Rect2(Vector2(x, y), TILE), GearIcons.icon(wid), "", String(st["name"]), sub,
				Color(0.4, 1.0, 0.5) if act else Color(0.5, 0.55, 0.6, 0.5), -1.0 if arm else barv, DT_COL[String(st.get("dtype", "kinetic"))])
			if arm:
				_charge_frame(Rect2(Vector2(x, y), TILE).grow(-3.0), combat.arm_charge_k())
			x += TILE.x + TILE_GAP
		x += GROUP_GAP - TILE_GAP
	# the grenades
	if not gr.is_empty():
		_label(Vector2(x, y - 4), "%s  grenade – hold: throw" % Keybinds.key_text("foot_grenade"))
		g.grenade()
		for j in gr.size():
			var p: Dictionary = gr[j]
			var act2: bool = j == int(g.gr_sel) and not p.is_empty()
			if p.is_empty():
				SuitHud.tile(self, Rect2(Vector2(x, y), TILE), null, "", "empty", "", Color(0.5, 0.55, 0.6, 0.35), -1.0, Color.WHITE)
			else:
				SuitHud.tile(self, Rect2(Vector2(x, y), TILE), GearIcons.icon(String(p["id"])), "", String(GearData.base(String(p["id"]))["name"]),
					"×%d" % int(p["n"]), Color(1.0, 0.3, 0.25) if act2 else Color(0.5, 0.55, 0.6, 0.5), -1.0, Color.WHITE)
			x += TILE.x + TILE_GAP
		x += GROUP_GAP - TILE_GAP
	# the drones (0.7.52.18: two on the Senate armours)
	for di in combat.drone_places():
		if combat.drone_id(di) == "":
			continue
		combat.pick_drone(di)
		var did: String = combat.drone_id()
		var dst := GearData.stats(did)
		var d: Dictionary = combat.drone
		var state := String(d.get("state", "docked")) if not d.is_empty() else "docked"
		var sub2 := ""
		var barv2 := -1.0
		var bcol := Color(0.45, 0.8, 1.0)
		if not combat.drone_alive():
			sub2 = "new in %ds" % int(ceil(combat.drone_rebuild))
			barv2 = 1.0 - combat.drone_rebuild / maxf(float(dst["rebuild"]), 0.01)
		else:
			sub2 = {"docked": "off", "dock": "back", "launch": "up", "hover": "on", "return": "empty", "reload": "reload", "dive": "dive!"}.get(state, state)
			if String(dst["kind"]) == "laser":
				barv2 = float(d["heat"]) / float(dst["heat_max"])
				bcol = Color(1.0, 0.3, 0.2) if bool(d["over"]) else Color(1.0, 0.55, 0.2)
			elif String(dst["kind"]) == "kinetic":
				barv2 = float(d["ammo"]) / maxf(float(dst["mag"]), 1.0)
				bcol = Color(0.85, 0.85, 0.8)
			else:
				barv2 = (float(d["st"]["shield"]) + float(d["st"]["armor"])) / maxf(float(d["mx"]["shield"]) + float(d["mx"]["armor"]), 1.0)
		var on := combat.drone_flying()
		_label(Vector2(x, y - 4), "%s  drone" % Keybinds.key_text("foot_drone" if di == 0 else "foot_drone_2"))
		SuitHud.tile(self, Rect2(Vector2(x, y), TILE), GearIcons.icon(did), "", String(dst["name"]), sub2,
			Color(0.45, 0.9, 1.0) if on else Color(0.5, 0.55, 0.6, 0.5), barv2, bcol)
		x += TILE.x + TILE_GAP
	combat.pick_drone(0)
