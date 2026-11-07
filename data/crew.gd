extends RefCounted
## Package 31: the crew. Ships from M upwards carry crew in slots; every hull says how many slots it has, which
## profession each slot takes and which of them must be filled before the ship may undock.
##
## A crew member: name (from big lists of first and last names), a random portrait (PilotArt look), a profession
## (= the slot role), a quality F–A (later S, S+) and ONE rolled bonus of that profession – which bonus and how
## high is rolled inside the frame of the quality. Very rarely a perk (fixed for life). They learn slowly from
## the work of their profession; a step up rolls an improvement on top (it may go beyond the frame).
## Crew costs a small share of income (sales, bounties, contract rewards) – only the crew of the active ship.

const QUALITIES := ["F", "D", "C", "B", "A"]
const QUALITY_NAMES := {"F": "Rookie", "D": "Trained", "C": "Seasoned", "B": "Veteran", "A": "Elite"}
const QUALITY_COLORS := {"F": Color(0.6, 0.6, 0.62), "D": Color(0.75, 0.85, 0.95), "C": Color(0.45, 1.0, 0.55),
	"B": Color(0.4, 0.7, 1.0), "A": Color(0.85, 0.5, 1.0)}
## bonus frame in per cent when hired
const FRAME := {"F": [1.0, 2.0], "D": [2.0, 4.0], "C": [4.0, 6.0], "B": [6.0, 9.0], "A": [9.0, 12.0]}
## a step up: the improvement rolled on top (percentage points; may go beyond the frame)
const STEP_UP := {"D": [1.0, 2.0], "C": [1.5, 3.0], "B": [2.0, 3.5], "A": [2.5, 4.0]}
## share of income per crew member (fraction)
const SHARE := {"F": 0.0002, "D": 0.0005, "C": 0.001, "B": 0.0015, "A": 0.0025}
## experience to the next quality (about: F→D 2 h, D→C 5 h, C→B 12 h, B→A 30 h of the right work)
const XP_NEED := {"F": 200.0, "D": 500.0, "C": 1200.0, "B": 3000.0}
## hiring price at the bar (± 30 %)
const PRICE := {"F": 1500, "D": 5000, "C": 20000, "B": 75000, "A": 250000}
## how often each quality turns up at a bar
const BAR_WEIGHTS := {"F": 12.0, "D": 40.0, "C": 30.0, "B": 13.0, "A": 5.0}

## role: name, bonuses [id, label, stat], short text what it learns from
const ROLES := {
	"copilot": {"name": "Co-Pilot", "icon": "engine", "learns": "warps and jumps",
		"bonuses": [["speed", "Speed"], ["turn", "Agility"], ["align", "Warp alignment"], ["warp", "Warp speed"], ["accel", "Acceleration"]]},
	"gunner": {"name": "Gunner", "icon": "w_kinetic", "learns": "destroying pirates",
		"bonuses": [["dmg_optical", "Optical damage"], ["dmg_kinetic", "Kinetic damage"], ["dmg_explosive", "Explosive damage"], ["w_range", "Weapon range"], ["rof", "Rate of fire"]]},
	"engineer": {"name": "Engineer", "icon": "reactor", "learns": "taking hits and long flights",
		"bonuses": [["power", "Power output"], ["cap", "Capacitor recharge"], ["shield_regen", "Shield regeneration"], ["downtime", "Shorter shield downtime"], ["armor", "Armour"]]},
	"science": {"name": "Science Officer", "icon": "t_analyzer", "learns": "anomalies and scans",
		"bonuses": [["scan_range", "Scanner range"], ["survey", "Survey range"], ["sensor", "Sensor range"], ["scan_speed", "Scan speed"]]},
	"foreman": {"name": "Mining Foreman", "icon": "t_mining", "learns": "ore mined and refined",
		"bonuses": [["mining", "Mining rate"], ["ore_hold", "Ore hold"], ["refine", "Refinery yield"], ["drone_mining", "Drone mining"]]},
	"quartermaster": {"name": "Quartermaster", "icon": "o_cargo", "learns": "trading",
		"bonuses": [["cargo", "Cargo hold"], ["sell", "Sale prices"], ["fuel", "Fuel per jump"], ["share", "Lower crew share"]]},
	"drone_op": {"name": "Drone Operator", "icon": "drone", "learns": "drones at work",
		"bonuses": [["drone_damage", "Drone damage"], ["drone_range", "Drone range"], ["drone_speed", "Drone speed"], ["drone_hull", "Drone hull"]]},
}

