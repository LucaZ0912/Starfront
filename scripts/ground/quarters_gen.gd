extends RefCounted
## Package 58 (Luz, 18 Nov 2026): the quarters – a level of its own by the lift on stations and in cities: a lobby
## with the concierge's desk, then a long corridor with numbered rooms on both sides in three sizes (Small, Medium,
## Luxury). A closed room cannot be seen: only its door (a red lamp) shows. A room you rent opens (its lamp green),
## one room stands open while a cleaning robot works in it. The bed in your room: sleep – the time passes, the
## planets of the system stand elsewhere, the stations have new contracts and the bars new faces. At the corridor's
## end the penthouse lift (kept for the casino, later).
##
## The rooms of a station are fixed (seeded by its id); renting one is GameState.lodging[station id].

const SIZES := {
	"small": {"name": "Small room", "w": 4, "price": 220, "what": "a bed, a locker, a lamp"},
	"medium": {"name": "Medium room", "w": 6, "price": 450, "what": "a wide bed, a sofa, a table"},
	"luxury": {"name": "Luxury suite", "w": 9, "price": 1100, "what": "a big bed, a lounge, a screen wall"},
}
const ORDER := ["small", "medium", "luxury"]
const W := 68
const H := 25
const NY0 := 3            # north rooms: floor rows 3–8 (their back wall's face in rows 1–2)
const NY1 := 8
const CY0 := 12           # the corridor: rows 12–14 (the face of its north wall in rows 10–11)
const CY1 := 14
const SY0 := 18           # south rooms: floor rows 18–23 (their face in rows 16–17, seen from inside)
const SY1 := 23
const RX0 := 16           # the first room's left wall
const PENT_X := W - 6     # the penthouse lift at the corridor's end
const COL := Color(0.78, 0.58, 1.0)


## Has this station (or city) quarters? Not at a waystation, not in a settlement.
static func has_quarters(station: Dictionary) -> bool:
	if station.is_empty() or bool(station.get("settlement", false)):
		return false
	return not String(station.get("type", "")) in ["waystation"]


## A night's price by the station's tier.
static func price(station: Dictionary, size: String) -> int:
	var t := clampi(int(station.get("tier", 1)), 1, 3)
	return int(round(float(SIZES[size]["price"]) * (0.8 + 0.2 * t) / 10.0)) * 10


## The rooms of a station: [{i, side ("n"/"s"), x0, x1, size, no}] – the same every visit.
static func rooms(station: Dictionary) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(station.get("id", "x"))) + 7717
	var out: Array = []
	for side in ["n", "s"]:
		var x := RX0
		var k := 0
		var bag: Array = []
		while true:
			if bag.is_empty():
				var b2: Array = []
				for s0 in ["small", "small", "medium", "medium", "luxury"]:
					b2.insert(rng.randi() % (b2.size() + 1), s0)        # shuffled by the station's own rng
				bag = b2
			var s: String = bag.pop_front()
			var w := int(SIZES[s]["w"])
			if x + w > PENT_X - 2:
				var fit := ""
				for s2 in ["medium", "small"]:
					if x + int(SIZES[s2]["w"]) <= PENT_X - 2:
						fit = s2
						break
				if fit == "":
					break
				s = fit
				w = int(SIZES[s]["w"])
			k += 1
			out.append({"i": out.size(), "side": side, "x0": x, "x1": x + w - 1, "size": s, "no": (100 if side == "n" else 200) + k})
			x += w + 1
	# every size at least once
	for s3 in ORDER:
		if not out.any(func(r): return String(r["size"]) == s3):
			out[0]["size"] = s3
	return out


static func room(station: Dictionary, i: int) -> Dictionary:
	var rs := rooms(station)
	return rs[i] if i >= 0 and i < rs.size() else {}


## A free room of that size (not the one being cleaned).
static func room_for(station: Dictionary, size: String) -> int:
	var cl := clean_room(station, -1)
	var cand: Array = []
	for r in rooms(station):
		if String(r["size"]) == size and int(r["i"]) != cl:
			cand.append(int(r["i"]))
	if cand.is_empty():
		return -1
	return cand[int(GameState.play_time / 60.0) % cand.size()]


