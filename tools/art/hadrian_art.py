import os, sys, json
os.chdir(r"C:\Users\Luca\OneDrive\Dokumente\My Games\Sternfeld5.0")
# Hadrian Dynamics v2: brutalist armour, dark metal, few (red) lights, guns in plain view –
# rounded side parts, Goliath with arched arms, Citadel with launch platform, drone hatch and a choice of bridges.
# Chars: B steel edge, M gunmetal, N dark steel, X black seams/holes, R red light,
#        w weapon mount, g barrel, e/f engine, a owner colour. Top half incl. centre row (mirrored).


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

    def pod(self, x0, y0, x1, y1, fill="M", edge="B", bottom="N"):
        """A rounded capsule: corners cut (two pixels at the ends when it is tall)."""
        h = y1 - y0 + 1
        r = 2 if h >= 5 else 1
        for y in range(y0, y1 + 1):
            d = min(y - y0, y1 - y)
            cut = max(0, r - d)
            for x in range(x0 + cut, x1 - cut + 1):
                ch = fill
                if y == y0 or (x in (x0 + cut, x1 - cut) and y < (y0 + y1) / 2):
                    ch = edge
                elif y == y1:
                    ch = bottom
                self.put(x, y, ch)

    def rows(self):
        out = ["".join(r).rstrip(".") for r in self.g]
        while out and out[0] == "":
            out.pop(0)
        return out


def engines(c, x0, ys):
    for y in range(min(ys), max(ys) + 1):
        for x in range(x0, x0 + 3):
            if c.g[y][x] == ".":
                c.put(x, y, "N")
    for y in ys:
        c.put(x0, y, "f")
        c.put(x0 + 1, y, "e")
        c.put(x0 + 2, y, "X")


# ---------------- Talon (S dropship): an armour wedge, a rounded gun pod with a missile rack
def talon():
    W, H = 36, 9
    c = Canvas(W, H)
    cy = H - 1
    c.rect(4, 4, 26, cy, "M", "B")
    for x in (10, 16, 22):
        c.vline(x, 5, cy, "N")
    for y, x1 in [(5, 28), (6, 30), (7, 32), (8, 34)]:
        c.hline(27, x1, y, "M")
        c.put(x1, y, "B")
    c.put(27, 4, "B")
    c.pod(6, 0, 24, 3, "N", "B", "N")                    # rounded gun pod
    for x in range(9, 21, 2):
        c.put(x, 2, "X")                                 # missile rack
    c.hline(25, 31, 1, "g")
    c.hline(25, 29, 2, "g")
    c.hline(19, 23, 7, "R")
    c.hline(12, 14, cy, "a")
    engines(c, 1, [5, 6, 8])
    c.rect(1, 4, 3, 4, "N")
    return c.rows()


# ---------------- Maul (M gunboat): heavy block, a rounded armour skirt, a big turret on the spine
def maul():
    W, H = 54, 12
    c = Canvas(W, H)
    cy = H - 1
    c.rect(4, 5, 40, cy, "M", "B")
    for y, x1 in [(6, 42), (7, 44), (8, 46), (9, 48), (10, 49), (11, 50)]:
        c.hline(41, x1, y, "M")
        c.put(x1, y, "B")
    c.put(41, 5, "B")
    for x in (12, 20, 28, 36):
        c.vline(x, 6, cy, "N")
    c.pod(7, 0, 41, 4, "N", "B", "N")                    # rounded armour skirt with the side guns
    for x in range(11, 31, 3):
        c.put(x, 2, "X")
    c.rect(33, 1, 38, 3, "w")
    c.hline(42, 48, 1, "g")
    c.hline(42, 46, 3, "g")
    c.rect(22, 8, 32, cy, "w", "B")
    c.rect(24, 9, 30, cy, "N")
    c.hline(33, 53, cy, "g")
    c.hline(33, 51, cy - 1, "g")
    c.put(53, cy, "w")
    c.hline(42, 45, 8, "R")
    c.hline(14, 17, cy, "a")
    engines(c, 1, [6, 7, 9, 10])
    c.rect(1, 5, 3, 5, "N")
    return c.rows()


# ---------------- Goliath (M destroyer): two mighty arms that start far back and arch around the hull
GOL_W, GOL_H = 86, 21
GOL_PIVOT = (12, 12)            # the hinge of the arms (column, row of the top half): fixed contact at the stern


