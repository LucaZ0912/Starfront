extends Node
## Package 28a – the audio framework. Game events play sounds by id (assets/sfx/<id>.wav, later .ogg as well);
## the ids, events and the planned sound of each are listed in docs/audio/sound_list.md. The placeholders come
## from tools/audio/make_placeholders.py – a real sound with the same name replaces one without touching code.
##
## Channels (audio buses, volumes in the settings): Master → Music, Ambience, SFX; UI sounds run through SFX.
##   Audio.play(id, event)              – a one-shot sound (interface, the pilot's own ship)
##   Audio.play_at(id, world_pos, event) – a sound out in space: quieter the further from the camera
##   Audio.loop(key, id, on, vol, pitch) – a looping sound held by a key (engine, beam, mining, alarm …)
## Every sound played is written to a short event log (debug menu → Audio).

const BUSES := ["Music", "Ambience", "SFX", "UI"]
const BUS_OF := {"amb_": "Ambience", "mus_": "Music", "ui_": "UI", "buy": "UI", "sell": "UI", "notify": "UI", "warn": "UI",
	"mission_": "UI"}
const LOOPS := ["engine_loop", "w_beam_loop", "mining_loop", "alarm_hull", "amb_space"]
const HEAR_RANGE := 9000.0        # km: sounds further from the camera are not heard
const VOICES := 24                # one-shot players in the pool
const SAME_ID_GAP := 0.045        # seconds: the same sound does not start again faster than this
const MAX_SAME := 4               # at most this many of one sound at once

var _streams := {}
var _pool: Array = []
var _loops := {}                  # key -> AudioStreamPlayer
var _last_start := {}             # id -> time
var events: Array = []            # [{t, event, id, bus}] newest last (debug)
var played := 0                   # sounds started since the game began (smoke test)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_buses()
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)


## Creates the channels under Master once (also called from the settings, which may load first).
static func ensure_buses() -> void:
	for b in BUSES:
		if AudioServer.get_bus_index(b) < 0:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, b)
			AudioServer.set_bus_send(idx, "SFX" if b == "UI" else "Master")


## Every sound id there is a file for.
func ids() -> Array:
	var out: Array = []
	var d := DirAccess.open("res://assets/sfx")
	if d == null:
		return out
	for f in d.get_files():
		var base := f.get_basename()
		if f.ends_with(".import") or base in out:
			continue
		if f.get_extension() in ["wav", "ogg"]:
			out.append(base)
	out.sort()
	return out


func stream(id: String) -> AudioStream:
	if _streams.has(id):
		return _streams[id]
	var s: AudioStream = null
	for ext in ["ogg", "wav"]:
		var path := "res://assets/sfx/%s.%s" % [id, ext]
		if ResourceLoader.exists(path):
			s = load(path)
			break
	if s != null and id in LOOPS:
		s = s.duplicate()
		if s is AudioStreamWAV:
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_begin = 0
			s.loop_end = int(s.get_length() * float(s.mix_rate))
		elif s is AudioStreamOggVorbis:
			s.loop = true
	_streams[id] = s
	return s


func bus_of(id: String) -> String:
	for k in BUS_OF:
		if id.begins_with(k):
			return BUS_OF[k]
	return "SFX"


## A sound of the interface or the pilot's own ship (no distance).
func play(id: String, event: String = "", vol_db: float = 0.0, pitch_spread: float = 0.04) -> void:
	_start(id, event, vol_db, pitch_spread)


## A sound out in space: fades with the distance to the camera, silent beyond HEAR_RANGE.
func play_at(id: String, pos: Vector2, event: String = "", vol_db: float = 0.0) -> void:
	var lis := listener()
	if lis == Vector2.INF:
		return
	var d := pos.distance_to(lis)
	if d > HEAR_RANGE:
		return
	var k := 1.0 - d / HEAR_RANGE
	_start(id, event, vol_db + linear_to_db(maxf(k * k, 0.02)), 0.06)


## Where the player hears from: the camera of the system view, else the pilot's ship; INF = nowhere (menus).
func listener() -> Vector2:
	var w = Commands.world
	if w == null or not is_instance_valid(w):
		return Vector2.INF
	if "camera" in w and w.camera != null and is_instance_valid(w.camera):
		return w.camera.global_position
	if w.player != null and is_instance_valid(w.player):
		return w.player.position
	return Vector2.INF


func _start(id: String, event: String, vol_db: float, pitch_spread: float) -> void:
	var s := stream(id)
	if s == null:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_start.get(id, -10.0)) < SAME_ID_GAP:
		return
	# a free voice; with MAX_SAME of this sound already playing (or every voice busy) the oldest one is taken over
	var same: Array = []
	var voice: AudioStreamPlayer = null
	var oldest: AudioStreamPlayer = null
	for p in _pool:
		if p.playing:
			if p.get_meta("id", "") == id:
				same.append(p)
			if oldest == null or float(p.get_meta("t", 0.0)) < float(oldest.get_meta("t", 0.0)):
				oldest = p
		elif voice == null:
			voice = p
	if same.size() >= MAX_SAME:
		voice = same[0]
		for q in same:
			if float(q.get_meta("t", 0.0)) < float(voice.get_meta("t", 0.0)):
				voice = q
	elif voice == null:
		voice = oldest
	_last_start[id] = now
	voice.stream = s
	voice.bus = bus_of(id)
	voice.volume_db = vol_db
	voice.pitch_scale = 1.0 + randf_range(-pitch_spread, pitch_spread)
	voice.set_meta("id", id)
	voice.set_meta("t", now)
	voice.play()
	played += 1
	_log(event, id, voice.bus)


## A looping sound held by `key`: on/off, volume (linear 0–1) and pitch follow every call.
func loop(key: String, id: String, on: bool, vol: float = 1.0, pitch: float = 1.0) -> void:
	var p: AudioStreamPlayer = _loops.get(key)
	if not on:
		if p != null and p.playing:
			p.stop()
		return
	if p == null:
		p = AudioStreamPlayer.new()
		add_child(p)
		_loops[key] = p
	var s := stream(id)
	if s == null:
		return
	if p.stream != s:
		p.stream = s
		p.bus = bus_of(id)
	p.volume_db = linear_to_db(clampf(vol, 0.0001, 1.0))
	p.pitch_scale = clampf(pitch, 0.3, 3.0)
	if not p.playing:
		p.play()
		played += 1
		_log("loop:" + key, id, p.bus)


func stop_all_loops() -> void:
	for k in _loops:
		_loops[k].stop()


func loop_playing(key: String) -> bool:
	return _loops.has(key) and _loops[key].playing


func _log(event: String, id: String, bus: String) -> void:
	events.append({"t": Time.get_ticks_msec() / 1000.0, "event": event, "id": id, "bus": bus})
	if events.size() > 60:
		events.pop_front()


## Current level of a channel in dB (left), for the debug meters.
func level_db(bus: String) -> float:
	var i := AudioServer.get_bus_index(bus)
	return -80.0 if i < 0 else AudioServer.get_bus_peak_volume_left_db(i, 0)
