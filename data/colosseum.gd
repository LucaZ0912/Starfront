extends RefCounted
## Package 62a, part 3 (Luz): the Colosseum's rules, as numbers. In the arena you fight with gear the house hands
## out, never with your own: every piece costs gear points, by what it is and by its quality. The points are a
## budget: what you wear takes points, what you take off gives them back, so you may fit yourself anew before every
## fight. Wins raise the budget. The four ways to play (only one of them open yet), the modes (only King of the
## Colosseum open yet), the opponents of a round and what a win pays. All of it is meant to be tuned: the costs and
## the rewards stand here in tables. No class_name: preload it.

const GearData = preload("res://data/gear.gd")

const START_POINTS := 10           # the budget of gear points you begin with
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
	["split", "Split screen", "Two at one screen.", false],
]
## The modes: id, name, what it is, open yet.
const MODES := [
	{"id": "king", "name": "King of the Colosseum", "open": true,
		"text": "You against three: one strong, two weak. Every win makes the next round harder and pays more."},
	{"id": "team", "name": "Team Deathmatch", "open": false, "text": "Three against three strong ones."},
	{"id": "survivor", "name": "Survivor", "open": false, "text": "Alone against waves without end."},
]


static func fresh() -> Dictionary:
	return {"points": 0, "wins": 0, "streak": 0, "best": 0, "fights": 0, "round": 1, "play": "single", "mode": "", "fit": default_fit()}


## The fit you begin with: the plainest suit and a pistol, both free.
static func default_fit() -> Dictionary:
	return fitted({"suit": "suit_civil:F", "weapons": ["wp_pistol:F"], "grenades": [], "belt": [], "features": [], "drones": []})


static func budget(col: Dictionary) -> int:
	return START_POINTS + int(col.get("points", 0))


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
static func equip(fit: Dictionary, place: String, idx: int, id: String, points: int) -> Dictionary:
	var f := fitted(fit)
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


## Who waits in the arena in a round of King of the Colosseum: one strong, two weak: [{"who": a fighter of
## ColosseumGen.FIGHTERS, "strong": bool}].
static func opponents(round_no: int, fighters: int) -> Array:
	var a := posmod(round_no * 3 + 1, fighters)
	return [{"who": a, "strong": true}, {"who": posmod(a + 2, fighters), "strong": false}, {"who": posmod(a + 5, fighters), "strong": false}]


## What a win in a round pays: Coins and gear points.
static func reward(round_no: int) -> Dictionary:
	return {"coins": 30 + 10 * round_no, "points": 2 + (round_no - 1) / 3}
