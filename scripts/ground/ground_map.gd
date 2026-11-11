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
var explore: Array = []                       # 0.7.52.22 (package 52b): boxes, terminals, tablets, relics (scripts/ground/explore.gd)
var zones: Array = []                         # {rect (art px), kind: service/exit/crew/label, id, title, col, sign}
var objects: Array = []                       # furniture: {kind, x, y, w, h (tiles), col, …} – drawn by GroundView
var decals: Array = []                        # flat things painted into the floor: {kind, x, y, w, h, col}
var face_deco: Array = []                     # things on a wall face: {kind, x, y, w, col}
var people: Array = []                        # NPCs that stay: {pos (art px, feet), look?, dir, role, sit, crew?}
var wander: Array = []                        # where strolling NPCs may go (art px)
var lights: Array = []                        # light pools (the view adds them): {pos (art px), r, col, a, flicker}
var lifts: Array = []                         # lift doors on a wall face: {x, y, w} (tiles) – the view animates them
var holos: Array = []                         # holographic adverts over a wall: {pos (art px, bottom centre), text, sub, col}
var spawn := Vector2.ZERO
var pal: Dictionary = {}
var hull_top := -9999                 # the station's structure goes on everywhere from this row down (the view draws it)
var under_glass := -1                 # floor kind seen through glass (the hangar below the walkway); -1: space
var ship_at := Vector2.INF
var bay_rect := Rect2()               # tiles: the hangar bay (the view lays a haze over it – it is far below)            # the hangar: where the player's ship stands (art px)
var window_rect := Rect2()            # tiles: where space shows through the glass (the view draws it there only)
var round_corners: Array = []         # {x, r, side}: a window front's corner rounded off (tiles; side -1 west, +1 east)
var title := ""
var style := ""                       # 0.7.53.2: a dungeon theme's own walls and floors ("precursor": rusted iron)
var pads: Array = []                  # 0.7.50.10: a settlement's landing pads – their centres (art px)
var pad_rects: Array = []             # 0.7.50.15: the pads themselves (art px) – their lights follow them
var foe_spawns: Array = []             # package 52: where foes stand when a fight is set up (art px)
var econ: Dictionary = {}             # 0.7.50.12: a settlement's economy area – {kind, rect (art px), …} for its life
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


var _astar: AStarGrid2D


## A path (art px, tile centres) from a to b round walls and furniture – empty if there is none.
func path(a: Vector2, b: Vector2) -> PackedVector2Array:
	if _astar == null:
		_astar = AStarGrid2D.new()
		_astar.region = Rect2i(0, 0, w, h)
		_astar.cell_size = Vector2(TILE, TILE)
		_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
		_astar.update()
		for y in h:
			for x in w:
				_astar.set_point_solid(Vector2i(x, y), not walkable_t(t_at(x, y)))
	var ta := Vector2i(clampi(int(a.x / TILE), 0, w - 1), clampi(int(a.y / TILE), 0, h - 1))
	var tb := Vector2i(clampi(int(b.x / TILE), 0, w - 1), clampi(int(b.y / TILE), 0, h - 1))
	if _astar.is_point_solid(ta) or _astar.is_point_solid(tb):
		return PackedVector2Array()
	var pts := _astar.get_point_path(ta, tb)
	var out := PackedVector2Array()
	for k in range(1, pts.size()):
		out.append(pts[k] + Vector2(TILE, TILE) * 0.5)
	if not out.is_empty():
		out[out.size() - 1] = b
	return out


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

## 0.7.52.28: draw the floor and walls again (a shaft opened) – into the same texture.
func refresh_texture() -> void:
	if _tex == null:
		return
	_render()
	(_tex as ImageTexture).update(_img)


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
					if under_glass >= 0:
						_floor_tile(x, y, px, py, under_glass)
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
				if up == T.CAP:
					# the neon strip's light spilling onto the floor
					for k in 4:
						_tint(x2 * TILE, y2 * TILE + k, TILE, 1, pal["accent"], [0.3, 0.17, 0.09, 0.04][k])


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
	if pal.has("terrain_b"):
		# package 50: on a planet the ground goes on all round – rougher, a little darker
		var ta: Color = pal["terrain_b"]
		var tb: Color = pal["terrain_c"]
		for py in n:
			for px in n:
				var hv := hash2(px / 3, py / 3, 50)
				img.set_pixel(px, py, ta.lerp(tb, hv * 0.7).darkened(0.12 + 0.1 * hash2(px, py, 7)))
		for k in 10:
			var rx := int(hash2(k, 1, 9) * 58)
			var ry := int(hash2(k, 2, 9) * 58)
			img.fill_rect(Rect2i(rx, ry, 4, 3), ta.darkened(0.45))
			img.fill_rect(Rect2i(rx, ry, 4, 1), ta.darkened(0.2))
		return ImageTexture.create_from_image(img)
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