def goliath_body(c):
    """Hull, stern, the straight drive sections of the arms with their hinges, drone hatch, eye-slits."""
    cy = GOL_H - 1
    c.pod(8, 14, 60, cy + 4, "M", "B", "M")              # the hull: rounded stern, unchanged middle …
    for y, x1 in [(14, 61), (15, 64), (16, 67), (17, 70), (18, 73), (19, 76), (20, 79)]:
        c.hline(58, x1, y, "M")                          # … and a long spike at the front
        c.put(x1, y, "B")
    c.hline(62, 79, cy, "N")
    for x in (20, 40, 50):
        c.vline(x, 15, cy, "N")
    c.hline(14, 17, cy, "a")
    hx0, hy0, hx1 = GOL_HATCH                            # drone hatch on the spine
    c.rect(hx0 - 1, hy0 - 1, hx1 + 1, cy, "B")
    c.rect(hx0, hy0, hx1, cy, "M")
    for y in range(hy0 + 1, cy + 1, 2):
        c.hline(hx0, hx1, y, "N")
    c.vline(hx1, hy0, cy, "X")
    for k in range(15):                                  # the bridge: slanted red eye-slits under a brow
        x = 44 + k
        y = 15 + k // 5
        c.put(x, y - 1, "X")
        c.put(x, y, "R")
    c.put(59, 18, "R")
    # the straight drive section of each arm along the stern, fixed to the hull, ending in the hinge
    px, py = GOL_PIVOT
    for x in range(0, px + 1):
        for y in range(py - 2, py + 3):
            c.put(x, y, "B" if y == py - 2 else ("N" if y == py + 2 else "M"))
    for y in range(py - 1, py + 2):
        c.put(0, y, "f")
        c.put(1, y, "e")
    c.put(5, py, "X")
    c.put(8, py, "X")
    c.pod(px - 2, py - 3, px + 2, py + 3, "X", "B", "N")   # the hinge
    c.put(px, py, "B")


GOL_ARM_FRAMES = 8              # 0 = folded in (hangar bays), 7 = swung open in a round arc
GOL_OPEN_ROWS = 9               # extra rows above the hull canvas that the open arms reach into


def goliath_arm(c, s=0.0, dy=0):
    """The arm, morphed by s (0 closed … 1 open): from the hinge at the stern it rises – closed in a flat
    curve, open steeply and round like a circle – and carries the pincers further out the more it opens."""
    px, py = GOL_PIVOT
    peak = 3.5 - 8.0 * s                                 # how far out the arm reaches
    end_y = 9.5 - 5.5 * s                                # where the pincers sit
    xp = 30.0 - 4.0 * s                                  # where the arc tops out …
    xq = 44.0 - 10.0 * s                                 # … and starts to close in again

    def yc(x):
        if x < xp:
            t = (xp - x) / (xp - px)
            k = (1.0 - s) * t * t + s * (1.0 - (max(0.0, 1.0 - t * t)) ** 0.5)
            return peak + (py - peak) * k
        if x <= xq:
            return peak
        u = (x - xq) / (66.0 - xq)
        k2 = (1.0 - s) * u * u + s * (1.0 - (max(0.0, 1.0 - u * u)) ** 0.5)
        return peak + (end_y - peak) * k2
    for x in range(px + 1, 67):
        half = 3.0 if x >= px + 4 else 2.2 + 0.2 * (x - px)
        if x > 58:
            half = 3.0 - 0.12 * (x - 58)
        y0 = int(round(yc(x) - half))
        y1 = int(round(yc(x) + half))
        if x < px + 5:
            y1 = max(y1, py + 2)                         # stays joined to the hinge while it rises
        seg = (x - 8) % 7 == 0 and 14 < x < 60
        for y in range(y0, y1 + 1):
            ch = "M"
            if y == y0:
                ch = "B"
            elif y == y1:
                ch = "N"
            elif seg:
                ch = "X"
            c.put(x, y + dy, ch)
        if (x - 8) % 7 == 3 and 14 < x < 60:
            c.put(x, y0 + 1 + dy, "B")
    for x in (20, 52):
        c.put(x, int(round(yc(x))) + dy, "R")
    for x in (30, 40):                                   # point-defence turrets on the arms
        y = int(round(yc(x))) + dy
        c.rect(x - 1, y - 1, x + 2, y + 1, "w", "B")
        c.hline(x + 3, x + 5, y - 1, "g")
    gy = int(round(yc(62))) + dy                         # the pincers around a long cannon
    c.pod(57, gy - 4, 64, gy + 4, "M", "B", "N")
    c.rect(60, gy - 1, 64, gy + 1, "w")
    for k in range(12):
        t = k / 11.0
        yo = int(round(gy - 4 + 2.6 * t * t))
        yi = int(round(gy + 4 - 2.6 * t * t))
        x = 65 + k
        c.put(x, yo - 1, "B")
        c.put(x, yo, "M" if k < 10 else "B")
        c.put(x, yi, "M" if k < 10 else "N")
        c.put(x, yi + 1, "N")
    c.put(77, gy - 2, "R")
    c.put(77, gy + 2, "R")
    c.hline(65, 85, gy, "g")
    c.put(85, gy, "w")


