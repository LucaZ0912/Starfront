extends RefCounted
## Package 60 (Luz): the people you have come to know – only the main figures for now (more once Fern stands).
## Each has a relationship from -100 to +100, shown as a bar from the middle: to the right it fills gold through
## Acquaintance, Friend and Best friend, to the left red through Wary, Rival and Enemy.
## The value is the sum of what the story did (EVENTS: a condition on the story's flags and missions, points, a line
## for "Together" – so it also counts for what happened before this package) plus what you do with or for a person
## (GameState.story.flags["acq_extra"], e.g. a bar game with them). Per person, capped at ±100.
## No class_name: preload it.

const StoryData = preload("res://data/story.gd")
const MAX := 100
const STEP := 100.0 / 3.0
const LEVELS_POS := ["Acquaintance", "Friend", "Best friend"]
const LEVELS_NEG := ["Wary", "Rival", "Enemy"]
const ORDER := ["dan", "ossa", "rook", "silas", "imre", "luz"]
const GAME_POINTS := 3                 # a bar game with someone …
const GAME_CAP := 12                   # … up to this much from games

## "met": the condition from which the person is in the list. "events": [condition, points, line].
## "about": a line under the name; "bio": who they are, in short; "likes": a taste of what they like (for later: gifts).
## Conditions: "flag:NAME" (set and not false), "run:MISSION" (running or done), "done:MISSION".
const PEOPLE := {
	"dan": {"met": "flag:intro_stage", "home": "Dan's Dusty Duty Store, Beyond", "beyond": true,
		"about": "Pulled you out of the Veil. Says you still owe him a whiskey.",
		"bio": "Runs the Dusty Duty Store, the only station in Beyond worth the name: salvage yard, bar and bank in one. Thirty years out past the Veil. Gruff, generous, and keeps count of every drink owed.",
		"likes": ["Whiskey, the good stuff", "Old Earth coins", "A full bar", "Scrap that arrives on time"],
		"events": [
			["flag:intro_stage", 10, "Towed your wreck out of the Veil and had you patched up."],
			["flag:dan_deal_yes", 10, "Offered you a deal: work for a ticket to the Cluster."],
			["flag:ticket_ship", 10, "Gave you Little Darling."],
			["flag:w58_slept", 5, "Gave you a room on the house."],
			["flag:w58_escorted", 10, "You kept the pirates off the scrap run to Driftwood."],
			["done:darling", 10, "Three months of work for Dan."],
			["flag:w58_base_down", 20, "Flew against the Red Talon Roost together. Dan's drones kept you alive."],
			["flag:w58_drinks", 10, "Celebrated in Dan's bar until the morning."],
			["flag:w59_left", 15, "Arranged your passage to the Cluster and saw you off."],
		]},
	"ossa": {"met": "flag:w58_ossa", "home": "Upper Brine, Beyond", "beyond": true,
		"about": "Paid you once. Trusts you now.",
		"bio": "Owner and lead pilot of Kell Freight in Upper Brine. Hauls scrap out of Beyond with two old freighters and no patience for excuses. Never pays early, never forgets a favour.",
		"likes": ["A clean game of pool", "Strong coffee", "Pilots who show up on time", "Pirates in pieces"],
		"events": [
			["flag:w58_ossa", 8, "Hired you to escort her haulers."],
			["flag:w58_escorted", 10, "Both haulers reached the Driftwood Waystation."],
			["flag:w58_maul", 7, "Lent you her Maul."],
			["flag:w58_gear", 7, "Lent you her ground gear."],
			["flag:w58_base_down", 9, "Fought at the Red Talon Roost at your side."],
			["flag:w58_gifted", 4, "Gave you a combat suit to keep."],
			["flag:w59_left", 5, "Sent Rook along to look after you."],
		]},
	"rook": {"met": "flag:w58_maul", "home": "Aboard the Maul, Beyond", "beyond": true,
		"about": "Came along to keep you alive. Just for a while.",
		"bio": "Ossa's gunner on the Maul. Neon pink hair, a cyber eye, and a scar with a story that changes every time Rook tells it. Good on the ground, better behind a gun.",
		"likes": ["Loud music", "Spicy noodles", "Neon paint", "A fair fight, or an unfair one that works"],
		"events": [
			["flag:w58_maul", 8, "Came aboard the Maul as your gunner."],
			["flag:w58_sim", 8, "Trained you in the hangar simulation."],
			["flag:w58_relay", 12, "Went down to the relay station with you."],
			["flag:w58_base_down", 10, "Manned the guns at the Roost."],
			["flag:w59_left", 8, "Crossed the Veil with you."],
			["flag:start_job", 4, "Shared a drink on your first evening in the Cluster."],
		]},
	"silas": {"met": "flag:w58_contact", "home": "Driftwood Waystation, Driftwood", "beyond": true,
		"about": "Listens to everything. Probably to you too.",
		"bio": "Engineer of the Stubborn Hope, an unarmed Bastion bristling with antennas. Built the Listener to hear what the Veil hides. Talks to machines more easily than to people.",
		"likes": ["Old radio parts", "Tea, never coffee", "Quiet", "Signals nobody else can hear"],
		"events": [
			["flag:w58_contact", 8, "Met in the Driftwood Waystation's diner."],
			["flag:w58_listened", 12, "You kept the pirates off the Stubborn Hope while the Listener ran."],
			["flag:w58_briefing", 5, "Planned the strike round Dan's pool table."],
			["flag:w58_base_down", 15, "Jammed the guns of the Roost."],
			["flag:w59_left", 5, "Promised to listen for you."],
		]},
	# package 61: Luz, your way into Centauria
	"luz": {"met": "flag:fern_luz", "home": "Centauria, Pelagia, Fern",
		"about": "Owns the Static Feedback. Knows everyone anyway.",
		"bio": "Runs an underground punk bar in Centauria and has done a little of everything in the Rim. Rook's contact, and the one to ask when you want to know who does what in the city.",
		"likes": ["Punk, played loud", "Cheap beer", "People who keep their word", "Trouble, in small doses"],
		"events": [
			["flag:fern_luz", 8, "Met in Centauria, on Rook's word."],
		]},
	"imre": {"met": "flag:w59_met", "home": "Dan's bar, Beyond", "beyond": true,
		"about": "Paid a million for your licence and never mentioned it again.",
		"bio": "A scholar of the Meridian Directorate and captain of the Threshold, a prototype that crosses the Veil. Collects what is left of Earth and dreams of a museum for it.",
		"likes": ["Relics of Earth", "Stories from before the Severance", "Good coffee", "Questions"],
		"events": [
			["flag:w59_met", 5, "Introduced by Dan in the closed bar."],
			["flag:w59_left", 7, "Carried you through the Veil aboard the Threshold."],
			["flag:cit_licence", 10, "Bought you a pilot licence. For a million."],
		]},
}


