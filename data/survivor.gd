extends RefCounted
## Package 62a, part 7 (Luz, 23 Nov 2026): Survivor, a game inside the game. You stand alone on a very large
## hologram; the others come in swarms from all sides; your weapons fire by themselves, you only walk (and dodge).
## Who is put out drops shards of light; enough of them make a level, and with every level you pick one of three
## cards: a new weapon, a level of one you carry, a bonus, a level of a bonus (five places for weapons, five for boni,
## five levels each). A weapon at level 5 and its own bonus make its ultimate. A stage lasts fifteen minutes.
## No class_name: load("res://data/survivor.gd").
##
## Part 7a, the core: the first stage (Outbreak), the shamblers, shards and levels, Pulse and Laser.
## Part 7b, the arsenal: all six weapons, the six boni, the six ultimates, the choice of your first weapon.
## Part 7c-2, the stage: runners, haulers, spitters, bloaters, shieldbearers, howlers, an alpha every minute; the
## flock, the ring, the sleepers, the wall, the blackout, supply drops; crates and what they hold; The Foreman at
## 7:30 and The Brood at the end, each inside walls of light.
## Part 7c-3, what is round it: four more weapons (Mine Layer, Sentry, Cryo Spray, Gravity Well), five more boni
## (Stabiliser, Overclock, Shield Cell, Scavenger, Lucky Find), four more ultimates; cores, and what they buy at
## the console in the lobby (to unlock, fine tuning, rerolls, a last chance); the choice of stage.
## Part 8 (Luz): a second stage, AI Takeover: a city quarter by night, long after the machines took it. It opens
## once you have put out The Foreman on Outbreak. Part 8a: its ground, the Enforcers (the swarm), Scouts, Gunners.
## Part 8b: Bulwarks, Seekers, Jammers, Hunters; searchlights, reinforcements, the kill line, the EMP; Override.
## Part 8c: its two bosses: The Warden at 7:30, The Core (with its four pylons) when the time is up.

const RUN_TIME := 900.0            # a stage: fifteen minutes
const SLOTS := 5                   # places for weapons, and as many for boni (Luz: five are plenty; there is more to carry than places)
const MAX_LEVEL := 5               # of a weapon, of a bonus
const ULT := 6                     # a weapon's level once it is its ultimate
const HEALTH := 100.0              # your one bar
const HURT_GAP := 0.45             # seconds nothing can hurt you after a hit
const MAGNET := 34.0               # art px: shards nearer than this fly to you
const MAX_FOES := 600              # at once
## The flood (Luz, 23 Nov 2026): from FLOOD_FROM on the swarm comes in absurd numbers until the time is up: FLOOD_RATE
## more of them a second, up to FLOOD_FOES at once, each with only FLOOD_HP of the health its kind would have by then.
const FLOOD_FROM := 780.0
const FLOOD_RATE := 90.0
const FLOOD_FOES := 1000
const FLOOD_HP := 0.4
const HEAL := 30.0                 # a med cell
const START_WEAPON := "pulse"

## The stages: id, name, what it is; "open": it is built; "need": the boss you must have put out before it opens to you;
## "col": its colour in the windows.
const STAGES := [
	{"id": "outbreak", "name": "Outbreak", "text": "A colony under quarantine, by night. Whoever lived here still walks.", "open": true, "col": Color(0.4, 1.0, 0.6)},
	{"id": "takeover", "name": "AI Takeover", "text": "A city by night, long after the machines took it. What moves has red eyes.", "open": true, "need": "foreman",
		"need_text": "put out The Foreman on Outbreak", "col": Color(1.0, 0.42, 0.42)},
	{"id": "whiteout", "name": "Whiteout", "text": "A moon of ice, by day. What moves is a dark shape in the snow.", "open": true, "need": "warden",
		"need_text": "put out The Warden on AI Takeover", "col": Color(0.6, 0.92, 1.0)},
	{"id": "lab", "name": "Alien Laboratory", "text": "A laboratory that is not ours: vast halls, wide corridors, and what they keep in the tanks.", "open": true, "need": "worm",
		"need_text": "put out The Ice Worm on Whiteout", "col": Color(0.55, 1.0, 0.35)},
]

## The weapons (Luz). "levels": what it does at level 1 … 5; "up": what a level brings, in words; "bonus": the
## bonus that makes its ultimate ("ult", "ult_text") once the weapon is at level 5.
##   pulse:      a field of radius "r" (art px) round you hurts all in it by "dmg" every "every" seconds
##   laser:      every "every" seconds "n" beams at the nearest within "reach", "dmg" each
##   plasma:     every "every" seconds "n" grenades thrown near you; each bursts in a radius "r" for "dmg"
##   drone:      a drone flies with you; every "every" seconds it turns its gun once round and fires "n" shots one after
##               another, "dmg" each, as far as "reach"
##   superlaser: every "every" seconds a beam as long as "reach" sweeps a quarter of the round; what it touches is out
##   blade:      every "every" seconds "n" blades dart away from you for "time" seconds, cut what they touch ("dmg" a
##               pass), bounce at the edge of the picture and dart back
##   mines:      every "every" seconds "n" mines where you walk; one goes off (radius "r", "dmg") when one of them
##               steps on it; it lies there for "time" seconds at most
##   sentry:     every "every" seconds "n" small guns set down; each fires at whoever is nearest to it (within
##               "reach", every "rate" seconds, "dmg") for "time" seconds
##   cryo:       every "every" seconds a cone of cold as far as "reach" the way you walk ("arc": half its angle): all
##               in it are hurt by "dmg" and frozen for "time" seconds
##   gravity:    every "every" seconds a sphere among them: for "time" seconds it pulls all within "r" to its middle
##               and hurts them by "dmg" twice a second
##   taser:      (Luz) every "every" seconds a cone of lightning right before you, the way you look, as far as
##               "reach" ("arc": half its angle): all in it are hurt by "dmg" and stunned for "stun" seconds
##   blackhole:  (Luz) the weapon for the end of a run: every "every" seconds (very rarely) a black hole the way you
##               look; it drifts on at "speed" towards the edge of the picture and pulls all within "r" into it: who
##               reaches its middle is out (the tough ones take "tough" four times a second instead). "from": the
##               level of the run from which its card can come (it cannot be the weapon you begin with)
## "kb": how much further than usual its hits throw them back (1 when not named; 0: not at all, for what pulls them in)
const WEAPONS := {
	"pulse": {"name": "Pulse", "text": "A field round you that hurts all in it and throws them back, again and again.", "up": "A wider field, more damage, a shorter interval.", "kb": 2.4,
		"bonus": "amp", "ult": "Nova Field", "ult_text": "The field stands for good, burns without a pause and slows all in it.",
		"levels": [{"r": 44.0, "dmg": 4.0, "every": 1.4}, {"r": 52.0, "dmg": 6.0, "every": 1.25}, {"r": 60.0, "dmg": 8.0, "every": 1.1},
			{"r": 70.0, "dmg": 10.0, "every": 0.95}, {"r": 82.0, "dmg": 13.0, "every": 0.8}]},      # (Luz, 24 Nov 2026: weaker, and it throws them back far)
	"laser": {"name": "Laser", "text": "A beam at whoever is nearest, again and again.", "up": "More beams at once, more damage.", "reach": 230.0,
		"bonus": "coolant", "ult": "Prism Array", "ult_text": "Every beam jumps on to two more of them.",
		"levels": [{"n": 1, "dmg": 10.0, "every": 1.0}, {"n": 1, "dmg": 14.0, "every": 0.95}, {"n": 2, "dmg": 14.0, "every": 0.9},
			{"n": 3, "dmg": 17.0, "every": 0.85}, {"n": 4, "dmg": 22.0, "every": 0.8}]},
	"plasma": {"name": "Plasma Grenades", "text": "Grenades thrown near you. Each bursts and hurts all round it.", "up": "More grenades, a wider burst, more damage.",
		"bonus": "reactor", "ult": "Plasma Rain", "ult_text": "Grenades fall all over the field you see.",
		"levels": [{"n": 1, "r": 26.0, "dmg": 14.0, "every": 2.2}, {"n": 2, "r": 28.0, "dmg": 16.0, "every": 2.1}, {"n": 2, "r": 32.0, "dmg": 20.0, "every": 2.0},
			{"n": 3, "r": 36.0, "dmg": 24.0, "every": 1.9}, {"n": 4, "r": 42.0, "dmg": 30.0, "every": 1.8}]},
	"drone": {"name": "Drone", "text": "A drone flies with you. Its gun turns once round and fires shot by shot, all ways in turn.", "up": "More shots, a shorter interval.", "reach": 190.0,
		"bonus": "magnet", "ult": "Carrier Swarm", "ult_text": "Three drones fly with you, each firing its own round, and the shots go through whoever they hit.",
		"levels": [{"n": 6, "dmg": 8.0, "every": 2.4}, {"n": 8, "dmg": 9.0, "every": 2.2}, {"n": 10, "dmg": 10.0, "every": 2.0},
			{"n": 12, "dmg": 12.0, "every": 1.8}, {"n": 16, "dmg": 14.0, "every": 1.5}]},
	"superlaser": {"name": "Superlaser", "text": "A mighty beam sweeps a quarter of the round. What it touches is out. It fires rarely.", "up": "A longer beam, a shorter interval.",
		"bonus": "nanite", "ult": "Sunlance", "ult_text": "The beam sweeps the whole round.", "tough": 60.0,
		"levels": [{"reach": 210.0, "every": 18.0}, {"reach": 245.0, "every": 16.5}, {"reach": 280.0, "every": 15.0}, {"reach": 320.0, "every": 13.5},
			{"reach": 370.0, "every": 12.0}]},                  # (Luz, 24 Nov 2026: it comes more rarely and reaches further)
	"blade": {"name": "Silverblade Drone", "text": "Darts away from you, cuts what it touches, bounces at the edge of the picture and darts back.",
		"up": "It lasts longer, cuts deeper, more of them at once.", "bonus": "servo", "ult": "Silver Storm",
		"ult_text": "One more blade, and they stay for good. Their trails burn in every colour and cut what they touch.",
		"levels": [{"n": 1, "dmg": 9.0, "time": 3.0, "every": 6.0}, {"n": 1, "dmg": 11.0, "time": 3.5, "every": 6.0}, {"n": 2, "dmg": 13.0, "time": 4.0, "every": 6.0},
			{"n": 2, "dmg": 16.0, "time": 5.0, "every": 6.0}, {"n": 3, "dmg": 20.0, "time": 6.0, "every": 6.0}]},
	"mines": {"name": "Mine Layer", "text": "Lays mines where you walk. One goes off when one of them steps on it.", "up": "More mines at once, a wider burst, more damage.",
		"bonus": "stabiliser", "ult": "Minefield", "ult_text": "Mines fall in a ring round you, and each arms itself once more.", "time": 18.0,
		"levels": [{"n": 1, "r": 24.0, "dmg": 18.0, "every": 2.6}, {"n": 1, "r": 26.0, "dmg": 24.0, "every": 2.3}, {"n": 2, "r": 28.0, "dmg": 28.0, "every": 2.3},
			{"n": 2, "r": 32.0, "dmg": 34.0, "every": 2.0}, {"n": 3, "r": 36.0, "dmg": 42.0, "every": 1.8}]},
	"sentry": {"name": "Sentry", "text": "Sets down a small gun. It fires at whoever is nearest to it for a while.", "up": "It stays longer and hits harder; later two of them.",
		"bonus": "overclock", "ult": "Battery", "ult_text": "Three guns that stay for as long as you stay near them.", "reach": 120.0, "rate": 0.4,
		"levels": [{"n": 1, "dmg": 7.0, "time": 6.0, "every": 9.0}, {"n": 1, "dmg": 9.0, "time": 7.0, "every": 9.0}, {"n": 1, "dmg": 11.0, "time": 8.0, "every": 8.0},
			{"n": 2, "dmg": 12.0, "time": 8.0, "every": 8.0}, {"n": 2, "dmg": 15.0, "time": 10.0, "every": 7.0}]},
	"cryo": {"name": "Cryo Spray", "text": "A cone of cold the way you walk. Who stands in it freezes for a while.", "up": "A longer cone, a longer freeze, more damage.",
		"bonus": "shieldcell", "ult": "Absolute Zero", "ult_text": "A wave of frost all round you. What is frozen shatters at the next hit.", "arc": 0.55,
		"levels": [{"reach": 60.0, "dmg": 5.0, "time": 1.2, "every": 3.4}, {"reach": 68.0, "dmg": 7.0, "time": 1.4, "every": 3.2}, {"reach": 76.0, "dmg": 9.0, "time": 1.6, "every": 3.0},
			{"reach": 86.0, "dmg": 12.0, "time": 1.9, "every": 2.8}, {"reach": 98.0, "dmg": 15.0, "time": 2.2, "every": 2.6}]},
	"gravity": {"kb": 0.0, "name": "Gravity Well", "text": "A sphere thrown among them. It pulls all near it to one point and wears them down.", "up": "A wider pull, it lasts longer, more damage.",
		"bonus": "scavenger", "ult": "Singularity", "ult_text": "At its end it crushes what it has pulled in and sends you the shards.",
		"levels": [{"r": 46.0, "dmg": 4.0, "time": 2.5, "every": 8.0}, {"r": 52.0, "dmg": 5.0, "time": 2.8, "every": 7.5}, {"r": 58.0, "dmg": 6.0, "time": 3.2, "every": 7.0},
			{"r": 66.0, "dmg": 8.0, "time": 3.6, "every": 6.5}, {"r": 76.0, "dmg": 10.0, "time": 4.0, "every": 6.0}]},
	"taser": {"name": "Taser", "text": "A cone of lightning right before you, the way you look. Who stands in it is hurt and stunned for a moment.",
		"up": "A longer cone, more damage, a shorter interval.", "bonus": "capacitor", "ult": "Chain Lightning", "ult_text": "The shock jumps on from everyone it hits to three more near them.",
		"stun": 0.35, "arc": 0.6,
		"levels": [{"reach": 40.0, "dmg": 12.0, "every": 0.9}, {"reach": 45.0, "dmg": 15.0, "every": 0.8}, {"reach": 50.0, "dmg": 18.0, "every": 0.7}, {"reach": 56.0, "dmg": 22.0, "every": 0.6},
			{"reach": 64.0, "dmg": 27.0, "every": 0.5}]},
	"blackhole": {"kb": 0.0, "name": "Blackhole Gun", "text": "Fires a black hole the way you look. It drifts on towards the edge of the picture and swallows all that comes near it. It fires very rarely.",
		"up": "A wider pull, a shorter interval.", "bonus": "massdriver", "ult": "Event Horizon", "ult_text": "Three black holes at once, spread like a fan.", "speed": 34.0, "tough": 45.0,
		"from": 10,
		"levels": [{"r": 50.0, "every": 28.0}, {"r": 58.0, "every": 25.0}, {"r": 66.0, "every": 22.0}, {"r": 76.0, "every": 19.0}, {"r": 88.0, "every": 16.0}]},
	# (Luz, 23 Nov 2026) orbs of plasma on a round about you: "n" of them at "r" from you for "time" seconds, then "every" seconds until they come
	# again; what one touches takes "dmg" a pass. "turn": how fast they go round (radians a second); "burst": seconds between the Fusion Halo's bursts.
	"orbs": {"name": "Plasma Orbs", "text": "Orbs of plasma circle you for a while and burn what they touch.", "up": "More orbs, a wider round, they stay longer.",
		"bonus": "gyro", "ult": "Fusion Halo",
		"ult_text": "The orbs stay for good, a second ring turns the other way further out, and every few seconds a ring of plasma bursts out from them.", "turn": 3.2, "burst": 5.0,
		"levels": [{"n": 1, "r": 38.0, "dmg": 10.0, "time": 4.0, "every": 9.0}, {"n": 2, "r": 42.0, "dmg": 12.0, "time": 4.5, "every": 9.0}, {"n": 2, "r": 48.0, "dmg": 14.0, "time": 5.0, "every": 8.5},
			{"n": 3, "r": 54.0, "dmg": 17.0, "time": 5.5, "every": 8.0}, {"n": 4, "r": 62.0, "dmg": 20.0, "time": 6.0, "every": 7.5}]},
}
const WEAPON_ORDER := ["pulse", "laser", "plasma", "drone", "superlaser", "blade", "mines", "sentry", "cryo", "gravity", "taser", "blackhole", "orbs"]