## The room the cleaning robot is in just now (changes every quarter of an hour).
static func clean_room(station: Dictionary, rented: int) -> int:
	var rs := rooms(station)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(station.get("id", "x"))) + int(GameState.play_time / 900.0) * 31
	for t in 8:
		var i := rng.randi() % rs.size()
		if i != rented:
			return i
	return -1


## The level. `rented`: your room (-1 none); `sleeping`: 0 up, 1 asleep in your bed, 2 just woken.
static func build(station: Dictionary, rented: int, sleeping: int = 0) -> GroundMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(station.get("id", "x"))) + 58
	var m := GroundMap.new()
	m.pal = DeckGen.palette_for(station).duplicate()
	m.pal["accent"] = COL
	m.pal["floor"] = Color(0.32, 0.3, 0.38)
	m.pal["floor2"] = Color(0.4, 0.36, 0.44)
	m.title = String(station.get("name", "Station"))
	m.hull_top = -60
	m.setup(W, H)
	m.fill(0, 0, W, H, GroundMap.T.CAP)
	# ---- the lift room (Luz: a room of its own, as in the clinic), through an opening into the lobby beside it –
	# you come out in front of the concierge's desk, not behind it
	m.fill(1, 1, 5, 2, GroundMap.T.FACE)
	m.fill(1, NY0, 5, NY1 - NY0 + 2, GroundMap.T.FLOOR, 2)
	for lx0 in [1, 4]:
		m.face_deco.append({"kind": "lift", "x": lx0, "y": 2, "w": 2, "col": Color(0.4, 1.0, 0.6)})
		m.lifts.append({"x": lx0, "y": 2, "w": 2})
	m.decals.append({"kind": "mat", "x": 1, "y": NY0, "w": 5, "h": 1, "col": COL})
	m.spawn = Vector2(3.5, NY0 + 1.6) * GroundMap.TILE
	m.zones.append({"rect": Rect2(Vector2(1, NY0) * GroundMap.TILE, Vector2(5, 1.4) * GroundMap.TILE), "kind": "lift", "id": "lift",
		"title": "Lifts", "col": Color(0.4, 1.0, 0.6), "sign": Vector2(-100, -100)})
	m.add_object({"kind": "plant", "x": 1, "y": NY1 + 1, "w": 1, "h": 1})
	m.fill(6, 6, 1, 3, GroundMap.T.FLOOR, 2)                         # the opening into the lobby
	# ---- the lobby: the concierge's desk against the back wall, a lounge, open onto the corridor
	m.fill(7, 1, 7, 2, GroundMap.T.FACE)
	m.fill(7, NY0, 7, SY1 - NY0 + 1, GroundMap.T.FLOOR, 2)
	m.fill(14, CY0, W - 15, CY1 - CY0 + 1, GroundMap.T.FLOOR, 6)
	m.fill(14, NY1 + 2, W - 15, 2, GroundMap.T.FACE)                 # the corridor's north wall, its face
	m.holos.append({"pos": Vector2(10.5, 1.6) * GroundMap.TILE, "text": "QUARTERS", "sub": "rooms by the night", "col": COL})
	for fx in [7, 12]:
		m.face_deco.append({"kind": "screen", "x": fx, "y": 2, "w": 2, "col": COL})
	m.add_object({"kind": "counter", "x": 8, "y": 5, "w": 5, "h": 1})
	m.people.append({"pos": Vector2(10.5, 4.4) * GroundMap.TILE, "dir": 0, "role": "keeper", "look": _concierge_look(rng)})
	m.set_meta("concierge_look", m.people.back()["look"])
	m.zones.append({"rect": Rect2(Vector2(8, 6) * GroundMap.TILE, Vector2(5, 1.5) * GroundMap.TILE), "kind": "q_desk", "id": "q_desk",
		"title": "Concierge: rent a room", "col": COL, "sign": Vector2(-100, -100)})
	m.decals.append({"kind": "rug", "x": 7, "y": 15, "w": 7, "h": 7, "col": COL.darkened(0.45)})
	_seat_row(m, 7, 16, rng)
	m.add_object({"kind": "plant", "x": 13, "y": NY0, "w": 1, "h": 1})
	m.add_object({"kind": "plant", "x": 7, "y": SY1, "w": 1, "h": 1})
	m.add_object({"kind": "plant", "x": 13, "y": SY1, "w": 1, "h": 1})
	m.decals.append({"kind": "guide", "x": 14, "y": CY0 + 1, "w": W - 16, "h": 1, "col": COL})
	m.lights.append({"pos": Vector2(10.5, 5.0) * GroundMap.TILE, "r": 60.0, "col": COL.lerp(Color.WHITE, 0.3), "a": 0.22})
	m.lights.append({"pos": Vector2(3.5, NY0 + 2.0) * GroundMap.TILE, "r": 46.0, "col": Color(0.8, 1.0, 0.9), "a": 0.16})
	# ---- the rooms
	var clean := clean_room(station, rented)
	for r in rooms(station):
		var i := int(r["i"])
		_room(m, r, i == rented, i == clean and i != rented, sleeping if i == rented else 0, rng)
	# ---- the penthouse lift at the corridor's end (Luz: the casino part)
	m.fill(PENT_X - 1, CY0, 5, CY1 - CY0 + 1, GroundMap.T.FLOOR, 4)
	m.face_deco.append({"kind": "lift", "x": PENT_X, "y": NY1 + 3, "w": 2, "col": Color(1.0, 0.82, 0.35)})
	m.face_deco.append({"kind": "room_plate", "x": PENT_X + 2, "y": NY1 + 3, "w": 1, "no": 0, "text": "PH", "col": Color(1.0, 0.82, 0.35)})
	m.zones.append({"rect": Rect2(Vector2(PENT_X - 0.5, CY0) * GroundMap.TILE, Vector2(3, 1.4) * GroundMap.TILE), "kind": "q_penthouse", "id": "q_penthouse",
		"title": "Penthouse lift", "col": Color(1.0, 0.82, 0.35), "sign": Vector2(-100, -100)})
	m.lights.append({"pos": Vector2(PENT_X + 1.0, CY0 + 0.5) * GroundMap.TILE, "r": 50.0, "col": Color(1.0, 0.82, 0.35), "a": 0.25})
	for lxx in range(15, W - 4, 7):
		m.lights.append({"pos": Vector2(lxx, CY0 + 1.5) * GroundMap.TILE, "r": 44.0, "col": COL.lerp(Color.WHITE, 0.5), "a": 0.14})
	for k in 5:
		m.wander.append(Vector2(rng.randf_range(15, W - 8), rng.randf_range(CY0 + 0.4, CY1 + 0.6)) * GroundMap.TILE)
	m.wander.append(Vector2(10.5, 12.0) * GroundMap.TILE)
	DeckGen._seats(m)
	return m


