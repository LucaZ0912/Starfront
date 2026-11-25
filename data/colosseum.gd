extends RefCounted
## Package 62a, part 3 (Luz): the Colosseum's rules, as numbers. In the arena you fight with gear the house hands
## out, never with your own: every piece costs gear points, by what it is and by its quality. The points are a
## budget: what you wear takes points, what you take off gives them back, so you may fit yourself anew before every
## fight. Wins raise the budget. The four ways to play (only one of them open yet), the modes (only King of the
## Colosseum open yet), the opponents of a round and what a win pays. All of it is meant to be tuned: the costs and
## the rewards stand here in tables. No class_name: preload it.

const GearData = preload("res://data/gear.gd")

const START_POINTS := 10           # the budget of gear points you begin with (at the first rank)
## Part 4 (Luz): the rank. It stays, whatever the mode and however a run ends. Each rank: its name, the rank points
## it takes, the budget you begin a run with, the best quality the house hands you (an index into the qualities).
const RANKS := [
	{"name": "Newcomer", "xp": 0, "start": 10, "q": 1},
	{"name": "Contender", "xp": 60, "start": 12, "q": 2},
	{"name": "Gladiator", "xp": 180, "start": 14, "q": 3},
	{"name": "Champion", "xp": 400, "start": 16, "q": 4},
	{"name": "Legend", "xp": 800, "start": 18, "q": 5},
]
const BOSS_EVERY := 10             # every so many rounds a named opponent waits instead of the strong one
const STATIONS := 5                # charging points on a fight's ground (Luz): energy and ammunition, for you and for the others
const STATION_COOL := 25.0         # seconds a charging point is drawn dry after somebody used it
const FOE_RESERVE := 0.5           # how much of their suit's energy and ammunition the others carry into a fight
## The named ones (Luz: every ten wins an important opponent), in their order; after the last the list begins anew.
const BOSSES := [
	{"name": "THE WARDEN", "suit": "suit_mil_heavy", "seed": 101, "col": Color(1.0, 0.82, 0.3), "line": "Ten rounds and still standing. I end that."},
	{"name": "OLD MERCY", "suit": "suit_mil_heavy", "seed": 113, "col": Color(0.9, 0.95, 1.0), "line": "I have buried better fits than yours."},
	{"name": "GLASS SAINT", "suit": "suit_mil_pathfinder", "seed": 127, "col": Color(0.4, 0.95, 1.0), "line": "The crowd came for you. They will stay for me."},
	{"name": "THE LAST OF KILN", "suit": "suit_mil_heavy", "seed": 131, "col": Color(1.0, 0.4, 0.2), "line": "Nobody leaves the thirtieth round the way they came."},
]
## The settings of the fight (Luz: whole maps in different settings, far larger than the arena; the arena builds them
## as holograms): id, name, the body whose ground it has, what stands there.
## Part 5 (Luz): six settings, and every one has a danger of its own ("hazard", "danger": what it is called):
##   cloud: clouds that block the sight drift over the field (dust) or burst from vents (steam)
##   ice:   sheets of ice: you slide on them
##   burn:  ground that burns whoever stands on it: plates under current that pulse on and off, fields of embers
##   slow:  undergrowth that holds you back
const SETTINGS := [
	{"id": "dust", "name": "Dust Canyon", "body": "desert", "text": "Red rock and dry wind.", "cover": ["rock", "rock", "rock", "crates", "barrier"], "made": false,
		"hazard": "cloud", "danger": "Dust devils: they hide whoever stands behind them."},
	{"id": "ice", "name": "Glacier Shelf", "body": "ice", "text": "Blue ice under a white sky.", "cover": ["rock", "rock", "barrier", "barrier", "bulwark"], "made": false,
		"hazard": "ice", "danger": "Sheets of bare ice: you slide on them."},
	{"id": "yard", "name": "Container Yard", "body": "metal", "text": "Stacks of steel, floodlights.", "cover": ["crates", "crates", "crates", "bulwark", "barrier", "barrel"], "made": true,
		"hazard": "burn", "danger": "Plates under current: they pulse on and off."},
	{"id": "jungle", "name": "Jungle Ruin", "body": "jungle", "text": "Old stone under green.", "cover": ["tree", "tree", "rock", "rock", "barrier"], "made": false,
		"hazard": "slow", "danger": "Undergrowth: it holds you back."},
	{"id": "lava", "name": "Lava Field", "body": "lava", "text": "Black rock, red light.", "cover": ["lava_rock", "lava_rock", "lava_rock", "barrel", "barrier"], "made": false,
		"hazard": "burn", "danger": "Fields of embers: they burn whoever stands on them."},
	{"id": "neon", "name": "Neon Yard", "body": "barren", "text": "A back lot of the city at night.", "cover": ["crates", "crates", "bulwark", "bulwark", "barrier", "barrel"], "made": true,
		"hazard": "cloud", "danger": "Steam vents: they burst and hide the lot."},
]
## The ground plans, mixed with every setting: id, name.
const LAYOUTS := [["open", "an open field"], ["canyon", "a canyon"], ["fortress", "a fortress"], ["lanes", "three lanes"]]
## Part 5: who may stand beside you in Team Deathmatch. The story's people come first (Luz: Rook to begin with; how
## that comes about follows); a chance acquaintance of the arena joins them; later crew with the standing of a
## gladiator. `quality`: where they begin (F, D, C, B, A, as crew), and how fast they grow with your rank and your run.
const MATES := [
	{"id": "rook", "name": "Rook Varga", "who": "rook", "quality": "C", "weapon": "wp_smg", "stance": "flank", "text": "Gunner of the Maul. Comes round the side."},
]
const MATE_Q := ["F", "D", "C", "B", "A"]
const MATE_WEAPONS := ["wp_rifle", "wp_shotgun", "wp_smg", "wp_laser_rifle"]
const TEAM_SIZE := 2               # how many stand beside you
const RUN_KEYS := ["points", "wins", "streak", "best", "fights", "round", "fit"]       # what a mode's run is made of
const Q_COST := {"F": 0, "E": 1, "D": 2, "C": 3, "B": 5, "A": 7}      # what a quality adds to a piece's cost
## What a piece costs at quality F (grenades and what goes on the belt have no quality: their place's cost).
const BASE := {
	"suit_civil": 0, "suit_work": 1, "suit_survey": 1, "suit_mil_light": 3, "suit_mil_heavy": 5,
	"wp_pistol": 0, "wp_laser_pistol": 1, "wp_smg": 2, "wp_shotgun": 2, "wp_rifle": 3, "wp_laser_rifle": 3, "wp_beam": 3, "wp_sniper": 4, "wp_launcher": 5,
	"ft_shield": 3, "ft_plates": 2, "ft_sprint": 2, "ft_jets": 2, "ft_ammo": 1, "ft_battery": 1,
	"dr_laser": 4, "dr_kinetic": 4, "dr_kamikaze": 3,
	"gr_frag": 1, "gr_emp": 1, "gr_smoke": 1, "gr_shield": 2,
	"cs_medkit": 1, "cs_stim": 1, "cs_cell": 1, "cs_ammo": 1,
}
## How many of a thing without quality one place holds.
const STACK := {"gr_frag": 2, "gr_emp": 2, "gr_smoke": 2, "gr_shield": 1, "cs_medkit": 2, "cs_stim": 1, "cs_cell": 2, "cs_ammo": 1}
## The places of a fit, in the order the window shows them: the key in the fit, what it is called, what goes in.
const PLACES := [["suit", "Suit", "suit_"], ["weapons", "Weapon", "wp_"], ["grenades", "Grenades", "gr_"], ["belt", "Belt", "cs_"], ["features", "Module", "ft_"], ["drones", "Drone", "dr_"]]