## The boni: each helps all you carry, level by level (five), and belongs to one weapon besides (its ultimate).
const BONI := {
	"amp": {"name": "Field Amplifier", "text": "Wider fields and bursts, longer reach."},
	"coolant": {"name": "Coolant Loop", "text": "Shorter intervals for all your weapons."},
	"reactor": {"name": "Reactor Tuning", "text": "More damage from all your weapons."},
	"magnet": {"name": "Magnet Coil", "text": "Shards fly to you from farther off."},
	"nanite": {"name": "Nanite Weave", "text": "More health, and it comes back slowly."},
	"servo": {"name": "Servo Frame", "text": "You walk faster."},
	"stabiliser": {"name": "Stabiliser", "text": "What you set going lasts longer: blades, orbs, mines, guns, the cold, the pull, and what a crate gives you."},
	"overclock": {"name": "Overclock", "text": "Now and then one more: a beam, a grenade, a shot, a blade, a mine."},
	"shieldcell": {"name": "Shield Cell", "text": "Takes one hit for you, then charges again."},
	"scavenger": {"name": "Scavenger", "text": "Shards are worth more."},
	"lucky": {"name": "Lucky Find", "text": "Supply drops come sooner, and a weapon crate holds three or five rewards more often."},
	"capacitor": {"name": "Capacitor", "text": "Now and then a hit strikes twice as hard."},
	"massdriver": {"name": "Mass Driver", "text": "Whatever you hit is thrown back further (not by what pulls them in: the Gravity Well, the Blackhole Gun)."},
	"gyro": {"name": "Gyroscope", "text": "What circles or darts for you is faster: orbs turn faster, blades fly faster, the drone's gun turns faster."},
}
const BONUS_ORDER := ["amp", "coolant", "reactor", "magnet", "nanite", "servo", "stabiliser", "overclock", "shieldcell", "scavenger", "lucky", "capacitor", "massdriver", "gyro"]

