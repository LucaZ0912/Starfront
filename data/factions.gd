extends RefCounted
## Governments of the Cluster (phase 0.5 package 10). Separate from the corporations, which keep
## their service monopolies. Three powers and three pirate factions; Free Captains own no
## territory and only appear as pirates.
##   kind      "power" | "pirate"
##   territory does the faction control systems?
##   color     main colour (territory on the map, ship accents)
##   hull      base colour of its ships' paint
##   crest     coat of arms: shield shape, field colour, symbol colour, rim colour, symbol
##   pilot     prefix for its ships' names ("Crown Hornet")
##   bounty    powers: how generous its bounties on pirates are (package 13)

const FACTIONS := {
	"assembly": {
		"name": "Cluster Assembly", "short": "Assembly", "kind": "power", "territory": true,
		"gov": "Direct democracy",
		"motto": "The Cluster is home.",
		"desc": "Every citizen votes on every law through the gate datanet. Born from the colonists and station crews who rebuilt after the Severance, the Assembly wants to make the Cluster a home rather than a waiting room. Strong in trade and infrastructure, slow to decide, defended by militias.",
		"color": Color(0.3, 0.58, 1.0), "hull": Color(0.74, 0.79, 0.86),
		"crest": {"shape": "round", "field": Color(0.16, 0.32, 0.72), "symbol": Color(0.95, 0.97, 1.0), "rim": Color(0.92, 0.95, 1.0), "symbol_id": "hand"},
		"pilot": "Assembly", "bounty": 0.9,
	},
	"covenant": {
		"name": "Covenant of Return", "short": "Covenant", "kind": "power", "territory": true,
		"gov": "Theocratic autocracy",
		"motto": "The road leads home.",
		"desc": "Ruled by the Hierarch. The Covenant holds Earth to be sacred and the Severance a trial of faith; those who want to stay – the Settled – are enemies. Founded by the crew of the colonial fleet whose chaplain-admiral declared the Return a holy duty. Disciplined and heavily armed.",
		"color": Color(0.86, 0.16, 0.2), "hull": Color(0.42, 0.24, 0.25),
		"crest": {"shape": "gothic", "field": Color(0.62, 0.08, 0.12), "symbol": Color(1.0, 0.8, 0.3), "rim": Color(1.0, 0.8, 0.3), "symbol_id": "sun_road"},
		"pilot": "Covenant", "bounty": 1.25,
	},
	"directorate": {
		"name": "Meridian Directorate", "short": "Directorate", "kind": "power", "territory": true,
		"gov": "Technocracy",
		"motto": "Measure twice. Cross once.",
		"desc": "Governed by a council of experts; offices are earned by examination. Descended from a research expedition that was inside the Cluster when it was cut off. The Directorate improves life in the Cluster – medicine, terraforming, refining – and searches for a way through the Veil with Project Bridge.",
		"color": Color(0.25, 0.85, 0.55), "hull": Color(0.68, 0.72, 0.74),
		"crest": {"shape": "hex", "field": Color(0.1, 0.42, 0.3), "symbol": Color(0.85, 0.9, 0.92), "rim": Color(0.8, 0.85, 0.88), "symbol_id": "compass"},
		"pilot": "Directorate", "bounty": 1.0,
	},
	"hollow_crown": {
		"name": "Hollow Crown", "short": "Hollow Crown", "kind": "pirate", "territory": true,
		"gov": "Smuggling cartel",
		"motto": "Every border has a price.",
		"desc": "A cartel that runs the Cluster's black market: forbidden Directorate technology, Covenant relics, anything that is scarce. Its captains prefer a deal to a fight – but they do not lose fights.",
		"color": Color(0.66, 0.36, 1.0), "hull": Color(0.26, 0.22, 0.32),
		"crest": {"shape": "diamond", "field": Color(0.1, 0.08, 0.14), "symbol": Color(0.72, 0.45, 1.0), "rim": Color(0.6, 0.35, 0.95), "symbol_id": "crown"},
		"pilot": "Crown",
	},
	"severed": {
		"name": "The Severed", "short": "Severed", "kind": "pirate", "territory": true,
		"gov": "Nihilist cult",
		"motto": "Earth forgot us. We forget mercy.",
		"desc": "A cult convinced that Earth abandoned the Cluster. The Severed strip wrecks, weld their ships together from scrap and attack anything that still believes in a way home.",
		"color": Color(0.85, 0.42, 0.2), "hull": Color(0.5, 0.33, 0.24),
		"crest": {"shape": "jagged", "field": Color(0.42, 0.18, 0.1), "symbol": Color(0.94, 0.9, 0.82), "rim": Color(0.94, 0.9, 0.82), "symbol_id": "broken_ring"},
		"pilot": "Severed",
	},
	"free_captains": {
		"name": "Free Captains", "short": "Free Captains", "kind": "pirate", "territory": false,
		"gov": "Brotherhood of privateers",
		"motto": "Our code, our coin.",
		"desc": "Freebooters bound by their own code. They hold no systems and fly for whoever pays – which, most of the time, means for themselves.",
		"color": Color(0.2, 0.88, 0.82), "hull": Color(0.22, 0.24, 0.27),
		"crest": {"shape": "pennant", "field": Color(0.08, 0.09, 0.1), "symbol": Color(0.25, 0.92, 0.85), "rim": Color(0.25, 0.92, 0.85), "symbol_id": "blades"},
		"pilot": "Free Captain",
	},
}

## Attitude between factions: -1 hostile, 0 neutral, +1 allied (symmetric; unlisted pairs = 0).
## Pirate factions are hostile to every power.
const RELATIONS := {
	"assembly|covenant": -1.0,
	"assembly|directorate": 0.25,
	"covenant|directorate": 0.0,
	"hollow_crown|severed": -0.5,
}

const POWERS := ["assembly", "covenant", "directorate"]
const PIRATES := ["hollow_crown", "severed", "free_captains"]
const TERRITORIAL_PIRATES := ["hollow_crown", "severed"]


static func relation(a: String, b: String) -> float:
	if a == b:
		return 1.0
	if a == "" or b == "":
		return 0.0
	var ka: bool = FACTIONS.has(a) and FACTIONS[a]["kind"] == "pirate"
	var kb: bool = FACTIONS.has(b) and FACTIONS[b]["kind"] == "pirate"
	if ka != kb:
		return -1.0
	return float(RELATIONS.get(a + "|" + b, RELATIONS.get(b + "|" + a, 0.0)))


static func relation_text(v: float) -> String:
	if v >= 0.75:
		return "allied"
	if v > 0.1:
		return "friendly"
	if v <= -0.75:
		return "at war"
	if v < -0.1:
		return "hostile"
	return "neutral"


static func name_of(fid: String) -> String:
	return String(FACTIONS[fid]["name"]) if FACTIONS.has(fid) else "Independent"


static func short_of(fid: String) -> String:
	return String(FACTIONS[fid]["short"]) if FACTIONS.has(fid) else "Independent"


static func color_of(fid: String) -> Color:
	return FACTIONS[fid]["color"] if FACTIONS.has(fid) else Color(0.7, 0.72, 0.75)
