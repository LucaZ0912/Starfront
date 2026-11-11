extends RefCounted
## 0.7.51.7 (Luz: the Gear page like the ship menu – tiles with pictures): a pixel icon for every piece of personal
## equipment, 24×24 like the module icons, drawn by its family – suits in their colours, weapons by their kind
## (lasers glow cyan, slug guns grey steel, the launcher a fat tube), the belt's grenades, tools and consumables, the
## suit's features.

const GearData = preload("res://data/gear.gd")
const S := 24
const OUT := Color(0.06, 0.06, 0.09)
const CYAN := Color(0.35, 0.95, 1.0)
const STEEL := Color(0.55, 0.58, 0.64)
const DARK := Color(0.22, 0.23, 0.27)

static var _cache := {}


static func icon(id: String) -> Texture2D:
	var fam := GearData.family(id) if id != "" else ""
	if _cache.has(fam):
		return _cache[fam]
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	_paint(img, fam)
	_outline(img)
	var tex := ImageTexture.create_from_image(img)
	_cache[fam] = tex
	return tex


static func _paint(img: Image, fam: String) -> void:
	if fam == "":
		_r(img, 11, 11, 2, 2, Color(0.3, 0.33, 0.4))
		return
	if fam.begins_with("suit_"):
		var sd: Dictionary = GearData.SUITS.get(fam, {})
		_suit(img, sd.get("col", Color(0.9, 0.9, 0.85)), sd.get("trim", Color(1.0, 0.55, 0.15)), fam)
		return
	match fam:
		# ---- weapons
		"wp_laser_pistol":
			_gun(img, 6, 9, 11, 4, Color(0.88, 0.9, 0.94), CYAN, 2)
		"wp_laser_rifle":
			_gun(img, 2, 9, 19, 4, Color(0.88, 0.9, 0.94), CYAN, 3)
			_r(img, 8, 7, 5, 2, DARK)
		"wp_beam":
			_gun(img, 3, 8, 16, 6, Color(0.75, 0.78, 0.85), CYAN, 3)
			for k in 4:
				_r(img, 8 + k * 2, 8, 1, 6, Color(0.95, 0.6, 0.2))
		"wp_pistol":
			_gun(img, 6, 9, 11, 4, STEEL, Color(0.3, 0.3, 0.33), 2)
		"wp_smg":
			_gun(img, 4, 9, 15, 4, STEEL.darkened(0.15), Color(0.3, 0.3, 0.33), 2)
			_r(img, 12, 13, 3, 6, DARK)
		"wp_rifle":
			_gun(img, 1, 9, 21, 4, Color(0.42, 0.46, 0.4), Color(0.3, 0.3, 0.33), 3)
			_r(img, 3, 8, 15, 1, CYAN)
		"wp_shotgun":
			_gun(img, 2, 8, 18, 5, Color(0.5, 0.36, 0.26), Color(0.3, 0.3, 0.33), 3)
			_r(img, 18, 8, 3, 5, DARK)
		"wp_sniper":
			_gun(img, 0, 10, 23, 3, Color(0.4, 0.42, 0.46), Color(0.3, 0.3, 0.33), 3)
			_r(img, 7, 6, 8, 3, DARK)
			_r(img, 7, 7, 1, 1, CYAN)
		"wp_launcher":
			_r(img, 3, 7, 17, 7, Color(0.38, 0.42, 0.34))
			_r(img, 3, 7, 17, 1, Color(0.55, 0.6, 0.5))
			_r(img, 19, 6, 3, 9, DARK)
			_r(img, 8, 14, 3, 5, DARK)
			_r(img, 12, 14, 2, 3, DARK)
			_r(img, 5, 9, 3, 3, Color(0.95, 0.6, 0.2))
		# ---- belt: grenades
		"gr_frag":
			_ball(img, 12, 14, 6.0, Color(0.36, 0.45, 0.3))
			_r(img, 10, 6, 4, 3, DARK)
			_r(img, 14, 5, 3, 1, STEEL)
			_r(img, 8, 13, 8, 1, Color(0.25, 0.32, 0.2))
		"gr_emp":
			_ball(img, 12, 13, 6.5, Color(0.2, 0.3, 0.55))
			_r(img, 5, 13, 14, 1, CYAN)
			_ball(img, 12, 13, 2.0, CYAN)
		"gr_smoke":
			_r(img, 8, 7, 8, 13, Color(0.6, 0.62, 0.64))
			_r(img, 8, 7, 8, 2, DARK)
			_r(img, 8, 12, 8, 2, Color(0.85, 0.85, 0.85))
			_ball(img, 17, 5, 3.0, Color(0.8, 0.82, 0.85, 0.9))
		"gr_shield":
			for k2 in 6:
				_r(img, 9 - k2 / 2, 6 + k2, 6 + k2, 1, CYAN.darkened(0.2))
				_r(img, 9 - k2 / 2, 17 - k2, 6 + k2, 1, CYAN.darkened(0.2))
			_r(img, 6, 11, 12, 2, CYAN.darkened(0.2))
			_ball(img, 12, 11.5, 2.5, Color(0.85, 1.0, 1.0))
		# ---- belt: tools
		"tl_scanner":
			_r(img, 6, 4, 12, 16, DARK)
			_r(img, 8, 6, 8, 7, Color(0.15, 0.35, 0.3))
			_r(img, 9, 9, 6, 1, Color(0.4, 1.0, 0.6))
			_r(img, 11, 7, 1, 5, Color(0.4, 1.0, 0.6))
			_r(img, 8, 15, 3, 2, CYAN)
			_r(img, 13, 15, 3, 2, Color(1.0, 0.7, 0.2))
		"tl_cloak":                                        # 0.7.52.25: a disc with a shimmer round it
			_r(img, 7, 7, 10, 10, DARK)
			_r(img, 9, 9, 6, 6, Color(0.25, 0.3, 0.45))
			_r(img, 11, 11, 2, 2, Color(0.75, 0.9, 1.0))
			for k6 in 4:
				_r(img, 4 + k6 * 5, 4 + (k6 % 2) * 15, 2, 1, Color(0.6, 0.85, 1.0, 0.8))
				_r(img, 4 + (k6 % 2) * 15, 5 + k6 * 4, 1, 2, Color(0.6, 0.85, 1.0, 0.8))
		"tl_cutter":
			_r(img, 3, 12, 12, 5, STEEL)
			_r(img, 3, 12, 12, 1, STEEL.lightened(0.3))
			_r(img, 14, 13, 3, 3, DARK)
			_r(img, 17, 13, 3, 3, Color(0.4, 0.8, 1.0))
			_r(img, 20, 14, 3, 1, Color(0.9, 0.97, 1.0))
			_r(img, 6, 17, 3, 4, DARK)
		"tl_mining":
			_r(img, 2, 11, 13, 6, Color(0.95, 0.75, 0.2))
			_r(img, 2, 11, 13, 1, Color(1.0, 0.9, 0.5))
			_r(img, 14, 12, 4, 4, DARK)
			_r(img, 18, 13, 5, 2, Color(1.0, 0.3, 0.25))
			_r(img, 6, 17, 3, 4, DARK)
		# ---- belt: consumables
		"cs_medkit":
			_r(img, 4, 7, 16, 12, Color(0.92, 0.92, 0.9))
			_r(img, 9, 5, 6, 2, DARK)
			_r(img, 11, 9, 2, 8, Color(0.9, 0.2, 0.2))
			_r(img, 8, 12, 8, 2, Color(0.9, 0.2, 0.2))
		"cs_stim":
			for k3 in 12:
				_r(img, 5 + k3, 17 - k3, 3, 2, Color(0.8, 0.85, 0.9))
			for k4 in 6:
				_r(img, 8 + k4, 13 - k4, 2, 2, Color(0.4, 1.0, 0.5))
			_r(img, 3, 18, 3, 3, DARK)
		"cs_breach":                                       # 0.7.52.24: a spike with its glowing tip
			_r(img, 10, 3, 4, 12, STEEL)
			_r(img, 10, 3, 1, 12, Color(0.8, 0.82, 0.86))
			_r(img, 8, 14, 8, 6, DARK)
			_r(img, 9, 15, 6, 1, Color(0.3, 1.0, 0.7))
			_r(img, 11, 20, 2, 3, Color(0.3, 1.0, 0.7))
			_r(img, 11, 1, 2, 2, Color(0.3, 1.0, 0.7))
		"cs_cell", "ft_battery":
			_r(img, 7, 5, 10, 16, DARK)
			_r(img, 10, 3, 4, 2, STEEL)
			_r(img, 8, 6, 8, 14, Color(0.12, 0.2, 0.26))
			for k5 in 3:
				_r(img, 9, 15 - k5 * 4, 6, 3, CYAN.darkened(0.15 * k5))
			if fam == "ft_battery":
				_r(img, 4, 8, 3, 10, STEEL)
				_r(img, 17, 8, 3, 10, STEEL)
		"cs_o2", "ft_o2":
			_r(img, 8, 5, 8, 16, Color(0.3, 0.5, 0.85))
			_r(img, 8, 5, 2, 16, Color(0.5, 0.7, 1.0))
			_r(img, 10, 2, 4, 3, STEEL)
			_r(img, 8, 11, 8, 2, Color(0.95, 0.95, 0.95))
			if fam == "ft_o2":
				_r(img, 16, 7, 3, 12, Color(0.3, 0.5, 0.85).darkened(0.2))
		"cs_ammo", "ft_ammo":
			_r(img, 4, 10, 16, 10, Color(0.36, 0.42, 0.32))
			_r(img, 4, 10, 16, 1, Color(0.5, 0.58, 0.45))
			for k6 in 5:
				_r(img, 6 + k6 * 3, 5, 2, 5, Color(0.9, 0.72, 0.3))
				_p(img, 6 + k6 * 3, 5, Color(0.65, 0.5, 0.2))
			_r(img, 9, 14, 6, 2, Color(0.95, 0.78, 0.15))
			if fam == "ft_ammo":
				_r(img, 2, 9, 2, 12, DARK)
				_r(img, 20, 9, 2, 12, DARK)
		# ---- features
		"wp_arm_laser":                                    # 0.7.52.14: the red bracer with its emitter
			_r(img, 4, 9, 14, 6, Color(0.66, 0.08, 0.1))
			_r(img, 4, 9, 14, 1, Color(0.95, 0.75, 0.3))
			_r(img, 6, 12, 10, 1, Color(0.4, 0.04, 0.06))
			_r(img, 18, 10, 3, 4, DARK)
			_r(img, 17, 13, 3, 1, Color(1.0, 0.35, 0.25))
			_r(img, 20, 11, 2, 2, Color(1.0, 0.6, 0.5))
		"dr_laser", "dr_kinetic", "dr_kamikaze":           # 0.7.52.11: a quadcopter from above
			var body: Color = {"dr_laser": Color(0.9, 0.92, 0.95), "dr_kinetic": Color(0.4, 0.42, 0.46), "dr_kamikaze": Color(0.45, 0.5, 0.34)}[fam]
			var trim: Color = {"dr_laser": CYAN, "dr_kinetic": Color(1.0, 0.72, 0.25), "dr_kamikaze": Color(1.0, 0.82, 0.15)}[fam]
			for i in 7:
				_p(img, 5 + i, 5 + i, DARK)
				_p(img, 18 - i, 5 + i, DARK)
				_p(img, 5 + i, 18 - i, DARK)
				_p(img, 18 - i, 18 - i, DARK)
			for c in [Vector2i(5, 5), Vector2i(18, 5), Vector2i(5, 18), Vector2i(18, 18)]:
				_r(img, c.x - 3, c.y - 1, 7, 2, Color(0.75, 0.8, 0.85, 0.8))
				_r(img, c.x - 1, c.y - 1, 2, 2, DARK)
			_r(img, 9, 9, 6, 6, body)
			_r(img, 9, 9, 6, 1, body.lightened(0.3))
			_r(img, 10, 13, 4, 1, trim)
			if fam == "dr_kamikaze":
				_p(img, 11, 11, Color(1.0, 0.25, 0.2))
			else:
				_p(img, 11, 11, trim)
		"ft_shield":
			for k7 in 14:
				var ww := 14 - maxi(0, k7 - 7) * 2
				_r(img, 12 - ww / 2, 4 + k7, ww, 1, CYAN.darkened(0.25))
			_r(img, 11, 6, 2, 10, Color(0.85, 1.0, 1.0))
		"ft_plates":
			for k8 in 3:
				_r(img, 5 + k8, 5 + k8 * 5, 14 - k8 * 2, 5, Color(0.45, 0.48, 0.42).lightened(0.08 * k8))
				_r(img, 5 + k8, 5 + k8 * 5, 14 - k8 * 2, 1, Color(0.7, 0.72, 0.68))
		"ft_sprint":
			for k9 in 3:
				for t in 5:
					_r(img, 4 + k9 * 6 + t, 7 + t, 2, 1, Color(1.0, 0.75, 0.2))
					_r(img, 4 + k9 * 6 + t, 17 - t, 2, 1, Color(1.0, 0.75, 0.2))
		"ft_jets":
			_r(img, 6, 4, 4, 10, STEEL)
			_r(img, 14, 4, 4, 10, STEEL)
			_r(img, 6, 14, 4, 2, DARK)
			_r(img, 14, 14, 4, 2, DARK)
			for k10 in 5:
				_r(img, 7 - k10 / 3, 16 + k10, 2 + (k10 / 3) * 2, 1, Color(1.0, 0.6 + k10 * 0.06, 0.2))
				_r(img, 15 - k10 / 3, 16 + k10, 2 + (k10 / 3) * 2, 1, Color(1.0, 0.6 + k10 * 0.06, 0.2))
		"ft_thermo":
			_r(img, 10, 3, 4, 14, Color(0.9, 0.92, 0.95))
			_ball(img, 12, 18, 3.5, Color(1.0, 0.35, 0.25))
			_r(img, 11, 9, 2, 9, Color(1.0, 0.35, 0.25))
			_r(img, 15, 5, 4, 1, CYAN)
			_r(img, 15, 9, 4, 1, Color(1.0, 0.6, 0.2))
		_:
			_r(img, 5, 5, 14, 14, DARK)
			_r(img, 8, 8, 8, 8, CYAN.darkened(0.3))


