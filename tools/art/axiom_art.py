"""Axiom Astronautics (package 25g): the Directorate's research ships – highly futuristic: graphite and slate
hulls, white leading edges, thin cyan light lines; the Threshold carries an artificial black hole in a
round core (user's design), its accretion disc animated by PixelArt.

Chars (fixed colours): 1 graphite, 2 slate, 3 light panel, 4 cyan glow, 5 deep cyan, 6 white edge,
7 black hole, 8 accretion orange, 9 accretion white-hot, 0 accretion dark red; e/f engines, a owner colour.
Run: python tools/art/axiom_art.py [--show]
"""
import os, sys, math
ROOT = os.path.join(os.path.dirname(__file__), "..", "..")


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.g = [["."] * w for _ in range(h)]

    def put(self, x, y, ch):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.g[y][x] = ch

    def hline(self, x0, x1, y, ch):
        for x in range(x0, x1 + 1):
            self.put(x, y, ch)

    def rows(self):
        out = ["".join(r).rstrip(".") for r in self.g]
        while out and out[0] == "":
            out.pop(0)
        return out


def engines(c, x0, ys):
    for y in ys:
        c.put(x0, y, "f")
        c.put(x0 + 1, y, "e")


# ---------------- Parallax (S research ship): a slim delta with a sensor ring
def parallax():
    W, H = 36, 9
    c = Canvas(W, H)
    cy = H - 1
    for y in range(0, H):
        k = cy - y                                       # rows above the centre line
        x0 = 3 + k * 2
        x1 = 34 - int(k * 2.6)
        if x1 <= x0:
            continue
        c.hline(x0, x1, y, "1")
        c.put(x1, y, "6")                                # white leading edge
        c.put(x0, y, "2")
    c.hline(6, 30, cy - 2, "2")
    c.hline(10, 27, cy - 3, "4")                         # cyan light line
    c.hline(16, 33, cy, "3")
    # the sensor ring
    for a in range(0, 360, 15):
        x = int(round(16 + 3.2 * math.cos(math.radians(a))))
        y = int(round(cy + 3.2 * math.sin(math.radians(a))))
        if y <= cy:
            c.put(x, y, "6")
    c.put(16, cy, "4")
    c.put(16, cy - 1, "5")
    c.put(29, cy - 1, "4")                               # the bow sensor
    engines(c, 1, [cy - 2, cy - 1, cy])
    c.put(8, cy, "a")
    return c.rows()


# ---------------- Threshold (L jump ship prototype): a long spine through a round core with an artificial
# black hole seen at a slant (0.4.25.35): the accretion disc is tilted towards the camera – its near half
# runs in front of the hole, its far half behind it and is lensed into a bright arc over the top
SHADE_DOWN = {"6": "3", "3": "2", "2": "1"}
TILT = math.radians(-10.0)                               # the disc's long axis, slightly turned
FLAT = 0.28                                              # how flat the tilted disc appears (cos of the inclination)


def disc_coords(dx, dy):
    """Screen offset from the hole (x already scaled by 1/1.1) -> (u, v) in the plane of the disc."""
    u = dx * math.cos(TILT) + dy * math.sin(TILT)
    v = -dx * math.sin(TILT) + dy * math.cos(TILT)
    return u, v / FLAT


