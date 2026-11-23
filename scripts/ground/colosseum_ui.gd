extends RefCounted
## Package 62a, part 3 (Luz): the Colosseum's two windows. `Play`: how you want to play (singleplayer; online co-op,
## online versus and split screen are there already, covered by "COMING SOON"). `Prep`: the fighters' room: on one
## side your gear, fitted from gear points (the house's pieces, never your own), on the other the mode; once a mode
## is picked, a preview of who waits in the arena, your record and what a win pays, and READY. READY counts down
## from five, the picture goes white, and you step into the arena. Every choice goes through the command bus
## (col_play, col_equip, col_mode, col_ready) with the seat, so a second player's can come the same way.
## No class_name: preload it.

const CD = preload("res://data/colosseum.gd")
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
	var col_focus := 0               # (the controller) 0 your gear, 1 the pieces, 2 the modes
	var opt_sel := 0
	var mode_sel := 0
	var counting := -1.0             # the countdown's seconds left (-1: not counting)
	var white := 0.0                 # the picture going white (0 … 1)
	var msg := "Mark a place of your fit, then pick what goes into it. Pick a mode and press READY."
	var _t := 0.0
	var _last := 6

	func is_col_prep() -> bool:
		return true

	func setup(_cfg: Dictionary) -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func col() -> Dictionary:
		return GameState.col_state()

	## The places of the fit as rows: [{"place", "idx", "label", "id"}].
	func slots() -> Array:
		var fit: Dictionary = col()["fit"]
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

	func ready_rect() -> Rect2:
		var vs := get_viewport_rect().size
		return Rect2(vs.x - 400.0, vs.y - 150.0, 340.0, 84.0)

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
		var e: String = Commands.execute({"type": "col_equip", "seat": 0, "place": String(sl["place"]), "idx": int(sl["idx"]), "id": String(o[i])})
		msg = e if e != "" else "%s: %s." % [String(sl["label"]), CD.piece_name(String(o[i]))]
		Audio.play("ui_error" if e != "" else "ui_click", "colosseum: a piece")
		slot = clampi(slot, 0, slots().size() - 1)

	func pick_mode(i: int) -> void:
		if counting >= 0.0:
			return
		mode_sel = clampi(i, 0, CD.MODES.size() - 1)
		var e: String = Commands.execute({"type": "col_mode", "seat": 0, "mode": String(CD.MODES[mode_sel]["id"])})
		msg = e if e != "" else String(CD.MODES[mode_sel]["text"])
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
			for i3 in CD.MODES.size():
				if mode_rect(i3).has_point(mb.position):
					col_focus = 2
					pick_mode(i3)
					return

	func _move(d: int) -> void:
		match col_focus:
			0:
				mark(slot + d)
			1:
				opt_sel = clampi(opt_sel + d, 0, options().size() - 1)
				scroll = clampi(scroll, maxi(0, opt_sel - shown() + 1), opt_sel)
			2:
				mode_sel = clampi(mode_sel + d, 0, CD.MODES.size() - 1)

	func _press() -> void:
		match col_focus:
			0:
				col_focus = 1
			1:
				take(opt_sel)
			2:
				pick_mode(mode_sel)

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
					col_focus = mini(2, col_focus + 1)
				KEY_ENTER, KEY_SPACE:
					if not (event as InputEventKey).echo:
						_press()
				KEY_R:
					if not (event as InputEventKey).echo:
						go_ready()
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
				col_focus = mini(2, col_focus + 1)
			"cross":
				_press()
			"triangle":
				go_ready()
			"circle":
				back()
		return true

	func _draw() -> void:
		var vs := get_viewport_rect().size
		var font := ThemeDB.fallback_font
		var c := col()
		var fit: Dictionary = c["fit"]
		var used: int = CD.fit_cost(fit)
		var have: int = CD.budget(c)
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.03, 0.03, 0.07))
		for ln in 14:                                            # the room: lockers of light along the wall
			var lx := ln * vs.x / 13.0
			draw_rect(Rect2(lx - 1.0, 0.0, 2.0, vs.y), Color(NEON[ln % 4], 0.05 + 0.03 * sin(_t + ln)))
		draw_rect(Rect2(0.0, 120.0, vs.x, 2.0), Color(NEON[1], 0.5))
		draw_string(font, Vector2(60.0, 70.0), "THE FIGHTERS' ROOM", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 40, Color(1.0, 0.5, 0.8).lerp(Color(0.3, 0.9, 1.0), 0.5 + 0.5 * sin(_t * 1.5)))
		draw_string(font, Vector2(60.0, 104.0), "You fight with the house's gear, fitted from gear points. What you take off gives its points back.", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color(0.8, 0.85, 0.95))
		draw_string(font, Vector2(vs.x - 700.0, 76.0), "GEAR POINTS  %d of %d" % [used, have], HORIZONTAL_ALIGNMENT_RIGHT, 640.0, 34, Color(1.0, 0.85, 0.4))
		draw_string(font, Vector2(vs.x - 700.0, 104.0), "%d free" % (have - used), HORIZONTAL_ALIGNMENT_RIGHT, 640.0, 17, Color(0.5, 1.0, 0.6))
		var mp := get_local_mouse_position()
		# ---- your gear
		draw_string(font, Vector2(60.0, 172.0), "YOUR GEAR", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(1.0, 0.85, 0.4))
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
			var can := after <= have
			var hot := orr.has_point(mp) or (col_focus == 1 and opt_sel == oi)
			draw_rect(orr, Color(0.12, 0.1, 0.2) if hot else Color(0.06, 0.05, 0.11))
			if worn:
				draw_rect(orr, Color(NEON[1], 0.9), false, 2.0)
			if oid != "":
				draw_texture_rect(GearIcons.icon(oid), Rect2(orr.position.x + 6.0, orr.position.y + 2.0, 26.0, 26.0), false, Color(1, 1, 1, 1.0 if can else 0.4))
			draw_string(font, orr.position + Vector2(42.0, 21.0), CD.piece_name(oid) if oid != "" else "Nothing", HORIZONTAL_ALIGNMENT_LEFT, 380.0, 16,
				(Color(0.95, 0.96, 1.0) if can else Color(0.5, 0.45, 0.5)))
			draw_string(font, Vector2(orr.end.x - 56.0, orr.position.y + 21.0), "%d" % maxi(0, CD.cost(oid)), HORIZONTAL_ALIGNMENT_RIGHT, 46.0, 17, Color(1.0, 0.85, 0.4) if can else Color(1.0, 0.45, 0.45))
		if o.size() > shown():
			draw_string(font, Vector2(640.0, 190.0 + shown() * OPT + 16.0), "%d to %d of %d   ·   the wheel scrolls" % [scroll + 1, mini(o.size(), scroll + shown()), o.size()], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13,
				Color(0.6, 0.65, 0.78))
		# ---- the mode, the preview, READY
		draw_string(font, Vector2(vs.x - 700.0, 172.0), "THE MODE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(1.0, 0.85, 0.4))
		var picked := String(c.get("mode", ""))
		for mi in CD.MODES.size():
			var mr := mode_rect(mi)
			var md: Dictionary = CD.MODES[mi]
			var mon := picked == String(md["id"])
			var mopen := bool(md["open"])
			draw_rect(mr, Color(0.1, 0.08, 0.18) if mon else Color(0.06, 0.05, 0.11))
			draw_rect(mr, Color(NEON[0], 1.0) if mon else Color(NEON[3], 0.8 if (mr.has_point(mp) or (col_focus == 2 and mode_sel == mi)) else 0.35), false, 3.0 if mon else 1.5)
			draw_string(font, mr.position + Vector2(16.0, 36.0), String(md["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color(1, 1, 1) if mopen else Color(0.45, 0.48, 0.58))
			if mopen:
				draw_string(font, Vector2(mr.end.x - 216.0, mr.position.y + 36.0), "Round %d" % int(c.get("round", 1)), HORIZONTAL_ALIGNMENT_RIGHT, 200.0, 17, Color(0.8, 0.9, 1.0))
			else:
				draw_rect(Rect2(mr.end.x - 170.0, mr.position.y + 14.0, 154.0, 30.0), Color(1.0, 0.82, 0.25, 0.92))
				draw_string(font, Vector2(mr.end.x - 170.0, mr.position.y + 35.0), "COMING SOON", HORIZONTAL_ALIGNMENT_CENTER, 154.0, 15, Color(0.1, 0.07, 0.02))
		var pv := Rect2(vs.x - 700.0, 190.0 + CD.MODES.size() * 66.0 + 14.0, 640.0, 380.0)
		draw_rect(pv, Color(0.05, 0.04, 0.1))
		draw_rect(pv, Color(NEON[1], 0.5), false, 1.5)
		if picked == "":
			draw_string(font, pv.position + Vector2(0.0, 190.0), "Pick a mode to see who waits in the arena.", HORIZONTAL_ALIGNMENT_CENTER, pv.size.x, 18, Color(0.6, 0.65, 0.78))
		else:
			draw_string(font, pv.position + Vector2(16.0, 30.0), "WHO WAITS IN THE ARENA", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(1.0, 0.85, 0.4))
			var foes: Array = CD.opponents(int(c.get("round", 1)), CG.FIGHTERS.size())
			for fi in foes.size():
				var fo: Dictionary = foes[fi]
				var fd: Dictionary = CG.FIGHTERS[int(fo["who"])]
				var fx := pv.position.x + 24.0 + fi * 204.0
				var strong := bool(fo["strong"])
				var tex: Texture2D = CG.fighter_tex(int(fo["who"]), false)
				var th := 150.0 if strong else 120.0
				draw_rect(Rect2(fx, pv.position.y + 44.0, 184.0, 204.0), Color(0.08, 0.06, 0.14))
				draw_rect(Rect2(fx, pv.position.y + 44.0, 184.0, 204.0), Color(1.0, 0.35, 0.35) if strong else Color(0.4, 1.0, 0.6), false, 2.0)
				draw_texture_rect(tex, Rect2(fx + 92.0 - th * 0.5 * tex.get_width() / tex.get_height(), pv.position.y + 204.0 - th, th * tex.get_width() / tex.get_height(), th), false)
				draw_string(font, Vector2(fx, pv.position.y + 224.0), String(fd["name"]), HORIZONTAL_ALIGNMENT_CENTER, 184.0, 17, Color(fd["col"]).lightened(0.3))
				draw_string(font, Vector2(fx, pv.position.y + 242.0), "strong" if strong else "weak", HORIZONTAL_ALIGNMENT_CENTER, 184.0, 14, Color(1.0, 0.45, 0.45) if strong else Color(0.5, 1.0, 0.6))
			draw_string(font, pv.position + Vector2(16.0, 284.0), "YOUR RECORD", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(1.0, 0.85, 0.4))
			draw_string(font, pv.position + Vector2(16.0, 310.0), "%d wins in a row   ·   best run %d   ·   %d wins in %d fights" % [int(c.get("streak", 0)), int(c.get("best", 0)), int(c.get("wins", 0)), int(c.get("fights", 0))],
				HORIZONTAL_ALIGNMENT_LEFT, pv.size.x - 32.0, 17, Color(0.9, 0.93, 1.0))
			var rw: Dictionary = CD.reward(int(c.get("round", 1)))
			draw_string(font, pv.position + Vector2(16.0, 346.0), "A win pays %d Coins and %d gear points." % [int(rw["coins"]), int(rw["points"])], HORIZONTAL_ALIGNMENT_LEFT, pv.size.x - 32.0, 17, Color(0.5, 1.0, 0.6))
		var rr := ready_rect()
		var okr := picked != "" and counting < 0.0
		draw_rect(rr, Color(0.1, 0.3, 0.18) if okr else Color(0.08, 0.08, 0.12))
		for g in 3:
			draw_rect(rr.grow(g * 4.0), Color(0.4, 1.0, 0.6, (0.9 - g * 0.3) * (0.6 + 0.4 * absf(sin(_t * 3.0)) if okr else 0.25)), false, 3.0)
		draw_string(font, Vector2(rr.position.x, rr.position.y + 54.0), "READY  (R)", HORIZONTAL_ALIGNMENT_CENTER, rr.size.x, 34, Color(1, 1, 1) if okr else Color(0.45, 0.48, 0.58))
		draw_string(font, Vector2(60.0, vs.y - 96.0), msg, HORIZONTAL_ALIGNMENT_LEFT, vs.x - 520.0, 19, Color(1.0, 0.95, 0.6))
		draw_string(font, Vector2(60.0, vs.y - 60.0), "Esc: back to the lobby", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(0.6, 0.65, 0.78))
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
