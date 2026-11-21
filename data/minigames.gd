extends RefCounted
## Package 54b (Luz): the bar games – what each is, its modes and rules; the stakes by the win streak (low, from 10
## wins in a row medium, from 25 high – the guests get better with it); the guests of a bar who play.
## Pure data and small helpers. No class_name: preload it.

const GAMES := {
	"billiards": {"name": "Billiards", "where": "The pool table",
		"modes": [["8ball", "8-Ball"], ["9ball", "9-Ball"], ["practice", "Practice (alone)"]],
		"rules": {"8ball": "Break, then one of you takes the solids (1–7), the other the stripes (9–15): whoever pockets first chooses. Pocket all of yours, then the black 8. Fouls (the cue ball in a pocket, hitting the other's ball first, hitting nothing) give the other player the ball in hand. The 8 too early, or with a foul, loses.",
			"9ball": "Always hit the lowest ball on the table first. Whatever you pocket that way, you keep shooting. Whoever pockets the 9 legally wins, even early, on a combination. A foul gives the ball in hand.",
			"practice": "The table to yourself: no turns, no fouls. R racks again."}},
	"darts": {"name": "Darts", "where": "The dartboard",
		"modes": [["301", "301"], ["501", "501"], ["clock", "Around the clock (alone)"]],
		"rules": {"301": "Both start at 301; each turn three darts, their points come off. Who gets down to exactly nothing first wins. Below nothing is a bust: the turn counts for nothing. The thin outer ring doubles, the inner ring triples; the bull is 50, the green ring round it 25.",
			"501": "Like 301, from 501: a longer game.",
			"clock": "Alone: hit 1, then 2, … up to 20, then the bull. Doubles and trebles of the number count. As few darts as you can."}},
	"drift": {"name": "Drift", "where": "The card table",
		"modes": [["drift", "Drift: you and the table"]],
		"rules": {"drift": "Cards 1–10 in four suits (comets, moons, suns, nebulae) and four Warp cards worth nothing. Everyone gets two cards; in turn you draw (drift) or hold: over 21 you burn out. Closest to 21 takes the pot (everyone's stake); hit exactly 21 (a Singularity) and you win at once. A Warp in your hand swaps one of your cards for the deck's top one, then goes to the discard."}},
	"rockhopper": {"name": "Rock Hopper", "where": "The arcade cabinet",
		"modes": [["arcade", "Arcade: 1 credit a game"]],
		"rules": {"arcade": "Fly the mining tug (W thrust, mouse or A/D to turn). The drill laser (left button) cracks the rocks (big ones split, small ones shatter) and spills their ore; the tractor beam (right button) pulls it into your hold. Only ore you bring home to the refinery in the middle counts: dock there slowly; a full hold counts double, and the tank is filled. Lose the tug and the hold spills. From wave 3 pirate drones hunt you. Three tugs."}},
}

## The stake tiers: from how many wins in a row, the stakes on offer, the guests' strength (stars) then.
const TIERS := [
	{"name": "low", "from": 0, "stakes": [50, 100, 150, 200], "stars": [1, 3]},
	{"name": "medium", "from": 10, "stakes": [500, 1000], "stars": [2, 4]},
	{"name": "high", "from": 25, "stakes": [2500, 5000], "stars": [3, 5]},
]

const FIRST := ["Rusty", "Dana", "Imre", "Kofi", "Mara", "Juno", "Tevin", "Ilse", "Bram", "Selin", "Odo", "Nia", "Kasimir", "Rhea",
	"Tobias", "Yara", "Vik", "Lena", "Pjotr", "Ama", "Hollis", "Zuri", "Esko", "Fen"]
const LAST := ["Vell", "Okafor", "Brandt", "Teal", "Marsh", "Ruiz", "Kowal", "Achebe", "Lindqvist", "Sato", "Morrow", "Haddad",
	"Novak", "Quint", "Arvidsen", "Bello", "Krane", "Szabo"]
const NICK := ["Snake", "Chalk", "Lucky", "Doc", "Ace", "Rail", "Spin", "Bank"]
const JOBS := ["miner", "freighter pilot", "smuggler", "dock worker", "mechanic", "trader", "medic", "drone wrangler", "prospector",
	"ex-marine", "courier", "cook"]
const LINES := ["\"Rack 'em up, spacer.\"", "\"Loser buys the next round.\"", "\"Don't cry when I clear the table.\"", "\"I've got time.\"",
	"\"Go easy on me, long shift.\"", "\"Haven't lost here since the last refit.\"", "\"You break.\"", "\"Let's see that hand of yours.\""]


