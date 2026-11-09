class_name GroundMap
extends RefCounted
## Package 49: a walkable place on foot – a grid of tiles (16 art px each), what blocks, the zones you can use (a shop
## door, the airlock back to the ship) and the picture of it all. Made by a generator (DeckGen for station decks);
## drawn at ×SCALE by GroundView.

const TILE := 16
const SCALE := 3.0
enum T { VOID, FLOOR, WALL, DOOR, BLOCK, WINDOW }

var w := 0
var h := 0
var tiles := PackedInt32Array()
var floor_kind := PackedInt32Array()          # 0 promenade, 1 room, 2 airlock, 3 bar …: picks the floor pattern
var zones: Array = []                         # {rect (art px), kind: "service"/"exit", id, title, col, sign: Vector2}
var props: Array = []                         # {kind, x, y, w, h (tiles), col, …} – drawn into the picture
var people: Array = []                        # NPCs that stay put: {pos (art px), look, facing, sit}
var wander: Array = []                        # where walking NPCs may go (art px points on the promenade)
var spawn := Vector2.ZERO                     # where the pilot comes in (art px)
var dock_at := Vector2.INF                    # where the pilot's ship lies against the airlock (art px), drawn by GroundView
var pal: Dictionary = {}
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


## A room: walls round, floor inside.
func room(x: int, y: int, rw: int, rh: int, fk: int) -> void:
	fill(x, y, rw, rh, T.WALL)
	fill(x + 1, y + 1, rw - 2, rh - 2, T.FLOOR, fk)


static func walkable_t(t: int) -> bool:
	return t == T.FLOOR or t == T.DOOR


## Can a body of radius r (art px) stand at p (art px)?
func free_at(p: Vector2, r: float = 4.0) -> bool:
	for c in [Vector2(-r, -r), Vector2(r, -r), Vector2(-r, r), Vector2(r, r)]:
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


# ---------------------------------------------------------------- The picture

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


func _hash(x: int, y: int, s: int = 0) -> float:
	var v := sin(float(x) * 12.9898 + float(y) * 78.233 + float(s) * 3.7) * 43758.5453
	return v - floor(v)


func _render() -> void:
	_img = Image.create(w * TILE, h * TILE, false, Image.FORMAT_RGBA8)
	_img.fill(Color(0.01, 0.012, 0.03))
	# space beyond the hull: a few stars
	for i in 260:
		var sx := int(_hash(i, 1) * w * TILE)
		var sy := int(_hash(i, 2) * h * TILE)
		var b := 0.4 + 0.6 * _hash(i, 3)
		_px(sx, sy, Color(b, b, b * 1.05))
	for y in h:
		for x in w:
			var t := t_at(x, y)
			var px := x * TILE
			var py := y * TILE
			match t:
				T.FLOOR, T.DOOR, T.BLOCK:
					_floor_tile(x, y, px, py, floor_kind[y * w + x])
				T.WALL:
					_wall_tile(x, y, px, py)
				T.WINDOW:
					_window_tile(x, y, px, py)
	for p in props:
		_prop(p)
	# doors: a lit threshold in the wall
	for y2 in h:
		for x2 in w:
			if t_at(x2, y2) == T.DOOR:
				var c: Color = pal["accent"]
				_rect(x2 * TILE, y2 * TILE, TILE, TILE, Color(pal["floor2"]).lerp(c, 0.18))
				for k in 4:
					_px(x2 * TILE + 2 + k * 4, y2 * TILE + 1, c)
					_px(x2 * TILE + 2 + k * 4, y2 * TILE + TILE - 2, c)


func _floor_tile(x: int, y: int, px: int, py: int, fk: int) -> void:
	var f: Color = pal["floor"] if fk != 1 else pal.get("room_floor", pal["floor"])
	var f2: Color = pal["floor2"] if fk != 1 else Color(pal.get("room_floor", pal["floor"])).lightened(0.025)
	match fk:
		0:              # promenade: big plates with seams, a guide line down the middle
			_rect(px, py, TILE, TILE, f)
			_rect(px + 1, py + 1, TILE - 2, TILE - 2, f2 if (x + y) % 2 == 0 else f)
			if _hash(x, y, 9) < 0.08:
				_rect(px + 5, py + 5, 6, 6, f.darkened(0.15))
		1:              # rooms: a fine floor with thin seams
			_rect(px, py, TILE, TILE, f2 if (x + y) % 2 == 0 else f)
			_rect(px, py + TILE - 1, TILE, 1, f.darkened(0.12))
			_rect(px + TILE - 1, py, 1, TILE, f.darkened(0.12))
		2:              # airlock: hazard stripes along the edge, grating
			_rect(px, py, TILE, TILE, Color(0.2, 0.21, 0.24))
			for k in 4:
				_rect(px, py + k * 4 + 1, TILE, 1, Color(0.14, 0.15, 0.17))
		3:              # bar: warm wooden planks
			var wood: Color = pal.get("bar_floor", Color(0.32, 0.2, 0.12))
			_rect(px, py, TILE, TILE, wood)
			for k in 4:
				_rect(px, py + k * 4, TILE, 1, wood.darkened(0.25))
				if _hash(x, y + k, 4) < 0.5:
					_rect(px + int(_hash(x, k, 5) * 12), py + k * 4, 1, 4, wood.darkened(0.3))


