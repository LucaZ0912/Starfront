extends RefCounted
## Notorious pirates (phase 0.5 package 15) – named captains with a nickname, their own paint, a
## special trait and escorts in formation. They roam the whole Cluster except the home systems
## (the three capitals and the pilot's start system): lawless space for long stretches, safer
## systems only for short visits, lurking in the asteroid fields. They never leave while the
## pilot is in their system. Owned by GameState (GameState.notorious), saved with the pilot.
##
## Danger: 1–5 stars. More stars = more escorts, heavier escort ships and a tougher captain.
## A captain gains a star every STAR_TIME it survives. The bounty is independent of the stars and
## rises in small steps the longer the captain lives ("wanted since").
## 5-star captains now and then raid a station (never a military outpost): announced 5 minutes
## ahead, fought live when the pilot is there (station hull bar, turrets that can be shot down or
## knocked out by ion torpedoes), resolved by chance otherwise. A won raid adds 100,000 cr to the
## bounty and turns one star red; the station goes offline (StationStatus). A captain about to lose
## flees and hides for a while.
## After a death a successor (1–2 stars) takes over the crew after a while. A step towards bosses.

const FactionData = preload("res://data/factions.gd")
const PilotArtN = preload("res://scripts/core/pilot_art.gd")
const ArchData = preload("res://data/pirate_archetypes.gd")

const START_STARS := [1, 1, 2, 2, 3]    # the five captains of a new game
const COUNT := 5
const MOVE_MIN := 360.0                 # lawless space: 6–12 min per system
const MOVE_MAX := 720.0
const VISIT_MIN := 120.0                # safer systems (security > LAWLESS): only 2–4 min
const VISIT_MAX := 240.0
const LAWLESS := 0.65
const STAR_TIME := 1800.0               # one more star every 30 min alive (max 5)
const BOUNTY_STEP := 500                # the bounty rises by 500 cr …
const BOUNTY_EVERY := 240.0             # … every 4 minutes alive
const SUCCESSOR_MIN := 1200.0           # a successor takes over after 20–40 minutes
const SUCCESSOR_MAX := 2400.0
const RAID_CHANCE := 0.5                # 5 stars: chance to raid a station when arriving in a system with one
const RAID_MIN := 180.0
const RAID_MAX := 300.0
const RAID_WARNING := 300.0             # the raid is announced 5 minutes ahead
const RAID_PRIZE := 100000              # bounty bonus for a won raid
const HIDE_TIME := 900.0                # a captain that fled stays hidden for 15 minutes
## escorts by stars (index = stars); "never_alone" adds two
const ESCORTS := [0, 2, 2, 3, 4, 5]
## damage the captain takes by stars
const TOUGHNESS := [1.0, 0.85, 0.75, 0.65, 0.58, 0.5]

## Special traits: name, description, effect handled by Ship (trait checks).
const TRAITS := {
	"shield_breaker": {"name": "Shield Breaker", "desc": "Its weapons tear through shields (+60 % damage while the target's shield holds)."},
	"never_alone": {"name": "Never Alone", "desc": "Always flies with two extra escorts."},
	"iron_hide": {"name": "Iron Hide", "desc": "Takes 40 % less damage."},
	"ghost": {"name": "Ghost", "desc": "Hard to lock on – target locks take 2.5× as long."},
	"overcharged": {"name": "Overcharged", "desc": "Its weapons cycle 40 % faster."},
	"regenerator": {"name": "Regenerator", "desc": "Shields regenerate three times as fast and armour repairs itself."},
}
const FIRST := ["Vesna", "Kord", "Isolde", "Marek", "Juno", "Taras", "Ilka", "Dragan", "Sabeth", "Orin",
	"Mirela", "Cass", "Brannoc", "Yelva", "Quill", "Tamsin", "Rook", "Zora", "Halvard", "Ness"]
