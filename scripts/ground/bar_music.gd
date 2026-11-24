extends RefCounted
## (Luz, 24 Nov 2026) Music made on the spot, as the jukebox makes its loops (no files): three punk songs for the
## Static Feedback at night, when the band plays (fast, three chords, a distorted guitar, a driving bass, kick and
## snare), a quiet tune for the bar by day, and a track for Survivor (a pulse and an arpeggio that push without
## getting on your nerves). Each is rendered once, in a thread of its own so that the game does not stop for it, and
## kept: stream(id) gives nothing until it is ready. No class_name: preload it.

const RATE := 16000
## id -> name, kind, bpm, root (MIDI), bars, the chords' roots by the bar (semitones from the root), the level (dB)
const TRACKS := {
	"punk1": {"name": "The Hull Breach: Airlock Song", "kind": "punk", "bpm": 176, "root": 40, "bars": 16, "prog": [0, 0, 5, 5, 7, 7, 5, 0], "minor": false, "db": -9.0, "seed": 11},
	"punk2": {"name": "The Hull Breach: No Requests", "kind": "punk", "bpm": 184, "root": 45, "bars": 16, "prog": [0, 8, 3, 10], "minor": true, "db": -9.0, "seed": 23},
	"punk3": {"name": "The Hull Breach: Cash Only", "kind": "punk", "bpm": 168, "root": 38, "bars": 16, "prog": [0, 7, 9, 5], "minor": false, "db": -9.0, "seed": 37},
	"calm": {"name": "Closed Till Dark", "kind": "calm", "bpm": 66, "root": 57, "bars": 8, "prog": [0, -3, 5, 7, 0, -3, 2, 7], "minor": false, "db": -11.0, "seed": 5},
	"survivor": {"name": "Wave After Wave", "kind": "pulse", "bpm": 124, "root": 45, "bars": 16, "prog": [0, 0, 8, 8, 3, 3, 10, 10], "minor": true, "db": -12.0, "seed": 9},
}
const NIGHT := ["punk1", "punk2", "punk3"]
const DAY := ["calm"]

static var _cache := {}
static var _threads := {}
static var _done := {}
static var _lock := Mutex.new()


static func track_name(id: String) -> String:
	return String((TRACKS.get(id, {}) as Dictionary).get("name", id))


static func level_db(id: String) -> float:
	return float((TRACKS.get(id, {}) as Dictionary).get("db", -9.0))


## The music of a level: the bar by night and by day, Survivor's stage; nothing elsewhere.
static func list_for(level: String, night: bool) -> Array:
	match level:
		"zbar":
			return NIGHT if night else DAY
		"zcolsv":
			return ["survivor"]
	return []


## The stream of a track, or null while it is still being made (it is begun at the first asking).
static func stream(id: String) -> AudioStreamWAV:
	if _cache.has(id):
		return _cache[id]
	if not TRACKS.has(id):
		return null
	_lock.lock()
	var data = _done.get(id, null)
	_lock.unlock()
	if data != null:
		if _threads.has(id):
			(_threads[id] as Thread).wait_to_finish()
			_threads.erase(id)
		_cache[id] = _wav(data)
		return _cache[id]
	if not _threads.has(id):
		var th := Thread.new()
		_threads[id] = th
		th.start(_job.bind(id))
	return null


static func _job(id: String) -> void:
	var data := render(id)
	_lock.lock()
	_done[id] = data
	_lock.unlock()


static func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = data.size() / 2
	return w


## Waits for the threads still at work (when the game closes).
static func finish() -> void:
	for id in _threads.keys():
		(_threads[id] as Thread).wait_to_finish()
	_threads.clear()


static func _hz(note: float) -> float:
	return 440.0 * pow(2.0, (note - 69.0) / 12.0)


## The samples of a track (16 bit, mono): a whole number of bars, so that it loops.
static func render(id: String) -> PackedByteArray:
	var t: Dictionary = TRACKS[id]
	match String(t["kind"]):
		"punk":
			return _punk(t)
		"calm":
			return _calm(t)
	return _pulse(t)


