extends RefCounted
## Package 33: wingmen – pilots with their own ship who fly with you for a contract (mercenaries for ground combat
## follow in part 7 with the same mechanics). Hired at The Bar: a price up front for the time, plus a share of the
## income (sales, bounties, contract rewards) – much more than crew. Real characters: two skills, two traits that
## colour how they fly, and a ship with a real loadout.

const LEVELS := ["F", "D", "C", "B", "A"]
const LEVEL_NAMES := {"F": "Rookie", "D": "Trained", "C": "Seasoned", "B": "Veteran", "A": "Ace"}
## share of the income while the contract runs
const SHARE := {"F": 0.02, "D": 0.04, "C": 0.07, "B": 0.12, "A": 0.20}
## price for 30 minutes of play
const PRICE := {"F": 3000, "D": 8000, "C": 20000, "B": 50000, "A": 120000}
## contract lengths (minutes of play) and their price factor
const DURATIONS := [[30, 1.0], [60, 1.8], [120, 3.2]]
## Piloting and Gunnery levels by level (+1 % speed / damage each)
const SKILLS := {"F": [1, 2], "D": [2, 4], "C": [4, 6], "B": [6, 8], "A": [8, 10]}
## the ships they bring (standard fits)
const SHIPS := {"F": ["hornet", "for_acolyte"], "D": ["hornet", "hdy_talon", "for_acolyte"], "C": ["warden", "hdy_maul", "for_templar"],
	"B": ["hdy_maul", "for_templar", "hdy_goliath"], "A": ["hdy_goliath", "bastion"]}
const BAR_WEIGHTS := {"F": 15.0, "D": 35.0, "C": 30.0, "B": 14.0, "A": 6.0}
const BAR_PILOTS := [1, 3]
const MAX_BASE := 1                  # wingmen at once without Leadership
const MAX := 2                       # with Leadership 3 or more
const LEADERSHIP_FOR_TWO := 3
const LEASH := 9000.0                # km from the ship they fly with – they do not chase further

## Traits: two per wingman (fixed), they colour the behaviour
const TRAITS := {
	"brave": {"name": "Daredevil", "text": "Chases enemies further and keeps fighting longer."},
	"cautious": {"name": "Cautious", "text": "Falls back into formation when the shield drops below half."},
	"disciplined": {"name": "Disciplined", "text": "Sticks exactly to the order – never strays from the target you gave."},
	"hothead": {"name": "Hothead", "text": "Now and then opens fire on its own even when told to be defensive."},
	"sharpshooter": {"name": "Sharpshooter", "text": "Keeps its distance and fights at long range."},
	"loyal": {"name": "Loyal", "text": "Goes first for whoever attacks you."},
	"greedy": {"name": "Greedy", "text": "Salvages wrecks nearby between fights – the loot goes into your hold."},
}
const TRAIT_PAIRS_FORBIDDEN := [["brave", "cautious"], ["disciplined", "hothead"]]
const STANCES := {"aggressive": "Aggressive", "defensive": "Defensive", "passive": "Passive"}


static func level_color(l: String) -> Color:
	return {"F": Color(0.6, 0.6, 0.62), "D": Color(0.75, 0.85, 0.95), "C": Color(0.45, 1.0, 0.55), "B": Color(0.4, 0.7, 1.0), "A": Color(1.0, 0.75, 0.3)}.get(l, Color.WHITE)
