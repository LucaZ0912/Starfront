import os, sys, math, random
os.chdir(r"C:\Users\Luca\OneDrive\Dokumente\My Games\Sternfeld5.0")
# Empress (full art, not mirrored): narrow window sides, gold stripes, and between them a long park
# deck under a glass dome – lawn, trees, a pool with sun loungers. Animated in PixelArt (water, glint).
W, H = 116, 33
CY = 16
PROFILE = [(0, 10), (3, 12), (8, 14), (14, 15), (92, 15), (100, 13), (106, 9), (111, 5), (115, 2)]
DECK = (14, 94)
SHADE = {"J": "I", "I": "j", "u": "U"}


def interp(pts, x):
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        if x0 <= x <= x1:
            t = (x - x0) / max(x1 - x0, 1)
            t = (1 - math.cos(t * math.pi)) / 2
            return y0 + (y1 - y0) * t
    return 0


hh = [int(round(interp(PROFILE, x))) for x in range(W)]
rng = random.Random(7)
trees = []
for zone in [(18, 44), (74, 92)]:
    for i in range(14):
        trees.append((rng.uniform(*zone), rng.uniform(-8.0, 8.0), rng.choice([1.5, 1.9, 2.3, 2.8])))
flowers = {(rng.randrange(16, 93), rng.randrange(-9, 10)): rng.choice('ry') for _ in range(40)}
trees.append((90, 0, 1.6))


def park_limit(x):
    e = min(x - DECK[0], DECK[1] - x)
    if e < 0:
        return -1
    return 10 - [3, 2, 1, 1][e] if e < 4 else 10


def cell(x, k):
    a = abs(k)
    if a > hh[x]:
        return "."
    d = hh[x] - a
    if x <= 2 and a <= 9:
        if a in (0, 4, 8, 9):
            return "d" if x < 2 else "I"
        return "f" if x == 0 else ("e" if x == 1 else "j")
    if d == 0:
        return "u" if x >= 112 else "J"
    lim = park_limit(x)
    if lim >= 0 and a <= lim:
        if a == lim:
            return "c"                                   # rim of the glass dome
        if x % 10 == 4:
            return "q"                                   # glass ribs
        if 50 <= x <= 68 and a <= 3 and not (a == 3 and x in (50, 68)):
            return "P"                                   # pool
        if 47 <= x <= 71 and a <= 5:
            if a == 5 and x % 3 == 1 and 49 <= x <= 69:
                return "u"                               # sun loungers
            return "I"                                   # pool deck
        for (tx, tk, r) in trees:
            dd = math.hypot(x - tx, (k - tk) * 1.1)
            if dd <= r:
                return "t" if (x - tx) + (k - tk) > 0.3 else "T"
        if k == 0:
            return "I"                                   # promenade
        if (x, k) in flowers:
            return flowers[(x, k)]
        return "n"                                       # lawn
    if d == 1:
        return "I"
    if d == 2:
        return "v" if x % 3 == 0 else "V"                # one row of cabin windows
    if d == 3:
        return "u"
    if d == 4 and 4 <= x <= 108:
        return "U"                                       # gold stripe
    if x >= 99 and a <= 3:
        return "C" if (x + a) % 4 == 0 else "c"          # bridge glass in the bow
    if 5 <= x <= 8 and a <= 1:
        return "a"
    return "I"


rows = []
for y in range(H):
    k = CY - y
    r = ""
    for x in range(W):
        ch = cell(x, k)
        if k < 0 and not (park_limit(x) >= 0 and abs(k) <= park_limit(x)):
            ch = SHADE.get(ch, ch)
        r += ch
    rows.append(r.rstrip("."))

if "--show" in sys.argv:
    print("\n".join(rows))
    sys.exit()
p = "data/pixel_art.gd"
s = open(p, encoding="utf-8", newline="").read()
i = s.index('\t"aur_empress": [')
j = s.index('\t],\n', i) + 4
s = s[:i] + '\t"aur_empress": [\n' + "".join('\t\t"%s",\n' % r for r in rows) + "\t],\n" + s[j:]
open(p, "w", encoding="utf-8", newline="").write(s)
print("empress ok")