## Punk: a power chord chugging in eighths through a fuzz, the bass under it, kick on one and three, snare on two
## and four, a hat on every eighth; from the second half on a lead of a few notes over it; a fill before the turn.
static func _punk(t: Dictionary) -> PackedByteArray:
	var beat := 60.0 / float(t["bpm"])
	var bar := beat * 4.0
	var eighth := beat * 0.5
	var bars := int(t["bars"])
	var n := int(bar * bars * RATE)
	var prog: Array = t["prog"]
	var root := float(t["root"])
	var third := 3.0 if bool(t["minor"]) else 4.0
	var lead_steps: Array = [0.0, third, 7.0, 12.0, 7.0, third, 0.0, 7.0, 12.0, 12.0 + third, 12.0, 7.0, third, 7.0, 0.0, 0.0]
	var rng := RandomNumberGenerator.new()
	rng.seed = int(t["seed"])
	var data := PackedByteArray()
	data.resize(n * 2)
	for s in n:
		var tt := float(s) / RATE
		var bi := int(tt / bar)
		var in_bar := tt - bi * bar
		var bn := int(in_bar / beat)
		var in_beat := in_bar - bn * beat
		var en := int(in_bar / eighth)
		var in_e := in_bar - en * eighth
		var ch := root + float(prog[bi % prog.size()])
		var f := _hz(ch)
		var nz := rng.randf_range(-1.0, 1.0)
		# the guitar: root, fifth and octave as saws, a second string a little off, through a fuzz; chugged
		var g := (2.0 * fmod(f * tt, 1.0) - 1.0) + 0.8 * (2.0 * fmod(f * 1.4983 * tt, 1.0) - 1.0) + 0.6 * (2.0 * fmod(f * 2.0 * tt, 1.0) - 1.0) \
			+ 0.5 * (2.0 * fmod(f * 1.006 * tt, 1.0) - 1.0)
		var open: bool = bi % 4 == 3 and bn >= 2                      # (the chord rings out before the turn)
		var chug := 1.0 if open else (0.35 + 0.65 * exp(-in_e * 9.0))
		var gtr := tanh(g * 1.9 * chug) * 0.21
		# the bass: every eighth, an octave down
		var bf := f * 0.5
		var bass := (1.0 if fmod(bf * tt, 1.0) < 0.5 else -1.0) * 0.16 * exp(-in_e * 5.0) + 0.1 * sin(TAU * bf * tt)
		# the drums
		var drum := 0.0
		if bn == 0 or bn == 2 or (bn == 1 and in_beat > eighth and bi % 2 == 1):
			var kt := in_beat if not (bn == 1) else in_beat - eighth
			drum += 0.42 * exp(-kt * 16.0) * sin(TAU * (48.0 + 90.0 * exp(-kt * 34.0)) * kt)
		if bn == 1 or bn == 3:
			drum += 0.26 * exp(-in_beat * 17.0) * nz + 0.14 * exp(-in_beat * 24.0) * sin(TAU * 190.0 * in_beat)
		drum += 0.07 * exp(-in_e * 55.0) * nz
		if bi % 8 == 7 and bn == 3:
			var st16 := fmod(in_beat, beat * 0.25)
			drum += 0.2 * exp(-st16 * 30.0) * nz                      # a roll on the snare into the next round
		# the lead: from the second half on, a few notes two octaves up
		var lead := 0.0
		if bi >= bars / 2:
			var ln := _hz(ch + 24.0 + float(lead_steps[(en + bi * 3) % lead_steps.size()]))
			var lv := sin(TAU * ln * tt + 2.0 * sin(TAU * 5.5 * tt) * 0.3)
			lead = (0.07 * (1.0 if lv > 0.0 else -1.0) + 0.05 * lv) * (0.4 + 0.6 * exp(-in_e * 4.0))
		var v := tanh((gtr + bass + drum + lead) * 1.25)
		data.encode_s16(s * 2, int(clampf(v, -1.0, 1.0) * 29000.0))
	return data


