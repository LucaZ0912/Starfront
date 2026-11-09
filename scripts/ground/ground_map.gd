class_name GroundMap
extends RefCounted
## Package 49: a walkable place on foot – a grid of tiles (16 art px each), what blocks, the zones you can use and
## the picture of the floor and the walls. 0.7.49.2: a slanted, cosy top-down view – walls show their front face,
## window fronts are glass you look through into space, furniture stands as separate objects (drawn by GroundView,
## sorted by depth so people walk in front of and behind them).

const TILE := 16
const SCALE := 3.0
## VOID outside · FLOOR · CAP the top of a wall · FACE a wall's front face · GLASS a window front (see-through) ·
## DOOR an opening · BLOCK floor under furniture
enum T { VOID, FLOOR, CAP, FACE, GLASS, DOOR, BLOCK }

var w := 0
var h := 0
var tiles := PackedInt32Array()
var floor_kind := PackedInt32Array()          # 0 corridor, 1 shop, 2 lift, 3 bar wood, 4 carpet
var zones: Array = []                         # {rect (art px), kind: service/exit/crew/label, id, title, col, sign}
var objects: Array = []                       # furniture: {kind, x, y, w, h (tiles), col, …} – drawn by GroundView
var decals: Array = []                        # flat things painted into the floor: {kind, x, y, w, h, col}
var face_deco: Array = []                     # things on a wall face: {kind, x, y, w, col}
var people: Array = []                        # NPCs that stay: {pos (art px, feet), look?, dir, role, sit, crew?}
var wander: Array = []                        # where strolling NPCs may go (art px)
var spawn := Vector2.ZERO
var pal: Dictionary = {}
var hull_top := -1                    # the station's structure goes on everywhere from this row down (the view draws it)
var window_rect := Rect2()            # tiles: where space shows through the glass (the view draws it there only)
var round_corners: Array = []         # {x, r, side}: a window front's corner rounded off (tiles; side -1 west, +1 east)
var title := ""
var _img: Image
var _tex: Texture2D


func setup(p_w: int, p_h: int) -> void:
	w = p_w
	h = p_h
	tiles.resize(w * h)
	tiles.fill(T.VOID)
	floor_kind.resize(w * h)
	floor_kind.fill(0)


