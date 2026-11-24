extends Control
## Split screen, stage 0 (Luz, 24 Nov 2026): the picture in two halves, side by side: left the first player, right the
## second. Each half is a viewport of its own with a camera of its own, and both look at the same world: what stands
## in the world is there once and seen twice.
##
##   var sv = SplitViewScript.new()
##   parent.add_child(sv)
##   sv.add_world(world_node)          # the world goes into the first half; the second sees the same one
##   sv.cams[0].position = ...         # each camera follows its player
##   sv.set_split(false)               # one picture again (the first player's camera takes all of it)
##
## Preload this script (no class_name: the game also runs without an editor scan).

const LINE := 4.0                     # the line between the halves, in pixels
const COL_1 := Color(0.25, 0.9, 1.0)
const COL_2 := Color(1.0, 0.45, 0.85)

var split := true
var frames: Array = []                # the two SubViewportContainers
var views: Array = []                 # the two SubViewports
var cams: Array = []                  # the two Camera2Ds
var _line: ColorRect


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 2:
		var fr := SubViewportContainer.new()
		fr.stretch = true
		fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(fr)
		var vp := SubViewport.new()
		vp.transparent_bg = false
		vp.handle_input_locally = false
		vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		fr.add_child(vp)
		var cam := Camera2D.new()
		vp.add_child(cam)
		frames.append(fr)
		views.append(vp)
		cams.append(cam)
	_line = ColorRect.new()
	_line.color = Color(0.02, 0.03, 0.06)
	_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_line)


func _ready() -> void:
	(views[1] as SubViewport).world_2d = (views[0] as SubViewport).world_2d
	resized.connect(_layout)
	_layout()
	for c in cams:
		(c as Camera2D).make_current()


## The world: lives in the first half, the second looks at the same one.
func add_world(world: Node) -> void:
	(views[0] as SubViewport).add_child(world)
	(views[0] as SubViewport).move_child(world, 0)


## Two halves, or one picture (the first player's camera then sees all of it).
func set_split(on: bool) -> void:
	split = on
	_layout()


## The size of one player's picture.
func view_size(player: int = 0) -> Vector2:
	return (frames[player] as Control).size


## Where a point of the world is on the screen of a player (for what is drawn over the picture: names, marks).
func to_screen(player: int, world_pos: Vector2) -> Vector2:
	var cam: Camera2D = cams[player]
	var fr: Control = frames[player]
	return fr.position + fr.size * 0.5 + (world_pos - cam.get_screen_center_position()) * cam.zoom


func _layout() -> void:
	var s := size
	var half := floorf((s.x - LINE) * 0.5)
	var f0: Control = frames[0]
	var f1: Control = frames[1]
	f0.position = Vector2.ZERO
	f0.size = Vector2(half, s.y) if split else s
	f1.visible = split
	f1.position = Vector2(s.x - half, 0.0)
	f1.size = Vector2(half, s.y)
	(views[1] as SubViewport).render_target_update_mode = SubViewport.UPDATE_ALWAYS if split else SubViewport.UPDATE_DISABLED
	_line.visible = split
	_line.position = Vector2(half, 0.0)
	_line.size = Vector2(s.x - half * 2.0, s.y)
