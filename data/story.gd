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
	"dan": {"name": "Dan T. Rogue", "sub": "Salvage master · Beyond Yard", "col": Color(1.0, 0.65, 0.3), "seed": 7731,
		"look": {"beard": 2, "scar": 1}},
}

## Dialogues: lines one after the other; a line's answers lead on ("next": the line's index, -1: the end) and may set
## a story flag ("flag": [name, value]).
const DIALOGUES := {
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
