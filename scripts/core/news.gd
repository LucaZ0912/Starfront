extends RefCounted
## News of the Cluster (phase 0.5 package 16) – feeds the ticker in the HUD's ship panel and the
## news archive at every station (Lumen Newsnet).
##   world  events of the Cluster: bounty campaigns, convoys, pirate activity, notorious pirates
##   radio  chatter of the system you are in: distress calls, patrol responses, reinforcements
##   alert  station raids (these also appear in the log)
## Bounty campaigns are real: for a while a power pays more for pirates in one system.
## Owned by GameState (GameState.news), saved with the pilot.

const FactionData = preload("res://data/factions.gd")

const MAX_ITEMS := 80
const RADIO_RANGE := 26000.0      # radio chatter reaches the ticker only this close to you (≈ one asteroid field across)
const EVENT_MIN := 150.0          # a world event every 2.5–5 minutes
const EVENT_MAX := 300.0
const CAMPAIGN_TIME := 1800.0     # bounty campaigns last 30 minutes …
const CAMPAIGN_MULT := 1.5        # … and pay 50 % more

var items: Array = []             # newest first: {t, text, kind, system}
var campaigns := {}               # system id -> {faction, mult, until}
var _next_event := 0.0


func reset() -> void:
	items.clear()
	campaigns.clear()
	_next_event = GameState.play_time + randf_range(30.0, 90.0)


func to_dict() -> Dictionary:
	return {"items": items.duplicate(true), "campaigns": campaigns.duplicate(true), "next": _next_event}


func from_dict(d: Dictionary) -> void:
	items = d.get("items", []).duplicate(true)
	campaigns = {}
	var c: Dictionary = d.get("campaigns", {})
	for k in c:
		campaigns[int(k)] = c[k]
	_next_event = float(d.get("next", GameState.play_time + 60.0))


## Adds a news item; identical radio chatter within 20 s is dropped (no spam from repeated calls).
func add(text: String, kind: String = "world", system: int = -1, ticker: bool = true) -> void:
	if kind == "radio":
		for it in items.slice(0, 6):
			if it["text"] == text and GameState.play_time - float(it["t"]) < 20.0:
				return
	var item := {"t": GameState.play_time, "text": text, "kind": kind, "system": system, "ticker": ticker}
	items.push_front(item)
	if items.size() > MAX_ITEMS:
		items.pop_back()
	GameState.news_added.emit(item)


## Radio chatter. With a position it only reaches the ticker when that is within RADIO_RANGE of
## your ship – everything still goes into the archive.
func radio(text: String, system: int, pos: Vector2 = Vector2.INF) -> void:
	add(text, "radio", system, pos == Vector2.INF or near_player(system, pos))


static func near_player(system: int, pos: Vector2) -> bool:
	var w = Commands.world
	if w != null and is_instance_valid(w) and w.system_id == system and w.player != null and is_instance_valid(w.player):
		return w.player.position.distance_to(pos) <= RADIO_RANGE   # the live ship
	var f := GameState.active()
	if f == null or f.in_transit() or f.system_id != system:
		return false
	return f.position.distance_to(pos) <= RADIO_RANGE


func latest(n: int, system: int = -2) -> Array:
	var out: Array = []
	for it in items:
		if system == -2 or it["kind"] != "radio" or int(it["system"]) == system:
			out.append(it)
			if out.size() >= n:
				break
	return out


## Bounty multiplier of a running campaign in system `sid` (1.0 = none).
func bounty_mult(sid: int) -> float:
	var law := GameState.senate.mod("bounty") if Universe.controller(sid) == "assembly" else 1.0     # package 39a
	var c: Dictionary = campaigns.get(sid, {})
	if c.is_empty():
		return law
	if GameState.play_time >= float(c["until"]):
		campaigns.erase(sid)
		return law
	return float(c["mult"]) * law


func start_campaign(faction: String, sid: int) -> void:
	campaigns[sid] = {"faction": faction, "mult": CAMPAIGN_MULT, "until": GameState.play_time + CAMPAIGN_TIME}
	add("The %s raises bounties in %s by %d %% for the next %d minutes." % [FactionData.name_of(faction), Universe.systems[sid]["name"], int(round((CAMPAIGN_MULT - 1.0) * 100.0)), int(CAMPAIGN_TIME / 60.0)], "world", sid)


## Called by GameState every frame: now and then a world event.
func update() -> void:
	if GameState.play_time < _next_event or Universe.systems.is_empty():
		return
	_next_event = GameState.play_time + randf_range(EVENT_MIN, EVENT_MAX)
	var roll := randf()
	if roll < 0.4:
		_random_campaign()
	elif roll < 0.7 and GameState.convoys != null and not GameState.convoys.convoys.is_empty():
		var c: Dictionary = GameState.convoys.convoys[randi() % GameState.convoys.convoys.size()]
		add("Trade convoy under way: %s." % GameState.convoys.label(c), "world", int(c.get("cur", -1)))
	else:
		var wild: Array = []
		for s in Universe.systems:
			if float(s["security"]) < 0.4:
				wild.append(int(s["id"]))
		if not wild.is_empty():
			var sid: int = wild[randi() % wild.size()]
			add(["Pirate activity is rising in %s.", "Freighter captains report raiders near the gates of %s.", "Salvage crews avoid %s after a string of ambushes."][randi() % 3] % Universe.systems[sid]["name"], "world", sid)


func _random_campaign() -> void:
	var options: Array = []
	for s in Universe.systems:
		var sid := int(s["id"])
		var ctl := Universe.controller(sid)
		var f := ctl if ctl in FactionData.POWERS else ""
		if f == "":
			for cl in Universe.claimants(sid):
				if cl in FactionData.POWERS:
					f = cl
		if f != "" and float(s["security"]) < 0.8 and not campaigns.has(sid):
			options.append([f, sid])
	if options.is_empty():
		return
	var o: Array = options[randi() % options.size()]
	start_campaign(String(o[0]), int(o[1]))