## The ways to play: id, name, a line under it, open yet.
const PLAY := [
	["single", "Singleplayer", "You against the house.", true],
	["coop", "Online co-op", "Side by side with a friend.", false],
	["versus", "Online versus", "Against other pilots.", false],
	["split", "Split screen", "Two at one screen.", true],
]
## The modes: id, name, what it is, open yet.
const MODES := [
	{"id": "king", "name": "King of the Colosseum", "open": true,
		"text": "You against three: one strong, two weak. Every win makes the next round harder and pays more."},
	{"id": "team", "name": "Team Deathmatch", "open": true, "text": "Three against three strong ones. You pick two to stand beside you. Lost only when your whole team is out."},
	{"id": "survivor", "name": "Survivor", "open": true, "text": "Alone against swarms without end. Your weapons fire by themselves."},
]


static func fresh() -> Dictionary:
	return {"points": 0, "wins": 0, "streak": 0, "best": 0, "fights": 0, "round": 1, "play": "single", "mode": "", "fit": default_fit(), "xp": 0, "seen": false,
		"runs": {}, "mates": [], "team": []}


## Part 5 (Luz): every mode has a run of its own (its round, its wins in a row, its gear points, its fit). The run
## of the mode you are in lies open in the state itself; the others wait in "runs". Switching puts one by and takes
## the other out (a mode never played yet begins fresh). The rank belongs to all of them.
static func switch_mode(col: Dictionary, mode: String) -> void:
	var old := String(col.get("mode", ""))
	if old == mode:
		return
	if not col.has("runs"):
		col["runs"] = {}
	if old != "":
		var keep := {}
		for k in RUN_KEYS:
			keep[k] = col[k]
		col["runs"][old] = keep
		var nxt: Dictionary = col["runs"].get(mode, {})
		var base := fresh()
		for k2 in RUN_KEYS:
			col[k2] = nxt[k2] if nxt.has(k2) else base[k2]
		col["runs"].erase(mode)
	col["mode"] = mode


