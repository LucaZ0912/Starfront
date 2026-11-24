import math, os, re, sys
os.chdir(r"C:\Users\Luca\OneDrive\Dokumente\My Games\Sternfeld5.0")
import random, struct, zlib

# Package 63: the four new ships (top half, the game mirrors it). Without arguments: writes them into
# data/pixel_art.gd. --show prints them, --mock renders the comparison sheets into Claude outputs.
# New chars: i/%/W obsidian (base / mid / edge), = pulsing gold, +/-/_ chrome (bright / mid / dark)


def interp(pts, x):
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        if x0 <= x <= x1:
            t = (x - x0) / max(x1 - x0, 1)
            t = (1 - math.cos(t * math.pi)) / 2
            return y0 + (y1 - y0) * t
    return 0


def build(W, H, px):
    rows = []
    for r in range(H):
        k = H - 1 - r
        rows.append("".join(px(x, k) for x in range(W)))
    return rows


# ---------------- Earthworks 190SL: the scout of the intro, brought up to date and chromed
def sl(x, k):
    # engine pods on the wing tips
    if 9 <= k <= 11:
        if x == 0:
            return "f" if k == 10 else "."
        if x == 1:
            return "e"
        if x == 2:
            return "_"
        if 3 <= x <= 12:
            if x >= 11:
                return "+" if k >= 10 else "-"
            if x == 8:
                return "U"
            return "+" if k == 11 else "I" if k == 10 else "j"
        if x == 13 and k == 10:
            return "+"
    # the wing
    if 4 <= k <= 8:
        le = 17 - (k - 3) * 9 / 6.0
        te = 6 - (k - 3) * 3 / 6.0
        if te <= x <= le:
            if x >= le - 1:
                return "+"
            if k in (4, 5) and 9 <= x <= 12:
                return "g" if x % 2 == 0 else "w"
            return "I" if x > te + 1 else "j"
    # the hull
    if 4 <= x <= 31:
        hw = 3 if x <= 20 else int(round(3 * (31 - x) / 11.0))
        if k <= hw:
            if x == 4:
                return "_"
            if x == 5:
                return "-"
            if 22 <= x <= 26 and k < max(hw, 1) and k <= 1:
                return "C" if (x, k) in ((24, 1), (25, 0)) else "c"
            if k == hw:
                return "+"
            if k == 0 and 7 <= x <= 20:
                return "a" if 9 <= x <= 12 else "U"
            if k == 2 and 6 <= x <= 17:
                return "u"
            return "I"
    if x == 3 and k <= 2:
        return "e"
    if x == 2 and k <= 1:
        return "f"
    return "."


# ---------------- Mistral: the racer, a needle between two oversized engines
def mistral(x, k):
    # a long ogive bow in the owner's colour that fades in dots into ivory; aft the hull splits into two blades
    # and a spine, the machinery open between them; an engine at the end of each
    bow = 21
    if x >= bow:
        hw = int(round(6.4 * (1 - ((x - bow) / 25.0) ** 1.7)))
        if x > 46 or k > hw:
            return "."
        if 37 <= x <= 39 and k == 0:
            return "C" if x == 38 else "c"
        if k == 2 and 24 <= x <= 40 and k < hw:
            return "J"                                  # a fine white line along the bow
        if x >= 31:
            col = True
        elif x >= 27:
            col = (x + k) % 2 == 0
        elif x >= 23:
            col = x % 2 == 0 and k % 2 == 0
        else:
            col = False
        if col:
            return "a"
        return "J" if k == hw else "I"
    # the blades
    top = 7 if x <= 14 else 6
    if 3 <= x < bow and top - 2 <= k <= top:
        if x == 3:
            return "U"
        if k == top - 1 and 5 <= x <= 17:
            return "a"
        return "J" if k == top else "I" if k == top - 1 else "j"
    if x == 2 and top - 2 <= k <= top:
        return "e"
    if x <= 1 and 5 <= k <= 7:
        return "f" if k == 6 or x == 1 else "."
    # the spine
    if 6 <= x < bow and k <= 1:
        if x == 6:
            return "U"
        return "a" if k == 0 and x >= 9 else "I"
    if x == 5 and k <= 1:
        return "e"
    if x in (3, 4) and k <= 1:
        return "f" if k == 0 or x == 4 else "."
    # the machinery between
    if 8 <= x < bow and 2 <= k < top - 2:
        if x % 5 == 0:
            return "U"
        return "g" if (x + k) % 3 == 0 else "x"
    return "."


