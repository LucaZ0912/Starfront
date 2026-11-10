extends Node
## Save games and settings.
##
## A save is a text file in user://saves/<slot>.sav written with var_to_str (Godot's own
## text format – readable, keeps Vector2 and int/float types intact). It holds:
##   version, meta (for the load list), game (GameState.to_dict) and world (Universe.to_dict).
## The galaxy is regenerated from its seed; only changes are stored.
##
## Scene flow: the main menu sets `pending` and switches to the game scene; main.gd then
## calls start_pending() to create a new game or load a slot.

const SAVE_DIR := "user://saves/"
const SETTINGS_PATH := "user://settings.cfg"
const VERSION := 2               # 2: module system of package 19 – older saves cannot be loaded
const AUTOSAVE := "autosave"
const QUICKSAVE := "quicksave"

const MENU_SCENE := "res://scenes/menu.tscn"
const GAME_SCENE := "res://scenes/main.tscn"

var pending: Dictionary = {}     # {"mode": "new", "pilot", "seed"} or {"mode": "load", "slot"}
var settings := {"fullscreen": false, "volume": 0.8, "autosave": true, "map_territory": true, "map_traffic": true,
	"vol_music": 0.6, "vol_ambience": 0.7, "vol_sfx": 0.8,           # package 28a: volume per channel
	"show_fps": true}                                                # 0.6.35.15: frames per second in the top bar


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	load_settings()


# ---------------------------------------------------------------- Saving

func slot_path(slot: String) -> String:
	return SAVE_DIR + slot + ".sav"


## Turns any text into a safe file name.
static func slot_name(text: String) -> String:
	var out := ""
	for ch in text.strip_edges().to_lower():
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			out += ch
		elif out != "" and not out.ends_with("_"):
			out += "_"
	out = out.trim_suffix("_")
	return out if out != "" else "save"


func save_game(slot: String, label: String = "") -> String:
	if not GameState.running:
		return "No game running."
	if Universe.test_mode:
		return "Saving is disabled in the test system."
	var f := GameState.active()
	if f != null and f.in_transit():
		return "Cannot save during a hyperspace jump."
	var main := get_tree().current_scene
	if main != null and main.has_method("prepare_save"):
		main.prepare_save()
	var data := {
		"version": VERSION,
		"meta": {
			"label": label if label != "" else slot.capitalize(),
			"pilot": GameState.pilot_name, "credits": GameState.credits,
			"ship": f.ship_name if f != null else "–",
			"location": f.location_text() if f != null else "–",
			"play_time": GameState.play_time,
			"saved_at": Time.get_datetime_string_from_system(false, true),
			"unix": Time.get_unix_time_from_system(),
		},
		"game": GameState.to_dict(),
		"world": Universe.to_dict(),
	}
	var file := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if file == null:
		return "Could not write save (%s)." % error_string(FileAccess.get_open_error())
	file.store_string(var_to_str(data))
	file.close()
	return ""


func read_save(slot: String) -> Dictionary:
	if not FileAccess.file_exists(slot_path(slot)):
		return {}
	var text := FileAccess.get_file_as_string(slot_path(slot))
	var v = str_to_var(text)
	if not (v is Dictionary) or not v.has("game"):
		return {}
	return _migrate(v)


## Upgrades old save formats (nothing to do yet – version 1 is the first).
func _migrate(data: Dictionary) -> Dictionary:
	return data


## Applies a save to the autoloads. The caller (main.gd) then builds the view.
func apply_save(slot: String) -> String:
	var data := read_save(slot)
	if data.is_empty():
		return "Save '%s' not found or damaged." % slot
	if int(data.get("version", 1)) < VERSION:
		# alpha rule: no migrations that would hold back reworks (see Roadmap → Arbeitsweise)
		return "'%s' was saved by an older alpha (before the module rework) and can no longer be loaded – please start a new game." % slot
	if int(data["world"].get("version", 1)) < Universe.GALAXY_VERSION:
		# made with an older (smaller) star cluster: build the current one and move the pilot there
		Universe.generate(int(data["world"]["seed"]))
		GameState.from_dict(data["game"])
		GameState.migrate_to_current_cluster(int(data["world"].get("version", 1)))
		return ""
	Universe.from_dict(data["world"])
	GameState.from_dict(data["game"])
	return ""


## All saves, newest first: [{slot, meta}]
func list_saves() -> Array:
	var out: Array = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return out
	for fn in dir.get_files():
		if not fn.ends_with(".sav"):
			continue
		var slot := fn.trim_suffix(".sav")
		var data := read_save(slot)
		if data.is_empty():
			continue
		out.append({"slot": slot, "meta": data["meta"], "old": int(data.get("version", 1)) < VERSION})
	out.sort_custom(func(a, b): return float(a["meta"]["unix"]) > float(b["meta"]["unix"]))
	return out


func latest_slot() -> String:
	for e in list_saves():
		if not e.get("old", false):
			return String(e["slot"])
	return ""                        # saves of an older alpha cannot be continued


func delete_save(slot: String) -> void:
	DirAccess.remove_absolute(slot_path(slot))


func autosave() -> void:
	if GameState.running and bool(settings["autosave"]) and not Universe.test_mode:
		if save_game(AUTOSAVE, "Autosave") == "":
			GameState.log_msg("Autosaved.", Color(0.6, 0.7, 0.8))


# ---------------------------------------------------------------- Scene flow

func start_new(pilot: String, seed_v: int, pilot_data: Dictionary = {}) -> void:
	pending = {"mode": "new", "pilot": pilot, "seed": seed_v, "pilot_data": pilot_data}
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE)


## Debug builds only: the test system with every station, planet and asteroid type.
func start_test() -> void:
	pending = {"mode": "test"}
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE)


func start_load(slot: String) -> void:
	pending = {"mode": "load", "slot": slot}
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE)


## Called by main.gd: sets up the game state for the pending action.
func start_pending() -> void:
	var p := pending
	pending = {}
	Engine.time_scale = 1.0
	Commands.god_mode = false
	Commands.suit_god = false
	var err := ""
	if p.get("mode", "") == "load":
		err = apply_save(String(p["slot"]))
	if p.get("mode", "") == "test":
		GameState.new_game("Tester", -1, true)
	elif p.get("mode", "") != "load" or err != "":
		GameState.new_game(String(p.get("pilot", "Lefty")), int(p.get("seed", -1)), false, p.get("pilot_data", {}))
	GameState.running = true
	if err != "":
		GameState.log_msg(err, GameState.COL_BAD)


func to_menu() -> void:
	GameState.running = false
	Engine.time_scale = 1.0
	Commands.god_mode = false
	Commands.suit_god = false
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)


# ---------------------------------------------------------------- Settings

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		for k in settings:
			settings[k] = cfg.get_value("settings", k, settings[k])
	apply_settings()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for k in settings:
		cfg.set_value("settings", k, settings[k])
	cfg.save(SETTINGS_PATH)
	apply_settings()


func apply_settings() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(float(settings["volume"]), 0.0001)))
	# package 28a: the channels (created here if the audio framework has not started yet)
	preload("res://scripts/autoload/audio.gd").ensure_buses()
	for spec in [["Music", "vol_music"], ["Ambience", "vol_ambience"], ["SFX", "vol_sfx"]]:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(spec[0]), linear_to_db(maxf(float(settings[spec[1]]), 0.0001)))


static func fmt_time(sec: float) -> String:
	var s := int(sec)
	return "%dh %02dm" % [s / 3600, (s / 60) % 60]