static func mode_name(id: String) -> String:
	for m in MODES:
		if String(m["id"]) == id:
			return String(m["name"])
	return "The Colosseum"


## Who may stand beside you: the story's people, then the arena's chance acquaintances kept in your state (the
## first is made when first asked for). Each: {"id", "name", "who" ("" or a character of the story), "quality",
## "weapon", "stance", "seed", "text"}.
static func mates(col: Dictionary) -> Array:
	if not col.has("mates") or (col["mates"] as Array).is_empty():
		var MG = load("res://data/minigames.gd")
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		col["mates"] = [{"id": "mate_1", "name": "%s %s" % [String(MG.FIRST[rng.randi() % MG.FIRST.size()]), String(MG.LAST[rng.randi() % MG.LAST.size()])], "who": "", "quality": "F",
			"weapon": String(MATE_WEAPONS[rng.randi() % MATE_WEAPONS.size()]), "stance": String(["aggressive", "careful", "flank"][rng.randi() % 3]), "seed": rng.randi() % 100000,
			"text": "New to the lists, like you."}]
	return MATES.filter(func(m): return story_mate_open(String(m["id"]))) + (col["mates"] as Array)


## Package 64f (Luz): one of the story's people stands beside you only once the story has brought you together (the
## flag "<id>_mate": Rook after the morning at the Colosseum). A game without the story is not held back.
static func story_mate_open(id: String) -> bool:
	var st = GameState.story
	return st == null or not st.flags.has("intro_stage") or bool(st.flags.get(id + "_mate", false))


## The two who stand beside you now (their ids in "team"; whoever is missing is filled from the list).
static func team(col: Dictionary) -> Array:
	var all := mates(col)
	var ids: Array = (col.get("team", []) as Array).filter(func(id): return all.any(func(m): return String(m["id"]) == String(id)))
	for m in all:
		if ids.size() < TEAM_SIZE and not String(m["id"]) in ids and not bool(col.get("team_open", false)):
			ids.append(String(m["id"]))
	col["team"] = ids.slice(0, TEAM_SIZE)
	return all.filter(func(m): return String(m["id"]) in (col["team"] as Array))


## How good one who stands beside you is now: their own quality sets where they begin and how fast they grow; your
## rank and your run in this mode make them better.
static func mate_quality(m: Dictionary, col: Dictionary) -> String:
	var base := maxi(0, MATE_Q.find(String(m.get("quality", "F"))))
	var grow := float(rank(col)) + float(int(col.get("streak", 0))) / 3.0
	return String(MATE_Q[clampi(base + int(grow * (0.5 + 0.125 * base)), 0, MATE_Q.size() - 1)])


## One who stands beside you as a member of a ground team (what the fights on foot know).
static func mate_member(m: Dictionary, col: Dictionary) -> Dictionary:
	var q := mate_quality(m, col)
	var look: Dictionary = {}
	if String(m.get("who", "")) != "":
		look = load("res://scripts/core/story.gd").look_of(String(m["who"]))
	else:
		var rng := RandomNumberGenerator.new()
		rng.seed = int(m.get("seed", 1))
		look = ChibiArt.PilotArt.random_look(rng)
	return {"name": String(m["name"]), "look": look, "quality": q, "stance": String(m.get("stance", "careful")), "role": "",
		"gear": {"suit": "suit_mil_light:%s" % q, "weapons": ["%s:%s" % [String(m.get("weapon", "wp_rifle")), q], ""], "belt": []}}


