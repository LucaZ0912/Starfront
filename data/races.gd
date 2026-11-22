extends RefCounted
## Package 62b (Luz): the races shown on The Track, the cinema floor of the Grand Centauria, and the bets on them.
## Three dangerous courses in the Fern system take turns; six of a stable of twelve racing pilots fly each race.
## The races run by the clock (the play time, plus what you have waited in the cinema): every PERIOD seconds one,
## bets are taken until it starts. A race is the same for everybody: it is made from its number alone. The house's
## odds hold a margin; they know a pilot's skill, only a little of the form of the day. Who flies with more risk
## is faster and wrecks more often (a wreck is a wreck: the pilot is picked up). No class_name: preload it.

const PERIOD := 300.0              # seconds from one race's start of betting to the next
const RUN := 50.0                  # … of which the race runs this long …
const SHOW := 10.0                 # … and its result stands this long
const LAPS := 3
const MARGIN := 0.12               # the house's share in the odds
const LIMIT := 500                 # Coins a seat may stake on one race
const CHIPS := [1, 5, 25, 100]
const KINDS := {"win": "Win", "place": "Place", "exacta": "Exacta"}
const TRIALS := 300                # how often the house flies a race in its head to set the odds
const DAY := 0.07                  # how much the form of the day moves a pilot's time (seconds, one sigma)

const TRACKS := [
	{"id": "kiln", "name": "The Kiln Run", "where": "the lava canyons of Kiln", "hazard": "a fountain of lava"},
	{"id": "rings", "name": "The Ring Dash", "where": "the rings of Lapis", "hazard": "a block of ice"},
	{"id": "belt", "name": "The Belt Slalom", "where": "the asteroid belt of Fern", "hazard": "a tumbling rock"},
]
const PILOTS := [
	{"name": "Vega Ruiz", "ship": "Needle", "col": Color(1.0, 0.36, 0.66), "skill": 0.9, "risk": 0.45},
	{"name": "Odo Krane", "ship": "Hailstone", "col": Color(0.3, 0.9, 1.0), "skill": 0.8, "risk": 0.3},
	{"name": "Nia Sato", "ship": "Firefly", "col": Color(1.0, 0.82, 0.25), "skill": 0.7, "risk": 0.7},
	{"name": "Bram Teal", "ship": "Old Faithful", "col": Color(0.55, 1.0, 0.6), "skill": 0.6, "risk": 0.1},
	{"name": "Zuri Bello", "ship": "Razor", "col": Color(0.72, 0.5, 1.0), "skill": 0.75, "risk": 0.95},
	{"name": "Esko Marsh", "ship": "Brick", "col": Color(1.0, 0.45, 0.25), "skill": 0.4, "risk": 0.2},
	{"name": "Ilse Novak", "ship": "Glass Arrow", "col": Color(0.9, 0.95, 1.0), "skill": 0.85, "risk": 0.6},
	{"name": "Tevin Achebe", "ship": "Loud Mouth", "col": Color(1.0, 0.3, 0.3), "skill": 0.55, "risk": 0.8},
	{"name": "Rhea Quint", "ship": "Second Wind", "col": Color(0.4, 0.6, 1.0), "skill": 0.65, "risk": 0.35},
	{"name": "Kasimir Vell", "ship": "Bad Idea", "col": Color(0.8, 1.0, 0.3), "skill": 0.5, "risk": 0.9},
	{"name": "Ama Lindqvist", "ship": "Quiet One", "col": Color(1.0, 0.6, 0.85), "skill": 0.72, "risk": 0.15},
	{"name": "Fen Haddad", "ship": "Rust Bucket", "col": Color(0.75, 0.6, 0.45), "skill": 0.3, "risk": 0.5},
]

static var _cache := {}


## The races' clock.
static func clock() -> float:
	return GameState.play_time + GameState.race_shift


## Where the clock stands: {"n": the race's number, "state": "bets" | "run" | "result", "left": seconds until the
## state ends, "rt": the race's own time (0 before it, RUN after it)}.
static func phase(t: float) -> Dictionary:
	var n := int(floor(t / PERIOD))
	var u := t - n * PERIOD
	var bets := PERIOD - RUN - SHOW
	if u < bets:
		return {"n": n, "state": "bets", "left": bets - u, "rt": 0.0}
	if u < bets + RUN:
		return {"n": n, "state": "run", "left": bets + RUN - u, "rt": u - bets}
	return {"n": n, "state": "result", "left": PERIOD - u, "rt": RUN}


## The race that takes bets now: {"n", "left": seconds until it starts}. While a race runs, the one after it.
static func next_open(t: float) -> Dictionary:
	var ph := phase(t)
	if String(ph["state"]) == "bets":
		return {"n": int(ph["n"]), "left": float(ph["left"])}
	return {"n": int(ph["n"]) + 1, "left": (int(ph["n"]) + 1) * PERIOD - t + PERIOD - RUN - SHOW}