func _wall_tile(x: int, y: int, px: int, py: int) -> void:
	var wl: Color = pal["wall"]
	var wd: Color = pal["wall_dark"]
	_rect(px, py, TILE, TILE, wd)
	# the top face of the wall (lit), a dark rim where it meets the floor below
	var below := t_at(x, y + 1)
	_rect(px, py, TILE, TILE - 4 if walkable_t(below) or below == T.BLOCK else TILE, wl)
	if walkable_t(below) or below == T.BLOCK:
		_rect(px, py + TILE - 4, TILE, 4, wd.darkened(0.2))
	if x % 4 == 0:
		_rect(px, py, 1, TILE - 4, wl.darkened(0.2))
	if _hash(x, y, 7) < 0.12 and walkable_t(below):
		_rect(px + 6, py + TILE - 3, 4, 2, pal["accent"])          # a small light


func _window_tile(x: int, y: int, px: int, py: int) -> void:
	_rect(px, py, TILE, TILE, Color(0.02, 0.03, 0.07))
	for i in 3:
		var sx := px + 1 + int(_hash(x, y, i) * (TILE - 2))
		var sy := py + 1 + int(_hash(x, y, i + 4) * (TILE - 2))
		_px(sx, sy, Color(0.9, 0.92, 1.0))
	_rect(px, py, TILE, 1, Color(pal["wall"]))
	_rect(px, py + TILE - 1, TILE, 1, Color(pal["wall"]))
	if x % 3 == 0:
		_rect(px, py, 1, TILE, Color(pal["wall"]))