func _tint(x: int, y: int, rw: int, rh: int, c: Color, k: float) -> void:
	for yy in range(y, y + rh):
		for xx in range(x, x + rw):
			if xx >= 0 and yy >= 0 and xx < _img.get_width() and yy < _img.get_height():
				var o := _img.get_pixel(xx, yy)
				if o.a > 0.0:
					_img.set_pixel(xx, yy, Color(o.r + c.r * k, o.g + c.g * k, o.b + c.b * k, o.a))


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
		5:              # heavy deck plates with rivets (military, shipyard)
			var mp: Color = Color(pal["floor2"]).darkened(0.08)
			_rect(px, py, TILE, TILE, mp)
			_rect(px, py, TILE, 1, mp.lightened(0.1))
			_rect(px, py + TILE - 1, TILE, 1, mp.darkened(0.25))
			_rect(px + TILE - 1, py, 1, TILE, mp.darkened(0.2))
			for c in [Vector2i(2, 2), Vector2i(13, 2), Vector2i(2, 13), Vector2i(13, 13)]:
				_px(px + c.x, py + c.y, mp.lightened(0.25))
		6:              # bright tiles (research, ice, resort halls)
			var tc: Color = Color(pal["floor2"]).lightened(0.08)
			_rect(px, py, TILE, TILE, tc if (x + y) % 2 == 0 else tc.darkened(0.04))
			_rect(px, py + TILE - 1, TILE, 1, tc.darkened(0.12))
			_rect(px + TILE - 1, py, 1, TILE, tc.darkened(0.1))
		7:              # sand
			var sc := Color(0.86, 0.76, 0.55)
			_rect(px, py, TILE, TILE, sc)
			for k in 6:
				_px(px + int(hash2(x, y, k) * 15), py + int(hash2(y, x, k + 9) * 15), sc.darkened(0.1 + 0.08 * (k % 2)))
		8:              # grating (industry)
			var gc: Color = Color(pal["floor2"]).darkened(0.15)
			_rect(px, py, TILE, TILE, gc.darkened(0.35))
			for k in 4:
				_rect(px, py + k * 4, TILE, 2, gc)
			_rect(px + TILE - 1, py, 1, TILE, gc.darkened(0.45))
		9:              # dark worn planks (mining, pirates)
			var dw: Color = Color(pal["wood"]).darkened(0.35)
			_rect(px, py, TILE, TILE, dw)
			for k in 2:
				_rect(px, py + k * 8 + 7, TILE, 1, dw.darkened(0.35))
				_rect(px + int(hash2(x, y * 2 + k) * 15), py + k * 8, 1, 7, dw.darkened(0.3))
			if hash2(x, y, 5) > 0.85:
				_rect(px + 4, py + 5, 5, 3, dw.darkened(0.2))
		11:             # the hangar floor far below: small plates (it is far away), seams, now and then a stain
			var hc: Color = Color(pal["floor"]).darkened(0.4)
			for qy in 4:
				for qx in 4:
					_rect(px + qx * 4, py + qy * 4, 4, 4, hc if (x * 4 + qx + y * 4 + qy) % 2 == 0 else hc.darkened(0.05))
			_rect(px, py + TILE - 1, TILE, 1, hc.darkened(0.2))
			_rect(px + TILE - 1, py, 1, TILE, hc.darkened(0.18))
			if hash2(x, y, 11) > 0.9:
				_rect(px + 5, py + 7, 3, 2, hc.darkened(0.2))
		12:             # a diner's checkered floor
			var a := Color(0.9, 0.88, 0.84)
			var b := Color(0.16, 0.15, 0.17)
			for qy in 2:
				for qx in 2:
					_rect(px + qx * 8, py + qy * 8, 8, 8, a if (qx + qy) % 2 == 0 else b)
		13:             # the ground of a planet – its own colours, a little noise and pebbles
			var ta: Color = pal.get("terrain_b", Color(0.5, 0.45, 0.35))
			var tb: Color = pal.get("terrain_c", Color(0.6, 0.55, 0.42))
			for qy in 4:
				for qx in 4:
					var hv := hash2(x * 4 + qx, y * 4 + qy, 13)
					_rect(px + qx * 4, py + qy * 4, 4, 4, ta.lerp(tb, hv * 0.6).darkened(0.08 * hash2(qx, qy, x + y)))
			if hash2(x, y, 31) > 0.8:
				_rect(px + int(hash2(x, y, 3) * 12), py + int(hash2(y, x, 4) * 12), 2, 2, ta.darkened(0.35))
		14:             # the landing pad: concrete slabs
			var cc := Color(0.52, 0.53, 0.55)
			_rect(px, py, TILE, TILE, cc if (x + y) % 2 == 0 else cc.darkened(0.04))
			_rect(px, py + TILE - 1, TILE, 1, cc.darkened(0.2))
			_rect(px + TILE - 1, py, 1, TILE, cc.darkened(0.18))
			if hash2(x, y, 14) > 0.85:
				_rect(px + 4, py + 6, 5, 3, cc.darkened(0.15))
		15:             # a gravel path
			var gc := Color(pal.get("terrain_c", Color(0.6, 0.55, 0.42))).lerp(Color(0.55, 0.55, 0.55), 0.6)
			_rect(px, py, TILE, TILE, gc)
			for k in 8:
				_px(px + int(hash2(x, y, k) * 15), py + int(hash2(y, x, k + 3) * 15), gc.darkened(0.25))
		17:             # 0.7.53.2: the Precursors' rusted iron floor
			_precursor_floor(x, y, px, py)
		16:             # 0.7.52.27: an air duct – dark steel, ribs across its run (0.7.52.28: walls on its closed sides)
			_duct_tile(x, y, px, py)
		10:             # water (a pool)
			var wc := Color(0.2, 0.6, 0.8)
			_rect(px, py, TILE, TILE, wc)
			for k in 3:
				var wy := int(hash2(x, y, k) * 14)
				_rect(px + int(hash2(y, x, k) * 10), py + wy, 5, 1, wc.lightened(0.3))
			if t_at(x, y - 1) != T.BLOCK or floor_kind[(y - 1) * w + x] != 10:
				_rect(px, py, TILE, 3, Color(0.85, 0.9, 0.92))
				_rect(px, py + 3, TILE, 2, wc.darkened(0.3))
			if y + 1 < h and floor_kind[(y + 1) * w + x] != 10:
				_rect(px, py + TILE - 2, TILE, 2, Color(0.85, 0.9, 0.92))
			if x > 0 and floor_kind[y * w + x - 1] != 10:
				_rect(px, py, 2, TILE, Color(0.85, 0.9, 0.92))
			if x + 1 < w and floor_kind[y * w + x + 1] != 10:
				_rect(px + TILE - 2, py, 2, TILE, Color(0.85, 0.9, 0.92))


## The top of a wall – seen from above, a thin lit edge.
## 0.7.53.2 (Luz): rusted iron – a panel with its seams and rivets, rust in patches and streaks running down.
func _rust(px: int, py: int, pw: int, ph: int, base: Color, sd: int) -> void:
	_rect(px, py, pw, ph, base)
	_rect(px, py, pw, 1, base.lightened(0.16))
	_rect(px, py + ph - 1, pw, 1, base.darkened(0.35))
	_rect(px + pw - 1, py, 1, ph, base.darkened(0.28))
	for c in [Vector2i(2, 2), Vector2i(pw - 3, 2), Vector2i(2, ph - 3), Vector2i(pw - 3, ph - 3)]:
		_px(px + c.x, py + c.y, base.lightened(0.3))
	for i in int(pw * ph / 26):
		var rx := px + int(hash2(i, sd, 1) * pw)
		var ry := py + int(hash2(i, sd, 2) * ph)
		var rc := Color(0.55, 0.28, 0.12).lerp(Color(0.36, 0.19, 0.1), hash2(i, sd, 3))
		_rect(rx, ry, 1 + int(hash2(i, sd, 4) * 2.5), 1 + int(hash2(i, sd, 5) * 1.8), rc)
	var sx := px + 2 + int(hash2(sd, 7) * (pw - 4))
	var sl := int(ph * (0.3 + 0.6 * hash2(sd, 8)))
	for yy in sl:
		_tint(sx, py + 2 + yy, 1, 1, Color(0.5, 0.25, 0.1), 0.5 * (1.0 - float(yy) / maxf(sl, 1)))