def full_rows(c):
    """All rows at full width, none stripped – parts of one ship must line up exactly."""
    return ["".join(r) for r in c.g]


def goliath():
    """The scorpion (closed, as in menus and in the hangar bays): body + arms in one picture."""
    c = Canvas(GOL_W, GOL_H)
    goliath_body(c)
    goliath_arm(c)
    return full_rows(c)


def goliath_parts():
    """The hull alone and the arm in GOL_ARM_FRAMES stages from folded to open (on a taller canvas –
    the pictures are centred, so the extra rows only reach further out)."""
    b = Canvas(GOL_W, GOL_H)
    goliath_body(b)
    frames = []
    for i in range(GOL_ARM_FRAMES):
        a = Canvas(GOL_W, GOL_H + GOL_OPEN_ROWS)
        goliath_arm(a, i / (GOL_ARM_FRAMES - 1.0), GOL_OPEN_ROWS)
        frames.append(full_rows(a))
    return full_rows(b), frames


GOL_HATCH = (28, 16, 37)        # x0, top row, x1 of the Goliath's drone hatch


# ---------------- Citadel (L fleet carrier): a fortress with a launch platform and a drone hatch
CIT_W, CIT_H = 104, 19
PLATFORM = (36, 7, 64)          # x0, top row, x1 of the platform frame (to the centre row)
PLAT_HATCH = (43, 12, 57)       # x0, top row, x1 of the platform hatch
DRONE_HATCH = (20, 14, 27)      # x0, top row, x1 of the drone hatch


def bridge(c, v):
    cy = CIT_H - 1
    if v == "keep":          # a square keep with crenellations and arrow slits (like the rampart crest)
        c.rect(82, 9, 92, cy, "N", "B")
        for x in range(82, 93, 3):
            c.rect(x, 7, x + 1, 8, "N", "B")
        for x in (84, 87, 90):
            c.vline(x, 11, 13, "R")
    elif v == "tower":       # a stepped command tower with one long red visor
        c.rect(80, 12, 94, cy, "N", "B")
        c.rect(83, 9, 92, 11, "M", "B")
        c.rect(85, 7, 90, 8, "M", "B")
        c.hline(81, 93, 14, "R")
        c.hline(84, 91, 10, "X")
    elif v == "dome":        # an armoured half dome with a ring of red slits
        for y in range(9, cy + 1):
            d = cy - y
            half = int(round((max(0, 90 - d * d)) ** 0.5))
            for x in range(87 - half, 87 + half + 1):
                c.put(x, y, "B" if y == 9 or x in (87 - half, 87 + half) else "N")
        for x, y in [(81, 14), (83, 12), (87, 11), (91, 12), (93, 14)]:
            c.put(x, y, "R")
    elif v == "prow":        # the bridge in a stepped prow: a red chevron of windows
        for i in range(8):
            c.put(86 + i, 11 + i, "R")
            c.put(85 + i, 11 + i, "X")
            c.put(87 + i, 11 + i, "N")
        c.rect(80, 11, 84, cy, "N", "B")