## The rest of a fight worked out without being fought (you are out and end it): the chance that your side wins is
## its share of what both sides still have.
static func sim_win(rng: RandomNumberGenerator, ours: float, theirs: float) -> bool:
	if ours <= 0.0:
		return false
	return rng.randf() < ours / maxf(0.001, ours + theirs)


## Your rank (0 … 4) from your rank points.
static func rank(col: Dictionary) -> int:
	var r := 0
	for i in RANKS.size():
		if int(col.get("xp", 0)) >= int(RANKS[i]["xp"]):
			r = i
	return r


## Where you stand on the way to the next rank: {"rank", "name", "xp", "from", "to" (-1: the last rank), "k": 0 … 1}.
static func rank_state(col: Dictionary) -> Dictionary:
	var r := rank(col)
	var xp := int(col.get("xp", 0))
	var from := int(RANKS[r]["xp"])
	var to := int(RANKS[r + 1]["xp"]) if r + 1 < RANKS.size() else -1
	return {"rank": r, "name": String(RANKS[r]["name"]), "xp": xp, "from": from, "to": to, "k": 1.0 if to < 0 else clampf(float(xp - from) / float(to - from), 0.0, 1.0)}


## May a piece of this quality be handed to you at your rank? (Things without quality always.)
static func allowed(id: String, col: Dictionary) -> bool:
	if not id.contains(":"):
		return true
	return GearData.QUALITIES.find(id.get_slice(":", 1)) <= int(RANKS[rank(col)]["q"])


## How loud the crowd claps (dB): by how full the stands are.
static func applause_db(col: Dictionary) -> float:
	return lerpf(-20.0, 2.0, crowd(col))


## How full the stands are (0.2 … 1): fuller the longer your run and the higher your rank.
static func crowd(col: Dictionary) -> float:
	if String(col.get("mode", "")) == "survivor":       # part 7 (Luz): in Survivor the stands fill with how far you have come in that mode
		return lerpf(0.2, 1.0, load("res://data/survivor.gd").progress(col))
	return clampf(0.22 + 0.07 * int(col.get("streak", 0)) + 0.12 * rank(col), 0.2, 1.0)


## The fit you begin with: the plainest suit and a pistol, both free.
static func default_fit() -> Dictionary:
	return fitted({"suit": "suit_civil:F", "weapons": ["wp_pistol:F"], "grenades": [], "belt": [], "features": [], "drones": []})


static func budget(col: Dictionary) -> int:
	return int(RANKS[rank(col)]["start"]) + int(col.get("points", 0))


## How many places of each kind a suit has.
static func places(suit_id: String) -> Dictionary:
	var s: Dictionary = GearData.stats(suit_id)
	return {"weapons": int(s.get("weapons", 1)), "grenades": int(s.get("grenades", 0)), "belt": int(s.get("belt", 1)), "features": int(s.get("features", 0)), "drones": int(s.get("drones", 0))}


## A fit with its lists as long as its suit's places (what no longer fits falls off).
static func fitted(fit: Dictionary) -> Dictionary:
	var out := {"suit": String(fit.get("suit", "suit_civil:F"))}
	var pl := places(String(out["suit"]))
	for k in pl:
		var arr: Array = (fit.get(k, []) as Array).duplicate()
		arr.resize(int(pl[k]))
		for i in arr.size():
			if arr[i] == null:
				arr[i] = ""
		out[k] = arr
	return out


## What a piece costs ("" costs nothing; an unknown piece -1).
static func cost(id: String) -> int:
	if id == "":
		return 0
	var fam := id.get_slice(":", 0)
	if not BASE.has(fam):
		return -1
	if id.contains(":"):
		return int(BASE[fam]) + int(Q_COST.get(id.get_slice(":", 1), 99))
	return int(BASE[fam])


static func fit_cost(fit: Dictionary) -> int:
	var n := cost(String(fit.get("suit", "")))
	for p in PLACES:
		if String(p[0]) != "suit":
			for id in fit.get(String(p[0]), []):
				n += maxi(0, cost(String(id)))
	return n