## A crack: a jagged dark line downwards from (x, y).
func _crack(x: int, y: int, n: int, sd: int) -> void:
	var cx := x
	var cy := y
	for i in n:
		_px(cx, cy, Color(0.07, 0.05, 0.04))
		cx += int(round(hash2(i, sd, 11) * 2.0 - 1.0))
		cy += 1
		if cx < 0 or cy >= h * TILE:
			return


## The Precursors' floor: rusted iron panels; here and there a crack, a hole into the dark, rubble, a bit of rubbish.
func _precursor_floor(x: int, y: int, px: int, py: int) -> void:
	var base := Color(0.34, 0.25, 0.19).lerp(Color(0.28, 0.2, 0.15), hash2(x, y, 21))
	_rust(px, py, TILE, TILE, base, x * 31 + y * 17)
	var r := hash2(x, y, 22)
	if r < 0.12:
		_crack(px + 3 + int(hash2(x, y, 23) * 9), py + 1, 8 + int(hash2(x, y, 24) * 6), x + y * 7)
	elif r < 0.16:
		# a hole: dark, its broken lip lit on top
		var hx := px + 4 + int(hash2(x, y, 25) * 4)
		var hy := py + 4 + int(hash2(x, y, 26) * 4)
		_rect(hx, hy, 7, 5, Color(0.03, 0.02, 0.02))
		_rect(hx + 1, hy - 1, 5, 1, Color(0.03, 0.02, 0.02))
		_rect(hx, hy, 7, 1, Color(0.46, 0.33, 0.24))
	elif r < 0.3:
		for k in 3 + int(hash2(x, y, 27) * 4):           # rubble
			_rect(px + int(hash2(k, x * 3 + y, 28) * 14), py + int(hash2(k, x + y * 5, 29) * 14), 1 + int(hash2(k, x, 30) * 2), 1, Color(0.42, 0.38, 0.33).lerp(Color(0.22, 0.18, 0.15), hash2(k, y, 31)))
	elif r < 0.34:
		_rect(px + 4, py + 9, 6, 1, Color(0.55, 0.55, 0.52))   # a bent strip of metal
		_rect(px + 9, py + 7, 1, 2, Color(0.55, 0.55, 0.52))


## The Precursors' wall face: tall rusted panels, cracks, streaks, a rusted ledge at the foot.
func _precursor_face(x: int, y: int, px: int, py: int) -> void:
	var wl: Color = Color(pal["wall"]).lerp(Color(0.36, 0.25, 0.18), hash2(x, 0, 41))
	if t_at(x, y - 1) != T.FACE:
		wl = wl.darkened(0.12)                           # the upper row lies in the shadow of the ceiling
	_rust(px, py, TILE, TILE, wl, x * 13 + y * 3)
	for gx in [5, 11]:
		_rect(px + gx, py, 1, TILE, wl.darkened(0.32))  # tall panels: vertical grooves, unlike the floor's plates
	if t_at(x, y - 1) != T.FACE:
		_rect(px, py, TILE, 2, wl.lightened(0.15))
	if t_at(x, y + 1) != T.FACE:
		_rect(px, py + TILE - 3, TILE, 3, Color(pal["trim"]))
		_rect(px, py + TILE - 1, TILE, 1, Color(pal["trim"]).darkened(0.4))
	if hash2(x, y, 42) < 0.18:
		_crack(px + 3 + int(hash2(x, y, 43) * 10), py + 2, 10, x * 5 + y)
	if x % 4 == 0:
		_rect(px, py, 2, TILE, wl.darkened(0.2))         # a rib between the panels
		_rect(px, py, 1, TILE, wl.lightened(0.1))


func _cap_tile(x: int, y: int, px: int, py: int) -> void:
	if style == "precursor":
		# the solid mass of the ruin: dark iron, barely a speck of rust – so the rooms read as rooms
		var top0: Color = Color(pal["wall_top"]).lerp(Color(0.09, 0.07, 0.06), 0.5 + 0.3 * hash2(x, y, 51))
		_rect(px, py, TILE, TILE, top0)
		if (x + y) % 3 == 0:
			_px(px + int(hash2(x, y, 52) * 15), py + int(hash2(y, x, 53) * 15), Color(0.32, 0.17, 0.09))
		if x % 2 == 0:
			_rect(px, py, 1, TILE, top0.darkened(0.3))
		if y % 2 == 0:
			_rect(px, py, TILE, 1, top0.darkened(0.3))
		var rim: Color = Color(pal["wall"]).darkened(0.1)
		if t_at(x, y - 1) != T.CAP and t_at(x, y - 1) != T.VOID:
			_rect(px, py, TILE, 2, rim)
		if t_at(x - 1, y) != T.CAP and t_at(x - 1, y) != T.VOID:
			_rect(px, py, 2, TILE, rim)
		if t_at(x + 1, y) != T.CAP and t_at(x + 1, y) != T.VOID:
			_rect(px + TILE - 2, py, 2, TILE, rim.darkened(0.2))
		var below0 := t_at(x, y + 1)
		if walkable_t(below0) or below0 == T.BLOCK:
			_rect(px, py + TILE - 3, TILE, 3, Color(pal["wall"]).darkened(0.25))
		elif below0 == T.FACE:
			_rect(px, py + TILE - 2, TILE, 2, rim.lightened(0.1))
		return
	var top: Color = pal["wall_top"]
	_rect(px, py, TILE, TILE, top)
	var below := t_at(x, y + 1)
	var duct_below: bool = y + 1 < h and floor_kind[(y + 1) * w + x] == 16 and walkable_t(below)
	if duct_below:
		pass                                                                      # 0.7.52.28: over a duct – its own rim
	elif walkable_t(below) or below == T.BLOCK:
		_rect(px, py + TILE - 4, TILE, 4, Color(pal["wall"]).darkened(0.05))      # the low face of a thin wall
		var ac: Color = pal["accent"]
		_rect(px, py + TILE - 2, TILE, 1, ac.darkened(0.2))                      # a neon strip along its foot
		_rect(px, py + TILE - 1, TILE, 1, ac.lerp(Color.WHITE, 0.35))
	if t_at(x, y - 1) != T.CAP:
		_rect(px, py, TILE, 1, top.lightened(0.25))


