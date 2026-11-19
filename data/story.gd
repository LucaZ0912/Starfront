extends RefCounted
## Package 55 (Luz): the story's data – missions (story and side missions) made of steps, each with goals and what
## happens when it starts and when it is done; the characters who speak (with their portraits), the dialogues and
## their answers (which set story flags), the tips and the secrets. The story itself comes with packages 56–59; for
## now only a test mission, started from the debug menu.
##
## A mission: {title, kind: "story" | "side", chapter, desc, debug_only, lessons, steps: [step, …]} – "lessons": the
## journal keeps every step's text, also the ones done (the flight training).
## A step: {id, title, text, goals: [goal, …], on_start: [action, …], on_done: [action, …]}
## A goal: {id, kind, label, …} – kinds:
##   "dock"   at a station: "target" (an object id, "@target" the step's target, "" any)
##   "near"   within "km" of "target"
##   "lock"   lock "target"
##   "jump"   arrive in system "system" (-1: any other)
##   "talk"   a dialogue "dialogue" finished
##   "flag"   story flag "flag" set
## An action: {do: "dialogue" (id) | "radio" (who, text) | "tip" (id) | "flag" (name, value) | "credits" (n) |
##   "secret" (id) | "target" ("nearest_station")}
## Text may name keys: {key:action_id} – shown as the key (or the controller's button) bound to it; {move}, {zoom},
## {views} and {journal} say how to fly, zoom, change the view and open the journal – with the keys or the controller,
## whichever is in use. A line without answers goes on with a press – to the next line or to its "next" (-1: the end).

## Who speaks: name, what they are, the colour of their frame, the look of their portrait (PilotArt.random_look with
## this seed, then the fields given).
const CHARACTERS := {
	# package 56 (Luz): an older, broad man, Black, with an eye patch
	"dan": {"name": "Dan T. Rogue", "sub": "Salvage master · Dan's Dusty Duty Store", "col": Color(1.0, 0.65, 0.3), "seed": 7731,
		"look": {"body": 2, "skin": 6, "hair": 1, "hair_color": 6, "beard": 3, "brows": 2, "scar": 0, "headgear": 4, "implant": 0,
			"tattoo": 0, "outfit": 1, "color1": 9, "color2": 0, "freckles": 0}},
	# package 56: the medic of Dan's station (name a placeholder until Luz picks one)
	"doc": {"name": "Dr. Vesna Kalu", "sub": "Medic · Dan's Dusty Duty Store", "col": Color(0.45, 1.0, 0.75), "seed": 5612,
		"look": {"body": 1, "skin": 3, "hair": 8, "hair_color": 6, "eyes": 2, "brows": 1, "beard": 0, "scar": 0, "freckles": 0,
			"outfit": 0, "color1": 3, "color2": 5, "implant": 1, "tattoo": 0, "headgear": 1}},
	# package 56: the computer of the pilot's old Earthworks 190SL – a hologram (shown whenever the ship's computer speaks)
	"ship_ai": {"name": "Ship computer", "sub": "Earthworks 190SL", "col": Color(0.4, 0.9, 1.0), "holo": true},
	# package 58 (Luz): the lead pilot of a convoy you escort calls when it is attacked
	"convoy_pilot": {"name": "Convoy lead", "sub": "Freighter captain", "col": Color(0.7, 0.85, 1.0), "seed": 2207},
	# package 58, part 3 (Luz): the client of the first escort – Kell Freight, two old haulers out of Upper Brine
	# (Luz: reworked) a weathered freight boss in her fifties: grey ponytail, a headset (she flies the lead hauler herself),
	# an old scar on the cheek, an olive work jacket
	"ossa": {"name": "Ossa Kell", "sub": "Kell Freight · Upper Brine", "col": Color(0.45, 0.9, 0.85), "seed": 6143,
		"look": {"body": 1, "skin": 4, "hair": 5, "hair_color": 6, "eyes": 4, "brows": 1, "beard": 0, "scar": 1, "freckles": 0,
			"outfit": 1, "color1": 7, "color2": 0, "implant": 0, "tattoo": 0, "headgear": 1, "lipstick": 0, "blush": 0, "eye_makeup": 0}},
	# package 58, part 3: Dan on the radio (his face, the call's header) – the call at the end of the escort
	"dan_radio": {"name": "Dan T. Rogue", "sub": "◉ Radio call · Dan's Dusty Duty Store", "col": Color(1.0, 0.65, 0.3), "seed": 7731,
		"look": {"body": 2, "skin": 6, "hair": 1, "hair_color": 6, "beard": 3, "brows": 2, "scar": 0, "headgear": 4, "implant": 0,
			"tattoo": 0, "outfit": 1, "color1": 9, "color2": 0, "freckles": 0}},
	# package 56, sequence 6: regulars of Dan's bar
	"patron_a": {"name": "Hob Karst", "sub": "Scrap hauler", "col": Color(0.75, 0.8, 0.9), "seed": 3307},
	"patron_b": {"name": "Mira Teague", "sub": "Mechanic", "col": Color(0.75, 0.8, 0.9), "seed": 9124},
	"patron_c": {"name": "Ossen Vale", "sub": "Regular", "col": Color(0.75, 0.8, 0.9), "seed": 4471},
}

