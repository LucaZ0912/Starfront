extends RefCounted
## Codex state (phase 0.5 package 18): which entries the pilot has unlocked, which are unread.
## Entries come from data/codex.gd. Unlocks are saved with the pilot and also collected across all
## games in user://codex.cfg, so the main menu can show everything discovered so far.
## Owned by GameState (GameState.codex).

const CodexData = preload("res://data/codex.gd")
const GLOBAL_PATH := "user://codex.cfg"

var all := {}                  # id -> entry (static data)
var unlocked := {}             # id -> play time of the unlock
var unread := {}               # id -> true
var persist := true            # write the cross-game file (the smoke test turns this off)


func _init() -> void:
	all = CodexData.entries()
	reset()


func reset() -> void:
	unlocked.clear()
	unread.clear()
	for id in all:
		if all[id]["unlock"] == "start":
			unlocked[id] = 0.0


func to_dict() -> Dictionary:
	return {"unlocked": unlocked.duplicate(), "unread": unread.duplicate()}


func from_dict(d: Dictionary) -> void:
	reset()
	for id in d.get("unlocked", {}):
		if all.has(id):
			unlocked[id] = float(d["unlocked"][id])
	for id in d.get("unread", {}):
		if all.has(id):
			unread[id] = true


func is_unlocked(id: String) -> bool:
	return unlocked.has(id)


## Something was discovered: unlocks every entry waiting for this event. Returns the new ids.
func event(ev: String) -> Array:
	var got: Array = []
	for id in all:
		if String(all[id]["unlock"]) == ev and not unlocked.has(id):
			got.append(id)
	got.sort()
	for id in got:
		unlock(id)
	return got


func unlock(id: String) -> void:
	if not all.has(id) or unlocked.has(id):
		return
	unlocked[id] = GameState.play_time
	unread[id] = true
	_save_global(id)
	GameState.codex_unlocked.emit(id)


func mark_read(id: String) -> void:
	unread.erase(id)


## Entry ids of a category, sorted by title.
func ids_in(cat: String) -> Array:
	var out: Array = []
	for id in all:
		if all[id]["cat"] == cat:
			out.append(id)
	out.sort_custom(func(a, b): return String(all[a]["title"]) < String(all[b]["title"]))
	return out


# ---------------------------------------------------------------- Across all games (main menu)

func _save_global(id: String) -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	cfg.load(GLOBAL_PATH)
	cfg.set_value("unlocked", id, true)
	cfg.save(GLOBAL_PATH)


## Everything ever discovered in any game (plus the start entries).
static func load_global() -> Dictionary:
	var out := {}
	var cfg := ConfigFile.new()
	if cfg.load(GLOBAL_PATH) == OK and cfg.has_section("unlocked"):
		for id in cfg.get_section_keys("unlocked"):
			out[id] = 0.0
	var data := CodexData.entries()
	for id in data:
		if data[id]["unlock"] == "start":
			out[id] = 0.0
	return out