## The others (part 7c-2: the whole stage). hp at the start of a stage (it grows with the time; not a boss's),
## speed (art px a second; you walk 58), what a touch costs you, its size (art px), the shards it drops.
##   "tough": the superlaser and the bomb do not put it out at once
##   "beh":   how it goes about it: 0 walks at you; 1 runs in a zigzag; 2 the hauler (winds up and stamps when it is
##            near); 3 the spitter (keeps its distance, spits); 4 the howler (stands and howls: those near it walk
##            faster); 5 flies straight on, over everything; 8 the scout (runs in a zigzag, crouches near you, leaps);
##            9 the gunner (keeps its distance, takes aim along a line, fires three bolts along it); 10 the bulwark
##            (walks at you, stops now and then and lobs a shell onto a marked spot); 11 the seeker (rolls straight
##            at you, arms near you, goes off: it hurts the machines round it too, and goes off when put out); 12 the
##            jammer (keeps well back: the machines near it carry a shield while it lives); from 20 on a boss:
##            20 The Foreman, 21 The Brood, 22 The Warden, 23 The Core, 24 a pylon of The Core; 13 the burrower (part
##            9a: it runs under the ice, where nothing reaches it and it touches nobody; under you it stops, a mark
##            shows where, it breaks out; it stays above for a while, then it dives again)
##   "mass":  how little a hit throws it back (1 as a shambler, 0 not at all)
##   "shield": what its shield takes before it breaks
const FOES := {
	"shambler": {"name": "Shambler", "hp": 8.0, "speed": 19.0, "dmg": 6.0, "r": 5.0, "xp": 1, "tough": false, "beh": 0, "mass": 1.0},
	"runner": {"name": "Runner", "hp": 5.0, "speed": 44.0, "dmg": 5.0, "r": 4.5, "xp": 1, "tough": false, "beh": 1, "mass": 1.2},
	"hauler": {"name": "Hauler", "hp": 150.0, "speed": 14.0, "dmg": 12.0, "r": 9.0, "xp": 10, "tough": true, "beh": 2, "mass": 0.12},
	"spitter": {"name": "Spitter", "hp": 14.0, "speed": 21.0, "dmg": 5.0, "r": 5.0, "xp": 3, "tough": false, "beh": 3, "mass": 1.0},
	"bloater": {"name": "Bloater", "hp": 36.0, "speed": 13.0, "dmg": 8.0, "r": 7.5, "xp": 4, "tough": false, "beh": 0, "mass": 0.5},
	"shieldbearer": {"name": "Shieldbearer", "hp": 26.0, "speed": 17.0, "dmg": 8.0, "r": 6.0, "xp": 4, "tough": false, "beh": 0, "mass": 1.0, "shield": 60.0},
	"howler": {"name": "Howler", "hp": 20.0, "speed": 17.0, "dmg": 5.0, "r": 5.0, "xp": 5, "tough": false, "beh": 4, "mass": 1.0},
	"screecher": {"name": "Screecher", "hp": 6.0, "speed": 120.0, "dmg": 8.0, "r": 5.0, "xp": 1, "tough": false, "beh": 5, "mass": 0.0, "fly": true},
	"foreman": {"name": "The Foreman", "hp": 2400.0, "speed": 22.0, "dmg": 16.0, "r": 13.0, "xp": 150, "tough": true, "beh": 20, "mass": 0.0, "boss": true},
	"brood": {"name": "The Brood", "hp": 6000.0, "speed": 0.0, "dmg": 18.0, "r": 22.0, "xp": 400, "tough": true, "beh": 21, "mass": 0.0, "boss": true},
	# part 8a: AI Takeover: the corporations' security robots as the swarm, four-legged scouts, gunners
	"enforcer": {"name": "Enforcer", "hp": 9.0, "speed": 20.0, "dmg": 6.0, "r": 5.0, "xp": 1, "tough": false, "beh": 0, "mass": 0.9},
	"scout": {"name": "Scout", "hp": 6.0, "speed": 46.0, "dmg": 7.0, "r": 5.0, "xp": 1, "tough": false, "beh": 8, "mass": 1.1},
	"gunner": {"name": "Gunner", "hp": 16.0, "speed": 20.0, "dmg": 5.0, "r": 5.0, "xp": 3, "tough": false, "beh": 9, "mass": 1.0, "bolt": 7.0},
	# part 8b: the rest of AI Takeover: "shell": what a bulwark's shell costs you (in "shell_r"); "boom": what a seeker's
	# burst costs you, "boom_foes" the machines, within "boom_r"; "jam": the shield a jammer gives those within "jam_r"
	"bulwark": {"name": "Bulwark", "hp": 130.0, "speed": 13.0, "dmg": 12.0, "r": 8.5, "xp": 9, "tough": true, "beh": 10, "mass": 0.15, "shell": 16.0, "shell_r": 26.0},
	"seeker": {"name": "Seeker", "hp": 7.0, "speed": 62.0, "dmg": 0.0, "r": 4.5, "xp": 2, "tough": false, "beh": 11, "mass": 1.0, "boom": 18.0, "boom_r": 30.0, "boom_foes": 40.0},
	"jammer": {"name": "Jammer", "hp": 24.0, "speed": 18.0, "dmg": 4.0, "r": 5.0, "xp": 6, "tough": false, "beh": 12, "mass": 0.8, "jam": 20.0, "jam_r": 80.0},
	"hunter": {"name": "Hunter", "hp": 28.0, "speed": 190.0, "dmg": 16.0, "r": 14.0, "xp": 4, "tough": false, "beh": 5, "mass": 0.0, "fly": true},
	# part 8c: the bosses of AI Takeover. The Warden: "arm": how far its laser arm reaches, "arm_dmg": what it costs you;
	# "rocket": one of its rockets (within "rocket_r" of its mark); "stomp": its stamp (the ring runs out to "stomp_r").
	# The Core: "beam": what a pylon's beam and an arm of its cross cost you; "field": a field of the floor that bursts.
	# A pylon is a kind of its own: while one stands, nothing hurts The Core.
	"warden": {"name": "The Warden", "hp": 2800.0, "speed": 16.0, "dmg": 16.0, "r": 15.0, "xp": 170, "tough": true, "beh": 22, "mass": 0.0, "boss": true,
		"arm": 140.0, "arm_dmg": 18.0, "rocket": 16.0, "rocket_r": 22.0, "stomp": 18.0, "stomp_r": 92.0},
	"core": {"name": "The Core", "hp": 5200.0, "speed": 0.0, "dmg": 18.0, "r": 18.0, "xp": 420, "tough": true, "beh": 23, "mass": 0.0, "boss": true,
		"beam": 16.0, "field": 20.0},
	"pylon": {"name": "Pylon", "hp": 420.0, "speed": 0.0, "dmg": 0.0, "r": 8.0, "xp": 20, "tough": true, "beh": 24, "mass": 0.0, "boss": true},
	# part 9a: Whiteout: what lives on the ice and under it. The burrower: "pace": how many times its pace it runs under
	# the ice; "warn": seconds its mark shows before it breaks out; "erupt": what that costs you (within "erupt_r");
	# "up": seconds it stays above. The rimeback's "shield" is its shell of ice.
	"mite": {"name": "Frost Mite", "hp": 5.0, "speed": 30.0, "dmg": 4.0, "r": 4.0, "xp": 1, "tough": false, "beh": 0, "mass": 1.2},
	"burrower": {"name": "Burrower", "hp": 22.0, "speed": 24.0, "dmg": 7.0, "r": 6.0, "xp": 3, "tough": false, "beh": 13, "mass": 0.8,
		"pace": 3.0, "warn": 0.9, "erupt": 12.0, "erupt_r": 20.0, "up": 5.0},
	"rimeback": {"name": "Rimeback", "hp": 60.0, "speed": 15.0, "dmg": 10.0, "r": 8.0, "xp": 6, "tough": false, "beh": 0, "mass": 0.3, "shield": 90.0},
	# part 9b: the shardthrower ("beh" 14: it keeps its distance, raises its arm, throws "fan" needles of ice, "spread"
	# apart, "needle" each); the glider (it flies along a line shown first and lets chunks of ice fall onto it: "chunk"
	# within "chunk_r"; it does not touch you)
	"shardthrower": {"name": "Shardthrower", "hp": 16.0, "speed": 20.0, "dmg": 5.0, "r": 5.0, "xp": 3, "tough": false, "beh": 14, "mass": 1.0, "needle": 6.0, "fan": 3, "spread": 0.26},
	"glider": {"name": "Glider", "hp": 24.0, "speed": 150.0, "dmg": 0.0, "r": 12.0, "xp": 4, "tough": false, "beh": 5, "mass": 0.0, "fly": true, "chunk": 10.0, "chunk_r": 16.0},
	# part 9c: the bosses of Whiteout. The Ice Worm ("beh" 25): "warn": seconds a mark shows before it breaks out there;
	# "erupt": what that costs you within "erupt_r"; "needle": one of its needles. The Storm Heart ("beh" 26): "needle":
	# one of its needles; "strike": a bolt of its lightning within "strike_r".
	"worm": {"name": "The Ice Worm", "hp": 3000.0, "speed": 0.0, "dmg": 16.0, "r": 14.0, "xp": 170, "tough": true, "beh": 25, "mass": 0.0, "boss": true,
		"warn": 0.95, "erupt": 22.0, "erupt_r": 30.0, "needle": 8.0},
	"heart": {"name": "The Storm Heart", "hp": 5400.0, "speed": 0.0, "dmg": 18.0, "r": 16.0, "xp": 420, "tough": true, "beh": 26, "mass": 0.0, "boss": true,
		"needle": 8.0, "strike": 18.0, "strike_r": 24.0},
	# part 11a: the Alien Laboratory: little green men as the swarm; the Grey ("beh" 15: it walks straight at you
	# through the walls; inside a wall nothing reaches it and it touches nobody); the specimen, out of a tank: slow,
	# and it takes a great deal
	"lgm": {"name": "Little Green Man", "hp": 6.0, "speed": 26.0, "dmg": 5.0, "r": 4.5, "xp": 1, "tough": false, "beh": 0, "mass": 1.1},
	"grey": {"name": "Grey", "hp": 12.0, "speed": 22.0, "dmg": 7.0, "r": 4.5, "xp": 3, "tough": false, "beh": 15, "mass": 0.9},
	"specimen": {"name": "Specimen", "hp": 170.0, "speed": 13.0, "dmg": 14.0, "r": 9.5, "xp": 10, "tough": true, "beh": 0, "mass": 0.1},
	# part 11b: the trooper ("beh" 16: it keeps its distance and fires a slow ring of light, "ray" what it costs you;
	# a wall turns the ring back once); the brain ("beh" 17: it hovers at a distance and, while it is in the hall
	# with you and within "pull_r", pulls you to it by "pull" of your pace); the saucer (it flies along a line shown
	# first, its tractor beam under it: who stands in it ("beam_r") is hurt ("beam") and held for "hold" seconds; a
	# dodge frees you)
	"trooper": {"name": "Trooper", "hp": 16.0, "speed": 21.0, "dmg": 5.0, "r": 5.0, "xp": 3, "tough": false, "beh": 16, "mass": 1.0, "ray": 9.0},
	"brain": {"name": "Brain", "hp": 34.0, "speed": 17.0, "dmg": 4.0, "r": 6.0, "xp": 6, "tough": false, "beh": 17, "mass": 0.7, "pull": 0.42, "pull_r": 230.0},
	"saucer": {"name": "Saucer", "hp": 26.0, "speed": 105.0, "dmg": 0.0, "r": 12.0, "xp": 4, "tough": false, "beh": 5, "mass": 0.0, "fly": true, "beam": 9.0, "beam_r": 20.0, "hold": 0.9},
	# part 11c: the bosses of the Alien Laboratory. The Apex ("beh" 27), the hunter they bred: faster than you; it
	# leaps at you along a line shown first ("pounce": what that costs you), from two thirds of its health three
	# times in a row from wall to wall and then strikes a ring out of its tail ("tail" within "tail_r"), in its last
	# third it spits a fan that leaves pools ("spit" each) and is faster still. The Mastermind ("beh" 28), what
	# slept in the great tank: it does not move; rings of thought with gaps in them ("wave" each); from two thirds
	# it hurls what stands in its hall onto marks ("hurl" within "hurl_r"); in its last third it pulls you to it
	# ("pull" of your pace), a round about it wears you down ("ring" twice a second within "ring_r"), and Greys
	# come in through the walls.
	"apex": {"name": "The Apex", "hp": 3200.0, "speed": 66.0, "dmg": 18.0, "r": 13.0, "xp": 180, "tough": true, "beh": 27, "mass": 0.0, "boss": true,
		"pounce": 24.0, "tail": 18.0, "tail_r": 120.0, "spit": 8.0},
	"mastermind": {"name": "The Mastermind", "hp": 5600.0, "speed": 0.0, "dmg": 18.0, "r": 20.0, "xp": 440, "tough": true, "beh": 28, "mass": 0.0, "boss": true,
		"wave": 9.0, "hurl": 22.0, "hurl_r": 30.0, "ring": 12.0, "ring_r": 78.0, "pull": 0.45},
}
const FOE_ORDER := ["shambler", "runner", "hauler", "spitter", "bloater", "shieldbearer", "howler", "screecher", "foreman", "brood", "enforcer", "scout", "gunner", "bulwark", "seeker",
	"jammer", "hunter", "warden", "core", "pylon", "mite", "burrower", "rimeback", "shardthrower", "glider", "worm", "heart", "lgm", "grey", "specimen", "trooper", "brain", "saucer", "apex", "mastermind"]

