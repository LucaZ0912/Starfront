extends RefCounted
## Package 62, part 2 (Luz): the games of the Grand Centauria, their numbers. The slot machines (three reels, one
## line) and roulette (one wheel, 37 pockets). Both are played for Coins. A pilot's Dexterity and the perk Lucky Hand
## make them a little kinder: a machine's reel is nudged into a pair now and then, the wheel's ball hops one pocket on.
## The house keeps its edge all the same. No class_name: preload it.

const SYMBOLS := ["ore", "cell", "comet", "star", "ring", "seven", "coin"]
const NAMES := {"ore": "Ore", "cell": "Fuel cell", "comet": "Comet", "star": "Star", "ring": "Ring of Lapis", "seven": "Holo seven", "coin": "Coin"}
const WEIGHTS := {"ore": 30, "cell": 26, "comet": 20, "star": 14, "ring": 9, "seven": 4, "coin": 5}      # how often each stands on a reel
const PAY3 := {"ore": 8, "cell": 12, "comet": 15, "star": 30, "ring": 60, "seven": 250, "coin": 100}     # three alike: times the stake
const PAY2 := 2                    # the first two reels alike: times the stake
const SLOT_STAKES := [1, 5, 25]
const JACKPOT_START := 5000        # Coins; it grows with every spin in the house
const JACKPOT_SHARE := 0.04        # … by this much of the stake
const PERK := "lucky_hand"

const WHEEL := [0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26]
const REDS := [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36]
const CHIPS := [1, 5, 25, 100]
const CHIPS_HIGH := [100, 500, 2500]
const LIMIT := 500                 # Coins a seat may stake on one spin …
const LIMIT_HIGH := 25000          # … at the lounge's high table
const OUTSIDE := [["low", "1 to 18"], ["even", "Even"], ["red", "Red"], ["black", "Black"], ["odd", "Odd"], ["high", "19 to 36"]]


## How kind the machines are to this pilot: the chance that a spin without a win is nudged into a pair.
static func slot_luck(dex: int, perk: bool) -> float:
	return clampf((dex - 3) * 0.006, 0.0, 0.03) + (0.02 if perk else 0.0)


## … and the wheel: the chance that the ball hops one pocket on when that is better for you.
static func wheel_luck(dex: int, perk: bool) -> float:
	return clampf((dex - 3) * 0.002, 0.0, 0.01) + (0.006 if perk else 0.0)


static func reel(rng: RandomNumberGenerator) -> String:
	var total := 0
	for s in SYMBOLS:
		total += int(WEIGHTS[s])
	var r := rng.randi() % total
	for s in SYMBOLS:
		r -= int(WEIGHTS[s])
		if r < 0:
			return s
	return "ore"


## One spin: {"reels": [a, b, c], "win": Coins paid (the stake not taken off), "jackpot": bool, "nudged": bool,
## "what": a line about it}. Three Coins at the highest stake take the jackpot.
static func spin(rng: RandomNumberGenerator, luck: float, stake: int, jackpot: int) -> Dictionary:
	var rs := [reel(rng), reel(rng), reel(rng)]
	var nudged := false
	if rs[0] != rs[1] and rs[0] != rs[2] and rng.randf() < luck:
		rs[1] = rs[0]                                    # (a kind hand: the middle reel slips one on)
		nudged = true
	var win := 0
	var jp := false
	var what := "Nothing."
	if rs[0] == rs[1] and rs[1] == rs[2]:
		win = stake * int(PAY3[rs[0]])
		what = "Three of %s: %d times your stake." % [String(NAMES[rs[0]]), int(PAY3[rs[0]])]
		if String(rs[0]) == "coin" and stake == int(SLOT_STAKES[SLOT_STAKES.size() - 1]):
			jp = true
			win += jackpot
			what = "Three Coins at the highest stake: the JACKPOT."
	elif rs[0] == rs[1]:
		win = stake * PAY2
		what = "A pair of %s: twice your stake." % String(NAMES[rs[0]])
	return {"reels": rs, "win": win, "jackpot": jp, "nudged": nudged, "what": what}


# ---------------------------------------------------------------- roulette

static func is_red(n: int) -> bool:
	return n in REDS


