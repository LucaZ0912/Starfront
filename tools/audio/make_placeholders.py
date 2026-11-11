"""Synthesises the placeholder sounds of priority A (package 28a) – rough sketches after the descriptions in
docs/audio/sound_list.md, meant to be replaced one by one by real sounds with the same file name.
Mono WAV, 22,050 Hz, 16 bit, into assets/sfx/. Pure Python (no numpy needed).
Run: python tools/audio/make_placeholders.py
"""
import math, os, random, struct, wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sfx")
random.seed(7)


def n(sec):
    return int(sec * RATE)


def env(i, total, a=0.01, r=0.2, curve=1.0):
    """Attack/release envelope (seconds)."""
    t = i / RATE
    T = total / RATE
    e = 1.0
    if a > 0 and t < a:
        e = t / a
    if r > 0 and t > T - r:
        e = min(e, max(0.0, (T - t) / r))
    return e ** curve


def tone(sec, f0, f1=None, wave_="sine", vol=0.6, a=0.005, r=0.1, vib=0.0, vib_rate=6.0, curve=1.0):
    f1 = f0 if f1 is None else f1
    N = n(sec)
    out = []
    ph = 0.0
    for i in range(N):
        k = i / max(N - 1, 1)
        f = f0 * (f1 / f0) ** k if f0 > 0 and f1 > 0 else f0 + (f1 - f0) * k
        f *= 1.0 + vib * math.sin(2 * math.pi * vib_rate * i / RATE)
        ph += 2 * math.pi * f / RATE
        if wave_ == "sine":
            v = math.sin(ph)
        elif wave_ == "square":
            v = 1.0 if math.sin(ph) >= 0 else -1.0
            v *= 0.6
        elif wave_ == "saw":
            v = ((ph / (2 * math.pi)) % 1.0) * 2 - 1
            v *= 0.7
        elif wave_ == "tri":
            x = (ph / (2 * math.pi)) % 1.0
            v = 4 * abs(x - 0.5) - 1
        out.append(v * vol * env(i, N, a, r, curve))
    return out


def noise(sec, vol=0.5, lp=0.2, lp_end=None, a=0.005, r=0.2, curve=1.0):
    """Low-passed noise; lp = filter coefficient 0..1 (small = dark), may sweep to lp_end."""
    N = n(sec)
    out = []
    y = 0.0
    lp_end = lp if lp_end is None else lp_end
    for i in range(N):
        k = i / max(N - 1, 1)
        c = lp + (lp_end - lp) * k
        y += c * (random.uniform(-1, 1) - y)
        out.append(y * vol * env(i, N, a, r, curve) * (1.0 / max(c, 0.05)) ** 0.5)
    return out


def mix(*tracks, at=None):
    at = at or [0.0] * len(tracks)
    L = max(n(o) + len(t) for t, o in zip(tracks, at))
    out = [0.0] * L
    for t, o in zip(tracks, at):
        s = n(o)
        for i, v in enumerate(t):
            out[s + i] += v
    return out


def gain(t, g):
    return [v * g for v in t]


def loopify(t, fade=0.25):
    """Seamless loop: crossfades the end into the beginning."""
    F = n(fade)
    body = t[:len(t) - F]
    tail = t[len(t) - F:]
    for i in range(F):
        k = i / F
        body[i] = body[i] * k + tail[i] * (1 - k)
    return body


def save(name, t, norm=0.85):
    peak = max(1e-6, max(abs(v) for v in t))
    sc = norm / peak
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, v * sc)) * 32767)) for v in t))


