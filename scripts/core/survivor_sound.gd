extends RefCounted
## Package 62a, part 7c-2 (Luz): the sounds of Survivor, made here (no files), like the crowd's applause: short and
## plain, so that a hundred of them a minute do not wear on the ear. Each is a tone that slides from one pitch to
## another, with some noise in it, dying away; "sv_level" is three notes going up.
## No class_name: load("res://scripts/core/survivor_sound.gd").make(id).

const RATE := 22050
## id: [seconds, pitch at its start (Hz), pitch at its end, the wave (0 sine, 1 square, 2 saw, 3 noise only), how much
## noise is in it (0 … 1), how fast it dies away, a waver (Hz), how deep the waver is]
const SPEC := {
	"sv_pulse": [0.22, 150.0, 60.0, 0, 0.15, 7.0, 0.0, 0.0],
	"sv_laser": [0.12, 1500.0, 500.0, 2, 0.05, 10.0, 0.0, 0.0],
	"sv_boom": [0.4, 120.0, 40.0, 0, 0.7, 6.0, 0.0, 0.0],
	"sv_shot": [0.09, 900.0, 600.0, 1, 0.1, 14.0, 0.0, 0.0],
	"sv_beam": [0.7, 300.0, 900.0, 2, 0.2, 2.0, 30.0, 0.2],
	"sv_blade": [0.3, 700.0, 1100.0, 0, 0.3, 5.0, 40.0, 0.3],
	"sv_shard": [0.07, 1800.0, 2400.0, 0, 0.0, 16.0, 0.0, 0.0],
	"sv_crate": [0.2, 300.0, 200.0, 1, 0.4, 9.0, 0.0, 0.0],
	"sv_item": [0.35, 700.0, 1400.0, 0, 0.0, 5.0, 12.0, 0.1],
	"sv_bomb": [1.1, 90.0, 30.0, 0, 0.85, 2.2, 0.0, 0.0],
	"sv_stomp": [0.35, 90.0, 45.0, 0, 0.6, 7.0, 0.0, 0.0],
	"sv_spit": [0.18, 400.0, 150.0, 3, 0.9, 9.0, 0.0, 0.0],
	"sv_howl": [0.9, 420.0, 300.0, 2, 0.15, 1.5, 6.0, 0.08],
	"sv_screech": [0.6, 1400.0, 900.0, 2, 0.3, 2.5, 22.0, 0.15],
	"sv_alarm": [0.7, 440.0, 440.0, 1, 0.0, 1.6, 4.0, 0.25],
	"sv_break": [0.25, 1200.0, 300.0, 3, 0.8, 8.0, 0.0, 0.0],
	"sv_mine": [0.08, 520.0, 760.0, 1, 0.0, 12.0, 0.0, 0.0],
	"sv_freeze": [0.45, 2200.0, 900.0, 3, 0.85, 4.0, 0.0, 0.0],
	"sv_well": [0.6, 210.0, 70.0, 0, 0.1, 3.0, 9.0, 0.3],
	"sv_taser": [0.14, 2400.0, 1400.0, 1, 0.55, 9.0, 90.0, 0.4],
	"sv_hole": [1.2, 120.0, 34.0, 0, 0.25, 1.8, 5.0, 0.35],
	"sv_shell": [0.5, 900.0, 300.0, 2, 0.1, 2.0, 0.0, 0.0],
	"sv_emp": [0.6, 80.0, 40.0, 3, 0.9, 3.0, 0.0, 0.0],
	"sv_steam": [1.0, 2600.0, 900.0, 3, 1.0, 2.4, 0.0, 0.0],      # part 9a: a steam vent bursts
	"sv_ice": [0.32, 1500.0, 420.0, 3, 0.85, 7.0, 0.0, 0.0],      # … a burrower breaks out of the ice
}


static func make(id: String) -> AudioStreamWAV:
	var buf := PackedFloat32Array()
	if id == "sv_level":
		for note in [660.0, 880.0, 1320.0]:
			buf.append_array(_tone([0.14, note, note, 0, 0.0, 6.0, 0.0, 0.0], 660 + int(note)))
	elif SPEC.has(id):
		buf = _tone(SPEC[id], hash(id))
	else:
		return null
	var peak := 0.001
	for v in buf:
		peak = maxf(peak, absf(v))
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i] / peak * 0.8, -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = bytes
	return s


static func _tone(sp: Array, seed_n: int) -> PackedFloat32Array:
	var n := int(float(sp[0]) * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_n
	var phase := 0.0
	var low := 0.0
	var wave := int(sp[3])
	var noise := float(sp[4])
	for i in n:
		var u := float(i) / float(n)
		var t := float(i) / float(RATE)
		var f := lerpf(float(sp[1]), float(sp[2]), u) * (1.0 + float(sp[7]) * sin(TAU * float(sp[6]) * t))
		phase = fposmod(phase + f / float(RATE), 1.0)
		var w := 0.0
		match wave:
			0:
				w = sin(phase * TAU)
			1:
				w = 0.7 if phase < 0.5 else -0.7
			2:
				w = (phase * 2.0 - 1.0) * 0.8
		low = low * 0.72 + rng.randf_range(-1.0, 1.0) * 0.28
		var env := exp(-float(sp[5]) * u) * minf(1.0, float(i) / (0.004 * RATE)) * minf(1.0, (1.0 - u) * 12.0)
		buf[i] = (w * (1.0 - noise) + low * 2.2 * noise) * env
	return buf