const LAST := ["Kaine", "Morrow", "Vrell", "Ashgrove", "Tolt", "Ravenscar", "Dunmere", "Sorrell", "Klav",
	"Hesk", "Varga", "Lunt", "Corvane", "Brisk", "Malloy", "Stray", "Okonkwo", "Feld", "Ostrava", "Wynn"]
const NICK := ["the Butcher", "Red Veil", "Quiet Knife", "the Undertaker", "Hollow Eye", "Saint Rust",
	"the Lantern", "Ninefingers", "Blackwake", "the Tax Collector", "Old Static", "the Widowmaker",
	"Ironjaw", "Cinder", "the Magpie", "Cold Harbor"]
## Own paint per captain: [hull, accent]
const PAINTS := [
	[Color(0.12, 0.11, 0.12), Color(1.0, 0.78, 0.2)], [Color(0.85, 0.85, 0.82), Color(0.95, 0.15, 0.2)],
	[Color(0.2, 0.08, 0.1), Color(1.0, 0.3, 0.6)], [Color(0.1, 0.16, 0.2), Color(0.3, 1.0, 0.7)],
	[Color(0.35, 0.28, 0.2), Color(1.0, 0.55, 0.15)], [Color(0.16, 0.12, 0.25), Color(0.6, 0.85, 1.0)],
]

var captains: Array = []            # see _make()
var _counter := 0
var news: Array = []                # sightings, raids, deaths (newest first, max 30) – for the news ticker (package 16)


func reset() -> void:
	captains.clear()
	news.clear()
	_counter = 0


