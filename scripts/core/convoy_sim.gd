class_name ConvoySim
extends Node
## Trade convoys of the whole cluster (phase 0.5 package 11).
## Convoys carry goods from a station that produces them to one that consumes them, along real
## hyperspace routes. Outside the system the player is in they are simulated coarsely (a timer per
## system, a small risk of being lost in lawless space). When a convoy reaches the observed system,
## it "goes live": the system's Traffic spawns real ships that fly to the gate or the destination
## station; when they jump out or are lost, the convoy is handed back to this simulation.
## Not saved – convoys are rebuilt on load.

signal convoy_live(c: Dictionary)          # entered the observed system → spawn ships
signal convoy_lost(c: Dictionary)
signal convoy_delivered(c: Dictionary)

const CommodityData = preload("res://data/commodities.gd")
const FactionData = preload("res://data/factions.gd")
const LEG_TIME := Vector2(140.0, 280.0)     # seconds a convoy spends crossing one system
const MAX_JUMPS := 5

var convoys: Array = []
var observed := -1          # system with a live view (-1 = none)
var _next_id := 0
var _spawn_t := 3.0
var _seeded := false
var _rng := RandomNumberGenerator.new()


func reset() -> void:
	convoys.clear()
	observed = -1
	_seeded = false
	_spawn_t = 3.0
	_rng.randomize()


## How many convoys the cluster supports: grows with its trade.
func target_count() -> int:
	var w := 0.0
	for s in Universe.systems:
		for pe in s.get("stations_plan", []):
			w += float(pe[1]) * (2.0 if pe[0] == "trade" else 0.5)
	return clampi(int(w / 3.0), 8, 30)


func _process(delta: float) -> void:
	if not GameState.running or Universe.test_mode or Universe.systems.size() < 2:
		return
	if not _seeded:
		_seeded = true
		for i in target_count():
			var c := _make()
			if c.is_empty():
				continue
			# spread the starting convoys along their routes
			for k in _rng.randi_range(0, (c["route"] as Array).size()):
				if c["cur"] == c["dst"]:
					break
				_hop(c)
			c["t"] = _rng.randf_range(10.0, float(c["T"]))
	_spawn_t -= delta
	if _spawn_t <= 0.0:
		_spawn_t = 20.0
		if convoys.size() < target_count():
			_make()
	for c in convoys.duplicate():
		if c["live"]:
			continue
		c["t"] = float(c["t"]) - delta
		if float(c["t"]) > 0.0:
			continue
		if c["cur"] == c["dst"]:
			_finish(c)
			continue
		# lawless space: a small chance that the convoy does not make it
		var sec := float(Universe.systems[c["cur"]]["security"])
		if _rng.randf() < (1.0 - sec) * 0.05:
			convoys.erase(c)
			convoy_lost.emit(c)
			continue
		_hop(c)
		if c["cur"] == observed:
			_go_live(c)


## Moves a convoy one system further along its route (abstract).
func _hop(c: Dictionary) -> void:
	var route: Array = c["route"]
	if route.is_empty():
		return
	c["prev"] = c["cur"]
	c["cur"] = int(route.pop_front())
	c["departed"] = true
	c["T"] = _rng.randf_range(LEG_TIME.x, LEG_TIME.y)
	c["t"] = c["T"]


func _finish(c: Dictionary) -> void:
	convoys.erase(c)
	convoy_delivered.emit(c)


func _go_live(c: Dictionary) -> void:
	c["live"] = true
	convoy_live.emit(c)


## A new convoy: source station weighted by tier (trade hubs count triple), cargo = something it
## produces, destination = the nearest station (≤ 5 jumps, routes up to class 2) that consumes it.
func _make() -> Dictionary:
	var pool: Array = []
	var total := 0.0
	for s in Universe.systems:
		var plan: Array = s.get("stations_plan", [])
		for i in plan.size():
			var w := float(plan[i][1]) * (3.0 if plan[i][0] == "trade" else 1.0) * (0.7 + 0.15 * Economy.level(int(s["id"])))     # 42c
			pool.append([int(s["id"]), i, String(plan[i][0]), int(plan[i][1]), w])
			total += w
	if pool.is_empty():
		return {}
	for attempt in 6:
		var r := _rng.randf() * total
		var src: Array = pool[0]
		for e in pool:
			r -= float(e[4])
			if r <= 0.0:
				src = e
				break
		# package 42c: what the source's market makes, bound for a market that wants it
		var src_st := Universe.find_station(int(src[0]), "st_%d_%d" % [src[0], src[1]])
		var goods: Array = []
		for cid in GameData.commodities:
			if Market.on_market(cid) and not src_st.is_empty() and Market.role(src_st, cid) == "produce":
				goods.append(cid)
		if goods.is_empty():
			goods = (CommodityData.STATION_TYPES[src[2]]["produces"] as Array).duplicate()
		goods.shuffle()
		for good in goods.slice(0, 8):
			var best: Array = []
			var best_score := -INF
			for e2 in pool:
				if e2[0] == src[0]:
					continue
				var dst_st := Universe.find_station(int(e2[0]), "st_%d_%d" % [e2[0], e2[1]])
				if dst_st.is_empty() or Market.role(dst_st, String(good)) != "consume":
					continue
				var path := Universe.find_path(src[0], e2[0], 2)
				if path.is_empty() or path.size() > MAX_JUMPS:
					continue
				var score := -float(path.size()) + float(e2[3]) * 0.3 + _rng.randf() * 1.5
				if score > best_score:
					best_score = score
					best = [e2, path]
			if best.is_empty():
				continue
			var dst: Array = best[0]
			var gov := Universe.station_faction(src[0], src[1])
			var danger := 0.0
			for sid in best[1]:
				danger = maxf(danger, 1.0 - float(Universe.systems[sid]["security"]))
			_next_id += 1
			var c := {
				"id": _next_id, "gov": gov, "cargo": good,
				"freighters": 1 + int(src[3] >= 2) + int(src[3] >= 3 and _rng.randf() < 0.5),
				"escorts": (1 + int(danger > 0.55)) if gov in FactionData.POWERS else 0,
				"src": src[0], "src_st": "st_%d_%d" % [src[0], src[1]],
				"dst": dst[0], "dst_st": "st_%d_%d" % [dst[0], dst[1]],
				"route": (best[1] as Array).duplicate(), "cur": src[0], "prev": -1, "departed": false,
				"T": _rng.randf_range(LEG_TIME.x, LEG_TIME.y) * 0.5, "t": 0.0, "live": false,
			}
			c["t"] = c["T"]
			convoys.append(c)
			if c["cur"] == observed:
				_go_live(c)
			return c
	return {}