## Every field you can bet on: "n0" … "n36", the six outside bets, the dozens "d1" … "d3", the columns "c1" … "c3".
static func bet_ok(key: String) -> bool:
	if key.begins_with("n") and key.substr(1).is_valid_int():
		return int(key.substr(1)) >= 0 and int(key.substr(1)) <= 36
	return key in ["low", "high", "even", "odd", "red", "black", "d1", "d2", "d3", "c1", "c2", "c3"]


## What a bet on `key` gives back for one Coin staked when `n` comes (the stake included; 0: lost).
static func bet_pays(key: String, n: int) -> int:
	if key.begins_with("n"):
		return 36 if int(key.substr(1)) == n else 0
	if n == 0:
		return 0
	match key:
		"low":
			return 2 if n <= 18 else 0
		"high":
			return 2 if n >= 19 else 0
		"even":
			return 2 if n % 2 == 0 else 0
		"odd":
			return 2 if n % 2 == 1 else 0
		"red":
			return 2 if is_red(n) else 0
		"black":
			return 2 if not is_red(n) else 0
		"d1", "d2", "d3":
			return 3 if (n - 1) / 12 == int(key.substr(1)) - 1 else 0
		"c1", "c2", "c3":
			return 3 if (n - 1) % 3 == int(key.substr(1)) - 1 else 0
	return 0


## What a seat's bets ({key: Coins}) give back when `n` comes.
static func settle(bets: Dictionary, n: int) -> int:
	var back := 0
	for k in bets:
		back += int(bets[k]) * bet_pays(String(k), n)
	return back


## The wheel turns: {"n": the number, "from": where the ball first lay (-1: it did not hop)}. With `luck` the ball
## hops one pocket on if that gives `bets` more back.
static func roll(rng: RandomNumberGenerator, luck: float, bets: Dictionary) -> Dictionary:
	var i := rng.randi() % WHEEL.size()
	var n: int = WHEEL[i]
	var nx: int = WHEEL[(i + 1) % WHEEL.size()]
	if not bets.is_empty() and settle(bets, nx) > settle(bets, n) and rng.randf() < luck:
		return {"n": nx, "from": n}
	return {"n": n, "from": -1}


# ---------------------------------------------------------------- the cards (package 62, part 3)

## Package 62, part 3 (Luz): the house's deck: 52 cards in the four suits of Drift (comets, moons, suns, nebulae),
## 2 to 10, then Pilot, Captain, Admiral and the Ace. A card is [rank 2 … 14, suit 0 … 3].
const CARD_SUITS := ["comet", "moon", "sun", "nebula"]
const SUIT_NAMES := ["Comets", "Moons", "Suns", "Nebulae"]
const RANK_LABEL := {11: "P", 12: "C", 13: "Ad", 14: "A"}
const RANK_NAME := {11: "Pilot", 12: "Captain", 13: "Admiral", 14: "Ace"}
const BJ_DECKS := 6                # blackjack is dealt from a shoe of six decks, shuffled for every round
const POKER_BUYINS := [100, 200, 500]          # Coins to sit down at the poker table …
const POKER_BUYINS_HIGH := [5000]              # … and at the lounge's high table
const POKER_BLINDS := 50           # the big blind is the buy-in through this, the small blind half of it
const RAKE := 0.05                 # the house's share of a poker pot that has seen the flop …
const RAKE_CAP := 25               # … at most this many Coins …
const RAKE_CAP_HIGH := 1000        # … at the high table
const HAND_NAMES := ["A high card", "A pair", "Two pairs", "Three of a kind", "A straight", "A flush", "A full house", "Four of a kind", "A straight flush"]
const STYLES := {
	"careful": {"name": "careful", "margin": 0.08, "raise": 0.8, "bluff": 0.03},
	"loose": {"name": "loose", "margin": -0.06, "raise": 0.72, "bluff": 0.08},
	"bluffer": {"name": "a bluffer", "margin": 0.0, "raise": 0.74, "bluff": 0.22},
}
## The story's people at the poker tables, once the story has brought you over the Veil ("from"): how likely they
## sit at the low table and at the high one in a given hour.
const POKER_SPECIAL := {
	"rook": {"name": "Rook Varga", "job": "gunner", "style": "bluffer", "stars": 4, "from": "w59_left", "low": 0.5, "high": 0.25,
		"line": "\"I never bluff. Ask anyone I have bluffed.\""},
	"dan": {"name": "Dan T. Rogue", "job": "station owner", "style": "careful", "stars": 3, "from": "w59_left", "low": 0.3, "high": 0.4,
		"line": "\"You still owe me a whiskey. Let's make it two.\""},
}