## 0.7.52.28 (Luz): a duct's tile – open towards the duct and rooms it joins, a wall rim on every other side; its ribs
## run across the way it goes (both ways at a bend).
func _duct_tile(x: int, y: int, px: int, py: int) -> void:
	var base := Color(0.2, 0.21, 0.24)
	_rect(px, py, TILE, TILE, base)
	var open := {}
	for dv in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var nx: int = x + dv.x
		var ny: int = y + dv.y
		var nt := t_at(nx, ny)
		var duct: bool = nx >= 0 and ny >= 0 and nx < w and ny < h and floor_kind[ny * w + nx] == 16 and (walkable_t(nt) or nt == T.BLOCK)
		open[dv] = duct or walkable_t(nt)
	var horiz: bool = open[Vector2i(-1, 0)] or open[Vector2i(1, 0)]
	var vert: bool = open[Vector2i(0, -1)] or open[Vector2i(0, 1)]
	for k in 4:
		if vert or not horiz:
			_rect(px + 1, py + 2 + k * 4, TILE - 2, 1, Color(0.28, 0.3, 0.33))
		if horiz:
			_rect(px + 2 + k * 4, py + 1, 1, TILE - 2, Color(0.28, 0.3, 0.33))
	var rim := Color(0.42, 0.44, 0.48)
	var dark := Color(0.08, 0.08, 0.09)
	if not open[Vector2i(0, -1)]:
		_rect(px, py, TILE, 2, rim)
		_rect(px, py + 2, TILE, 1, dark)
	if not open[Vector2i(0, 1)]:
		_rect(px, py + TILE - 2, TILE, 2, rim.darkened(0.3))
	if not open[Vector2i(-1, 0)]:
		_rect(px, py, 2, TILE, rim.darkened(0.1))
		_rect(px + 2, py, 1, TILE, dark)
	if not open[Vector2i(1, 0)]:
		_rect(px + TILE - 2, py, 2, TILE, rim.darkened(0.25))
		_rect(px + TILE - 3, py, 1, TILE, dark)