## By day: a slow tune of soft notes falling out of a chord, one to the eighth, a low hum under it, a hiss like an
## old record.
static func _calm(t: Dictionary) -> PackedByteArray:
	var beat := 60.0 / float(t["bpm"])
	var bar := beat * 4.0
	var eighth := beat * 0.5
	var bars := int(t["bars"])
	var n := int(bar * bars * RATE)
	var prog: Array = t["prog"]
	var root := float(t["root"])
	var tones: Array = [0.0, 7.0, 4.0, 12.0, 7.0, 16.0, 12.0, 4.0]
	var rng := RandomNumberGenerator.new()
	rng.seed = int(t["seed"])
	var data := PackedByteArray()
	data.resize(n * 2)
	for s in n:
		var tt := float(s) / RATE
		var bi := int(tt / bar)
		var in_bar := tt - bi * bar
		var en := int(in_bar / eighth)
		var in_e := in_bar - en * eighth
		var ch := root + float(prog[bi % prog.size()])
		# the note of this eighth, and the one before it still ringing
		var v := 0.0
		for back in 3:
			var k := en - back
			var age := in_e + back * eighth
			if k < 0:
				continue
			var f := _hz(ch + float(tones[k % tones.size()]))
			v += (sin(TAU * f * tt) + 0.3 * sin(TAU * f * 2.0 * tt) * exp(-age * 5.0)) * exp(-age * 2.3) * 0.13
		# a low hum: root and fifth, breathing with the bar
		var hum := (sin(TAU * _hz(ch - 12.0) * tt) + 0.6 * sin(TAU * _hz(ch - 5.0) * tt)) * 0.06 * (0.7 + 0.3 * sin(PI * in_bar / bar))
		var hiss := rng.randf_range(-1.0, 1.0) * 0.006
		data.encode_s16(s * 2, int(clampf((v + hum) * 1.6 + hiss, -1.0, 1.0) * 29000.0))
	return data


## Survivor: a kick on every beat, the bass pulsing between the kicks, an arpeggio in sixteenths that opens and shuts
## slowly, a hat off the beat, a pad; in the second half a slow line over it. It pushes, it does not shout.
static func _pulse(t: Dictionary) -> PackedByteArray:
	var beat := 60.0 / float(t["bpm"])
	var bar := beat * 4.0
	var six := beat * 0.25
	var bars := int(t["bars"])
	var n := int(bar * bars * RATE)
	var prog: Array = t["prog"]
	var root := float(t["root"])
	var arp: Array = [0.0, 7.0, 12.0, 15.0, 12.0, 7.0, 19.0, 15.0]
	var line: Array = [12.0, 15.0, 19.0, 17.0, 15.0, 12.0, 10.0, 12.0]
	var rng := RandomNumberGenerator.new()
	rng.seed = int(t["seed"])
	var total := bar * bars
	var data := PackedByteArray()
	data.resize(n * 2)
	for s in n:
		var tt := float(s) / RATE
		var bi := int(tt / bar)
		var in_bar := tt - bi * bar
		var bn := int(in_bar / beat)
		var in_beat := in_bar - bn * beat
		var sn := int(in_bar / six)
		var in_s := in_bar - sn * six
		var ch := root + float(prog[bi % prog.size()])
		var duck := 1.0 - 0.75 * exp(-in_beat * 7.0)                   # everything ducks under the kick and comes back
		var kick := 0.36 * exp(-in_beat * 13.0) * sin(TAU * (44.0 + 80.0 * exp(-in_beat * 30.0)) * in_beat)
		var bf := _hz(ch - 12.0)
		var bass := (sin(TAU * bf * tt) + 0.35 * (2.0 * fmod(bf * tt, 1.0) - 1.0)) * 0.2 * duck
		var af := _hz(ch + 12.0 + float(arp[(sn + bi * 2) % arp.size()]))
		var tri := 2.0 * absf(2.0 * fmod(af * tt, 1.0) - 1.0) - 1.0
		var open := 0.5 + 0.5 * sin(TAU * tt / (bar * 4.0) - PI * 0.5)   # opens and shuts over four bars
		var arpv := tri * 0.09 * exp(-in_s * (16.0 - 9.0 * open)) * (0.45 + 0.55 * open) * duck
		var hat := 0.0
		if in_beat > beat * 0.5:
			hat = 0.04 * exp(-(in_beat - beat * 0.5) * 45.0) * rng.randf_range(-1.0, 1.0)
		var pad := (sin(TAU * _hz(ch) * tt) + sin(TAU * _hz(ch + 3.0) * tt) + sin(TAU * _hz(ch + 7.0) * tt)) * 0.035 * duck
		var lead := 0.0
		if bi >= bars / 2:
			var lf := _hz(ch + 12.0 + float(line[(bi * 2 + bn / 2) % line.size()]))
			var half := fmod(in_bar, beat * 2.0)
			lead = sin(TAU * lf * tt + 0.25 * sin(TAU * 5.0 * tt)) * 0.07 * minf(half / 0.08, 1.0) * exp(-half * 1.1)
		var fade := minf(minf(tt / 0.02, 1.0), minf((total - tt) / 0.02, 1.0))
		data.encode_s16(s * 2, int(clampf(tanh((kick + bass + arpv + hat + pad + lead) * 1.3) * fade, -1.0, 1.0) * 29000.0))
	return data