## A race is decided (its bets can be paid) from here on the clock.
static func over(n: int, t: float) -> bool:
	var ph := phase(t)
	return int(ph["n"]) > n or (int(ph["n"]) == n and String(ph["state"]) == "result")


static func _outcome(rng: RandomNumberGenerator, entry: Array, day: Array) -> Dictionary:
	var time: Array = []
	var crash: Array = []
	for i in entry.size():
		var p: Dictionary = PILOTS[int(entry[i])]
		time.append(clampf(46.5 - 5.0 * float(p["skill"]) - 1.5 * float(p["risk"]) - float(day[i]) + rng.randfn(0.0, 1.1), 36.0, RUN - 1.0))
		crash.append(rng.randf_range(0.2, 0.95) if rng.randf() < 0.03 + 0.16 * float(p["risk"]) else -1.0)
	var order: Array = range(entry.size())
	order.sort_custom(func(a, b):
		var ca := float(crash[a]) >= 0.0
		var cb := float(crash[b]) >= 0.0
		if ca != cb:
			return cb
		return float(crash[a]) > float(crash[b]) if ca else float(time[a]) < float(time[b]))
	return {"time": time, "crash": crash, "order": order}


## Race number `n`: {"n", "track": its course, "entry": six of PILOTS (their numbers), "time": every racer's time
## to the line, "crash": how far each came (-1: to the line), "crash_t": when it wrecked, "order": the racers
## (0 … 5) from first to last, "wob": how each one's speed sways, "win", "place": the odds, "p": the chance to win
## as the house sees it, "tip": the racer in the best form of the day}.
static func race(n: int) -> Dictionary:
	if _cache.has(n):
		return _cache[n]
	if _cache.size() > 80:
		_cache.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("spacefarer_race_%d" % n)
	var pool: Array = range(PILOTS.size())
	var entry: Array = []
	for i in 6:
		entry.append(pool.pop_at(rng.randi() % pool.size()))
	var day: Array = []
	var seen: Array = []
	var tip := 0
	for i2 in 6:
		day.append(rng.randfn(0.0, DAY))
		seen.append(float(day[i2]) * 0.3)
		if float(day[i2]) > float(day[tip]):
			tip = i2
	var wins: Array = [0, 0, 0, 0, 0, 0]
	var top3: Array = [0, 0, 0, 0, 0, 0]
	for k in TRIALS:
		var o: Array = _outcome(rng, entry, seen)["order"]
		wins[int(o[0])] += 1
		for q in 3:
			top3[int(o[q])] += 1
	var p: Array = []
	var win: Array = []
	var place: Array = []
	for i3 in 6:
		p.append(maxf(0.012, float(wins[i3]) / TRIALS))
		win.append(_round_odds((1.0 - MARGIN) / float(p[i3]), 1.1))
		place.append(_round_odds((1.0 - MARGIN) / maxf(0.03, float(top3[i3]) / TRIALS), 1.05))
	var res: Dictionary = _outcome(rng, entry, day)
	var wob: Array = []
	var crash_t: Array = []
	for i4 in 6:
		wob.append([rng.randf_range(0.25, 0.6), rng.randf_range(0.0, TAU), rng.randf_range(0.012, 0.03)])
		crash_t.append(-1.0)
	var out := {"n": n, "track": TRACKS[posmod(n, TRACKS.size())], "entry": entry, "time": res["time"], "crash": res["crash"], "crash_t": crash_t, "order": res["order"],
		"wob": wob, "win": win, "place": place, "p": p, "tip": tip}
	for i5 in 6:                                          # when each wreck happens: where its way reaches the spot
		if float(res["crash"][i5]) >= 0.0:
			var t := 0.0
			while t < RUN and _raw(out, i5, t) < float(res["crash"][i5]):
				t += 0.1
			crash_t[i5] = t
	_cache[n] = out
	return out


static func _round_odds(o: float, least: float) -> float:
	o = clampf(o, least, 60.0)
	return snappedf(o, 0.1) if o < 10.0 else snappedf(o, 1.0)


static func _raw(r: Dictionary, i: int, t: float) -> float:
	var T := float(r["time"][i])
	var w: Array = r["wob"][i]
	var u := clampf(t / T, 0.0, 1.0)
	return clampf(u + float(w[2]) * sin(PI * u) * sin(float(w[0]) * t + float(w[1])), 0.0, 1.0) + maxf(0.0, t - T) / T


## How far racer `i` (0 … 5) has come at the race's time `t`: 0 the start, 1 the line (more: past it). A wreck
## stays where it happened.
static func progress(r: Dictionary, i: int, t: float) -> float:
	var c := float(r["crash"][i])
	return minf(_raw(r, i, t), c) if c >= 0.0 else _raw(r, i, t)


static func wrecked(r: Dictionary, i: int, t: float) -> bool:
	return float(r["crash"][i]) >= 0.0 and t >= float(r["crash_t"][i])