## (Part 10a, Luz) The collection in the pilot's window: where each kind is at home, and a few words about it. A kind
## counts once you have put one of it out; the record keeps how many of each ("slain").
const FOE_HOME := {
	"outbreak": ["shambler", "runner", "hauler", "spitter", "bloater", "shieldbearer", "howler", "screecher", "foreman", "brood"],
	"takeover": ["enforcer", "scout", "gunner", "bulwark", "seeker", "jammer", "hunter", "warden", "core", "pylon"],
	"whiteout": ["mite", "burrower", "rimeback", "shardthrower", "glider", "worm", "heart"],
	"lab": ["lgm", "grey", "specimen", "trooper", "brain", "saucer", "apex", "mastermind"],
}
const FOE_INFO := {
	"shambler": "What the outbreak made of the people here. Slow and weak alone, but it never comes alone.",
	"runner": "Lean and quick. It comes at you in a zigzag and is on you before the rest.",
	"hauler": "A giant among them. Near you it winds up and stamps: step out of its round before it lands.",
	"spitter": "It keeps its distance and spits at you. Close in on it, or stay on the move.",
	"bloater": "Swollen and slow. Put out, it bursts into a cloud that stays for a while and hurts whoever stands in it.",
	"shieldbearer": "It walks behind a shield. The shield has to break before anything reaches it.",
	"howler": "It stands and howls. Those near it walk faster for as long as it does.",
	"screecher": "It flies straight across the field, over everything in its way. They come as a flock.",
	"foreman": "Comes at 7:30, inside walls of light. It charges along a line, strikes the ground so a ring runs out, and throws containers onto marked spots.",
	"brood": "Waits at the end of Outbreak and does not move. Rings and turning arms of acid, and it lets out more of the swarm all the while.",
	"enforcer": "A corporation's security robot, built by the thousand. It walks at you and does not stop.",
	"scout": "Four legs, and quick. It runs in a zigzag, crouches near you and leaps.",
	"gunner": "It keeps its distance, takes aim along a line you can see and fires three bolts along it.",
	"bulwark": "Heavy plate on slow legs. It stops now and then and lobs a shell onto a marked spot.",
	"seeker": "A rolling charge. It comes straight at you, arms itself near you and goes off. It hurts the machines round it too.",
	"jammer": "It stays well back. The machines near it carry a shield for as long as it stands.",
	"hunter": "A fast flyer. It crosses the field along a line and hits hard on its way.",
	"warden": "Comes at 7:30, inside walls of light. A laser arm that warms up first, rockets onto marked spots, and a stamp whose ring runs far.",
	"core": "Waits at the end of AI Takeover. Nothing hurts it while one of its four pylons stands. Then come its cross of beams and a floor that bursts field by field.",
	"pylon": "One of four round The Core. Each aims a beam at you, and while one of them stands The Core cannot be hurt.",
	"mite": "Small, quick and countless. What lives on the ice comes as a carpet of these.",
	"burrower": "It runs under the ice, where nothing reaches it. Under you it stops, a mark shows, and it breaks out.",
	"rimeback": "Slow, under a shell of ice. The shell has to break before anything reaches it.",
	"shardthrower": "It keeps its distance, raises its arm and throws a fan of ice needles.",
	"glider": "It flies along a line shown first and lets chunks of ice fall onto it. It does not touch you.",
	"worm": "Comes at 7:30, inside walls of light. Under the ice nothing reaches it. Red marks show where it breaks out, and only while it is above can it be hurt.",
	"heart": "Waits at the end of Whiteout: a crystal in the eye of a storm. Outside the eye the storm wears you down, and the eye closes as the Heart weakens.",
	"lgm": "Small, green, a large head, two antennae. They come down every corridor at once and have to go round the walls, as you do.",
	"grey": "Thin and grey, with large black eyes. It walks straight through the walls. Inside a wall nothing reaches it, and it cannot touch you from there.",
	"specimen": "Something out of one of the tanks. Slow, and it takes a great deal before it goes down.",
	"trooper": "A green one in a suit and a glass helmet, with a ray gun. It keeps its distance and fires a slow ring of light that a wall turns back once.",
	"brain": "A brain under a dome of glass, hovering. While it is in the hall with you it pulls you towards it. Leave the hall, or put it out.",
	"saucer": "It flies along a line shown first, its tractor beam under it. Who stands in the beam is hurt and held. A dodge frees you.",
	"apex": "Comes at 7:30: the hunter they bred, faster than you. It leaps along a line shown first, later three times in a row from wall to wall. The doors of the hall you stand in shut behind you both.",
	"mastermind": "What slept in the great tank of the Core Hall. Rings of thought with gaps in them, then what stands in the hall flies at you, and at the last it pulls you to it while Greys come in through the walls.",
}


## The stage a kind is at home on ("" if none).
static func foe_home(kind: String) -> String:
	for st in FOE_HOME:
		if kind in (FOE_HOME[st] as Array):
			return String(st)
	return ""
const BOSS_BEH := 20               # a kind whose "beh" is this or more is a boss

## Who comes besides the shamblers: from which second on, every how many seconds a group, how many in a group, how
## many of that kind at once at most. (The groups come faster the longer the run.)
const WAVES := [
	{"kind": "runner", "from": 90.0, "every": 13.0, "n": [5, 8], "cap": 40},
	{"kind": "hauler", "from": 180.0, "every": 24.0, "n": [1, 1], "cap": 6},
	{"kind": "spitter", "from": 270.0, "every": 12.0, "n": [1, 2], "cap": 8},
	{"kind": "bloater", "from": 360.0, "every": 14.0, "n": [1, 2], "cap": 8},
	{"kind": "shieldbearer", "from": 510.0, "every": 9.0, "n": [2, 3], "cap": 24},
	{"kind": "howler", "from": 570.0, "every": 30.0, "n": [1, 1], "cap": 3},
]
## An alpha: a great, glowing one of a kind that has come by then, once a minute. It can take ALPHA_HP times as
## much, hits harder, and drops a crate.
const ALPHA_EVERY := 60.0
const ALPHA_HP := 10.0
const ALPHA_KINDS := ["shambler", "runner", "spitter", "bloater", "shieldbearer"]
## What happens when (seconds into the stage). The flock comes again and again from FLOCK_FROM on, a supply drop
## from SUPPLY_FROM on.
const EVENTS := [{"t": 240.0, "kind": "ring"}, {"t": 330.0, "kind": "sleepers"}, {"t": 600.0, "kind": "wall"}, {"t": 660.0, "kind": "blackout"},
	{"t": 750.0, "kind": "ring"}, {"t": 756.0, "kind": "wall"}]
const FLOCK_FROM := 150.0
const FLOCK_EVERY := 45.0
const SUPPLY_FROM := 120.0
const SUPPLY_EVERY := 110.0
const BLACKOUT_TIME := 20.0
const SOFT_BOSS := 450.0           # The Foreman comes at 7:30; The Brood when the time is up
const BARRIER := Vector2(560.0, 400.0)      # the field the walls of light close round a boss and you (art px)
const BANNERS := {"flock": "THE FLOCK", "ring": "THE RING CLOSES", "sleepers": "THEY RISE", "wall": "THE WALL", "blackout": "BLACKOUT", "supply": "SUPPLY DROP",
	"alpha": "AN ALPHA", "foreman": "THE FOREMAN", "brood": "THE BROOD", "barrier": "THE WALLS OF LIGHT CLOSE", "free": "THE WALLS FALL",
	"searchlight": "SEARCHLIGHTS", "reinforce": "REINFORCEMENTS", "killline": "KILL LINE", "emp": "EMP",
	"warden": "THE WARDEN", "core": "THE CORE", "shield": "THE SHIELD FALLS", "flood": "THE FLOOD",
	"frozen": "FROZEN IN: STEP ON THE VENT", "blizzard": "BLIZZARD", "icebreak": "THE ICE BREAKS", "avalanche": "AVALANCHE",
	"worm": "THE ICE WORM", "heart": "THE STORM HEART",
	"lockdown": "LOCKDOWN", "purge": "PURGE", "breach": "CONTAINMENT BREACH", "apex": "THE APEX", "mastermind": "THE MASTERMIND WAKES", "sealed": "THE DOORS SHUT"}
## Part 8c: The Core. Its cross of laser arms reaches CROSS_LEN; from CORE_LAST of its health down the floor of its
## field lights up in squares FIELD_CELL wide, FIELD_WARN seconds before they burst.
const CROSS_LEN := 360.0
const CORE_LAST := 0.45
const FIELD_CELL := 80.0
const FIELD_WARN := 1.3
## Part 8b: what happens on AI Takeover. Searchlights (SEARCH_TIME seconds of them): stand SEARCH_LIT seconds in a
## light (SEARCH_R wide) and a shell comes down where you stand. The EMP: for EMP_TIME seconds none of your weapons
## charges. The kill line: a line of light crossing the field at LINE_PACE, gaps in it LINE_GAP wide.
const SEARCH_TIME := 25.0
const SEARCH_LIT := 1.5
const SEARCH_R := 46.0
const EMP_TIME := 5.0
const LINE_PACE := 55.0
const LINE_GAP := 46.0

