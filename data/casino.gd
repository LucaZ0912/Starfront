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