def threshold():
    W, H = 124, 21
    c = Canvas(W, H)
    cy = H - 1
    cx, R = 60, 19                                       # the core: centre on the centre line, radius in rows
    # the spine (upper half, mirrored below with shading)
    for y in range(cy - 5, cy + 1):
        c.hline(4, 116 - (cy - y) * 2, y, "1")
    c.hline(4, 106, cy - 5, "6")
    c.hline(8, 104, cy - 3, "2")
    for x in range(10, 104, 6):
        c.put(x, cy - 4, "4")                            # running lights
    c.hline(108, 123, cy, "3")                           # the sensor needle
    c.put(123, cy, "4")
    c.put(122, cy, "6")
    for k in range(6):                                   # fins near the stern
        c.hline(8 + k, 22 - k, cy - 6 - k, "2")
        c.put(22 - k, cy - 6 - k, "6")
    engines(c, 1, [cy - 5, cy - 4, cy - 2, cy - 1, cy])
    c.hline(2, 3, cy - 3, "1")
    top = [list(r) for r in c.g]
    full = top + [[SHADE_DOWN.get(ch, ch) for ch in r] for r in reversed(top[:-1])]
    HH = len(full)
    # the raised bridge at the stern (0.4.25.36): three stepped tiers on the centre line, lit from the upper
    # left – each tier casts a shadow onto the one below; the cabin on top looks forward through a cyan band
    def tier(x0, x1, h, body, edge, lit, corner=1):
        cells = [(x, cy + dy) for x in range(x0, x1 + 1) for dy in range(-h, h + 1)
                 if not (corner and (x - x0 < corner or x1 - x < corner) and abs(dy) == h)]
        for x, y in cells:                                  # the shadow cast down and to the right
            if full[y + 1][x + 1] not in (".",) and (x + 1, y + 1) not in cells:
                full[y + 1][x + 1] = {"6": "3", "3": "2", "2": "1", "1": "1"}.get(full[y + 1][x + 1], full[y + 1][x + 1])
        for x, y in cells:
            dy = y - cy
            top_left = dy == -h or x == x0 or (corner and abs(dy) == h - 1 and (x - x0 < corner))
            bottom_right = dy == h or x == x1
            full[y][x] = lit if top_left else (edge if bottom_right else body)
    tier(23, 38, 7, "2", "1", "6", 2)                      # the base deck, a little wider than the spine
    tier(26, 37, 5, "3", "2", "6", 1)                      # the middle tier
    tier(29, 36, 3, "3", "2", "6", 1)                      # the bridge cabin on top
    for dy in range(-2, 3):
        full[cy + dy][35] = "4"                            # the forward-looking window band
        full[cy + dy][36] = "5"
    full[cy][32] = "5"                                     # a sensor dome on the roof
    full[cy][31] = "4"
    for x in (27, 28):
        full[cy - 4][x] = "a"                              # owner colour on the middle tier
        full[cy + 4][x] = "a"
    # the round core, drawn over the full image
    RH, R_IN, R_OUT = 5.4, 8.0, 15.0                     # hole radius, disc inner and outer radius
    for y in range(HH):
        for x in range(cx - R - 2, cx + R + 3):
            dx, dy = (x - cx) / 1.1, y - cy
            d = math.hypot(dx, dy)
            if d > R + 0.4:
                continue
            if d > R - 1.0:
                full[y][x] = "6" if dy <= 0 else "3"     # white rim, in shadow underneath
                continue
            if d > R - 3.0:
                full[y][x] = "2" if dy <= 0 else "1"     # the housing
                continue
            if d > R - 4.0:
                full[y][x] = "5"
                continue
            ch = "5" if d > R - 5.2 else "1"             # the field inside: a faint cyan glow at the edge
            u, v = disc_coords(dx, dy)
            r = math.hypot(u, v)
            def disc(r, u):
                # brightest at the inner edge; the side turning towards us (left) shines brighter
                if r < R_IN + 1.2 or (u < -2 and r < R_IN + 3.5):
                    return "9"
                if (r > R_OUT - 1.5 and u > -6) or (u > 6 and r > R_IN + 3.0):
                    return "0"
                return "8"
            if R_IN <= r <= R_OUT and v < 0:
                ch = disc(r, u)                          # the far half of the disc …
            if dy < 0.5 and RH + 0.6 < d < RH + 3.4:
                ch = "8" if d > RH + 2.2 else "9"        # … lensed into an arc over the hole
            elif dy > 0 and RH + 0.6 < d < RH + 1.5:
                ch = "0"                                 # … and a thin one beneath it
            if RH - 0.1 < d <= RH + 0.6:
                ch = "9"                                 # the photon ring
            if d <= RH - 0.1:
                ch = "7"                                 # the black hole itself
            if R_IN <= r <= R_OUT and v >= 0:
                ch = disc(r, u)                          # the near half runs in front of the hole
            full[y][x] = ch
    out = ["".join(r).rstrip(".") for r in full]
    return out


ARTS = {"axa_parallax": parallax(), "axa_threshold": threshold()}
if "--show" in sys.argv:
    for k, a in ARTS.items():
        print(k)
        print("\n".join(a))
        print()
    sys.exit()
p = os.path.join(ROOT, "data", "pixel_art.gd")
s = open(p, encoding="utf-8", newline="").read()
if "# AXIOM_END" not in s:
    s = s.replace("\t# Forge of Return (package 25f)", "\t# Axiom Astronautics (package 25g) – generated by tools/art/axiom_art.py: futuristic research ships\n\t# AXIOM_END\n\t# Forge of Return (package 25f)", 1)
for k, art in ARTS.items():
    block = '\t"%s": [\n' % k + "".join('\t\t"%s",\n' % r for r in art) + "\t],\n"
    if '\t"%s": [' % k in s:
        i = s.index('\t"%s": [' % k)
        j = s.index('\t],\n', i) + 4
        s = s[:i] + block + s[j:]
    else:
        i = s.index('\t# AXIOM_END\n')
        s = s[:i] + block + s[i:]
open(p, "w", encoding="utf-8", newline="").write(s)
print("axiom art ok")