## Very rare perks (fixed for life, any quality except F crew that come with a new ship).
## second_profession: also fits a second role, with a bonus of its own there.
const PERKS := {
	"second_profession": {"name": "Second Profession", "text": "Also serves in a second role, with its own bonus there.", "weight": 1.0},
	"lucky": {"name": "Lucky", "text": "Survives the loss of the ship almost always (package 31a).", "weight": 0.5},
	"quick_learner": {"name": "Quick Learner", "text": "Learns twice as fast.", "weight": 0.5},
	"loyal": {"name": "Loyal", "text": "Takes no share of the income.", "weight": 0.5},
	"old_hand": {"name": "Old Hand", "text": "Bonus +50 %.", "weight": 0.4},
	"medic": {"name": "Medic", "text": "The rest of the crew survives a ship loss more often (package 31a).", "weight": 0.4},
	"thrifty": {"name": "Thrifty", "text": "The whole crew of the ship takes half the share.", "weight": 0.35},
	"night_owl": {"name": "Night Owl", "text": "Bonus doubled in systems with low security (below 0.5).", "weight": 0.35},
}
const PERK_CHANCE := 0.04            # all perks together (second profession about 1 %)

## Crew slots of the hulls: [role, required]. S hulls carry no crew for now.
const SHIP_CREW := {
	"mule": [["copilot", true], ["quartermaster", false]],
	"freighter": [["copilot", true], ["quartermaster", false], ["engineer", false], ["quartermaster", false]],
	"drillhead": [["foreman", true], ["copilot", false], ["engineer", false]],
	"anaguma": [["foreman", true], ["copilot", false], ["engineer", false]],
	"warden": [["gunner", true], ["copilot", false], ["engineer", false]],
	"for_templar": [["gunner", true], ["copilot", false], ["engineer", false]],
	"hdy_maul": [["gunner", true], ["copilot", false], ["engineer", false]],
	"hdy_goliath": [["gunner", true], ["gunner", false], ["copilot", false], ["engineer", false]],
	"cfw_quirinus": [["drone_op", true], ["gunner", false], ["engineer", false]],
	"aur_boulevard": [["copilot", true], ["quartermaster", false], ["engineer", false]],
	"aur_opal": [["copilot", true], ["quartermaster", false], ["engineer", false]],
	"bastion": [["gunner", true], ["engineer", true], ["copilot", false], ["gunner", false], ["science", false], ["quartermaster", false]],
	"iwakudaki": [["foreman", true], ["engineer", true], ["foreman", false], ["copilot", false], ["quartermaster", false], ["drone_op", false]],
	"kanayama": [["foreman", true], ["engineer", true], ["quartermaster", true], ["foreman", false], ["foreman", false], ["engineer", false],
		["drone_op", false], ["drone_op", false], ["copilot", false], ["quartermaster", false]],
	"axa_threshold": [["science", true], ["engineer", true], ["copilot", false], ["science", false], ["gunner", false], ["quartermaster", false]],
	"for_cathedral": [["gunner", true], ["engineer", true], ["gunner", false], ["gunner", false], ["copilot", false], ["engineer", false],
		["science", false], ["quartermaster", false]],
	"cfw_concordia": [["drone_op", true], ["gunner", true], ["engineer", true], ["drone_op", false], ["drone_op", false], ["gunner", false],
		["copilot", false], ["engineer", false], ["science", false], ["quartermaster", false]],
	"hdy_citadel": [["drone_op", true], ["gunner", true], ["engineer", true], ["drone_op", false], ["gunner", false], ["gunner", false],
		["copilot", false], ["engineer", false], ["science", false], ["quartermaster", false]],
	"aur_empress": [["copilot", true], ["quartermaster", true], ["engineer", true], ["quartermaster", false], ["engineer", false],
		["copilot", false], ["science", false], ["drone_op", false], ["gunner", false], ["quartermaster", false]],
}

