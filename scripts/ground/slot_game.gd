extends Control
## Package 62, part 2 (Luz): a slot machine of the Grand Centauria, loud with neon. Three reels, one line; the stake
## is 1, 5 or 25 Coins; the pay table stands beside the reels, the house's jackpot over them. Space (or the lever)
## spins: the spin itself goes through the command bus (slot_spin), which takes the stake, rolls the reels and pays;
## this window only shows it. Esc leaves. No class_name: preload it.

signal finished(won: bool)

const CD = preload("res://data/casino.gd")
const NEON := [Color(1.0, 0.36, 0.66), Color(0.3, 0.9, 1.0), Color(1.0, 0.82, 0.25), Color(0.55, 1.0, 0.6), Color(0.72, 0.5, 1.0), Color(1.0, 0.45, 0.25)]
const STOPS := [0.8, 1.25, 1.7]                  # seconds until each reel stands

var title := "Lucky Lapis"
var col := Color(1.0, 0.36, 0.66)
var stake := 1
var reels: Array = ["ring", "seven", "coin"]     # what stands on the line
var res: Dictionary = {}                         # the spin running or last shown
var spin_t := -1.0                               # seconds into the spin (-1: the reels stand)
var shown := 0                                   # the Coins shown (they follow the spin, not the purse)
var msg := "Pick your stake and pull."
var flash := 0.0
var _t := 0.0
var _btns := {}
var _ui := {}


func setup(cfg: Dictionary) -> void:
	title = String(cfg.get("title", title))
	col = cfg.get("col", col)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	shown = GameState.coins


func _ready() -> void:
	var vs := get_viewport_rect().size
	var row := UI.hbox(12)
	row.position = Vector2(vs.x * 0.5 - 330, vs.y - 112)
	add_child(row)
	row.add_child(UI.label("Stake", 16, UI.GOLD))
	for s in CD.SLOT_STAKES:
		var sv: int = s
		var b := UI.button("%d C" % sv, func(): set_stake(sv))
		b.custom_minimum_size = Vector2(90, 46)
		row.add_child(b)
		_btns[sv] = b
	var go := UI.button("PULL  (Space)", func(): pull())
	go.custom_minimum_size = Vector2(220, 46)
	row.add_child(go)
	_btns["go"] = go
	var out := UI.button("Leave  (Esc)", func(): finished.emit(false))
	out.custom_minimum_size = Vector2(150, 46)
	row.add_child(out)


func busy() -> bool:
	return spin_t >= 0.0


func set_stake(s: int) -> void:
	if not busy() and s in CD.SLOT_STAKES:
		stake = s
		Audio.play("ui_click", "slot: stake")


func pull() -> void:
	if busy():
		return
	var e: String = Commands.execute({"type": "slot_spin", "stake": stake})
	if e != "":
		msg = e
		Audio.play("ui_error", "slot: refused")


## The command bus has spun: the reels run and stop one after the other on this.
func slot_result(r: Dictionary) -> void:
	res = r
	spin_t = 0.0
	shown -= stake
	msg = ""
	Audio.play("card_shuffle", "slot: reels")


func _process(dt: float) -> void:
	_t += dt
	flash = maxf(0.0, flash - dt)
	if spin_t >= 0.0:
		spin_t += dt
		for i in 3:
			if spin_t >= float(STOPS[i]) and spin_t - dt < float(STOPS[i]):
				reels[i] = res["reels"][i]
				Audio.play("ui_click", "slot: reel stops")
		if spin_t >= float(STOPS[2]) + 0.25:
			spin_t = -1.0
			shown = GameState.coins
			msg = String(res.get("what", ""))
			if bool(res.get("nudged", false)) and int(res.get("win", 0)) > 0:
				msg += "  (The middle reel slipped one on: a kind hand.)"
			if int(res.get("win", 0)) > 0:
				flash = 3.0 if bool(res.get("jackpot", false)) else 1.2
				Audio.play("arcade_bank" if bool(res.get("jackpot", false)) else "arcade_coin", "slot: win")
	for s in CD.SLOT_STAKES:
		(_btns[s] as Button).disabled = busy()
		(_btns[s] as Button).modulate = Color(1.0, 0.85, 0.4) if int(s) == stake else Color.WHITE
	(_btns["go"] as Button).disabled = busy() or GameState.coins < stake
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_back", false, true):
		get_viewport().set_input_as_handled()
		if not busy():
			finished.emit(false)
	elif event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_SPACE, KEY_ENTER:
				get_viewport().set_input_as_handled()
				pull()
			KEY_1:
				set_stake(int(CD.SLOT_STAKES[0]))
			KEY_2:
				set_stake(int(CD.SLOT_STAKES[1]))
			KEY_3:
				set_stake(int(CD.SLOT_STAKES[2]))