static func _seat_row(m: GroundMap, x: int, y: int, rng: RandomNumberGenerator) -> void:
	m.add_object({"kind": "sofa", "x": x + 1, "y": y, "w": 3, "h": 1, "col": COL.darkened(0.35), "face": 2})
	m.add_object({"kind": "table_small", "x": x + 2, "y": y + 2, "w": 1, "h": 1})
	m.add_object({"kind": "sofa", "x": x + 1, "y": y + 4, "w": 3, "h": 1, "col": COL.darkened(0.35), "face": 0})


## One room: closed (only its door), or open – yours (its bed to sleep in) or being cleaned.
static func _room(m: GroundMap, r: Dictionary, mine: bool, cleaning: bool, sleeping: int, rng: RandomNumberGenerator) -> void:
	var x0 := int(r["x0"])
	var x1 := int(r["x1"])
	var w := x1 - x0 + 1
	var north := String(r["side"]) == "n"
	var dx := x0 + 1                                  # the door (2 wide)
	var no := int(r["no"])
	var size := String(r["size"])
	if not (mine or cleaning):
		if north:
			m.face_deco.append({"kind": "room_door", "x": dx, "y": NY1 + 3, "w": 2, "no": no, "col": Color(1.0, 0.3, 0.3)})
		else:
			m.decals.append({"kind": "room_door_s", "x": dx, "y": CY1, "w": 2, "h": 1, "no": no, "col": Color(1.0, 0.3, 0.3)})
		var fy := CY0 if north else CY1
		m.zones.append({"rect": Rect2(Vector2(dx - 0.3, fy) * GroundMap.TILE, Vector2(2.6, 1.0) * GroundMap.TILE), "kind": "q_door", "id": "q_door_%d" % no,
			"title": "Room %d" % no, "col": Color(1.0, 0.45, 0.45), "sign": Vector2(-100, -100), "no": no})
		return
	var ry0 := NY0 if north else SY0
	var ry1 := NY1 if north else SY1
	if north:
		m.fill(x0, 1, w, 2, GroundMap.T.FACE)
		m.fill(x0, ry0, w, ry1 - ry0 + 1, GroundMap.T.FLOOR, 3 if size == "luxury" else 1)
		m.fill(dx, NY1 + 1, 2, 3, GroundMap.T.DOOR, 1)
	else:
		m.fill(x0, SY0 - 2, w, 2, GroundMap.T.FACE)
		m.fill(x0, ry0, w, ry1 - ry0 + 1, GroundMap.T.FLOOR, 3 if size == "luxury" else 1)
		m.fill(dx, CY1 + 1, 2, 3, GroundMap.T.DOOR, 1)
	var plate_x := dx + 2 if dx + 2 <= x1 else dx - 1
	if north and not mine:                           # (yours: the number is on its door)
		m.face_deco.append({"kind": "room_plate", "x": plate_x, "y": NY1 + 3, "w": 1, "no": no, "col": Color(1.0, 0.8, 0.3)})
	if mine:
		# (Luz: no sign over it – your room shows by the quest tracker; its door slides open when you stand by it)
		m.set_meta("my_door", {"x": dx, "north": north, "no": no, "size": size})
		if not north:
			# (Luz) a room below the corridor: its number on the floor by the door, as at the closed ones
			m.decals.append({"kind": "room_door_s", "x": dx, "y": CY1, "w": 2, "h": 1, "no": no, "open": true, "col": Color(0.4, 1.0, 0.55)})
	# the bed against the back wall (north rooms: the top; south rooms: the bottom row is the far side – the top too)
	var bw := 2 if size == "small" else 3
	var bx := x1 - bw + 1
	var bh := 2                                      # (Luz: the pilot shown in it – a bed of a person's length, ~2 m)
	var by := ry0 if north else ry1 - bh + 1         # against the far wall
	var bed := {"kind": "q_bed", "x": bx, "y": by, "w": bw, "h": bh, "col": COL if size != "small" else Color(0.45, 0.6, 0.9), "seed": no}
	if cleaning:
		bed["unmade"] = true
	if sleeping > 0:
		bed["patient"] = ChibiArt.PilotArt.clean(GameState.pilot.get("look", {}))
		bed["awake"] = sleeping == 2
	m.add_object(bed)
	m.lights.append({"pos": Vector2(bx + bw * 0.5, by + 1.5) * GroundMap.TILE, "r": 42.0 + w * 4.0, "col": Color(1.0, 0.86, 0.66), "a": 0.2})
	match size:
		"small":
			m.add_object({"kind": "locker", "x": x0, "y": ry0, "w": 1, "h": 1})
			m.add_object({"kind": "plant", "x": x0, "y": ry1, "w": 1, "h": 1})
		"medium":
			m.add_object({"kind": "locker", "x": x0, "y": ry0, "w": 1, "h": 1})
			m.add_object({"kind": "sofa", "x": x0, "y": ry1 - 1, "w": 2, "h": 1, "col": COL.darkened(0.3), "face": 0})
			m.add_object({"kind": "table_small", "x": x0 + 1, "y": ry0 + 2, "w": 1, "h": 1})
			m.add_object({"kind": "plant", "x": x1, "y": ry1 if north else ry0, "w": 1, "h": 1})
		"luxury":
			m.decals.append({"kind": "rug", "x": x0 + 1, "y": ry0 + 3, "w": w - 2, "h": 2, "col": Color(0.55, 0.35, 0.2)})
			m.add_object({"kind": "display", "x": x0 if north else x0 + 4, "y": ry0, "w": 2, "h": 1, "col": COL})      # (not in the door's way)
			m.add_object({"kind": "sofa", "x": x0, "y": ry1 - 1, "w": 3, "h": 1, "col": COL.darkened(0.25), "face": 0})
			m.add_object({"kind": "round_table", "x": x0 + 4, "y": ry1 - 2, "w": 1, "h": 1})
			m.add_object({"kind": "fridge", "x": x0 + 3, "y": ry0, "w": 1, "h": 1})
			m.add_object({"kind": "locker", "x": x0 + 2 if north else x0 + 6, "y": ry0, "w": 1, "h": 1})
			m.add_object({"kind": "plant", "x": x1, "y": ry1 if north else ry0, "w": 1, "h": 1})
			m.add_object({"kind": "plant", "x": x0 + 3, "y": ry1, "w": 1, "h": 1})
	if cleaning:
		m.set_meta("clean_bot", Rect2(Vector2(x0 + 0.6, (ry0 + 3.4) if north else (ry0 + 0.6)) * GroundMap.TILE, Vector2(maxf(w - 2.4, 1.0), 1.6) * GroundMap.TILE))
	if mine:
		# the locker: your gear (Luz – straight to the character's equipment)
		var lx := x0
		if size == "luxury":
			lx = x0 + 2 if north else x0 + 6
		m.zones.append({"rect": Rect2(Vector2(lx - 0.3, ry0 + 1.0) * GroundMap.TILE, Vector2(1.6, 1.2) * GroundMap.TILE), "kind": "q_locker", "id": "q_locker",
			"title": "Locker: your gear", "col": Color(0.4, 1.0, 0.55), "sign": Vector2(-100, -100)})
		var zy: float = float(by + bh) if north else float(by) - 1.3
		m.zones.append({"rect": Rect2(Vector2(bx - 0.2, zy) * GroundMap.TILE, Vector2(bw + 0.4, 1.3) * GroundMap.TILE), "kind": "q_bed", "id": "q_bed",
			"title": "Bed: sleep", "col": Color(0.4, 1.0, 0.55), "sign": Vector2(-100, -100)})
		m.set_meta("bed_front", Vector2(bx + bw * 0.5, (zy + 1.3) if north else (zy + 0.2)) * GroundMap.TILE)      # (clear of the bed)
		m.set_meta("room_door_front", Vector2(dx + 1.0, (CY0 + 0.6) if north else (CY1 + 0.4)) * GroundMap.TILE)