## Dialogues: lines one after the other; a line's answers lead on ("next": the line's index, -1: the end) and may set
## a story flag ("flag": [name, value]).
const DIALOGUES := {
	# package 56, sequence 4 (Luz): Dan's infirmary and his bar. A line may name its speaker ("who"; "you" is the pilot);
	# an answer's 4th entry is what the pilot then says at length.
	"intro_bed": {"who": "doc", "lines": [
		{"text": "We did what we could, but I just can't make sense of a lot of these readings. For now all we can do is wait."},
		{"who": "dan", "text": "Alright. Let me know as soon as anything changes."},
	]},
	"intro_wake": {"who": "dan", "lines": [
		{"who": "you", "text": "Mmmmh…"},
		{"text": "Ah, finally, you're awake. We thought that was it for you. Your suit had at least as many holes as your ship."},
		{"text": "I'm Dan. Dan T. Rogue. I run this little operation here. Nice to meet you."},
		{"text": "You should rest a bit more. When you're fit, come see me in the bar. Just take the turbolift."},
	]},
	"intro_doc": {"who": "doc", "lines": [
		{"text": "Careful! Yes, just like that. That looks good already. You should be able to move freely around the station. But take it easy for now, okay?",
			"answers": [["\"Thanks for patching me up, Doc.\"", 1, [], "Thanks for patching me up, Doc. I owe you one."]]},
		{"text": "No problem, that's my job."},
	]},
	"intro_doc_again": {"who": "doc", "lines": [
		{"text": "Oh? Anything else? Dan's waiting up in the bar. Just take the turbolift."},
	]},
	# package 56 (Luz): Dan in the bar while the flight training waits – what you can ask him
	"dan_help": {"who": "dan", "lines": [
		{"text": "Can I help you with anything else?",
			"answers": [["\"You wanted to talk to me.\"", 6, ["prologue_bar", true], "You said you wanted to talk to me. What's on your mind?", {"if": [["intro_stage", "six"]], "not": ["dan_deal_no", "dan_deal_yes"], "gold": true}],
				["\"About your deal: I've thought it over.\"", 18, [], "About your deal. I've thought it over, and I'd like to hear it again.", {"if": [["dan_deal_no", true]], "not": ["dan_deal_yes"], "gold": true}],
				["\"What is this place again?\"", 1, [], "Sorry, remind me: what is this place again?"], ["\"What about my ship?\"", 3, [], "And what about my ship? Can she be fixed?"],
				["\"Where was I going again?\"", 4, [], "Where was I supposed to go again?", {"if": [["intro_stage", "five"], ["dan_deal_yes", true]]}],
				["\"Pool?\"", 5, [], "I saw a pool table back there. Can I play?"], ["\"That's all, thanks.\"", -1, [], "That's all for now. Thanks, Dan."]]},
		{"text": "This is Dan's Dusty Duty Store! My very own wreck-breaking business, right here in Beyond!",
			"answers": [["\"Beyond?\"", 2, [], "Beyond? What's that supposed to mean?"], ["\"Something else…\"", 0, [], "Actually, something else…"]]},
		{"text": "Beyond is the beating heart of a tiny little cluster outside the real Cluster. I'll tell you more once we've finished your training.", "next": 0},
		{"text": "Oh, yeah… I'm sorry, but she's done for. Everything on her is broken, and the rest is so old I can barely work out how that technology ever ran. I'll get rid of the wreck for you. Free of charge, of course!", "next": 0},
		{"text": "Just down to the hangar. Take the turbolift, you can't miss it.", "next": 0},
		{"text": "Sure, go play a round. Some folks are keen to bet their credits on it, too. But you'll have to earn a few first, I reckon.", "next": 0},
		# 6 – sequence 6 (Luz): what Dan wanted to talk about
		{"text": "You seem like a capable pilot to me. But you've got no ship, no pilot licence, and you're stuck here in Beyond.",
			"answers": [["\"Stuck?\"", 7, ["dan_q_stuck", true], "What do you mean, stuck?"], ["\"Pilot licence?\"", 8, ["dan_q_licence", true], "A pilot licence? Since when do I need one of those?"]]},
		{"text": "Yeah, Beyond is cut off from the Cluster. There are no jump gates, and only a few ways there.",
			"answers": [["\"Pilot licence?\"", 8, ["dan_q_licence", true], "A pilot licence? Since when do I need one of those?", {"not": ["dan_q_licence"]}],
				["\"And what do you suggest?\"", 10, [], "So what do you suggest I do now?", {"if": [["dan_q_licence", true]]}]]},
		{"text": "Yeah, you'll need one to buy a ship in the Cluster and to be allowed to fly it. The factions issue them. But politics isn't my thing."},
		{"text": "I don't mind folks flying around here without a licence. But that's not your only problem, is it?",
			"answers": [["\"Stuck?\"", 7, ["dan_q_stuck", true], "What do you mean, stuck?", {"not": ["dan_q_stuck"]}],
				["\"And what do you suggest?\"", 10, [], "So what do you suggest I do now?", {"if": [["dan_q_stuck", true]]}]]},
		{"text": "I know someone who might be able to help you. He's got contacts with the Assembly and the Covenant. He'll get you placed, no doubt. And he's got a ship that can make the trip.",
			"answers": [["\"Where's the catch?\"", 11, [], "That sounds too good to be true. Where's the catch?"]]},
		{"text": "Ah, you're smarter than you look! See, nothing in the Cluster is free. If someone wants to give you something for nothing, you can be sure they're cheating you."},
		{"text": "My friend's services don't come cheap, and I'm not exactly swimming in money out here. But here's the deal:"},
		{"text": "You give me a hand, and you earn your ticket to the Cluster.",
			"answers": [["\"And what would that look like?\"", 14, [], "And what exactly would that look like?"]]},
		{"text": "I give you a ship and some gear and show you how to get by out here. You do a few jobs for me, and then we'll see.",
			"answers": [["\"How long is that supposed to take?\"", 15, [], "And how long is that supposed to take?"]]},
		{"text": "Well, let me work that out… plus board… carry the one…"},
		{"text": "About three years.",
			"answers": [["\"What?\"", 17, [], "THREE YEARS? That's half an eternity!?"]]},
		{"text": "Well, for someone over three hundred years old that should be bearable, surely. We'll just see how it goes, yeah? I don't think you'll find a better offer around here."},
		# 18 – the question (also when you come back to it)
		{"text": "So, what do you say?",
			"answers": [["\"Yes, deal.\"", 19, ["dan_deal_yes", true], "Yes. You've got yourself a deal, Dan."], ["\"No.\"", 20, ["dan_deal_no", true], "No. Sorry, Dan, but that's not for me."]]},
		{"text": "Alright! There's a small ship waiting for you in the hangar. It's got some gear in it already, but a few things still need fitting. Climb aboard and I'll explain how it works. Then we'll see.", "next": -1},
		{"text": "Fair enough. You're still welcome here, of course. Maybe you'll find someone else to take you on. But hardly anyone here has a ship to give away, and without a licence nobody'll take you on as crew either. Come and see me if you change your mind.", "next": -1},
	]},
	# package 58, part 2 (Luz): the first load of scrap at Dan's
	"dan_scrap": {"who": "dan", "lines": [
		{"text": "Let's see what you've brought me."},
		{"text": "Hm. Not bad for a first run. Gold Fleet steel, still good for something after three hundred years. Like some people I know.",
			"answers": [["\"Very funny.\"", 2, [], "Ha. Very funny. So what's it worth?"], ["\"Thanks, I think.\"", 2, [], "I'll take that as a compliment. What's it worth?"]]},
		{"text": "Two thousand. Don't spend it all on drinks. Well, maybe on one."},
		{"text": "Next time it won't be rocks. I've got a few people who need things moved around Beyond, and they pay better than scrap does.",
			"answers": [["\"I'm listening.\"", 4, [], "I'm listening. Who are they?"]]},
		{"text": "Later. Get some rest first. I've put you in one of my rooms upstairs, on the house: take the lift up to the Quarters. Come and find me in the bar when you're up.", "next": -1},
	]},
	# package 58, part 3 (Luz): Dan's next job, in his bar – Ossa Kell's run to Driftwood needs an escort
	"dan_job": {"who": "dan", "lines": [
		{"text": "There you are. Slept it off? Good, because I've got work for you. Proper work, with credits at the end.",
			"answers": [["\"Let's hear it.\"", 1, [], "I'm rested and I'm listening. What's the job?"]]},
		{"text": "Ossa Kell. She runs Kell Freight out of Brine: two old haulers and a lot of stubbornness. She buys my scrap and sells it on in Driftwood."},
		{"text": "Only lately the pirates have taken a liking to her runs. Two haulers lost this year. Now she won't fly without an escort, and nobody out here does escorts.",
			"answers": [["\"So I'm the escort.\"", 3, [], "And let me guess: I'm the escort now."],
				["\"Pirates? In Little Darling?\"", 3, [], "Pirates? You want me to take on pirates in a mining ship?"]]},
		{"text": "You're what I've got. And Little Darling's tougher than she looks. Like her pilot."},
		{"text": "My boys put a better laser in her and some armour plating. On loan, like the rest. Don't scratch it.",
			"answers": [["\"Where do I find Ossa?\"", 5, ["w58_job", true], "Fine, I'll do it. Where do I find this Ossa Kell?", {"gold": true}]]},
		{"text": "Upper Brine, the city down on Brine. Land there and she'll meet you at your ship in the hangar. And be nice: she pays on time, which makes her the only one out here who does.", "next": -1},
	]},
	"dan_rest": {"who": "dan", "lines": [
		{"text": "You look like a wreck I wouldn't buy. Bed first, work later. Your room's upstairs, the Quarters.", "next": -1},
	]},
	# package 58, part 4 (Luz): three months later – the party, then Dan and you at the bar
	"dan_party": {"who": "dan", "lines": [
		{"text": "*Sigh…*"},
		{"who": "you", "text": "That's a pretty worried face for a party."},
		{"text": "Don't get me wrong, the last few months have been fantastic. We've rarely had business this steady. But…"},
		{"who": "you", "text": "The pirates…?"},
		{"text": "No matter how many you shoot down, there seem to be more of them every time."},
		{"who": "you", "text": "And they're getting better organised."},
		{"text": "…"},
		{"who": "you", "text": "Instead of only ever defending ourselves, we should take the fight to them."},
		{"text": "Oh yeah? And who's supposed to do that? You'd have to be completely out of your mind to…"},
		{"who": "you", "text": "…"},
		{"text": "No. You've earned your name as \"Spacefarer\" fair and square, but I don't want to lose my best employee… and certainly not a friend."},
		{"who": "you", "text": "We can't keep going like this forever."},
		{"text": "You're right."},
		{"who": "you", "text": "Give me a proper ship and some gear, and I'll take care of the pirates."},
		{"text": "I'll let Ossa know. She's got a Maul. A pretty patched-up old thing, but it'll do out here."},
		{"text": "Then you should talk to a friend of mine in Driftwood. He might know how to track the pirates down. I'll send you the contacts once you've got the Maul."},
		{"text": "But tonight you're the star of the party. Have a few more, and we'll see tomorrow.", "next": -1},
	]},
	# package 58, part 4: Ossa hands you her Maul (in Upper Brine's shopping street)
	"ossa_maul": {"who": "ossa", "lines": [
		{"text": "There's our pirate hunter. Dan told me everything. Mad, the lot of you."},
		{"text": "So. The Maul. Hadrian built her as a gunboat, the pirates shot her full of holes, and I patched her up. Twice.",
			"answers": [["\"Will she hold?\"", 2, [], "Will she hold together out there, Ossa?"],
				["\"Twice?\"", 2, [], "Twice? That's not exactly reassuring."]]},
		{"text": "Better than she looks. A strong shield, real guns, a drone bay with drones in it, and a repair system that patches her up while you fly. I didn't skimp. You'll need all of it."},
		{"text": "And she doesn't fly herself. Rook Varga comes along as your gunner: the best I ever had, and he hates pirates more than I do. Don't get him killed.",
			"answers": [["\"Thank you, Ossa.\"", 4, ["w58_maul", true], "Thank you, Ossa. I'll bring her back in one piece. Mostly.", {"gold": true}]]},
		{"text": "Bring yourself back, that's enough. Now, you've never flown with a crew, have you? Let me show you how that works.", "next": -1},
	]},
	# package 58 (Luz): shot down while working for Dan – you wake in his clinic, no game over
	"dan_wake": {"who": "dan", "lines": [
		{"text": "Easy, easy. You're back in my clinic. My boys fished you out of what was left of the cockpit. Doc says you'll live."},
		{"text": "And Little Darling? Patched up, again. She's taken worse. So what are you still lying around here for?",
			"answers": [["\"The convoy…\"", 2, [], "The convoy… what happened to Ossa's haulers?", {"if": [["w58_phase", "convoy"]]}],
				["\"Back to work.\"", 3, [], "Alright, alright. I'm getting up. Back to work."]]},
		{"text": "Ossa's waiting outside my store with what she's got left, and she's not happy. Get back in Little Darling. The moment you undock, we try that again.", "next": -1},
		{"text": "That's the spirit. She's waiting for you in the hangar.", "next": -1},
	]},
	"dan_busy": {"who": "dan", "lines": [
		{"text": "Don't keep Ossa waiting. Brine's the blue one. I'll call you if I need you.", "next": -1},
	]},
	"ossa_meet": {"who": "ossa", "lines": [
		{"text": "You'll be Dan's new pilot. The one he fished out of the Veil.",
			"answers": [["\"Word gets around.\"", 1, [], "Word travels fast around here, it seems."],
				["\"And you're Ossa Kell.\"", 7, [], "And you must be Ossa Kell. Dan sends his regards."]]},
		{"text": "Beyond is small. Three systems, one bar worth the name and a lot of wrecks. Everybody knows everything."},
		{"text": "Here's the job. My two haulers are taking on Dan's scrap at his store. They go through the gate to the Driftwood Waystation. You fly with them and keep the pirates off.",
			"answers": [["\"How bad are the pirates?\"", 3, [], "How bad are we talking? Dan said you lost two haulers this year."],
				["\"What does it pay?\"", 4, [], "And what's in it for me?"]]},
		{"text": "Bad enough. They don't wait at the gates. They pull you out of warp halfway and swarm you. Two or three of them, old fighters, cheap guns, no patience.", "next": 4},
		{"text": "Three thousand when my haulers dock in Driftwood. Not a credit before. Dan says you're good for it.", "next": 5},
		{"text": "My lead hauler waits outside Dan's store, marked green. Come alongside, or select her and follow, and we set off. Stay close in warp: if they pull us out, you come out with us.",
			"answers": [["\"Let's go.\"", 6, ["w58_ossa", true], "Alright. I'll meet your haulers at Dan's store. Let's get your cargo to Driftwood.", {"gold": true}]]},
		{"text": "Good. I fly the lead myself, so you'll hear from me. Don't be late.", "next": -1},
		# 7 – (Luz) her own answer when you name her
		{"text": "That's me. Owner, captain and the only one still fool enough to fly for Kell Freight. Dan's regards usually come with a bill, so let's hear what he's sent me.", "next": 2},
	]},
	# package 58, part 3 (Luz): the escort done, Dan calls – angry about the pirates, then: come back
	"dan_end": {"who": "dan_radio", "lines": [
		{"text": "Darling? Ossa just called. You made it, good. But pirates again! That's the third time this month!"},
		{"text": "Do they have any idea what they're doing to business out here? Nobody hauls scrap that gets shot at. Nobody buys scrap that never arrives. And who's left sitting on the scrap? Me!",
			"answers": [["\"We handled it.\"", 2, [], "We handled it, Dan. Both haulers made it in one piece."],
				["\"They won't stop, will they?\"", 2, [], "They won't stop, will they? Not as long as there's something out here to take."]]},
		{"text": "Yeah, yeah. You did good out there. Don't let it go to your head."},
		{"text": "That's enough for now. You've earned yourself a drink, and little Darling needs some love. Come on back.",
			"answers": [["\"On my way.\"", -1, ["w58_called", true], "On my way, Dan. Keep a glass cold for me.", {"gold": true}]]},
	]},
	# package 56, sequence 6 (Luz): the bar busy again – asked for work, they say no (you have no licence)
	"patron_a": {"who": "patron_a", "lines": [
		{"who": "you", "text": "Got any work for a pilot?"},
		{"text": "Work? For someone without a licence? Sorry, friend. My insurer would have my hide."},
	]},
	"patron_b": {"who": "patron_b", "lines": [
		{"who": "you", "text": "You wouldn't need a pilot, would you?"},
		{"text": "Ha! No papers, no ship, no record? Try Dan. He takes in strays."},
	]},
	"patron_c": {"who": "patron_c", "lines": [
		{"who": "you", "text": "I'm looking for a job. Anything?"},
		{"text": "Not out here, love. Beyond's small. Everyone already knows who flies for whom."},
	]},
	# package 56, sequence 5 (Luz): the flight training with one of Dan's drones
	"tut_start": {"who": "dan", "lines": [
		{"text": "Ready? Then hop in, Betty's warmed up.",
			"answers": [["Start the flight training", -1, ["tut_go", true]], ["Not yet", -1, []]]},
	]},
	"tut_hangar_back": {"who": "dan", "lines": [
		{"text": "There are a few more things I need to talk to you about."},
		{"text": "Come to the bar when you're ready, yeah?"},
	]},
	"intro_dan_bar": {"who": "dan", "lines": [
		{"text": "Ah, you're looking fit again!",
			"answers": [["\"Thanks for saving me.\"", 1, [], "Thank you for saving me. I really thought that was it."]]},
		{"text": "Ah, don't mention it. Your ship wasn't so lucky, I'm afraid. But tell me, how did you come by a ship like that?",
			"answers": [["\"It was issued to me.\"", 2, [], "What do you mean? The UN issued it to me. Who else?"]]},
		{"text": "UN? As in United Nations? As in the United Nations of Earth?"},
		{"who": "you", "text": "Yes…?"},
		{"text": "Oh. Uhm… what year do you think it is?"},
		{"who": "you", "text": "Around 12,600 HE… I don't know exactly. I don't know how long I was out."},
		{"text": "It's 12,900 HE. I think a hyperdrive failure threw you almost three hundred years into the future."},
		{"who": "you", "text": "…"},
		{"text": "Okay, that's a lot to take in. How about we take your mind off it? I had a look at your cockpit. Seems not that much has changed, but your pilot licence expired a while ago. Want to brush up on the basics?",
			"answers": [["\"Yes, that'd be good.\"  (flight tutorial)", 9, ["flight_tutorial", true], "Yes, that'd be good. Show me what's new."],
				["\"No, I'll manage.\"  (skip the tutorial)", 11, ["flight_tutorial", false], "No, I'll manage. Flying is flying."]]},
		{"text": "Alright, I've still got a few remote-controlled drones. We'll start with those."},
		{"text": "Come to my hangar whenever you're ready. No rush, though. Have a drink, or play a round of pool.", "next": -1},
		{"text": "Oh? Confident, are we? Question is whether you're brave or just stupid."},
		{"text": "Well. I've still got a few things to talk over with you, but have a look around first. Have a drink, play a round of pool, and come over here when you're ready."},
	]},
	"test_hello": {"who": "dan", "lines": [
		{"text": "So the debug menu sent you. Good, this is a test of the story's framework: dialogues, radio calls, tips, goals and the journal.",
			"answers": [["\"What do I do?\"", 1, []], ["\"I know how this works.\"", 2, ["test_confident", true]]]},
		{"text": "Fly to the station I mark for you, then dock there. I'll call you on the way, and the journal (Pilot window) keeps it all.",
			"answers": [["\"On my way.\"", -1, []]]},
		{"text": "Then show me. The station's marked. Dock there.",
			"answers": [["\"On my way.\"", -1, []]]},
	]},
}