# ---------------- Soleil (M): an obsidian flying wing – long swept wings, two engine nacelles on each, glass
def _pod(x, k, x0, x1, kc):
    """a nacelle: a teardrop from x0 (its bell) to x1 (its tip) round the row kc"""
    if not (x0 <= x <= x1 and abs(k - kc) <= 1):
        return None
    if x == x0:
        return "f"
    if x == x0 + 1:
        return "e"
    if x >= x1 - 1 and k != kc:
        return None
    if x == x1:
        return "u"
    if x == x1 - 4:
        return "U"
    if k == kc:
        return "=" if x < x1 - 4 else "W"
    return "W" if k > kc else "%"


def soleil(x, k):
    for (x0, x1, kc) in ((10, 33, 8), (8, 26, 14)):
        p = _pod(x, k, x0, x1, kc)
        if p:
            return p
    # the body
    if 12 <= x <= 51:
        hw = int(round(interp([(12, 2), (18, 4), (32, 4), (44, 2), (51, 0)], x)))
        if k <= hw:
            if x == 12:
                return "e"
            if 36 <= x <= 44 and k < max(hw, 1) and k <= 2:
                return "C" if (x - k) % 4 == 0 else "c"
            if 18 <= x <= 32 and k <= 1:
                return "U" if x in (18, 32) else "q" if x % 5 == 0 else "C" if (x + k) % 6 == 0 else "c"
            if k == 2 and 18 <= x <= 32:
                return "U"
            if k == hw:
                return "W"
            if k == 0 and 45 <= x <= 50:
                return "="
            if k == 1 and 14 <= x <= 16:
                return "a"
            return "%" if k == hw - 1 else "i"
    if x == 11 and k <= 1:
        return "f"
    # the wing
    if 3 <= k <= 23:
        le = 39 - (k - 3) * 1.45
        te = 16 - (k - 3) * 0.7
        if te <= x <= le:
            if x >= le - 1:
                return "W"
            if x >= le - 2.6:
                return "="                              # a gold line just behind the leading edge
            if x <= te + 1:
                return "%"
            if k == 23:
                return "u"
            if k in (5, 11, 17) and x < le - 4:
                return "%"                              # panel seams
            return "i"
    return "."


# ---------------- Sovereign (L): a long obsidian blade; a ring round her stern carries the engines
V_PROF = [(10, 5), (18, 7), (34, 9), (56, 7), (80, 4), (100, 2), (111, 0)]


def sovereign(x, k):
    hh = int(round(interp(V_PROF, x))) if 10 <= x <= 111 else -1
    # the engines on the ring
    p = _pod(x, k, 8, 32, 18)
    if p:
        return p
    if k <= hh:
        if x == 10:
            return "e" if k % 3 != 2 else "i"
        # a glass spine from the ring forward
        if 40 <= x <= 78 and k <= 3:
            lim = 3 if x <= 66 else int(round(3 * (78 - x) / 12.0))
            if k <= lim:
                if k == lim or x == 40:
                    return "U"
                if x % 7 == 0:
                    return "q"
                if 50 <= x <= 58 and k <= 1:
                    return "p" if (x + 2 * k) % 5 == 0 else "P"
                return "C" if (x - k) % 8 == 0 else "c"
        if 86 <= x <= 95 and k <= 1 and k < hh:
            return "C" if (x - k) % 4 == 0 else "c"
        # the lounge under glass inside the ring
        dl = ((x - 24) / 8.0) ** 2 + (k / 4.6) ** 2
        if dl <= 1.0:
            if dl > 0.68:
                return "U"
            return "V" if (x + k) % 5 == 0 else "C" if (x - k) % 4 == 0 else "c"
        if k == hh:
            return "W"
        if k == hh - 2 and 14 <= x <= 104:
            return "="
        if k == hh - 1 and 60 <= x <= 98 and x % 4 == 0:
            return "V"                                  # a row of lights down her bow
        if k == 0 and 98 <= x <= 109:
            return "="
        if k == 5 and 41 <= x <= 56 and k < hh - 2:
            return "C" if x % 3 == 0 else "c"
        if k == 1 and 13 <= x <= 15:
            return "a"
        return "%" if k == hh - 1 else "i"
    if x == 9 and k <= 4 and k % 3 != 2:
        return "f"
    # the ring
    d = math.hypot(x - 24, k)
    if 14.4 <= d <= 18.4:
        if d >= 17.5:
            return "W"
        if 15.7 <= d < 16.6:
            return "="
        return "%" if d < 15.2 else "i"
    # two spokes from the hull out to the ring
    if hh < k < 16 and (abs(x - 17 + (k - 7) * 0.3) < 1.0 or abs(x - 31 - (k - 9) * 0.3) < 1.0):
        return "W" if k % 4 == 0 else "%"
    return "."