static func _concierge_look(rng: RandomNumberGenerator) -> Dictionary:
	var lk := ChibiArt.PilotArt.random_look(rng)
	lk["headgear"] = 1
	lk["outfit"] = 1
	lk["color1"] = 11
	lk["color2"] = 3
	return lk


## Your room's door (Luz): two leaves that slide apart into the wall while you stand by it, and close behind you.
class RoomDoor extends Node2D:
	var view = null                       # the ground view (its pilot)
	var rect := Rect2()                   # the opening's face, art px
	var no := 0                           # the room's number (on the door, Luz)
	var k := 0.0                          # 0 shut … 1 open
	var _was := false

	func setup(d: Dictionary) -> void:
		var T := float(GroundMap.TILE)
		var y0 := float(NY1 + 2) if bool(d["north"]) else float(CY1 + 2)
		rect = Rect2(float(d["x"]) * T, y0 * T, 2.0 * T, 2.0 * T)
		no = int(d.get("no", 0))
		position = Vector2(rect.position.x, rect.end.y) * GroundMap.SCALE

	func near() -> bool:
		if view == null or not is_instance_valid(view) or view.pilot == null or not is_instance_valid(view.pilot):
			return false
		var c := rect.get_center()
		var p: Vector2 = view.pilot.pos
		return absf(p.x - c.x) < GroundMap.TILE * 1.6 and absf(p.y - c.y) < GroundMap.TILE * 2.6

	func _process(dt: float) -> void:
		var open := near()
		if open != _was:
			_was = open
			Audio.play("module_on" if open else "module_off", "quarters: your door", -12.0)
		k = move_toward(k, 1.0 if open else 0.0, dt * 3.5)
		queue_redraw()

	func _draw() -> void:
		var s := GroundMap.SCALE
		var w := rect.size.x * s
		var h := rect.size.y * s
		var top := -h
		var leaf := w * 0.5 * (1.0 - k)
		var dc := Color(0.24, 0.22, 0.3)
		if leaf > 0.5:
			draw_rect(Rect2(0, top, leaf, h), dc)
			draw_rect(Rect2(w - leaf, top, leaf, h), dc)
			draw_rect(Rect2(0, top, leaf, 1.0 * s), dc.lightened(0.25))
			draw_rect(Rect2(w - leaf, top, leaf, 1.0 * s), dc.lightened(0.25))
			draw_rect(Rect2(leaf - 1.0 * s, top, 1.0 * s, h), dc.darkened(0.35))
			draw_rect(Rect2(w - leaf, top, 1.0 * s, h), dc.darkened(0.35))
			if k < 0.35:
				# its number, as on the closed rooms' doors (for a room below the corridor: on its inside)
				draw_rect(Rect2(4.0 * s, top + 5.0 * s, w - 8.0 * s, 7.0 * s), Color(0.08, 0.08, 0.1))
				var txt := str(no)
				for di in txt.length():                  # the same pixel digits as on the other doors
					var gl: Array = GroundMap.DIGITS.get(txt[di], GroundMap.DIGITS["0"])
					for gy in 5:
						for gx in 3:
							if String(gl[gy])[gx] == "1":
								draw_rect(Rect2((6.0 + di * 4 + gx) * s, top + (6.0 + gy) * s, s, s), Color(0.95, 0.92, 0.85))
				draw_rect(Rect2(w - 6.0 * s, top + 14.0 * s, 3.0 * s, 3.0 * s), Color(0.4, 1.0, 0.55))
		draw_rect(Rect2(-1.0 * s, top - 1.0 * s, w + 2.0 * s, 1.0 * s), Color(0.4, 1.0, 0.55, 0.6 + 0.4 * k))   # the frame's light