## Part 7f (Luz, 23 Nov 2026): two kinds of crates.
## An item crate (those lying on a stage, the supply drops) always holds an item. "w": how often by lot; "col": the
## colour of its sign, which springs up over you when you take it.
## A weapon crate (what an alpha leaves, what a boss leaves; golden) holds levels of what you carry, drawn by lot
## before your eyes while the run stands still: one mostly, three now and then, five rarely. DRAW_ODDS: the chance of
## three and of five, by who left it (a boss's holds three at least); Lucky Find adds DRAW_LUCK to each per level.
const ITEMS := {
	"shield": {"name": "Shield", "text": "Nothing touches you for a while.", "time": 6.0, "w": 3, "col": Color(0.4, 0.92, 1.0)},
	"magnet": {"name": "Magnet", "text": "Every shard on the field flies to you.", "w": 3, "col": Color(0.4, 1.0, 0.6)},
	"medkit": {"name": "Medkit", "text": "Health back.", "heal": 35.0, "w": 3, "col": Color(0.5, 1.0, 0.55)},
	"bomb": {"name": "Atomic Bomb", "text": "All round you are out.", "r": 230.0, "tough": 400.0, "w": 2, "col": Color(1.0, 0.62, 0.2)},
	"stasis": {"name": "Stasis", "text": "They all stand still for a while.", "time": 4.0, "w": 2, "col": Color(0.6, 0.8, 1.0)},
	"overdrive": {"name": "Overdrive", "text": "Your weapons fire twice as fast for a while.", "time": 8.0, "w": 2, "col": Color(1.0, 0.82, 0.35)},
	"override": {"name": "Override", "text": "The machines near you fight for you for a while.", "time": 8.0, "r": 110.0, "w": 3, "stage": "takeover", "col": Color(0.4, 1.0, 0.55)},      # (part 8b: on AI Takeover only)
	"thermal": {"name": "Thermal Charge", "text": "Melts all round you: a shell of ice, the ice over a crate, the ice over a burrower.", "r": 120.0, "dmg": 50.0, "w": 3, "stage": "whiteout",
		"col": Color(1.0, 0.88, 0.45)},                        # (part 9b: on Whiteout only)
	"seal": {"name": "Containment Seal", "text": "Fields of force close every doorway of the hall you stand in: nobody comes in, and what touches a field burns.", "time": 10.0, "w": 3, "stage": "lab",
		"col": Color(0.55, 1.0, 0.75)},                        # (part 11b: in the Alien Laboratory only)
}
const ITEM_ORDER := ["shield", "magnet", "medkit", "bomb", "stasis", "overdrive", "override", "thermal", "seal"]
const DRAW_ODDS := {"alpha": [0.16, 0.04], "boss": [0.75, 0.25]}
const DRAW_LUCK := [0.03, 0.01]

## Part 8: what each stage is made of. "swarm": the kind that comes all the time; "waves": who comes besides;
## "alpha": what an alpha can be; "events": what happens when; "soft" / "end": its two bosses ("": none yet: with no
## last one the stage is held when the time is up); "flock": the kind that flies through you ("": none); "banners":
## words across the picture that are this stage's own; "dangers": what the picture before a run names.
const TK_WAVES := [
	{"kind": "scout", "from": 90.0, "every": 13.0, "n": [4, 6], "cap": 36},
	{"kind": "gunner", "from": 180.0, "every": 15.0, "n": [1, 2], "cap": 10},
	{"kind": "bulwark", "from": 270.0, "every": 26.0, "n": [1, 1], "cap": 5},
	{"kind": "seeker", "from": 360.0, "every": 11.0, "n": [2, 3], "cap": 14},
	{"kind": "jammer", "from": 510.0, "every": 28.0, "n": [1, 1], "cap": 3},
]
const TK_EVENTS := [{"t": 120.0, "kind": "searchlight"}, {"t": 240.0, "kind": "reinforce"}, {"t": 300.0, "kind": "searchlight"}, {"t": 390.0, "kind": "killline"},
	{"t": 480.0, "kind": "searchlight"}, {"t": 600.0, "kind": "killline"}, {"t": 660.0, "kind": "emp"}, {"t": 720.0, "kind": "searchlight"}, {"t": 750.0, "kind": "reinforce"},
	{"t": 840.0, "kind": "searchlight"}]
## Part 9a (Luz, 23 Nov 2026): Whiteout, a moon of ice by day. Bare ice: you keep your way on it and turn it only
## slowly (ICE_TURN: how fast, a second). A steam vent: step within VENT_STEP of one and steam bursts out of it; it
## scalds all of them within VENT_R (VENT_DMG, growing with the time as they do), reaches the burrowers under the ice
## there and throws them out of it, melts a rimeback's shell at once, and thaws a crate frozen in beside it; it
## stands for VENT_TIME seconds, then the vent rests for VENT_REST. The steam does nothing to you.
const WO_WAVES := [
	{"kind": "burrower", "from": 90.0, "every": 14.0, "n": [2, 3], "cap": 16},
	{"kind": "rimeback", "from": 180.0, "every": 20.0, "n": [1, 2], "cap": 10},
	{"kind": "shardthrower", "from": 270.0, "every": 14.0, "n": [1, 2], "cap": 8},
]
## Part 9b: what happens on Whiteout. A blizzard: for BLIZZARD_TIME seconds you see only a round of BLIZZARD_R about
## you. The ice breaks: plates BREAK_CELL wide crack for BREAK_WARN seconds, then they break (BREAK_DMG to you;
## BREAK_FOES to them, growing with the time). An avalanche: after AVA_WARN seconds a wall of snow crosses the field
## at AVA_SPEED; it hurts you (AVA_DMG) and throws you, and carries them off (AVA_FOES); behind something solid you
## are safe.
const WO_EVENTS := [{"t": 210.0, "kind": "blizzard"}, {"t": 300.0, "kind": "icebreak"}, {"t": 400.0, "kind": "avalanche"}, {"t": 510.0, "kind": "blizzard"}, {"t": 570.0, "kind": "icebreak"},
	{"t": 650.0, "kind": "avalanche"}, {"t": 720.0, "kind": "blizzard"}, {"t": 800.0, "kind": "icebreak"}, {"t": 850.0, "kind": "avalanche"}]
const BLIZZARD_TIME := 18.0
const BLIZZARD_R := 120.0
const BREAK_CELL := 72.0
const BREAK_WARN := 1.6
const BREAK_DMG := 14.0
const BREAK_FOES := 40.0
const AVA_WARN := 2.4
const AVA_SPEED := 130.0
const AVA_DMG := 18.0
const AVA_FOES := 30.0
## Part 9c: The Storm Heart stands in the eye of a storm. The eye is EYE_MAX wide (its radius) while the Heart is
## whole and closes to EYE_MIN as it is worn down. Out in the storm you lose STORM_DMG twice a second.
const EYE_MAX := 250.0
const EYE_MIN := 105.0
const STORM_DMG := 8.0
const ICE_TURN := 2.2
const VENT_STEP := 11.0
const VENT_R := 46.0
const VENT_DMG := 45.0
const VENT_TIME := 1.2
const VENT_REST := 16.0
## Part 11a (Luz, 24 Nov 2026): the Alien Laboratory: the first stage with walls: nine halls in a grid of three by
## three, wide corridors between them. They find their way to you through the doors (the game's `_steer`); a Grey
## walks through the walls. What you fire is turned back by a wall or ends at it; what looks for a target needs a
## free line to it. Its events, its item and its two bosses come with parts 11b and 11c.
const LAB_WAVES := [
	{"kind": "grey", "from": 90.0, "every": 12.0, "n": [2, 3], "cap": 14},
	{"kind": "specimen", "from": 180.0, "every": 24.0, "n": [1, 1], "cap": 5},
	{"kind": "trooper", "from": 270.0, "every": 15.0, "n": [1, 2], "cap": 8},
	{"kind": "brain", "from": 360.0, "every": 30.0, "n": [1, 1], "cap": 3},
]
## Part 11b: what happens in the Alien Laboratory. A lockdown: for LOCK_TIME seconds fields of force close the
## doorways of the hall (or corridor) you stand in: nobody passes them, you neither; a Grey walks through the wall
## as ever. A purge: after PURGE_WARN seconds the hall you stand in burns for PURGE_BURN seconds: PURGE_DMG to you
## as it lights and PURGE_TICK twice a second while you stay; PURGE_FOES to them twice a second (growing with the
## time, as what they can take does). A containment breach: in the hall nearest to you that still has whole tanks,
## the BREACH_TANKS nearest to you burst, a specimen out of each. The laser grids across some doorways are on for
## GRID_ON seconds and off for GRID_OFF (the last GRID_WARN of that they flicker): GRID_DMG to you, GRID_FOES to
## them four times a second. A Containment Seal's fields cost them SEAL_FOES four times a second.
const LAB_EVENTS := [{"t": 150.0, "kind": "breach"}, {"t": 240.0, "kind": "lockdown"}, {"t": 330.0, "kind": "purge"}, {"t": 420.0, "kind": "breach"}, {"t": 510.0, "kind": "lockdown"},
	{"t": 600.0, "kind": "purge"}, {"t": 690.0, "kind": "breach"}, {"t": 750.0, "kind": "purge"}, {"t": 810.0, "kind": "lockdown"}, {"t": 860.0, "kind": "purge"}]
const LOCK_TIME := 15.0
const PURGE_WARN := 4.0
const PURGE_BURN := 1.6
const PURGE_DMG := 40.0
const PURGE_TICK := 10.0
const PURGE_FOES := 90.0
const BREACH_TANKS := 4
const GRID_ON := 2.4
const GRID_OFF := 2.8
const GRID_WARN := 0.7
const GRID_DMG := 14.0
const GRID_FOES := 16.0
const SEAL_FOES := 22.0
const STAGE_DATA := {
	"lab": {"swarm": "lgm", "waves": LAB_WAVES, "alpha": ["lgm", "grey", "trooper"], "events": LAB_EVENTS, "soft": "apex", "end": "mastermind", "flock": "saucer",
		"banners": {"flood": "FULL INVASION", "alpha": "A COMMANDER", "flock": "SAUCERS"},
		"dangers": ["Swarms in every corridor", "Greys walk through walls", "Walls turn your fire back", "Nutrient slows you"]},
	"outbreak": {"swarm": "shambler", "waves": WAVES, "alpha": ALPHA_KINDS, "events": EVENTS, "soft": "foreman", "end": "brood", "flock": "screecher",
		"dangers": ["Swarms from all sides", "Burning wrecks", "Spilled coolant"]},
	"takeover": {"swarm": "enforcer", "waves": TK_WAVES, "alpha": ["enforcer", "scout", "gunner"], "events": TK_EVENTS, "soft": "warden", "end": "core", "flock": "hunter",
		"banners": {"flock": "HUNTERS", "alpha": "A PRIME", "flood": "ALL UNITS"}, "dangers": ["Machines from all sides", "Searchlights", "Burning wrecks", "Spilled oil"]},
	"whiteout": {"swarm": "mite", "waves": WO_WAVES, "alpha": ["mite", "burrower", "rimeback", "shardthrower"], "events": WO_EVENTS, "soft": "worm", "end": "heart", "flock": "glider",
		"banners": {"flood": "THE ICE WAKES", "flock": "GLIDERS"}, "dangers": ["Mites from all sides", "Burrowers under the ice", "Bare ice: you slide", "Steam vents thaw the crates"]},
}


static func stage_data(id: String) -> Dictionary:
	return STAGE_DATA.get(id, STAGE_DATA["outbreak"])


