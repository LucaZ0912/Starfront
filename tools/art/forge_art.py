"""Forge of Return (package 25f): the Covenant's flying temples. Duality of power: outside a dark crimson,
spiked armour bristling with glowing red focus crystals (a threat to every enemy); inside a radiant nave of
ivory and gold with stained-glass windows (a shining example for the faithful). Fixed colours – red and
gold like the Covenant's crest, whoever owns the ship.

Chars: F crimson, A bright crimson, l dark crimson, I/J/j ivory, U/u gold, R/E red glow (crystals, glass),
b blue glass, w mount, g barrel, e/f engines, a owner colour.
Run: python tools/art/forge_art.py [--show]
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

    def get(self, x, y):
        return self.g[y][x] if 0 <= x < self.w and 0 <= y < self.h else "."

    def rect(self, x0, y0, x1, y1, ch, edge=None):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.put(x, y, edge if (edge and y == y0) else ch)

    def hline(self, x0, x1, y, ch):
        for x in range(x0, x1 + 1):
            self.put(x, y, ch)

    def vline(self, x, y0, y1, ch):
        for y in range(y0, y1 + 1):
            self.put(x, y, ch)

    def rows(self):
        out = ["".join(r).rstrip(".") for r in self.g]
        while out and out[0] == "":
            out.pop(0)
        return out


def nave(c, x0, x1, y0, cy, glass_row, window_step=3):
    """The radiant nave: ivory with a gold rim and a row of stained-glass windows."""
    c.rect(x0, y0, x1, cy, "I", "u")
    for x in range(x0 + 2, x1 - 1, window_step):
        c.put(x, glass_row, "R" if (x // window_step) % 3 else "b")
        c.put(x, glass_row + 1, "E" if (x // window_step) % 3 else "b")
    c.hline(x0, x1, cy, "J")


def crystal(c, x, y, big=False):
    """A focus-crystal laser: a gold mount with a glowing red crystal."""
    c.put(x - 1, y, "U")
    c.put(x, y, "R")
    c.put(x + 1, y, "E")
    c.put(x + 2, y, "g")
    if big:
        c.put(x, y - 1, "U")
        c.put(x + 1, y - 1, "R")
        c.put(x + 3, y, "g")


def buttress(c, x, y_from, y_to):
    """A flying buttress: a gold rib arching from the armour to the nave."""
    for k, y in enumerate(range(y_from, y_to + 1)):
        c.put(x + k, y, "u")
        c.put(x + k + 1, y, "U")


def engines(c, x0, ys):
    for y in ys:
        c.put(x0, y, "f")
        c.put(x0 + 1, y, "e")


# ---------------- Acolyte (S militia ship): a crimson reliquary blade around a small golden chapel
def acolyte():
    W, H = 38, 9
    c = Canvas(W, H)
    cy = H - 1
    for y, (x0, x1) in {2: (10, 22), 3: (7, 26), 4: (5, 29), 5: (4, 31), 6: (4, 33), 7: (4, 35), 8: (4, 37)}.items():
        c.hline(x0, x1, y, "F")
        c.put(x1, y, "A")
        c.put(x0, y, "A")
    c.hline(10, 22, 2, "A")
    for x in range(9, 24, 4):
        c.put(x, 2, "U")                                 # gold studs
    nave(c, 12, 28, 6, cy, 7, 3)
    c.hline(29, 33, cy, "u")
    c.put(34, cy, "U")                                   # the golden spire at the bow
    crystal(c, 18, 3)
    crystal(c, 24, 4)
    c.hline(1, 3, 6, "l")
    engines(c, 2, [6, 7, 8])
    c.put(12, cy, "a")
    return c.rows()


# ---------------- Templar (M patrol ship): a longer nave, crimson flanks with flying buttresses and crystals
def templar():
    W, H = 62, 13
    c = Canvas(W, H)
    cy = H - 1
    for y in range(2, cy + 1):                           # crimson armour, tapering to a blade at the bow
        x0 = 4 if y >= 5 else 10 - y
        x1 = 46 + (y - 2) * 1 if y < 8 else 52 + (y - 8) * 2
        c.hline(x0, x1, y, "F")
        c.put(x1, y, "A")
    c.hline(8, 44, 2, "A")
    for x in range(8, 46, 5):
        c.put(x, 1, "A")                                 # spikes on the outer armour
        c.put(x, 2, "U")
    nave(c, 14, 48, 8, cy, 9, 3)
    for bx in (16, 24, 32, 40):
        buttress(c, bx, 4, 7)
    for x in (12, 22, 32, 42):
        crystal(c, x, 3)
    # a golden halo round the bridge dome near the stern
    for a in range(0, 360, 20):
        x = int(round(10 + 3.2 * math.cos(math.radians(a))))
        y = int(round(cy - 1 + 3.2 * math.sin(math.radians(a))))
        if y <= cy:
            c.put(x, y, "u")
    c.put(10, cy, "J")
    c.put(10, cy - 1, "I")
    c.hline(49, 58, cy, "u")
    c.put(59, cy, "U")
    c.put(60, cy, "U")
    c.rect(1, 6, 3, cy, "l")
    engines(c, 1, [6, 7, 9, 10, 12])
    c.put(20, cy, "a")
    return c.rows()


# ---------------- Cathedral (L flagship): a fortress of faith – spiked crimson battlements full of crystal
# batteries outside, a radiant nave with stained glass inside, a great rose window at the bow, twin bell
# towers with golden spires, a golden halo over the sanctuary at the stern
def cathedral():
    W, H = 124, 21
    c = Canvas(W, H)
    cy = H - 1
    # the crimson battlements (outer armour), crenellated and spiked
    for y in range(3, cy + 1):
        x0 = 6 if y >= 6 else 12 - y
        x1 = 104 if y < 10 else 104 + (y - 10) * 2
        c.hline(x0, x1, y, "F")
        c.put(x1, y, "A")
    c.hline(10, 102, 3, "A")
    for x in range(10, 102, 6):
        c.rect(x, 1, x + 1, 2, "F", "A")                 # battlement merlons
        c.put(x, 0, "U")                                 # gold spike tips
    # crystal batteries along the battlements (the threat)
    for x in range(14, 100, 8):
        crystal(c, x, 4, big=True)
    # flying buttresses from the battlements to the nave
    for bx in range(18, 96, 10):
        buttress(c, bx, 6, 10)
    # the radiant nave (the example): ivory and gold with two rows of stained glass
    nave(c, 22, 100, 11, cy, 12, 3)
    for x in range(24, 98, 3):
        c.put(x, 16, "R" if (x // 3) % 2 else "u")
        c.put(x, 17, "E" if (x // 3) % 2 else "b")
    c.hline(22, 100, 15, "u")
    # twin bell towers with golden spires near the bow
    for tx in (84, 94):
        c.rect(tx, 6, tx + 4, 10, "I", "u")
        c.rect(tx + 1, 7, tx + 3, 9, "b")
        c.put(tx + 2, 8, "R")
        c.vline(tx + 2, 4, 5, "U")
        c.put(tx + 2, 3, "u")
    # the great rose window at the bow
    rx, ry, rr = 108, cy - 1, 6
    for y in range(ry - rr, cy + 1):
        for x in range(rx - rr, rx + rr + 1):
            d = math.hypot(x - rx, y - ry)
            if d <= rr + 0.4:
                ang = math.degrees(math.atan2(y - ry, x - rx)) % 360
                if d > rr - 1.0:
                    ch = "U"                             # gold frame
                elif d < 1.5:
                    ch = "E"                             # glowing heart
                elif int(ang // 30) % 2 == 0:
                    ch = "R"
                else:
                    ch = "b" if d < rr - 2.5 else "u"    # blue glass, gold tracery
                c.put(x, y, ch)
    for x in range(115, 122):
        c.put(x, cy, "U" if x < 121 else "u")            # the golden prow
    # the sanctuary at the stern under a golden halo (the shining example)
    hx, hy = 16, cy - 2
    for a in range(0, 360, 12):
        for rad in (5.0, 5.8):
            x = int(round(hx + rad * math.cos(math.radians(a))))
            y = int(round(hy + rad * math.sin(math.radians(a))))
            if y <= cy:
                c.put(x, y, "u" if rad < 5.5 else "U")
    c.rect(14, cy - 3, 18, cy, "J")
    c.put(16, cy - 1, "E")
    c.rect(1, 7, 5, cy, "l")
    engines(c, 1, [7, 8, 10, 11, 13, 14, 16, 17, 19, 20])
    c.put(40, cy, "a")
    c.put(41, cy, "a")
    return c.rows()


ARTS = {"for_acolyte": acolyte(), "for_templar": templar(), "for_cathedral": cathedral()}
if "--show" in sys.argv:
    for k, a in ARTS.items():
        print(k)
        print("\n".join(a))
        print()
    sys.exit()
p = os.path.join(ROOT, "data", "pixel_art.gd")
s = open(p, encoding="utf-8", newline="").read()
if "# FORGE_END" not in s:
    s = s.replace("\t# Concord Fleetworks (package 25e)", "\t# Forge of Return (package 25f) – generated by tools/art/forge_art.py: flying temples in red and gold\n\t# FORGE_END\n\t# Concord Fleetworks (package 25e)", 1)
for k, art in ARTS.items():
    block = '\t"%s": [\n' % k + "".join('\t\t"%s",\n' % r for r in art) + "\t],\n"
    if '\t"%s": [' % k in s:
        i = s.index('\t"%s": [' % k)
        j = s.index('\t],\n', i) + 4
        s = s[:i] + block + s[j:]
    else:
        i = s.index('\t# FORGE_END\n')
        s = s[:i] + block + s[i:]
open(p, "w", encoding="utf-8", newline="").write(s)
print("forge art ok")
