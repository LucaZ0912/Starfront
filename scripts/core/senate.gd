extends RefCounted
## The Senate of the Cluster Assembly (package 39a) – a service in The Vote (Landfall). Every 30–60 minutes a bill
## comes to the vote; citizens with an entry permit vote Yes or No. A passed bill holds for an hour in all of the
## Assembly's territory: at its stations (prices, fuel and repairs, Concord ships) and in its systems (bounties,
## patrols). Every bill has its upside and its price.
## Influence: your own vote (a little), a party donation (more, but never certain) and a bribe (very dear; if it is
## not found out it settles the vote – if it is, the money is gone and the Assembly's trust with it).
## Owned by GameState (GameState.senate), saved with the pilot.

const FactionData = preload("res://data/factions.gd")

const VOTE_MIN := 1800.0          # a bill is debated 30–60 minutes …
const VOTE_MAX := 3600.0
const LAW_TIME := 3600.0          # … a passed bill holds for an hour
const NEXT_BILL := 120.0          # the next bill comes two minutes after a vote
const VOTE_SWAY := 0.03           # your own vote
const DONATION_STEP := 25000      # one donation …
const DONATION_SWAY := 0.04       # … moves the odds this much (at most DONATION_MAX in all)
const DONATION_MAX := 0.16
const BRIBE_BASE := 250000        # a bribe – grows with the pilot's wealth, so it always hurts
const BRIBE_SHARE := 0.25
const BRIBE_CAUGHT := 0.45        # chance that it comes out
const BRIBE_REP := 30.0           # standing lost when it does
const WIN_REP := 1.5              # standing for being on the winning side

## mods: multipliers for the Assembly while the bill is law – buy / sell (prices at its stations), service (fuel
## and repairs), concord (Concord Fleetworks ships), bounty (pirate bounties in its systems), patrols (> 1: one more
## patrol group in each of its systems).
const BILLS := {
	"tariff": {"name": "Tariff Reduction Act", "text": "Cuts the duties on trade between Assembly stations.",
		"pro": "goods at Assembly stations −8 %", "con": "what you sell there earns 5 % less",
		"mods": {"buy": 0.92, "sell": 0.95}},
	"militia": {"name": "Militia Mobilisation Act", "text": "Calls up the militias and puts a premium on every pirate.",
		"pro": "bounties in Assembly space +30 %, an extra patrol in every system", "con": "a militia levy: goods +4 %",
		"mods": {"bounty": 1.3, "patrols": 2.0, "buy": 1.04}},
	"yards": {"name": "Shipyard Subsidy Act", "text": "Public money for Concord Fleetworks – the fleet must grow.",
		"pro": "Concord ships −15 %", "con": "fuel and repairs +15 %",
		"mods": {"concord": 0.85, "service": 1.15}},
	"fuel": {"name": "Fuel Relief Act", "text": "Caps what the depots may charge for fuel and repairs.",
		"pro": "fuel and repairs −30 %", "con": "bounties −10 %",
		"mods": {"service": 0.7, "bounty": 0.9}},
	"export": {"name": "Export Promotion Act", "text": "Rewards every cargo that leaves an Assembly station.",
		"pro": "what you sell earns 8 % more", "con": "goods +4 %",
		"mods": {"sell": 1.08, "buy": 1.04}},
	"austerity": {"name": "Fleet Austerity Act", "text": "Less money for warships, more for the people.",
		"pro": "goods −4 %", "con": "Concord ships +10 %",
		"mods": {"buy": 0.96, "concord": 1.1}},
}

var bill := {}                    # {id, ends, base, vote ("yes"/"no"/""), donated {yes, no}, bribe {side, cost}}
var laws: Array = []              # passed bills in force: {id, until}
var history: Array = []           # newest first: {id, passed, yes, t}
var next_t := 0.0


func reset() -> void:
	bill = {}
	laws.clear()
	history.clear()
	next_t = GameState.play_time + randf_range(20.0, 60.0)


func to_dict() -> Dictionary:
	return {"bill": bill.duplicate(true), "laws": laws.duplicate(true), "history": history.duplicate(true), "next": next_t}


func from_dict(d: Dictionary) -> void:
	bill = d.get("bill", {}).duplicate(true)
	laws = d.get("laws", []).duplicate(true)
	history = d.get("history", []).duplicate(true)
	next_t = float(d.get("next", GameState.play_time + 60.0))


## Called by GameState every frame.
func update() -> void:
	for l in laws.duplicate():
		if GameState.play_time >= float(l["until"]):
			laws.erase(l)
			GameState.news.add("The %s has expired." % BILLS[l["id"]]["name"], "world", Universe.special_system("landfall"))
	if bill.is_empty():
		if GameState.play_time >= next_t:
			new_bill()
	elif GameState.play_time >= float(bill["ends"]):
		resolve()


## A new bill comes to the vote (`id` "" = a random one not in force).
func new_bill(id: String = "") -> void:
	if id == "":
		var pool: Array = BILLS.keys().filter(func(k): return not in_force(k))
		if pool.is_empty():
			pool = BILLS.keys()
		id = pool[randi() % pool.size()]
	bill = {"id": id, "ends": GameState.play_time + randf_range(VOTE_MIN, VOTE_MAX), "base": randf_range(0.35, 0.65),
		"vote": "", "donated": {"yes": 0, "no": 0}, "bribe": {}}
	GameState.news.add("The Assembly votes on the %s – %s" % [BILLS[id]["name"], BILLS[id]["text"]], "world", Universe.special_system("landfall"))