## How many rewards a weapon crate holds: 1, 3 or 5 (`great`: a boss left it).
static func draw_count(run: Dictionary, rng: RandomNumberGenerator, great: bool) -> int:
	var odds: Array = DRAW_ODDS["boss" if great else "alpha"]
	var luck := bonus_level(run, "lucky")
	var five := float(odds[1]) + float(DRAW_LUCK[1]) * luck
	var three := float(odds[0]) + float(DRAW_LUCK[0]) * luck
	var roll := rng.randf()
	if roll < five:
		return 5
	return 3 if (great or roll < five + three) else 1


## What a weapon crate holds: `count` rewards, each a card as `apply` takes it: {"kind": "up" | "bonus_up", "id",
## "level": the level it rises to, "name"}; the same thing can come more than once (a level each time). When
## nothing you carry can rise further: a med cell (once, when you are hurt), then purses. The run is not changed here.
static func draw_rewards(run: Dictionary, rng: RandomNumberGenerator, count: int) -> Array:
	var lv := {}
	for w in run["weapons"]:
		lv["w:" + String(w[0])] = int(w[1])                  # (an ultimate stays what it is)
	for b in run["boni"]:
		lv["b:" + String(b[0])] = int(b[1])
	var out: Array = []
	var healed := false
	for q in count:
		var fused := false                                   # (Luz, 24 Nov 2026) a weapon ready to fuse: the crate gives its ultimate before anything else
		for wid in WEAPON_ORDER:
			if not fused and int(lv.get("w:" + String(wid), 0)) == MAX_LEVEL and int(lv.get("b:" + String(WEAPONS[wid]["bonus"]), 0)) > 0:
				fused = true
				lv["w:" + String(wid)] = ULT
				out.append({"kind": "ult", "id": String(wid), "level": ULT, "name": String(WEAPONS[wid]["ult"])})
		if fused:
			continue
		var able: Array = lv.keys().filter(func(k): return int(lv[k]) < MAX_LEVEL)
		if able.is_empty():
			if not healed and float(run.get("hp", HEALTH)) < max_hp(run):
				healed = true
				out.append({"kind": "heal", "id": "heal", "level": 0, "name": "Med cell"})
			else:
				out.append({"kind": "coins", "id": "coins", "level": 0, "name": "A purse"})
			continue
		var key := String(able[rng.randi() % able.size()])
		lv[key] = int(lv[key]) + 1
		var is_w := key.begins_with("w:")
		var id := key.substr(2)
		out.append({"kind": "up" if is_w else "bonus_up", "id": id, "level": int(lv[key]), "name": String((WEAPONS if is_w else BONI)[id]["name"])})
	return out


