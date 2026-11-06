"""Finds a spot for a drone hatch on every ship that carries drones (package 25d follow-up) and prints
the hull entries ("hatches": {"drones": [x, y, w, h]} in columns/rows of the full, mirrored ship image).

The hatch sits on the centre line (it is mirrored with the art), on plain hull plating – no cockpit,
guns, engines, owner colour or edges – as close as possible to 40 % of the length from the stern.
Run: python tools/art/drone_hatches.py   (--apply writes the entries into data/hulls.gd)
"""
import os, re, sys
ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
SIZES = {1: (4, 3), 2: (6, 5), 3: (8, 7)}           # hatch width, height by hull size
PLAIN = set("hHdDYLQIJjuMNkK123")                      # plain plating a hatch may cover
SHADE = {"H": "h", "h": "d", "d": "D", "L": "Y", "Y": "Q", "J": "I", "I": "j", "u": "U", "B": "M", "M": "N"}


def parse_gd_dict(text, name):
    """Very small reader for the SHIPS / FULL constants of data/pixel_art.gd."""
    i = text.index("const %s := {" % name)
    body = text[i:]
    arts = {}
    for m in re.finditer(r'\t"([a-z0-9_]+)": \[\n((?:\t\t"[^"]*",\n)*)\t\]', body):
        if m.start() > body.index("\n}\n"):
            break
        arts[m.group(1)] = re.findall(r'\t\t"([^"]*)"', m.group(2))
    return arts


def full_grid(art, full):
    w = max(len(r) for r in art)
    rows = [r.ljust(w, ".") for r in art]
    if full:
        return rows
    out = list(rows)
    for r in reversed(rows[:-1]):
        out.append("".join(SHADE.get(c, c) for c in r))
    return out


def main():
    gd = open(os.path.join(ROOT, "data", "pixel_art.gd"), encoding="utf-8").read()
    ships = parse_gd_dict(gd, "SHIPS")
    full = set(re.findall(r'"([a-z_]+)": true', gd[gd.index("const FULL"):gd.index("\n", gd.index("const FULL"))]))
    hulls = open(os.path.join(ROOT, "data", "hulls.gd"), encoding="utf-8").read()
    result = {}
    for m in re.finditer(r'\n\t"([a-z_]+)": \{\n(.*?)\n\t\},', hulls, re.S):
        hid, block = m.group(1), m.group(2)
        drones = re.search(r'"drones": (\d+)', block)
        size = re.search(r'"size": (\d)', block)
        if not drones or int(drones.group(1)) == 0 or "drone_only" in block or "drone_deck" in block or '"hatches"' in block:
            continue
        g = full_grid(ships[hid], hid in full)
        h, w = len(g), len(g[0])
        hw, hh = SIZES[int(size.group(1))]
        y0 = (h - hh) // 2
        best, best_d = None, 1e9
        for x0 in range(int(w * 0.12), int(w * 0.8) - hw):
            ok = all(g[y][x] in PLAIN for y in range(y0 - 1, y0 + hh + 1) for x in range(x0 - 1, x0 + hw + 1))
            if ok:
                d = abs((x0 + hw / 2) - w * 0.4)
                if d < best_d:
                    best, best_d = x0, d
        if best is None:                             # no plain spot that big: try one size smaller
            hw, hh = max(3, hw - 2), max(3, hh - 2)
            y0 = (h - hh) // 2
            for x0 in range(int(w * 0.1), int(w * 0.85) - hw):
                if all(g[y][x] in PLAIN for y in range(y0, y0 + hh) for x in range(x0, x0 + hw)):
                    d = abs((x0 + hw / 2) - w * 0.4)
                    if d < best_d:
                        best, best_d = x0, d
        result[hid] = [best, y0, hw, hh] if best is not None else None
    for hid, r in result.items():
        print(hid, r)
    if "--apply" in sys.argv:
        for hid, r in result.items():
            if r is None:
                continue
            pat = '\n\t"%s": {\n' % hid
            i = hulls.index(pat)
            j = hulls.index('\t\t"drones": ', i)
            k = hulls.index("\n", j)
            hulls = hulls[:k + 1] + '\t\t"hatches": {"drones": %s}, "hatch_overlay": true,\n' % str(r) + hulls[k + 1:]
        open(os.path.join(ROOT, "data", "hulls.gd"), "w", encoding="utf-8", newline="").write(hulls)
        print("applied")


main()