## A convoy for an escort contract (package 17): leaves `src_st` now, bound for `dst_st`.
func make_escort(src: int, src_st: String, dst: int, dst_st: String, gov: String, mission_id: String, freighters: int = 2) -> Dictionary:
	var path := Universe.find_path(src, dst, 1)
	if path.is_empty():
		return {}
	var src_data := Universe.find_station(src, src_st)
	var goods: Array = CommodityData.STATION_TYPES[String(src_data.get("type", "trade"))]["produces"]
	_next_id += 1
	var c := {
		"id": _next_id, "gov": gov, "cargo": goods[_rng.randi() % goods.size()] if not goods.is_empty() else "food",
		"freighters": freighters, "escorts": 1 if gov in FactionData.POWERS else 0,
		"src": src, "src_st": src_st, "dst": dst, "dst_st": dst_st,
		"route": path.duplicate(), "cur": src, "prev": -1, "departed": false,
		"T": _rng.randf_range(LEG_TIME.x, LEG_TIME.y) * 0.5, "t": 0.0, "live": false, "mission": mission_id,
	}
	c["t"] = c["T"]
	convoys.append(c)
	if c["cur"] == observed:
		_go_live(c)
	return c


func find(id: int) -> Dictionary:
	for c in convoys:
		if int(c["id"]) == id:
			return c
	return {}


## A system view opened: every convoy currently crossing it goes live.
func set_observed(sid: int) -> void:
	observed = sid
	for c in convoys:
		if not c["live"] and c["cur"] == sid:
			_go_live(c)


func clear_observed(sid: int) -> void:
	if observed == sid:
		observed = -1


## Live ships left the view without jumping (player left): back to the coarse simulation.
func dematerialize(c: Dictionary, freighters: int, escorts: int) -> void:
	c["live"] = false
	c["freighters"] = freighters
	c["escorts"] = escorts
	if freighters <= 0:
		convoys.erase(c)
		return
	c["t"] = minf(float(c["t"]), float(c["T"]) * 0.5)


## The live convoy jumped to `next`.
func live_jumped(c: Dictionary, next: int, freighters: int, escorts: int) -> void:
	c["live"] = false
	c["freighters"] = freighters
	c["escorts"] = escorts
	var route: Array = c["route"]
	if not route.is_empty() and int(route[0]) == next:
		route.pop_front()
	c["prev"] = c["cur"]
	c["cur"] = next
	c["departed"] = true
	c["T"] = _rng.randf_range(LEG_TIME.x, LEG_TIME.y)
	c["t"] = c["T"]
	if freighters <= 0:
		convoys.erase(c)


func live_delivered(c: Dictionary) -> void:
	convoys.erase(c)
	convoy_delivered.emit(c)


func live_lost(c: Dictionary) -> void:
	convoys.erase(c)
	convoy_lost.emit(c)


## Position for the galaxy map: between the current system and the next one.
func map_pos(c: Dictionary) -> Vector2:
	var a: Vector2 = Universe.systems[c["cur"]]["pos"]
	var route: Array = c["route"]
	if route.is_empty() or c["live"]:
		return a
	var b: Vector2 = Universe.systems[int(route[0])]["pos"]
	var f := 1.0 - clampf(float(c["t"]) / maxf(float(c["T"]), 1.0), 0.0, 1.0)
	return a.lerp(b, f * 0.5)


func count_in(sid: int) -> int:
	var n := 0
	for c in convoys:
		if c["cur"] == sid:
			n += 1
	return n


static func label(c: Dictionary) -> String:
	var who := FactionData.short_of(String(c["gov"])) if String(c["gov"]) != "" else "Independent"
	return "%s convoy (%s)" % [who, GameData.item_name(String(c["cargo"]))]