static func _suit(img: Image, col: Color, trim: Color, fam: String) -> void:
	## a suit on its stand: the helmet's glass dome, the torso with its chest plate, shoulders, belt
	var heavy := fam == "suit_mil_heavy"
	var sw := 14 if heavy else 12
	var x0 := 12 - sw / 2
	_r(img, x0, 10, sw, 10, col)                                  # torso
	_r(img, x0 - 2, 10, 3, 4, col.darkened(0.15))                 # shoulders
	_r(img, x0 + sw - 1, 10, 3, 4, col.darkened(0.15))
	_r(img, x0 + 2, 12, sw - 4, 4, trim)                          # chest plate
	_r(img, x0 + 3, 13, 2, 1, trim.lightened(0.4))
	_r(img, x0, 18, sw, 2, DARK)                                  # belt
	_r(img, 11, 18, 2, 2, CYAN)
	_ball(img, 12, 6.5, 4.5, col.darkened(0.1))                   # the helmet
	_ball(img, 12, 6.5, 3.2, Color(0.35, 0.55, 0.7))
	_r(img, 10, 4, 2, 2, Color(0.85, 0.95, 1.0))
	_r(img, x0 + 1, 20, 4, 3, col.darkened(0.2))                  # legs
	_r(img, x0 + sw - 5, 20, 4, 3, col.darkened(0.2))