static func rank_label(r: int) -> String:
	return String(RANK_LABEL.get(r, str(r)))


static func card_name(c: Array) -> String:
	return "%s of %s" % [String(RANK_NAME.get(int(c[0]), str(int(c[0])))), String(SUIT_NAMES[int(c[1])])]


## `decks` decks of 52, shuffled; draw with pop_back().
static func new_deck(rng: RandomNumberGenerator, decks: int = 1) -> Array:
	var out: Array = []
	for d in decks:
		for r in range(2, 15):
			for s in 4:
				out.append([r, s])
	for i in range(out.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = out[i]
		out[i] = out[j]
		out[j] = tmp
	return out


# ---------------------------------------------------------------- blackjack

static func bj_total(hand: Array) -> int:
	var t := 0
	var aces := 0
	for c in hand:
		var r := int(c[0])
		if r == 14:
			aces += 1
			t += 11
		else:
			t += mini(r, 10)
	while t > 21 and aces > 0:
		t -= 10
		aces -= 1
	return t


## An ace still counts eleven in this hand.
static func bj_soft(hand: Array) -> bool:
	var hard := 0
	var ace := false
	for c in hand:
		hard += 1 if int(c[0]) == 14 else mini(int(c[0]), 10)
		ace = ace or int(c[0]) == 14
	return ace and hard + 10 <= 21


static func bj_natural(hand: Array) -> bool:
	return hand.size() == 2 and bj_total(hand) == 21


## How kind the cards are to this pilot: the chance that a card which would take you over 21 slips back for the
## next of the shoe.
static func bj_luck(dex: int, perk: bool) -> float:
	return clampf((dex - 3) * 0.004, 0.0, 0.02) + (0.015 if perk else 0.0)


## What a hand gives back for its stake (the stake included; 0: lost). A blackjack pays 3 to 2, a win 1 to 1, a
## stand-off gives the stake back. The house draws to 16 and stands on 17.
static func bj_back(stake: int, hand: Array, house: Array) -> int:
	var pt := bj_total(hand)
	if pt > 21:
		return 0
	var nat := bj_natural(hand)
	var hnat := bj_natural(house)
	if nat and not hnat:
		return stake + stake * 3 / 2
	if hnat and not nat:
		return 0
	var ht := bj_total(house)
	if ht > 21 or pt > ht:
		return stake * 2
	return stake if pt == ht else 0


## How a guest plays a hand against the house's open card: "hit", "stand" or "double".
static func bj_guest(hand: Array, up: int) -> String:
	var t := bj_total(hand)
	var upv := 11 if up == 14 else mini(up, 10)
	if bj_soft(hand):
		return "hit" if t <= 17 or (t == 18 and upv >= 9) else "stand"
	if hand.size() == 2 and (t == 11 or (t == 10 and upv <= 9)):
		return "double"
	if t <= 11:
		return "hit"
	if t >= 17:
		return "stand"
	if t == 12:
		return "stand" if upv >= 4 and upv <= 6 else "hit"
	return "stand" if upv <= 6 else "hit"


# ---------------------------------------------------------------- poker

static func _straight_top(has: Array) -> int:
	var run := 0
	for r in range(14, 1, -1):
		run = run + 1 if has[r] else 0
		if run >= 5:
			return r + 4
	if run >= 4 and has[14]:                             # the wheel: 5 4 3 2 and the ace
		return 5
	return 0


static func _pack(cat: int, ks: Array) -> int:
	var v := cat
	for i in 5:
		v = v * 15 + (int(ks[i]) if i < ks.size() else 0)
	return v


## The worth of the best five out of five to seven cards, as one number to compare (the higher, the better).
static func hand_value(cards: Array) -> int:
	var cnt: Array = []
	cnt.resize(15)
	cnt.fill(0)
	var sc := [0, 0, 0, 0]
	for c in cards:
		cnt[int(c[0])] += 1
		sc[int(c[1])] += 1
	var flush := -1
	for s in 4:
		if sc[s] >= 5:
			flush = s
	var has: Array = []
	has.resize(15)
	if flush >= 0:
		has.fill(false)
		for c2 in cards:
			if int(c2[1]) == flush:
				has[int(c2[0])] = true
		var sf := _straight_top(has)
		if sf > 0:
			return _pack(8, [sf])
	var quads := 0
	var trips: Array = []
	var pairs: Array = []
	var singles: Array = []
	for r in range(14, 1, -1):
		match int(cnt[r]):
			4:
				quads = r
			3:
				trips.append(r)
			2:
				pairs.append(r)
			1:
				singles.append(r)
	if quads > 0:
		var k := 0
		for r2 in range(14, 1, -1):
			if r2 != quads and int(cnt[r2]) > 0:
				k = r2
				break
		return _pack(7, [quads, k])
	if trips.size() >= 2 or (trips.size() == 1 and pairs.size() >= 1):
		return _pack(6, [trips[0], maxi(int(trips[1]) if trips.size() >= 2 else 0, int(pairs[0]) if pairs.size() >= 1 else 0)])
	if flush >= 0:
		var five: Array = []
		for r3 in range(14, 1, -1):
			if has[r3] and five.size() < 5:
				five.append(r3)
		return _pack(5, five)
	for r4 in 15:
		has[r4] = int(cnt[r4]) > 0
	var st := _straight_top(has)
	if st > 0:
		return _pack(4, [st])
	if trips.size() == 1:
		return _pack(3, [trips[0]] + singles.slice(0, 2))
	if pairs.size() >= 2:
		var rest: Array = singles.duplicate()
		if pairs.size() >= 3:
			rest.append(pairs[2])
		rest.sort()
		return _pack(2, [pairs[0], pairs[1], rest[rest.size() - 1] if not rest.is_empty() else 0])
	if pairs.size() == 1:
		return _pack(1, [pairs[0]] + singles.slice(0, 3))
	return _pack(0, singles.slice(0, 5))


static func hand_name(value: int) -> String:
	return String(HAND_NAMES[clampi(value / 759375, 0, 8)])        # (15 to the fifth)


## How good two cards are with this board: the share of the pots they take against one hand dealt at random
## (0 … 1), tried `n` times.
static func poker_equity(hole: Array, board: Array, rng: RandomNumberGenerator, n: int = 60) -> float:
	var used := {}
	for c in hole + board:
		used[int(c[0]) * 4 + int(c[1])] = true
	var rest: Array = []
	for r in range(2, 15):
		for s in 4:
			if not used.has(r * 4 + s):
				rest.append([r, s])
	var need := 2 + 5 - board.size()
	var score := 0.0
	for i in n:
		for k in need:
			var j := k + rng.randi() % (rest.size() - k)
			var tmp = rest[k]
			rest[k] = rest[j]
			rest[j] = tmp
		var full: Array = board + rest.slice(2, need)
		var mine := hand_value(hole + full)
		var theirs := hand_value([rest[0], rest[1]] + full)
		score += 1.0 if mine > theirs else (0.5 if mine == theirs else 0.0)
	return score / n


## The pots of a hand: what every seat has put in (`totals`), who has folded, the worth of every hand that is still
## in. Out comes [{"amount", "winners": [seat]}]: the main pot first, then the side pots of those who had more.
static func poker_pots(totals: Array, folded: Array, values: Array) -> Array:
	var levels: Array = []
	for i in totals.size():
		if not bool(folded[i]) and int(totals[i]) > 0 and not int(totals[i]) in levels:
			levels.append(int(totals[i]))
	levels.sort()
	var out: Array = []
	var prev := 0
	for lv in levels:
		var amount := 0
		for t in totals:
			amount += clampi(int(t), prev, int(lv)) - prev
		var best := -1
		var winners: Array = []
		for i2 in totals.size():
			if bool(folded[i2]) or int(totals[i2]) < int(lv):
				continue
			if int(values[i2]) > best:
				best = int(values[i2])
				winners = [i2]
			elif int(values[i2]) == best:
				winners.append(i2)
		out.append({"amount": amount, "winners": winners})
		prev = int(lv)
	var over := 0                                         # (what a seat that folded had in above all the others)
	for t2 in totals:
		over += maxi(0, int(t2) - prev)
	if over > 0 and not out.is_empty():
		out[out.size() - 1]["amount"] = int(out[out.size() - 1]["amount"]) + over
	return out


## What a guest does: {"move": "fold" | "call" | "raise", "to": the bet raised to}. `hs`: how good the hand is
## (poker_equity), `opp`: how many others are still in, `to_call`: what it costs to stay, `min_to`: the least a
## raise must go to, `top`: all the guest can put in this round (the bet so far and the stack).
static func poker_ai(rng: RandomNumberGenerator, hs: float, style: String, stars: int, opp: int, to_call: int, pot: int, bet: int, min_to: int, top: int, bb: int, can_raise: bool) -> Dictionary:
	var st: Dictionary = STYLES.get(style, STYLES["careful"])
	var eff := pow(clampf(hs + (5 - clampi(stars, 1, 5)) * 0.04 * rng.randf_range(-1.0, 1.0), 0.02, 0.99), 1.0 + 0.35 * maxi(0, opp - 1))
	var size := func(lo: float, hi: float) -> int:
		var want := bet + to_call + int(maxf(float(bb), pot * rng.randf_range(lo, hi)))
		return mini(top, maxi(min_to, (want / maxi(1, bb)) * maxi(1, bb)))
	can_raise = can_raise and top > bet + to_call
	if to_call <= 0:
		if can_raise and ((eff > float(st["raise"]) - 0.2 and rng.randf() < 0.75) or rng.randf() < float(st["bluff"])):
			return {"move": "raise", "to": size.call(0.45, 0.8)}
		return {"move": "call", "to": 0}
	var need := float(to_call) / float(pot + to_call)
	var weight := 0.25 * float(to_call) / float(maxi(1, top - bet))
	if can_raise and eff > float(st["raise"]) and rng.randf() < 0.6:
		return {"move": "raise", "to": size.call(0.6, 1.0)}
	if eff > need + float(st["margin"]) + weight:
		return {"move": "call", "to": 0}
	if can_raise and weight < 0.08 and rng.randf() < float(st["bluff"]) * 0.4:
		return {"move": "raise", "to": size.call(0.6, 1.0)}
	return {"move": "fold", "to": 0}


## How well this pilot reads the table: the chance in a hand to see a tell of one of the guests.
static func tell_luck(dex: int, perk: bool) -> float:
	return clampf((dex - 3) * 0.05, 0.0, 0.25) + (0.15 if perk else 0.0)


## What a tell says about a hand as good as `hs`.
static func tell_text(hs: float) -> String:
	if hs >= 0.66:
		return "sits very still: a strong hand"
	if hs <= 0.42:
		return "drums on the cloth: a weak hand"
	return "gives nothing away"


## Who sits at a poker table in this hour: three guests with a name, a trade, a way of playing and a strength
## ({name, job, style, stars, who, line}); the story's people among them once `flags` let them.
static func poker_guests(high: bool, hour: int, flags: Dictionary) -> Array:
	var MG = load("res://data/minigames.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("poker_%s_%d" % ["high" if high else "low", hour])
	var out: Array = []
	for k in POKER_SPECIAL:
		var sp: Dictionary = POKER_SPECIAL[k]
		var roll := rng.randf()
		if bool(flags.get(String(sp["from"]), false)) and roll < float(sp["high" if high else "low"]) and out.size() < 2:
			out.append({"name": String(sp["name"]), "job": String(sp["job"]), "style": String(sp["style"]), "stars": int(sp["stars"]), "who": String(k), "line": String(sp["line"])})
	while out.size() < 3:
		out.append(poker_guest(rng, high))
	return out


static func poker_guest(rng: RandomNumberGenerator, high: bool) -> Dictionary:
	var MG = load("res://data/minigames.gd")
	var jobs: Array = ["shipping heir", "mining baron", "fund manager", "senator's child", "holo star", "arms broker"] if high else MG.JOBS
	return {"name": "%s %s" % [String(MG.FIRST[rng.randi() % MG.FIRST.size()]), String(MG.LAST[rng.randi() % MG.LAST.size()])], "job": String(jobs[rng.randi() % jobs.size()]),
		"style": String(STYLES.keys()[rng.randi() % STYLES.size()]), "stars": rng.randi_range(3, 5) if high else rng.randi_range(1, 4), "who": "", "line": ""}