func in_force(id: String) -> bool:
	for l in laws:
		if l["id"] == id:
			return true
	return false


## Chance that the running bill passes (polls – without the bribe, which nobody knows about).
func yes_chance() -> float:
	if bill.is_empty():
		return 0.0
	var c := float(bill["base"])
	match String(bill["vote"]):
		"yes":
			c += VOTE_SWAY
		"no":
			c -= VOTE_SWAY
	c += _donation_sway("yes") - _donation_sway("no")
	return clampf(c, 0.03, 0.97)


func _donation_sway(side: String) -> float:
	return minf(float(bill["donated"].get(side, 0)) / DONATION_STEP * DONATION_SWAY, DONATION_MAX)


## "" = done, otherwise why not. Voting, donating and bribing need the Assembly's entry permit.
func vote(side: String) -> String:
	if bill.is_empty():
		return "No bill on the floor right now."
	if not GameState.has_permit("assembly"):
		return "Only citizens with an entry permit may vote."
	bill["vote"] = side
	GameState.log_msg("You voted %s on the %s." % [side.to_upper(), BILLS[bill["id"]]["name"]], GameState.COL_INFO)
	return ""


func donate(side: String) -> String:
	if bill.is_empty():
		return "No bill on the floor right now."
	if _donation_sway(side) >= DONATION_MAX:
		return "The campaign cannot use more money."
	if not GameState.spend(DONATION_STEP):
		return "Not enough credits."
	bill["donated"][side] = int(bill["donated"].get(side, 0)) + DONATION_STEP
	GameState.log_msg("Party donation: %s to the %s campaign on the %s." % [GameData.fmt_credits(DONATION_STEP), side.to_upper(), BILLS[bill["id"]]["name"]], GameState.COL_INFO)
	return ""


func bribe_cost() -> int:
	return int(round(maxf(float(BRIBE_BASE), GameState.credits * BRIBE_SHARE) / 1000.0)) * 1000


func bribe(side: String) -> String:
	if bill.is_empty():
		return "No bill on the floor right now."
	if not (bill["bribe"] as Dictionary).is_empty():
		return "You have already paid someone on this bill."
	var cost := bribe_cost()
	if not GameState.spend(cost):
		return "Not enough credits."
	bill["bribe"] = {"side": side, "cost": cost}
	GameState.log_msg("%s changed hands in a quiet corridor of The Vote. Now hope nobody talks." % GameData.fmt_credits(cost), GameState.COL_WARN)
	return ""


## The vote: the bill passes or fails; a bribe settles it unless it comes out.
func resolve(force_caught: int = -1) -> Dictionary:
	if bill.is_empty():
		return {}
	var b: Dictionary = bill
	var bd: Dictionary = BILLS[b["id"]]
	var lf := Universe.special_system("landfall")
	var passed := randf() < yes_chance()
	var caught := false
	var br: Dictionary = b["bribe"]
	if not br.is_empty():
		caught = randf() < BRIBE_CAUGHT if force_caught < 0 else force_caught == 1
		if caught:
			GameState.rep.change("assembly", -BRIBE_REP, "bribery")
			GameState.news.add("SCANDAL: a pilot tried to buy votes on the %s. The Senate has seized %s." % [bd["name"], GameData.fmt_credits(int(br["cost"]))], "world", lf)
			GameState.log_msg("Your bribe came out – the money is gone and the Assembly will not forget it.", GameState.COL_BAD)
		else:
			passed = String(br["side"]) == "yes"
	var share := snappedf(yes_chance() * 100.0 + randf_range(-6.0, 6.0), 0.1)
	if not br.is_empty() and not caught:
		share = randf_range(51.0, 58.0) if passed else randf_range(42.0, 49.0)
	share = clampf(share, 51.0, 97.0) if passed else clampf(share, 3.0, 49.0)
	if passed:
		laws = laws.filter(func(l): return l["id"] != b["id"])
		laws.append({"id": b["id"], "until": GameState.play_time + LAW_TIME})
		GameState.news.add("The Assembly passed the %s (%.0f %% yes) – %s, %s, for the next hour." % [bd["name"], share, bd["pro"], bd["con"]], "world", lf)
	else:
		GameState.news.add("The Assembly rejected the %s (%.0f %% yes)." % [bd["name"], share], "world", lf)
	var mine := String(b["vote"])
	if mine != "" and (mine == "yes") == passed and not caught:
		GameState.rep.change("assembly", WIN_REP, "Senate vote")
	history.push_front({"id": b["id"], "passed": passed, "yes": share, "t": GameState.play_time})
	if history.size() > 10:
		history.pop_back()
	bill = {}
	next_t = GameState.play_time + NEXT_BILL
	return {"passed": passed, "caught": caught, "yes": share}


## Product of the multipliers of all laws in force for `key`.
func mod(key: String) -> float:
	var m := 1.0
	for l in laws:
		m *= float(BILLS[l["id"]]["mods"].get(key, 1.0))
	return m


## Price multiplier for a hull bought at a station of faction `f`.
func hull_mult(hid: String, f: String) -> float:
	if f != "assembly":
		return 1.0
	if String(GameData.hulls.get(hid, {}).get("maker", "")) != "concord":
		return 1.0
	return mod("concord")


func minutes_left(t: float) -> int:
	return int(ceil(maxf(0.0, t - GameState.play_time) / 60.0))