static func _cond(c: String) -> bool:
	var st = GameState.story
	var k := c.get_slice(":", 0)
	var v := c.get_slice(":", 1)
	match k:
		"flag":
			var fv = st.flags.get(v, false)
			return not (fv is bool and fv == false)
		"run":
			return st.running(v) or st.done.has(v)
		"done":
			return st.done.has(v)
	return false


static func met(id: String) -> bool:
	return PEOPLE.has(id) and _cond(String(PEOPLE[id]["met"]))


## The people you know, in the list's order.
static func known() -> Array:
	return ORDER.filter(func(id): return met(id))


## What you did with or for someone, apart from the story.
static func extra(id: String) -> int:
	return int((GameState.story.flags.get("acq_extra", {}) as Dictionary).get(id, 0))


## The relationship, -100 … +100.
static func value(id: String) -> int:
	if not PEOPLE.has(id):
		return 0
	var v := extra(id)
	for e in PEOPLE[id]["events"]:
		if _cond(String(e[0])):
			v += int(e[1])
	return clampi(v, -MAX, MAX)


## The step the value stands on: 0 (a stranger), +1 … +3 (Acquaintance, Friend, Best friend), -1 … -3.
static func level(v: int) -> int:
	if v == 0:
		return 0
	return signi(v) * clampi(int(ceil(absf(v) / STEP)), 1, 3)


static func level_name(lv: int) -> String:
	if lv > 0:
		return LEVELS_POS[lv - 1]
	if lv < 0:
		return LEVELS_NEG[-lv - 1]
	return "Stranger"


