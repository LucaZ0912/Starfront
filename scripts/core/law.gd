extends RefCounted
## Law and wanted status per faction (phase 0.5 package 13) – a light first step towards the
## later crime system.
##
## Crimes are recorded with the AUTHORITY of the place: the power that controls the system (in
## contested systems the power whose ship or station was the victim, otherwise the first
## claimant). Pirate space has no law. Each crime adds points; points fade by one every
## DECAY_TIME seconds without a new crime, or are cleared by paying the fine at a Bond Office
## (Sable Writ Exchange) of that faction.
##
##   points 0     Clean
##          1–2   Suspect      its patrols attack you on sight (also inside no-fire zones)
##          3–5   Wanted       + no contracts at its stations
##          6+    Most Wanted  + its stations refuse docking
##
## Owned by GameState (GameState.law); preloaded, not a class_name.

const FactionData = preload("res://data/factions.gd")

const LEVELS := [
	{"id": "clean", "name": "Clean", "min": 0, "color": Color(0.6, 0.9, 0.65)},
	{"id": "suspect", "name": "Suspect", "min": 1, "color": Color(1.0, 0.8, 0.35)},
	{"id": "wanted", "name": "Wanted", "min": 3, "color": Color(1.0, 0.5, 0.3)},
	{"id": "most_wanted", "name": "Most Wanted", "min": 6, "color": Color(1.0, 0.25, 0.25)},
]
## Points per crime (tuned in package 8).
const CRIMES := {
	"zone_fire": 1,          # opening fire inside a no-fire zone
	"attack_civilian": 1,    # first shot at a civilian that was no threat
	"attack_patrol": 2,
	"kill_civilian": 2,
	"kill_patrol": 3,
	"interdict": 1,          # pulling a lawful ship out of warp
}
const DECAY_TIME := 300.0    # one point fades every 5 minutes without a new crime
const FINE_PER_POINT := 2000
const MAX_POINTS := 12

var records := {}            # faction id -> {points, last (play time of the last crime / decay step)}


func reset() -> void:
	records.clear()


func to_dict() -> Dictionary:
	return records.duplicate(true)


func from_dict(d: Dictionary) -> void:
	records.clear()
	for f in d:
		if f in FactionData.POWERS:
			records[f] = {"points": int(d[f].get("points", 0)), "last": float(d[f].get("last", 0.0))}


## Which power's law applies in system `sid` ("" = lawless). `victim_gov`: faction of the
## ship or station that was wronged – decides in contested systems.
static func authority(sid: int, victim_gov: String = "") -> String:
	var c := Universe.controller(sid)
	if c in FactionData.POWERS:
		return c
	if c != "":
		return ""                # pirate space: no law
	var cl: Array = Universe.claimants(sid)
	if victim_gov in FactionData.POWERS and victim_gov in cl:
		return victim_gov
	for f in cl:
		if f in FactionData.POWERS:
			return f
	return ""


# ---------------------------------------------------------------- Queries

func points(f: String) -> int:
	_decay(f)
	return int(records.get(f, {}).get("points", 0))


func level(f: String) -> int:
	var p := points(f)
	var lv := 0
	for i in LEVELS.size():
		if p >= int(LEVELS[i]["min"]):
			lv = i
	return lv


func level_info(f: String) -> Dictionary:
	return LEVELS[level(f)]


func level_name(f: String) -> String:
	return String(level_info(f)["name"])


func is_wanted_anywhere() -> bool:
	for f in records.keys():
		if points(f) > 0:
			return true
	return false


func fine(f: String) -> int:
	return points(f) * FINE_PER_POINT


## Seconds until the next point fades (0 = clean).
func decay_left(f: String) -> float:
	if points(f) <= 0:
		return 0.0
	return maxf(0.0, float(records[f]["last"]) + DECAY_TIME - GameState.play_time)


## Patrols of this faction treat you as a criminal.
func hunted_by(f: String) -> bool:
	return f != "" and level(f) >= 1


func contracts_error(f: String) -> String:
	if f != "" and level(f) >= 2:
		return "BlackLedger posts no contracts for you here – you are %s by the %s." % [level_name(f).to_lower(), FactionData.name_of(f)]
	return ""


func dock_error(st: Dictionary) -> String:
	var f := String(st.get("faction", ""))
	if f != "" and String(st.get("type", "")) != "pirate_haven" and level(f) >= 3:
		return "%s refuses docking – you are MOST WANTED by the %s. Let it cool down (−1 every %d min) or pay your fine elsewhere." % [st.get("name", "The station"), FactionData.name_of(f), int(DECAY_TIME / 60.0)]
	return ""


func _decay(f: String) -> void:
	if not records.has(f):
		return
	var r: Dictionary = records[f]
	var now := GameState.play_time
	while int(r["points"]) > 0 and now - float(r["last"]) >= DECAY_TIME:
		r["points"] = int(r["points"]) - 1
		r["last"] = float(r["last"]) + DECAY_TIME
	if int(r["points"]) <= 0:
		records.erase(f)


# ---------------------------------------------------------------- Changes

## Records a crime with faction `f` (only the three powers keep records).
func offence(f: String, crime: String, what: String = "") -> void:
	if not f in FactionData.POWERS or not CRIMES.has(crime):
		return
	var lv0 := level(f)
	var r: Dictionary = records.get(f, {"points": 0, "last": 0.0})
	r["points"] = mini(int(r["points"]) + int(CRIMES[crime]), MAX_POINTS)
	r["last"] = GameState.play_time
	records[f] = r
	var lv1 := level(f)
	GameState.log_msg("%s: crime recorded – %s. Status: %s (%d)." % [FactionData.name_of(f), what if what != "" else crime.replace("_", " "), level_name(f), points(f)], GameState.COL_BAD)
	if lv1 > lv0:
		GameState.log_msg(_level_message(f), GameState.COL_BAD)
	GameState.wanted_changed.emit(f, lv1)


## Pays the fine with faction `f` (caller checks where). Returns the amount paid, -1 = not enough credits.
func pay_fine(f: String) -> int:
	var amount := fine(f)
	if amount <= 0:
		return 0
	if not GameState.spend(amount):
		return -1
	records.erase(f)
	GameState.log_msg("Sable Writ Exchange: fine of %s paid – your record with the %s is clean." % [GameData.fmt_credits(amount), FactionData.name_of(f)], GameState.COL_GOOD)
	GameState.wanted_changed.emit(f, 0)
	return amount


func _level_message(f: String) -> String:
	var n := FactionData.name_of(f)
	match String(level_info(f)["id"]):
		"suspect":
			return "You are now a SUSPECT in %s space – its patrols will attack you." % n
		"wanted":
			return "You are now WANTED by the %s – no contracts at its stations." % n
		"most_wanted":
			return "You are now MOST WANTED by the %s – its stations refuse you." % n
	return ""