## What may go into a place of this kind: every piece of the house, the cheapest first.
static func options(place: String) -> Array:
	var prefix := ""
	for p in PLACES:
		if String(p[0]) == place:
			prefix = String(p[2])
	var out: Array = []
	for fam in BASE:
		if not String(fam).begins_with(prefix):
			continue
		if prefix in ["gr_", "cs_"]:
			out.append(String(fam))
		else:
			for q in GearData.QUALITIES:
				out.append("%s:%s" % [fam, q])
	out.sort_custom(func(a, b): return cost(a) < cost(b) if cost(a) != cost(b) else a < b)
	return out


static func piece_name(id: String) -> String:
	if id == "":
		return "empty"
	var fam := id.get_slice(":", 0)
	var nm := String(GearData.base(id).get("name", fam))
	if STACK.has(fam):
		return "%d × %s" % [int(STACK[fam]), nm]
	return "%s %s" % [nm, id.get_slice(":", 1)]


## Puts a piece into a place of a fit ("" empties it). Returns {"fit": the new fit, "err": "" or why not}; the fit
## must stay within `points`.
static func equip(fit: Dictionary, place: String, idx: int, id: String, points: int, max_q: int = 5) -> Dictionary:
	var f := fitted(fit)
	if id.contains(":") and GearData.QUALITIES.find(id.get_slice(":", 1)) > max_q:
		return {"fit": f, "err": "Your rank does not reach quality %s yet." % id.get_slice(":", 1)}
	if place == "suit":
		if id == "" or not id.begins_with("suit_") or cost(id) < 0:
			return {"fit": f, "err": "No such suit."}
		f["suit"] = id
		f = fitted(f)
	else:
		var ok := false
		for p in PLACES:
			ok = ok or (String(p[0]) == place and (id == "" or (id.begins_with(String(p[2])) and cost(id) >= 0)))
		if not ok or not f.has(place):
			return {"fit": fitted(fit), "err": "That does not go there."}
		var arr: Array = f[place]
		if idx < 0 or idx >= arr.size():
			return {"fit": fitted(fit), "err": "This suit has no such place."}
		arr[idx] = id
	if fit_cost(f) > points:
		return {"fit": fitted(fit), "err": "Not enough gear points: that fit costs %d, you have %d." % [fit_cost(f), points]}
	return {"fit": f, "err": ""}


## The numbers of a fit: shield, armor, energy, ammo, speed (as the pilot's own gear adds up).
static func totals(fit: Dictionary) -> Dictionary:
	var g := PilotGear.new()
	g.suit = String(fit.get("suit", "suit_civil:F"))
	g.features = (fit.get("features", []) as Array).duplicate()
	return g.totals()


## Who waits in the arena in a round of King of the Colosseum: one strong, two weak, drawn by lot (`salt`: so that
## the lot falls the same for the preview and the fight): [{"who": a fighter of ColosseumGen.FIGHTERS, "strong":
## bool, "boss": -1 or a named one of BOSSES}]. Every BOSS_EVERY rounds a named opponent stands in the strong one's place.
static func opponents(round_no: int, fighters: int, salt: int = 0, mode: String = "king") -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("col_round_%d_%d" % [round_no, salt])
	var pool: Array = range(fighters)
	var out: Array = []
	for i in 3:
		out.append({"who": int(pool.pop_at(rng.randi() % pool.size())), "strong": i == 0 or mode == "team", "boss": -1})      # (Team Deathmatch: three strong ones)
	if round_no % BOSS_EVERY == 0:
		out[0]["boss"] = posmod(round_no / BOSS_EVERY - 1, BOSSES.size())
	return out


## How an opponent of a round is made: the kind of foe (data/foes.gd), its tier and the quality of its gear.
static func foe_of(o: Dictionary, round_no: int, slot_i: int) -> Dictionary:
	var qs: Array = GearData.QUALITIES
	if int(o.get("boss", -1)) >= 0:
		return {"kind": "col_boss", "tier": "red", "quality": String(qs[mini(5, 3 + round_no / 20)])}
	if bool(o["strong"]):
		return {"kind": "col_champion", "tier": "yellow" if round_no < 5 else "red", "quality": String(qs[mini(5, 1 + (round_no - 1) / 2)])}
	return {"kind": ["col_rusher", "col_rifle", "col_gunner"][posmod(int(o["who"]) + slot_i, 3)], "tier": "green" if round_no < 4 else ("yellow" if round_no < 9 else "red"),
		"quality": String(qs[mini(5, (round_no - 1) / 3)])}


