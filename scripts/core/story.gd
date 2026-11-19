extends RefCounted
## Package 55 (Luz): the story's state and its running – which missions are under way and at which step, the goals
## met, the story flags, the mission tracked, the tips seen, the secrets found, what was said (the journal). The
## game reports what happens (event: docked, jumped, locked, near, talked, a flag set); a step whose goals are all
## met is done, its actions run, the next step starts. What is to be shown (a dialogue, a radio call, a tip) goes out
## as `show` – StoryUI shows it. Kept in the save (GameState.story). No class_name: preload it.

signal show(kind: String, data: Dictionary)
signal changed

const Data = preload("res://data/story.gd")
const PilotArt = preload("res://scripts/core/pilot_art.gd")

var missions := {}            # mission id -> {step, goals: {goal id: true}, log: [{who, text, radio}], target, started}
var done: Array = []          # missions finished
var flags := {}               # story flags (dialogue answers, events)
var tracked := ""             # the mission whose goals show over the ship's panel
var tips_seen: Array = []
var tips_off := false
var secrets: Array = []
var done_log := {}            # package 56 (Luz): what was said in a finished mission – the journal's Completed tab


func reset() -> void:
	missions = {}
	done = []
	flags = {}
	tracked = ""
	tips_seen = []
	tips_off = false
	secrets = []
	done_log = {}
	changed.emit()