## Package 80: with the controller ✕ pulls, ← → pick the stake, ◯ leaves.
func pad_button(b: String, pressed: bool) -> bool:
	if not pressed:
		return true
	var i := CD.SLOT_STAKES.find(stake)
	match b:
		"cross":
			pull()
		"left":
			set_stake(int(CD.SLOT_STAKES[maxi(0, i - 1)]))
		"right":
			set_stake(int(CD.SLOT_STAKES[mini(CD.SLOT_STAKES.size() - 1, i + 1)]))
		"circle":
			if not busy():
				finished.emit(false)
	return true


## One symbol, drawn round `c`, `s` px across.
static func symbol(ci: CanvasItem, id: String, c: Vector2, s: float) -> void:
	var font := ThemeDB.fallback_font
	match id:
		"ore":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.4, 0.1) * s, c + Vector2(-0.15, -0.35) * s, c + Vector2(0.3, -0.25) * s, c + Vector2(0.42, 0.15) * s, c + Vector2(0.1, 0.4) * s, c + Vector2(-0.3, 0.35) * s]), Color(0.62, 0.42, 0.26))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.15, -0.35) * s, c + Vector2(0.3, -0.25) * s, c + Vector2(0.05, 0.0) * s]), Color(0.86, 0.62, 0.36))
			ci.draw_circle(c + Vector2(0.12, 0.16) * s, s * 0.06, Color(1.0, 0.85, 0.4))
		"cell":
			ci.draw_rect(Rect2(c + Vector2(-0.22, -0.34) * s, Vector2(0.44, 0.72) * s), Color(0.12, 0.3, 0.2))
			ci.draw_rect(Rect2(c + Vector2(-0.09, -0.42) * s, Vector2(0.18, 0.08) * s), Color(0.7, 0.8, 0.75))
			for k in 3:
				ci.draw_rect(Rect2(c + Vector2(-0.16, 0.2 - k * 0.2) * s, Vector2(0.32, 0.14) * s), Color(0.4, 1.0, 0.6))
		"comet":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0.1, -0.02) * s, c + Vector2(0.24, 0.16) * s, c + Vector2(-0.44, 0.4) * s]), Color(0.3, 0.9, 1.0, 0.55))
			ci.draw_circle(c + Vector2(0.18, -0.08) * s, s * 0.2, Color(0.75, 0.97, 1.0))
			ci.draw_circle(c + Vector2(0.18, -0.08) * s, s * 0.11, Color(1, 1, 1))
		"star":
			var pts := PackedVector2Array()
			for k in 10:
				pts.append(c + Vector2.from_angle(-PI * 0.5 + k * PI / 5.0) * s * (0.42 if k % 2 == 0 else 0.18))
			ci.draw_colored_polygon(pts, Color(1.0, 0.86, 0.3))
			ci.draw_circle(c, s * 0.1, Color(1.0, 0.97, 0.8))
		"ring":
			ci.draw_set_transform(c, -0.35, Vector2(1.0, 0.32))
			ci.draw_arc(Vector2.ZERO, s * 0.44, PI, TAU, 24, Color(0.75, 0.85, 1.0), s * 0.07)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			ci.draw_circle(c, s * 0.25, Color(0.2, 0.42, 0.95))
			ci.draw_circle(c + Vector2(-0.06, -0.07) * s, s * 0.13, Color(0.4, 0.62, 1.0))
			ci.draw_set_transform(c, -0.35, Vector2(1.0, 0.32))
			ci.draw_arc(Vector2.ZERO, s * 0.44, 0.0, PI, 24, Color(0.75, 0.85, 1.0), s * 0.07)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"seven":
			ci.draw_string(font, c + Vector2(-0.3, 0.33) * s, "7", HORIZONTAL_ALIGNMENT_CENTER, s * 0.6, int(s * 0.9), Color(1.0, 0.3, 0.75))
			ci.draw_rect(Rect2(c + Vector2(-0.4, -0.02) * s, Vector2(0.8, 0.03) * s), Color(1, 1, 1, 0.35))
		_:
			ci.draw_circle(c, s * 0.4, Color(0.8, 0.6, 0.15))
			ci.draw_circle(c, s * 0.33, Color(1.0, 0.85, 0.4))
			ci.draw_arc(c, s * 0.17, 0.8, TAU - 0.8, 16, Color(0.6, 0.42, 0.1), s * 0.07)


