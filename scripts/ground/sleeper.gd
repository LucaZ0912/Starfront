extends Node2D
## Package 58 (Luz, 18 Nov 2026): the pilot lying in a bed, shown as themselves – their own figure seen from above
## (the front, head on the pillow; eyes shut asleep, open awake), the blanket (a clinic's sheet) pulled up to the
## chest over them, breathing slowly. Used for the quarters' beds and the clinic bed of the intro.

var bed: Dictionary = {}          # the bed object (x, y, w, h in tiles; kind, col)
var look: Dictionary = {}
var awake := false
var _t := 0.0


func setup(p_bed: Dictionary, p_look: Dictionary, p_awake: bool) -> void:
	bed = p_bed
	look = p_look
	awake = p_awake
	var T := GroundMap.TILE
	position = Vector2((float(bed["x"]) + float(bed.get("w", 1)) * 0.5) * T, (float(bed["y"]) + float(bed.get("h", 1))) * T + 1.0) * GroundMap.SCALE


func _process(dt: float) -> void:
	_t += dt
	queue_redraw()


func _draw() -> void:
	var s := GroundMap.SCALE
	var T := float(GroundMap.TILE)
	var bw := float(bed.get("w", 1)) * T * s
	var bh := float(bed.get("h", 1)) * T * s
	var top := -bh - 1.0 * s
	var tex := ChibiArt.frame(look, 0, 5 if awake else 4)
	var size := Vector2(tex.get_width(), tex.get_height()) * ChibiArt.CHAR_SCALE
	var head_y := top + 2.0 * s
	draw_texture_rect(tex, Rect2(Vector2(-size.x * 0.5, head_y), size), false)
	# the blanket over them, from the chest down (it rises and falls a little)
	var med := String(bed.get("kind", "")) in ["med_bed", "med_bed_occ"]
	var col: Color = Color(0.62, 0.8, 0.97) if med else bed.get("col", Color(0.78, 0.58, 1.0))
	var breathe := sin(_t * (1.6 if awake else 1.1)) * 0.6 * s
	var by0 := head_y + size.y * 0.56 + breathe            # from the waist: the chest and arms show
	var by1 := -4.0 * s
	var bx0 := -bw * 0.5 + 2.0 * s
	draw_rect(Rect2(bx0, by0, bw - 4.0 * s, by1 - by0), col)
	draw_rect(Rect2(bx0, by0, bw - 4.0 * s, 2.0 * s), col.lightened(0.35))            # the fold at the top
	draw_rect(Rect2(bx0, by0 + 2.0 * s, bw - 4.0 * s, 1.0 * s), col.darkened(0.15))
	draw_rect(Rect2(bx0 + bw * 0.5 - 2.0 * s, by0 + 6.0 * s, 1.0 * s, by1 - by0 - 8.0 * s), col.darkened(0.1))   # legs under it
	# the hands on the blanket
	var skin: Color = ChibiArt.PilotArt.SKINS[int(look.get("skin", 2)) % ChibiArt.PilotArt.SKINS.size()]
	draw_rect(Rect2(-size.x * 0.5 + 2.0 * s, by0 - 1.0 * s, 2.0 * s, 2.0 * s), skin)
	draw_rect(Rect2(size.x * 0.5 - 4.0 * s, by0 - 1.0 * s, 2.0 * s, 2.0 * s), skin)
	if not awake:
		# a slow "z" rising over the sleeper
		var k := fmod(_t * 0.45, 1.0)
		var zp := Vector2(size.x * 0.5 + 4.0 * s + k * 6.0 * s, head_y - k * 14.0 * s)
		var zc := Color(0.85, 0.85, 1.0, 1.0 - k)
		var zz := 3.0 * s
		draw_line(zp, zp + Vector2(zz, 0), zc, s)
		draw_line(zp + Vector2(zz, 0), zp + Vector2(0, zz), zc, s)
		draw_line(zp + Vector2(0, zz), zp + Vector2(zz, zz), zc, s)