def citadel(bv="keep"):
    W, H = CIT_W, CIT_H
    c = Canvas(W, H)
    cy = H - 1
    c.rect(8, 4, 84, cy, "M", "B")
    for x in range(10, 84, 6):                           # crenellations of the rampart
        c.rect(x, 2, x + 2, 3, "M", "B")
    for y, x1 in [(5, 86), (6, 88), (7, 90), (8, 92), (9, 93), (10, 94), (11, 95), (12, 96), (13, 97),
                  (14, 98), (15, 99), (16, 100), (17, 101), (18, 102)]:
        c.hline(85, x1, y, "M")
        c.put(x1, y, "B")
    c.put(85, 4, "B")
    c.hline(10, 82, 6, "N")
    for x in range(12, 84, 10):
        c.vline(x, 7, cy, "N")
    # the launch platform: a big pad framed in steel, red corner lights, a row of guide marks, the hatch
    px0, py0, px1 = PLATFORM
    c.rect(px0, py0, px1, cy, "N", "B")
    c.vline(px0, py0, cy, "B")
    c.vline(px1, py0, cy, "B")
    c.put(px0 + 1, py0 + 1, "R")
    c.put(px1 - 1, py0 + 1, "R")
    for x in range(px0 + 3, px1 - 2, 2):
        c.put(x, py0 + 2, "X")
    hx0, hy0, hx1 = PLAT_HATCH
    c.rect(hx0 - 1, hy0 - 1, hx1 + 1, cy, "B")
    c.rect(hx0, hy0, hx1, cy, "M")
    for y in range(hy0 + 1, cy + 1, 2):
        c.hline(hx0, hx1, y, "N")                        # hatch plates
    c.vline(hx1, hy0, cy, "X")
    # the drone hatch behind it
    dx0, dy0, dx1 = DRONE_HATCH
    c.rect(dx0 - 1, dy0 - 1, dx1 + 1, cy, "B")
    c.rect(dx0, dy0, dx1, cy, "M")
    for y in range(dy0 + 1, cy + 1, 2):
        c.hline(dx0, dx1, y, "N")
    c.vline(dx1, dy0, cy, "X")
    c.put(dx0 - 2, dy0, "R")
    # point-defence towers and forward guns
    for tx in (30, 68, 76):
        c.rect(tx, 0, tx + 4, 3, "w", "B")
        c.hline(tx + 5, tx + 8, 1, "g")
    bridge(c, bv)
    c.hline(10, 14, cy, "a")
    engines(c, 5, [6, 7, 9, 10, 12, 13, 15, 16])
    c.rect(5, 4, 7, 5, "N")
    c.rect(5, 17, 7, 18, "N")
    return c.rows()


BRIDGE = "dome"                 # chosen by Luz (0.4.25.19); the other bridges are kept as variants
if "--bridge" in sys.argv:
    BRIDGE = sys.argv[sys.argv.index("--bridge") + 1]
_gb, _ga = goliath_parts()
ARTS = {"hdy_talon": talon(), "hdy_maul": maul(), "hdy_goliath": goliath(), "hdy_goliath_body": _gb,
        "hdy_citadel": citadel(BRIDGE)}
for _i, _f in enumerate(_ga):
    ARTS["hdy_goliath_arm_%d" % _i] = _f
VARIANTS = {"hdy_citadel": {v: citadel(v) for v in ["keep", "tower", "dome", "prow"]}}
if "--show" in sys.argv:
    for k, a in ARTS.items():
        print(k)
        print("\n".join(a))
        print()
    sys.exit()
p = "data/pixel_art.gd"
s = open(p, encoding="utf-8", newline="").read()
for k, art in ARTS.items():
    block = '\t"%s": [\n' % k + "".join('\t\t"%s",\n' % r for r in art) + "\t],\n"
    if '\t"%s": [' % k in s:
        i = s.index('\t"%s": [' % k)
        j = s.index('\t],\n', i) + 4
        s = s[:i] + block + s[j:]
    else:
        i = s.index('\t# HADRIAN_END\n')
        s = s[:i] + block + s[i:]
# design variants kept for later (not used in the game)
vb = "## Design variants kept for later (not used in the game): hull -> {variant: art}. The Citadel's\n"
vb += "## bridges (package 25d): keep (crenellated keep), tower (command tower), dome (armoured dome – in use),\n"
vb += "## prow (chevron in the bow).\nconst VARIANTS := {\n"
for hid, vs in VARIANTS.items():
    vb += '\t"%s": {\n' % hid
    for v, art in vs.items():
        vb += '\t\t"%s": [\n' % v + "".join('\t\t\t"%s",\n' % r for r in art) + "\t\t],\n"
    vb += "\t},\n"
vb += "}\n"
if "## Design variants kept for later" in s:
    i = s.index("## Design variants kept for later")
    s = s[:i] + vb
else:
    s = s.rstrip("\n") + "\n\n\n" + vb
open(p, "w", encoding="utf-8", newline="").write(s)
print("hdy art ok")