ARTS = {
    "ew_190sl": build(32, 12, sl),
    "aur_mistral": build(47, 8, mistral),
    "aur_soleil": build(52, 24, soleil),
    "aur_sovereign": build(112, 20, sovereign),
}
for k_, a_ in ARTS.items():
    w_ = max(len(r.rstrip(".")) for r in a_)
    ARTS[k_] = [r[:w_].rstrip(".") for r in a_]

if "--show" in sys.argv:
    for k_, a_ in ARTS.items():
        print(k_)
        print("\n".join(a_))
        print()
    sys.exit()

if "--mock" not in sys.argv:
    p = "data/pixel_art.gd"
    g = open(p, encoding="utf-8", newline="").read()
    for k_, art_ in ARTS.items():
        block = '\t"%s": [\n' % k_ + "".join('\t\t"%s",\n' % r for r in art_) + "\t],\n"
        if '\t"%s": [' % k_ in g:
            a_ = g.index('\t"%s": [' % k_)
            b_ = g.index('\t],\n', a_) + 4
            g = g[:a_] + block + g[b_:]
        else:
            a_ = g.index('\t# PACKAGE63_END\n')
            g = g[:a_] + block + g[a_:]
    open(p, "w", encoding="utf-8", newline="").write(g)
    print("art ok")
    sys.exit()

# ------------------------------------------------------------------ the picture
src = open("scripts/core/pixel_art.gd", encoding="utf-8").read()
PAL = {}
for m in re.finditer(r'"(.)": Color\(([0-9., ]+)\)', src[:src.index("const SHADE_DOWN")]):
    v = [float(t) for t in m.group(2).split(",")][:3]
    if m.group(1) not in PAL or m.start() < src.index("const FACTION"):
        PAL[m.group(1)] = tuple(v)
pl = src[src.index('"player":'):src.index('"khi_drone"')]
for m in re.finditer(r'"(.)": Color\(([0-9., ]+)\)', pl):
    PAL[m.group(1)] = tuple(float(t) for t in m.group(2).split(","))[:3]
PAL.update({"i": (0.085, 0.085, 0.12), "%": (0.15, 0.155, 0.21), "W": (0.36, 0.38, 0.48),
            "+": (0.94, 0.97, 1.0), "-": (0.66, 0.73, 0.82), "_": (0.4, 0.46, 0.56), "=": (0.84, 0.63, 0.22)})
SHADE = {"H": "h", "h": "d", "d": "D", "J": "I", "I": "j", "u": "U", "+": "-", "-": "_", "%": "i"}
FULL = {"aur_empress"}
data = open("data/pixel_art.gd", encoding="utf-8").read()


def game_art(key):
    i = data.index('\t"%s": [' % key)
    j = data.index("\t],", i)
    return re.findall(r'"([^"]*)",', data[i + len(key) + 5:j])