func to_dict() -> Dictionary:
	return {"missions": missions.duplicate(true), "done": done.duplicate(), "flags": flags.duplicate(true), "tracked": tracked,
		"tips_seen": tips_seen.duplicate(), "tips_off": tips_off, "secrets": secrets.duplicate(),
		"done_log": done_log.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	missions = (d.get("missions", {}) as Dictionary).duplicate(true)
	done = (d.get("done", []) as Array).duplicate()
	flags = (d.get("flags", {}) as Dictionary).duplicate(true)
	tracked = String(d.get("tracked", ""))
	tips_seen = (d.get("tips_seen", []) as Array).duplicate()
	tips_off = bool(d.get("tips_off", false))
	secrets = (d.get("secrets", []) as Array).duplicate()
	done_log = (d.get("done_log", {}) as Dictionary).duplicate(true)
	changed.emit()


# ---------------------------------------------------------------- missions and steps

static func mission_data(mid: String) -> Dictionary:
	return Data.MISSIONS.get(mid, {})


func running(mid: String) -> bool:
	return missions.has(mid)


func step_index(mid: String) -> int:
	return int((missions.get(mid, {}) as Dictionary).get("step", -1))


func step_data(mid: String) -> Dictionary:
	var steps: Array = mission_data(mid).get("steps", [])
	var i := step_index(mid)
	return steps[i] if i >= 0 and i < steps.size() else {}


## A mission one before it leads to (deferred): only if it has not been started meanwhile (package 58: else the
## started one would begin again from its first step).
func _start_next(mid: String) -> void:
	if not running(mid) and not done.has(mid):
		start(mid)


## Starts a mission at its first step (or `at`); tracked if nothing else is.
func start(mid: String, at: int = 0) -> String:
	var md := mission_data(mid)
	if md.is_empty():
		return "No such mission."
	done.erase(mid)
	missions[mid] = {"step": -1, "goals": {}, "log": [], "target": "", "started": GameState.play_time}
	if tracked == "" or not missions.has(tracked):
		tracked = mid
	_enter(mid, clampi(at, 0, (md["steps"] as Array).size() - 1))
	return ""


func _enter(mid: String, i: int) -> void:
	var m: Dictionary = missions[mid]
	m["step"] = i
	m["goals"] = {}
	var st: Dictionary = (mission_data(mid)["steps"] as Array)[i]
	GameState.log_msg("Story: %s, %s" % [String(mission_data(mid)["title"]), String(st["title"])], Color(1.0, 0.82, 0.35))
	_run(mid, st.get("on_start", []))
	changed.emit()
	# a goal met already (a flag set before, standing at the target)
	for g in st.get("goals", []):
		if String(g["kind"]) == "flag" and flags.has(String(g["flag"])):
			_meet(mid, String(g["id"]))


func _run(mid: String, actions: Array) -> void:
	for a in actions:
		match String(a.get("do", "")):
			"dialogue":
				show.emit("dialogue", {"id": String(a["id"]), "mission": mid})
			"radio":
				var who := String(a.get("who", ""))
				_say(mid, who, String(a["text"]), true)
				# Luz, 18 Nov 2026: a call can stay until something is done – a flag ("until_flag") or this step ("until_step")
				show.emit("radio", {"who": who, "text": String(a["text"]), "mission": mid, "until_flag": String(a.get("until_flag", "")),
					"until_step": bool(a.get("until_step", false)), "step": step_index(mid), "hint": String(a.get("hint", ""))})
			"tip":
				tip(String(a["id"]))
			"flag":
				set_flag(String(a["name"]), a.get("value", true))
			"credits":
				GameState.credits += int(a["n"])
				GameState.credits_changed.emit(GameState.credits)
				GameState.log_msg("+%d cr" % int(a["n"]), GameState.COL_GOOD)
			"secret":
				find_secret(String(a["id"]))
			"target":
				missions[mid]["target"] = _pick_target(String(a.get("what", "")))
			"start":
				if not running(String(a["id"])) and not done.has(String(a["id"])):
					_start_next.call_deferred(String(a["id"]))    # package 56: one mission leads to the next


## The object a step points at (for the goals "@target" and the marker).
func _pick_target(what: String) -> String:
	if what == "nearest_station" or what == "next_station":
		var main = Engine.get_main_loop().current_scene if Engine.get_main_loop() != null else null
		var v = main.view if main != null and "view" in main else null
		if v != null and v.player != null and is_instance_valid(v.player):
			var best := ""
			var bd := INF
			for sid in v.stations:
				var st = v.stations[sid]
				if is_instance_valid(st):
					var d: float = st.position.distance_to(v.player.position)
					if what == "next_station" and d < 10000.0:
						continue                              # not the one you are at – the next one
					if d < bd:
						bd = d
						best = String(sid)
			if best == "" and what == "next_station":
				return _pick_target("nearest_station")
			return best
	return what


## The concrete target of a goal ("@target": the step's).
func goal_target(mid: String, g: Dictionary) -> String:
	var t := String(g.get("target", ""))
	if t == "@target":
		return String((missions.get(mid, {}) as Dictionary).get("target", ""))
	return t


func _say(mid: String, who: String, text: String, radio: bool) -> void:
	if not missions.has(mid):
		return
	(missions[mid]["log"] as Array).append({"who": who, "text": text, "radio": radio})


func _meet(mid: String, gid: String) -> void:
	if not missions.has(mid):
		return
	var m: Dictionary = missions[mid]
	if bool((m["goals"] as Dictionary).get(gid, false)):
		return
	m["goals"][gid] = true
	var st := step_data(mid)
	var all := true
	for g in st.get("goals", []):
		all = all and bool(m["goals"].get(String(g["id"]), false))
	changed.emit()
	if all:
		_next(mid)


func _next(mid: String) -> void:
	var st := step_data(mid)
	_run(mid, st.get("on_done", []))
	var steps: Array = mission_data(mid)["steps"]
	var i := step_index(mid) + 1
	if i >= steps.size():
		complete(mid)
		return
	_enter(mid, i)


## Package 56: a running mission on to step i (the steps between skipped).
func goto_step(mid: String, i: int) -> void:
	if missions.has(mid):
		_enter(mid, clampi(i, 0, (mission_data(mid)["steps"] as Array).size() - 1))


## A mission finished (its last step done – or the story moved past it): what was said is kept for the journal.
func complete(mid: String) -> void:
	if missions.has(mid):
		done_log[mid] = (missions[mid].get("log", []) as Array).duplicate(true)
		missions.erase(mid)
		if not done.has(mid):
			done.append(mid)
		GameState.log_msg("Story: %s, done." % String(mission_data(mid)["title"]), GameState.COL_GOOD)
		if tracked == mid:
			tracked = String(missions.keys()[0]) if not missions.is_empty() else ""
		changed.emit()


## Something happened in the game – the goals waiting for it are met.
func event(kind: String, d: Dictionary = {}) -> void:
	for mid in missions.keys():
		var st := step_data(mid)
		for g in st.get("goals", []):
			if String(g["kind"]) != kind:
				continue
			var ok := false
			match kind:
				"dock", "lock":
					var t := goal_target(mid, g)
					ok = t == "" or t == String(d.get("id", ""))
				"jump":
					ok = int(g.get("system", -1)) < 0 or int(g["system"]) == int(d.get("system", -2))
				"talk":
					ok = String(g.get("dialogue", "")) == String(d.get("id", ""))
				"flag":
					ok = String(g.get("flag", "")) == String(d.get("name", ""))
				"near":
					ok = goal_target(mid, g) == String(d.get("id", "")) and float(d.get("km", INF)) <= float(g.get("km", 50.0))
			if ok:
				_meet(mid, String(g["id"]))


## The "near" goals waiting now: [mission, goal, target id] – StoryUI measures them each second.
func near_goals() -> Array:
	var out: Array = []
	for mid in missions:
		var st := step_data(mid)
		for g in st.get("goals", []):
			if String(g["kind"]) == "near" and not bool(missions[mid]["goals"].get(String(g["id"]), false)):
				out.append([mid, g, goal_target(mid, g)])
	return out


func set_flag(name: String, value = true) -> void:
	flags[name] = value
	event("flag", {"name": name})
	changed.emit()


## A dialogue finished (its answers' flags already set) – recorded in the journal.
func dialogue_done(mid: String, id: String, said: Array) -> void:
	for s in said:
		_say(mid, String(s[0]), String(s[1]), false)
	event("talk", {"id": id})
	changed.emit()


func tip(id: String) -> void:
	if not Data.TIPS.has(id):
		return
	var first := not tips_seen.has(id)
	if first:
		tips_seen.append(id)
	if first and not tips_off:
		show.emit("tip", {"id": id})
	changed.emit()


func find_secret(id: String) -> void:
	if Data.SECRETS.has(id) and not secrets.has(id):
		secrets.append(id)
		GameState.log_msg("Secret found: %s" % String(Data.SECRETS[id]["title"]), Color(0.8, 0.5, 1.0))
		changed.emit()


func track(mid: String) -> void:
	tracked = mid if missions.has(mid) else ""
	changed.emit()


## A text with {key:action} replaced by the key (or the controller's button) bound to it.
static func keys(text: String) -> String:
	var out := text
	# package 56 (Luz): how to fly, zoom and change the view – said for the keys or the controller, whichever is in use
	var pad: bool = Pad.enabled and Pad.using_pad
	if out.contains("{move}"):
		out = out.replace("{move}", "the left stick" if pad else "%s %s %s %s" % [Keybinds.key_text("ship_up"), Keybinds.key_text("ship_left"),
			Keybinds.key_text("ship_down"), Keybinds.key_text("ship_right")])
	if out.contains("{zoom}"):
		out = out.replace("{zoom}", ("%s / %s on the d-pad" % [Keybinds.key_text("pad_zoom_in"), Keybinds.key_text("pad_zoom_out")]) if pad else "the mouse wheel")
	if out.contains("{journal}"):
		out = out.replace("{journal}", ("hold %s for the window wheel and pick Journal" % Pad.glyph("options")) if pad else "press %s" % Keybinds.key_text("journal"))
	if out.contains("{views}"):
		out = out.replace("{views}", "Each press of %s or %s is one view further." % [Keybinds.key_text("pad_zoom_in"), Keybinds.key_text("pad_zoom_out")] if pad
			else "Straight to one: %s Combat, %s Recon, %s Orbit, %s System." % [Keybinds.key_text("zoom_combat"), Keybinds.key_text("zoom_recon"),
				Keybinds.key_text("zoom_orbit"), Keybinds.key_text("zoom_system")])
	var i := out.find("{key:")
	while i >= 0:
		var j := out.find("}", i)
		if j < 0:
			break
		var act := out.substr(i + 5, j - i - 5)
		out = out.substr(0, i) + Keybinds.key_text(act) + out.substr(j + 1)
		i = out.find("{key:")
	return out


## The goals of the step now, each [label, met].
func goal_lines(mid: String) -> Array:
	var out: Array = []
	var m: Dictionary = missions.get(mid, {})
	for g in step_data(mid).get("goals", []):
		out.append([String(g.get("label", g["kind"])), bool((m.get("goals", {}) as Dictionary).get(String(g["id"]), false))])
	return out


## A character's portrait: a pilot's face, or a hologram for a ship's computer (package 56).
static func portrait_of(who: String) -> Texture2D:
	var c: Dictionary = Data.CHARACTERS.get(who, {})
	if c.get("holo", false):
		return load("res://scripts/core/holo_art.gd").portrait(c.get("col", Color(0.4, 0.9, 1.0)))
	return PilotArt.portrait(look_of(who))


## The look of a character's portrait.
static func look_of(who: String) -> Dictionary:
	var c: Dictionary = Data.CHARACTERS.get(who, {})
	var rng := RandomNumberGenerator.new()
	rng.seed = int(c.get("seed", hash(who)))
	var l: Dictionary = PilotArt.random_look(rng)
	for k in (c.get("look", {}) as Dictionary):
		l[k] = c["look"][k]
	return l