## Package 58, part 8 (Luz): special opponents: the story's people at a bar game, once the story lets them. Beat one
## and they go into the collection ("Special opponents"). Each: who (the story character, for the portrait), the
## games, where (a story flag holding the station's id), from (the flag that opens them), their strength.
const SPECIAL := {
	"ossa": {"who": "ossa", "name": "Ossa Kell", "job": "hauler boss", "stars": 5, "games": ["billiards"],
		"where": "w58_dan_st", "from": "w58_drinks", "line": "\"I never miss the black. Ask Silas.\"",
		"text": "Runs the haulers out of Upper Brine. Plays pool the way Ossa flies: no wasted moves."},
	"dan": {"who": "dan", "name": "Dan", "job": "station owner", "stars": 3, "games": ["billiards"],
		"where": "w58_dan_st", "from": "w58_drinks", "line": "\"My table, my rules. Mostly.\"",
		"text": "Owns the station, the bar and the table. Swears the table leans to the left."},
}


## The special opponents at this place for this game now (as lobby seats).
static func specials(place_id: String, game: String) -> Array:
	var out: Array = []
	var fl: Dictionary = GameState.story.flags
	for k in SPECIAL:
		var sp: Dictionary = SPECIAL[k]
		if not game in sp["games"] or not bool(fl.get(String(sp["from"]), false)) or String(fl.get(String(sp["where"]), "-")) != place_id:
			continue
		out.append({"id": "sp_" + String(k), "special": String(k), "who": String(sp["who"]), "name": String(sp["name"]), "job": String(sp["job"]),
			"stars": int(sp["stars"]), "line": String(sp["line"]), "kind": "special"})
	return out


## A mode played alone (no opponent, no stake, no streak).
static func solo(mode: String) -> bool:
	return mode in ["practice", "clock", "arcade"]


const ARCADE_NAMES := ["JUNO", "VIK", "ODO", "AMA", "ZURI", "FEN", "KASI", "RHEA", "ESKO", "BRAM", "NIA", "TEVI"]


## A cabinet's high score list tonight: invented regulars (by the place) and your own scores there – the best five,
## each [name, score, yours].
static func arcade_board(place_id: String, best: Dictionary) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("rh_%s" % place_id)
	var rows: Array = []
	var names := ARCADE_NAMES.duplicate()
	for i in 5:
		var nm: String = names.pop_at(rng.randi() % names.size())
		rows.append([nm, int(round(rng.randf_range(900.0, 9000.0) / 50.0)) * 50, false])
	var me := String(GameState.pilot.get("name", "YOU")).to_upper().left(4) if GameState.pilot is Dictionary else "YOU"
	for sc in best.get("rh:" + place_id, []):
		rows.append([me, int(sc), true])
	rows.sort_custom(func(a, b): return int(a[1]) > int(b[1]))
	return rows.slice(0, 5)


static func tier(streak: int) -> int:
	var t := 0
	for i in TIERS.size():
		if streak >= int(TIERS[i]["from"]):
			t = i
	return t


## All stakes, each [amount, open] – those above the tier are shown locked.
static func stakes(streak: int) -> Array:
	var out: Array = [[0, true]]
	var t := tier(streak)
	for i in TIERS.size():
		for s in TIERS[i]["stakes"]:
			out.append([int(s), i <= t])
	return out


static func max_stake(streak: int) -> int:
	return int((TIERS[tier(streak)]["stakes"] as Array).back())


## The guests of a bar who would play now: 2–4, their strength by the tier (seeded by the place, the game and the
## hour, so they stay while you are there).
static func guests(place_id: String, game: String, streak: int, hour: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s_%s_%d_%d" % [place_id, game, hour, tier(streak)])
	var st: Array = TIERS[tier(streak)]["stars"]
	var out: Array = []
	for i in rng.randi_range(2, 4):
		var nm := "%s %s" % [FIRST[rng.randi() % FIRST.size()], LAST[rng.randi() % LAST.size()]]
		if rng.randf() < 0.2:
			nm = "\"%s\" %s" % [NICK[rng.randi() % NICK.size()], LAST[rng.randi() % LAST.size()]]
		out.append({"id": "guest_%d" % i, "name": nm, "job": JOBS[rng.randi() % JOBS.size()], "stars": rng.randi_range(int(st[0]), int(st[1])),
			"line": LINES[rng.randi() % LINES.size()], "kind": "guest"})
	return out


static func stars_text(n: int) -> String:
	return "●".repeat(clampi(n, 0, 5)) + "○".repeat(5 - clampi(n, 0, 5))