## The front face of a wall, lit, with a trim and a skirting board.
func _face_tile(x: int, y: int, px: int, py: int) -> void:
	if style == "precursor":
		_precursor_face(x, y, px, py)
		return
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
	if under_glass >= 0:
		_tint(px, py, TILE, TILE, Color(0.55, 0.75, 1.0), 0.1)        # the hangar shows through
	else:
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
			# a lit line set into the floor
			_tint(px, py + ph / 2 - 3, pw, 1, c, 0.08)
			_tint(px, py + ph / 2 - 2, pw, 1, c, 0.18)
			_rect(px, py + ph / 2 - 1, pw, 2, c.lerp(Color.WHITE, 0.25))
			_tint(px, py + ph / 2 + 1, pw, 1, c, 0.18)
			_tint(px, py + ph / 2 + 2, pw, 1, c, 0.08)
		"bay":                     # far down in the bay: tiny crates, carts and floor lights – the scale of a giant room
			for k in int(pw * ph / 700):
				var tx := px + 2 + int(hash2(k, 3, 7) * (pw - 6))
				var edge := hash2(k, 4, 7)
				var ty := py + 2 + (int(hash2(k, 5, 7) * 6) if edge < 0.5 else ph - 8 + int(hash2(k, 5, 7) * 5))
				var kc: Color = [Color(0.45, 0.35, 0.22), Color(0.35, 0.38, 0.42), Color(0.6, 0.5, 0.2)][k % 3]
				_rect(tx, ty, 3 + k % 2, 2, kc)
				_rect(tx, ty, 3 + k % 2, 1, kc.lightened(0.2))
			for k2 in int(pw / 12):
				_px(px + 6 + k2 * 12, py + 1, c.lightened(0.3))
				_px(px + 6 + k2 * 12, py + ph - 2, c.lightened(0.3))
		"pad":                     # the landing marks on the hangar floor
			_tint(px, py, pw, 2, c, 0.35)
			_tint(px, py + ph - 2, pw, 2, c, 0.35)
			for k in int(pw / 6):
				_rect(px + k * 6, py, 3, 2, c.darkened(0.1))
				_rect(px + k * 6, py + ph - 2, 3, 2, c.darkened(0.1))
			var cx := px + pw / 2
			var cy := py + ph / 2
			for k2 in 64:
				var an := k2 * TAU / 64.0
				_px(cx + int(cos(an) * ph * 0.42), cy + int(sin(an) * ph * 0.42), c.darkened(0.15))
		# ---- 0.7.50.12: the economy areas
		"pit":                     # an open pit mine: terraces stepping down, a ramp winding into it, water at the bottom
			var levels := int(d.get("levels", 5))
			var stp := int(d.get("step", 14))
			var ground: Color = pal.get("terrain_b", Color(0.5, 0.42, 0.34))
			for lv in levels:
				var inset := lv * stp
				var rr := Rect2i(px + inset, py + inset, pw - inset * 2, ph - inset * 2)
				if rr.size.x < 8 or rr.size.y < 8:
					break
				var lc := ground.lightened(0.06).darkened(lv * 0.06).lerp(Color(0.6, 0.46, 0.32), 0.12 + 0.1 * lv / levels)
				_rect(rr.position.x, rr.position.y, rr.size.x, rr.size.y, lc)
				_rect(rr.position.x, rr.position.y, rr.size.x, 6, lc.darkened(0.3))       # the terrace's face (in shade)
				_rect(rr.position.x, rr.position.y, 4, rr.size.y, lc.darkened(0.18))
				_rect(rr.position.x + rr.size.x - 3, rr.position.y, 3, rr.size.y, lc.lightened(0.08))
				_rect(rr.position.x, rr.position.y + rr.size.y - 2, rr.size.x, 2, lc.lightened(0.12))   # the lit edge below
				_rect(rr.position.x, rr.position.y + 6, rr.size.x, 1, lc.lightened(0.1))
				for kk in int(rr.size.x / 9):                                                   # strata in the face
					_px(rr.position.x + kk * 9 + 3, rr.position.y + 2 + kk % 3, lc.darkened(0.45))
				for k in int(rr.size.x * rr.size.y / 60):
					_px(rr.position.x + int(hash2(k, lv, 1) * rr.size.x), rr.position.y + int(hash2(k, lv, 2) * rr.size.y), lc.darkened(0.1) if k % 2 else lc.lightened(0.06))
			# the ramp: down the west side, then along each terrace
			for t in levels:                                                                    # the ramp's track down each terrace
				_rect(px + t * stp + 6, py + t * stp + stp / 2, pw - t * stp * 2 - 20, 3, ground.darkened(0.02 + t * 0.06).lightened(0.1))
				_rect(px + t * stp + 6, py + t * stp + stp / 2, 3, stp, ground.lightened(0.08))
			var bot := Rect2i(px + levels * stp, py + levels * stp, pw - levels * stp * 2, ph - levels * stp * 2)
			if bot.size.x > 12 and bot.size.y > 12:
				_rect(bot.position.x + bot.size.x - bot.size.x / 4 - 4, bot.position.y + bot.size.y - bot.size.y / 4 - 4, bot.size.x / 4, bot.size.y / 5, Color(0.28, 0.35, 0.38))   # a pool
				_rect(bot.position.x + bot.size.x - bot.size.x / 4 - 4, bot.position.y + bot.size.y - bot.size.y / 4 - 4, bot.size.x / 4, 1, Color(0.5, 0.6, 0.65))
		"pit_edge":                # 0.7.50.13: an open pit seen from its rim – the berm, then faces and benches stepping down
			var ground2: Color = pal.get("terrain_b", Color(0.5, 0.42, 0.34))
			var rock := ground2.darkened(0.2).lerp(Color(0.55, 0.45, 0.36), 0.3)
			var depth := 0
			for b in d.get("bands", []):
				var y0 := int(b[0])
				var y1 := int(b[1])
				var kind := String(b[2])
				match kind:
					"rim":                                       # the berm along the rim, posts with reflectors
						_rect(px, y1 - 14, pw, 8, ground2.lightened(0.12))
						_rect(px, y1 - 6, pw, 6, ground2.darkened(0.15))
						for x in range(px + 6, px + pw, 28):
							_rect(x, y1 - 26, 2, 14, Color(0.85, 0.85, 0.8))
							_rect(x, y1 - 24, 2, 3, Color(1.0, 0.4, 0.2))
					"face":                                      # a rock face: strata, cracks, the lip lit
						var fc := rock.darkened(0.1 + depth * 0.06)
						_rect(px, y0, pw, y1 - y0, fc)
						var sy := y0 + 3
						var band_i := 0
						while sy < y1 - 2:
							var sh := 4 + int(hash2(band_i, depth, 11) * 6)
							_rect(px, sy, pw, sh, fc.lightened(0.06) if band_i % 2 == 0 else fc.darkened(0.06))
							sy += sh
							band_i += 1
						for k in int(pw / 26):                       # a few cracks down the face
							var cx := px + int(hash2(k, depth, 12) * pw)
							var cl := int((y1 - y0) * (0.3 + hash2(k, depth, 15) * 0.5))
							for t in cl:
								_px(cx + (t / 9) % 2, y0 + 4 + t, fc.darkened(0.3))
						_rect(px, y0, pw, 3, fc.lightened(0.22))
						_rect(px, y1 - 3, pw, 3, fc.darkened(0.25))
					"bench":                                     # a bench: its floor, tyre tracks, the safety berm at its edge
						var bc := ground2.darkened(0.06 + depth * 0.05)
						_rect(px, y0, pw, y1 - y0, bc)
						for k2 in int(pw * (y1 - y0) / 80):
							_px(px + int(hash2(k2, depth, 13) * pw), y0 + int(hash2(k2, depth, 14) * (y1 - y0)), bc.darkened(0.12) if k2 % 2 else bc.lightened(0.07))
						for tr in 2:
							var ty := y1 - 14 - tr * 9
							for x2 in range(px, px + pw, 3):
								_px(x2, ty, bc.darkened(0.15))
								_px(x2 + 1, ty + 4, bc.darkened(0.15))
						_rect(px, y1 - 4, pw, 4, bc.lightened(0.1))
						depth += 1
			# the haul road down: a ramp cut across the faces on the east side
			var bands2: Array = d.get("bands", [])
			if bands2.size() >= 5:
				var ry0 := int(bands2[1][0])
				var ry1 := int(bands2[4][1]) - 10
				for y3 in range(ry0, ry1):
					var u := float(y3 - ry0) / float(maxi(1, ry1 - ry0))
					var rx0 := px + pw - 60 - int(u * 120)
					_rect(rx0, y3, 44, 1, ground2.darkened(0.04 + u * 0.12))
					_px(rx0, y3, ground2.darkened(0.3))
					_px(rx0 + 43, y3, ground2.lightened(0.1))
		"field":                   # a field: rows of its crop, a darker edge, the soil between
			var soil := Color(0.36, 0.26, 0.16)
			_rect(px, py, pw, ph, soil)
			var vert := bool(d.get("vert", false))
			if vert:
				for x in range(px + 1, px + pw - 1, 3):
					_rect(x, py + 2, 2, ph - 4, c)
					for y in range(py + 2, py + ph - 2, 4):
						_px(x, y, c.lightened(0.15))
			else:
				for y in range(py + 1, py + ph - 1, 3):
					_rect(px + 2, y, pw - 4, 2, c)
					for x in range(px + 2, px + pw - 2, 4):
						_px(x, y, c.lightened(0.15))
			_rect(px, py, pw, 1, soil.darkened(0.3))
			_rect(px, py + ph - 1, pw, 1, soil.lightened(0.15))
		"piperun":                 # a run of pipes along the ground, with flanges and a valve now and then
			for k in 3:
				var yy := py + 3 + k * 4
				_rect(px, yy, pw, 3, Color(0.5, 0.52, 0.55).darkened(k * 0.08))
				_rect(px, yy, pw, 1, Color(0.7, 0.72, 0.75))
				for fx in range(px + 6, px + pw, 24):
					_rect(fx, yy - 1, 2, 5, Color(0.35, 0.36, 0.38))
			for vx in range(px + 18, px + pw, 60):
				_rect(vx, py, 4, 3, Color(0.85, 0.2, 0.2))
		"cable":                   # cables lying on the ground between two points (w: right, h: down)
			var x1 := px + int(d.get("dx", 0))
			var y1 := py + int(d.get("dy", 0))
			var n := maxi(absi(x1 - px), absi(y1 - py))
			for t in n:
				var u := float(t) / maxf(n, 1)
				_px(int(lerpf(px, x1, u)), int(lerpf(py, y1, u)) + int(sin(u * 9.0) * 1.5), Color(0.12, 0.12, 0.14))
		"boardwalk":               # a floating walkway – 0.7.51.6: steel grating on pontoons, a light strip along its edges
			_rect(px, py, pw, ph, Color(0.3, 0.32, 0.36))
			for x in range(px, px + pw, 3):
				_rect(x, py, 1, ph, Color(0.22, 0.24, 0.27))
			for y in range(py, py + ph, 3):
				_rect(px, y, pw, 1, Color(0.24, 0.26, 0.29))
			_rect(px, py, pw, 1, Color(0.55, 0.58, 0.62))
			_rect(px, py + ph - 2, pw, 2, Color(0.18, 0.19, 0.22))
			if pw >= ph:
				_rect(px, py + 1, pw, 1, Color(0.35, 0.95, 1.0, 0.7))
			else:
				_rect(px + 1, py, 1, ph, Color(0.35, 0.95, 1.0, 0.7))
				_rect(px + pw - 2, py, 1, ph, Color(0.35, 0.95, 1.0, 0.7))
		"canal":                   # an irrigation channel
			_rect(px, py, pw, ph, Color(0.2, 0.35, 0.5))
			_rect(px, py, pw, 1, Color(0.45, 0.6, 0.72))
			for k in int(pw * ph / 30):
				_px(px + int(hash2(k, 3, 7) * pw), py + int(hash2(k, 4, 7) * ph), Color(0.55, 0.72, 0.85))
		"yard":                    # a work yard: concrete slabs, painted lines, oil stains
			_rect(px, py, pw, ph, Color(0.4, 0.4, 0.41))
			for x in range(px, px + pw, 32):
				_rect(x, py, 1, ph, Color(0.34, 0.34, 0.35))
			for y in range(py, py + ph, 32):
				_rect(px, y, pw, 1, Color(0.34, 0.34, 0.35))
			for k in int(pw / 40):
				_rect(px + 8 + k * 40, py + ph / 2, 20, 2, Color(0.9, 0.75, 0.2))
			for k2 in int(pw * ph / 3000):
				var sx := px + int(hash2(k2, 9, 1) * pw)
				var sy := py + int(hash2(k2, 9, 2) * ph)
				_rect(sx, sy, 6, 4, Color(0.3, 0.3, 0.31))
		"pen":                     # a fish pen floating on the sea: a ring of floats, the net below
			var cx := px + pw / 2
			var cy := py + ph / 2
			var r := mini(pw, ph) / 2 - 2
			for a in 64:
				var ang := a * TAU / 64.0
				_rect(cx + int(cos(ang) * r) - 1, cy + int(sin(ang) * r * 0.8) - 1, 3, 3, Color(0.85, 0.55, 0.2) if a % 8 == 0 else Color(0.6, 0.62, 0.65))
			for k3 in 40:
				var a2 := hash2(k3, 5, 5) * TAU
				var rr2 := sqrt(hash2(k3, 6, 5)) * r * 0.85
				_px(cx + int(cos(a2) * rr2), cy + int(sin(a2) * rr2 * 0.8), Color(0.75, 0.82, 0.88))
		"landing_pad":             # 0.7.50.15: a landing pad in detail
			_landing_pad(px, py, pw, ph, c, int(d.get("n", 1)))
		"pad_marks":               # the landing pad's markings: a yellow frame, a big H
			_rect(px, py, pw, 2, c)
			_rect(px, py + ph - 2, pw, 2, c)
			_rect(px, py, 2, ph, c)
			_rect(px + pw - 2, py, 2, ph, c)
			for k in int(pw / 12):
				_rect(px + 4 + k * 12, py + 4, 6, 1, c.darkened(0.2))
				_rect(px + 4 + k * 12, py + ph - 5, 6, 1, c.darkened(0.2))
		"ramp":                    # the ship's ramp, down to the pad
			_rect(px, py, pw, ph, Color(0.38, 0.4, 0.45))
			for k in int(ph / 3):
				_rect(px, py + k * 3, pw, 1, Color(0.3, 0.32, 0.36))
			_rect(px, py, 1, ph, c)
			_rect(px + pw - 1, py, 1, ph, c)
		"stairs":                  # steps going down to the west, each a little darker
			var steps := int(pw / 4)
			for k in steps:
				var sc: Color = Color(pal["floor"]).darkened(0.05 + 0.5 * float(k) / steps)
				_rect(px + pw - (k + 1) * 4, py, 4, ph, sc)
				_rect(px + pw - (k + 1) * 4, py, 1, ph, sc.lightened(0.25))
			_rect(px, py, pw, 1, c)
			_rect(px, py + ph - 1, pw, 1, c)
		"mat":
			_rect(px + 2, py + 3, pw - 4, ph - 6, Color(0.16, 0.14, 0.16))
			for k in int((pw - 6) / 3):
				_rect(px + 3 + k * 3, py + 4, 1, ph - 8, Color(0.16, 0.14, 0.16).lerp(c, 0.35))