## Experience from the work (metric -> [[role, xp per unit, "drones" = only while drones are out]]), aimed at roughly
## 100 xp per hour of that work
const LEARN := {
	"warps": [["copilot", 3.0], ["engineer", 1.0]], "jumps": [["copilot", 6.0], ["engineer", 2.0]],
	"kills": [["gunner", 8.0], ["drone_op", 6.0, "drones"]], "damage_taken": [["engineer", 0.01]],
	"analysed": [["science", 15.0]], "scans": [["science", 4.0]], "exotic": [["science", 10.0]],
	"mined": [["foreman", 0.03], ["drone_op", 0.02, "drones"]], "refined_station": [["foreman", 0.01]],
	"turnover": [["quartermaster", 0.0005]],
}

## Which professions a bar offers more often, by station type
const BAR_BIAS := {
	"military": ["gunner", "gunner", "engineer", "drone_op"], "research": ["science", "science", "engineer"],
	"mining_colony": ["foreman", "foreman", "engineer"], "ice_refinery": ["foreman", "engineer"],
	"trade": ["quartermaster", "quartermaster", "copilot"], "agri": ["quartermaster", "copilot"],
	"industry": ["engineer", "foreman", "quartermaster"], "shipyard": ["engineer", "copilot", "drone_op"],
	"pirate_haven": ["gunner", "copilot", "drone_op"],
}
const BAR_SIZE := [4, 8]
const BAR_REFRESH := 1200.0          # seconds of play time

