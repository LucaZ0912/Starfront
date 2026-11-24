extends RefCounted
## Package 62a, part 3 (Luz): the Colosseum's two windows. `Play`: how you want to play (singleplayer; online co-op,
## online versus and split screen are there already, covered by "COMING SOON"). `Prep`: the fighters' room: on one
## side your gear, fitted from gear points (the house's pieces, never your own), on the other the mode; once a mode
## is picked, a preview of who waits in the arena, your record and what a win pays, and READY. READY counts down
## from five, the picture goes white, and you step into the arena. Every choice goes through the command bus
## (col_play, col_equip, col_mode, col_ready) with the seat, so a second player's can come the same way.
## No class_name: preload it.

const CD = preload("res://data/colosseum.gd")
const SV = preload("res://data/survivor.gd")                 # package 62a, part 7: Survivor
const SU = preload("res://scripts/ground/survivor_ui.gd")
const CG = preload("res://scripts/ground/colosseum_gen.gd")
const NEON := [Color(1.0, 0.36, 0.66), Color(0.3, 0.9, 1.0), Color(1.0, 0.82, 0.25), Color(0.72, 0.5, 1.0)]


class Play extends Control:
	signal finished(won: bool)
	var sel := 0
	var msg := "How do you want to play?"
	var _t := 0.0

	func is_col_play() -> bool:
		return true

	func setup(_cfg: Dictionary) -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func tiles() -> Array:
		var vs := get_viewport_rect().size
		var out: Array = []
		var w := 380.0
		var x0 := vs.x * 0.5 - (w * 4.0 + 36.0 * 3.0) * 0.5
		for i in CD.PLAY.size():
			out.append(Rect2(x0 + i * (w + 36.0), vs.y * 0.5 - 170.0, w, 340.0))
		return out

	## You pick a way to play (0 … 3). The ones that are not open yet only say so.
	func pick(i: int) -> void:
		sel = clampi(i, 0, CD.PLAY.size() - 1)
		var e: String = Commands.execute({"type": "col_play", "seat": 0, "play": String(CD.PLAY[sel][0])})
		if e != "":
			msg = e
			Audio.play("ui_error", "colosseum: not yet")
			return
		Audio.play("ui_open", "colosseum: the way to play")
		finished.emit(true)

	func _process(dt: float) -> void:
		_t += dt
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			var ts := tiles()
			for i in ts.size():
				if (ts[i] as Rect2).has_point((event as InputEventMouseButton).position):
					pick(i)
					accept_event()
					return

	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("menu_back", false, true):
			get_viewport().set_input_as_handled()
			finished.emit(false)
		elif event is InputEventKey and event.pressed and not event.echo:
			var kc := (event as InputEventKey).keycode
			if kc == KEY_LEFT or kc == KEY_RIGHT:
				sel = posmod(sel + (1 if kc == KEY_RIGHT else -1), CD.PLAY.size())
				get_viewport().set_input_as_handled()
			elif kc == KEY_ENTER or kc == KEY_SPACE:
				get_viewport().set_input_as_handled()
				pick(sel)

	func pad_button(b: String, pressed: bool) -> bool:
		if not pressed:
			return true
		match b:
			"left", "right":
				sel = posmod(sel + (1 if b == "right" else -1), CD.PLAY.size())
			"cross":
				pick(sel)
			"circle":
				finished.emit(false)
		return true

	func _draw() -> void:
		var vs := get_viewport_rect().size
		var font := ThemeDB.fallback_font
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.03, 0.02, 0.07, 0.96))
		draw_string(font, Vector2(0.0, vs.y * 0.5 - 250.0), "THE COLOSSEUM", HORIZONTAL_ALIGNMENT_CENTER, vs.x, 54, Color(1.0, 0.5, 0.8).lerp(Color(0.3, 0.9, 1.0), 0.5 + 0.5 * sin(_t * 1.5)))
		draw_string(font, Vector2(0.0, vs.y * 0.5 - 205.0), "Choose how you play", HORIZONTAL_ALIGNMENT_CENTER, vs.x, 22, Color(1.0, 0.85, 0.4))
		var ts := tiles()
		var mp := get_local_mouse_position()
		for i in ts.size():
			var r: Rect2 = ts[i]
			var p: Array = CD.PLAY[i]
			var open := bool(p[3])
			var hot := r.has_point(mp) or sel == i
			var col: Color = NEON[i % NEON.size()]
			draw_rect(r, Color(0.07, 0.05, 0.13) if open else Color(0.05, 0.05, 0.08))
			for g in 3:
				draw_rect(r.grow(g * 5.0), Color(col, (0.85 - g * 0.25) * (1.0 if open else 0.35) * (1.0 if hot else 0.6)), false, 3.0)
			# a mark for each: one figure, two side by side, two facing, two at one screen
			var c := r.position + Vector2(r.size.x * 0.5, 130.0)
			var fc := col if open else col.darkened(0.55)
			var who: Array = [[0.0], [-34.0, 34.0], [-46.0, 46.0], [-30.0, 30.0]][i]
			for dx in who:
				draw_circle(c + Vector2(float(dx), -36.0), 17.0, fc)
				draw_rect(Rect2(c.x + float(dx) - 20.0, c.y - 14.0, 40.0, 56.0), fc)
			if i == 2:
				draw_string(font, Vector2(c.x - 30.0, c.y + 12.0), "VS", HORIZONTAL_ALIGNMENT_CENTER, 60.0, 26, Color(0.05, 0.04, 0.1))
			if i == 3:
				draw_rect(Rect2(c.x - 74.0, c.y - 66.0, 148.0, 116.0), fc, false, 4.0)
				draw_line(Vector2(c.x, c.y - 66.0), Vector2(c.x, c.y + 50.0), fc, 4.0)
			draw_string(font, Vector2(r.position.x, r.position.y + 236.0), String(p[1]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 30, Color(1, 1, 1) if open else Color(0.5, 0.52, 0.6))
			draw_string(font, Vector2(r.position.x, r.position.y + 272.0), String(p[2]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 17, Color(0.8, 0.85, 0.95) if open else Color(0.4, 0.42, 0.5))
			if not open:                                        # the band across it
				draw_set_transform(r.get_center(), -0.16, Vector2.ONE)
				draw_rect(Rect2(-r.size.x * 0.62, -24.0, r.size.x * 1.24, 48.0), Color(1.0, 0.82, 0.25, 0.94))
				draw_string(font, Vector2(-r.size.x * 0.62, 10.0), "COMING SOON", HORIZONTAL_ALIGNMENT_CENTER, r.size.x * 1.24, 28, Color(0.1, 0.07, 0.02))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_string(font, Vector2(0.0, vs.y * 0.5 + 240.0), msg, HORIZONTAL_ALIGNMENT_CENTER, vs.x, 20, Color(1.0, 0.95, 0.6))
		draw_string(font, Vector2(0.0, vs.y - 60.0), "Click a tile, or left and right and Enter   ·   Esc: back to the counter", HORIZONTAL_ALIGNMENT_CENTER, vs.x, 16, Color(0.6, 0.65, 0.78))


class Prep extends Control:
	signal finished(won: bool)
	const GearIcons = preload("res://scripts/ui/gear_icons.gd")
	const ROW := 50.0
	const OPT := 34.0
	const COUNT := 5.0               # seconds READY counts down
	var slot := 0                    # the place marked: an index into slots()
	var scroll := 0                  # the first option shown
	var col_focus := 0               # (the controller) 0 your gear, 1 the pieces, 2 the modes, 3 READY
	var opt_sel := 0
	var mode_sel := 0
	var counting := -1.0             # the countdown's seconds left (-1: not counting)
	var white := 0.0                 # the picture going white (0 … 1)
	var msg := "Mark a place of your fit, then pick what goes into it. Pick a mode and press READY."
	var _t := 0.0
	var _last := 6
	var seat := 0                    # split screen: whose fit is on the table (0 you, 1 the second player)

	func is_col_prep() -> bool:
		return true

	func two() -> bool:
		return Players.split and GameState.has_pilot2()

	func fit_key() -> String:
		return "fit2" if seat == 1 and two() else "fit"

	func seat_rect(i: int) -> Rect2:
		return Rect2(210.0 + i * 200.0, 150.0, 190.0, 30.0)

	## Split screen: the other player's fit onto the table.
	func pick_seat(i: int) -> void:
		if not two() or counting >= 0.0:
			return
		seat = clampi(i, 0, 1)
		slot = 0
		scroll = 0
		opt_sel = 0
		msg = "%s: mark a place of the fit, then pick what goes into it." % String((GameState.pilot2 if seat == 1 else GameState.pilot).get("name", "")).get_slice(" ", 0)
		Audio.play("ui_click", "colosseum: whose fit")

	func setup(_cfg: Dictionary) -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func col() -> Dictionary:
		return GameState.col_state()

	## The places of the fit as rows: [{"place", "idx", "label", "id"}].
	func slots() -> Array:
		var fit: Dictionary = col()[fit_key()]
		var out: Array = [{"place": "suit", "idx": 0, "label": "Suit", "id": String(fit["suit"])}]
		for p in CD.PLACES:
			var k := String(p[0])
			if k == "suit":
				continue
			var arr: Array = fit.get(k, [])
			for i in arr.size():
				out.append({"place": k, "idx": i, "label": String(p[1]) + (" %d" % (i + 1) if arr.size() > 1 else ""), "id": String(arr[i])})
		return out

	## What may go into the place marked ("" first: nothing).
	func options() -> Array:
		var sl := slots()
		slot = clampi(slot, 0, sl.size() - 1)
		var o: Array = CD.options(String(sl[slot]["place"]))
		if String(sl[slot]["place"]) != "suit":
			o.push_front("")
		return o

	func slot_rect(i: int) -> Rect2:
		return Rect2(60.0, 190.0 + i * ROW, 540.0, ROW - 6.0)

	func opt_rect(i: int) -> Rect2:
		return Rect2(640.0, 190.0 + i * OPT, 520.0, OPT - 4.0)

	func shown() -> int:
		return int((get_viewport_rect().size.y - 190.0 - 150.0) / OPT)

	func mode_rect(i: int) -> Rect2:
		return Rect2(get_viewport_rect().size.x - 700.0, 190.0 + i * 66.0, 640.0, 58.0)

	## (Part 10, Luz) The modes of this room: the fights. Survivor has a room of its own (SvPrep).
	func modes() -> Array:
		return (CD.MODES as Array).filter(func(m): return String(m["id"]) != "survivor")

	func ready_rect() -> Rect2:
		var vs := get_viewport_rect().size
		return Rect2(vs.x - 400.0, vs.y - 150.0, 340.0, 84.0)

	## (part 5) Team Deathmatch: the rows of those who may stand beside you.
	func mate_rect(i: int) -> Rect2:
		return Rect2(get_viewport_rect().size.x - 684.0, 190.0 + modes().size() * 66.0 + 14.0 + 268.0 + i * 36.0, 608.0, 32.0)

	func pick_mate(i: int) -> void:
		var ms: Array = CD.mates(col())
		if i < 0 or i >= ms.size() or counting >= 0.0:
			return
		var e: String = Commands.execute({"type": "col_team", "seat": 0, "id": String(ms[i]["id"])})
		msg = e if e != "" else "Your team: %s." % ", ".join((CD.team(col()) as Array).map(func(m): return String(m["name"])))
		Audio.play("ui_error" if e != "" else "ui_click", "colosseum: the team")

	func mark(i: int) -> void:
		slot = clampi(i, 0, slots().size() - 1)
		scroll = 0
		opt_sel = 0
		Audio.play("ui_click", "colosseum: a place")

	## You pick option `i` for the place marked.
	func take(i: int) -> void:
		var o := options()
		if i < 0 or i >= o.size() or counting >= 0.0:
			return
		var sl: Dictionary = slots()[slot]
		var e: String = Commands.execute({"type": "col_equip", "seat": seat if two() else 0, "place": String(sl["place"]), "idx": int(sl["idx"]), "id": String(o[i])})
		msg = e if e != "" else "%s: %s." % [String(sl["label"]), CD.piece_name(String(o[i]))]
		Audio.play("ui_error" if e != "" else "ui_click", "colosseum: a piece")
		slot = clampi(slot, 0, slots().size() - 1)

	func pick_mode(i: int) -> void:
		if counting >= 0.0:
			return
		mode_sel = clampi(i, 0, modes().size() - 1)
		var e: String = Commands.execute({"type": "col_mode", "seat": 0, "mode": String(modes()[mode_sel]["id"])})
		msg = e if e != "" else String(modes()[mode_sel]["text"])
		Audio.play("ui_error" if e != "" else "ui_open", "colosseum: a mode")

	func go_ready() -> void:
		if counting >= 0.0:
			return
		var e: String = Commands.execute({"type": "col_ready", "seat": 0})
		if e != "":
			msg = e
			Audio.play("ui_error", "colosseum: not ready")
			return
		counting = COUNT
		_last = 6
		msg = "Ready. The gate to the arena opens."

	func back() -> void:
		if counting >= 0.0:
			if counting > 2.0:                                 # (the count may still be called off)
				counting = -1.0
				msg = "Called off. Press READY when you are."
				Audio.play("ui_close", "colosseum: called off")
			return
		finished.emit(false)

	func _process(dt: float) -> void:
		_t += dt
		if counting >= 0.0:
			counting -= dt
			var n := int(ceil(counting))
			if n != _last and n >= 1:
				_last = n
				Audio.play("ui_click", "colosseum: countdown")
			if counting <= 0.0:
				counting = 0.0
				white = minf(1.0, white + dt / 0.7)
				if white >= 1.0:
					set_process(false)
					finished.emit(true)
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN or mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				scroll = clampi(scroll + (3 if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN else -3), 0, maxi(0, options().size() - shown()))
				accept_event()
				return
			if mb.button_index != MOUSE_BUTTON_LEFT:
				return
			accept_event()
			if ready_rect().has_point(mb.position):
				go_ready()
				return
			if two():
				for si in 2:
					if seat_rect(si).has_point(mb.position):
						pick_seat(si)
						return
			for i in slots().size():
				if slot_rect(i).has_point(mb.position):
					col_focus = 0
					mark(i)
					return
			for i2 in mini(shown(), options().size() - scroll):
				if opt_rect(i2).has_point(mb.position):
					col_focus = 1
					opt_sel = scroll + i2
					take(scroll + i2)
					return
			for i3 in modes().size():
				if mode_rect(i3).has_point(mb.position):
					col_focus = 2
					pick_mode(i3)
					return
			if String(col().get("mode", "")) == "team":
				for i4 in (CD.mates(col()) as Array).size():
					if mate_rect(i4).has_point(mb.position):
						pick_mate(i4)
						return

	func _move(d: int) -> void:
		match col_focus:
			0:
				mark(slot + d)
			1:
				opt_sel = clampi(opt_sel + d, 0, options().size() - 1)
				scroll = clampi(scroll, maxi(0, opt_sel - shown() + 1), opt_sel)
			2:
				if d > 0 and mode_sel >= modes().size() - 1:
					col_focus = 3                                  # (down from the last mode: onto READY)
				else:
					mode_sel = clampi(mode_sel + d, 0, modes().size() - 1)
			3:
				if d < 0:
					col_focus = 2

	func _press() -> void:
		match col_focus:
			0:
				col_focus = 1
			1:
				take(opt_sel)
			2:
				pick_mode(mode_sel)
			3:
				go_ready()

	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("menu_back", false, true):
			get_viewport().set_input_as_handled()
			back()
		elif event is InputEventKey and event.pressed:
			var kc := (event as InputEventKey).keycode
			var used := true
			match kc:
				KEY_UP:
					_move(-1)
				KEY_DOWN:
					_move(1)
				KEY_LEFT:
					col_focus = maxi(0, col_focus - 1)
				KEY_RIGHT:
					col_focus = mini(3, col_focus + 1)
				KEY_ENTER, KEY_SPACE:
					if not (event as InputEventKey).echo:
						_press()
				KEY_R:
					if not (event as InputEventKey).echo:
						go_ready()
				KEY_TAB:
					if not (event as InputEventKey).echo:
						pick_seat(1 - seat)
				_:
					used = false
			if used:
				get_viewport().set_input_as_handled()

	## Package 80: with the controller the cross moves through the three columns, ✕ takes, △ is READY, ◯ goes back.
	func pad_button(b: String, pressed: bool) -> bool:
		if not pressed:
			return true
		match b:
			"up":
				_move(-1)
			"down":
				_move(1)
			"left":
				col_focus = maxi(0, col_focus - 1)
			"right":
				col_focus = mini(3, col_focus + 1)
			"cross":
				_press()
			"triangle", "square", "options":
				go_ready()
			"l1", "r1":
				pick_seat(1 - seat)                                  # split screen: the other player's fit
			"circle":
				back()
		return true

	func _draw() -> void:
		var vs := get_viewport_rect().size
		var font := ThemeDB.fallback_font
		var c := col()
		var fit: Dictionary = c[fit_key()]
		var used: int = CD.fit_cost(fit)
		var have: int = CD.budget(c)
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.03, 0.03, 0.07))
		for ln in 14:                                            # the room: lockers of light along the wall
			var lx := ln * vs.x / 13.0
			draw_rect(Rect2(lx - 1.0, 0.0, 2.0, vs.y), Color(NEON[ln % 4], 0.05 + 0.03 * sin(_t + ln)))
		draw_rect(Rect2(0.0, 120.0, vs.x, 2.0), Color(NEON[1], 0.5))
		draw_string(font, Vector2(60.0, 70.0), "THE FIGHTERS' ROOM", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 40, Color(1.0, 0.5, 0.8).lerp(Color(0.3, 0.9, 1.0), 0.5 + 0.5 * sin(_t * 1.5)))
		draw_string(font, Vector2(60.0, 104.0), "You fight with the house's gear, fitted from gear points.", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color(0.8, 0.85, 0.95))
		draw_string(font, Vector2(vs.x - 700.0, 76.0), "GEAR POINTS  %d of %d" % [used, have], HORIZONTAL_ALIGNMENT_RIGHT, 640.0, 34, Color(1.0, 0.85, 0.4))
		draw_string(font, Vector2(vs.x - 700.0, 104.0), "%d free" % (have - used), HORIZONTAL_ALIGNMENT_RIGHT, 640.0, 17, Color(0.5, 1.0, 0.6))
		var rk: Dictionary = CD.rank_state(c)                    # (part 4) your rank: it stays, whatever the mode
		draw_string(font, Vector2(vs.x * 0.5 - 150.0, 60.0), "RANK %d   ·   %s" % [int(rk["rank"]) + 1, String(rk["name"]).to_upper()], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color(0.5, 0.9, 1.0))
		var rb := Rect2(vs.x * 0.5 - 150.0, 72.0, 300.0, 10.0)
		draw_rect(rb, Color(0.1, 0.1, 0.18))
		draw_rect(Rect2(rb.position, Vector2(rb.size.x * float(rk["k"]), rb.size.y)), Color(0.5, 0.9, 1.0))
		draw_string(font, Vector2(rb.position.x, 104.0), "the house hands you quality %s at most" % String(CD.GearData.QUALITIES[int(CD.RANKS[int(rk["rank"])]["q"])]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14,
			Color(0.6, 0.65, 0.78))
		var mp := get_local_mouse_position()
		# ---- your gear
		draw_string(font, Vector2(60.0, 172.0), "YOUR GEAR" if not two() else "THE GEAR OF", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(1.0, 0.85, 0.4))
		if two():                                                # split screen: a fit each, the same gear points each
			for si in 2:
				var sr := seat_rect(si)
				var scol: Color = Color(0.3, 0.9, 1.0) if si == 0 else Color(1.0, 0.45, 0.85)
				draw_rect(sr, Color(scol.darkened(0.7), 0.9) if si == seat else Color(0.06, 0.06, 0.12, 0.9))
				draw_rect(sr, scol if si == seat else Color(scol, 0.35), false, 2.0)
				draw_string(font, sr.position + Vector2(10.0, 21.0), "P%d  %s" % [si + 1, String((GameState.pilot2 if si == 1 else GameState.pilot).get("name", "")).get_slice(" ", 0)],
					HORIZONTAL_ALIGNMENT_LEFT, sr.size.x - 16.0, 16, scol if si == seat else Color(scol, 0.6))
			draw_string(font, Vector2(60.0, vs.y - 132.0), "[Tab] or L1 / R1: the other player's fit. Each of you has the same gear points.", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(0.6, 0.65, 0.78))
		var sl := slots()
		for i in sl.size():
			var r := slot_rect(i)
			var s: Dictionary = sl[i]
			var id := String(s["id"])
			var on := i == slot
			draw_rect(r, Color(0.1, 0.08, 0.18) if on else Color(0.06, 0.05, 0.11))
			draw_rect(r, Color(NEON[1], 1.0) if on else (Color(NEON[3], 0.8) if r.has_point(mp) else Color(NEON[3], 0.35)), false, 3.0 if on and col_focus == 0 else 1.5)
			if id != "":
				draw_texture_rect(GearIcons.icon(id), Rect2(r.position.x + 8.0, r.position.y + 4.0, 36.0, 36.0), false)
			draw_string(font, r.position + Vector2(54.0, 18.0), String(s["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.6, 0.65, 0.78))
			draw_string(font, r.position + Vector2(54.0, 38.0), CD.piece_name(id), HORIZONTAL_ALIGNMENT_LEFT, 400.0, 18, Color(0.95, 0.96, 1.0) if id != "" else Color(0.45, 0.48, 0.58))
			draw_string(font, Vector2(r.end.x - 60.0, r.position.y + 30.0), "%d" % CD.cost(id) if id != "" else "", HORIZONTAL_ALIGNMENT_RIGHT, 48.0, 22, Color(1.0, 0.85, 0.4))
		var tt: Dictionary = CD.totals(fit)
		var sy := 190.0 + sl.size() * ROW + 16.0
		draw_string(font, Vector2(60.0, sy + 8.0), "Shield %d   ·   Armour %d   ·   Energy %d   ·   Ammunition %d   ·   Speed %d %%" % [int(tt["shield"]), int(tt["armor"]), int(tt["energy"]), int(tt["ammo"]),
			int(round(float(tt["speed"]) * 100.0))], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(0.8, 0.9, 1.0))
		# ---- the pieces for the place marked
		var o := options()
		draw_string(font, Vector2(640.0, 172.0), "THE HOUSE'S PIECES: %s" % String(sl[slot]["label"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(1.0, 0.85, 0.4))
		for k in mini(shown(), o.size() - scroll):
			var oi := scroll + k
			var orr := opt_rect(k)
			var oid := String(o[oi])
			var worn := oid == String(sl[slot]["id"])
			var after: int = used - maxi(0, CD.cost(String(sl[slot]["id"]))) + maxi(0, CD.cost(oid))
			var may: bool = CD.allowed(oid, c)                       # (part 4) not above what your rank reaches
			var can := after <= have and may
			var hot := orr.has_point(mp) or (col_focus == 1 and opt_sel == oi)
			draw_rect(orr, Color(0.12, 0.1, 0.2) if hot else Color(0.06, 0.05, 0.11))
			if worn:
				draw_rect(orr, Color(NEON[1], 0.9), false, 2.0)
			if oid != "":
				draw_texture_rect(GearIcons.icon(oid), Rect2(orr.position.x + 6.0, orr.position.y + 2.0, 26.0, 26.0), false, Color(1, 1, 1, 1.0 if can else 0.4))
			draw_string(font, orr.position + Vector2(42.0, 21.0), CD.piece_name(oid) if oid != "" else "Nothing", HORIZONTAL_ALIGNMENT_LEFT, 380.0, 16,
				(Color(0.95, 0.96, 1.0) if can else Color(0.5, 0.45, 0.5)))
			draw_string(font, Vector2(orr.end.x - 56.0, orr.position.y + 21.0), "%d" % maxi(0, CD.cost(oid)), HORIZONTAL_ALIGNMENT_RIGHT, 46.0, 17, Color(1.0, 0.85, 0.4) if can else Color(1.0, 0.45, 0.45))
			if not may:
				draw_string(font, Vector2(orr.end.x - 190.0, orr.position.y + 21.0), "higher rank", HORIZONTAL_ALIGNMENT_RIGHT, 120.0, 13, Color(0.5, 0.7, 0.9))
		if o.size() > shown():
			draw_string(font, Vector2(640.0, 190.0 + shown() * OPT + 16.0), "%d to %d of %d   ·   the wheel scrolls" % [scroll + 1, mini(o.size(), scroll + shown()), o.size()], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13,
				Color(0.6, 0.65, 0.78))
		# ---- the mode, the preview, READY
		draw_string(font, Vector2(vs.x - 700.0, 172.0), "THE MODE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(1.0, 0.85, 0.4))
		var picked := String(c.get("mode", ""))
		for mi in modes().size():
			var mr := mode_rect(mi)
			var md: Dictionary = modes()[mi]
			var mon := picked == String(md["id"])
			var mopen := bool(md["open"])
			draw_rect(mr, Color(0.1, 0.08, 0.18) if mon else Color(0.06, 0.05, 0.11))
			draw_rect(mr, Color(NEON[0], 1.0) if mon else Color(NEON[3], 0.8 if (mr.has_point(mp) or (col_focus == 2 and mode_sel == mi)) else 0.35), false, 3.0 if mon else 1.5)
			draw_string(font, mr.position + Vector2(16.0, 36.0), String(md["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color(1, 1, 1) if mopen else Color(0.45, 0.48, 0.58))
			if mopen and String(md["id"]) == "survivor":       # (part 7) no rounds there: your best time
				var bst := float((SV.record(c)["best"] as Dictionary).get(SV.cur_stage(c), 0.0))
				draw_string(font, Vector2(mr.end.x - 216.0, mr.position.y + 36.0), "Best %s" % SV.time_text(bst) if bst > 0.0 else "Not played yet", HORIZONTAL_ALIGNMENT_RIGHT, 200.0, 17, Color(0.8, 0.9, 1.0))
			elif mopen:                                         # (every mode has a run of its own: its round)
				var rnd := int(c.get("round", 1)) if mon else int(((c.get("runs", {}) as Dictionary).get(String(md["id"]), {}) as Dictionary).get("round", 1))
				draw_string(font, Vector2(mr.end.x - 216.0, mr.position.y + 36.0), "Round %d" % rnd, HORIZONTAL_ALIGNMENT_RIGHT, 200.0, 17, Color(0.8, 0.9, 1.0))
			else:
				draw_rect(Rect2(mr.end.x - 170.0, mr.position.y + 14.0, 154.0, 30.0), Color(1.0, 0.82, 0.25, 0.92))
				draw_string(font, Vector2(mr.end.x - 170.0, mr.position.y + 35.0), "COMING SOON", HORIZONTAL_ALIGNMENT_CENTER, 154.0, 15, Color(0.1, 0.07, 0.02))
		var teamed := picked == "team"
		var pv := Rect2(vs.x - 700.0, 190.0 + modes().size() * 66.0 + 14.0, 640.0, 380.0 + (90.0 if teamed else 0.0))
		draw_rect(pv, Color(0.05, 0.04, 0.1))
		draw_rect(pv, Color(NEON[1], 0.5), false, 1.5)
		if picked == "" or picked == "survivor":
			draw_string(font, pv.position + Vector2(0.0, 190.0), "Pick a mode to see who waits in the arena.", HORIZONTAL_ALIGNMENT_CENTER, pv.size.x, 18, Color(0.6, 0.65, 0.78))
		else:
			draw_string(font, pv.position + Vector2(16.0, 30.0), "WHO WAITS IN THE ARENA", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(1.0, 0.85, 0.4))
			var foes: Array = CD.opponents(int(c.get("round", 1)), CG.FIGHTERS.size(), int(c.get("fights", 0)), picked)
			var sett: Dictionary = CD.setting(int(c.get("round", 1)), int(c.get("fights", 0)))
			draw_string(font, Vector2(pv.end.x - 436.0, pv.position.y + 30.0), "the ground: %s" % String(sett["name"]), HORIZONTAL_ALIGNMENT_RIGHT, 420.0, 15, Color(0.5, 0.9, 1.0))
			draw_string(font, Vector2(pv.position.x + 16.0, pv.position.y + 264.0), String(sett["danger"]), HORIZONTAL_ALIGNMENT_LEFT, pv.size.x - 32.0, 14, Color(1.0, 0.6, 0.4))
			for fi in foes.size():
				var fo: Dictionary = foes[fi]
				var fd: Dictionary = CG.foe_card(fo)
				var fx := pv.position.x + 24.0 + fi * 204.0
				var strong := bool(fo["strong"])
				var tex: Texture2D = fd["tex"]
				var th := 150.0 if strong else 120.0
				draw_rect(Rect2(fx, pv.position.y + 44.0, 184.0, 204.0), Color(0.08, 0.06, 0.14))
				draw_rect(Rect2(fx, pv.position.y + 44.0, 184.0, 204.0), Color(1.0, 0.85, 0.3) if int(fo["boss"]) >= 0 else (Color(1.0, 0.35, 0.35) if strong else Color(0.4, 1.0, 0.6)), false, 4.0 if int(fo["boss"]) >= 0 else 2.0)
				draw_texture_rect(tex, Rect2(fx + 92.0 - th * 0.5 * tex.get_width() / tex.get_height(), pv.position.y + 204.0 - th, th * tex.get_width() / tex.get_height(), th), false)
				draw_string(font, Vector2(fx, pv.position.y + 224.0), String(fd["name"]), HORIZONTAL_ALIGNMENT_CENTER, 184.0, 17, Color(fd["col"]).lightened(0.3))
				draw_string(font, Vector2(fx, pv.position.y + 242.0), "the named one" if int(fo["boss"]) >= 0 else ("strong" if strong else "weak"), HORIZONTAL_ALIGNMENT_CENTER, 184.0, 14,
					Color(1.0, 0.85, 0.4) if int(fo["boss"]) >= 0 else (Color(1.0, 0.45, 0.45) if strong else Color(0.5, 1.0, 0.6)))
			var dy := 0.0
			if teamed:                                             # your team: click a row to send one away or call one in
				dy = 90.0
				var ms: Array = CD.mates(c)
				var mine: Array = (CD.team(c) as Array).map(func(m): return String(m["id"]))
				draw_string(font, pv.position + Vector2(16.0, 288.0), "WHO STANDS BESIDE YOU  (%d of %d)" % [mine.size(), CD.TEAM_SIZE], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(1.0, 0.85, 0.4))
				for mi2 in ms.size():
					var mr2 := mate_rect(mi2)
					mr2.position.y += 30.0
					var mm: Dictionary = ms[mi2]
					var inn := String(mm["id"]) in mine
					draw_rect(mr2, Color(0.1, 0.14, 0.2) if inn else Color(0.06, 0.05, 0.11))
					draw_rect(mr2, Color(0.4, 1.0, 0.7) if inn else Color(NEON[3], 0.8 if mr2.has_point(mp) else 0.35), false, 2.0 if inn else 1.0)
					draw_string(font, mr2.position + Vector2(10.0, 22.0), ("✓  " if inn else "    ") + String(mm["name"]), HORIZONTAL_ALIGNMENT_LEFT, 240.0, 16,
						Color(1.0, 0.82, 0.3) if String(mm.get("who", "")) != "" else Color(0.95, 0.96, 1.0))
					draw_string(font, mr2.position + Vector2(210.0, 22.0), "quality %s   ·   %s" % [CD.mate_quality(mm, c), String(mm.get("text", ""))], HORIZONTAL_ALIGNMENT_LEFT, mr2.size.x - 216.0, 13,
						Color(0.75, 0.8, 0.92))
			draw_string(font, pv.position + Vector2(16.0, 284.0 + dy + (30.0 if teamed else 0.0)), "YOUR RECORD" if not teamed else "", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(1.0, 0.85, 0.4))
			draw_string(font, pv.position + Vector2(16.0, 310.0 + dy + (16.0 if teamed else 0.0)), "%d wins in a row   ·   best run %d   ·   %d wins in %d fights" % [int(c.get("streak", 0)), int(c.get("best", 0)), int(c.get("wins", 0)), int(c.get("fights", 0))],
				HORIZONTAL_ALIGNMENT_LEFT, pv.size.x - 32.0, 17, Color(0.9, 0.93, 1.0))
			var rw: Dictionary = CD.reward(int(c.get("round", 1)), picked)
			draw_string(font, pv.position + Vector2(16.0, 346.0 + dy + (8.0 if teamed else 0.0)), "A win pays %d Coins, %d gear points and %d rank points." % [int(rw["coins"]), int(rw["points"]), int(rw["xp"])], HORIZONTAL_ALIGNMENT_LEFT, pv.size.x - 32.0, 17, Color(0.5, 1.0, 0.6))
		var rr := ready_rect()
		var okr := picked != "" and picked != "survivor" and counting < 0.0
		draw_rect(rr, Color(0.1, 0.3, 0.18) if okr else Color(0.08, 0.08, 0.12))
		for g in 3:
			draw_rect(rr.grow(g * 4.0), Color(0.4, 1.0, 0.6, (0.9 - g * 0.3) * (0.6 + 0.4 * absf(sin(_t * 3.0)) if okr else 0.25)), false, 3.0)
		draw_string(font, Vector2(rr.position.x, rr.position.y + 54.0), "READY  (R)", HORIZONTAL_ALIGNMENT_CENTER, rr.size.x, 34, Color(1, 1, 1) if okr else Color(0.45, 0.48, 0.58))
		if col_focus == 3:                                      # (the controller stands on it)
			SU.brackets(self, rr.grow(16.0), Color(1, 1, 1), 26.0, 4.0)
		draw_string(font, Vector2(60.0, vs.y - 96.0), msg, HORIZONTAL_ALIGNMENT_LEFT, vs.x - 520.0, 19, Color(1.0, 0.95, 0.6))
		draw_string(font, Vector2(60.0, vs.y - 60.0), "Esc: back to the choice of the mode", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(0.6, 0.65, 0.78))
		# ---- the countdown, the picture going white
		if counting >= 0.0:
			draw_rect(Rect2(Vector2.ZERO, vs), Color(0.02, 0.02, 0.05, 0.72))
			var n := int(ceil(counting))
			if n >= 1:
				var k := counting - floorf(counting)
				draw_arc(vs * 0.5, 190.0, -PI * 0.5, -PI * 0.5 + TAU * (counting / COUNT), 64, Color(NEON[1], 0.9), 10.0)
				draw_string(font, Vector2(0.0, vs.y * 0.5 + 90.0 + (1.0 - k) * 10.0), "%d" % n, HORIZONTAL_ALIGNMENT_CENTER, vs.x, int(220.0 + 60.0 * k), Color(1, 1, 1, 0.5 + 0.5 * k))
				draw_string(font, Vector2(0.0, vs.y * 0.5 + 260.0), "The gate to the arena opens" + ("   ·   Esc calls it off" if counting > 2.0 else ""), HORIZONTAL_ALIGNMENT_CENTER, vs.x, 22, Color(1.0, 0.85, 0.4))
			draw_rect(Rect2(Vector2.ZERO, vs), Color(1, 1, 1, white))


## Part 10 (Luz, 24 Nov 2026): behind the fighters' gate you choose first: the fights (the fighters' room, `Prep`) or
## Survivor (its own room, `SvPrep`). Two large tiles. `picked`: "match" | "survivor" ("": you went back to the lobby).
class Choose extends Control:
	signal finished(won: bool)
	var sel := 0
	var picked := ""
	var _t := 0.0

	func is_col_choose() -> bool:
		return true

	func setup(_cfg: Dictionary) -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		sel = 1 if String(GameState.col_state().get("mode", "")) == "survivor" else 0

	func tiles() -> Array:
		var vs := get_viewport_rect().size
		var w := 660.0
		return [Rect2(vs.x * 0.5 - w - 34.0, vs.y * 0.5 - 250.0, w, 540.0), Rect2(vs.x * 0.5 + 34.0, vs.y * 0.5 - 250.0, w, 540.0)]

	func pick(i: int) -> void:
		sel = clampi(i, 0, 1)
		picked = "match" if sel == 0 else "survivor"
		Audio.play("ui_open", "colosseum: match or survivor")
		finished.emit(true)

	func back() -> void:
		picked = ""
		finished.emit(false)

	func _process(dt: float) -> void:
		_t += dt
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			var ts0 := tiles()
			for i0 in 2:
				if (ts0[i0] as Rect2).has_point((event as InputEventMouseMotion).position):
					sel = i0
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			var ts := tiles()
			for i in 2:
				if (ts[i] as Rect2).has_point((event as InputEventMouseButton).position):
					pick(i)
					accept_event()
					return

	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("menu_back", false, true):
			get_viewport().set_input_as_handled()
			back()
		elif event is InputEventKey and event.pressed and not event.echo:
			var kc := (event as InputEventKey).keycode
			if kc in [KEY_LEFT, KEY_RIGHT, KEY_A, KEY_D]:
				sel = 1 - sel
				get_viewport().set_input_as_handled()
			elif kc in [KEY_ENTER, KEY_SPACE, KEY_E]:
				get_viewport().set_input_as_handled()
				pick(sel)

	func pad_button(b: String, pressed: bool) -> bool:
		if not pressed:
			return true
		match b:
			"left", "right":
				sel = 1 - sel
			"cross":
				pick(sel)
			"circle":
				back()
		return true

	func _draw() -> void:
		var vs := get_viewport_rect().size
		var font := ThemeDB.fallback_font
		var c: Dictionary = GameState.col_state()
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.03, 0.02, 0.07, 0.97))
		for ln in 14:
			draw_rect(Rect2(ln * vs.x / 13.0 - 1.0, 0.0, 2.0, vs.y), Color(NEON[ln % 4], 0.05 + 0.03 * sin(_t + ln)))
		draw_string(font, Vector2(0.0, vs.y * 0.5 - 340.0), "BEHIND THE FIGHTERS' GATE", HORIZONTAL_ALIGNMENT_CENTER, vs.x, 50, Color(1.0, 0.5, 0.8).lerp(Color(0.3, 0.9, 1.0), 0.5 + 0.5 * sin(_t * 1.5)))
		draw_string(font, Vector2(0.0, vs.y * 0.5 - 296.0), "What do you want to play?", HORIZONTAL_ALIGNMENT_CENTER, vs.x, 22, Color(1.0, 0.85, 0.4))
		var ts := tiles()
		for i in 2:
			var r: Rect2 = ts[i]
			var hot := sel == i
			var col: Color = NEON[0] if i == 0 else Color(0.4, 1.0, 0.6)
			if hot:
				r = r.grow(8.0)
			draw_rect(r, Color(col.r * 0.1, col.g * 0.1, col.b * 0.12) if hot else Color(0.05, 0.05, 0.1))
			for g in 3:
				draw_rect(r.grow(g * 6.0), Color(col, (0.9 - g * 0.28) * (1.0 if hot else 0.45)), false, 3.0)
			SU.brackets(self, r.grow(4.0), Color(col, 1.0 if hot else 0.6), 34.0, 5.0)
			var mc := r.position + Vector2(r.size.x * 0.5, 150.0)
			if i == 0:                                           # the fights: you, "VS", the three who wait
				draw_circle(mc + Vector2(-150.0, -40.0), 22.0, col)
				draw_rect(Rect2(mc.x - 176.0, mc.y - 12.0, 52.0, 72.0), col)
				draw_string(font, Vector2(mc.x - 60.0, mc.y + 26.0), "VS", HORIZONTAL_ALIGNMENT_CENTER, 120.0, 54, Color(1, 1, 1))
				for q in 3:
					var fx := mc.x + 96.0 + q * 62.0
					var big := 1.25 if q == 1 else 1.0
					draw_circle(Vector2(fx, mc.y - 30.0 * big - 8.0), 17.0 * big, col.darkened(0.2))
					draw_rect(Rect2(fx - 20.0 * big, mc.y - 10.0 * big, 40.0 * big, 56.0 * big + (14.0 if q == 1 else 0.0)), col.darkened(0.2))
			else:                                                # Survivor: you in the middle, the swarm all round
				draw_circle(mc + Vector2(0.0, -40.0), 22.0, Color(1, 1, 1))
				draw_rect(Rect2(mc.x - 26.0, mc.y - 12.0, 52.0, 72.0), Color(1, 1, 1))
				draw_arc(mc + Vector2(0.0, 6.0), 84.0 + 6.0 * sin(_t * 4.0), 0.0, TAU, 48, Color(0.4, 0.92, 1.0, 0.8), 3.0)
				for q2 in 46:
					var a := q2 * 2.399 + _t * 0.15
					var rr := 130.0 + 110.0 * fposmod(q2 * 0.618, 1.0) - fposmod(_t * 14.0 + q2 * 7.0, 60.0) * 0.5
					draw_rect(Rect2(mc + Vector2(cos(a) * rr * 1.25, sin(a) * rr * 0.55 + 6.0) - Vector2(5.0, 9.0), Vector2(10.0, 18.0)), Color(col, 0.85))
			draw_string(font, Vector2(r.position.x, r.position.y + 312.0), "MATCH MODE" if i == 0 else "SURVIVOR MODE", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 46, Color(1, 1, 1))
			draw_multiline_string(font, Vector2(r.position.x + 60.0, r.position.y + 350.0),
				"Fights in rounds against the arena's fighters, in the house's gear, fitted from gear points." if i == 0
				else "Alone against swarms without end. Your weapons fire by themselves: you walk, you dodge, you take the shards.",
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 120.0, 18, 3, Color(0.82, 0.87, 0.96))
			var ly := r.position.y + 432.0
			if i == 0:
				for md in CD.MODES:
					if String(md["id"]) == "survivor":
						continue
					var rnd := int(c.get("round", 1)) if String(c.get("mode", "")) == String(md["id"]) else int(((c.get("runs", {}) as Dictionary).get(String(md["id"]), {}) as Dictionary).get("round", 1))
					draw_string(font, Vector2(r.position.x + 90.0, ly), String(md["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, col.lightened(0.35))
					draw_string(font, Vector2(r.end.x - 290.0, ly), "Round %d" % rnd, HORIZONTAL_ALIGNMENT_RIGHT, 200.0, 20, Color(0.9, 0.93, 1.0))
					ly += 32.0
			else:
				var rec: Dictionary = SV.record(c)
				var stg: Dictionary = SV.stage(SV.cur_stage(c))
				var bst := float((rec["best"] as Dictionary).get(String(stg["id"]), 0.0))
				draw_string(font, Vector2(r.position.x + 90.0, ly), "Stage: %s" % String(stg["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, col.lightened(0.35))
				draw_string(font, Vector2(r.end.x - 390.0, ly), ("Best %s" % SV.time_text(bst)) if bst > 0.0 else "Not played yet", HORIZONTAL_ALIGNMENT_RIGHT, 300.0, 20, Color(0.9, 0.93, 1.0))
				draw_string(font, Vector2(r.position.x + 90.0, ly + 32.0), "%d runs" % int(rec["runs"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, col.lightened(0.35))
				draw_string(font, Vector2(r.end.x - 390.0, ly + 32.0), "%d cores" % int(rec["cores"]), HORIZONTAL_ALIGNMENT_RIGHT, 300.0, 20, Color(0.6, 0.95, 1.0))
		draw_string(font, Vector2(0.0, vs.y - 60.0), "Click a tile, or left and right and Enter   ·   Esc: back to the lobby", HORIZONTAL_ALIGNMENT_CENTER, vs.x, 16, Color(0.6, 0.65, 0.78))


## Part 10 (Luz, 24 Nov 2026): Survivor's own room. All that the fighters' room showed of it, with room to spare: the
## stages as large tiles and, under them, what the one marked is made of (its dangers, who comes from when, its
## bosses, your best time, what opens it); the weapons you can begin with as large tiles and, under them, what the one
## marked does in words and in figures and what it fuses into; your record and your cores; READY. Every choice goes
## through the command bus (sv_stage, sv_weapon, col_ready). The controller: the cross moves through the stages, the
## weapons and READY; ✕ takes, △ is READY, ◯ goes back.
class SvPrep extends Control:
	signal finished(won: bool)
	const SArt = preload("res://scripts/ground/survivor_art.gd")
	const COUNT := 5.0
	const PER_ROW := 5
	var focus := 0                   # 0 the stages, 1 the weapons, 2 READY
	var st_sel := 0                  # the stage marked (what is shown under the tiles)
	var w_sel := 0                   # the weapon marked
	var counting := -1.0
	var white := 0.0
	var msg := "Pick a stage and the weapon you begin with, then press READY."
	var _t := 0.0
	var _last := 6
	var seat := 0                    # split screen: whose first weapon is being picked (0 you, 1 the second player)

	func is_col_prep() -> bool:
		return true

	func is_sv_prep() -> bool:
		return true

	func two() -> bool:
		return Players.split and GameState.has_pilot2()

	func seat_rect(i: int) -> Rect2:
		return Rect2(get_viewport_rect().size.x - 810.0 + 250.0 + i * 180.0, 140.0, 170.0, 28.0)

	## The weapon one of you begins with.
	func weapon_of(i: int) -> String:
		return SV.second_weapon(col()) if i == 1 else SV.first_weapon(col())

	## Split screen: the other player's first weapon.
	func pick_seat(i: int) -> void:
		if not two() or counting >= 0.0:
			return
		seat = clampi(i, 0, 1)
		w_sel = maxi(0, (SV.WEAPON_ORDER as Array).find(weapon_of(seat)))
		msg = "%s: pick the weapon to begin with." % String((GameState.pilot2 if seat == 1 else GameState.pilot).get("name", "")).get_slice(" ", 0)
		Audio.play("ui_click", "survivor: whose first weapon")

	func setup(_cfg: Dictionary) -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		for i in SV.STAGES.size():
			if String(SV.STAGES[i]["id"]) == SV.cur_stage(col()):
				st_sel = i
		w_sel = maxi(0, (SV.WEAPON_ORDER as Array).find(SV.first_weapon(col())))

	func col() -> Dictionary:
		return GameState.col_state()

	func sv_stage_rect(i: int) -> Rect2:
		return Rect2(60.0 + i * 262.0, 176.0, 248.0, 116.0)

	func sv_weapon_rect(i: int) -> Rect2:
		var x0 := get_viewport_rect().size.x - 810.0
		return Rect2(x0 + (i % PER_ROW) * 150.0, 176.0 + (i / PER_ROW) * 100.0, 142.0, 92.0)

	func ready_rect() -> Rect2:
		var vs := get_viewport_rect().size
		return Rect2(vs.x - 400.0, vs.y - 150.0, 340.0, 84.0)

	func pick_sv_stage(i: int) -> void:
		if i < 0 or i >= SV.STAGES.size() or counting >= 0.0:
			return
		st_sel = i
		var e: String = Commands.execute({"type": "sv_stage", "seat": 0, "id": String(SV.STAGES[i]["id"])})
		msg = e if e != "" else "The stage: %s." % String(SV.STAGES[i]["name"])
		Audio.play("ui_error" if e != "" else "ui_click", "survivor: the stage")

	func pick_sv_weapon(i: int) -> void:
		if i < 0 or i >= SV.WEAPON_ORDER.size() or counting >= 0.0:
			return
		w_sel = i
		var st2: bool = two() and seat == 1
		var e: String = Commands.execute({"type": "sv_weapon", "seat": 1 if st2 else 0, "id": String(SV.WEAPON_ORDER[i])})
		msg = e if e != "" else ("%s begins with: %s." % [String(GameState.pilot2.get("name", "")).get_slice(" ", 0), String(SV.WEAPONS[String(SV.WEAPON_ORDER[i])]["name"])] if st2
			else "You begin with: %s." % String(SV.WEAPONS[String(SV.WEAPON_ORDER[i])]["name"]))
		Audio.play("ui_error" if e != "" else "ui_click", "survivor: the first weapon")

	func go_ready() -> void:
		if counting >= 0.0:
			return
		var e: String = Commands.execute({"type": "col_ready", "seat": 0})
		if e != "":
			msg = e
			Audio.play("ui_error", "colosseum: not ready")
			return
		counting = COUNT
		_last = 6
		msg = "Ready. The gate to the arena opens."

	func back() -> void:
		if counting >= 0.0:
			if counting > 2.0:
				counting = -1.0
				msg = "Called off. Press READY when you are."
				Audio.play("ui_close", "colosseum: called off")
			return
		finished.emit(false)

	func _process(dt: float) -> void:
		_t += dt
		if counting >= 0.0:
			counting -= dt
			var n := int(ceil(counting))
			if n != _last and n >= 1:
				_last = n
				Audio.play("ui_click", "colosseum: countdown")
			if counting <= 0.0:
				counting = 0.0
				white = minf(1.0, white + dt / 0.7)
				if white >= 1.0:
					set_process(false)
					finished.emit(true)
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			var mb := event as InputEventMouseButton
			accept_event()
			if ready_rect().has_point(mb.position):
				go_ready()
				return
			if two():
				for si in 2:
					if seat_rect(si).has_point(mb.position):
						pick_seat(si)
						return
			for i in SV.STAGES.size():
				if sv_stage_rect(i).has_point(mb.position):
					focus = 0
					pick_sv_stage(i)
					return
			for i2 in SV.WEAPON_ORDER.size():
				if sv_weapon_rect(i2).has_point(mb.position):
					focus = 1
					pick_sv_weapon(i2)
					return

	## The cross of the controller, the arrow keys: within the stages and the weapons; right out of the stages into
	## the weapons, down out of the weapons onto READY.
	func move(d: Vector2i) -> void:
		if counting >= 0.0:
			return
		var wn := SV.WEAPON_ORDER.size()
		match focus:
			0:
				if d.x != 0:
					if st_sel + d.x >= SV.STAGES.size():
						focus = 1
					else:
						st_sel = clampi(st_sel + d.x, 0, SV.STAGES.size() - 1)
				elif d.y > 0:
					focus = 2
			1:
				if d.x != 0:
					if d.x < 0 and w_sel % PER_ROW == 0:
						focus = 0
					else:
						w_sel = clampi(w_sel + d.x, 0, wn - 1)
				elif d.y < 0 and w_sel >= PER_ROW:
					w_sel -= PER_ROW
				elif d.y > 0:
					if w_sel + PER_ROW < wn:
						w_sel += PER_ROW
					else:
						focus = 2
			2:
				if d.y < 0 or d.x < 0:
					focus = 1 if d.y < 0 else 0

	## ✕ or Enter: takes what is marked and goes on (Luz, 24 Nov 2026): from the stage to the weapons, from the weapon
	## to READY. What cannot be taken (a stage still shut, a weapon still locked) keeps you where you are.
	func press() -> void:
		match focus:
			0:
				pick_sv_stage(st_sel)
				if SV.cur_stage(col()) == String(SV.STAGES[st_sel]["id"]):
					focus = 1
			1:
				pick_sv_weapon(w_sel)
				if SV.first_weapon(col()) == String(SV.WEAPON_ORDER[w_sel]):
					focus = 2
			2:
				go_ready()

	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("menu_back", false, true):
			get_viewport().set_input_as_handled()
			back()
		elif event is InputEventKey and event.pressed:
			var kc := (event as InputEventKey).keycode
			var used := true
			match kc:
				KEY_UP:
					move(Vector2i(0, -1))
				KEY_DOWN:
					move(Vector2i(0, 1))
				KEY_LEFT:
					move(Vector2i(-1, 0))
				KEY_RIGHT:
					move(Vector2i(1, 0))
				KEY_ENTER, KEY_SPACE:
					if not (event as InputEventKey).echo:
						press()
				KEY_R:
					if not (event as InputEventKey).echo:
						go_ready()
				KEY_TAB:
					if not (event as InputEventKey).echo:
						pick_seat(1 - seat)
				_:
					used = false
			if used:
				get_viewport().set_input_as_handled()

	func pad_button(b: String, pressed: bool) -> bool:
		if not pressed:
			return true
		match b:
			"up":
				move(Vector2i(0, -1))
			"down":
				move(Vector2i(0, 1))
			"left":
				move(Vector2i(-1, 0))
			"right":
				move(Vector2i(1, 0))
			"cross":
				press()
			"triangle", "square", "options":
				go_ready()
			"l1", "r1":
				pick_seat(1 - seat)                                  # split screen: the other player's first weapon
			"circle":
				back()
		return true

	## (Part 10b) Where your rig is shown: in the stage's panel, under "what else".
	func rig_rect() -> Rect2:
		var vs := get_viewport_rect().size
		return Rect2(560.0, vs.y - 176.0 - 132.0, 518.0, 116.0)

	## One of those who come, as a small card: its picture, its name, from when.
	func _foe_card(at: Vector2, kind: String, when: String, tint: Color, wide: float) -> void:
		var font := ThemeDB.fallback_font
		var r := Rect2(at, Vector2(wide, 132.0))
		draw_rect(r, Color(0.06, 0.06, 0.12))
		draw_rect(r, Color(tint, 0.5), false, 1.0)
		var tex: Texture2D = SArt.texture(kind, 0, 0, 0)
		var k := minf(2.0, minf(84.0 / tex.get_height(), (wide - 12.0) / tex.get_width()))
		var sz := Vector2(tex.get_width(), tex.get_height()) * k
		draw_texture_rect(tex, Rect2(r.position.x + (wide - sz.x) * 0.5, r.position.y + 90.0 - sz.y, sz.x, sz.y), false)
		draw_string(font, r.position + Vector2(2.0, 108.0), String(SV.FOES[kind]["name"]), HORIZONTAL_ALIGNMENT_CENTER, wide - 4.0, 13, Color(0.95, 0.96, 1.0))
		draw_string(font, r.position + Vector2(2.0, 125.0), when, HORIZONTAL_ALIGNMENT_CENTER, wide - 4.0, 12, tint.lightened(0.3))

	func _draw() -> void:
		var vs := get_viewport_rect().size
		var font := ThemeDB.fallback_font
		var c := col()
		var rec: Dictionary = SV.record(c)
		var gold := Color(1.0, 0.85, 0.4)
		var green := Color(0.4, 1.0, 0.6)
		var mp := get_local_mouse_position()
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.02, 0.035, 0.06))
		for gx in range(0, int(vs.x), 64):
			draw_line(Vector2(gx, 0.0), Vector2(gx, vs.y), Color(green, 0.03), 1.0)
		for gy in range(0, int(vs.y), 64):
			draw_line(Vector2(0.0, gy), Vector2(vs.x, gy), Color(green, 0.03), 1.0)
		draw_rect(Rect2(0.0, 120.0, vs.x, 2.0), Color(green, 0.5))
		draw_string(font, Vector2(60.0, 70.0), "SURVIVOR", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 44, green.lerp(Color(0.3, 0.9, 1.0), 0.5 + 0.5 * sin(_t * 1.5)))
		draw_string(font, Vector2(60.0, 104.0), "Alone against swarms without end. No gear: your weapons and boni come from the run itself, level by level.", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color(0.8, 0.85, 0.95))
		SU.icon(self, "core", Vector2(vs.x - 232.0, 58.0), 11.0, Color(0.4, 0.92, 1.0))
		draw_string(font, Vector2(vs.x - 210.0, 68.0), "%d cores" % int(rec["cores"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 28, Color(0.6, 0.95, 1.0))
		draw_string(font, Vector2(vs.x - 660.0, 104.0), "%d runs   ·   %d put out in all   ·   the console in the lobby unlocks more" % [int(rec["runs"]), int(rec["kills"])], HORIZONTAL_ALIGNMENT_RIGHT, 600.0, 14,
			Color(0.7, 0.76, 0.88))
		# ---- the stages
		draw_string(font, Vector2(60.0, 160.0), "THE STAGE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, gold)
		draw_string(font, Vector2(804.0, 160.0), "%s to hold out" % SV.time_text(SV.RUN_TIME), HORIZONTAL_ALIGNMENT_RIGHT, 290.0, 15, Color(0.8, 0.9, 1.0))
		for si in SV.STAGES.size():
			var sd: Dictionary = SV.STAGES[si]
			var sr := sv_stage_rect(si)
			var sopen := bool(sd["open"])
			var smine: bool = sopen and SV.stage_open(c, String(sd["id"]))
			var son: bool = smine and SV.cur_stage(c) == String(sd["id"])
			var smark := si == st_sel
			var own: Color = sd.get("col", Color(0.5, 1.0, 0.6))
			var scol := own if son else (Color(0.62, 0.68, 0.8) if smine else Color(0.45, 0.5, 0.62))
			draw_rect(sr, Color(own.r * 0.14, own.g * 0.14, own.b * 0.14) if son else (Color(0.08, 0.08, 0.14) if (sr.has_point(mp) or smark) else Color(0.05, 0.05, 0.1)))
			draw_rect(sr, Color(scol, 1.0 if son else 0.5), false, 3.0 if son else 1.0)
			if smark:
				SU.brackets(self, sr.grow(5.0), Color(1, 1, 1) if focus == 0 else Color(scol, 0.9), 16.0, 3.0)
			if sopen:
				draw_string(font, sr.position + Vector2(0.0, 44.0), String(sd["name"]).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, sr.size.x, 24, Color(1, 1, 1) if smine else Color(0.55, 0.58, 0.68))
				if smine:
					var bst := float((rec["best"] as Dictionary).get(String(sd["id"]), 0.0))
					draw_string(font, sr.position + Vector2(0.0, 72.0), ("best %s" % SV.time_text(bst)) if bst > 0.0 else "not played yet", HORIZONTAL_ALIGNMENT_CENTER, sr.size.x, 14, Color(0.7, 0.95, 0.8))
					if son:
						draw_string(font, sr.position + Vector2(0.0, 98.0), "YOUR NEXT RUN", HORIZONTAL_ALIGNMENT_CENTER, sr.size.x, 12, own)
				else:
					SU.icon(self, "lock", sr.position + Vector2(sr.size.x - 18.0, 16.0), 6.0, Color(scol, 0.8))
					draw_string(font, sr.position + Vector2(0.0, 72.0), "after %s" % String(SV.FOES.get(String(sd.get("need", "")), {}).get("name", "the stage before")), HORIZONTAL_ALIGNMENT_CENTER, sr.size.x, 14,
						Color(1.0, 0.82, 0.25, 0.9))
			else:
				SU.icon(self, "lock", sr.position + Vector2(sr.size.x * 0.5, 40.0), 11.0, Color(scol, 0.7))
				draw_string(font, sr.position + Vector2(0.0, 84.0), "COMING SOON", HORIZONTAL_ALIGNMENT_CENTER, sr.size.x, 14, Color(1.0, 0.82, 0.25, 0.9))
		# ---- what the stage marked is made of
		var sp := Rect2(60.0, 306.0, 1034.0, vs.y - 306.0 - 176.0)
		var md: Dictionary = SV.STAGES[st_sel]
		var mcol: Color = md.get("col", Color(0.62, 0.68, 0.8))
		draw_rect(sp, Color(0.04, 0.05, 0.09))
		draw_rect(sp, Color(mcol, 0.5), false, 1.5)
		if not bool(md["open"]):
			draw_string(font, sp.position + Vector2(0.0, sp.size.y * 0.5), "This stage is still to come.", HORIZONTAL_ALIGNMENT_CENTER, sp.size.x, 20, Color(0.6, 0.65, 0.78))
		else:
			var data: Dictionary = SV.stage_data(String(md["id"]))
			draw_string(font, sp.position + Vector2(20.0, 42.0), String(md["name"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 32, mcol)
			draw_string(font, sp.position + Vector2(20.0, 70.0), String(md["text"]), HORIZONTAL_ALIGNMENT_LEFT, sp.size.x - 40.0, 16, Color(0.85, 0.9, 0.97))
			if not SV.stage_open(c, String(md["id"])):
				draw_string(font, Vector2(sp.end.x - 620.0, sp.position.y + 40.0), "Opens once you have %s." % String(md.get("need_text", "come further")), HORIZONTAL_ALIGNMENT_RIGHT, 600.0, 15, Color(1.0, 0.82, 0.25))
			var dx := sp.position.x + 20.0
			for dg in data["dangers"]:
				var dw := font.get_string_size(String(dg), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14).x + 40.0
				draw_rect(Rect2(dx, sp.position.y + 86.0, dw, 28.0), Color(1.0, 0.42, 0.42, 0.14))
				draw_rect(Rect2(dx, sp.position.y + 86.0, dw, 28.0), Color(1.0, 0.42, 0.42, 0.7), false, 1.0)
				draw_colored_polygon(PackedVector2Array([Vector2(dx + 9.0, sp.position.y + 107.0), Vector2(dx + 16.0, sp.position.y + 93.0), Vector2(dx + 23.0, sp.position.y + 107.0)]), Color(1.0, 0.42, 0.42))
				draw_string(font, Vector2(dx + 30.0, sp.position.y + 106.0), String(dg), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(1.0, 0.8, 0.78))
				dx += dw + 10.0
			draw_string(font, sp.position + Vector2(20.0, 146.0), "WHO COMES", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, gold)
			var comers: Array = [[String(data["swarm"]), "from the start"]]
			for w in data["waves"]:
				comers.append([String(w["kind"]), "from %s" % SV.time_text(float(w["from"]))])
			if String(data["flock"]) != "":
				comers.append([String(data["flock"]), "flies through"])
			var cw := minf(140.0, (sp.size.x - 40.0 - (comers.size() - 1) * 8.0) / comers.size())
			for q in comers.size():
				_foe_card(sp.position + Vector2(20.0 + q * (cw + 8.0), 156.0), String(comers[q][0]), String(comers[q][1]), mcol, cw)
			draw_string(font, sp.position + Vector2(20.0, 322.0), "ITS BOSSES", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, gold)
			var bosses: Array = []
			if String(data["soft"]) != "":
				bosses.append([String(data["soft"]), "at %s" % SV.time_text(SV.SOFT_BOSS)])
			if String(data["end"]) != "":
				bosses.append([String(data["end"]), "at %s, the last one" % SV.time_text(SV.RUN_TIME)])
			if bosses.is_empty():
				draw_string(font, sp.position + Vector2(20.0, 352.0), "None yet: hold out to the end and the stage is held.", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(0.7, 0.76, 0.88))
			for q2 in bosses.size():
				_foe_card(sp.position + Vector2(20.0 + q2 * 228.0, 332.0), String(bosses[q2][0]), String(bosses[q2][1]), Color(1.0, 0.45, 0.42), 220.0)
			var ix := sp.position.x + 500.0
			draw_string(font, Vector2(ix, sp.position.y + 322.0), "WHAT ELSE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, gold)
			var notes: Array = ["An alpha every minute: it leaves a weapon crate.", "A supply drop now and then: an item.",
				"From %s on: the flood." % SV.time_text(SV.FLOOD_FROM), "%d things happen by the clock." % (data["events"] as Array).size()]
			for q3 in notes.size():
				draw_string(font, Vector2(ix, sp.position.y + 350.0 + q3 * 26.0), "·  " + String(notes[q3]), HORIZONTAL_ALIGNMENT_LEFT, sp.end.x - ix - 16.0, 15, Color(0.82, 0.87, 0.96))
		# ---- (part 10b, Luz) your rig: what you wear in there, by how far you have come at the console
		var rb := rig_rect()
		var rig_n: int = SV.rig_tier(c)
		draw_rect(rb, Color(0.05, 0.06, 0.11))
		draw_rect(rb, Color(gold, 0.45), false, 1.0)
		var rlook: Dictionary = (GameState.pilot.get("look", {}) as Dictionary).duplicate()
		rlook["sv"] = rig_n
		var rtex: Texture2D = ChibiArt.frame(rlook, 0, 0)
		var rfr := Rect2(rb.position.x + 14.0, rb.position.y + (rb.size.y - rtex.get_height() * 2.0) * 0.5 - 2.0, rtex.get_width() * 2.0, rtex.get_height() * 2.0)
		draw_texture_rect(rtex, rfr, false)
		var rgl: Array = ChibiArt.glow(rlook, 0, 0)
		for gi in rgl.size():
			if rgl[gi] != null:
				var ga := 0.5 + 0.5 * sin(_t * 2.4) if gi == 0 else pow(maxf(0.0, sin(_t * 3.4 - float(gi - 1) * TAU / 3.0)), 2.0)
				var gc: Color = ChibiArt.sv_hue(_t * 0.22 + gi * 0.07) if rig_n >= SV.RIG_STEPS else ChibiArt.SV_LIGHT
				gc = gc.lerp(Color.WHITE, 0.45 * ga)
				draw_texture_rect(rgl[gi], rfr, false, Color(gc.r, gc.g, gc.b, 0.3 + 0.7 * ga))
		var rx := rb.position.x + 84.0
		draw_string(font, Vector2(rx, rb.position.y + 26.0), "YOUR RIG   ·   STEP %d OF %d" % [rig_n, SV.RIG_STEPS], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, gold)
		draw_string(font, Vector2(rx, rb.position.y + 50.0), String(SV.RIG_NAMES[rig_n]), HORIZONTAL_ALIGNMENT_LEFT, rb.end.x - rx - 10.0, 16, Color(1, 1, 1))
		for q5 in SV.RIG_STEPS:
			var pr := Rect2(rx + q5 * 22.0, rb.position.y + 62.0, 18.0, 8.0)
			draw_rect(pr, gold if q5 < rig_n else Color(0.12, 0.16, 0.24))
		draw_string(font, Vector2(rx, rb.position.y + 92.0), ("Looks only. Next piece at %d %% at the console (now %d %%)." % [(rig_n + 1) * 10, int(floorf(SV.progress(c) * 100.0 + 0.01))]) if rig_n < SV.RIG_STEPS
			else "Complete. Outside the arena: the Champion's Regalia.", HORIZONTAL_ALIGNMENT_LEFT, rb.end.x - rx - 10.0, 13, Color(0.7, 0.76, 0.88))
		# ---- the weapons you can begin with
		var x0 := vs.x - 810.0
		var first: String = weapon_of(seat if two() else 0)
		var other_w: String = weapon_of(1 - seat) if two() else ""
		draw_string(font, Vector2(x0, 160.0), "YOUR FIRST WEAPON" if not two() else "THE FIRST WEAPON OF", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, gold)
		if two():                                                # split screen: a first weapon each, never the same one
			for si in 2:
				var sr := seat_rect(si)
				var scol: Color = Color(0.3, 0.9, 1.0) if si == 0 else Color(1.0, 0.45, 0.85)
				draw_rect(sr, Color(scol.darkened(0.7), 0.9) if si == seat else Color(0.06, 0.06, 0.12, 0.9))
				draw_rect(sr, scol if si == seat else Color(scol, 0.35), false, 2.0)
				draw_string(font, sr.position + Vector2(10.0, 20.0), "P%d  %s" % [si + 1, String((GameState.pilot2 if si == 1 else GameState.pilot).get("name", "")).get_slice(" ", 0)],
					HORIZONTAL_ALIGNMENT_LEFT, sr.size.x - 16.0, 15, scol if si == seat else Color(scol, 0.6))
			draw_string(font, Vector2(seat_rect(1).end.x + 12.0, 160.0), "[Tab] or L1 / R1", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.6, 0.65, 0.78))
		for i in SV.WEAPON_ORDER.size():
			var id := String(SV.WEAPON_ORDER[i])
			var wr := sv_weapon_rect(i)
			var late: bool = int(SV.WEAPONS[id].get("from", 0)) > 1
			var mine: bool = SV.owned(c, id) and not late
			var on := id == first
			var colw := Color(0.4, 0.92, 1.0) if on else (Color(0.62, 0.68, 0.8) if mine else Color(0.34, 0.37, 0.46))
			draw_rect(wr, Color(0.08, 0.12, 0.2) if on else (Color(0.08, 0.08, 0.14) if (wr.has_point(mp) or i == w_sel) else Color(0.05, 0.05, 0.1)))
			draw_rect(wr, Color(colw, 1.0 if on else 0.5), false, 3.0 if on else 1.0)
			if i == w_sel:
				SU.brackets(self, wr.grow(5.0), Color(1, 1, 1) if focus == 1 else Color(colw, 0.9), 14.0, 3.0)
			SU.icon(self, id, wr.position + Vector2(wr.size.x * 0.5, 36.0), 17.0, colw)
			draw_string(font, wr.position + Vector2(2.0, 80.0), String(SV.WEAPONS[id]["name"]), HORIZONTAL_ALIGNMENT_CENTER, wr.size.x - 4.0, 13, Color(1, 1, 1) if on else (Color(0.8, 0.84, 0.92) if mine else Color(0.45, 0.48, 0.58)))
			if late and SV.owned(c, id):
				draw_string(font, wr.position + Vector2(wr.size.x - 40.0, 17.0), "late", HORIZONTAL_ALIGNMENT_RIGHT, 34.0, 11, Color(1.0, 0.82, 0.3))
			elif not mine:
				SU.icon(self, "lock", wr.position + Vector2(wr.size.x - 15.0, 14.0), 6.0, Color(0.6, 0.64, 0.76))
			if other_w != "" and id == other_w:                  # (split screen: the other one begins with this)
				draw_string(font, wr.position + Vector2(6.0, 17.0), "P%d" % (2 - seat), HORIZONTAL_ALIGNMENT_LEFT, 40.0, 12, Color(0.3, 0.9, 1.0) if seat == 1 else Color(1.0, 0.45, 0.85))
		# ---- what the weapon marked does
		var rows := (SV.WEAPON_ORDER.size() + PER_ROW - 1) / PER_ROW
		var wp := Rect2(x0, 176.0 + rows * 100.0 + 8.0, 750.0, vs.y - (176.0 + rows * 100.0 + 8.0) - 176.0)
		var wid := String(SV.WEAPON_ORDER[w_sel])
		var wd: Dictionary = SV.WEAPONS[wid]
		var wlate: bool = int(wd.get("from", 0)) > 1
		var wmine: bool = SV.owned(c, wid)
		var wcol := Color(0.4, 0.92, 1.0) if (wmine and not wlate) else Color(0.62, 0.68, 0.8)
		draw_rect(wp, Color(0.04, 0.05, 0.09))
		draw_rect(wp, Color(wcol, 0.5), false, 1.5)
		SU.hex_frame(self, wp.position + Vector2(76.0, 80.0), 48.0, wcol, _t)
		SU.icon(self, wid, wp.position + Vector2(76.0, 80.0), 26.0, wcol.lightened(0.2))
		draw_string(font, wp.position + Vector2(150.0, 46.0), String(wd["name"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 28, Color(1, 1, 1))
		var state: String = "You begin with it." if wid == first else ("It comes late in a run: it cannot begin one." if (wlate and wmine) else ("Yours: click to begin with it." if wmine else "Locked: the Survivor console in the lobby unlocks it."))
		draw_string(font, wp.position + Vector2(150.0, 70.0), state, HORIZONTAL_ALIGNMENT_LEFT, wp.size.x - 166.0, 14, green if wid == first else (gold if not wmine or wlate else Color(0.7, 0.9, 1.0)))
		draw_multiline_string(font, wp.position + Vector2(150.0, 96.0), String(wd["text"]), HORIZONTAL_ALIGNMENT_LEFT, wp.size.x - 170.0, 15, 3, Color(0.82, 0.9, 0.96))
		var ly := wp.position.y + 176.0
		draw_string(font, Vector2(wp.position.x + 20.0, ly), "AT LEVEL 1", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, gold)
		draw_string(font, Vector2(wp.position.x + 390.0, ly), "WITH ITS LEVELS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, gold)
		draw_multiline_string(font, Vector2(wp.position.x + 390.0, ly + 24.0), String(wd["up"]), HORIZONTAL_ALIGNMENT_LEFT, wp.size.x - 410.0, 14, 4, Color(0.82, 0.87, 0.96))
		var lines: Array = SV.weapon_lines(wid, 0, 1)
		for q4 in lines.size():
			var yy := ly + 24.0 + q4 * 22.0
			draw_string(font, Vector2(wp.position.x + 20.0, yy), String(lines[q4][0]), HORIZONTAL_ALIGNMENT_LEFT, 200.0, 14, Color(0.68, 0.74, 0.86))
			draw_string(font, Vector2(wp.position.x + 190.0, yy), String(lines[q4][2]), HORIZONTAL_ALIGNMENT_RIGHT, 160.0, 15, wcol.lightened(0.3))
		var has_b: bool = SV.owned(c, String(wd["bonus"]))
		var fy := wp.end.y - 62.0
		draw_rect(Rect2(wp.position.x + 14.0, fy - 18.0, wp.size.x - 28.0, 68.0), Color(1.0, 0.4, 0.8, 0.08))
		draw_string(font, Vector2(wp.position.x + 24.0, fy), "Fuses with %s into %s%s" % [String(SV.BONI[String(wd["bonus"])]["name"]), String(wd["ult"]), "" if has_b else "  (that bonus is still locked)"],
			HORIZONTAL_ALIGNMENT_LEFT, wp.size.x - 48.0, 15, Color(1.0, 0.55, 0.85) if has_b else Color(0.7, 0.5, 0.65))
		draw_multiline_string(font, Vector2(wp.position.x + 24.0, fy + 20.0), String(wd["ult_text"]), HORIZONTAL_ALIGNMENT_LEFT, wp.size.x - 48.0, 13, 2, Color(0.85, 0.75, 0.9))
		# ---- READY, the words at the foot
		var rr := ready_rect()
		var okr := counting < 0.0
		draw_rect(rr, Color(0.1, 0.3, 0.18) if okr else Color(0.08, 0.08, 0.12))
		for g in 3:
			draw_rect(rr.grow(g * 4.0), Color(0.4, 1.0, 0.6, (0.9 - g * 0.3) * (0.6 + 0.4 * absf(sin(_t * 3.0)) if okr else 0.25)), false, 3.0)
		draw_string(font, Vector2(rr.position.x, rr.position.y + 54.0), "READY  (R)", HORIZONTAL_ALIGNMENT_CENTER, rr.size.x, 34, Color(1, 1, 1) if okr else Color(0.45, 0.48, 0.58))
		if focus == 2:
			SU.brackets(self, rr.grow(16.0), Color(1, 1, 1), 26.0, 4.0)
		draw_string(font, Vector2(60.0, vs.y - 140.0), "A run pays Coins and rank points by the time you hold out, and cores: by the time, for alphas, for the bosses.", HORIZONTAL_ALIGNMENT_LEFT, vs.x - 520.0, 14, Color(0.45, 1.0, 0.7))
		draw_string(font, Vector2(60.0, vs.y - 96.0), msg, HORIZONTAL_ALIGNMENT_LEFT, vs.x - 520.0, 19, Color(1.0, 0.95, 0.6))
		draw_string(font, Vector2(60.0, vs.y - 60.0), "Esc: back to the choice of the mode", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(0.6, 0.65, 0.78))
		if counting >= 0.0:
			draw_rect(Rect2(Vector2.ZERO, vs), Color(0.02, 0.02, 0.05, 0.72))
			var n := int(ceil(counting))
			if n >= 1:
				var k := counting - floorf(counting)
				draw_arc(vs * 0.5, 190.0, -PI * 0.5, -PI * 0.5 + TAU * (counting / COUNT), 64, Color(green, 0.9), 10.0)
				draw_string(font, Vector2(0.0, vs.y * 0.5 + 90.0 + (1.0 - k) * 10.0), "%d" % n, HORIZONTAL_ALIGNMENT_CENTER, vs.x, int(220.0 + 60.0 * k), Color(1, 1, 1, 0.5 + 0.5 * k))
				draw_string(font, Vector2(0.0, vs.y * 0.5 + 260.0), "The gate to the arena opens" + ("   ·   Esc calls it off" if counting > 2.0 else ""), HORIZONTAL_ALIGNMENT_CENTER, vs.x, 22, gold)
			draw_rect(Rect2(Vector2.ZERO, vs), Color(1, 1, 1, white))


## Part 4: the picture before a fight: the three who wait on the left (the strong one large in the middle), you on
## the right in the suit you chose, "VS" between, the mode and the round under it. It runs by itself; holding Esc or
## Options ends it early when you have seen an entrance before.
class Versus extends Control:
	signal finished(won: bool)
	const LEN := 4.2
	var foes: Array = []             # [{name, col, tex, strong, boss, line}]
	var you_tex: Texture2D = null
	var you_name := ""
	var mates: Array = []            # (part 5) those beside you: [{name, tex}]
	var sub := ""
	var _t := 0.0

	func is_col_versus() -> bool:
		return true

	func setup(cfg: Dictionary) -> void:
		foes = cfg.get("foes", [])
		you_tex = cfg.get("you_tex", null)
		you_name = String(cfg.get("you", "YOU"))
		mates = cfg.get("mates", [])
		sub = String(cfg.get("sub", ""))
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(dt: float) -> void:
		_t += dt
		if _t >= LEN:
			set_process(false)
			finished.emit(true)
		queue_redraw()

	func _draw() -> void:
		var vs := get_viewport_rect().size
		var font := ThemeDB.fallback_font
		var k_in := ease(clampf(_t / 0.6, 0.0, 1.0), 0.3)
		var k_out := clampf((_t - (LEN - 0.4)) / 0.4, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.02, 0.02, 0.05))
		# two slanted halves sliding in: theirs from the left, yours from the right
		var lx := -vs.x * 0.6 * (1.0 - k_in)
		var rx := vs.x * 0.6 * (1.0 - k_in)
		draw_colored_polygon(PackedVector2Array([Vector2(lx, 0.0), Vector2(lx + vs.x * 0.62, 0.0), Vector2(lx + vs.x * 0.5, vs.y), Vector2(lx, vs.y)]), Color(0.42, 0.08, 0.14))
		draw_colored_polygon(PackedVector2Array([Vector2(rx + vs.x * 0.62, 0.0), Vector2(rx + vs.x, 0.0), Vector2(rx + vs.x, vs.y), Vector2(rx + vs.x * 0.5, vs.y)]), Color(0.06, 0.2, 0.4))
		for sl in range(0, int(vs.y), 8):
			draw_rect(Rect2(0.0, sl, vs.x, 2.0), Color(0, 0, 0, 0.14))
		var order := [1, 0, 2]                                    # (the strong one, foes[0], stands in the middle)
		for q in mini(3, foes.size()):
			var f: Dictionary = foes[order[q]] if order[q] < foes.size() else foes[q]
			var big := bool(f.get("strong", false))
			var tex: Texture2D = f.get("tex", null)
			var th := vs.y * (0.56 if big else 0.4)
			var cx := lx + vs.x * (0.1 + q * 0.14)
			var by := vs.y * 0.72
			var col: Color = f.get("col", Color.WHITE)
			if tex != null:
				var tw := th * tex.get_width() / tex.get_height()
				draw_texture_rect(tex, Rect2(cx - tw * 0.5, by - th, tw, th), false)
			draw_string(font, Vector2(cx - 150.0, by + 36.0), String(f.get("name", "")), HORIZONTAL_ALIGNMENT_CENTER, 300.0, 30 if big else 22, col.lightened(0.3))
			var tag := "the named one" if int(f.get("boss", -1)) >= 0 else ("strong" if big else "weak")
			draw_string(font, Vector2(cx - 150.0, by + 62.0), tag, HORIZONTAL_ALIGNMENT_CENTER, 300.0, 16, Color(1.0, 0.85, 0.4) if int(f.get("boss", -1)) >= 0 else (Color(1.0, 0.5, 0.5) if big else Color(0.6, 1.0, 0.7)))
			if int(f.get("boss", -1)) >= 0 and _t > 1.6:
				draw_string(font, Vector2(lx + 40.0, vs.y * 0.9), "\"%s\"" % String(f.get("line", "")), HORIZONTAL_ALIGNMENT_LEFT, vs.x * 0.44, 20, Color(1.0, 0.9, 0.6, clampf(_t - 1.6, 0.0, 1.0)))
		if you_tex != null:
			var yh := vs.y * 0.56
			var yw := yh * you_tex.get_width() / you_tex.get_height()
			draw_texture_rect(you_tex, Rect2(rx + vs.x * 0.78 - yw * 0.5, vs.y * 0.72 - yh, yw, yh), false)
		draw_string(font, Vector2(rx + vs.x * 0.78 - 250.0, vs.y * 0.72 + 36.0), you_name, HORIZONTAL_ALIGNMENT_CENTER, 500.0, 30, Color(0.7, 0.9, 1.0))
		for mq in mini(2, mates.size()):                             # (part 5) your team: one either side of you, a little smaller
			var mt: Texture2D = mates[mq].get("tex", null)
			var mx2 := rx + vs.x * (0.78 + (-0.13 if mq == 0 else 0.13))
			if mt != null:
				var mh := vs.y * 0.4
				var mw := mh * mt.get_width() / mt.get_height()
				draw_texture_rect(mt, Rect2(mx2 - mw * 0.5, vs.y * 0.72 - mh, mw, mh), false)
			draw_string(font, Vector2(mx2 - 120.0, vs.y * 0.72 + 64.0), String(mates[mq].get("name", "")), HORIZONTAL_ALIGNMENT_CENTER, 240.0, 20, Color(0.6, 1.0, 0.75))
		var kv := clampf((_t - 0.7) / 0.3, 0.0, 1.0)
		if kv > 0.0:
			var fs := int(260.0 + 120.0 * (1.0 - kv))
			draw_string(font, Vector2(0.0, vs.y * 0.5 + fs * 0.34), "VS", HORIZONTAL_ALIGNMENT_CENTER, vs.x, fs, Color(1.0, 0.92, 0.6, kv))
		draw_string(font, Vector2(0.0, 90.0), sub, HORIZONTAL_ALIGNMENT_CENTER, vs.x, 34, Color(1.0, 0.85, 0.4, k_in))
		draw_rect(Rect2(Vector2.ZERO, vs), Color(1, 1, 1, k_out))


## … and the picture after it: what a win paid (Coins, gear points, rank points, the way to the next rank), or what
## a defeat cost. Won: on to the next round, or stop for now. Lost: back into the lobby.
class Result extends Control:
	signal finished(won: bool)
	var res: Dictionary = {}
	var _t := 0.0

	func is_col_result() -> bool:
		return true

	func setup(cfg: Dictionary) -> void:
		res = cfg.get("res", {})
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func go(next: bool) -> void:
		if _t < 0.8:
			return                                            # (not by a key still held from the fight)
		Audio.play("ui_open", "colosseum: on")
		finished.emit(next and bool(res.get("won", false)))

	func rects() -> Array:
		var vs := get_viewport_rect().size
		return [Rect2(vs.x * 0.5 - 330.0, vs.y * 0.5 + 220.0, 320.0, 64.0), Rect2(vs.x * 0.5 + 10.0, vs.y * 0.5 + 220.0, 320.0, 64.0)]

	func _process(dt: float) -> void:
		_t += dt
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			var rs := rects()
			if bool(res.get("won", false)) and (rs[0] as Rect2).has_point((event as InputEventMouseButton).position):
				go(true)
			elif (rs[1] as Rect2).has_point((event as InputEventMouseButton).position):
				go(false)
			accept_event()

	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("menu_back", false, true):
			get_viewport().set_input_as_handled()
			go(false)
		elif event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode in [KEY_ENTER, KEY_SPACE]:
			get_viewport().set_input_as_handled()
			go(bool(res.get("won", false)))

	func pad_button(b: String, pressed: bool) -> bool:
		if not pressed:
			return true
		if b == "cross":
			go(bool(res.get("won", false)))
		elif b == "circle":
			go(false)
		return true

	func _draw() -> void:
		var vs := get_viewport_rect().size
		var font := ThemeDB.fallback_font
		var won := bool(res.get("won", false))
		var c: Dictionary = GameState.col_state()
		var rs: Dictionary = CD.rank_state(c)
		var main := Color(0.4, 1.0, 0.6) if won else Color(1.0, 0.4, 0.4)
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.02, 0.02, 0.05, 0.9))
		var box := Rect2(vs.x * 0.5 - 430.0, vs.y * 0.5 - 300.0, 860.0, 620.0)
		draw_rect(box, Color(0.05, 0.04, 0.1))
		for g in 3:
			draw_rect(box.grow(g * 5.0), Color(main, 0.85 - g * 0.25), false, 3.0)
		draw_string(font, Vector2(box.position.x, box.position.y + 86.0), "VICTORY" if won else "DEFEATED", HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 68, main)
		draw_string(font, Vector2(box.position.x, box.position.y + 126.0), "%s   ·   round %d%s" % [CD.mode_name(String(c.get("mode", "king"))), int(res.get("round", 1)), "   ·   worked out" if bool(res.get("sim", false)) else ""],
			HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 20, Color(0.8, 0.85, 0.95))
		var y := box.position.y + 190.0
		var lines: Array = []
		if won:
			lines = [["+ %d Coins" % int(res.get("coins", 0)), Color(1.0, 0.85, 0.4)], ["+ %d gear points   (your budget: %d)" % [int(res.get("points", 0)), CD.budget(c)], Color(0.5, 1.0, 0.6)],
				["+ %d rank points" % int(res.get("xp", 0)), Color(0.5, 0.9, 1.0)], ["%d wins in a row   ·   best run %d" % [int(c.get("streak", 0)), int(c.get("best", 0))], Color(0.85, 0.9, 1.0)]]
		else:
			lines = [["Your run ends here.", Color(0.95, 0.96, 1.0)], ["The run's gear points go back to the house: %d lost." % int(res.get("lost_points", 0)), Color(1.0, 0.6, 0.6)],
				["Your rank stays. You begin again with %d gear points." % CD.budget(c), Color(0.5, 0.9, 1.0)], ["Best run %d   ·   %d wins in %d fights" % [int(c.get("best", 0)), int(c.get("wins", 0)), int(c.get("fights", 0))], Color(0.85, 0.9, 1.0)]]
		for i in lines.size():
			var show := clampf(_t * 3.0 - i * 0.6, 0.0, 1.0)
			draw_string(font, Vector2(box.position.x + 80.0, y + i * 44.0), String(lines[i][0]), HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 160.0, 26, Color(lines[i][1], show))
		# the rank
		var ry := box.position.y + 390.0
		draw_string(font, Vector2(box.position.x + 80.0, ry), "RANK %d   ·   %s" % [int(rs["rank"]) + 1, String(rs["name"]).to_upper()], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24,
			Color(1.0, 0.85, 0.4) if not bool(res.get("rank_up", false)) else Color(1.0, 0.95, 0.6).lerp(Color(1.0, 0.5, 0.8), 0.5 + 0.5 * sin(_t * 6.0)))
		if bool(res.get("rank_up", false)):
			draw_string(font, Vector2(box.end.x - 380.0, ry), "A NEW RANK", HORIZONTAL_ALIGNMENT_RIGHT, 300.0, 24, Color(1.0, 0.5, 0.8))
		var bar := Rect2(box.position.x + 80.0, ry + 16.0, box.size.x - 160.0, 16.0)
		draw_rect(bar, Color(0.1, 0.1, 0.18))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * float(rs["k"]) * clampf(_t * 1.5, 0.0, 1.0), bar.size.y)), Color(0.5, 0.9, 1.0))
		draw_rect(bar, Color(0.5, 0.9, 1.0, 0.6), false, 1.5)
		var nxt := "The highest rank." if int(rs["to"]) < 0 else "%d rank points to %s (a budget of %d to begin with, quality %s)." % [int(rs["to"]) - int(rs["xp"]),
			String(CD.RANKS[int(rs["rank"]) + 1]["name"]), int(CD.RANKS[int(rs["rank"]) + 1]["start"]), String(CD.GearData.QUALITIES[int(CD.RANKS[int(rs["rank"]) + 1]["q"])])]
		draw_string(font, Vector2(bar.position.x, bar.end.y + 26.0), nxt, HORIZONTAL_ALIGNMENT_LEFT, bar.size.x, 16, Color(0.7, 0.75, 0.88))
		var bs := rects()
		var mp := get_local_mouse_position()
		var labels := ["NEXT ROUND  (Enter)", "STOP FOR NOW  (Esc)"] if won else ["", "BACK TO THE LOBBY  (Enter)"]
		for b in 2:
			if String(labels[b]) == "":
				continue
			var br: Rect2 = bs[b]
			var bc := main if b == 0 else Color(0.72, 0.5, 1.0)
			draw_rect(br, Color(0.1, 0.1, 0.18) if not br.has_point(mp) else Color(0.16, 0.14, 0.26))
			draw_rect(br, bc, false, 3.0)
			draw_string(font, Vector2(br.position.x, br.position.y + 41.0), String(labels[b]), HORIZONTAL_ALIGNMENT_CENTER, br.size.x, 20, Color(1, 1, 1))