## What an item crate holds: {"kind": "item", "id"}.
static func crate_roll(run: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var here: Array = (ITEM_ORDER as Array).filter(func(id): return String(ITEMS[id].get("stage", "")) in ["", String(run.get("stage", "outbreak"))])      # (some belong to one stage)
	var total := 0
	for id in here:
		total += int(ITEMS[id]["w"])
	var pick := rng.randi() % total
	for id2 in here:
		pick -= int(ITEMS[id2]["w"])
		if pick < 0:
			return {"kind": "item", "id": id2}
	return {"kind": "item", "id": "medkit"}


## Which kinds have come by the second `t` on a stage (for an alpha, for the tests).
static func kinds_at(t: float, stage_id: String = "outbreak") -> Array:
	var sd: Dictionary = stage_data(stage_id)
	var out: Array = [String(sd["swarm"])]
	for w in sd["waves"]:
		if t >= float(w["from"]):
			out.append(String(w["kind"]))
	return out


## What a card shows in figures: the names of what a level changes.
const STAT_NAMES := {"n": "Count", "dmg": "Damage", "r": "Radius", "reach": "Reach", "time": "Lasts", "every": "Interval"}
const COUNT_NAMES := {"laser": "Beams", "plasma": "Grenades", "drone": "Shots", "blade": "Blades", "mines": "Mines", "sentry": "Guns", "orbs": "Orbs"}
const TIME_NAMES := {"cryo": "Freezes"}
const STAT_ORDER := ["n", "dmg", "r", "reach", "time", "every"]


## A figure as a card writes it.
static func _fig(key: String, v) -> String:
	if key in ["every", "time"]:
		return "%s s" % str(snappedf(float(v), 0.01))
	return str(int(v))


## What a weapon's level changes, as rows [what, before, after] (`from_lv` 0: a new weapon, all its figures, no
## "before").
static func weapon_lines(id: String, from_lv: int, to_lv: int) -> Array:
	var out: Array = []
	var a: Dictionary = stats(id, maxi(1, from_lv))
	var b: Dictionary = stats(id, to_lv)
	for key in STAT_ORDER:
		if not b.has(key):
			continue
		if from_lv > 0 and float(a[key]) == float(b[key]):
			continue
		var what := String(STAT_NAMES[key])
		if key == "n":
			what = String(COUNT_NAMES.get(id, "Count"))
		elif key == "time":
			what = String(TIME_NAMES.get(id, what))
		out.append([what, _fig(key, a[key]) if from_lv > 0 else "", _fig(key, b[key])])
	return out


## … and a bonus's level, the same way.
static func bonus_lines(id: String, from_lv: int, to_lv: int) -> Array:
	var f := func(lv: int) -> Array:
		match id:
			"amp":
				return [["Fields, bursts, reach", "+%d %%" % (8 * lv)]]
			"coolant":
				return [["Intervals", "-%d %%" % (6 * lv)]]
			"reactor":
				return [["Damage", "+%d %%" % (10 * lv)]]
			"magnet":
				return [["Shards fly to you from", "+%d %%" % (30 * lv)]]
			"nanite":
				return [["Health", "+%d" % (12 * lv)], ["Comes back", "%s a second" % str(snappedf(0.15 * lv, 0.01))]]
			"servo":
				return [["Your pace", "+%d %%" % (5 * lv)]]
			"stabiliser":
				return [["Lasts", "+%d %%" % (10 * lv)]]
			"overclock":
				return [["One more", "%d %% of the time" % (20 * lv)]]
			"shieldcell":
				return [["Charges in", "%d s" % (22 - 3 * lv)]]
			"scavenger":
				return [["Shards", "+%d %%" % (10 * lv)]]
			"lucky":
				return [["Supply drops", "%d %% sooner" % (8 * lv)], ["Three rewards", "+%d %%" % int(round(DRAW_LUCK[0] * 100.0 * lv))], ["Five rewards", "+%d %%" % int(round(DRAW_LUCK[1] * 100.0 * lv))]]
			"capacitor":
				return [["Twice as hard", "%d %% of the hits" % (6 * lv)]]
			"massdriver":
				return [["Thrown back", "+%d %%" % (25 * lv)]]
			"gyro":
				return [["Turns and flies", "+%d %%" % (10 * lv)]]
		return []
	var now: Array = f.call(to_lv)
	var was: Array = f.call(from_lv) if from_lv > 0 else []
	var out: Array = []
	for i in now.size():
		out.append([String(now[i][0]), String(was[i][1]) if i < was.size() else "", String(now[i][1])])
	return out


## The rows of a card of a new level.
static func card_lines(run: Dictionary, card: Dictionary) -> Array:
	var id := String(card.get("id", ""))
	match String(card.get("kind", "")):
		"weapon":
			return weapon_lines(id, 0, 1)
		"up":
			return weapon_lines(id, weapon_level(run, id), weapon_level(run, id) + 1)
		"bonus":
			return bonus_lines(id, 0, 1)
		"bonus_up":
			return bonus_lines(id, bonus_level(run, id), bonus_level(run, id) + 1)
	return []


## What a card fuses into: {"text", "ready": the other half is carried} ({} for a card that fuses into nothing).
static func fusion(run: Dictionary, card: Dictionary) -> Dictionary:
	var id := String(card.get("id", ""))
	match String(card.get("kind", "")):
		"weapon", "up":
			var wd: Dictionary = WEAPONS[id]
			return {"text": "Fuses with %s into %s" % [String(BONI[String(wd["bonus"])]["name"]), String(wd["ult"])], "ready": bonus_level(run, String(wd["bonus"])) > 0}
		"bonus", "bonus_up":
			for wid in WEAPON_ORDER:
				if String(WEAPONS[wid]["bonus"]) == id:
					return {"text": "Fuses %s into %s" % [String(WEAPONS[wid]["name"]), String(WEAPONS[wid]["ult"])], "ready": weapon_level(run, wid) > 0}
	return {}


## How a shard looks by what it is worth: 0 (one), 1 (a few), 2 (many), 3 (a great many).
static func shard_tier(value: int) -> int:
	return 0 if value < 2 else (1 if value < 5 else (2 if value < 20 else 3))


## Shards for the next level (from `level`).
static func need(level: int) -> int:
	return 4 + 3 * level + int(0.5 * level * level)


## How many of the others come in a second, `t` seconds into the stage.
static func spawn_rate(t: float) -> float:
	return minf(1.0 + t / 60.0 * 1.15, 20.0)


## What one of them can take, `t` seconds into the stage.
static func foe_hp(kind: String, t: float) -> float:
	if bool(FOES[kind].get("boss", false)) or bool(FOES[kind].get("fly", false)):
		return float(FOES[kind]["hp"])
	return float(FOES[kind]["hp"]) * (1.0 + t / 200.0)


## A run as it begins: {"stage", "t" seconds, "level", "xp" shards towards the next, "kills", "hp",
## "weapons": [[id, level], …], "boni": [[id, level], …], "alphas": put out, "bosses": put out}. With the
## Colosseum's state (`col`, part 7c-3) what you have at the console goes into it: "pool_w" / "pool_b" (the weapons
## and boni that can lie among the cards), "tune" (your ranks of fine tuning), "rerolls" (left in this run),
## "revive" (the last chance is still to come). Without it everything there is can come.
static func fresh(stage: String = "outbreak", weapon: String = START_WEAPON, col: Dictionary = {}) -> Dictionary:
	var run := {"stage": stage, "t": 0.0, "level": 1, "xp": 0, "kills": 0, "hp": HEALTH, "weapons": [[weapon if WEAPONS.has(weapon) else START_WEAPON, 1]], "boni": [], "alphas": 0,
		"bosses": []}
	if not col.is_empty():
		var rec := record(col)
		run["pool_w"] = (WEAPON_ORDER as Array).filter(func(id): return owned(col, String(id)))
		run["pool_b"] = (BONUS_ORDER as Array).filter(func(id): return owned(col, String(id)))
		run["tune"] = (rec["tune"] as Dictionary).duplicate()
		run["rerolls"] = int(rec["reroll"])
		run["revive"] = bool(rec["revive"])
		run["hp"] = max_hp(run)
	return run


static func stage(id: String) -> Dictionary:
	for s in STAGES:
		if String(s["id"]) == id:
			return s
	return STAGES[0]


## The level of a weapon in a run (0: not carried; ULT: its ultimate).
static func weapon_level(run: Dictionary, id: String) -> int:
	for w in run["weapons"]:
		if String(w[0]) == id:
			return int(w[1])
	return 0


## … and of a bonus.
static func bonus_level(run: Dictionary, id: String) -> int:
	for b in run["boni"]:
		if String(b[0]) == id:
			return int(b[1])
	return 0


## What a weapon does at a level (its ultimate: as at level 5, and more: the run knows what).
static func stats(id: String, level: int) -> Dictionary:
	var ls: Array = WEAPONS[id]["levels"]
	return ls[clampi(level, 1, ls.size()) - 1]


## What your boni (and your fine tuning at the console) make of you and of all you carry: "area" (fields, bursts,
## reach), "cd" (intervals), "dmg", "mag" (how far shards fly to you), "speed" (your pace), "dur" (how long what you
## set going lasts), "xp" (what a shard is worth) as factors; "hp" (health on top), "regen" (health a second),
## "more" (how often a volley fires one more, 0 … 1), "cell" (seconds the Shield Cell takes to charge; 0: none),
## "luck" (the level of Lucky Find), "crit" (how often a hit strikes twice as hard, 0 … 1), "kb" (how far a hit
## throws back, a factor).
static func mods(run: Dictionary) -> Dictionary:
	var tn: Dictionary = run.get("tune", {})
	var cell := bonus_level(run, "shieldcell")
	return {"area": 1.0 + 0.08 * bonus_level(run, "amp"),
		"cd": (1.0 - 0.06 * bonus_level(run, "coolant")) * (1.0 - 0.015 * int(tn.get("cd", 0))),
		"dmg": (1.0 + 0.1 * bonus_level(run, "reactor")) * (1.0 + 0.02 * int(tn.get("dmg", 0))),
		"mag": (1.0 + 0.3 * bonus_level(run, "magnet")) * (1.0 + 0.05 * int(tn.get("mag", 0))),
		"speed": (1.0 + 0.05 * bonus_level(run, "servo")) * (1.0 + 0.01 * int(tn.get("speed", 0))),
		"hp": 12.0 * bonus_level(run, "nanite") + 5.0 * int(tn.get("hp", 0)), "regen": 0.15 * bonus_level(run, "nanite"),
		"dur": 1.0 + 0.1 * bonus_level(run, "stabiliser"), "more": 0.2 * bonus_level(run, "overclock"), "cell": (22.0 - 3.0 * cell) if cell > 0 else 0.0,
		"xp": (1.0 + 0.1 * bonus_level(run, "scavenger")) * (1.0 + 0.02 * int(tn.get("xp", 0))), "luck": bonus_level(run, "lucky"),
		"crit": 0.06 * bonus_level(run, "capacitor"), "kb": 1.0 + 0.25 * bonus_level(run, "massdriver"), "spin": 1.0 + 0.1 * bonus_level(run, "gyro")}


## The most health you can have in a run.
static func max_hp(run: Dictionary) -> float:
	return HEALTH + float(mods(run)["hp"])


## Can this weapon become its ultimate now? (At level 5, its own bonus carried.)
static func ult_ready(run: Dictionary, id: String) -> bool:
	return weapon_level(run, id) == MAX_LEVEL and bonus_level(run, String(WEAPONS[id]["bonus"])) > 0


## Shards taken in: true for every level they make (call until false).
static func level_up(run: Dictionary) -> bool:
	if int(run["xp"]) < need(int(run["level"])):
		return false
	run["xp"] = int(run["xp"]) - need(int(run["level"]))
	run["level"] = int(run["level"]) + 1
	return true


## The three cards of a new level: {"kind": "weapon" (a new one) | "up" (a level of one you carry) | "bonus" (a new
## one) | "bonus_up" | "ult" (a weapon becomes its ultimate) | "heal" | "coins", "id", "level" (the level it brings),
## "name", "text"}. An ultimate that is ready lies on the table for sure; the rest by lot from what you can still
## take; when that is not three, a med cell and a purse fill up.
static func offers(run: Dictionary, rng: RandomNumberGenerator) -> Array:
	var pool: Array = []
	var out: Array = []
	var pw: Array = run.get("pool_w", WEAPON_ORDER)             # (part 7c-3: only what is yours can come new; what you carry goes on as ever)
	var pb: Array = run.get("pool_b", BONUS_ORDER)
	for id in WEAPON_ORDER:
		var lv := weapon_level(run, id)
		var wd: Dictionary = WEAPONS[id]
		if lv == 0 and (not (id in pw) or int(wd.get("from", 0)) > int(run.get("level", 1))):
			continue                                          # (not yours, or a weapon for the end of a run whose time has not come)
		if lv == 0 and (run["weapons"] as Array).size() < SLOTS:
			pool.append({"kind": "weapon", "id": id, "level": 1, "name": String(wd["name"]), "text": String(wd["text"])})
		elif lv > 0 and lv < MAX_LEVEL:
			pool.append({"kind": "up", "id": id, "level": lv + 1, "name": String(wd["name"]), "text": String(wd["up"])})
		elif ult_ready(run, id) and out.is_empty():
			out.append({"kind": "ult", "id": id, "level": ULT, "name": String(wd["ult"]), "text": "%s and %s: %s" % [String(wd["name"]), String(BONI[String(wd["bonus"])]["name"]), String(wd["ult_text"])]})
	for bid in BONUS_ORDER:
		var bl := bonus_level(run, bid)
		var bd: Dictionary = BONI[bid]
		if bl == 0 and not (bid in pb):
			continue
		if bl == 0 and (run["boni"] as Array).size() < SLOTS:
			pool.append({"kind": "bonus", "id": bid, "level": 1, "name": String(bd["name"]), "text": String(bd["text"])})
		elif bl > 0 and bl < MAX_LEVEL:
			pool.append({"kind": "bonus_up", "id": bid, "level": bl + 1, "name": String(bd["name"]), "text": String(bd["text"])})
	while out.size() < 3 and not pool.is_empty():
		out.append(pool.pop_at(rng.randi() % pool.size()))
	if out.size() < 3:
		out.append({"kind": "heal", "id": "heal", "level": 0, "name": "Med cell", "text": "%d health back." % int(HEAL)})
	while out.size() < 3:
		out.append({"kind": "coins", "id": "coins", "level": 0, "name": "A purse", "text": "15 Coins on top of what the run pays."})
	return out


## A card taken. "" or why not.
static func apply(run: Dictionary, card: Dictionary) -> String:
	var id := String(card.get("id", ""))
	match String(card.get("kind", "")):
		"weapon":
			if not WEAPONS.has(id):
				return "No such weapon."
			if weapon_level(run, id) > 0:
				return "You carry that already."
			if (run["weapons"] as Array).size() >= SLOTS:
				return "No place for another weapon."
			(run["weapons"] as Array).append([id, 1])
		"up":
			for w in run["weapons"]:
				if String(w[0]) == id:
					if int(w[1]) >= MAX_LEVEL:
						return "That is at its last level."
					w[1] = int(w[1]) + 1
					return ""
			return "You do not carry that."
		"bonus":
			if not BONI.has(id):
				return "No such bonus."
			if bonus_level(run, id) > 0:
				return "You carry that already."
			if (run["boni"] as Array).size() >= SLOTS:
				return "No place for another bonus."
			(run["boni"] as Array).append([id, 1])
		"bonus_up":
			for b in run["boni"]:
				if String(b[0]) == id:
					if int(b[1]) >= MAX_LEVEL:
						return "That is at its last level."
					b[1] = int(b[1]) + 1
					return ""
			return "You do not carry that."
		"ult":
			if not WEAPONS.has(id) or not ult_ready(run, id):
				return "That takes the weapon at level 5 and its bonus."
			for w2 in run["weapons"]:
				if String(w2[0]) == id:
					w2[1] = ULT
		"heal":
			run["hp"] = minf(max_hp(run), float(run["hp"]) + HEAL)
		"coins":
			run["purse"] = int(run.get("purse", 0)) + 15
		_:
			return "No such card."
	return ""


## What a run pays: Coins and rank points by the time you held out and by who you put out; a purse taken on the
## way on top; a stage held to the end pays half as much again.
static func reward(run: Dictionary, survived: bool) -> Dictionary:
	var secs := float(run.get("t", 0.0))
	var k := 1.5 if survived else 1.0
	var tk := 1.0 + 0.03 * int((run.get("tune", {}) as Dictionary).get("coins", 0))      # (fine tuning: a run pays more Coins)
	return {"coins": int((secs / 6.0 + float(int(run.get("kills", 0))) / 12.0) * k * tk) + int(run.get("purse", 0)), "xp": int(secs / 9.0 * k)}


static func time_text(secs: float) -> String:
	var s := int(secs)
	return "%02d:%02d" % [s / 60, s % 60]


# ---------------------------------------------------------------- part 7c-3: what stays of a run for the next ones

## (Luz) Survivor has its own way of getting on from run to run. Every run brings cores (by the time you held out,
## for every alpha, for The Foreman, for The Brood). At the console in the Colosseum's lobby they buy what stays:
##   to unlock: weapons and boni, which then lie among the cards of a run and can be the weapon you begin with
##             (free from the first run on: FREE_WEAPONS, FREE_BONI);
##   fine tuning: small shares for good, rank by rank (TUNE), and up to three rerolls of a level's cards a run;
##   a last chance: very dear; once a run you stand up again with half your health.
const FREE_WEAPONS := ["pulse", "laser", "plasma"]
const FREE_BONI := ["amp", "coolant", "reactor"]
const UNLOCK_COST := {"drone": 20, "taser": 20, "blade": 25, "mines": 25, "sentry": 30, "cryo": 30, "orbs": 30, "gravity": 35, "superlaser": 45, "blackhole": 90, "gyro": 18,
	"magnet": 12, "servo": 12, "nanite": 15, "scavenger": 15, "massdriver": 15, "stabiliser": 18, "capacitor": 18, "lucky": 20, "overclock": 22, "shieldcell": 22}
## Fine tuning: "per": what a rank brings (in words), "step": the figure behind it.
const TUNE := {
	"dmg": {"name": "Damage", "per": "+2 %", "text": "All your weapons hit harder.", "step": 2.0, "unit": " %"},
	"cd": {"name": "Interval", "per": "-1.5 %", "text": "All your weapons fire sooner.", "step": -1.5, "unit": " %"},
	"hp": {"name": "Health", "per": "+5", "text": "More health to begin with.", "step": 5.0, "unit": ""},
	"speed": {"name": "Pace", "per": "+1 %", "text": "You walk faster.", "step": 1.0, "unit": " %"},
	"mag": {"name": "Magnet", "per": "+5 %", "text": "Shards fly to you from farther off.", "step": 5.0, "unit": " %"},
	"xp": {"name": "XP", "per": "+2 %", "text": "Shards bring more towards the next level.", "step": 2.0, "unit": " %"},
	"coins": {"name": "Coins", "per": "+3 %", "text": "A run pays more Coins.", "step": 3.0, "unit": " %"},
}
const TUNE_ORDER := ["dmg", "cd", "hp", "speed", "mag", "xp", "coins"]
const TUNE_MAX := 10               # ranks of each
const REROLL_COST := [30, 60, 120] # the first, the second, the third reroll a run
const REVIVE_COST := 300
const CORE_SECS := 20.0            # a core for every so many seconds held out
const CORE_ALPHA := 2
const CORE_BOSS := {"foreman": 12, "brood": 30, "warden": 12, "core": 30, "worm": 12, "heart": 30, "apex": 12, "mastermind": 30}


## What stays of Survivor in the Colosseum's state: {"best": {stage: seconds}, "runs", "kills", "weapon": the one
## you begin with, "stage", "cores", "cores_all" (ever earned), "own": what you unlocked, "tune": {what: rank},
## "reroll": rerolls a run, "revive": the last chance is yours}.
static func record(col: Dictionary) -> Dictionary:
	if not col.has("sv"):
		col["sv"] = {"best": {}, "runs": 0, "kills": 0, "weapon": START_WEAPON}
	var rec: Dictionary = col["sv"]
	if not rec.has("cores"):
		rec["cores"] = 0
		rec["cores_all"] = 0
		rec["own"] = []
		rec["tune"] = {}
		rec["reroll"] = 0
		rec["revive"] = false
		rec["stage"] = "outbreak"
	if not rec.has("beaten"):
		rec["beaten"] = []                                    # (part 8) the bosses you have put out, ever: they open stages
	if not rec.has("slain"):
		rec["slain"] = {}                                     # (part 10a) the collection: how many of each kind you have put out, ever
	return rec


## (Part 8, Luz) Is this stage open to you? (It is built, and you have put out the boss it asks for.)
static func stage_open(col: Dictionary, id: String) -> bool:
	for s in STAGES:
		if String(s["id"]) == id:
			return bool(s["open"]) and (String(s.get("need", "")) == "" or String(s["need"]) in (record(col)["beaten"] as Array))
	return false


## The stage of your next run (the one you picked, while it is open to you).
static func cur_stage(col: Dictionary) -> String:
	var st := String(record(col).get("stage", "outbreak"))
	return st if stage_open(col, st) else "outbreak"


## Is this weapon or bonus yours (free from the start, or unlocked at the console)?
static func owned(col: Dictionary, id: String) -> bool:
	return id in FREE_WEAPONS or id in FREE_BONI or id in (record(col)["own"] as Array)


static func tune_rank(col: Dictionary, id: String) -> int:
	return int((record(col)["tune"] as Dictionary).get(id, 0))


## What fine tuning has made of a figure so far, as the console writes it ("+6 %").
static func tune_text(id: String, rank: int) -> String:
	var v := float(TUNE[id]["step"]) * rank
	return "%s%s%s" % ["+" if v >= 0.0 else "", str(snappedf(v, 0.1)).trim_suffix(".0"), String(TUNE[id]["unit"])]


## What the next step costs at the console in cores (-1: there is none).
##   what: "unlock" (id: a weapon or a bonus), "tune" (id: of TUNE), "reroll", "revive"
static func price(col: Dictionary, what: String, id: String = "") -> int:
	var rec := record(col)
	match what:
		"unlock":
			return -1 if owned(col, id) or not UNLOCK_COST.has(id) else int(UNLOCK_COST[id])
		"tune":
			return -1 if not TUNE.has(id) or tune_rank(col, id) >= TUNE_MAX else 4 + 3 * tune_rank(col, id)
		"reroll":
			return -1 if int(rec["reroll"]) >= REROLL_COST.size() else int(REROLL_COST[int(rec["reroll"])])
		"revive":
			return -1 if bool(rec["revive"]) else REVIVE_COST
	return -1


## Something is bought at the console. "" or why not.
static func buy(col: Dictionary, what: String, id: String = "") -> String:
	var rec := record(col)
	var p := price(col, what, id)
	if p < 0:
		match what:
			"unlock":
				return "That is yours already." if owned(col, id) else "No such thing."
			"tune":
				return "That is at its last rank." if TUNE.has(id) else "No such thing."
			"reroll":
				return "Three rerolls a run are the most."
			"revive":
				return "That is yours already."
		return "No such thing."
	if int(rec["cores"]) < p:
		return "That takes %d cores. You have %d." % [p, int(rec["cores"])]
	rec["cores"] = int(rec["cores"]) - p
	match what:
		"unlock":
			(rec["own"] as Array).append(id)
		"tune":
			rec["tune"][id] = tune_rank(col, id) + 1
		"reroll":
			rec["reroll"] = int(rec["reroll"]) + 1
		"revive":
			rec["revive"] = true
	return ""


## The cores a run brings.
static func cores(run: Dictionary) -> int:
	var c := int(float(run.get("t", 0.0)) / CORE_SECS) + CORE_ALPHA * int(run.get("alphas", 0))
	for b in run.get("bosses", []):
		c += int(CORE_BOSS.get(String(b), 0))
	return c


## Can a run begin with this weapon? (One that is yours, and not one for the end of a run.)
static func can_begin(col: Dictionary, id: String) -> bool:
	return WEAPONS.has(id) and owned(col, id) and int(WEAPONS[id].get("from", 0)) <= 1


## The weapon you begin a run with.
static func first_weapon(col: Dictionary) -> String:
	var w := String(record(col).get("weapon", START_WEAPON))
	return w if can_begin(col, w) else START_WEAPON


## Split screen: the weapon the second player begins with: what they picked in the fighters' room, never the first
## player's (a weapon is carried by one of the two); else the first one of yours that may begin a run.
static func second_weapon(col: Dictionary) -> String:
	var f := first_weapon(col)
	var w := String(record(col).get("weapon2", ""))
	if w != "" and w != f and WEAPONS.has(w) and owned(col, w) and can_begin(col, w):
		return w
	for id in WEAPON_ORDER:
		if String(id) != f and owned(col, String(id)) and can_begin(col, String(id)):
			return String(id)
	for id2 in WEAPON_ORDER:
		if String(id2) != f and int(WEAPONS[id2].get("from", 0)) <= 1:
			return String(id2)
	return f


## How far you have come in Survivor (0 … 1): the share of what you have unlocked and tuned at the console. (Luz)
## The crowd in the stands goes by this.
static func progress(col: Dictionary) -> float:
	var rec := record(col)
	var got := 0
	for id in UNLOCK_COST:
		if id in (rec["own"] as Array):
			got += 1
	var ranks := 0
	for t in TUNE_ORDER:
		ranks += tune_rank(col, String(t))
	return clampf(0.5 * float(got) / float(UNLOCK_COST.size()) + 0.3 * float(ranks) / float(TUNE_ORDER.size() * TUNE_MAX) + 0.1 * float(int(rec["reroll"])) / float(REROLL_COST.size())
		+ (0.1 if bool(rec["revive"]) else 0.0), 0.0, 1.0)


## (Part 10b, Luz) The Survivor rig: what you wear in the arena shows how far you have come at the console, in ten
## steps: 0 an undershirt and trousers; every tenth of `progress` one more piece; 10 the whole regalia. It changes
## nothing else. RIG_NAMES: what each step brings. RIG_SUIT: at the last step the Colosseum gives you the regalia as a
## suit for outside the arena.
const RIG_STEPS := 10
const RIG_NAMES := ["An undershirt and trousers", "Armoured boots, a belt with the first light", "Bracers", "Greaves and knee caps", "A cuirass with its core",
	"Pauldrons edged in gold", "The black undersuit, thigh plates, gloves", "Seams of light", "A cape with a gold hem", "A gorget and a laurel of light", "The whole regalia"]
const RIG_SUIT := "suit_survivor:A"


## The step of your rig (0 … RIG_STEPS). ("rig_force" in the record: set from the debug menu, to look at a step.)
static func rig_tier(col: Dictionary) -> int:
	var rec := record(col)
	if int(rec.get("rig_force", -1)) >= 0:
		return clampi(int(rec["rig_force"]), 0, RIG_STEPS)
	return clampi(int(floorf(progress(col) * RIG_STEPS + 0.0001)), 0, RIG_STEPS)


## A run is over: its reward, the record kept, the cores it brought. Returns {"coins", "xp", "cores", "time",
## "kills", "level", "survived", "best": a new best time}.
static func settle(col: Dictionary, run: Dictionary, survived: bool) -> Dictionary:
	var rec := record(col)
	var rw := reward(run, survived)
	var st := String(run.get("stage", "outbreak"))
	var before := float((rec["best"] as Dictionary).get(st, 0.0))
	var secs := float(run.get("t", 0.0))
	if secs > before:
		rec["best"][st] = secs
	rec["runs"] = int(rec["runs"]) + 1
	rec["kills"] = int(rec["kills"]) + int(run.get("kills", 0))
	var got := cores(run)
	rec["cores"] = int(rec["cores"]) + got
	rec["cores_all"] = int(rec["cores_all"]) + got
	var opened: Array = []                                      # (part 8) a boss put out for the first time may open a stage
	for b in run.get("bosses", []):
		if not (String(b) in (rec["beaten"] as Array)):
			(rec["beaten"] as Array).append(String(b))
			for sg in STAGES:
				if bool(sg["open"]) and String(sg.get("need", "")) == String(b):
					opened.append(String(sg["name"]))
	col["xp"] = int(col.get("xp", 0)) + int(rw["xp"])
	var new_foes: Array = []                                    # (part 10a) the collection: what this run put out, kind by kind; those met for the first time
	var slain: Dictionary = run.get("slain", {})
	for sk in slain:
		var kd := String(sk)
		if int(slain[sk]) <= 0 or not FOES.has(kd):
			continue
		var had := int((rec["slain"] as Dictionary).get(kd, 0))
		if had <= 0:
			new_foes.append(kd)
		rec["slain"][kd] = had + int(slain[sk])
	return {"coins": int(rw["coins"]), "xp": int(rw["xp"]), "cores": got, "time": secs, "kills": int(run.get("kills", 0)), "level": int(run.get("level", 1)), "survived": survived,
		"best": secs > before, "stage": st, "opened": opened, "new_foes": new_foes}