## The lines of "Together": what the story did, oldest first.
static func together(id: String) -> Array:
	var out: Array = []
	for e in PEOPLE[id]["events"]:
		if _cond(String(e[0])):
			out.append(String(e[2]))
	return out


## Where to find them; "far" when that lies beyond the Veil and you are in the Cluster.
static func where(id: String) -> Dictionary:
	var st = GameState.story
	var moved := bool(st.flags.get("cit_moved", false))
	var place := String(PEOPLE[id]["home"])
	var far := moved and bool(PEOPLE[id].get("beyond", false))
	if id == "rook" and moved:
		var stn: Dictionary = Universe.find_station(int(st.flags.get("cit_sys", -1)), String(st.flags.get("cit_st", "")))
		place = "%s, %s" % [String(stn.get("name", "your first station")), String(Universe.systems[int(st.flags.get("cit_sys", 0))]["name"])] if not stn.is_empty() else "Your first station"
		far = false
	elif id == "imre" and bool(st.flags.get("w59_left", false)):
		place = "Aboard the Threshold, somewhere in the Cluster"
		far = false
	return {"place": place, "far": far}


## Something done with or for a person (Luz): the bar moves, per person. Returns the points that counted.
static func add(id: String, points: int, why: String) -> int:
	if not PEOPLE.has(id) or points == 0:
		return 0
	var st = GameState.story
	var before := value(id)
	var ex: Dictionary = (st.flags.get("acq_extra", {}) as Dictionary).duplicate()
	ex[id] = int(ex.get(id, 0)) + points
	st.flags["acq_extra"] = ex
	var after := value(id)
	if after == before:
		ex[id] = int(ex[id]) - points                   # (the bar is full: nothing to add)
		st.flags["acq_extra"] = ex
		return 0
	var nm := String((StoryData.CHARACTERS.get(id, {}) as Dictionary).get("name", id))
	GameState.log_msg("%s: %s%d (%s)." % [nm, "+" if after > before else "", after - before, why], GameState.COL_GOOD if after > before else GameState.COL_WARN)
	st.changed.emit()
	return after - before


## A bar game with someone you know: a little closer each time, up to a cap.
static func played_with(id: String) -> void:
	if not met(id):
		return
	var st = GameState.story
	var gp: Dictionary = (st.flags.get("acq_games", {}) as Dictionary).duplicate()
	if int(gp.get(id, 0)) >= GAME_CAP:
		return
	var got := add(id, mini(GAME_POINTS, GAME_CAP - int(gp.get(id, 0))), "a game together")
	if got > 0:
		gp[id] = int(gp.get(id, 0)) + got
		st.flags["acq_games"] = gp


## New people and changed steps since the last look: says so in the log and marks them new (the gold dot).
## Called whenever the story changes.
static func refresh() -> void:
	var st = GameState.story
	var lv: Dictionary = (st.flags.get("acq_lv", {}) as Dictionary).duplicate()
	var fresh: Array = (st.flags.get("acq_new", []) as Array).duplicate()
	var dirty := false
	for id in known():
		var nm := String((StoryData.CHARACTERS.get(id, {}) as Dictionary).get("name", id))
		var now := level(value(id))
		if not lv.has(id):
			lv[id] = now
			if not id in fresh:
				fresh.append(id)
			GameState.log_msg("New acquaintance: %s." % nm, GameState.COL_GOOD)
			dirty = true
		elif int(lv[id]) != now:
			var up := now > int(lv[id])
			lv[id] = now
			GameState.log_msg("%s: %s." % [nm, ("now your %s" % level_name(now).to_lower()) if now > 0 and up else level_name(now)], GameState.COL_GOOD if up else GameState.COL_WARN)
			dirty = true
	if dirty:
		st.flags["acq_lv"] = lv
		st.flags["acq_new"] = fresh


static func is_new(id: String) -> bool:
	return id in (GameState.story.flags.get("acq_new", []) as Array)


static func seen(id: String) -> void:
	var fresh: Array = (GameState.story.flags.get("acq_new", []) as Array).duplicate()
	if id in fresh:
		fresh.erase(id)
		GameState.story.flags["acq_new"] = fresh
