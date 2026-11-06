import os
os.chdir(r"C:\Users\Luca\OneDrive\Dokumente\My Games\Sternfeld5.0")
W = 102
rows = [["."] * W for _ in range(15)]


def put(r, x, ch):
    if 0 <= x < W:
        rows[r][x] = ch


# ---- rear block (x 0..38): engines, stacks, hazard top, bridge at its front edge
for sx in (12, 18, 24):
    put(0, sx, "D"); put(0, sx + 1, "D")
    for r in (1, 2):
        put(r, sx, "D"); put(r, sx + 1, "d")
for x in range(10, 39):
    put(3, x, "Q")
for r in (4, 5):
    put(r, 10, "Q"); put(r, 38, "Q")
    for x in range(11, 38):
        put(r, x, "x" if (x + r) % 3 == 0 else "Y")
for r in range(6, 15):
    for x in range(0, 10):
        put(r, x, "f" if x < 4 else "e")
    put(r, 10, "Q")
    for x in range(11, 38):
        put(r, x, "Y")
    put(r, 38, "Q")
for x in range(12, 31):
    put(7, x, "L")
for x in range(16, 23):
    put(10, x, "a")
for x in range(14, 30):
    put(12, x, "k" if x % 5 else "Y")
    put(13, x, "K" if x % 5 else "Y")
# the bridge: the rounded, sloping glass front of the old design at the front of the block
EDGE = {3: 34, 4: 36, 5: 38, 6: 40, 7: 41}
for r, e in EDGE.items():
    for x in range(30, 45):
        put(r, x, ".")
    for x in range(10, e - 2):
        if r == 3:
            put(r, x, "Q")
        elif r in (4, 5):
            put(r, x, "Q" if x == 10 else ("x" if (x + r) % 3 == 0 else "Y"))
        else:
            put(r, x, "Q" if x == 10 else ("L" if r == 7 and x < 31 else "Y"))
    put(r, e - 2, "Q")
    put(r, e - 1, "c")
    put(r, e, "C")
for r in range(8, 15):
    put(r, 38, "Q")
# ---- flat flight deck (x 39..94), lower than the block
for x in range(39, 95):
    put(8, x, "Q")
    put(9, x, "x" if x % 3 == 0 else "Y")
    put(10, x, "G" if x % 8 == 3 else "d")
    for r in (11, 12, 13):
        put(r, x, "D")
    put(14, x, "y" if x % 5 < 2 else "D")
for lx in (46, 62, 78):                     # drone lifts
    for x in range(lx, lx + 6):
        for r in (11, 12):
            put(r, x, "w")
for x in (88, 89):
    put(7, x, "w")
put(7, 90, "g")
# ---- bow with the drill
for r, (x0, x1) in {10: (95, 95), 11: (95, 96), 12: (95, 97), 13: (95, 99), 14: (95, 99)}.items():
    for x in range(x0, x1 + 1):
        put(r, x, "Q" if r < 12 and x == 95 else "m")
put(14, 100, "g"); put(14, 101, "y")
art = ["".join(r).rstrip(".") for r in rows]
p = "data/pixel_art.gd"
s = open(p, encoding="utf-8", newline="").read()
i = s.index('\t"kanayama": [')
j = s.index('\t],\n', i) + 4
s = s[:i] + '\t"kanayama": [\n' + "".join('\t\t"%s",\n' % r for r in art) + "\t],\n" + s[j:]
open(p, "w", encoding="utf-8", newline="").write(s)
print("\n".join(art))