SOUNDS = {
    # flight & navigation
    "engine_loop": lambda: loopify(mix(noise(3.5, 0.6, 0.03, a=0, r=0), tone(3.5, 55, wave_="saw", vol=0.25, a=0, r=0, vib=0.01, vib_rate=3))),
    "boost": lambda: mix(noise(1.1, 0.75, 0.08, 0.25, a=0.01, r=0.7), tone(0.9, 70, 150, "saw", 0.45, a=0.01, r=0.6, vib=0.03, vib_rate=14),
                         tone(0.25, 180, 60, "sine", 0.7, r=0.2)),     # 0.6.75.2: thrust burst – a hard ignition roar
    "warp_spool": lambda: mix(tone(2.5, 120, 640, "saw", 0.35, a=0.3, r=0.2, vib=0.04, vib_rate=11), noise(2.5, 0.2, 0.05, 0.3, a=0.5, r=0.2)),
    "warp_enter": lambda: mix(tone(1.0, 90, 30, "sine", 0.8, r=0.5), noise(1.0, 0.5, 0.4, 0.02, r=0.6), tone(0.6, 300, 1600, "sine", 0.25, r=0.3)),
    "warp_exit": lambda: mix(noise(1.0, 0.6, 0.02, 0.4, a=0.05, r=0.5), tone(1.0, 900, 120, "sine", 0.3, r=0.6), tone(0.8, 50, 40, "sine", 0.5, r=0.5), at=[0, 0, 0.2]),
    "gate_activate": lambda: mix(*[tone(0.6, 110 * (k + 1), wave_="square", vol=0.15, a=0.05, r=0.2) for k in range(3)],
                                 noise(2.0, 0.25, 0.6, a=0.3, r=0.3), at=[0, 0.5, 1.0, 0]),
    "jump_hyperspace": lambda: mix(tone(0.5, 60, 30, "sine", 1.0, r=0.4), noise(2.6, 0.4, 0.5, 0.01, a=0.01, r=1.2),
                                   tone(2.2, 700, 90, "saw", 0.25, a=0.05, r=1.0, vib=0.03)),
    # docking
    "dock_clamp": lambda: mix(noise(0.15, 0.9, 0.5, r=0.12), tone(0.4, 70, 50, "sine", 0.8, r=0.3), noise(0.9, 0.3, 0.7, 0.3, a=0.05, r=0.6), at=[0, 0, 0.25]),
    "undock_release": lambda: mix(noise(0.08, 0.8, 0.6, r=0.06), noise(0.08, 0.8, 0.6, r=0.06), noise(0.8, 0.35, 0.7, 0.2, a=0.05, r=0.5),
                                  tone(0.6, 60, 90, "sine", 0.4, a=0.1, r=0.3), at=[0, 0.15, 0.25, 0.5]),
    # weapons
    "w_pulse": lambda: mix(tone(0.18, 1400, 500, "square", 0.4, r=0.12), noise(0.05, 0.3, 0.8, r=0.04)),
    "w_beam_loop": lambda: loopify(mix(tone(1.25, 880, wave_="saw", vol=0.25, a=0, r=0, vib=0.01, vib_rate=17), tone(1.25, 1320, wave_="sine", vol=0.15, a=0, r=0),
                                       noise(1.25, 0.1, 0.9, a=0, r=0))),
    "w_autocannon": lambda: mix(noise(0.12, 1.0, 0.6, 0.15, r=0.1, curve=2), tone(0.1, 160, 80, "square", 0.4, r=0.08)),
    "w_rocket": lambda: mix(noise(0.5, 0.7, 0.8, 0.2, a=0.01, r=0.35), tone(0.2, 200, 90, "sine", 0.5, r=0.15)),
    # 0.7.52.15 (Luz): the Pathfinder's Red Arm Laser – a deep hiss: dark rushing noise that swells and dies, a low rumble
    # under it and a faint sizzle on top (the beam cutting)
    # 0.7.52.17: holds 2.5 s like the beam
    "w_arm_laser": lambda: mix(noise(2.7, 0.9, 0.03, 0.06, a=0.04, r=0.45, curve=1.4), tone(2.6, 62, 48, "sine", 0.55, a=0.02, r=0.4),
                               tone(2.6, 31, 27, "saw", 0.18, a=0.05, r=0.4), noise(2.5, 0.12, 0.35, 0.2, a=0.08, r=0.4, curve=2.0)),
    # hits & destruction
    "hit_shield": lambda: mix(tone(0.3, 420, 260, "sine", 0.6, r=0.25, vib=0.08, vib_rate=30), noise(0.2, 0.2, 0.9, r=0.15)),
    "hit_armor": lambda: mix(noise(0.08, 0.9, 0.7, r=0.07), tone(0.3, 980, 900, "tri", 0.35, r=0.28), tone(0.3, 1530, wave_="sine", vol=0.2, r=0.25)),
    "hit_hull": lambda: mix(noise(0.4, 0.9, 0.3, 0.05, r=0.3), tone(0.3, 80, 50, "sine", 0.6, r=0.25)),
    "shield_down": lambda: mix(tone(0.8, 900, 150, "sine", 0.5, r=0.5, vib=0.1, vib_rate=25), noise(0.8, 0.3, 0.9, 0.1, r=0.6)),
    "explosion_small": lambda: mix(noise(1.0, 1.0, 0.5, 0.03, a=0.002, r=0.8, curve=2), tone(0.4, 90, 40, "sine", 0.7, r=0.35)),
    "explosion_large": lambda: mix(noise(2.5, 1.0, 0.25, 0.01, a=0.005, r=2.0, curve=1.5), tone(1.2, 60, 28, "sine", 0.9, r=1.0),
                                   noise(0.8, 0.6, 0.3, 0.02, r=0.6), noise(0.6, 0.5, 0.4, 0.03, r=0.5), at=[0, 0, 0.6, 1.2]),
    "lock_acquired": lambda: mix(tone(0.1, 1760, wave_="square", vol=0.3, r=0.03), tone(0.12, 2350, wave_="square", vol=0.3, r=0.05), at=[0, 0.14]),
    # modules
    "module_on": lambda: mix(noise(0.03, 0.6, 0.9, r=0.02), tone(0.18, 440, 880, "tri", 0.4, r=0.08)),
    "module_off": lambda: mix(noise(0.03, 0.6, 0.9, r=0.02), tone(0.18, 880, 440, "tri", 0.4, r=0.08)),
    "module_denied": lambda: mix(tone(0.14, 220, wave_="square", vol=0.35, r=0.04), tone(0.16, 165, wave_="square", vol=0.35, r=0.06), at=[0, 0.15]),
    "mining_loop": lambda: loopify(mix(tone(2.25, 660, wave_="saw", vol=0.2, a=0, r=0, vib=0.02, vib_rate=9), noise(2.25, 0.35, 0.35, a=0, r=0),
                                       *[noise(0.05, 0.4, 0.8, r=0.04) for _ in range(9)], at=[0, 0] + [random.uniform(0, 2.1) for _ in range(9)])),
    "scan_ping": lambda: mix(tone(1.0, 1250, wave_="sine", vol=0.5, a=0.002, r=0.95, curve=2), tone(0.9, 1250, wave_="sine", vol=0.15, a=0.002, r=0.85, curve=2), at=[0, 0.12]),
    # drones
    "drone_launch": lambda: mix(noise(0.5, 0.5, 0.7, 0.3, r=0.35), tone(0.5, 300, 1100, "saw", 0.2, a=0.05, r=0.2)),
    # interface
    "ui_click": lambda: mix(tone(0.05, 1800, 1200, "sine", 0.5, a=0.001, r=0.04), noise(0.01, 0.2, 0.9, r=0.008)),
    "ui_open": lambda: tone(0.25, 400, 1200, "tri", 0.4, a=0.01, r=0.12),
    "ui_close": lambda: tone(0.2, 1100, 380, "tri", 0.4, a=0.01, r=0.1),
    "ui_error": lambda: mix(tone(0.14, 196, wave_="square", vol=0.3, r=0.04), tone(0.16, 147, wave_="square", vol=0.3, r=0.08), at=[0, 0.15]),
    "buy": lambda: mix(tone(0.12, 1568, wave_="square", vol=0.25, r=0.05), tone(0.3, 2093, wave_="sine", vol=0.4, r=0.25), at=[0, 0.08]),
    "sell": lambda: mix(tone(0.12, 1175, wave_="square", vol=0.25, r=0.05), tone(0.3, 1568, wave_="sine", vol=0.4, r=0.25), at=[0, 0.08]),
    "mission_complete": lambda: mix(*[tone(0.35, f, wave_="tri", vol=0.4, r=0.2) for f in (523, 659, 784, 1047)], at=[0, 0.12, 0.24, 0.36]),
    "notify": lambda: mix(tone(0.3, 1319, wave_="sine", vol=0.4, r=0.25, curve=2), tone(0.25, 1976, wave_="sine", vol=0.15, r=0.2, curve=2)),
    "warn": lambda: mix(tone(0.15, 1047, wave_="square", vol=0.25, r=0.08), tone(0.2, 1047, wave_="square", vol=0.25, r=0.12), at=[0, 0.18]),
    "alarm_hull": lambda: loopify(mix(tone(0.55, 330, 300, "saw", 0.35, a=0.02, r=0.2), tone(0.55, 330, 300, "saw", 0.35, a=0.02, r=0.2), at=[0, 0.55]), 0.05),
    # atmosphere
    "amb_space": lambda: loopify(mix(noise(32.0, 0.4, 0.01, a=0, r=0), tone(32.0, 41, wave_="sine", vol=0.12, a=0, r=0, vib=0.02, vib_rate=0.1),
                                     *[noise(0.3, 0.06, 0.6, r=0.25) for _ in range(12)], at=[0, 0] + [random.uniform(0, 31) for _ in range(12)]), 1.5),
}


if __name__ == "__main__":
    for name, make in SOUNDS.items():
        save(name, make(), 0.6 if name in ("amb_space", "engine_loop") else 0.85)
    print("%d placeholder sounds written to assets/sfx/" % len(SOUNDS))
