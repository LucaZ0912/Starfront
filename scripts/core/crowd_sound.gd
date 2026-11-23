extends RefCounted
## Package 62a, part 4 (Luz): the Colosseum's crowd, as a sound made here (no file): applause. Many hands, each
## clapping at its own pace, a little out of step with the others; a low roar under it; it swells, holds and dies
## away. How loud it is played depends on how full the stands are (data/colosseum.gd `applause_db`).
## No class_name: preload it.

const RATE := 22050


static func applause(seconds: float = 5.5, hands: int = 46, seed_n: int = 6204) -> AudioStreamWAV:
	var n := int(seconds * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_n
	for h in hands:
		var pace := rng.randf_range(0.21, 0.31)                  # seconds between two claps of this pair of hands
		var loud := rng.randf_range(0.35, 1.0)
		var dull := rng.randf_range(0.25, 0.7)                   # how muffled its clap is
		var t := rng.randf_range(0.0, 0.5)
		while t < seconds - 0.05:
			var at := int(t * RATE)
			var len := int(rng.randf_range(0.006, 0.012) * RATE)
			var last := 0.0
			for k in len:
				if at + k >= n:
					break
				var raw := rng.randf_range(-1.0, 1.0)
				last = last * dull + raw * (1.0 - dull)
				buf[at + k] += last * loud * exp(-5.0 * float(k) / float(len))
			t += pace * rng.randf_range(0.86, 1.16)
	var low := 0.0                                               # the roar under it
	for i in n:
		low = low * 0.985 + rng.randf_range(-1.0, 1.0) * 0.015
		var u := float(i) / float(n)
		var env := clampf(u / 0.09, 0.0, 1.0) * clampf((1.0 - u) / 0.3, 0.0, 1.0)
		buf[i] = (buf[i] * 0.16 + low * 2.2) * env
	var peak := 0.001
	for i2 in n:
		peak = maxf(peak, absf(buf[i2]))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i3 in n:
		bytes.encode_s16(i3 * 2, int(clampf(buf[i3] / peak * 0.85, -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = bytes
	return s