const DIGITS := {"0": ["111", "101", "101", "101", "111"], "1": ["010", "110", "010", "010", "111"], "2": ["111", "001", "111", "100", "111"],
	"3": ["111", "001", "111", "001", "111"], "4": ["101", "101", "111", "001", "001"], "5": ["111", "100", "111", "001", "111"],
	"6": ["111", "100", "111", "101", "111"], "7": ["111", "001", "010", "010", "010"], "8": ["111", "101", "111", "101", "111"],
	"9": ["111", "101", "111", "001", "111"]}


## 0.7.50.15 (Luz): a landing pad in detail – its slabs each a little their own, the scorch of the lift-offs round its
## middle, the touchdown ring with its H, a hazard band round its edge with a white line inside, the corner brackets,
## its number painted big, the edge lights in their housings, drainage grates, tie-down rings, the fuel hatch.
func _landing_pad(px: int, py: int, pw: int, ph: int, c: Color, n: int) -> void:
	var base: Color = Color(pal.get("floor", Color(0.45, 0.46, 0.48))).lerp(Color(0.56, 0.57, 0.59), 0.45)
	for sy in range(0, ph, 28):
		for sx in range(0, pw, 32):
			var tw2 := mini(32, pw - sx)
			var th2 := mini(28, ph - sy)
			var tn := (hash2(px + sx, py + sy, 3) - 0.5) * 0.09
			_rect(px + sx, py + sy, tw2, th2, base.lightened(tn) if tn > 0.0 else base.darkened(-tn))
			_rect(px + sx, py + sy, tw2, 1, base.darkened(0.22))
			_rect(px + sx, py + sy, 1, th2, base.darkened(0.22))
			if hash2(px + sx, py + sy, 9) < 0.35:                       # a crack, a stain
				var kx := px + sx + 4 + int(hash2(sx, sy, 4) * (tw2 - 10))
				var ky := py + sy + 4 + int(hash2(sx, sy, 5) * (th2 - 8))
				for q in 6:
					_px(kx + q, ky + int(hash2(q, kx, 6) * 2.0), base.darkened(0.3))
	var cx := px + pw / 2
	var cy := py + ph / 2
	var rx := pw * 0.36
	var ry := ph * 0.4
	for yy in range(int(cy - ry), int(cy + ry)):
		for xx in range(int(cx - rx), int(cx + rx)):
			var dd := Vector2((xx - cx) / rx, (yy - cy) / ry).length()
			if dd < 1.0 and xx >= 0 and yy >= 0 and xx < _img.get_width() and yy < _img.get_height():
				var s2 := pow(1.0 - dd, 1.2) * (0.3 + 0.3 * hash2(xx / 3, yy / 3, 7))
				_img.set_pixel(xx, yy, _img.get_pixel(xx, yy).darkened(s2))
	var white := Color(0.9, 0.9, 0.86)
	var rr := minf(pw, ph) * 0.3
	for a in 140:
		var ang := a * TAU / 140.0
		_rect(int(cx + cos(ang) * rr * 1.25) - 1, int(cy + sin(ang) * rr) - 1, 2, 2, c)
	_rect(cx - 10, cy - 11, 4, 22, white)
	_rect(cx + 6, cy - 11, 4, 22, white)
	_rect(cx - 6, cy - 2, 12, 4, white)
	var hb := 5
	for yy in range(py, py + ph):
		for xx in range(px, px + pw):
			if xx < px + hb or xx >= px + pw - hb or yy < py + hb or yy >= py + ph - hb:
				_px(xx, yy, c if ((xx + yy) / 4) % 2 == 0 else Color(0.13, 0.13, 0.15))
	_rect(px + hb + 2, py + hb + 2, pw - hb * 2 - 4, 1, white)
	_rect(px + hb + 2, py + ph - hb - 3, pw - hb * 2 - 4, 1, white)
	_rect(px + hb + 2, py + hb + 2, 1, ph - hb * 2 - 4, white)
	_rect(px + pw - hb - 3, py + hb + 2, 1, ph - hb * 2 - 4, white)
	for cs in [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
		var bx2: int = cx + cs.x * int(pw * 0.3)
		var by2: int = cy + cs.y * int(ph * 0.28)
		_rect(bx2 - (10 if cs.x > 0 else 0), by2, 10, 2, white)
		_rect(bx2, by2 - (10 if cs.y > 0 else 0), 2, 10, white)
	var digits := str(n)
	for di in digits.length():
		var g: Array = DIGITS.get(digits[di], DIGITS["0"])
		for gy in 5:
			for gx in 3:
				if String(g[gy])[gx] == "1":
					_rect(px + hb + 7 + di * 13 + gx * 3, py + hb + 6 + gy * 3, 3, 3, white)
	for xx2 in range(px + 12, px + pw - 8, 16):
		for ey in [py + 1, py + ph - 4]:
			_rect(xx2 - 2, ey, 5, 3, Color(0.16, 0.16, 0.18))
			_rect(xx2 - 1, ey + 1, 3, 1, Color(1.0, 0.8, 0.45))
	for yy2 in range(py + 12, py + ph - 8, 16):
		for ex in [px + 1, px + pw - 4]:
			_rect(ex, yy2 - 2, 3, 5, Color(0.16, 0.16, 0.18))
			_rect(ex + 1, yy2 - 1, 1, 3, Color(1.0, 0.8, 0.45))
	for gx2 in [px + hb + 4, px + pw - hb - 8]:
		_rect(gx2, cy - 7, 4, 14, Color(0.18, 0.18, 0.2))
		for sl in range(0, 14, 2):
			_rect(gx2, cy - 7 + sl, 4, 1, Color(0.3, 0.3, 0.32))
	for tdx in [Vector2(-0.22, -0.3), Vector2(0.22, -0.3), Vector2(-0.22, 0.3), Vector2(0.22, 0.3)]:
		var tx := cx + int(tdx.x * pw)
		var ty := cy + int(tdx.y * ph)
		_rect(tx - 1, ty - 1, 3, 3, Color(0.25, 0.25, 0.28))
		_px(tx, ty, Color(0.55, 0.55, 0.58))
	var fx := px + pw - hb - 16
	var fy := py + ph - hb - 13
	_rect(fx, fy, 11, 8, Color(0.85, 0.7, 0.15))
	_rect(fx + 1, fy + 1, 9, 6, Color(0.62, 0.16, 0.13))
	_rect(fx + 3, fy + 3, 5, 2, Color(0.4, 0.1, 0.08))


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
		"screen":
			_rect(px + 2, py + 2, pw - 4, 10, Color(0.05, 0.06, 0.09))
			_rect(px + 3, py + 3, pw - 6, 8, c.darkened(0.4))
			for k in 3:
				_rect(px + 4, py + 4 + k * 2, int((pw - 8) * (0.4 + 0.2 * k)), 1, c)
		"lift":
			_rect(px + 1, py - 12, pw - 2, TILE + 10, Color(0.2, 0.21, 0.24))
			_rect(px + 3, py - 10, pw - 6, TILE + 7, Color(0.13, 0.14, 0.17))          # the car inside
			_rect(px + 3, py - 10, pw - 6, 2, Color(0.85, 0.9, 1.0))
			_rect(px + 4, py - 8, pw - 8, TILE + 2, Color(0.2, 0.22, 0.26))
			_rect(px + 4, py + 2, pw - 8, 1, Color(0.3, 0.32, 0.36))
			_rect(px + pw / 2 - 4, py - 15, 8, 3, Color(0.08, 0.08, 0.1))
			_rect(px + pw / 2 - 2, py - 14, 4, 1, c)
		"awning":                  # 0.7.50.11: a shop's canopy along its wall, the door left free – 0.7.51.6: plated, lit underneath
			var door_l := pw / 2 - TILE - 2
			var door_r := pw / 2 + TILE + 2
			for seg in [[2, door_l], [door_r, pw - 2]]:
				var sx0: int = seg[0]
				var sw0: int = seg[1] - seg[0]
				if sw0 <= 0:
					continue
				_rect(px + sx0, py + 2, sw0, 7, Color(0.2, 0.21, 0.24))
				_rect(px + sx0, py + 2, sw0, 1, Color(0.45, 0.47, 0.52))
				for x3 in range(px + sx0 + 10, px + sx0 + sw0, 12):
					_rect(x3, py + 3, 1, 6, Color(0.12, 0.13, 0.15))
				_rect(px + sx0, py + 9, sw0, 2, c)
				_rect(px + sx0, py + 11, sw0, 1, c.darkened(0.45))
				for x4 in range(px + sx0 + 4, px + sx0 + sw0 - 2, 8):
					_px(x4, py + 12, c.lightened(0.3))
		"flag":                    # 0.7.50.7: a power's flag hanging on the wall – cloth, its sign, a pointed end
			var c2: Color = d.get("col2", Color(1, 1, 1))
			_rect(px + 1, py - 13, pw - 2, 2, Color(0.25, 0.22, 0.18))
			_rect(px + 3, py - 11, pw - 6, TILE + 2, c)
			_rect(px + 3, py - 11, 1, TILE + 2, c.lightened(0.2))
			for k3 in 3:
				_rect(px + 3 + k3, py + TILE - 9 + k3, pw - 6 - k3 * 2, 1, c)
			match String(d.get("sign", "cross")):
				"circle":                                  # the Assembly's open hand – a ring
					_rect(px + pw / 2 - 2, py - 8, 4, 1, c2)
					_rect(px + pw / 2 - 2, py - 2, 4, 1, c2)
					_rect(px + pw / 2 - 3, py - 7, 1, 5, c2)
					_rect(px + pw / 2 + 2, py - 7, 1, 5, c2)
				"diamond":                                 # the Directorate's compass
					for k5 in 4:
						_rect(px + pw / 2 - 1 - k5, py - 8 + k5, 2 + k5 * 2, 1, c2)
						_rect(px + pw / 2 - 1 - k5, py - 1 - k5, 2 + k5 * 2, 1, c2)
				_:                                         # the Covenant's sun road
					_rect(px + pw / 2 - 1, py - 7, 2, 8, c2)
					_rect(px + pw / 2 - 3, py - 5, 6, 2, c2)
		"poster":
			if d.has("col2"):                     # a free city's neon poster
				_rect(px + 2, py - 12, pw - 4, TILE + 4, Color(0.05, 0.05, 0.08))
				_rect(px + 2, py - 12, pw - 4, 1, d["col2"])
				_rect(px + 2, py + TILE - 9, pw - 4, 1, d["col2"])
				_rect(px + 2, py - 12, 1, TILE + 4, d["col2"])
				_rect(px + pw - 3, py - 12, 1, TILE + 4, d["col2"])
				for k4 in 3:
					_rect(px + 5, py - 8 + k4 * 6, pw - 10, 2, Color(d["col2"]).lightened(0.3))
				return
			_rect(px + 3, py + 2, pw - 6, 10, Color(0.1, 0.1, 0.12))
			_rect(px + 4, py + 3, pw - 8, 8, c)
			_rect(px + 5, py + 4, int((pw - 10) * 0.6), 2, c.lightened(0.5))
		"storefront":              # 0.7.50.5: a shop's front in a city street – lit window, goods, door, awning
			var fh := TILE * 2
			_rect(px, py, pw, fh, Color(pal["wall"]).darkened(0.5))
			_rect(px + 2, py + 3, pw - 4, fh - 3, Color(0.06, 0.06, 0.09))
			_rect(px + 3, py + 5, pw - 18, fh - 9, c.darkened(0.55))
			_rect(px + 3, py + 5, pw - 18, 1, c.lightened(0.3))
			for k in int((pw - 22) / 5):
				_rect(px + 5 + k * 5, py + fh - 12, 3, 6, Color.from_hsv(hash2(k, int(d["x"]), 3), 0.5, 0.9))
			_rect(px + pw - 13, py + 6, 10, fh - 6, Color(0.13, 0.13, 0.17))
			_rect(px + pw - 12, py + 8, 8, fh - 9, c.darkened(0.7))
			_rect(px + pw - 6, py + fh / 2 + 2, 1, 2, c)
			for k2 in int(pw / 4):
				_rect(px + k2 * 4, py, 2, 4, c.darkened(0.15))
				_rect(px + k2 * 4 + 2, py, 2, 4, Color(0.88, 0.88, 0.9))
		"bay_door":                # the hangar's great doors, shut
			_rect(px, py - 14, pw, TILE + 12, Color(0.22, 0.23, 0.26))
			_rect(px + 2, py - 12, pw / 2 - 3, TILE + 8, Color(0.42, 0.44, 0.48))
			_rect(px + pw / 2 + 1, py - 12, pw / 2 - 3, TILE + 8, Color(0.4, 0.42, 0.46))
			for k in int(pw / 8):
				_rect(px + 2 + k * 8, py + TILE - 6, 4, 3, Color(0.95, 0.8, 0.2))
				_rect(px + 6 + k * 8, py + TILE - 6, 4, 3, Color(0.15, 0.15, 0.15))
			_rect(px + pw / 2 - 1, py - 12, 2, TILE + 8, Color(0.15, 0.15, 0.17))
			_rect(px + pw / 2 - 6, py - 16, 12, 2, c)
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