func to_dict() -> Dictionary:
	return {"captains": captains.duplicate(true), "counter": _counter, "news": news.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	reset()
	captains = d.get("captains", []).duplicate(true)
	_counter = int(d.get("counter", 0))
	news = d.get("news", []).duplicate(true)


## Creates the starting captains (new game): two 1-star, two 2-star and one 3-star captain.
func setup() -> void:
	reset()
	for i in COUNT:
		var c := _make(i, "", int(START_STARS[i]))
		c["system"] = _random_haunt(true)
		c["next_move"] = GameState.play_time + randf_range(MOVE_MIN, MOVE_MAX)
		captains.append(c)


func _make(slot: int, predecessor: String, stars: int) -> Dictionary:
	_counter += 1
	var factions: Array = FactionData.PIRATES
	var fid: String = factions[slot % factions.size()]
	var tr_keys: Array = TRAITS.keys()
	var arch_keys: Array = ArchData.ARCHETYPES.keys()
	var arch: String = arch_keys[randi() % arch_keys.size()]
	var tr: String = tr_keys[randi() % tr_keys.size()]
	var c := {
		"id": "nt%d" % _counter, "slot": slot,
		"name": "%s %s" % [FIRST[randi() % FIRST.size()], LAST[randi() % LAST.size()]],
		"nick": NICK[randi() % NICK.size()], "faction": fid, "archetype": arch, "trait": tr,
		"preset": String(ArchData.ARCHETYPES[arch]["presets"][2]), "escorts": [],
		"paint": _counter % PAINTS.size(), "stars": 0,
		"base_bounty": int(randf_range(40000.0, 80000.0) / 1000.0) * 1000, "bounty": 0,
		"since": GameState.play_time, "star_t": GameState.play_time,
		"alive": true, "system": -1, "seen": GameState.play_time, "next_move": 0.0, "respawn": 0.0,
		"raid": {}, "predecessor": predecessor, "bonus": 0, "red": 0, "hidden_until": 0.0,
		# package 34: a real character – a face for the posters, Piloting and Gunnery that grow with the stars
		"look": PilotArtN.random_look(), "skill_base": randi_range(1, 3),
	}
	c["bounty"] = int(c["base_bounty"])
	_set_stars(c, stars)
	return c


## Sets the danger level and grows the escort to match (escorts are only ever added).
func _set_stars(c: Dictionary, stars: int) -> void:
	c["stars"] = clampi(stars, 1, 5)
	var want := int(ESCORTS[int(c["stars"])]) + (2 if c["trait"] == "never_alone" else 0)
	var arch_keys: Array = ArchData.ARCHETYPES.keys()
	var esc: Array = c["escorts"]
	while esc.size() < want:
		var ea: String = arch_keys[randi() % arch_keys.size()]
		var tier := 0 if int(c["stars"]) <= 1 else (1 if int(c["stars"]) <= 3 else randi_range(1, 2))
		esc.append(String(ArchData.ARCHETYPES[ea]["presets"][tier]))


## Package 34: Piloting / Gunnery of a captain (+1 % speed / damage each): grows with the stars.
static func skill(c: Dictionary) -> int:
	return clampi(int(c.get("skill_base", 2)) + int(c.get("stars", 1)) * 2 - 1, 1, 12)


## Makes older captains real characters too.
static func ensure_character(c: Dictionary) -> void:
	if not c.has("look"):
		c["look"] = PilotArtN.random_look()
	if not c.has("skill_base"):
		c["skill_base"] = 2


static func title(c: Dictionary) -> String:
	return "%s »%s«" % [c["name"], c["nick"]]


static func trait_name(c: Dictionary) -> String:
	return String(TRAITS.get(c["trait"], {}).get("name", "?"))


static func stars_text(c: Dictionary) -> String:
	var n := int(c.get("stars", 1))
	return "★".repeat(n) + "☆".repeat(5 - n)


## Stars for RichTextLabels: red stars (won raids) first, then gold, then empty.
static func stars_bbcode(c: Dictionary) -> String:
	var n := int(c.get("stars", 1))
	var r := mini(int(c.get("red", 0)), n)
	return "[color=#ff3030]%s[/color][color=#ffd060]%s[/color][color=#706850]%s[/color]" % ["★".repeat(r), "★".repeat(n - r), "☆".repeat(5 - n)]


static func is_hidden(c: Dictionary) -> bool:
	return float(c.get("hidden_until", 0.0)) > GameState.play_time


static func toughness(c: Dictionary) -> float:
	return float(TOUGHNESS[clampi(int(c.get("stars", 1)), 0, 5)])


## The hull of the captain's own ship.
static func hull_of(c: Dictionary) -> String:
	if c.has("hull"):
		return String(c["hull"])
	return String(GameData.presets[String(c["preset"])]["hull"])


func get_captain(id: String) -> Dictionary:
	for c in captains:
		if c["id"] == id:
			return c
	return {}


func alive_in(sid: int) -> Array:
	var out: Array = []
	for c in captains:
		if c["alive"] and int(c["system"]) == sid and not is_hidden(c):
			out.append(c)
	return out


## Home systems they keep away from: the capitals of the three powers and the pilot's start system.
static func is_home(sid: int) -> bool:
	if sid == Universe.home_system:
		return true
	return bool(Universe.systems[sid].get("capital", false)) and Universe.controller(sid) in FactionData.POWERS


static func lawless(sid: int) -> bool:
	return float(Universe.systems[sid]["security"]) <= LAWLESS


func _random_haunt(lawless_only: bool) -> int:
	var out: Array = []
	for s in Universe.systems:
		var id := int(s["id"])
		if not is_home(id) and (not lawless_only or lawless(id)):
			out.append(id)
	return out[randi() % out.size()] if not out.is_empty() else 0


func _news(text: String, kind: String = "world", sid: int = -1) -> void:
	news.push_front({"t": GameState.play_time, "text": text})
	if news.size() > 30:
		news.pop_back()
	if GameState.news != null:
		GameState.news.add(text, kind, sid)


## Cluster simulation, called by GameState every frame while a game runs.
func update(player_system: int) -> void:
	var now := GameState.play_time
	for c in captains:
		if not c["alive"]:
			if now >= float(c["respawn"]):
				var n := _make(int(c["slot"]), title(c), randi_range(1, 2))
				n["system"] = _random_haunt(true)
				n["next_move"] = now + randf_range(MOVE_MIN, MOVE_MAX)
				captains[captains.find(c)] = n
				_news("New notorious pirate: %s has taken over the crew of %s." % [title(n), String(c["name"])])
			continue
		# the longer it lives, the higher the bounty (small steps) and the more dangerous (stars)
		c["bounty"] = int(c["base_bounty"]) + int((now - float(c["since"])) / BOUNTY_EVERY) * BOUNTY_STEP + int(c.get("bonus", 0))
		if int(c["stars"]) < 5 and now - float(c["star_t"]) >= STAR_TIME:
			c["star_t"] = now
			_set_stars(c, int(c["stars"]) + 1)
			_news("%s grows bolder – now %s with %d escorts." % [title(c), stars_text(c), (c["escorts"] as Array).size()])
		_update_raid(c, now, player_system)
		if now < float(c["next_move"]) or not (c["raid"] as Dictionary).is_empty():
			continue
		if int(c["system"]) == player_system:
			c["next_move"] = now + 30.0
			continue                 # it does not vanish while the pilot is in its system
		var options: Array = []
		for nb in Universe.systems[int(c["system"])]["links"]:
			if not is_home(int(nb)):
				options.append(int(nb))
		if options.is_empty():
			c["next_move"] = now + 60.0
			continue
		# mostly back towards lawless space, now and then a visit to safer systems
		var wild: Array = options.filter(func(x): return lawless(x))
		var to: int = options[randi() % options.size()]
		if not wild.is_empty() and randf() < 0.65:
			to = wild[randi() % wild.size()]
		c["system"] = to
		c["seen"] = now
		c["next_move"] = now + (randf_range(MOVE_MIN, MOVE_MAX) if lawless(to) else randf_range(VISIT_MIN, VISIT_MAX))
		_news("%s was sighted in %s." % [title(c), Universe.systems[to]["name"]])
		_maybe_raid(c, now)


## Raid phases: planned (announced) -> active -> resolved. A live raid (the pilot is in the
## system) is resolved by SystemView; otherwise by chance when the time is up.
func _update_raid(c: Dictionary, now: float, player_system: int) -> void:
	var r: Dictionary = c["raid"]
	if r.is_empty():
		return
	if String(r["state"]) == "planned" and now >= float(r["start"]):
		r["state"] = "active"
		_news("%s's raid on %s has begun!" % [title(c), r["name"]], "alert", int(c["system"]))
		GameState.log_msg("SWX ALERT: the raid on %s in %s has begun – %s is attacking!" % [r["name"], Universe.systems[int(c["system"])]["name"], title(c)], GameState.COL_BAD)
	if String(r["state"]) == "active" and now >= float(r["until"]) and not bool(r.get("live", false)):
		if int(c["system"]) == player_system:
			return               # the pilot is there: SystemView decides
		var st := Universe.find_station(int(c["system"]), String(r["station"]))
		var fall := clampf(0.65 - 0.15 * (int(st.get("tier", 1)) - 1), 0.2, 0.8)
		if randf() < fall:
			raid_won(c)
		else:
			raid_repelled(c, randf() < 0.5)


## 5-star captains sometimes raid a station on arrival (never a military outpost).
func _maybe_raid(c: Dictionary, now: float) -> void:
	if int(c["stars"]) < 5 or randf() > RAID_CHANCE:
		return
	var targets: Array = []
	for st in Universe.get_layout(int(c["system"]))["stations"]:
		if String(st["type"]) != "military":
			targets.append(st)
	if targets.is_empty():
		return
	start_raid(c, targets[randi() % targets.size()], now)


## Plans a raid on station `st` in the captain's system: announced now, starts in 5 minutes.
## `warning` < 0 = the default warning time (tests pass 0 to start at once).
func start_raid(c: Dictionary, st: Dictionary, now: float, warning: float = -1.0) -> void:
	var w := RAID_WARNING if warning < 0.0 else warning
	var dur := randf_range(RAID_MIN, RAID_MAX)
	c["raid"] = {"station": st["id"], "name": st["name"], "state": "planned", "start": now + w, "until": now + w + dur, "live": false}
	c["next_move"] = maxf(float(c["next_move"]), now + w + dur + 60.0)
	var sys: String = Universe.systems[int(c["system"])]["name"]
	var when := ("in %d minutes" % int(round(w / 60.0))) if w >= 60.0 else "now"
	GameState.codex.event("raid")
	_news("RAID ALERT: %s is preparing to raid %s in %s – the attack begins %s!" % [title(c), st["name"], sys, when], "alert", int(c["system"]))
	GameState.log_msg("SWX ALERT: %s (%s) is gathering for a raid on %s in %s – the attack begins %s!" % [title(c), stars_text(c), st["name"], sys, when], GameState.COL_BAD)


## The station fell: bounty +100,000 cr, one star turns red, the station goes offline.
func raid_won(c: Dictionary) -> void:
	var r: Dictionary = c["raid"]
	var st := Universe.find_station(int(c["system"]), String(r.get("station", "")))
	c["bonus"] = int(c.get("bonus", 0)) + RAID_PRIZE
	c["red"] = mini(int(c.get("red", 0)) + 1, int(c["stars"]))
	c["bounty"] = int(c["bounty"]) + RAID_PRIZE
	c["raid"] = {}
	if not st.is_empty():
		GameState.stations.knock_out(st, int(c["system"]))
	_news("%s overran %s in %s – the station is offline." % [title(c), r.get("name", "a station"), Universe.systems[int(c["system"])]["name"]], "alert", int(c["system"]))
	GameState.log_msg("SWX ALERT: %s has overrun %s in %s! Its bounty rises by %s." % [title(c), r.get("name", "a station"), Universe.systems[int(c["system"])]["name"], GameData.fmt_credits(RAID_PRIZE)], GameState.COL_BAD)


## The station held. `fled`: the captain was about to lose and hides for a while.
func raid_repelled(c: Dictionary, fled: bool) -> void:
	var r: Dictionary = c["raid"]
	c["raid"] = {}
	var where: String = Universe.systems[int(c["system"])]["name"]
	if fled:
		c["hidden_until"] = GameState.play_time + HIDE_TIME
		c["system"] = _random_haunt(true)
		c["next_move"] = GameState.play_time + HIDE_TIME + randf_range(MOVE_MIN, MOVE_MAX)
		_news("%s was driven off from %s in %s and has gone into hiding." % [title(c), r.get("name", "a station"), where], "alert")
	else:
		_news("%s gave up the raid on %s in %s – the station held." % [title(c), r.get("name", "a station"), where], "alert")
		c["next_move"] = GameState.play_time + 60.0


## The captain was destroyed (by the pilot or anyone else).
func on_killed(id: String, by_player: bool) -> void:
	var c := get_captain(id)
	if c.is_empty() or not c["alive"]:
		return
	c["alive"] = false
	if by_player:
		GameState.collect_notorious(c)              # package 34: the collection
	if not (c["raid"] as Dictionary).is_empty():
		_news("The raid on %s ended with the death of %s." % [c["raid"].get("name", "a station"), title(c)])
	c["raid"] = {}
	c["respawn"] = GameState.play_time + randf_range(SUCCESSOR_MIN, SUCCESSOR_MAX)
	_news("%s was destroyed in %s%s." % [title(c), Universe.systems[int(c["system"])]["name"], " by %s" % GameState.pilot_name if by_player else ""])


## Debug / tests: brings the first living captain to system `sid`.
func summon(sid: int) -> Dictionary:
	for c in captains:
		if c["alive"]:
			c["system"] = sid
			c["hidden_until"] = 0.0
			c["seen"] = GameState.play_time
			c["next_move"] = GameState.play_time + MOVE_MAX
			return c
	return {}
