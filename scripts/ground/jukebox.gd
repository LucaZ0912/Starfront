class_name Jukebox
extends RefCounted
## Package 49 (0.7.49.6): the bar's jukebox – a few short lounge loops made on the spot (soft chords, a bass, a
## brushed beat), no files needed. Each track is generated once and cached.

const RATE := 16000
const TRACKS := [
	{"name": "Neon Rain", "bpm": 84, "root": 57, "chords": [[0, 3, 7, 10], [-4, 0, 3, 7], [-7, -3, 0, 5], [-2, 2, 5, 9]]},
	{"name": "Dock Nine Blues", "bpm": 72, "root": 52, "chords": [[0, 4, 7, 10], [5, 9, 12, 15], [0, 4, 7, 10], [7, 11, 14, 17]]},
	{"name": "Low Orbit Lounge", "bpm": 96, "root": 55, "chords": [[0, 4, 7, 11], [-3, 0, 4, 7], [2, 5, 9, 12], [-5, -1, 2, 5]]},
]

static var _cache := {}


static func track_name(i: int) -> String:
	return String(TRACKS[i]["name"])


static func stream(i: int) -> AudioStreamWAV:
	if _cache.has(i):
		return _cache[i]
	var t: Dictionary = TRACKS[i]
	var beat := 60.0 / float(t["bpm"])
	var bar := beat * 4.0
	var chords: Array = t["chords"]
	var n := int(bar * chords.size() * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var root := int(t["root"])
	var rng := RandomNumberGenerator.new()
	rng.seed = 4900 + i
	for s in n:
		var tt := float(s) / RATE
		var ci := int(tt / bar) % chords.size()
		var in_bar := fmod(tt, bar)
		var ch: Array = chords[ci]
		# soft pad: the chord, a little detuned, swelling in each bar
		var env := minf(in_bar / 0.25, 1.0) * (0.75 + 0.25 * cos(in_bar / bar * PI))
		var pad := 0.0
		for note in ch:
			var f := 440.0 * pow(2.0, (root + int(note) - 69) / 12.0)
			pad += sin(TAU * f * tt) + 0.4 * sin(TAU * f * 1.003 * tt + 1.0)
		pad *= 0.045 * env
		# bass on beats one and three
		var in_beat := fmod(tt, beat)
		var bn := int(in_bar / beat)
		var bf := 440.0 * pow(2.0, (root + int(ch[0]) - 24 - 69) / 12.0)
		var bass := 0.0
		if bn == 0 or bn == 2 or (bn == 3 and in_beat > beat * 0.5):
			var bt := in_beat if bn != 3 else in_beat - beat * 0.5
			bass = 0.22 * exp(-bt * 3.0) * (2.0 * absf(2.0 * fmod(bf * tt, 1.0) - 1.0) - 1.0)
		# kick on one and three, a brushed hat on the off-beats
		var drum := 0.0
		if bn == 0 or bn == 2:
			drum += 0.3 * exp(-in_beat * 18.0) * sin(TAU * (50.0 + 70.0 * exp(-in_beat * 30.0)) * in_beat)
		var half := fmod(tt, beat * 0.5)
		if int(tt / (beat * 0.5)) % 2 == 1:
			drum += 0.05 * exp(-half * 40.0) * rng.randf_range(-1.0, 1.0)
		var v := clampf(pad + bass + drum, -1.0, 1.0)
		data.encode_s16(s * 2, int(v * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = n
	_cache[i] = w
	return w
