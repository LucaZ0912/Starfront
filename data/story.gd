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
	# package 58, part 5 (Luz): Dan's friend in Driftwood – a tinkerer with a Bastion and a device that listens
	# package 58, part 6 (Luz): Ossa's gunner on the Maul, your partner on the ground (no gender: Luz, 20 Nov 2026)
	"rook": {"name": "Rook Varga", "sub": "Gunner · the Maul", "col": Color(1.0, 0.6, 0.3), "seed": 7713,
		# (Luz) pink hair, and more dangerous: a sidecut in neon pink, a scar across the eye, a cyber eye, neck lines
		"look": {"body": 1, "skin": 5, "hair": 9, "hair_color": 8, "eyes": 5, "brows": 2, "beard": 0, "scar": 2, "freckles": 0,
			"outfit": 2, "color1": 0, "color2": 8, "implant": 1, "tattoo": 3, "headgear": 0, "lipstick": 0, "blush": 0, "eye_makeup": 0}},
	# package 59 (Luz): Dan's friend from the Directorate, with the Threshold – a man around sixty, grey hair, glasses,
	# Directorate green and silver (Luz: not like Silas, so bald with a grey goatee, a broader build, a jacket)
	# package 62a, part 3 (Luz: give the one at the registration an identity): the Marshal of the Lists, who fought in
	# the arena once (champion 2716): a scar, a long dark coat with gold
	"marshal": {"name": "Cass Ardent", "sub": "Marshal of the Lists · the Colosseum", "col": Color(1.0, 0.82, 0.35), "seed": 6233,
		"look": {"body": 1, "skin": 3, "hair": 4, "hair_color": 5, "eyes": 2, "brows": 2, "beard": 0, "scar": 1, "freckles": 0,
			"outfit": 3, "color1": 0, "color2": 10, "implant": 1, "tattoo": 0, "headgear": 0, "lipstick": 0, "blush": 0, "eye_makeup": 0}},
	"imre": {"name": "Dr. Imre Halden", "sub": "Meridian Directorate · the Threshold", "col": Color(0.45, 0.95, 0.65), "seed": 5911,
		"look": {"body": 1, "skin": 4, "hair": 0, "hair_color": 6, "eyes": 4, "brows": 2, "beard": 2, "scar": 0, "freckles": 0,
			"outfit": 1, "color1": 6, "color2": 2, "implant": 0, "tattoo": 0, "headgear": 3, "lipstick": 0, "blush": 0, "eye_makeup": 0}},
	# package 59, part 3 (Luz): the bureaucrats of the naturalisation – a tired clerk of the Assembly, a stiff registrar
	# of the Covenant
	"clerk_asm": {"name": "Clerk Pell Ansgar", "sub": "Assembly Registry · Office 14-C", "col": Color(0.45, 0.7, 1.0), "seed": 5931,
		"look": {"body": 1, "skin": 2, "hair": 2, "hair_color": 2, "eyes": 0, "brows": 1, "beard": 1, "scar": 0, "freckles": 0,
			"outfit": 1, "color1": 4, "color2": 3, "implant": 0, "tattoo": 0, "headgear": 1, "lipstick": 0, "blush": 0, "eye_makeup": 0}},
	"registrar_cov": {"name": "Registrar Oriel Tane", "sub": "Chancery of the Return", "col": Color(1.0, 0.75, 0.35), "seed": 5932,
		"look": {"body": 0, "skin": 0, "hair": 8, "hair_color": 0, "eyes": 5, "brows": 0, "beard": 0, "scar": 0, "freckles": 0,
			"outfit": 3, "color1": 8, "color2": 10, "implant": 0, "tattoo": 2, "headgear": 0, "lipstick": 0, "blush": 0, "eye_makeup": 0}},
	# package 61 (Luz): Luz of Centauria – long platinum hair, freckles, neck lines, an orange jacket over crimson
	"luz": {"name": "Luz", "sub": "Bar owner · Centauria", "col": Color(1.0, 0.55, 0.3), "seed": 6101,
		"look": {"body": 1, "skin": 2, "hair": 4, "hair_color": 5, "eyes": 3, "brows": 0, "beard": 0, "scar": 0, "freckles": 1,
			"outfit": 1, "color1": 9, "color2": 8, "implant": 0, "tattoo": 3, "headgear": 0, "lipstick": 5, "blush": 0, "eye_makeup": 0}},
	# package 61b (Luz): two of the Static Feedback's regulars, a little shady
	"ratte": {"name": "Ratte", "sub": "Knows a way in · the Back Alleys", "col": Color(0.6, 0.9, 0.5), "seed": 6131,
		"look": {"body": 0, "skin": 1, "hair": 9, "hair_color": 0, "eyes": 2, "brows": 1, "beard": 1, "scar": 1, "freckles": 0,
			"outfit": 3, "color1": 0, "color2": 7, "implant": 1, "tattoo": 3, "headgear": 0, "lipstick": 0, "blush": 0, "eye_makeup": 0}},
	"kraut": {"name": "Kraut", "sub": "Says little · the Back Alleys", "col": Color(0.9, 0.5, 0.4), "seed": 6137,
		"look": {"body": 2, "skin": 3, "hair": 6, "hair_color": 3, "eyes": 1, "brows": 2, "beard": 3, "scar": 2, "freckles": 0,
			"outfit": 1, "color1": 0, "color2": 2, "implant": 2, "tattoo": 2, "headgear": 0, "lipstick": 0, "blush": 0, "eye_makeup": 0}},
	# package 61b (Luz): The Hull Breach, the band of the Static Feedback (real people on its stage at night)
	"band_voice": {"name": "Vex", "sub": "The Hull Breach · vocals", "col": Color(1.0, 0.36, 0.66), "seed": 6141,
		"look": {"body": 0, "skin": 0, "hair": 6, "hair_color": 3, "eyes": 2, "brows": 1, "beard": 0, "scar": 0, "freckles": 0,
			"outfit": 1, "color1": 8, "color2": 0, "implant": 0, "tattoo": 1, "headgear": 0, "lipstick": 0, "blush": 0, "eye_makeup": 0}},
	"band_guitar": {"name": "Solder", "sub": "The Hull Breach · guitar", "col": Color(1.0, 0.45, 0.25), "seed": 6143,
		"look": {"body": 1, "skin": 2, "hair": 9, "hair_color": 0, "eyes": 1, "brows": 0, "beard": 1, "scar": 0, "freckles": 0,
			"outfit": 1, "color1": 0, "color2": 9, "implant": 3, "tattoo": 3, "headgear": 0, "lipstick": 0, "blush": 0, "eye_makeup": 0}},
	"band_bass": {"name": "Flux", "sub": "The Hull Breach · bass", "col": Color(0.3, 0.9, 1.0), "seed": 6147,
		"look": {"body": 2, "skin": 3, "hair": 5, "hair_color": 1, "eyes": 3, "brows": 2, "beard": 1, "scar": 0, "freckles": 0,
			"outfit": 3, "color1": 4, "color2": 0, "implant": 0, "tattoo": 0, "headgear": 3, "lipstick": 0, "blush": 0, "eye_makeup": 0}},
	"band_drums": {"name": "Tin", "sub": "The Hull Breach · drums", "col": Color(0.95, 0.85, 0.3), "seed": 6149,
		"look": {"body": 1, "skin": 1, "hair": 1, "hair_color": 0, "eyes": 0, "brows": 1, "beard": 3, "scar": 3, "freckles": 0,
			"outfit": 1, "color1": 6, "color2": 0, "implant": 0, "tattoo": 2, "headgear": 0, "lipstick": 0, "blush": 0, "eye_makeup": 0}},
	"silas": {"name": "Silas Marr", "sub": "Engineer · the Stubborn Hope", "col": Color(0.55, 0.75, 1.0), "seed": 4419,
		"look": {"body": 0, "skin": 2, "hair": 3, "hair_color": 7, "eyes": 3, "brows": 1, "beard": 4, "scar": 0, "freckles": 1,
			"outfit": 3, "color1": 1, "color2": 5, "implant": 3, "tattoo": 0, "headgear": 3, "lipstick": 0, "blush": 0, "eye_makeup": 0}},
	# package 58, part 8 (Luz): the pirates of the Red Talon Roost on the radio – a voice in the hangar, their captain
	"talon": {"name": "Red Talon", "sub": "◉ Pirate radio · the Roost", "col": Color(1.0, 0.35, 0.3), "seed": 6661,
		"look": {"hair": 2, "hair_color": 1, "scar": 1, "implant": 2, "tattoo": 2, "outfit": 2, "color1": 0, "color2": 8}},
	"talon_boss": {"name": "Red Talon captain", "sub": "◉ Pirate radio · the Roost", "col": Color(1.0, 0.25, 0.2), "seed": 6662,
		"look": {"hair": 6, "hair_color": 2, "beard": 2, "scar": 3, "implant": 1, "tattoo": 1, "outfit": 2, "color1": 0, "color2": 0, "headgear": 2}},
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
		{"text": "I know someone who might be able to help you. Someone with contacts in the Assembly and the Covenant, who'll get you placed, no doubt. And with a ship that can make the trip.",
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
		{"text": "Ossa Kell. Runs Kell Freight out of Brine: two old haulers and a lot of stubbornness. Ossa buys my scrap and sells it on in Driftwood."},
		{"text": "Only lately the pirates have taken a liking to Ossa's runs. Two haulers lost this year. No more flying without an escort, and nobody out here does escorts.",
			"answers": [["\"So I'm the escort.\"", 3, [], "And let me guess: I'm the escort now."],
				["\"Pirates? In Little Darling?\"", 3, [], "Pirates? You want me to take on pirates in a mining ship?"]]},
		{"text": "You're what I've got. And Little Darling's tougher than she looks. Like her pilot."},
		{"text": "My boys put a better laser in her and some armour plating. On loan, like the rest. Don't scratch it.",
			"answers": [["\"Where do I find Ossa?\"", 5, ["w58_job", true], "Fine, I'll do it. Where do I find this Ossa Kell?", {"gold": true}]]},
		{"text": "Upper Brine, the city down on Brine. Land there and Ossa will meet you at your ship in the hangar. And be nice: Ossa pays on time, the only one out here who does.", "next": -1},
	]},
	# package 62a, part 3 (Luz): the Colosseum's registration. "Register" (later "Compete") sets the flag col_go: the
	# game goes on from there (the way to play, through the gate, the fighters' room)
	"col_marshal": {"who": "marshal", "lines": [
		{"text": "Welcome to the Colosseum. Cass Ardent, Marshal of the Lists. I keep the names, the rounds and the peace between them. You look like someone who wants on the list.",
			"answers": [["Register", 3, ["col_go", true], "Put me on the list. I want to fight.", {"gold": true}],
				["What is the Colosseum?", 1, [], "What is this place, exactly?"],
				["What are the rules?", 2, [], "And the rules down there?"],
				["Later.", -1]]},
		{"text": "The oldest house in Centauria that still tells the truth. Down there nobody has the name the city gave them, only the one they earn. The floor is a holo grid: the arena builds the ground you fight on, and takes it away again. Nobody dies in it. Plenty have wished they had, for a day or two.", "next": 0},
		{"text": "Simple ones. Your own gear stays in the locker. The house hands out everything, and you fit yourself from gear points. Win, and you get Coins and more points. The points are yours to fit as you like before every fight. And no fighting on the carpet.", "next": 0},
		{"text": "Good. Your name goes on the list, the gate behind me opens to you. Pick how you want to play, then go on through. The room behind the gate is where you fit yourself.", "next": -1},
	]},
	"col_marshal_back": {"who": "marshal", "lines": [
		{"text": "Back for more? The list still has your name on it.",
			"answers": [["Compete", 1, ["col_go", true], "I am here to fight.", {"gold": true}],
				["What is the Colosseum?", 2, [], "Tell me again what this place is."],
				["What are the rules?", 3, [], "Remind me of the rules."],
				["Later.", -1]]},
		{"text": "Then pick how you want to play. The gate is open.", "next": -1},
		{"text": "The oldest house in Centauria that still tells the truth. Down there nobody has the name the city gave them, only the one they earn. The floor is a holo grid: the arena builds the ground you fight on, and takes it away again.", "next": 0},
		{"text": "Your own gear stays in the locker. The house hands out everything, and you fit yourself from gear points. Win, and you get Coins and more points. And no fighting on the carpet.", "next": 0},
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
		{"text": "I'll let Ossa know. Ossa's got a Maul. A pretty patched-up old thing, but it'll do out here."},
		{"text": "Then you should talk to a friend of mine in Driftwood, who might know how to track the pirates down. I'll send you the contacts once you've got the Maul."},
		{"text": "But tonight you're the star of the party. Have a few more, and we'll see tomorrow.", "next": -1},
	]},
	# package 58, part 8 (Luz): the celebration in Dan's bar after the Roost – the whiskey from Earth, Ossa's gift
	"strike_party": {"who": "dan", "lines": [
		{"text": "Whiskey from Earth. The real thing. I promised."},
		{"who": "ossa", "text": "To the craziest crew this side of the Veil."},
		{"who": "rook", "text": "And to the paint job. Rest in peace."},
		{"who": "silas", "text": "To the relay. Best thing we ever broke."},
		{"text": "Three hundred years in a box, and the first thing you do is blow up a pirate nest. Not bad, kid. Not bad at all."},
		{"who": "ossa", "text": "My gear goes back in my locker. But this is yours: a combat suit and a laser drone. You've earned them.",
			"answers": [["\"Thank you, all of you.\"", 6, ["w58_gifts", true], "Thank you. All of you. I woke up in a world I didn't know, and you made room for me in it.", {"gold": true}]]},
		{"text": "Drink up. Tomorrow there's still plenty of work, and you're still my best pilot.", "next": -1},
	]},
	# package 58, part 4: Ossa hands you her Maul (in Upper Brine's shopping street)
	"ossa_maul": {"who": "ossa", "lines": [
		{"text": "There's our pirate hunter. Dan told me everything. Mad, the lot of you."},
		{"text": "So. The Maul. Hadrian built her as a gunboat, the pirates shot her full of holes, and I patched her up. Twice.",
			"answers": [["\"Will she hold?\"", 2, [], "Will she hold together out there, Ossa?"],
				["\"Twice?\"", 2, [], "Twice? That's not exactly reassuring."]]},
		{"text": "Better than she looks. A strong shield, real guns, a drone bay with drones in it, and a repair system that patches her up while you fly. I didn't skimp. You'll need all of it."},
		{"text": "And she doesn't fly herself. Rook Varga comes along as your gunner: the best I ever had, and nobody hates pirates more than Rook does. Don't get my gunner killed.",
			"answers": [["\"Thank you, Ossa.\"", 4, ["w58_maul", true], "Thank you, Ossa. I'll bring her back in one piece. Mostly.", {"gold": true}]]},
		{"text": "Bring yourself back, that's enough. Now, you've never flown with a crew, have you? Let me show you how that works.", "next": -1},
	]},
	# package 58, part 5 (Luz): Silas Marr in the Driftwood Waystation's diner – the Listener
	# package 58, part 6 (Luz): back at Dan's after the Listener – the way into the briefing
	"dan_report": {"who": "dan", "lines": [
		{"text": "There's my pirate hunter. Silas called: says the data took some untangling, but there's something to show us now. Ossa's here too.",
			"answers": [["\"About the pirate base...\"", 1, ["w58_briefing", true], "About the pirate base. Silas said something wasn't right with the data."],
				["\"Later, Dan.\"", 2, [], "Give me a minute first, Dan. I'll be back."]]},
		{"text": "Then let's hear it. I'll close the bar. Everyone round the pool table.", "next": -1},
		{"text": "Don't take too long. Silas is pacing a hole in my floor.", "next": -1},
	]},
	# package 58, part 6 (Luz): the briefing round the pool table in the empty bar
	"briefing": {"who": "silas", "lines": [
		{"text": "See, I already suspected the data was too good to be true. These pirates are smarter and better prepared than we thought."},
		{"text": "They run their communications through a special relay station. There's no way around it: we have to get in there and pull the data straight out of their computer system."},
		{"who": "dan", "text": "Damn, missed again. Then we need a ground team. All I've got is a few miners, nobody with combat experience.",
			"answers": [["\"I've had combat training.\"", 3, [], "I've had combat training. Mind you, that was three hundred years ago. A refresher would be great."]]},
		{"who": "ossa", "text": "Well, Dan. I win again."},
		{"who": "dan", "text": "..."},
		{"who": "ossa", "text": "Fine. I'll have Rook bring you up to date. We'll use the hangar for a combat simulation. Afterwards Rook goes with you to the relay station: the only one I know who's crazy enough to come along and good enough to survive it."},
		{"text": "One more thing. What I could make out about their station is worrying. The Maul will never be enough to stand against that monster."},
		{"who": "ossa", "text": "Where do these raiders get all that tech from? The Gold Fleet, maybe?"},
		{"who": "dan", "text": "You know what?! We're ending this pirate plague now. We fly out together and deal with that station ourselves!"},
		{"who": "ossa", "text": "Hahaha, that takes me back. But of course, I'm in!"},
		{"text": "Me too!",
			"answers": [["\"Let's show them!\"", 11, [], "Then let's show them what we've got!"]]},
		{"who": "dan", "text": "Then it's settled. While you two get into the relay station, we get our ships ready for the fight. Send us the coordinates as soon as you have them, and we attack together."},
		{"who": "dan", "text": "Once the relay station is down, we have to move fast. As long as they're confused and cut off, we have the edge."},
		{"who": "dan", "text": "If we live through this, I'm opening my whiskey from Earth."},
		{"who": "ossa", "text": "Deal.", "next": -1},
	]},
	# package 58, part 6 (Luz): Rook in Dan's hangar, the simulation ready
	"rook_sim": {"who": "rook", "lines": [
		{"text": "There you are. Ossa told me: you, me and a pirate relay. Better than sitting at the guns waiting for them to come to us."},
		{"text": "And you asked for a refresher, I hear. Three hundred years, was it? Then let's knock the rust off."},
		{"text": "On foot it's different from the Maul: no hull between you and them. So we run it here first. The hangar's set up with holograms. They hit like the real thing, but nobody dies in here.",
			"answers": [["\"Let's go.\"", 3, ["w58_sim_go", true], "All right. Let's see how rusty I am."],
				["\"Give me a moment.\"", 4, [], "Give me a moment to get ready first."]]},
		{"text": "Stay close and listen. I'll talk you through it.", "next": -1},
		{"text": "Take your time. The holograms aren't going anywhere.", "next": -1},
	]},
	# package 58, part 7 (Luz): fallen at the relay – awake at Dan's
	"dan_relay_wake": {"who": "dan", "lines": [
		{"text": "Easy, easy. You're at my place. Rook dragged you back to the drone, and Ossa's people flew you both home."},
		{"text": "Rook's fine, by the way. Swearing a lot, but fine.",
			"answers": [["\"The relay...\"", 2, [], "The relay. We didn't get the coordinates."]]},
		{"text": "It'll still be there. They'll have patched up what you broke, so it's a fresh start. Rest, check your gear, and go again when you're ready.", "next": -1},
	]},
	# package 58, part 6 (Luz): after a round of the simulation – more, or done
	"rook_more": {"who": "rook", "lines": [
		{"text": "Want to keep going? I can put three more in here, as often as you like.",
			"answers": [["\"Three more.\"", 1, ["w58_sim_more", true], "Three more. I want to try a few things."],
				["\"That's enough.\"", 2, ["w58_sim_end", true], "That's enough for today. I'm ready."]]},
		{"text": "Coming up.", "next": -1},
		{"text": "Then let's go find that relay.", "next": -1},
	]},
	"silas_meet": {"who": "silas", "lines": [
		{"text": "Ah. Dan's pirate hunter. Sit, sit. The coffee here is terrible, but it's hot."},
		{"text": "Silas Marr. Dan and I go back a long way. Further than either of us likes to admit.",
			"answers": [["\"Dan says you can find them.\"", 2, [], "Dan says you might know how to find the pirates."],
				["\"How do you know Dan?\"", 7, [], "How do you two know each other?"]]},
		{"text": "Find them? I built something better than a map. I call it the Listener. Every pirate out here talks: to their friends, to their base, to their mothers. The Listener hears all of it."},
		{"text": "Give it enough time and it works out where all that chatter comes from. Their nest.",
			"answers": [["\"Where's the catch?\"", 4, [], "There's always a catch out here. What is it?"]]},
		{"text": "The catch is that listening is loud. The moment I switch it on, every pirate in range hears that someone is listening. And they'll come to switch it off. With guns."},
		{"text": "So. I take the Stubborn Hope out to a quiet asteroid field, unfold the Listener, and you keep them off me until it's done. A few minutes, three waves, maybe four. Dan says you're good.",
			"answers": [["\"I'll keep them off you.\"", 6, ["w58_contact", true], "Then let's do it. You listen, I'll keep them off you.", {"gold": true}]]},
		{"text": "Good. I'm docked outside. Follow me when I undock and stay close. And Spacefarer? Don't let them near the dish.", "next": -1},
		# 7 – how Silas knows Dan
		{"text": "We salvaged the same wreck once, from both ends, and met in the middle with our cutters drawn. Two days later we were sharing a bottle. That was twenty years ago.", "next": 2},
	]},
	# package 58 (Luz): shot down while working for Dan – you wake in his clinic, no game over
	"dan_wake": {"who": "dan", "lines": [
		{"text": "Easy, easy. You're back in my clinic. My boys fished you out of what was left of the cockpit. Doc says you'll live."},
		{"text": "And Little Darling? Patched up, again. She's taken worse. So what are you still lying around here for?",
			"answers": [["\"The convoy…\"", 2, [], "The convoy… what happened to Ossa's haulers?", {"if": [["w58_phase", "convoy"]]}],
				["\"Back to work.\"", 3, [], "Alright, alright. I'm getting up. Back to work."]]},
		{"text": "Ossa's waiting outside my store with what's left, and not happy about it. Get back in Little Darling. The moment you undock, we try that again.", "next": -1},
		{"text": "That's the spirit. Ossa's waiting for you in the hangar.", "next": -1},
	]},
	# package 58, part 8 (Luz): shot down at the Roost – the Maul, the rendezvous
	"dan_wake_strike": {"who": "dan", "lines": [
		{"text": "Easy, easy. You're back in my clinic. Rook dragged you out, and Ossa towed what was left of the Maul home."},
		{"text": "She's patched up again. Ossa wasn't happy about the state of her, mind.",
			"answers": [["\"The Roost...\"", 2, [], "The Roost... it's still out there, isn't it?"]]},
		{"text": "It is. We pulled back to the rendezvous. When you're ready, meet us there and we go again. Together.", "next": -1},
	]},
	# package 59, part 1 (Luz): the closed bar the morning after – Dan and Dr. Imre Halden
	"halden_meet": {"who": "dan", "lines": [
		{"who": "you", "text": "Morning, Dan. The bar's closed and you've got company. What's going on here?"},
		{"text": "There you are. Remember our deal? You work for me, and I get you to the Cluster."},
		{"text": "Well. After the Roost, after everything you did out here, I'd say you've more than earned it. So I made a call."},
		{"text": "This is Dr. Imre Halden, Meridian Directorate. An old friend, and the only one I know who flies in and out of Beyond."},
		{"who": "imre", "text": "A pleasure. A real pleasure. Dan told me about you, and to be honest, I didn't believe a word of it."},
		{"who": "imre", "text": "A pilot from before the Severance. You've seen Earth. With your own eyes. Not in an archive, not on a recording.",
			"answers": [["\"I have.\"", 6, [], "I have. Blue oceans, grey cities, far too many people. Back then it was just home."],
				["\"Feels like yesterday.\"", 6, [], "For me it feels like yesterday. For everyone else it's been three hundred years. I'm still getting used to that."]]},
		{"who": "imre", "text": "Do you know how many people in the Cluster can say that? None. Earth is a story to them. A myth."},
		{"who": "imre", "text": "I've spent my life collecting what's left of it. Charts from the Gold Fleet, old instruments, a whole crate of Earth coins Dan swears are real."},
		{"text": "They are real."},
		{"who": "imre", "text": "One day I want to open a museum. About Earth: what it was, who we were before the Veil. Someone like you could tell it better than any exhibit."},
		{"who": "imre", "text": "But that's for another day. My Threshold is waiting outside. A prototype, one of the very few ships that can cross the Veil."},
		{"who": "imre", "text": "I can take you to the Cluster whenever you like. There's no hurry. Say your goodbyes, finish what you need to, and come and talk to me when you're ready."},
		{"text": "Take your time. The bar opens at noon, and the first round's on me. Again.", "next": -1},
	]},
	# package 59, part 1 (Luz): Imre in the bar – leave, or ask about the Cluster and its three powers first
	"imre_talk": {"who": "imre", "lines": [
		{"text": "There's no hurry. Is there something you want to know first, or are you ready to go?",
			"answers": [["Time to leave...", 6, [], "I think it's time.", {"gold": true}],
				["How do things stand in the Cluster?", 1, [], "So how do things stand in the Cluster these days?"],
				["Tell me about the Assembly.", 2, [], "Tell me about the Assembly. Who are they?"],
				["Tell me about the Covenant.", 3, [], "And the Covenant? What should I know about them?"],
				["Tell me about the Directorate.", 4, [], "What about the Directorate? Your people."],
				["Never mind.", -1]]},
		{"text": "Quiet, for now. It's been almost two hundred years since the Severance. The Dark Decades are long over, but the peace between the Assembly and the Covenant is old and thin. They share the core, and their border systems are disputed. Every few years someone tests that border. Pirates hold the rim, and we in the Directorate keep to ourselves and trade with everyone.", "next": 0},
		{"text": "The Cluster Assembly. Every citizen votes on every law, directly, over the gate network. They call it the Vote. Slow to decide, but hard to fool. Traders, colonists, station crews. Their motto is 'The Cluster is home', and they mean it. They stopped waiting for Earth a long time ago.", "next": 0},
		{"text": "The Covenant of Return. A faith and a state at once. They believe the Severance was a trial and that humanity is meant to return to Earth. The Hierarch rules from Aureola, above Compline. Proud, strict, very good at war. Someone who has seen Earth? They will be curious about you. Perhaps too curious.", "next": 0},
		{"text": "Us. The Meridian Directorate. A council of experts, every office earned by examination. We came out of a research expedition that was in the Cluster when the gate fell. We build, we heal, we study. And we look for a way through the Veil. Project Bridge.",
			"answers": [["\"Why not the Directorate?\"", 5, [], "Why can't I come with you? To the Directorate, I mean."],
				["Something else.", 0]]},
		{"text": "We don't take settlers. A small enclave, a great many secrets, and frankly, far too many questions about you. Assembly or Covenant: both will have you.", "next": 0},
		# 6 – package 59, part 2: the question before you go
		{"text": "Ready to leave Beyond? There's no coming back for a while.",
			"answers": [["\"I'm ready.\"", -1, ["w59_go", true], "I'm ready. Let's go, before I change my mind.", {"gold": true}],
				["\"Not yet.\"", 7, [], "Not yet. Give me a little more time."]]},
		{"text": "Of course. I'll be right here. The coffee's better than I expected.", "next": -1},
	]},
	# package 59, part 2 (Luz): the farewell in Dan's hangar – Dan, Ossa, Silas and Rook by Little Darling
	"farewell59": {"who": "dan", "lines": [
		{"text": "So. This is it, then."},
		{"text": "Feels like yesterday I pulled a frozen pod out of the Veil and thought: well, there goes the salvage money."},
		{"text": "Don't let them cheat you at the market. And if you ever find a way back out here, bring whiskey. The good stuff."},
		{"who": "ossa", "text": "You fly well. Better than most I've paid. Keep the suit. Keep your head down."},
		{"who": "silas", "text": "Take care out there. And write. You know I'll be listening."},
		{"who": "silas", "text": "If you ever send something our way, the Hope will hear it. Probably. The Veil is very loud."},
		{"who": "ossa", "text": "One more thing. Rook goes with you."},
		{"who": "rook", "text": "Don't look at me like that. Someone has to keep you alive out there. Just for a while."},
		{"who": "ossa", "text": "Bring Rook back in one piece."},
		{"who": "rook", "text": "No promises about the paint."},
		{"text": "And don't worry about Little Darling. I'll keep her warm. Somebody has to fly the scrap runs now."},
		{"text": "Well? Say something, before I get sentimental.",
			"answers": [["\"Thank you. For everything.\"", 12, [], "Thank you. All of you. You took in a stranger who fell out of a hole in the sky, and you gave me a place here. I won't forget it.", {"gold": true}],
				["\"I'll be back.\"", 13, [], "I'll be back one day. Keep a stool free for me at the bar."]]},
		{"text": "Yeah, yeah. Get out of here, before I start crying into the whiskey.", "next": 14},
		{"text": "You'd better. Your tab's still open.", "next": 14},
		{"who": "ossa", "text": "Go on. Your ride's waiting.", "next": -1},
	]},
	# package 59, part 2 (Luz): Imre comes over – Assembly or Covenant (start_faction), each asked once more
	"imre_choice": {"who": "imre", "lines": [
		{"text": "One last thing before we go. I need to register you somewhere. A pilot without papers gets nowhere in the Cluster."},
		{"text": "I can sign you in with the Assembly, or with the Covenant. Where you start is up to you.",
			"answers": [["The Assembly.", 2, [], "The Assembly. A place where everyone has a say. After three hundred years, I'd like to have one too.", {"gold": true}],
				["The Covenant.", 3, [], "The Covenant. They want to go back to Earth. So do I, in a way.", {"gold": true}],
				["Tell me about them again.", 4, [], "Tell me about them again. Both of them."]]},
		{"text": "The Assembly, then. Are you sure? This decides where your story in the Cluster begins.",
			"answers": [["\"I'm sure.\"", 6, ["start_faction", "assembly"], "I'm sure. Sign me in with the Assembly.", {"gold": true}],
				["\"Let me think again.\"", 1]]},
		{"text": "The Covenant, then. Are you sure? This decides where your story in the Cluster begins.",
			"answers": [["\"I'm sure.\"", 7, ["start_faction", "covenant"], "I'm sure. Sign me in with the Covenant.", {"gold": true}],
				["\"Let me think again.\"", 1]]},
		{"text": "The Assembly: every citizen votes on every law, over the gate network. Slow to decide, hard to fool. Traders, colonists, station crews. They stopped waiting for Earth a long time ago."},
		{"text": "The Covenant of Return: a faith and a state at once. They believe humanity is meant to go back to Earth. Proud, strict, very good at war. And very curious about someone like you.", "next": 1},
		{"text": "The Assembly it is. They'll grumble about the paperwork, and then they'll vote you in. Get aboard, we leave within the hour.", "next": -1},
		{"text": "The Covenant it is. They'll want to hear everything about Earth, so get some sleep on the way. Get aboard, we leave within the hour.", "next": -1},
	]},
	# package 59, part 3 (Luz): the naturalisation – no flight record, a million more, nothing carries over
	"citizen_assembly": {"who": "clerk_asm", "lines": [
		{"text": "Next. Name, origin, last registered port."},
		{"who": "imre", "text": "This is the pilot I wrote to you about. Citizenship and a pilot licence, as agreed."},
		{"text": "Citizenship, fine. We vote residents in by the hundred every week."},
		{"text": "But a pilot licence? There's no flight record. No academy. No registered hours. According to this form, the applicant was born three hundred and forty years ago."},
		{"who": "you", "text": "I've aged well."},
		{"text": "Licences are earned here. Every class, every permit. That's the law, and forty million people voted for it."},
		{"who": "imre", "text": "And our arrangement?"},
		{"text": "Covered a resident's card. Not this. This costs another million. On top."},
		{"who": "imre", "text": "Done."},
		{"text": "...You're serious. If anyone audits this, I'm fired. I'll be fired, and then they'll hold a vote on whether to fire me again."},
		{"text": "Fine. But I can't carry anything over. Whatever ratings you held, wherever you held them, they're void. You get the basic licence, like everyone else, and you earn the rest.",
			"answers": [["\"Three hundred years of experience. Gone.\"", 11, [], "Three hundred years of flying experience, wiped out by a form. Wonderful. Truly, the future is everything I hoped for."],
				["\"Do I at least keep my name?\"", 11, [], "Do I at least get to keep my name, or does that cost extra too?"]]},
		{"text": "Don't push it."},
		{"text": "One basic pilot licence. And the starter grant every new pilot gets: one Dragonfly. Used. Don't scratch it, for the first year it still belongs to the Assembly.", "next": -1},
	]},
	"citizen_assembly_end": {"who": "clerk_asm", "lines": [
		{"text": "Welcome to the Cluster Assembly, citizen. Next!", "next": -1},
	]},
	"citizen_covenant": {"who": "registrar_cov", "lines": [
		{"text": "Step forward. Name, origin, and the road that brought you here."},
		{"who": "imre", "text": "This is the pilot I wrote to you about. Admission to the Covenant and a pilot licence, as agreed."},
		{"text": "Admission can be granted. The Covenant turns away no one who seeks the road home."},
		{"text": "But a licence to fly? There is no record. No oath of the helm. No hours under a Covenant flag. This form says the applicant was born on Earth."},
		{"who": "you", "text": "It's a long story."},
		{"text": "Licences are granted by the Chancery, seal by seal. That is the Hierarch's law. It does not bend."},
		{"who": "imre", "text": "And our arrangement?"},
		{"text": "Covered a pilgrim's papers. Not this. This requires a further donation. One million."},
		{"who": "imre", "text": "Done."},
		{"text": "...Keep your voice down. If the Wardens hear of this, I won't be dismissed. I'll be lynched!"},
		{"text": "Very well. But nothing carries over. Whatever you were allowed to fly before, the Covenant does not know it. You receive the first seal, like every novice, and you earn the rest.",
			"answers": [["\"The road leads home. Mine starts at the bottom.\"", 11, [], "The road leads home, they say. Good to know mine starts at the very bottom of it."],
				["\"Is there a seal for patience?\"", 11, [], "Is there a seal for patience? Because I think I've just earned that one."]]},
		{"text": "Mind your tongue. There are a dozen soldiers in this room."},
		{"text": "One pilot licence, first seal. And what the Covenant grants every new pilot: one Dragonfly. She is old. Treat her as a gift.", "next": -1},
	]},
	"citizen_covenant_end": {"who": "registrar_cov", "lines": [
		{"text": "The road leads home. Walk it well. Next!", "next": -1},
	]},
	# a little later, in the bar of your first station: Rook stays for now; what you plan decides the module you get
	"rook_plan": {"who": "rook", "lines": [
		{"text": "So that's it. You're official now. Licence and everything."},
		{"text": "I'm staying here for a while. Look around, see who's hiring. Someone always needs a gunner."},
		{"text": "I'll call you when I find something worth both our time. Don't change your frequency."},
		{"text": "What about you? What's the plan?",
			"answers": [["\"I'll do some mining.\"", 4, ["start_job", "mining"], "I'll do some mining. Honest work, and rocks don't shoot back."],
				["\"I'll keep dealing with pirates.\"", 5, ["start_job", "pirates"], "I'll keep dealing with pirates. Seems to be the one thing I'm good at."],
				["\"Maybe something scientific.\"", 6, ["start_job", "science"], "Maybe something scientific. There's a whole cluster out there nobody has shown me yet."]]},
		{"text": "Rocks. Sure. Wake me when it gets interesting.", "next": 7},
		{"text": "That's the pilot I know.", "next": 7},
		{"text": "You? Science? Now I've heard everything.", "next": 7},
		{"text": "Here. From Ossa, for the day you had a ship of your own again. Don't tell Ossa I handed it over this early. It's in your storage.", "next": -1},
	]},
	# the next morning: the ship computer's hologram – the open game begins
	"free_play": {"who": "ship_ai", "lines": [
		{"text": "Good morning, pilot. Registration complete. You are a licensed pilot of the {start_faction_name}."},
		{"text": "From here on, no one tells you where to fly. Mine, trade, hunt, explore. Earn new licences, find new ships, make friends and enemies."},
		{"text": "Your story in the Cluster is yours to write. The journal keeps track of what you find along the way: {journal}."},
		{"text": "Good luck out there.",
			"answers": [["Begin.", -1, ["intro_done", true], "", {"gold": true}]]},
	]},
	# package 61 (Luz): Centauria – Luz on the street, the first hello (the city and the bar come later)
	"luz_meet": {"who": "luz", "lines": [
		{"text": "You must be Rook's pilot. The one who fell out of the Veil. I'm Luz."},
		{"text": "Welcome to the Static Feedback. And to Centauria: the biggest city in the Rim, and the only one worth the trip.",
			"answers": [["\"Rook says there's work here.\"", 2, [], "Rook says there's work here. More than I can handle, apparently."],
				["\"Loud place.\"", 3, [], "Loud place you've got here. I like it."]]},
		{"text": "There will be. And plenty of ways to spend what it pays.", "next": 4},
		{"text": "It gets louder. The band comes on after dark.", "next": 4},
		{"text": "Right now the city is mostly promises. The casino's still painting its tables, the arena's still sweeping up. Give it time."},
		{"text": "Until then: the first one's on the house. Sit anywhere. Mind the two in the corner, they bite.", "next": -1},
	]},
	"luz_again": {"who": "luz", "lines": [
		{"text": "Back again? Good. The band plays after dark, the beer is cold all day. The rest of the city is still being built.", "next": -1},
	]},
	# package 61b (Luz): Ratte and Kraut, for now only a few words (the story comes later)
	"ratte_talk": {"who": "ratte", "lines": [
		{"text": "Psst. New face. You need something, you ask Ratte. Parts, papers, a door that was locked yesterday."},
		{"text": "Not today, though. Today Ratte is drinking. Come back when the city is awake.", "next": -1},
	]},
	"kraut_talk": {"who": "kraut", "lines": [
		{"text": "Hm."},
		{"text": "Sit somewhere else.", "next": -1},
	]},
	"dan_wait59": {"who": "dan", "lines": [
		{"text": "Imre doesn't bite. Talk to Imre when you're ready to go. Or have a coffee first, the machine's still warm.", "next": -1},
	]},
	"dan_busy": {"who": "dan", "lines": [
		{"text": "Don't keep Ossa waiting. Brine's the blue one. I'll call you if I need you.", "next": -1},
	]},
	"ossa_meet": {"who": "ossa", "lines": [
		{"text": "You'll be Dan's new pilot. The one Dan fished out of the Veil.",
			"answers": [["\"Word gets around.\"", 1, [], "Word travels fast around here, it seems."],
				["\"And you're Ossa Kell.\"", 7, [], "And you must be Ossa Kell. Dan sends his regards."]]},
		{"text": "Beyond is small. Three systems, one bar worth the name and a lot of wrecks. Everybody knows everything."},
		{"text": "Here's the job. My two haulers are taking on Dan's scrap at the store. They go through the gate to the Driftwood Waystation. You fly with them and keep the pirates off.",
			"answers": [["\"How bad are the pirates?\"", 3, [], "How bad are we talking? Dan said you lost two haulers this year."],
				["\"What does it pay?\"", 4, [], "And what's in it for me?"]]},
		{"text": "Bad enough. They don't wait at the gates. They pull you out of warp halfway and swarm you. Two or three of them, old fighters, cheap guns, no patience.", "next": 4},
		{"text": "Three thousand when my haulers dock in Driftwood. Not a credit before. Dan says you're good for it.", "next": 5},
		{"text": "My lead hauler waits outside Dan's store, marked green. Come alongside, or select her and follow, and we set off. Stay close in warp: if they pull us out, you come out with us.",
			"answers": [["\"Let's go.\"", 6, ["w58_ossa", true], "Alright. I'll meet your haulers at Dan's store. Let's get your cargo to Driftwood.", {"gold": true}]]},
		{"text": "Good. I fly the lead myself, so you'll hear from me. Don't be late.", "next": -1},
		# 7 – (Luz) her own answer when you name her
		{"text": "That's me. Owner, captain and the only one still fool enough to fly for Kell Freight. Dan's regards usually come with a bill, so let's hear what Dan's sent me.", "next": 2},
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
		{"text": "Ha! No papers, no ship, no record? Try Dan. Dan takes in strays."},
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
			{"id": "bar", "title": "Dan in the bar", "text": "Dan asked you to come up to the bar once you're fit. Take the turbolift. Dan's at the window.",
				"goals": [{"id": "talk", "kind": "talk", "dialogue": "intro_dan_bar", "label": "talk to Dan in the bar"}]},
			{"id": "hangar", "title": "Old Betty", "text": "Dan's ready for the flight training. Take the turbolift down to the hangar. Old Betty's stairs start it. No rush: have a drink, or a round of pool.",
				"goals": [{"id": "go", "kind": "flag", "flag": "tut_go", "label": "Old Betty's stairs in the hangar"}]},
			{"id": "training", "title": "The flight training", "text": "Out in a wreck field with one of Dan's drones. See Flight training.",
				"goals": [{"id": "home", "kind": "flag", "flag": "tut_home", "label": "finish the flight training"}]},
			{"id": "word", "title": "Talk to Dan", "text": "Dan has a few more things to talk over with you, in the bar.",
				"goals": [{"id": "talk", "kind": "flag", "flag": "prologue_bar", "label": "talk to Dan in the bar"}],
				"on_done": [{"do": "start", "id": "ticket"}]},
		]},
	# package 56, sequence 6 (Luz): Dan's deal – work for him, earn your passage
	"ticket": {"title": "A Ticket to the Cluster", "kind": "story", "chapter": "Chapter 1 · Beyond",
		"desc": "No ship, no licence, and stuck in Beyond. Dan knows someone who could get you to the Cluster, for a price. His deal: give him a hand and earn your ticket.",
		"steps": [
			{"id": "deal", "title": "Dan's deal", "text": "Dan offered you a ship, gear and a few jobs (about three years of them) to earn your ticket to the Cluster. Talk to Dan in the bar once you've made up your mind.",
				"goals": [{"id": "yes", "kind": "flag", "flag": "dan_deal_yes", "label": "take Dan's deal"}],
				"on_done": [{"do": "start", "id": "darling"}]},                # Luz: "Working for Dan" in the journal at once
			{"id": "work", "title": "Working for Dan", "text": "About three years of work for Dan, then a friend of Dan's takes you to the Cluster. The jobs come one by one; each pays a little.",
				"goals": [{"id": "paid", "kind": "flag", "flag": "ticket_paid", "label": "earn your ticket"}]},
			# package 59 (Luz): the way to the Cluster
			{"id": "way", "title": "The way to the Cluster", "text": "The morning after the party. Dan called: come up to the bar, he has something for you.",
				"goals": [{"id": "met", "kind": "flag", "flag": "w59_met", "label": "go up to the bar"}]},
			{"id": "ready", "title": "Ready when you are", "text": "Dr. Imre Halden of the Meridian Directorate can take you to the Cluster aboard the Threshold, parked outside Dan's station. There is no hurry: talk to Imre in the bar when you are ready to leave.",
				"goals": [{"id": "go", "kind": "flag", "flag": "w59_go", "label": "talk to Imre when you're ready"}]},
			{"id": "choice", "title": "Assembly or Covenant", "text": "Goodbyes in Dan's hangar. Imre can register you with the Assembly or with the Covenant: where you start in the Cluster is up to you.",
				"goals": [{"id": "pick", "kind": "flag", "flag": "start_faction", "label": "choose where you start"}]},
			{"id": "aboard", "title": "Aboard the Threshold", "text": "Everything stays in Beyond but the suit Ossa gave you. Imre's Threshold opens its black hole and takes you through the Veil.",
				"goals": [{"id": "left", "kind": "flag", "flag": "w59_left", "label": "the jump through the Veil"}]},
		]},
	# package 59, part 3 (Luz): the last scene of the intro – the naturalisation, the bar, the first morning
	"citizen": {"title": "A New Start", "kind": "story", "chapter": "Chapter 2 · The Cluster",
		"desc": "Through the Veil and into the Cluster, with nothing but the suit you wear. Imre will get you papers, the rest is up to you.",
		"steps": [
			{"id": "licence", "title": "Papers", "text": "Imre takes you to the registry. A citizen needs papers, and a pilot needs a licence.",
				"goals": [{"id": "lic", "kind": "flag", "flag": "cit_licence", "label": "get your pilot licence"}]},
			{"id": "plan", "title": "A drink with Rook", "text": "You have a licence and a Dragonfly. Rook is waiting in the bar.",
				"goals": [{"id": "job", "kind": "flag", "flag": "start_job", "label": "tell Rook what you plan to do"}]},
			{"id": "free", "title": "The first morning", "text": "A room of your own, a ship of your own, and a whole cluster outside.",
				"goals": [{"id": "done", "kind": "flag", "flag": "intro_done", "label": "wake up in the Cluster"}]},
		]},
	# package 61 (Luz): Rook's call at pilot level 5 – the way to Fern
	"fern": {"title": "A Place Called Fern", "kind": "story", "chapter": "Chapter 2 · The Cluster",
		"desc": "Rook heard of a place out in the Rim with more work than a pilot can handle, and more ways to lose the money again: Fern, and its city Centauria.",
		"steps": [
			{"id": "go", "title": "Out to the Rim", "text": "Fern lies in the Rim and belongs to no one. Find it on the galaxy map and fly there.",
				"goals": [{"id": "arrive", "kind": "flag", "flag": "fern_arrived", "label": "fly to Fern"}]},
			{"id": "land", "title": "Centauria", "text": "The city lies on Pelagia, the ocean world that circles Lapis, the blue giant with the rings. Descend and land in Centauria.",
				"goals": [{"id": "land", "kind": "flag", "flag": "fern_landed", "label": "land in Centauria on Pelagia"}]},
			{"id": "luz", "title": "Rook's contact", "text": "Luz knows the city and owes Rook a favour. Take Line A from Centauria Central to the Commercial District and go through the gate in the south of the plaza into the Back Alleys. Luz runs the Static Feedback: down the stairs at the east end of the street.",
				"goals": [{"id": "luz", "kind": "flag", "flag": "fern_luz", "label": "find Luz in the Static Feedback, in the Back Alleys"}]},
		]},
	# package 58, part 1 (Luz): Little Darling – Dan shows you the station window and the Outfitter (a guided tour),
	# you fit the lasers he left in storage and buy a drone with his advance. The flags come from
	# scripts/ground/dan_work.gd; the wreck field follows in part 2.
	"darling": {"title": "Working for Dan", "kind": "story", "chapter": "Chapter 1 · Working for Dan",
		"desc": "Dan gives you a ship and the first jobs. Get to know Little Darling, kit her out and earn your keep.",
		"steps": [
			{"id": "board", "title": "Little Darling", "text": "Board the ship Dan lends you: Little Darling, a small KHI miner in Dan's rust, waits in the hangar. She has some gear already, but a few things still need fitting. Climb aboard, Dan will explain.",
				"goals": [{"id": "board", "kind": "flag", "flag": "ticket_ship", "label": "board the ship Dan gives you"}]},
			{"id": "station", "title": "The station window", "text": "Dan walks you through the station window: you, the news, your ship and her services, the station and its services. Then on to the Outfitter.",
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
			{"id": "rest", "title": "A room upstairs", "text": "Dan put you in one of the station's rooms, on the house. Take the lift up to the Quarters, find your room (its lamp is green) and sleep in your bed.",
				"goals": [{"id": "slept", "kind": "flag", "flag": "w58_slept", "label": "sleep in your room in Dan's quarters"}]},
			# package 58, part 3 (Luz): Ossa Kell on Brine, the escort to Driftwood, Dan's call, home
			{"id": "next", "title": "More work", "text": "Dan has a few people who need things moved around Beyond. Rest a little, then see Dan in the bar.",
				"goals": [{"id": "job", "kind": "flag", "flag": "w58_job", "label": "talk to Dan in the bar"}]},
			{"id": "brine", "title": "Upper Brine", "text": "Dan's client is Ossa Kell of Kell Freight. Fly to Brine, descend and land in Upper Brine: Ossa meets you at your ship in the city's hangar. Dan lent you a better laser and armour plating for the job.",
				"goals": [{"id": "ossa", "kind": "flag", "flag": "w58_ossa", "label": "meet Ossa Kell in Upper Brine"}]},
			{"id": "escort", "title": "Kell Freight", "text": "Ossa's two haulers take on Dan's scrap at the store. Meet them outside, follow the lead hauler, and see them safely through the gate to the Driftwood Waystation. Pirates like to pull convoys out of warp: stay close.",
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
			{"id": "maul", "title": "The Maul", "text": "Dan has talked to Ossa, who gives you the Maul, a patched-up gunboat. Fly to Brine, land in Upper Brine and find Ossa in the shopping street.",
				"goals": [{"id": "maul", "kind": "flag", "flag": "w58_maul", "label": "pick up the Maul from Ossa in Upper Brine"}]},
			{"id": "contact", "title": "A friend in Driftwood", "text": "Dan's friend Silas Marr might know how to track the pirates down. Silas is waiting in the diner of the Driftwood Waystation.",
				"goals": [{"id": "contact", "kind": "flag", "flag": "w58_contact", "label": "meet Silas Marr in the Driftwood Waystation's diner"}]},
			# package 58, part 5 (Luz): the Listener – escort Silas's Bastion, defend it while it listens
			{"id": "follow", "title": "The Stubborn Hope", "text": "Silas takes the Bastion, the Stubborn Hope, out to a quiet asteroid field in Driftwood. Follow the Hope there.",
				"goals": [{"id": "follow", "kind": "flag", "flag": "w58_atlisten", "label": "follow the Stubborn Hope to the asteroid field"}]},
			{"id": "listen", "title": "The Listener", "text": "Silas has unfolded the Listener. Every pirate in range has heard it: keep them off the Stubborn Hope until the sweep is done.",
				"goals": [{"id": "listen", "kind": "flag", "flag": "w58_listened", "label": "defend the Stubborn Hope until the sweep is done"}],
				"on_done": [{"do": "credits", "n": 3000}]},
			# package 58, part 6 (Luz): the preparation
			{"id": "report", "title": "Back to Dan", "text": "The Listener heard the pirates, but Silas thinks the readings are far too clean and wants to look at them first. Fly back to Dan's Dusty Duty Store and find Dan in the bar.",
				"goals": [{"id": "report", "kind": "flag", "flag": "w58_briefing", "label": "ask Dan about the pirate base in the bar"}]},
			{"id": "gear", "title": "Ossa's gear", "text": "The pirates talk through a relay station on the ground, and someone has to get in there. Ossa lends you gear for it, and Rook comes along.",
				"goals": [{"id": "gear", "kind": "flag", "flag": "w58_gear", "label": "look over the gear Ossa lent you (Pilot window, Gear)"}]},
			{"id": "sim", "title": "The simulation", "text": "Three hundred years out of practice: Rook runs a combat simulation in Dan's hangar to bring you up to date.",
				"goals": [{"id": "sim", "kind": "flag", "flag": "w58_sim", "label": "talk to Rook in Dan's hangar and finish the simulation"}]},
			# package 58, part 7 (Luz): the relay station
			{"id": "relay", "title": "The relay", "text": "The pirates' relay station stands on a cold world in Hollow. Land a good way off, get in with Rook, pull the coordinates of their base from the data core at the bottom, then overload the transmitter.",
				"goals": [{"id": "coords", "kind": "flag", "flag": "w58_coords", "label": "pull the coordinates from their data core"},
					{"id": "overload", "kind": "flag", "flag": "w58_overload", "label": "overload the transmitter"}]},
			{"id": "escape", "title": "Get out!", "text": "The transmitter is going to blow and the whole nest is awake. Back to the landing drone and up.",
				"goals": [{"id": "escape", "kind": "flag", "flag": "w58_relay", "label": "get back to the drone and take off"}],
				"on_done": [{"do": "credits", "n": 2500}]},
			# package 58, part 8 (Luz): the strike
			{"id": "rendezvous", "title": "The rendezvous", "text": "Dan, Ossa and Silas wait for you at a spot in Hollow, far from the pirates' station. Meet them there: from there you strike together, while the pirates are still deaf.",
				"goals": [{"id": "rv", "kind": "flag", "flag": "w58_rv", "label": "meet Dan, Ossa and Silas at the rendezvous in Hollow"}]},
			{"id": "strike", "title": "The strike", "text": "The Red Talon Roost: four gun platforms, two hangars that keep sending fighters, and a reactor under heavy plating. Every hit counts. Once the plating gives, hit the core with everything you have.",
				"goals": [{"id": "strike", "kind": "flag", "flag": "w58_base_down", "label": "destroy the Red Talon Roost"}],
				"on_done": [{"do": "credits", "n": 5000}]},
			{"id": "drinks", "title": "Drinks at Dan's", "text": "The Roost is gone. Dan promised a whiskey from Earth.",
				"goals": [{"id": "drinks", "kind": "flag", "flag": "w58_drinks", "label": "celebrate in Dan's bar"}]},
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
			{"id": "home", "title": "Home", "text": "Dan takes you back to the station in Old Betty. Everything else is explained in the codex, in the Pilot menu.",
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
