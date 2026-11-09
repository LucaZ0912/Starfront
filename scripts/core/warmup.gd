extends Node
## Package 35: the basics of loading. Pictures that are made on the fly (asteroid sprites, the colossus shader) used to
## be made the moment they first came into view – entering a field with colossi hitched. Warmup makes them ahead of
## time, a few milliseconds per frame: the current system behind the loading screen at the start, the next one
## during the hyperspace jump (the jump hides the loading). Add as a child of Main.

const ColossusShaderW = preload("res://shaders/colossus.gdshader")

var _queue: Array = []               # [cls, shape, seed, px, ore]
var _seen := {}
var budget_ms := 4.0
var made := 0
var last_ms := 0.0                   # time the last system took to warm (debug)
var _t0 := 0
var _shader_done := false


## Queues every asteroid picture of a system (fields, loose rocks, scenery, colossus rims).
func queue_system(sid: int) -> void:
	var L := Universe.get_layout(sid)
	var before := _queue.size()
	for a in L.get("asteroids", []):
		_add(String(a["class"]), String(a["shape"]), int(a["seed"]), int(float(a["radius"]) / 2.2), String(a["ore"]))
	for d in L.get("debris", []):
		_add(String(d["class"]), String(d["shape"]), int(d["seed"]), int(float(d["radius"]) / 2.2), String(d["ore"]))
	if _queue.size() > before and _t0 == 0:
		_t0 = Time.get_ticks_msec()


func _add(cls: String, shape: String, seed_v: int, px: int, ore: String) -> void:
	var key := "%s_%s_%d_%d_%s" % [cls, shape, posmod(seed_v, 8), clampi(int(round(px / 4.0)) * 4, 8, 48), ore]
	if _seen.has(key):
		return
	_seen[key] = true
	_queue.append([cls, shape, seed_v, px, ore])


## Package 42c: every system's layout and its markets' roles – the galaxy map (economies) and the convoys (goods
## from market to market) need them all; made behind the loading screen instead of in one hitch later.
var _layouts: Array = []


func queue_layouts() -> void:
	for s in Universe.systems:
		var sid := int(s["id"])
		# package 40: only the inhabited systems – the empty ones of the ring are made when they are needed
		if not Universe.layouts.has(sid) and not sid in _layouts and Universe.has_stations(sid):
			_layouts.append(sid)
	if not _layouts.is_empty() and _t0 == 0:
		_t0 = Time.get_ticks_msec()


func _warm_layout(sid: int) -> void:
	var L := Universe.get_layout(sid)
	Economy.of(sid)
	for st in L["stations"]:
		for cid in GameData.commodities:
			if Market.on_market(cid):
				Market.role(st, cid)


func pending() -> int:
	return _queue.size() + _layouts.size()


func done() -> bool:
	return _queue.is_empty() and _layouts.is_empty() and _shader_done


func _process(_d: float) -> void:
	if not _shader_done:
		_warm_shader()
	if not _layouts.is_empty():
		var t_l := Time.get_ticks_usec()
		while not _layouts.is_empty():
			_warm_layout(int(_layouts.pop_front()))          # at least one per frame
			if float(Time.get_ticks_usec() - t_l) / 1000.0 >= budget_ms:
				break
		return
	if _queue.is_empty():
		if _t0 != 0:
			last_ms = float(Time.get_ticks_msec() - _t0)
			_t0 = 0
		return
	var start := Time.get_ticks_usec()
	while not _queue.is_empty() and float(Time.get_ticks_usec() - start) / 1000.0 < budget_ms:
		var q: Array = _queue.pop_back()
		PixelArt.asteroid_sprite(q[0], q[1], q[2], q[3], q[4])
		made += 1


## Draws the colossus shader once (barely visible, for a few frames) so it is compiled before the first colossus.
var _shader_node: Sprite2D
var _shader_frames := 0


func _warm_shader() -> void:
	if _shader_node == null:
		var layer := CanvasLayer.new()
		layer.layer = 127
		add_child(layer)
		_shader_node = Sprite2D.new()
		_shader_node.texture = PixelArt.white()
		_shader_node.position = Vector2(2, 2)
		_shader_node.scale = Vector2(0.05, 0.05)
		_shader_node.modulate = Color(1, 1, 1, 0.01)
		var mat := ShaderMaterial.new()
		mat.shader = ColossusShaderW
		_shader_node.material = mat
		layer.add_child(_shader_node)
	_shader_frames += 1
	if _shader_frames > 3:
		_shader_node.get_parent().queue_free()
		_shader_done = true