func t_at(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= w or y >= h:
		return T.VOID
	return tiles[y * w + x]


func set_t(x: int, y: int, t: int, fk: int = -1) -> void:
	if x < 0 or y < 0 or x >= w or y >= h:
		return
	tiles[y * w + x] = t
	if fk >= 0:
		floor_kind[y * w + x] = fk


func fill(x: int, y: int, rw: int, rh: int, t: int, fk: int = -1) -> void:
	for yy in range(y, y + rh):
		for xx in range(x, x + rw):
			set_t(xx, yy, t, fk)


static func walkable_t(t: int) -> bool:
	return t == T.FLOOR or t == T.DOOR


## Can someone with feet of radius r (art px) stand at p?
func free_at(p: Vector2, r: float = 4.0) -> bool:
	for c in [Vector2(-r, -r * 0.5), Vector2(r, -r * 0.5), Vector2(-r, r * 0.5), Vector2(r, r * 0.5)]:
		var q: Vector2 = p + c
		if not walkable_t(t_at(int(floor(q.x / TILE)), int(floor(q.y / TILE)))):
			return false
	return true


func zone_at(p: Vector2) -> Dictionary:
	for z in zones:
		if (z["rect"] as Rect2).has_point(p):
			return z
	return {}


func size_px() -> Vector2:
	return Vector2(w, h) * TILE


## An object stands on the floor: its footprint blocks.
func add_object(o: Dictionary, block: bool = true) -> void:
	objects.append(o)
	if block:
		fill(int(o["x"]), int(o["y"]), int(o.get("w", 1)), int(o.get("h", 1)), T.BLOCK)


# ---------------------------------------------------------------- The floor and the walls

func texture() -> Texture2D:
	if _tex == null:
		_render()
		_tex = ImageTexture.create_from_image(_img)
	return _tex


func _px(x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < _img.get_width() and y < _img.get_height():
		_img.set_pixel(x, y, c)


func _rect(x: int, y: int, rw: int, rh: int, c: Color) -> void:
	var r := Rect2i(x, y, rw, rh).intersection(Rect2i(0, 0, _img.get_width(), _img.get_height()))
	if r.size.x > 0 and r.size.y > 0:
		_img.fill_rect(r, c)


static func hash2(x: int, y: int, s: int = 0) -> float:
	var v := sin(float(x) * 12.9898 + float(y) * 78.233 + float(s) * 3.7) * 43758.5453
	return v - floor(v)


func _render() -> void:
	_img = Image.create(w * TILE, h * TILE, false, Image.FORMAT_RGBA8)
	_img.fill(Color(0, 0, 0, 0))                     # outside the walls: transparent – space shows through
	for y in h:
		for x in w:
			var px := x * TILE
			var py := y * TILE
			match t_at(x, y):
				T.FLOOR, T.DOOR, T.BLOCK:
					_floor_tile(x, y, px, py, floor_kind[y * w + x])
				T.CAP:
					if hull_top < 0 or y < hull_top or _cap_shows(x, y):
						_cap_tile(x, y, px, py)
				T.FACE:
					_face_tile(x, y, px, py)
				T.GLASS:
					_glass_tile(x, y, px, py)
	for rc in round_corners:
		_round_corner(rc)
	for d in decals:
		_decal(d)
	for fd in face_deco:
		_face_deco(fd)
	# soft shadows on the floor below a wall's face
	for y2 in range(1, h):
		for x2 in w:
			var t2 := t_at(x2, y2)
			if walkable_t(t2) or t2 == T.BLOCK:
				var up := t_at(x2, y2 - 1)
				if up == T.FACE or up == T.GLASS:
					_shade(x2 * TILE, y2 * TILE, TILE, 4, 0.25)
				var left := t_at(x2 - 1, y2)
				if left == T.CAP or left == T.FACE:
					_shade_x(x2 * TILE, y2 * TILE, 3, TILE, 0.18)


## A wall's top only where it borders a room – the solid mass behind it is the station's structure (drawn by the view).
func _cap_shows(x: int, y: int) -> bool:
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			var t := t_at(x + dx, y + dy)
			if t != T.CAP and t != T.VOID:
				return true
	return false


## Rounds a window front's upper corner: outside the arc it is space, along it the wall's top (one tile thick, like
## the straight walls), inside it the glass – the window's face reaches down to the floor below.
func _round_corner(rc: Dictionary) -> void:
	var r := int(rc["r"]) * TILE
	var side := int(rc["side"])
	var x0 := int(rc["x"]) * TILE if side < 0 else (int(rc["x"]) + 1) * TILE - r
	var c := Vector2(x0 + r if side < 0 else x0, r)
	var top: Color = pal["wall_top"]
	var fr: Color = pal["frame"]
	for py in r:
		for px in range(x0, x0 + r):
			var d := Vector2(px + 0.5, py + 0.5).distance_to(c)
			if d > r:
				_img.set_pixel(px, py, Color(0, 0, 0))
			elif d > r - 1.2:
				_img.set_pixel(px, py, top.lightened(0.25))
			elif d > r - TILE:
				_img.set_pixel(px, py, top)
			elif d > r - TILE - 2.0:
				_img.set_pixel(px, py, fr)


## The station's structure round the deck, seen from above (tiled by the view): plates, seams, rivets, a vent, a pipe
## run, a small light – the station goes on for kilometres in every direction.
func hull_texture() -> Texture2D:
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var base: Color = Color(pal["wall_top"]).darkened(0.12)
	img.fill(base)
	for py in n:
		for px in n:
			var hv := hash2(px / 16, py / 16, 7)
			var c := base.lightened(0.03) if hv > 0.6 else (base.darkened(0.06) if hv < 0.25 else base)
			if px % 32 == 0 or py % 32 == 0:
				c = base.darkened(0.3)
			elif px % 16 == 0 or py % 16 == 0:
				c = base.darkened(0.14)
			elif (px % 32 == 1) or (py % 32 == 1):
				c = c.lightened(0.07)
			img.set_pixel(px, py, c)
	for k in [Vector2i(3, 3), Vector2i(28, 3), Vector2i(3, 28), Vector2i(28, 28), Vector2i(35, 35), Vector2i(60, 35), Vector2i(35, 60), Vector2i(60, 60)]:
		img.set_pixel(k.x, k.y, base.lightened(0.18))
	for i in 5:
		img.fill_rect(Rect2i(38, 6 + i * 4, 18, 2), base.darkened(0.35))
	img.fill_rect(Rect2i(0, 47, 32, 3), base.lightened(0.08))
	img.fill_rect(Rect2i(0, 50, 32, 1), base.darkened(0.3))
	img.fill_rect(Rect2i(8, 12, 2, 2), Color(pal["accent"]).darkened(0.2))
	return ImageTexture.create_from_image(img)


func _shade(x: int, y: int, rw: int, rh: int, k: float) -> void:
	for yy in range(y, y + rh):
		for xx in range(x, x + rw):
			if xx >= 0 and yy >= 0 and xx < _img.get_width() and yy < _img.get_height():
				var c := _img.get_pixel(xx, yy)
				if c.a > 0.0:
					_img.set_pixel(xx, yy, c.darkened(k * (1.0 - float(yy - y) / maxf(rh, 1))))


func _shade_x(x: int, y: int, rw: int, rh: int, k: float) -> void:
	for yy in range(y, y + rh):
		for xx in range(x, x + rw):
			if xx >= 0 and yy >= 0 and xx < _img.get_width() and yy < _img.get_height():
				var c := _img.get_pixel(xx, yy)
				if c.a > 0.0:
					_img.set_pixel(xx, yy, c.darkened(k * (1.0 - float(xx - x) / maxf(rw, 1))))


func _floor_tile(x: int, y: int, px: int, py: int, fk: int) -> void:
	var f: Color = pal["floor"]
	var f2: Color = pal["floor2"]
	match fk:
		0:              # corridor: metal plates
			_rect(px, py, TILE, TILE, f2 if (x / 2 + y / 2) % 2 == 0 else f)
			_rect(px, py + TILE - 1, TILE, 1, f.darkened(0.15))
			_rect(px + TILE - 1, py, 1, TILE, f.darkened(0.12))
		1:              # shops: warm tiles
			var sf: Color = pal["shop_floor"]
			_rect(px, py, TILE, TILE, sf if (x + y) % 2 == 0 else sf.lightened(0.05))
			_rect(px, py + TILE - 1, TILE, 1, sf.darkened(0.1))
		2:              # the lift lobby: dark stone with a pattern
			var lf: Color = Color(pal["floor"]).darkened(0.25)
			_rect(px, py, TILE, TILE, lf)
			if (x + y) % 2 == 0:
				_rect(px + 6, py + 6, 4, 4, lf.lightened(0.12))
		3:              # the bar: warm wooden planks
			var wood: Color = pal["wood"]
			_rect(px, py, TILE, TILE, wood)
			for k in 4:
				var plank := wood.lightened(0.04 * float((x * 7 + y * 3 + k) % 3))
				_rect(px, py + k * 4, TILE, 4, plank)
				_rect(px, py + k * 4 + 3, TILE, 1, wood.darkened(0.22))
				_rect(px + int(hash2(x, y * 4 + k) * 15), py + k * 4, 1, 3, wood.darkened(0.25))
		4:              # carpet
			var cp: Color = pal["carpet"]
			_rect(px, py, TILE, TILE, cp)
			if (x + y) % 2 == 0:
				_rect(px + 7, py + 7, 2, 2, cp.lightened(0.12))


## The top of a wall – seen from above, a thin lit edge.
func _cap_tile(x: int, y: int, px: int, py: int) -> void:
	var top: Color = pal["wall_top"]
	_rect(px, py, TILE, TILE, top)
	var below := t_at(x, y + 1)
	if walkable_t(below) or below == T.BLOCK:
		_rect(px, py + TILE - 4, TILE, 4, Color(pal["wall"]).darkened(0.05))      # the low face of a thin wall
		_rect(px, py + TILE - 1, TILE, 1, Color(pal["trim"]).darkened(0.3))
	if t_at(x, y - 1) != T.CAP:
		_rect(px, py, TILE, 1, top.lightened(0.25))


## The front face of a wall, lit, with a trim and a skirting board.
func _face_tile(x: int, y: int, px: int, py: int) -> void:
	var wl: Color = pal["wall"]
	_rect(px, py, TILE, TILE, wl)
	if t_at(x, y - 1) != T.FACE:
		_rect(px, py, TILE, 2, wl.lightened(0.18))
	if t_at(x, y + 1) != T.FACE:
		_rect(px, py + TILE - 3, TILE, 3, pal["trim"])
		_rect(px, py + TILE - 1, TILE, 1, Color(pal["trim"]).darkened(0.4))
	if x % 3 == 0:
		_rect(px, py, 1, TILE, wl.darkened(0.1))


## Glass: see-through (space behind), framed – thin mullions, a sill.
func _glass_tile(x: int, y: int, px: int, py: int) -> void:
	_rect(px, py, TILE, TILE, Color(0.55, 0.75, 1.0, 0.07))
	var fr: Color = pal["frame"]
	if t_at(x, y - 1) != T.GLASS:
		_rect(px, py, TILE, 2, fr)
	if t_at(x, y + 1) != T.GLASS:
		_rect(px, py + TILE - 3, TILE, 3, fr.darkened(0.2))
	if t_at(x - 1, y) != T.GLASS:
		_rect(px, py, 2, TILE, fr)
	if t_at(x + 1, y) != T.GLASS:
		_rect(px + TILE - 2, py, 2, TILE, fr)
	if x % 4 == 0 and t_at(x - 1, y) == T.GLASS:
		_rect(px, py, 1, TILE, fr)
	if (x + y) % 5 == 0:
		for k in 6:
			_px(px + 3 + k, py + 10 - k, Color(1, 1, 1, 0.14))


func _decal(d: Dictionary) -> void:
	var px := int(d["x"]) * TILE
	var py := int(d["y"]) * TILE
	var pw := int(d.get("w", 1)) * TILE
	var ph := int(d.get("h", 1)) * TILE
	var c: Color = d.get("col", pal["accent"])
	match String(d["kind"]):
		"stripes":
			for k in int(pw / 4):
				_rect(px + k * 4, py + 1, 2, ph - 2, Color(0.95, 0.75, 0.1))
		"rug":
			_rect(px, py, pw, ph, c.darkened(0.35))
			_rect(px + 2, py + 2, pw - 4, ph - 4, c.darkened(0.1))
			_rect(px + 4, py + 4, pw - 8, ph - 8, c.darkened(0.25))
		"guide":
			_rect(px, py + ph / 2 - 1, pw, 2, Color(pal["floor"]).lerp(c, 0.45))
		"mat":
			_rect(px + 2, py + 3, pw - 4, ph - 6, Color(0.16, 0.14, 0.16))
			for k in int((pw - 6) / 3):
				_rect(px + 3 + k * 3, py + 4, 1, ph - 8, Color(0.16, 0.14, 0.16).lerp(c, 0.35))


## On a wall face: a lamp, a poster, a screen, lift doors, shelves.
func _face_deco(d: Dictionary) -> void:
	var px := int(d["x"]) * TILE
	var py := int(d["y"]) * TILE
	var pw := int(d.get("w", 1)) * TILE
	var c: Color = d.get("col", pal["accent"])
	match String(d["kind"]):
		"lamp":
			_rect(px + 6, py + 3, 4, 4, c.lightened(0.3))
			_rect(px + 5, py + 7, 6, 1, Color(pal["wall"]).darkened(0.3))
		"poster":
			_rect(px + 3, py + 2, pw - 6, 10, Color(0.1, 0.1, 0.12))
			_rect(px + 4, py + 3, pw - 8, 8, c)
			_rect(px + 5, py + 4, int((pw - 10) * 0.6), 2, c.lightened(0.5))
		"screen":
			_rect(px + 2, py + 2, pw - 4, 10, Color(0.05, 0.06, 0.09))
			_rect(px + 3, py + 3, pw - 6, 8, c.darkened(0.4))
			for k in 3:
				_rect(px + 4, py + 4 + k * 2, int((pw - 8) * (0.4 + 0.2 * k)), 1, c)
		"lift":
			_rect(px + 1, py - 12, pw - 2, TILE + 10, Color(0.2, 0.21, 0.24))
			_rect(px + 3, py - 10, pw / 2 - 3, TILE + 7, Color(0.62, 0.65, 0.7))
			_rect(px + pw / 2, py - 10, pw / 2 - 3, TILE + 7, Color(0.56, 0.59, 0.64))
			_rect(px + pw / 2 - 1, py - 10, 1, TILE + 7, Color(0.25, 0.26, 0.3))
			_rect(px + 3, py - 10, 1, TILE + 7, Color(0.75, 0.78, 0.82))
			_rect(px + pw / 2 - 4, py - 15, 8, 3, Color(0.08, 0.08, 0.1))
			_rect(px + pw / 2 - 2, py - 14, 4, 1, c)
		"shelf":
			_rect(px + 1, py + 1, pw - 2, TILE - 3, Color(pal["wall"]).darkened(0.35))
			for k in int((pw - 4) / 4):
				for j in 2:
					_rect(px + 2 + k * 4, py + 2 + j * 6, 3, 4, Color.from_hsv(hash2(k, j, int(d["x"])), 0.55, 0.85))
		"bottles":
			_rect(px + 1, py + 1, pw - 2, TILE - 3, Color(0.3, 0.18, 0.1))
			for k in int((pw - 4) / 3):
				for j in 2:
					var bc: Color = [Color(0.3, 0.75, 0.4), Color(0.85, 0.45, 0.15), Color(0.6, 0.25, 0.7), Color(0.95, 0.85, 0.4)][(k + j * 3) % 4]
					_rect(px + 2 + k * 3, py + 2 + j * 6, 2, 5, bc)
					_px(px + 2 + k * 3, py + 2 + j * 6, bc.lightened(0.5))
		"rack":
			_rect(px + 1, py + 1, pw - 2, TILE - 3, Color(0.18, 0.19, 0.22))
			for k in int((pw - 2) / 5):
				_rect(px + 3 + k * 5, py + 3, 2, TILE - 7, Color(0.6, 0.63, 0.7))
				_rect(px + 2 + k * 5, py + 7, 4, 2, c)