## The cleaning robot: a little round machine going to and fro over the floor of the room, its light blinking.
class CleanBot extends Node2D:
	var area := Rect2()
	var t := 0.0

	func _process(dt: float) -> void:
		t += dt
		var k := 0.5 + 0.5 * sin(t * 0.7)
		var p := Vector2(area.position.x + area.size.x * k, area.position.y + area.size.y * (0.5 + 0.45 * sin(t * 1.9)))
		position = p * GroundMap.SCALE
		queue_redraw()

	func _draw() -> void:
		var s := GroundMap.SCALE
		draw_circle(Vector2(0, 3) * s, 7.5 * s, Color(0, 0, 0, 0.25))
		draw_circle(Vector2.ZERO, 7.0 * s, Color(0.12, 0.13, 0.16))
		draw_circle(Vector2.ZERO, 6.0 * s, Color(0.85, 0.87, 0.9))
		draw_circle(Vector2(0, -1) * s, 3.2 * s, Color(0.7, 0.72, 0.76))
		var on := fmod(t, 1.0) < 0.5
		draw_circle(Vector2(0, -1) * s, 1.3 * s, Color(0.3, 1.0, 0.6) if on else Color(0.1, 0.4, 0.25))
		for a in 2:
			var ang := t * 9.0 + a * PI
			draw_line(Vector2(-5, 4) * s, (Vector2(-5, 4) + Vector2.from_angle(ang) * 3.0) * s, Color(0.5, 0.5, 0.55), s)
			draw_line(Vector2(5, 4) * s, (Vector2(5, 4) + Vector2.from_angle(-ang) * 3.0) * s, Color(0.5, 0.5, 0.55), s)