## The racers as they lie at the race's time `t`, the first first (after the race: its result).
static func standing(r: Dictionary, t: float) -> Array:
	if t >= RUN - 0.01:
		return (r["order"] as Array).duplicate()
	var out: Array = range(6)
	out.sort_custom(func(a, b):
		var wa := wrecked(r, a, t)
		var wb := wrecked(r, b, t)
		if wa != wb:
			return wb
		return progress(r, a, t) > progress(r, b, t))
	return out


static func pilot(r: Dictionary, i: int) -> Dictionary:
	return PILOTS[int(r["entry"][i])]


## What the speaker says at the race's time `t`.
static func speaker(r: Dictionary, t: float) -> String:
	var tr: Dictionary = r["track"]
	if t < 2.5:
		return "They are off: %s, three laps through %s." % [String(tr["name"]), String(tr["where"])]
	if t >= RUN - 0.01 or progress(r, int(r["order"][0]), t) >= 1.0:
		var first := int(r["order"][0])
		if float(r["crash"][first]) >= 0.0:
			return "Nobody reaches the line. %s came the farthest." % String(pilot(r, first)["name"])
		return "%s takes %s in the %s." % [String(pilot(r, first)["name"]), String(tr["name"]), String(pilot(r, first)["ship"])]
	var last := -1
	for i in 6:
		if wrecked(r, i, t) and t - float(r["crash_t"][i]) < 4.5 and (last < 0 or float(r["crash_t"][i]) > float(r["crash_t"][last])):
			last = i
	if last >= 0:
		return "%s meets %s and is out. The pilot is picked up." % [String(pilot(r, last)["name"]), String(tr["hazard"])]
	var st := standing(r, t)
	var gap := progress(r, int(st[0]), t) - progress(r, int(st[1]), t)
	return "%s leads%s, %s behind." % [String(pilot(r, int(st[0]))["name"]), " clear" if gap > 0.03 else " by a nose", String(pilot(r, int(st[1]))["name"])]


## A pilot's last three races before race `n`: the places ("X": wrecked), the latest first.
static func form(pilot_id: int, n: int) -> String:
	var out: Array = []
	var m := n - 1
	while m >= 0 and m > n - 14 and out.size() < 3:
		var r := race(m)
		var at := (r["entry"] as Array).find(pilot_id)
		if at >= 0:
			out.append("X" if float(r["crash"][at]) >= 0.0 else str((r["order"] as Array).find(at) + 1))
		m -= 1
	return " ".join(out) if not out.is_empty() else "new"


## The odds of a bet on race `r`: "win" and "place" on racer `a`, "exacta" on `a` first and `b` second. 0: no such bet.
static func odds(r: Dictionary, kind: String, a: int, b: int = -1) -> float:
	if a < 0 or a > 5:
		return 0.0
	match kind:
		"win":
			return float(r["win"][a])
		"place":
			return float(r["place"][a])
		"exacta":
			if b < 0 or b > 5 or b == a:
				return 0.0
			var pa := float(r["p"][a])
			var pb := float(r["p"][b])
			return snappedf(clampf((1.0 - MARGIN) / (pa * pb / maxf(0.05, 1.0 - pa)), 2.0, 500.0), 1.0)
	return 0.0


static func bet_won(r: Dictionary, kind: String, a: int, b: int) -> bool:
	var o: Array = r["order"]
	match kind:
		"win":
			return int(o[0]) == a
		"place":
			return a in o.slice(0, 3)
		"exacta":
			return int(o[0]) == a and int(o[1]) == b
	return false


static func bet_text(r: Dictionary, bet: Dictionary) -> String:
	var a := String(pilot(r, int(bet["a"]))["name"])
	if String(bet["kind"]) == "exacta":
		return "Exacta: %s, then %s" % [a, String(pilot(r, int(bet["b"]))["name"])]
	return "%s: %s" % [String(KINDS[String(bet["kind"])]), a]


## What tickets ({n, kind, a, b, stake, odds, seat}) give back that are decided at clock `t`:
## {"staked", "back", "won": how many, "count", "keep": the tickets still running}.
static func due(bets: Array, t: float, seat: int = 0) -> Dictionary:
	var out := {"staked": 0, "back": 0, "won": 0, "count": 0, "keep": []}
	for b in bets:
		if int(b.get("seat", 0)) != seat or not over(int(b["n"]), t):
			(out["keep"] as Array).append(b)
			continue
		out["count"] = int(out["count"]) + 1
		out["staked"] = int(out["staked"]) + int(b["stake"])
		if bet_won(race(int(b["n"])), String(b["kind"]), int(b["a"]), int(b.get("b", -1))):
			out["won"] = int(out["won"]) + 1
			out["back"] = int(out["back"]) + int(floor(int(b["stake"]) * float(b["odds"])))
	return out