func _draw() -> void:
	var vs := get_viewport_rect().size
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.03, 0.02, 0.07, 0.94))
	# the cabinet
	var cab := Rect2(vs.x * 0.5 - 430.0, 110.0, 560.0, vs.y - 260.0)
	draw_rect(cab, Color(0.07, 0.05, 0.12))
	for k in 3:
		draw_rect(cab.grow(float(k) * 5.0), Color(col, 0.5 - k * 0.15), false, 3.0)
	var bn := 0
	var bx := cab.position.x + 14.0
	while bx < cab.end.x - 8.0:                              # lamps running round the top
		draw_circle(Vector2(bx, cab.position.y + 14.0), 5.0, NEON[bn % NEON.size()] if (bn + int(_t * 8.0)) % 3 == 0 else Color(0.25, 0.2, 0.3))
		bx += 22.0
		bn += 1
	draw_string(font, Vector2(cab.position.x, cab.position.y + 70.0), title.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, cab.size.x, 44, col.lightened(0.3 + 0.2 * sin(_t * 3.0)))
	var jp := Rect2(cab.position.x + 60.0, cab.position.y + 92.0, cab.size.x - 120.0, 58.0)
	draw_rect(jp, Color(0.02, 0.02, 0.04))
	draw_rect(jp, Color(1.0, 0.82, 0.35, 0.6 + 0.4 * absf(sin(_t * 2.0))), false, 2.0)
	draw_string(font, Vector2(jp.position.x, jp.position.y + 20.0), "JACKPOT OF THE HOUSE", HORIZONTAL_ALIGNMENT_CENTER, jp.size.x, 13, Color(1.0, 0.6, 0.8))
	draw_string(font, Vector2(jp.position.x, jp.position.y + 48.0), "%s C" % GameData.fmt_credits(GameState.casino_jackpot).replace(" cr", ""), HORIZONTAL_ALIGNMENT_CENTER, jp.size.x, 26, Color(1.0, 0.9, 0.5))
	# the reels
	var rw := 150.0
	var ry := cab.position.y + 176.0
	var rh := cab.size.y - 330.0
	var step := rh / 3.0
	for sd in 2:                                              # strips of lamps down both sides, running
		var lx := cab.position.x - 34.0 if sd == 0 else cab.end.x + 14.0
		for ln in 20:
			draw_rect(Rect2(lx, cab.position.y + 20.0 + ln * (cab.size.y - 40.0) / 20.0, 20.0, 12.0), Color(NEON[(ln + sd * 3) % NEON.size()], 1.0 if (ln + int(_t * 7.0)) % 4 == 0 else 0.25))
	for i in 3:
		var rr := Rect2(cab.position.x + 40.0 + i * (rw + 15.0), ry, rw, rh)
		draw_rect(rr, Color(0.02, 0.02, 0.05))
		var running := spin_t >= 0.0 and spin_t < float(STOPS[i])
		for row in range(-1, 2):
			var id := String(reels[i])
			var off := 0.0
			if running:
				off = fposmod(_t * 900.0 + i * 37.0, step)
				id = CD.SYMBOLS[(int(_t * 14.0) + row * 3 + i * 5) % CD.SYMBOLS.size()]
			elif row != 0:
				id = CD.SYMBOLS[(CD.SYMBOLS.find(String(reels[i])) + row * (2 + i) + 7) % CD.SYMBOLS.size()]
			var cy := rr.position.y + rh * 0.5 + row * step + off - (step * 0.5 if running else 0.0)
			if cy > rr.position.y + 40.0 and cy < rr.end.y - 40.0:
				symbol(self, id, Vector2(rr.position.x + rw * 0.5, cy), 118.0 if row == 0 and not running else 92.0)
		draw_rect(Rect2(rr.position, Vector2(rw, 46.0)), Color(0.02, 0.02, 0.05, 0.8))
		draw_rect(Rect2(rr.position.x, rr.end.y - 46.0, rw, 46.0), Color(0.02, 0.02, 0.05, 0.8))
		draw_rect(rr, NEON[(i + int(_t * 2.0)) % NEON.size()], false, 3.0)
	var ly := ry + rh * 0.5
	var win := int(res.get("win", 0)) > 0 and spin_t < 0.0
	draw_rect(Rect2(cab.position.x + 26.0, ly - step * 0.5, cab.size.x - 52.0, step), Color(1.0, 0.85, 0.4, (0.5 + 0.5 * absf(sin(_t * 9.0))) if win and flash > 0.0 else 0.35), false, 3.0)
	# the lever
	var lv := Vector2(cab.end.x + 66.0, ry + 40.0 + (120.0 * clampf(spin_t / 0.3, 0.0, 1.0) * clampf(1.0 - (spin_t - 0.3) / 0.4, 0.0, 1.0) if spin_t >= 0.0 else 0.0))
	draw_rect(Rect2(cab.end.x + 60.0, ry + 40.0, 12.0, 200.0), Color(0.3, 0.28, 0.36))
	draw_circle(lv, 22.0, Color(1.0, 0.3, 0.4))
	draw_circle(lv + Vector2(-6.0, -7.0), 7.0, Color(1.0, 0.7, 0.75))
	# the purse, what happened
	draw_string(font, Vector2(cab.position.x, cab.end.y - 58.0), "%d Coins" % shown, HORIZONTAL_ALIGNMENT_CENTER, cab.size.x, 30, Color(1.0, 0.85, 0.4))
	draw_string(font, Vector2(cab.position.x - 60.0, cab.end.y - 20.0), msg, HORIZONTAL_ALIGNMENT_CENTER, cab.size.x + 120.0, 17,
		Color(0.5, 1.0, 0.6) if win else Color(0.85, 0.9, 1.0))
	# the pay table
	var px := cab.end.x + 130.0
	var py := cab.position.y + 20.0
	draw_rect(Rect2(px - 16.0, py - 10.0, 330.0, 540.0), Color(0.05, 0.04, 0.1))
	for pk in 3:
		draw_rect(Rect2(px - 16.0, py - 10.0, 330.0, 540.0).grow(pk * 4.0), Color(NEON[(pk + 1 + int(_t)) % NEON.size()], 0.8 - pk * 0.25), false, 2.0)
	draw_string(font, Vector2(px, py + 22.0), "PAYS  (times the stake)", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color(0.3, 0.9, 1.0))
	var k2 := 0
	for id2 in ["seven", "coin", "ring", "star", "comet", "cell", "ore"]:
		var yy := py + 62.0 + k2 * 50.0
		for q in 3:
			symbol(self, id2, Vector2(px + 22.0 + q * 44.0, yy), 38.0)
		draw_string(font, Vector2(px + 160.0, yy + 8.0), "%d" % int(CD.PAY3[id2]), HORIZONTAL_ALIGNMENT_RIGHT, 120.0, 22, Color(1.0, 0.9, 0.5))
		k2 += 1
	draw_string(font, Vector2(px, py + 62.0 + 7 * 50.0 + 6.0), "The first two alike", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(0.85, 0.9, 1.0))
	draw_string(font, Vector2(px + 160.0, py + 62.0 + 7 * 50.0 + 8.0), "%d" % CD.PAY2, HORIZONTAL_ALIGNMENT_RIGHT, 120.0, 22, Color(1.0, 0.9, 0.5))
	draw_string(font, Vector2(px, py + 62.0 + 8 * 50.0), "Three Coins at 25 C:", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(1.0, 0.6, 0.8))
	draw_string(font, Vector2(px, py + 62.0 + 8 * 50.0 + 22.0), "the house's jackpot", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(1.0, 0.6, 0.8))