const FIRST_NAMES := [
	"Ada", "Aiko", "Alexei", "Amara", "Anders", "Anika", "Arjun", "Astrid", "Aurelio", "Ayasha", "Bao", "Beatriz", "Bjorn", "Bram",
	"Caius", "Calla", "Camila", "Chidi", "Chiara", "Cyrus", "Dagny", "Dalia", "Dante", "Darius", "Dmitri", "Doria", "Eamon", "Edda",
	"Elif", "Elio", "Emeka", "Enzo", "Esme", "Ezra", "Farah", "Felix", "Femi", "Fiora", "Freya", "Gael", "Gideon", "Greta", "Hana",
	"Hamid", "Hector", "Helga", "Hiro", "Ines", "Ingrid", "Ivo", "Imani", "Jael", "Jarek", "Jasper", "Jin", "Joaquin", "Juno", "Kai",
	"Kalinda", "Kasimir", "Kenji", "Kira", "Kofi", "Lale", "Lars", "Leilani", "Lena", "Lio", "Lorcan", "Luka", "Lumi", "Mael", "Maeve",
	"Malik", "Mara", "Marek", "Mei", "Mika", "Mirela", "Moana", "Nadia", "Naveen", "Nell", "Niko", "Nilufar", "Noor", "Oda", "Odile",
	"Olek", "Omar", "Orla", "Oskar", "Paz", "Pema", "Petra", "Priya", "Quill", "Rafe", "Ravi", "Rhea", "Rina", "Rocco", "Ronja",
	"Rui", "Saga", "Salome", "Sami", "Sanaa", "Selin", "Sergei", "Sigrun", "Sol", "Soren", "Sunniva", "Tahir", "Talia", "Tamsin",
	"Taro", "Tess", "Theo", "Thandiwe", "Tomas", "Uma", "Usha", "Vale", "Vera", "Viggo", "Vik", "Wren", "Xiadani", "Yara", "Yusuf",
	"Yuki", "Zaid", "Zara", "Zeno", "Zofia", "Abel", "Agathe", "Akira", "Alba", "Ambrose", "Anouk", "Aras", "Ari", "Basil", "Bea",
	"Benedek", "Bodhi", "Briony", "Cato", "Cleo", "Coral", "Corwin", "Dax", "Delphine", "Desmond", "Dorian", "Eira", "Elan", "Elsa",
	"Emre", "Eun-ji", "Fabian", "Faye", "Florin", "Gaia", "Gunnar", "Halvar", "Hedda", "Idris", "Ilse", "Isra", "Jovan", "Kael",
	"Kalani", "Karim", "Keiko", "Lazlo", "Leander", "Liv", "Lucan", "Lys", "Magnus", "Marisol", "Matteo", "Milan", "Mirai", "Nazira",
	"Nestor", "Nika", "Nyx", "Ottilie", "Pavel", "Pia", "Quentin", "Rasmus", "Remy", "Rosa", "Sabine", "Silas", "Stellan", "Svea",
	"Tarik", "Tilda", "Ulla", "Valentin", "Vesna", "Wolfe", "Xander", "Ylva", "Zuri", "Aleksandra", "Bruno", "Dunja", "Hakon",
	"Jolene", "Kwame", "Mateus", "Odin", "Suki", "Tiberius", "Yasmin", "Zhen", "Anouar", "Birgit", "Carmen", "Dov", "Esther",
]
const LAST_NAMES := [
	"Abara", "Achterberg", "Adeyemi", "Albescu", "Almeida", "Amundsen", "Anand", "Arkwright", "Asante", "Bakshi", "Balogun", "Barros",
	"Bauer", "Bellamy", "Bergström", "Bianchi", "Blackwood", "Bogdan", "Brandt", "Brennan", "Calder", "Carvalho", "Castellan", "Chen",
	"Cho", "Cortez", "Crane", "Dahl", "Dalca", "Dasgupta", "Dekker", "Delacroix", "Draven", "Dubois", "Duarte", "Eastwood", "Ekström",
	"Eliasson", "Faraday", "Fenwick", "Ferreira", "Fischer", "Flint", "Forde", "Fujimoto", "Galloway", "Garza", "Gerhardt", "Grant",
	"Gruber", "Haddad", "Halloran", "Hartmann", "Hayashi", "Hollis", "Holm", "Huang", "Ibarra", "Ishikawa", "Ivanova", "Jansen",
	"Jovanovic", "Kader", "Kaminski", "Kang", "Karlsson", "Kaur", "Keller", "Kimura", "Kovac", "Kowalczyk", "Krause", "Kuznetsov",
	"Lachance", "Lindqvist", "Lombardi", "Lund", "Macharia", "Madsen", "Marchetti", "Mbeki", "Mendez", "Meyer", "Molnar", "Moreau",
	"Moretti", "Nakamura", "Navarro", "Ndiaye", "Nguyen", "Novak", "Nyberg", "Obi", "Okafor", "Oliveira", "Olsen", "Orlov", "Ortega",
	"Osei", "Park", "Pereira", "Petrov", "Pham", "Quintero", "Rahman", "Ramos", "Rasku", "Reyes", "Richter", "Rinaldi", "Rocha",
	"Romanov", "Rossi", "Sato", "Schäfer", "Schmidt", "Serrano", "Shah", "Sharma", "Silva", "Sokolov", "Solberg", "Stavros", "Steele",
	"Strand", "Suzuki", "Szabo", "Takahashi", "Tanaka", "Tavares", "Thorne", "Torres", "Tran", "Udeh", "Ueda", "Vance", "Varga",
	"Vasquez", "Vogel", "Volkov", "Wagner", "Walcott", "Wang", "Weiss", "Winter", "Wolff", "Xu", "Yamada", "Yilmaz", "Young", "Zamora",
	"Zhou", "Zielinski", "Ashdown", "Blackthorn", "Brightwater", "Coldiron", "Dunmore", "Emberly", "Farrow", "Greyhaven", "Hawke",
	"Ironside", "Kestrel", "Lockridge", "Mercer", "Northgate", "Oakheart", "Pell", "Quarry", "Ravenscroft", "Sable", "Starling",
	"Stormvale", "Thatcher", "Underhill", "Voss", "Westbrook", "Wilder", "Yardley", "Ackermann", "Bertolini", "Czerny", "Dragomir",
	"Esposito", "Fonseca", "Gallo", "Hendrix", "Inoue", "Jaramillo", "Kristiansen", "Lehmann", "Maalouf", "Nordin", "Ozturk",
	"Pacheco", "Quaye", "Rautio", "Sandoval", "Tamura", "Urquhart", "Valdivia", "Wojcik", "Ximenez", "Yoon", "Zubiri", "Aldana",
	"Brodeur", "Castillo", "Dimitrov", "Engel", "Falk", "Gutierrez", "Hirano", "Ilunga", "Juarez", "Kiplagat", "Larsen", "Mwangi",
]


static func slots_of(hid: String) -> Array:
	return SHIP_CREW.get(hid, [])


static func role_name(r: String) -> String:
	return String(ROLES.get(r, {}).get("name", r))


static func bonus_label(role: String, bonus: String) -> String:
	for b in ROLES.get(role, {}).get("bonuses", []):
		if b[0] == bonus:
			return String(b[1])
	return bonus


## Roles that some hull needs (required) – the others get their own skill tree tile.
static func roles_required_by(hid: String) -> Array:
	var out: Array = []
	for s in slots_of(hid):
		if bool(s[1]) and not s[0] in out:
			out.append(s[0])
	return out
