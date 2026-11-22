extends RefCounted
## Package 62, part 3 (Luz): the cards of the Grand Centauria, drawn. The four suits of Drift (comets, moons, suns,
## nebulae) on dark cards with an edge of neon; the Pilot, the Captain and the Admiral wear one, two and three
## chevrons. Also the chips. All static, drawn onto any CanvasItem. No class_name: preload it.

const SUIT_COL := [Color(0.4, 0.9, 1.0), Color(0.9, 0.9, 1.0), Color(1.0, 0.78, 0.25), Color(0.9, 0.45, 1.0)]
const SIZE := Vector2(84.0, 118.0)
const CD = preload("res://data/casino.gd")


static func symbol(ci: CanvasItem, suit: int, at: Vector2, s: float, col: Color) -> void:
	match suit:
		0:
			ci.draw_circle(at + Vector2(s * 0.3, -s * 0.3), s * 0.35, col)
			for t in 3:
				ci.draw_line(at + Vector2(s * 0.2, -s * 0.2), at + Vector2(-s * 0.7 + t * 4.0, s * 0.7 - t * 6.0), Color(col, 0.6), 2.0)
		1:
			ci.draw_arc(at, s * 0.5, 0.9, TAU - 0.9 + 1.2, 20, col, s * 0.28)
		2:
			ci.draw_circle(at, s * 0.42, col)
			for i in 8:
				var a := i * TAU / 8.0
				ci.draw_line(at + Vector2.from_angle(a) * s * 0.55, at + Vector2.from_angle(a) * s * 0.85, col, 2.0)
		_:
			for i2 in 4:
				ci.draw_circle(at + Vector2(cos(i2 * 1.7), sin(i2 * 2.3)) * s * 0.3, s * (0.4 - i2 * 0.05), Color(col, 0.5))


## A card face up at `p` (its top left), `sz` large. `glow`: a ring of light round it (alpha 0: none); `dim`: a
## card that is out of the game.
static func face(ci: CanvasItem, p: Vector2, sz: Vector2, card: Array, glow: Color = Color(0, 0, 0, 0), dim: bool = false) -> void:
	var font := ThemeDB.fallback_font
	var r := Rect2(p, sz)
	var suit := int(card[1])
	var rank := int(card[0])
	var col: Color = SUIT_COL[suit]
	if dim:
		col = col.darkened(0.55)
	var k := sz.x / SIZE.x
	ci.draw_rect(Rect2(p + Vector2(4.0, 5.0), sz), Color(0, 0, 0, 0.4))
	ci.draw_rect(r.grow(3.0), Color(col, 0.22))
	ci.draw_rect(r, Color(0.05, 0.05, 0.11))
	ci.draw_rect(r.grow(-1.5), col, false, 3.0)
	var lab: String = CD.rank_label(rank)
	ci.draw_string(font, p + Vector2(9.0, 28.0) * k, lab, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(24 * k), col.lightened(0.25))
	ci.draw_string(font, p + Vector2(sz.x - 40.0 * k, sz.y - 10.0 * k), lab, HORIZONTAL_ALIGNMENT_RIGHT, 32.0 * k, int(18 * k), col)
	var cen := p + sz * 0.5
	symbol(ci, suit, cen + Vector2(0.0, -4.0 * k if rank >= 11 and rank <= 13 else 0.0), 20.0 * k, col)
	if rank >= 11 and rank <= 13:                         # the court: chevrons for the rank
		for c in rank - 10:
			var cy := cen.y + (22.0 + c * 7.0) * k
			ci.draw_polyline(PackedVector2Array([Vector2(cen.x - 13.0 * k, cy - 5.0 * k), Vector2(cen.x, cy), Vector2(cen.x + 13.0 * k, cy - 5.0 * k)]), col.lightened(0.3), 2.0)
	elif rank == 14:
		ci.draw_arc(cen, 27.0 * k, 0.0, TAU, 28, Color(col, 0.7), 2.0)
	if glow.a > 0.0:
		ci.draw_rect(r.grow(5.0), glow, false, 3.0)


## A card face down.
static func back(ci: CanvasItem, p: Vector2, sz: Vector2, dim: bool = false) -> void:
	var r := Rect2(p, sz)
	var a := 0.45 if dim else 1.0
	ci.draw_rect(Rect2(p + Vector2(4.0, 5.0), sz), Color(0, 0, 0, 0.4 * a))
	ci.draw_rect(r, Color(0.16, 0.07, 0.26, a))
	ci.draw_rect(r.grow(-1.5), Color(1.0, 0.36, 0.66, a), false, 3.0)
	ci.draw_rect(r.grow(-8.0), Color(0.3, 0.9, 1.0, 0.6 * a), false, 1.5)
	var cen := p + sz * 0.5
	ci.draw_arc(cen, sz.x * 0.2, 0.0, TAU, 24, Color(1.0, 0.82, 0.3, 0.9 * a), 2.0)
	ci.draw_line(cen + Vector2(-sz.x * 0.3, sz.x * 0.08), cen + Vector2(sz.x * 0.3, -sz.x * 0.08), Color(1.0, 0.82, 0.3, 0.7 * a), 2.0)


## A little pile of chips with what it is worth beside it.
static func chips(ci: CanvasItem, at: Vector2, amount: int, col: Color) -> void:
	if amount <= 0:
		return
	var font := ThemeDB.fallback_font
	var n := clampi(1 + int(log(float(amount)) / log(5.0)), 1, 6)
	for i in n:
		var c := at + Vector2(0.0, -i * 5.0)
		ci.draw_circle(c + Vector2(0.0, 2.0), 15.0, Color(0.02, 0.02, 0.05))
		ci.draw_circle(c, 14.0, col)
		ci.draw_arc(c, 10.0, 0.0, TAU, 20, Color(0.05, 0.04, 0.1, 0.8), 2.0)
	ci.draw_string(font, at + Vector2(22.0, 6.0), "%d" % amount, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color(1.0, 0.92, 0.6))
