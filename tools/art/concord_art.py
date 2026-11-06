"""Concord Fleetworks (package 25e): close to Earthworks, but more modern – and built around their drones:
side pods and flight wings with clearly visible hangar doors. Painted in the owner's colours (h/H/d/D/a),
like Earthworks ships. Prints the hatch rectangles of every hangar door (full, mirrored image).

Run: python tools/art/concord_art.py [--show]
"""
import os, sys
ROOT = os.path.join(os.path.dirname(__file__), "..", "..")


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.g = [["."] * w for _ in range(h)]

    def put(self, x, y, ch):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.g[y][x] = ch

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

    def pod(self, x0, y0, x1, y1, fill="d", edge="H", bottom="D"):
        h = y1 - y0 + 1
        r = 2 if h >= 5 else 1
        for y in range(y0, y1 + 1):
            d = min(y - y0, y1 - y)
            cut = max(0, r - d)
            for x in range(x0 + cut, x1 - cut + 1):
                ch = fill
                if y == y0:
                    ch = edge
                elif y == y1:
                    ch = bottom
                self.put(x, y, ch)


def bay(c, x0, y0, w, h, doors):
    """A hangar door: dark frame, plated door (painted on – the game slides it open)."""
    c.rect(x0 - 1, y0 - 1, x0 + w, y0 + h, "D")
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            c.put(x, y, "h" if (y - y0) % 2 == 0 else "d")
    c.put(x0 - 1, y0 - 1, "a")                           # a guide light in the owner's colour
    doors.append([x0, y0, w, h])


def engines(c, x0, ys):
    for y in ys:
        c.put(x0, y, "f")
        c.put(x0 + 1, y, "e")


def finish(c, doors):
    """Rows of the top half (leading empty rows removed) and the hatch rectangles of the full image."""
    rows = ["".join(r).rstrip(".") for r in c.g]
    off = 0
    while rows and rows[0] == "":
        rows.pop(0)
        off += 1
    n = len(rows)
    full_h = 2 * n - 1
    hatches = {}
    k = 1
    for (x, y, w, h) in doors:
        y -= off
        top = [x, y, w, h]
        bottom = [x, full_h - 1 - (y + h - 1), w, h]
        hatches["drones" if k == 1 else "drones_%d" % k] = top
        hatches["drones_%d" % (k + 1)] = bottom
        k += 2
    return rows, hatches


# ---------------- Demos (S militia ship): a light hull, two side pods with one hangar door each
def demos():
    W, H = 37, 9
    c = Canvas(W, H)
    cy = H - 1
    doors = []
    c.rect(5, 5, 27, cy, "h", "H")                       # hull
    for y, x1 in [(5, 29), (6, 31), (7, 33), (8, 35)]:
        c.hline(28, x1, y, "h")
        c.put(x1, y, "H")
    c.hline(26, 30, 7, "c")
    c.hline(27, 32, 8, "c")
    c.put(31, 8, "C")
    c.hline(9, 22, 6, "a")
    c.pod(8, 1, 24, 4, "d", "H", "D")                    # side pod
    c.hline(25, 28, 3, "g")                              # its light gun
    bay(c, 12, 2, 6, 2, doors)
    c.rect(3, 5, 4, cy, "d")
    engines(c, 3, [5, 6, 7, 8])
    engines(c, 6, [2, 3])
    return finish(c, doors)


# ---------------- Quirinus (M patrol ship): a longer hull, two pods with two hangar doors each
def quirinus():
    W, H = 58, 12
    c = Canvas(W, H)
    cy = H - 1
    doors = []
    c.rect(5, 6, 44, cy, "h", "H")
    for y, x1 in [(6, 46), (7, 48), (8, 50), (9, 52), (10, 54), (11, 56)]:
        c.hline(45, x1, y, "h")
        c.put(x1, y, "H")
    c.hline(44, 49, 10, "c")
    c.hline(45, 52, 11, "c")
    c.put(50, 11, "C")
    for x in (16, 28, 38):
        c.vline(x, 7, cy, "d")
    c.hline(10, 40, 8, "a")
    c.pod(8, 1, 42, 5, "d", "H", "D")
    bay(c, 13, 2, 7, 2, doors)
    bay(c, 25, 2, 7, 2, doors)
    c.rect(36, 2, 39, 3, "w")
    c.hline(43, 48, 2, "g")
    c.rect(3, 6, 4, cy, "d")
    engines(c, 3, [6, 7, 9, 10, 11])
    c.rect(6, 2, 8, 4, "d")
    engines(c, 6, [2, 3, 4])
    c.put(42, 2, "d")
    return finish(c, doors)


# ---------------- Concordia (L flagship): a long carrier – broad flight wings with three hangar doors
# each, one big gun on the spine, a sensor array, strong shields
def concordia():
    W, H = 114, 18
    c = Canvas(W, H)
    cy = H - 1
    doors = []
    c.rect(6, 11, 96, cy, "h", "H")                      # the spine
    for y, x1 in [(11, 98), (12, 100), (13, 102), (14, 104), (15, 106), (16, 108), (17, 110)]:
        c.hline(97, x1, y, "h")
        c.put(x1, y, "H")
    for x in (20, 36, 52, 68, 84):
        c.vline(x, 12, cy, "d")
    c.pod(12, 2, 84, 10, "d", "H", "D")                  # the flight wing
    c.hline(16, 80, 4, "a")
    for bx in (20, 40, 60):
        bay(c, bx, 6, 10, 3, doors)
    for x in range(18, 82, 4):
        c.put(x, 9, "S")                                 # deck lights
    c.rect(86, 13, 94, cy, "w", "H")                     # the big gun
    c.hline(95, 113, cy, "g")
    c.hline(95, 110, cy - 1, "g")
    c.rect(60, 12, 74, 14, "s", "S")                     # the sensor array
    c.hline(62, 72, 13, "S")
    c.hline(98, 103, 14, "c")                            # bridge
    c.hline(99, 106, 15, "c")
    c.put(104, 15, "C")
    c.hline(22, 50, 16, "a")
    c.rect(2, 11, 5, cy, "d")
    engines(c, 2, [11, 12, 14, 15, 17])
    c.rect(8, 3, 11, 9, "d")
    engines(c, 8, [4, 5, 7, 8])
    return finish(c, doors)


ARTS = {"cfw_demos": demos(), "cfw_quirinus": quirinus(), "cfw_concordia": concordia()}
if "--show" in sys.argv:
    for k, (a, h) in ARTS.items():
        print(k, h)
        print("\n".join(a))
        print()
    sys.exit()
p = os.path.join(ROOT, "data", "pixel_art.gd")
s = open(p, encoding="utf-8", newline="").read()
if "# CONCORD_END" not in s:
    s = s.replace("\t# Hadrian Dynamics (package 25d)", "\t# Concord Fleetworks (package 25e) – generated by tools/art/concord_art.py: owner colours, hangar doors\n\t# CONCORD_END\n\t# Hadrian Dynamics (package 25d)", 1)
for k, (art, _h) in ARTS.items():
    block = '\t"%s": [\n' % k + "".join('\t\t"%s",\n' % r for r in art) + "\t],\n"
    if '\t"%s": [' % k in s:
        i = s.index('\t"%s": [' % k)
        j = s.index('\t],\n', i) + 4
        s = s[:i] + block + s[j:]
    else:
        i = s.index('\t# CONCORD_END\n')
        s = s[:i] + block + s[i:]
open(p, "w", encoding="utf-8", newline="").write(s)
for k, (_a, h) in ARTS.items():
    print(k, h)
print("concord art ok")