## The furniture and fittings (props) – all in art px from their tile corner.
func _prop(p: Dictionary) -> void:
	var px := int(p["x"]) * TILE
	var py := int(p["y"]) * TILE
	var pw := int(p.get("w", 1)) * TILE
	var ph := int(p.get("h", 1)) * TILE
	var c: Color = p.get("col", pal["accent"])
	match String(p["kind"]):
		"counter":
			_rect(px, py + 2, pw, ph - 4, Color(pal["wall"]).darkened(0.1))
			_rect(px, py + 2, pw, 3, Color(pal["wall"]).lightened(0.25))
			_rect(px, py + ph - 4, pw, 2, Color(c, 1.0))
		"bar_counter":
			_rect(px, py + 2, pw, ph - 4, Color(0.42, 0.24, 0.12))
			_rect(px, py + 2, pw, 3, Color(0.62, 0.4, 0.2))
			for k in int(pw / 10):
				_rect(px + 4 + k * 10, py + 6, 3, 4, [Color(0.8, 0.3, 0.2), Color(0.3, 0.7, 0.9), Color(0.95, 0.8, 0.3)][k % 3])
		"stool":
			_rect(px + 5, py + 5, 6, 6, Color(0.2, 0.2, 0.22))
			_rect(px + 6, py + 6, 4, 4, Color(0.7, 0.25, 0.2))
		"table":
			_rect(px + 2, py + 2, pw - 4, ph - 4, Color(0.35, 0.22, 0.13))
			_rect(px + 3, py + 3, pw - 6, 2, Color(0.5, 0.33, 0.2))
			_px(px + pw / 2, py + ph / 2, Color(1.0, 0.85, 0.4))
		"shelf":
			_rect(px, py, pw, ph, Color(pal["wall_dark"]))
			for k in int(pw / 4):
				for j in int(ph / 5):
					_rect(px + 1 + k * 4, py + 1 + j * 5, 3, 3, Color.from_hsv(_hash(k, j, int(p["x"])), 0.5, 0.85))
		"crates":
			for k in int(pw / 8):
				for j in int(ph / 8):
					var cc := Color(0.45, 0.33, 0.18) if (k + j) % 2 == 0 else Color(0.36, 0.38, 0.42)
					_rect(px + k * 8 + 1, py + j * 8 + 1, 7, 7, cc)
					_rect(px + k * 8 + 1, py + j * 8 + 1, 7, 1, cc.lightened(0.25))
		"rack":
			_rect(px, py, pw, ph, Color(0.18, 0.19, 0.22))
			for k in int(pw / 6):
				_rect(px + 2 + k * 6, py + 3, 2, ph - 6, Color(0.55, 0.58, 0.65))
				_rect(px + 1 + k * 6, py + ph / 2 - 1, 4, 2, c)
		"terminal":
			_rect(px + 2, py + 1, pw - 4, ph - 3, Color(0.12, 0.13, 0.16))
			_rect(px + 4, py + 3, pw - 8, ph - 9, c.darkened(0.15))
			_rect(px + 5, py + 4, pw - 10, 1, c.lightened(0.5))
			if p.has("icon"):
				var ic: Texture2D = PixelArt.icon_texture(String(p["icon"]))
				if ic != null:
					var im: Image = ic.get_image()
					im.convert(Image.FORMAT_RGBA8)
					var ox := px + (pw - im.get_width()) / 2
					var oy := py + 3
					for yy in mini(im.get_height(), ph - 9):
						for xx in im.get_width():
							var pc := im.get_pixel(xx, yy)
							if pc.a > 0.3:
								_px(ox + xx, oy + yy, pc)
		"planter":
			_rect(px + 1, py + 1, pw - 2, ph - 2, Color(0.35, 0.26, 0.18))
			for k in 10:
				var lx := px + 2 + int(_hash(k, int(p["x"]), 1) * (pw - 5))
				var ly := py + 2 + int(_hash(k, int(p["y"]), 2) * (ph - 5))
				_rect(lx, ly, 3, 3, Color(0.25, 0.6 + 0.2 * _hash(k, 3), 0.25))
		"bench":
			_rect(px, py + 4, pw, ph - 8, Color(pal["wall"]).darkened(0.25))
			_rect(px, py + 4, pw, 2, Color(pal["wall"]))
		"pillar":
			_rect(px + 2, py + 2, pw - 4, ph - 4, Color(pal["wall_dark"]))
			_rect(px + 3, py + 2, pw - 6, ph - 6, Color(pal["wall"]))
			_rect(px + 3, py + 2, pw - 6, 2, Color(pal["wall"]).lightened(0.3))
			_rect(px + 4, py + ph - 5, pw - 8, 1, c)
		"holo":
			_rect(px + 1, py + 2, pw - 2, ph - 4, Color(0.05, 0.06, 0.09))
			_rect(px + 2, py + 3, pw - 4, ph - 6, Color(pal["floor"]).lerp(c, 0.45))
			for k in int((ph - 6) / 2):
				_rect(px + 2, py + 3 + k * 2, pw - 4, 1, Color(pal["floor"]).lerp(c, 0.75))
			_rect(px + 4, py + 5, int((pw - 8) * 0.6), 2, c.lightened(0.6))
		"machine":
			_rect(px + 1, py + 1, pw - 2, ph - 2, Color(0.3, 0.27, 0.24))
			_rect(px + 3, py + 3, pw - 6, 3, Color(0.95, 0.55, 0.15))
			for k in int(pw / 6):
				_rect(px + 2 + k * 6, py + ph - 5, 3, 3, Color(0.15, 0.15, 0.15))
		"stripes":
			for k in int(pw / 4):
				_rect(px + k * 4, py, 2, ph, Color(0.95, 0.75, 0.1))
		"ship":
			var tex: Texture2D = PixelArt.ship_texture(String(p.get("hull", "dragonfly")), "player")
			var im2: Image = tex.get_image()
			im2.convert(Image.FORMAT_RGBA8)
			var sc := maxi(1, mini(pw / maxi(im2.get_width(), 1), ph / maxi(im2.get_height(), 1)))
			var ox2 := px + (pw - im2.get_width() * sc) / 2
			var oy2 := py + (ph - im2.get_height() * sc) / 2
			for yy in im2.get_height():
				for xx in im2.get_width():
					var pc2 := im2.get_pixel(xx, yy)
					if pc2.a > 0.3:
						_rect(ox2 + xx * sc, oy2 + yy * sc, sc, sc, pc2)
		"mirror":
			_rect(px + 2, py + 1, pw - 4, ph - 4, Color(0.7, 0.8, 0.9))
			_rect(px + 3, py + 2, 2, ph - 6, Color(0.95, 0.97, 1.0))
		"fountain":
			_rect(px + 1, py + 1, pw - 2, ph - 2, Color(0.75, 0.72, 0.65))
			_rect(px + 3, py + 3, pw - 6, ph - 6, Color(0.25, 0.55, 0.85))
			_rect(px + pw / 2 - 1, py + ph / 2 - 1, 2, 2, Color(0.85, 0.95, 1.0))
		"wallscreen":
			_rect(px + 2, py + 3, TILE - 4, 7, Color(0.06, 0.07, 0.1))
			_rect(px + 3, py + 4, TILE - 6, 5, Color(pal["wall_dark"]).lerp(c, 0.7))
			_rect(px + 3, py + 4, TILE - 6, 1, c.lightened(0.4))
		"lamp":
			_rect(px + 6, py + 4, 4, 8, Color(pal["wall"]).darkened(0.3))
			_rect(px + 5, py + 3, 6, 3, c)
			_rect(px + 6, py + 2, 4, 1, c.lightened(0.5))
		"rug":
			_rect(px, py, pw, ph, Color(pal["room_floor"]).lerp(c, 0.35).darkened(0.2))
			_rect(px + 2, py + 2, pw - 4, ph - 4, Color(pal["room_floor"]).lerp(c, 0.25))