static func _gun(img: Image, x: int, y: int, w: int, h: int, body: Color, glow: Color, grip: int) -> void:
	_r(img, x, y, w, h, body)
	_r(img, x, y, w, 1, body.lightened(0.25))
	_r(img, x + w, y + 1, 2, h - 2, glow)                         # the muzzle
	_r(img, x + 2, y + h, grip + 1, 5, DARK)                      # the grip
	_r(img, x + 2 + grip + 1, y + h, 2, 2, DARK.lightened(0.1))   # the trigger guard
	_r(img, x + w - 4, y + 1, 2, h - 2, glow.darkened(0.2))


static func _ball(img: Image, cx: float, cy: float, rad: float, c: Color) -> void:
	for yy in S:
		for xx in S:
			if Vector2(xx + 0.5 - cx, yy + 0.5 - cy).length() <= rad:
				_p(img, xx, yy, c)


static func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, S, S))
	if r.size.x > 0 and r.size.y > 0:
		img.fill_rect(r, c)


static func _p(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < S and y < S:
		img.set_pixel(x, y, c)


static func _outline(img: Image) -> void:
	var src := img.duplicate()
	for y in S:
		for x in S:
			if src.get_pixel(x, y).a > 0.1:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < S and q.y < S and src.get_pixel(q.x, q.y).a > 0.1:
					img.set_pixel(x, y, OUT)
					break