## Tips: shown once (unless switched off), kept in the journal under Tips.
const TIPS := {
	"tip_objective": {"title": "Goals and the marker", "text": "The mission you track shows its next goals over your ship's panel. In space a gold diamond marks the target, with an arrow at the edge when it is off the screen. The journal ({key:journal}) has all your missions."},
	"tip_fire_groups": {"title": "Fire groups", "text": "Your modules sit in fire groups: the tiles at the bottom. Lock a target, then press {key:module_1} to switch group 1 on. Set the groups in Ship → Modules → Fire groups."},
	"tip_docking": {"title": "Docking", "text": "Select a station, then press {key:cmd_dock} and your ship flies in and docks by itself."},
}

## Secrets: found ones are listed in the journal; the others show as "???" so you know there is more.
const SECRETS := {
	"test_secret": {"title": "The test framework", "text": "You finished the test mission of package 55. The framework works.", "debug_only": true},
}

## The missions.
const MISSIONS := {
	# package 56 (Luz): the walks between the intro's scenes – in the tracker on foot and in the journal
	"prologue": {"title": "Prologue", "kind": "story", "chapter": "Prologue · Dan's Dusty Duty Store",
		"desc": "You woke up on Dan's station, three hundred years after a jump that went wrong. Dan has a few things to talk over with you.",
		"steps": [
			{"id": "bar", "title": "Dan in the bar", "text": "Dan asked you to come up to the bar once you're fit. Take the turbolift. He's at the window.",
				"goals": [{"id": "talk", "kind": "talk", "dialogue": "intro_dan_bar", "label": "talk to Dan in the bar"}]},
			{"id": "hangar", "title": "Old Betty", "text": "Dan's ready for the flight training. Take the turbolift down to the hangar. Old Betty's stairs start it. No rush: have a drink, or a round of pool.",
				"goals": [{"id": "go", "kind": "flag", "flag": "tut_go", "label": "Old Betty's stairs in the hangar"}]},
			{"id": "training", "title": "The flight training", "text": "Out in a wreck field with one of Dan's drones. See Flight training.",
				"goals": [{"id": "home", "kind": "flag", "flag": "tut_home", "label": "finish the flight training"}]},
			{"id": "word", "title": "Talk to Dan", "text": "Dan has a few more things to talk over with you. He's in the bar.",
				"goals": [{"id": "talk", "kind": "flag", "flag": "prologue_bar", "label": "talk to Dan in the bar"}],
				"on_done": [{"do": "start", "id": "ticket"}]},
		]},
	# package 56, sequence 6 (Luz): Dan's deal – work for him, earn your passage
	"ticket": {"title": "A Ticket to the Cluster", "kind": "story", "chapter": "Chapter 1 · Beyond",
		"desc": "No ship, no licence, and stuck in Beyond. Dan knows someone who could get you to the Cluster, for a price. His deal: give him a hand and earn your ticket.",
		"steps": [
			{"id": "deal", "title": "Dan's deal", "text": "Dan offered you a ship, gear and a few jobs (about three years of them) to earn your ticket to the Cluster. Talk to him in the bar once you've made up your mind.",
				"goals": [{"id": "yes", "kind": "flag", "flag": "dan_deal_yes", "label": "take Dan's deal"}],
				"on_done": [{"do": "start", "id": "darling"}]},                # Luz: "Working for Dan" in the journal at once
			{"id": "work", "title": "Working for Dan", "text": "About three years of work for Dan, then his friend takes you to the Cluster. The jobs come one by one; each pays a little.",
				"goals": [{"id": "paid", "kind": "flag", "flag": "ticket_paid", "label": "earn your ticket"}]},
		]},
	# package 58, part 1 (Luz): Little Darling – Dan shows you the station window and the Outfitter (a guided tour),
	# you fit the lasers he left in storage and buy a drone with his advance. The flags come from
	# scripts/ground/dan_work.gd; the wreck field follows in part 2.
	"darling": {"title": "Working for Dan", "kind": "story", "chapter": "Chapter 1 · Working for Dan",
		"desc": "Dan gives you a ship and the first jobs. Get to know Little Darling, kit her out and earn your keep.",
		"steps": [
			{"id": "board", "title": "Little Darling", "text": "Board the ship Dan lends you: Little Darling, a small KHI miner in his rust, waits in his hangar. She has some gear already, but a few things still need fitting. Climb aboard, Dan will explain.",
				"goals": [{"id": "board", "kind": "flag", "flag": "ticket_ship", "label": "board the ship Dan gives you"}]},
			{"id": "station", "title": "The station window", "text": "Dan walks you through the station window: you, the news, your ship and her services, the station and its services. Then he wants you in the Outfitter.",
				"goals": [{"id": "tour", "kind": "flag", "flag": "w58_tour1", "label": "follow Dan's tour, open the Outfitter"}]},
			{"id": "fit", "title": "Teeth for her", "text": "Dan left a mining laser and a pulse laser in your storage. Fit the mining laser into a tool slot and the pulse laser into the weapon slot.",
				"goals": [{"id": "mining", "kind": "flag", "flag": "w58_mining", "label": "fit the mining laser"},
					{"id": "weapon", "kind": "flag", "flag": "w58_weapon", "label": "fit the pulse laser"}]},
			{"id": "drone", "title": "A drone of your own", "text": "Dan advanced you 2,500 credits. Back in the station window, buy a drone at the Drone Bay.",
				"goals": [{"id": "drone", "kind": "flag", "flag": "w58_drone", "label": "buy a drone"}],
				"on_start": [{"do": "credits", "n": 2500}],
				"on_done": [{"do": "credits", "n": 1000},
					{"do": "radio", "who": "dan", "text": "There she is. Your first ship in three hundred years, give or take. A thousand on top, for listening so nicely. Now let's earn that advance back."}]},
			# package 58, part 2 (Luz): the wreck field, the drone's controls, scrap home to Dan
			{"id": "salvage", "title": "To the wreck field", "text": "Undock and warp to the wreck field Dan marked: pick it in the overview on the right, or on the map.",
				"goals": [{"id": "field", "kind": "flag", "flag": "w58_atfield", "label": "fly to the marked wreck field"}]},
			{"id": "drones", "title": "Your drone", "text": "Dan explains your drone's controls: launching it, its jobs, how it goes about them, its fuel and recalling it.",
				"goals": [{"id": "drones", "kind": "flag", "flag": "w58_drones", "label": "launch your drone, set it to mining"}]},
			{"id": "mine", "title": "Cut scrap", "text": "Lock a piece of Gold Fleet scrap, switch the mining laser on and let the drone help. Twenty units will do.",
				"goals": [{"id": "mined", "kind": "flag", "flag": "w58_mined", "label": "cut 20 units of scrap"}]},
			{"id": "home", "title": "Back to Dan", "text": "Recall the drone and bring the scrap home to Dan's Dusty Duty Store.",
				"goals": [{"id": "home", "kind": "flag", "flag": "w58_delivered", "label": "bring the scrap to Dan"}],
				"on_done": [{"do": "credits", "n": 2000}]},
			# package 58 (Luz): a room in Dan's quarters, free – sleep there once
			{"id": "rest", "title": "A room upstairs", "text": "Dan put you in one of his rooms, on the house. Take the lift up to the Quarters, find your room (its lamp is green) and sleep in your bed.",
				"goals": [{"id": "slept", "kind": "flag", "flag": "w58_slept", "label": "sleep in your room in Dan's quarters"}]},
			# package 58, part 3 (Luz): Ossa Kell on Brine, the escort to Driftwood, Dan's call, home
			{"id": "next", "title": "More work", "text": "Dan has a few people who need things moved around Beyond. Rest a little, then see him in his bar.",
				"goals": [{"id": "job", "kind": "flag", "flag": "w58_job", "label": "talk to Dan in his bar"}]},
			{"id": "brine", "title": "Upper Brine", "text": "Dan's client is Ossa Kell of Kell Freight. Fly to Brine, descend and land in Upper Brine: she meets you at your ship in the city's hangar. Dan lent you a better laser and armour plating for the job.",
				"goals": [{"id": "ossa", "kind": "flag", "flag": "w58_ossa", "label": "meet Ossa Kell in Upper Brine"}]},
			{"id": "escort", "title": "Kell Freight", "text": "Ossa's two haulers take on Dan's scrap at his store. Meet them outside, follow the lead hauler, and see them safely through the gate to the Driftwood Waystation. Pirates like to pull convoys out of warp: stay close.",
				"goals": [{"id": "escort", "kind": "flag", "flag": "w58_escorted", "label": "escort Ossa's haulers to the Driftwood Waystation"}]},
			{"id": "call", "title": "Dan calls", "text": "Ossa paid. Dan is on the radio.",
				"goals": [{"id": "call", "kind": "flag", "flag": "w58_called", "label": "answer Dan's call"}]},
			{"id": "back", "title": "Home to Dan", "text": "That's enough for now. You've earned a drink, and Little Darling needs some love. Fly back to Dan's Dusty Duty Store.",
				"goals": [{"id": "back", "kind": "flag", "flag": "w58_back", "label": "fly back to Dan's store"}]},
		]},
	# package 58, part 4 (Luz): after the party – the Maul from Ossa, then Dan's friend in Driftwood, the pirates' station
	"fight": {"title": "Taking the Fight to Them", "kind": "story", "chapter": "Chapter 1 · Working for Dan",
		"desc": "The pirates around Beyond keep getting bolder. Dan's best employee wants to take the fight to them.",
		"steps": [
			{"id": "maul", "title": "The Maul", "text": "Dan has talked to Ossa: she gives you her Maul, a patched-up gunboat. Fly to Brine, land in Upper Brine and find Ossa in the shopping street.",
				"goals": [{"id": "maul", "kind": "flag", "flag": "w58_maul", "label": "pick up the Maul from Ossa in Upper Brine"}]},
			{"id": "contact", "title": "A friend in Driftwood", "text": "Dan sends you the contact of a friend in Driftwood who might know how to track the pirates down. (Package 58: comes with the next part.)",
				"goals": [{"id": "contact", "kind": "flag", "flag": "w58_contact", "label": "talk to Dan's friend in Driftwood"}]},
		]},
	# package 56, sequence 5 (Luz): the flight training – flown with one of Dan's drones from Old Betty in a wreck field;
	# the flags are set by scripts/ground/intro_five.gd (it watches the drone), the targets too
	"flight_training": {"title": "Flight training", "kind": "story", "lessons": true, "chapter": "Prologue · Dan's drones",
		"desc": "Dan lends you one of his remote drones and takes you out to a wreck field in Old Betty to brush up on the basics. Every lesson stays here to read again.",
		"steps": [
			{"id": "journal", "title": "The journal", "text": "Dan's calls, your missions and every lesson are kept in the journal: {journal}. The mission you track shows its next goals over your ship's panel; a gold diamond marks its target.",
				"goals": [{"id": "open", "kind": "flag", "flag": "tut_journal", "label": "open the journal"}],
				"on_start": [{"do": "radio", "who": "dan", "text": "Before we start: everything I tell you goes into your journal. Open it: {journal}. Have a look, then close it again."}]},
			{"id": "fly", "title": "Flying", "text": "Fly with {move}. The drone flies the way you point it and stops when you let go. Take a lap round Old Betty.",
				"goals": [{"id": "lap", "kind": "flag", "flag": "tut_lap", "label": "a lap round Old Betty"}],
				"on_start": [{"do": "radio", "who": "dan", "text": "Good. Now she's all yours. Fly with {move}. Take a lap round Betty, get a feel for her."}]},
			{"id": "views", "title": "Zoom and the views", "text": "Zoom with {zoom}, each step is one of the views. Combat: close, for fighting and mining. Recon: as far as your sensors reach. Orbit: the moons round a planet. System: the whole system as a map. The ship doesn't fly while it's open. {views}",
				"goals": [{"id": "recon", "kind": "flag", "flag": "tut_recon", "label": "Recon"}, {"id": "system", "kind": "flag", "flag": "tut_system", "label": "System map"},
					{"id": "combat", "kind": "flag", "flag": "tut_combat", "label": "back to Combat"}],
				"on_start": [{"do": "radio", "who": "dan", "text": "Nice flying. Now the views. Zoom out with {zoom}, all the way to the System map, then back down to Combat."}],
				"on_done": [{"do": "radio", "who": "dan", "text": "One more thing: warp and the gates are locked. The drone only listens to Betty, and her signal doesn't reach that far."}]},
			{"id": "mine", "title": "Mining", "text": "Pick a piece of scrap: {key:sel_target} steps through the targets in sensor range, or click one. Lock it with {key:cmd_lock}, then switch on the mining laser. It sits in fire group 5: press {key:module_5}. Stay close, the laser reaches 320 km.",
				"goals": [{"id": "mined", "kind": "flag", "flag": "tut_mined", "label": "fill the hold with scrap"}],
				"on_start": [{"do": "radio", "who": "dan", "text": "Normally you'd have to put your modules into fire groups yourself. You'll find that in the Ship menu, under Modules. I've done it for you already: the mining laser is on {key:module_5}, and if you need to defend yourself, the guns are on {key:module_1}."},
					{"do": "radio", "who": "dan", "text": "See the scrap I marked? Cut me a load of it. And keep your eyes open, pirates sometimes hang around here."}]},
			{"id": "unload", "title": "Unloading", "text": "Fly back to Old Betty. Close to her, the drone's hold empties into hers.",
				"goals": [{"id": "betty", "kind": "near", "target": "@target", "km": 600.0, "label": "back to Old Betty"}],
				"on_start": [{"do": "radio", "who": "dan", "text": "Hold's full? Good. Bring it to Betty, get close and I'll take it off you."}]},
			{"id": "far", "title": "Another load", "text": "Dan sent you to a wreck colossus further out for the next load. Its plating is worth more.",
				"goals": [{"id": "wreck", "kind": "flag", "flag": "tut_ambush", "label": "fly to the wreck colossus"}],
				"on_start": [{"do": "radio", "who": "dan", "text": "Nice haul. Now the big one out there, that colossus. Its plating's worth a lot more."}]},
			{"id": "lock", "title": "Pirates!", "text": "Two pirates came out from behind the wreck. Lock one: {key:sel_hostile} picks the next hostile ship, {key:cmd_lock} locks it.",
				"goals": [{"id": "locked", "kind": "flag", "flag": "tut_locked", "label": "lock a pirate"}]},
			{"id": "fire", "title": "Fight back", "text": "Your laser sits in fire group 1: press {key:module_1} to fire at the locked target. Keep moving: a moving target is harder to hit. The shield takes the first hits and comes back while you aren't hit.",
				"goals": [{"id": "hit", "kind": "flag", "flag": "tut_hit", "label": "hit a pirate"}],
				"on_start": [{"do": "radio", "who": "dan", "text": "Locked on. Now fire with {key:module_1}! And keep moving!"}]},
			{"id": "finish", "title": "Drive them off", "text": "Shoot one of them down and the other will run.",
				"goals": [{"id": "over", "kind": "flag", "flag": "tut_fight_over", "label": "drive the pirates off"}],
				"on_start": [{"do": "radio", "who": "dan", "text": "That's it, keep at it! Bring one down and the other will think twice."}]},
			{"id": "home", "title": "Home", "text": "Dan takes you back to his station in Old Betty. Everything else is explained in the codex, in the Pilot menu.",
				"goals": [{"id": "home", "kind": "flag", "flag": "tut_home", "label": "back at the station"}]},
		]},
	"debug_test": {"title": "Framework test", "kind": "story", "chapter": "Debug · package 55", "debug_only": true,
		"desc": "A short test of the story's framework: a dialogue, a radio call, a tip, a goal with its marker, docking. Started from the debug menu.",
		"steps": [
			{"id": "hello", "title": "Talk to Dan", "text": "Dan wants a word before you start.",
				"goals": [{"id": "talk", "kind": "talk", "dialogue": "test_hello", "label": "talk to Dan"}],
				"on_start": [{"do": "dialogue", "id": "test_hello"}]},
			{"id": "fly", "title": "Fly to the station", "text": "Dan marked a station for you, not the one you are at. Fly there.",
				"goals": [{"id": "near", "kind": "near", "target": "@target", "km": 4000.0, "label": "get within 4,000 km"}],
				"on_start": [{"do": "target", "what": "next_station"}, {"do": "radio", "who": "dan", "text": "See the gold diamond? That's where you're going. Fly in, no rush."},
					{"do": "tip", "id": "tip_objective"}]},
			{"id": "dock", "title": "Dock at the station", "text": "Close enough. Now dock.",
				"goals": [{"id": "dock", "kind": "dock", "target": "@target", "label": "dock"}],
				"on_start": [{"do": "radio", "who": "dan", "text": "Now dock. Select the station and let the ship do the rest."}, {"do": "tip", "id": "tip_docking"}],
				"on_done": [{"do": "credits", "n": 1000}, {"do": "secret", "id": "test_secret"},
					{"do": "radio", "who": "dan", "text": "Docked. That's the test done. A thousand credits for your trouble."}]},
		]},
}