## For trying things out (debug menu, tests): {"setting": id, "layout": id} instead of the lot.
static var force := {}


## The setting a round is fought in, and its ground plan (both by lot).
static func setting(round_no: int, salt: int = 0) -> Dictionary:
	for s in SETTINGS:
		if String(s["id"]) == String(force.get("setting", "")):
			return s
	return SETTINGS[posmod(hash("col_map_%d_%d" % [round_no, salt]), SETTINGS.size())]


static func layout(round_no: int, salt: int = 0) -> String:
	for l in LAYOUTS:
		if String(l[0]) == String(force.get("layout", "")):
			return String(l[0])
	return String(LAYOUTS[posmod(hash("col_plan_%d_%d" % [round_no, salt]), LAYOUTS.size())][0])


## What a win in a round pays: Coins, gear points, rank points (Team Deathmatch pays half as much again).
static func reward(round_no: int, mode: String = "king") -> Dictionary:
	var boss := round_no % BOSS_EVERY == 0
	var k := 1.5 if mode == "team" else 1.0
	return {"coins": int((30 + 10 * round_no) * (3 if boss else 1) * k), "points": 2 + (round_no - 1) / 3 + (3 if boss else 0), "xp": int((10 + 5 * round_no) * (2 if boss else 1) * k)}


## A fight is over. Won: the reward (the Coins are paid by the caller), the run goes on to the next round. Lost: the
## run ends: its gear points are gone, the round is 1 again; the rank stays. Returns what happened:
## {"won", "coins", "points", "xp", "round": the round fought, "rank_up": bool, "lost_points"}.
static func settle(col: Dictionary, won: bool) -> Dictionary:
	var rnd := int(col.get("round", 1))
	var before := rank(col)
	col["fights"] = int(col.get("fights", 0)) + 1
	var out := {"won": won, "coins": 0, "points": 0, "xp": 0, "round": rnd, "rank_up": false, "lost_points": 0}
	if won:
		var rw := reward(rnd, String(col.get("mode", "king")))
		out["coins"] = int(rw["coins"])
		out["points"] = int(rw["points"])
		out["xp"] = int(rw["xp"])
		col["points"] = int(col.get("points", 0)) + int(rw["points"])
		col["xp"] = int(col.get("xp", 0)) + int(rw["xp"])
		col["wins"] = int(col.get("wins", 0)) + 1
		col["streak"] = int(col.get("streak", 0)) + 1
		col["best"] = maxi(int(col.get("best", 0)), int(col["streak"]))
		col["round"] = rnd + 1
	else:
		out["lost_points"] = int(col.get("points", 0))
		col["points"] = 0
		col["streak"] = 0
		col["round"] = 1
		col["fit"] = default_fit()                          # (the run's gear goes back to the house)
		col["fit2"] = default_fit()                         # (split screen: the second player's too)
	out["rank_up"] = rank(col) > before
	return out


## The pilot's gear for the fight: a fit of the house's pieces as the gear the fights on foot know.
static func gear_of(fit: Dictionary) -> PilotGear:
	var f := fitted(fit)
	var g := PilotGear.new()
	g.suit = String(f["suit"])
	g.inv = []
	g.inv.resize(GearData.INV_SLOTS)
	g.inv.fill({})
	g._fit_slots()
	for i in mini(g.weapons.size(), (f["weapons"] as Array).size()):
		g.weapons[i] = String(f["weapons"][i])
	for i2 in mini(g.features.size(), (f["features"] as Array).size()):
		g.features[i2] = String(f["features"][i2])
	for i3 in mini(g.drones.size(), (f["drones"] as Array).size()):
		g.drones[i3] = String(f["drones"][i3])
	for i4 in mini(g.grenades.size(), (f["grenades"] as Array).size()):
		var gid := String(f["grenades"][i4])
		g.grenades[i4] = {"id": gid, "n": int(STACK.get(gid, 1))} if gid != "" else {}
	for i5 in mini(g.belt.size(), (f["belt"] as Array).size()):
		var bid := String(f["belt"][i5])
		g.belt[i5] = {"id": bid, "n": int(STACK.get(bid, 1))} if bid != "" else {}
	g.refill()
	return g
