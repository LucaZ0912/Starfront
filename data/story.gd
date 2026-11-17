extends RefCounted
## Package 55 (Luz): the story's data – missions (story and side missions) made of steps, each with goals and what
## happens when it starts and when it is done; the characters who speak (with their portraits), the dialogues and
## their answers (which set story flags), the tips and the secrets. The story itself comes with packages 56–59; for
## now only a test mission, started from the debug menu.
##
## A mission: {title, kind: "story" | "side", chapter, desc, debug_only, steps: [step, …]}
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
## Text may name keys: {key:action_id} – shown as the key (or the controller's button) bound to it.

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
		{"text": "Ah – finally, you're awake. We thought that was it for you. Your suit had at least as many holes as your ship."},
		{"text": "I'm Dan – Dan T. Rogue. I run this little operation here. Nice to meet you."},
		{"text": "You should rest a bit more. When you're fit, come see me in the bar. Just take the turbolift."},
	]},
	"intro_doc": {"who": "doc", "lines": [
		{"text": "Careful! Yes – just like that. That looks good already. You should be able to move freely around the station. But take it easy for now, okay?",
			"answers": [["\"Thanks for patching me up, Doc.\"", -1, []]]},
	]},
	"intro_dan_bar": {"who": "dan", "lines": [
		{"text": "Ah – you're looking fit again!",
			"answers": [["\"Thanks for saving me.\"", 1, [], "Thank you for saving me. I really thought that was it."]]},
		{"text": "Ah, don't mention it. Your ship wasn't so lucky, I'm afraid. But tell me – how did you come by a ship like that?",
			"answers": [["\"It was issued to me.\"", 2, [], "What do you mean? The UN issued it to me. Who else?"]]},
		{"text": "UN? As in United Nations? As in the United Nations of Earth?"},
		{"who": "you", "text": "Yes…?"},
		{"text": "Oh. Uhm… what year do you think it is?"},
		{"who": "you", "text": "Around 12,600 HE… I don't know exactly. I don't know how long I was out."},
		{"text": "It's 12,900 HE. I think a hyperdrive failure threw you almost three hundred years into the future."},
		{"who": "you", "text": "…"},
		{"text": "Okay – that's a lot to take in. How about we take your mind off it? I had a look at your cockpit. Seems not that much has changed – but your pilot licence expired a while ago. Want to brush up on the basics?",
			"answers": [["\"Yes, that'd be good.\"  (flight tutorial)", -1, ["flight_tutorial", true], "Yes, that'd be good – show me what's new."],
				["\"No, I'll manage.\"  (skip the tutorial)", -1, ["flight_tutorial", false], "No, I'll manage. Flying is flying."]]},
	]},
	"test_hello": {"who": "dan", "lines": [
		{"text": "So the debug menu sent you. Good – this is a test of the story's framework: dialogues, radio calls, tips, goals and the journal.",
			"answers": [["\"What do I do?\"", 1, []], ["\"I know how this works.\"", 2, ["test_confident", true]]]},
		{"text": "Fly to the station I mark for you, then dock there. I'll call you on the way – and the journal (Pilot window) keeps it all.",
			"answers": [["\"On my way.\"", -1, []]]},
		{"text": "Then show me. The station's marked – dock there.",
			"answers": [["\"On my way.\"", -1, []]]},
	]},
}

## Tips: shown once (unless switched off), kept in the journal under Tips.
const TIPS := {
	"tip_objective": {"title": "Goals and the marker", "text": "The mission you track shows its next goals over your ship's panel. In space a gold diamond marks the target – an arrow at the edge when it is off the screen. The journal ({key:journal}) has all your missions."},
	"tip_fire_groups": {"title": "Fire groups", "text": "Your modules sit in fire groups – the tiles at the bottom. Lock a target, then press {key:module_1} to switch group 1 on. Set the groups in Ship → Modules → Fire groups."},
	"tip_docking": {"title": "Docking", "text": "Select a station, then press {key:cmd_dock} – your ship flies in and docks by itself."},
}

## Secrets: found ones are listed in the journal; the others show as "???" so you know there is more.
const SECRETS := {
	"test_secret": {"title": "The test framework", "text": "You finished the test mission of package 55 – the framework works.", "debug_only": true},
}

## The missions.
const MISSIONS := {
	"debug_test": {"title": "Framework test", "kind": "story", "chapter": "Debug · package 55", "debug_only": true,
		"desc": "A short test of the story's framework: a dialogue, a radio call, a tip, a goal with its marker, docking. Started from the debug menu.",
		"steps": [
			{"id": "hello", "title": "Talk to Dan", "text": "Dan wants a word before you start.",
				"goals": [{"id": "talk", "kind": "talk", "dialogue": "test_hello", "label": "talk to Dan"}],
				"on_start": [{"do": "dialogue", "id": "test_hello"}]},
			{"id": "fly", "title": "Fly to the station", "text": "Dan marked a station for you – not the one you are at. Fly there.",
				"goals": [{"id": "near", "kind": "near", "target": "@target", "km": 4000.0, "label": "get within 4,000 km"}],
				"on_start": [{"do": "target", "what": "next_station"}, {"do": "radio", "who": "dan", "text": "See the gold diamond? That's where you're going. Fly in – no rush."},
					{"do": "tip", "id": "tip_objective"}]},
			{"id": "dock", "title": "Dock at the station", "text": "Close enough – now dock.",
				"goals": [{"id": "dock", "kind": "dock", "target": "@target", "label": "dock"}],
				"on_start": [{"do": "radio", "who": "dan", "text": "Now dock. Select the station and let the ship do the rest."}, {"do": "tip", "id": "tip_docking"}],
				"on_done": [{"do": "credits", "n": 1000}, {"do": "secret", "id": "test_secret"},
					{"do": "radio", "who": "dan", "text": "Docked. That's the test done – a thousand credits for your trouble."}]},
		]},
}
