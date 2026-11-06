import os, sys
os.chdir(r"C:\Users\Luca\OneDrive\Dokumente\My Games\Sternfeld5.0")
# Maison Aurelle ships: long, smooth ivory hulls, gold trim, rows of lit windows.
# Chars: J pearl highlight, I ivory, j ivory shadow, U gold, u champagne, v window band, V lit window,
#        c/C glass, e nozzle, f glow, a owner colour


def interp(pts, x):
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        if x0 <= x <= x1:
            t = (x - x0) / max(x1 - x0, 1)
            # smooth (cosine) easing for elegant curves
            import math
            t = (1 - math.cos(t * math.pi)) / 2
            return y0 + (y1 - y0) * t
    return 0


def build(W, H, profile, decks=(), feature=None):
    hh = []
    for x in range(W):
        h = interp(profile, x)
        for (x0, x1, top, rnd) in decks:
            if x0 <= x <= x1:
                # rounded ends: lose one level per `rnd` columns near the ends
                edge = min(x - x0, x1 - x)
                h = max(h, top - max(0, rnd - edge) // max(rnd // 2, 1) if rnd else top)
        hh.append(int(round(h)))
    rows = [["."] * W for _ in range(H)]
    for x in range(W):
        for k in range(0, min(hh[x], H - 1) + 1):
            r = H - 1 - k
            ch = "I"
            if k == hh[x]:
                ch = "J"
            if feature:
                ch = feature(x, k, hh, ch)
            rows[r][x] = ch
    out = ["".join(r).rstrip(".") for r in rows]
    while out and out[0] == "":
        out.pop(0)
    return out


def win(x, period=3, gap=0):
    return "v" if x % period == gap else "V"


# ---------------- Pearl (S): a small, very fast luxury yacht
def pearl_f(x, k, hh, ch):
    if x <= 1 and k <= 2:
        return "f" if x == 0 else "e"
    if k == hh[x]:
        return "u" if 4 <= x <= 9 and k >= 5 else ch
    if 19 <= x <= 27 and k in (3, 4):
        return "C" if (x + k) % 4 == 0 else "c"
    if k == 2 and 3 <= x <= 30:
        return "U"
    if k == 3 and 7 <= x <= 17:
        return win(x)
    if 10 <= x <= 12 and k == 1:
        return "a"
    return ch


pearl = build(34, 8, [(0, 3), (2, 4), (6, 5), (20, 5), (26, 4), (30, 2), (33, 0)],
              decks=[(4, 9, 6, 0)], feature=pearl_f)


# ---------------- Boulevard (M): the liner / shuttle – long, two rows of windows
def boul_f(x, k, hh, ch):
    if x <= 1 and k <= 4:
        return "f" if x == 0 else "e"
    if k == hh[x]:
        return ch
    if 45 <= x <= 51 and k in (5, 6):
        return "C" if (x + k) % 4 == 0 else "c"
    if k == 7 and 6 <= x <= 42:
        return "u"
    if k in (6, 4) and 5 <= x <= 43:
        return win(x)
    if k == 2 and 2 <= x <= 50:
        return "U"
    if 6 <= x <= 9 and k == 1:
        return "a"
    return ch


boulevard = build(54, 10, [(0, 6), (2, 7), (5, 8), (40, 8), (46, 7), (50, 5), (53, 2)],
                  decks=[(8, 40, 9, 4)], feature=boul_f)


# ---------------- Opal (M): sleek liner with a glass lounge, a sweeping gold line
def opal_f(x, k, hh, ch):
    if x <= 1 and k <= 4:
        return "f" if x == 0 else "e"
    if 25 <= x <= 35 and k >= 9:
        return "C" if (x + k) % 3 == 0 else "c"
    if k == hh[x]:
        return ch
    sweep = round(6.5 - 5.5 * x / 57)
    if k == sweep and 3 <= x <= 54:
        return "U"
    if k == sweep + 1 and 3 <= x <= 52:
        return "u"
    if k == 7 and 8 <= x <= 44 and k > sweep + 1:
        return win(x, 2)
    if 47 <= x <= 53 and k in (4, 5) and k > sweep + 1:
        return "C" if (x + k) % 4 == 0 else "c"
    if 5 <= x <= 7 and k == 1:
        return "a"
    return ch


opal = build(58, 11, [(0, 5), (3, 6), (10, 7), (20, 8), (38, 8), (46, 7), (51, 5), (55, 2), (57, 1)],
             decks=[(22, 38, 10, 4)], feature=opal_f)


# ---------------- Empress (L): the megaliner – stacked decks, lit windows, glass dome
def emp_f(x, k, hh, ch):
    if x <= 2 and k <= 7:
        if k in (3, 7):
            return "d" if x < 2 else "I"
        return "f" if x == 0 else "e" if x == 1 else "j"
    if 50 <= x <= 62 and k >= 14:
        return "C" if (x + k) % 3 == 0 else "c"
    if k == hh[x]:
        return "u" if x >= 106 else ch
    if k == 10 and 12 <= x <= 94:
        return "U"                                   # gold trim between hull and decks
    if k in (12, 13) and hh[x] > k:
        return win(x, 4)
    if k == 11 and 14 <= x <= 92:
        return win(x, 3)
    if k in (8, 6) and 5 <= x <= 96:
        return win(x, 3 if k == 8 else 2)
    if k == 3 and 3 <= x <= 105:
        return "U"
    if k == 4 and 3 <= x <= 103:
        return "u"
    if 98 <= x <= 104 and k in (6, 7):
        return "C" if (x + k) % 4 == 0 else "c"   # the bridge glass in the bow
    if 6 <= x <= 10 and k == 1:
        return "a"
    return ch


empress = build(112, 17, [(0, 8), (3, 9), (8, 10), (92, 10), (99, 8), (104, 5), (109, 2), (111, 1)],
                decks=[(12, 94, 12, 6), (24, 84, 13, 6), (36, 74, 14, 6), (48, 64, 15, 4)], feature=emp_f)

ARTS = {"aur_pearl": pearl, "aur_boulevard": boulevard, "aur_opal": opal}   # the Empress: empress_art.py
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
        i = s.index('\t# AURELLE_END\n')
        s = s[:i] + block + s[i:]
open(p, "w", encoding="utf-8", newline="").write(s)
print("art ok")