def image(key, rows, f=0, n=24):
    """-> dict (x, y) -> rgb, width, height (with the outline)"""
    w = max(len(r) for r in rows)
    rows = [r.ljust(w, ".") for r in rows]
    if key not in FULL:
        rows = rows + ["".join(SHADE.get(c, c) for c in r) for r in rows[-2::-1]]
    h = len(rows)
    px = {}
    for y, r in enumerate(rows):
        for x, c in enumerate(r):
            if c == ".":
                continue
            col = PAL.get(c, (1, 0, 1))
            if c == "=":
                t = (0.5 + 0.5 * math.sin(x * 0.3 - f * math.tau / n)) ** 3
                lo, hi = (0.5, 0.33, 0.08), (1.0, 0.93, 0.62)
                col = tuple(lo[q] + (hi[q] - lo[q]) * t for q in range(3))
            px[(x + 1, y + 1)] = tuple(int(round(v * 255)) for v in col)
    oc = tuple(int(round(v * 255)) for v in PAL["o"])
    solid = set(px)
    for y in range(h + 2):
        for x in range(w + 2):
            if (x, y) not in solid and any((x + a, y + b) in solid for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                px[(x, y)] = oc
    return px, w + 2, h + 2


class Canvas:
    def __init__(self, w, h, seed=7):
        self.w, self.h = w, h
        self.b = bytearray(bytes((7, 9, 18)) * (w * h))
        rnd = random.Random(seed)
        for _ in range(w * h // 5200):
            x, y, v = rnd.randrange(w - 2), rnd.randrange(h - 2), rnd.choice((70, 95, 130, 190))
            for a in (0, 1):
                for c in (0, 1):
                    self.put(x + a, y + c, (v, v, min(255, v + 25)))

    def put(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            i = (y * self.w + x) * 3
            self.b[i:i + 3] = bytes(c)

    def blit(self, img, x0, y0, z):
        px, w, h = img
        for (x, y), c in px.items():
            row = bytes(c) * z
            for dy in range(z):
                i = ((y0 + y * z + dy) * self.w + x0 + x * z) * 3
                self.b[i:i + 3 * z] = row

    def bar(self, x0, y0, w, h, c):
        for y in range(y0, y0 + h):
            for x in range(x0, x0 + w):
                self.put(x, y, c)

    def save(self, path):
        raw = b"".join(b"\x00" + bytes(self.b[y * self.w * 3:(y + 1) * self.w * 3]) for y in range(self.h))
        def chunk(t, d):
            return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
        open(path, "wb").write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", self.w, self.h, 8, 2, 0, 0, 0))
                               + chunk(b"IDAT", zlib.compress(raw, 6)) + chunk(b"IEND", b""))


def art(key):
    return ARTS[key] if key in ARTS else game_art(key)


Z = 6
out = "Claude outputs/schiffe_63_"
GOLD = (255, 205, 100)
# sheet 1: every new ship (a gold bar under it) beside today's ships of its size
ROWS = [["dragonfly", "aur_pearl", "ew_190sl", "aur_mistral"], ["aur_opal", "aur_soleil"], ["aur_empress", "aur_sovereign"]]
cv = Canvas(1920, 1100)
y = 40
for keys in ROWS:
    ims = [(k, image(k, art(k))) for k in keys]
    rh = max(i[1][2] for i in ims) * Z
    gap = (1920 - sum(i[1][1] * Z for i in ims)) // (len(ims) + 1)
    x = gap
    for k, im in ims:
        cv.blit(im, x, y + (rh - im[2] * Z) // 2, Z)
        if k in ARTS:
            cv.bar(x, y + rh + 14, im[1] * Z, 4, GOLD)
        x += im[1] * Z + gap
    y += rh + 70
cv.save(out + "vergleich.png")
# sheet 2: the four alone, large
for key, z in (("ew_190sl", 20), ("aur_mistral", 20), ("aur_soleil", 14), ("aur_sovereign", 12)):
    im = image(key, ARTS[key])
    c2 = Canvas(im[1] * z + 160, im[2] * z + 160, 3)
    c2.blit(im, 80, 80, z)
    c2.save(out + key.split("_")[1] + ".png")
# sheet 3: the pulse of the gold lines, four moments
sv = [image("aur_sovereign", ARTS["aur_sovereign"], q * 6) for q in range(4)]
so = [image("aur_soleil", ARTS["aur_soleil"], q * 6) for q in range(4)]
z3 = 7
step = max(sv[0][2], so[0][2]) * z3 + 30
c3 = Canvas(40 + sv[0][1] * z3 + 60 + so[0][1] * z3 + 40, 4 * step + 30, 5)
for q in range(4):
    c3.blit(sv[q], 40, 30 + q * step + (step - 30 - sv[q][2] * z3) // 2, z3)
    c3.blit(so[q], 40 + sv[0][1] * z3 + 60, 30 + q * step + (step - 30 - so[q][2] * z3) // 2, z3)
c3.save(out + "puls.png")
print("ok")
