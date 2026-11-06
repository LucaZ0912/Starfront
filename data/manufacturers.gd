extends RefCounted
## Ship manufacturers (phase 0.5 package 24). The ships themselves follow in package 25; here: who
## they are, their crest and their codex entry.
##   kind     "private" (megacorp) or "state" (manufacturer of a power: faction ships)
##   faction  the power of a state manufacturer
##   unlock   codex unlock event (see data/codex.gd)
##   crest    like the faction crests (scripts/core/crest_art.gd): shape, field, symbol, rim, symbol_id,
##            optional pattern ("hazard" = yellow-black warning stripes at the foot)
##   ships    planned models (shown in the codex as "known models")
##   yards    station types whose shipyards sell its hulls ("all" = every shipyard); "small_yards":
##            station types without a full shipyard that still sell some of its hulls (package 25a)
##   rich_only only in rich, safe systems of these powers (package 25c, Maison Aurelle)
## State manufacturers (kind "state") sell only at shipyards of their faction's stations, each hull
## from its standing tier (hull min_tier) – package 25e.

const MAKERS := {
	"earthworks": {
		"name": "Earthworks", "tag": "EWK", "kind": "private", "founded": 12450, "unlock": "start",
		"motto": "Built on Earth. Built to last.",
		"color": Color(0.55, 0.72, 0.9),
		"crest": {"shape": "round", "field": Color(0.24, 0.31, 0.4), "symbol": Color(0.62, 0.84, 1.0), "rim": Color(0.82, 0.86, 0.9), "symbol_id": "globe"},
		"text": "Founded on Earth in 12450 HE – the first great starship manufacturer not run by a state. Its ships carried the exploration of the galaxy and the settlement of the Cluster. Until shortly before the Severance it was the only starship manufacturer at all, with a single Shipyard Complex in orbit of Luna, Earth's moon. A second yard was built in the Cluster in 12696 HE; in 12701 HE the government of Earth finally allowed other manufacturers.\n\nIts design is plain and practical – the basic Earth design. Technically improved, it has hardly changed since the 12450s: proof of timeless design and great engineering. Earthworks builds something for everyone, mostly all-rounders, but also specialists such as the Mule and the Longhaul. Today it is an independent megacorp, and its ships are sold at nearly every shipyard.",
		"ships": ["Dragonfly", "Hornet", "Mule", "Drillhead", "Warden", "Bastion", "Skiff", "Longhaul"],
		"yards": "all", "small_yards": {"mining_colony": ["drillhead"]},
		"see": ["hist_expansion", "hist_severance", "maker_khi"]},
	"khi": {
		"name": "Kanayama Heavy Industries", "tag": "KHI", "kind": "private", "founded": 12701, "unlock": "corp:hoy",
		"motto": "We dig deeper.",
		"color": Color(1.0, 0.78, 0.12),
		"crest": {"shape": "plate", "field": Color(0.96, 0.74, 0.1), "symbol": Color(0.08, 0.08, 0.09), "rim": Color(0.1, 0.1, 0.11), "symbol_id": "mountain_pick", "pattern": "hazard"},
		"text": "Named after Kanayama-hiko, in old Shinto the god of mines and metalwork. Founded in the Cluster in 12701 HE, the year other manufacturers were allowed, when the mining boom drove up the demand for heavy machinery: the stations could no longer keep up with refining, and new solutions were needed.\n\nKHI builds mining and industrial ships – bulky, practical rather than pretty, painted in the yellow of construction machines. Every KHI ship carries its own refinery and ore hold, and when the refinery runs it belches black smoke. They mine better than anyone, but they are slow to turn and slow to warp.",
		"ships": ["Mogura", "Anaguma", "Iwakudaki", "Kanayama-maru"],
		"yards": ["industry", "shipyard"], "small_yards": {"mining_colony": ["mogura", "anaguma"]},
		"see": ["maker_earthworks", "cluster_asteroids"]},
	"aurelle": {
		"name": "Maison Aurelle", "tag": "AUR", "kind": "private", "founded": 12895, "unlock": "corp:hoy",
		"motto": "Arrive in style.",
		"color": Color(0.95, 0.85, 0.55),
		"crest": {"shape": "oval", "field": Color(0.94, 0.91, 0.84), "symbol": Color(0.8, 0.6, 0.2), "rim": Color(0.85, 0.66, 0.25), "symbol_id": "star_a"},
		"text": "The youngest manufacturer in the Cluster, founded in 12895 HE by Ivoire Maison and made possible by the economic boom of the Cluster Assembly in recent years. Close to the Assembly, but an independent megacorp.\n\nMaison Aurelle builds luxury liners and passenger ships – sleek, polished and very expensive. Its best customers are the rich oligarchs of the Covenant, where an Aurelle liner is a prized status symbol; that the founder is a citizen of the Assembly is politely left unsaid there.",
		"ships": ["Pearl", "Boulevard", "Opal", "Empress"],
		"yards": ["trade"], "rich_only": ["assembly", "covenant"],
		"see": ["fac_assembly", "fac_covenant"]},
	"hadrian": {
		"name": "Hadrian Dynamics", "tag": "HDY", "kind": "private", "founded": 12790, "unlock": "corp:hoy",
		"motto": "Deterrence is a product.",
		"color": Color(0.85, 0.35, 0.25),
		"crest": {"shape": "octagon", "field": Color(0.15, 0.16, 0.18), "symbol": Color(0.72, 0.74, 0.78), "rim": Color(0.75, 0.25, 0.18), "symbol_id": "rampart"},
		"text": "The most controversial manufacturer in the Cluster. After the Severance the Cluster sank into chaos, and arms makers such as Hadrian Ordnance grew immensely rich. Its owner, Erik Martin, also brought the Dark Decades to an end: he rediscovered how to build nuclear weapons and, around 12748 HE, forced the first ceasefire between the young, warring Assembly and Covenant by nuclear deterrence.\n\nAround 12790 HE Hadrian Ordnance merged with the hull maker Castellan Hullworks into Hadrian Dynamics and began to build its own ships – brutal, dangerous warships with reflective hulls, made for combat and little else. Today Erik Martin Jr. runs the company; he is said to be the richest man in the Cluster. Pirates fly worn-out copies of its ships.",
		"ships": ["Talon", "Maul", "Goliath", "Citadel"],
		"yards": "all",                      # Goliath and Citadel: hull yard_rule "military"
		"pirate_copies": ["hdy_talon", "hdy_maul", "hdy_citadel"],
		"see": ["hist_dark_decades", "fac_assembly", "fac_covenant"]},
	"concord": {
		"name": "Concord Fleetworks", "tag": "CFW", "kind": "state", "faction": "assembly", "founded": 12755, "unlock": "faction:assembly",
		"motto": "Every citizen comes home.",
		"color": Color(0.35, 0.6, 1.0),
		"crest": {"shape": "round", "field": Color(0.17, 0.35, 0.74), "symbol": Color(0.95, 0.97, 1.0), "rim": Color(0.75, 0.82, 0.92), "symbol_id": "rings"},
		"text": "When the wars ended, the Assembly had to retire or rebuild many old Earthworks ships worn out by decades of civil war. Its government wanted to nationalise Earthworks at first; after long and bitter debates it offered a partnership instead. Together with Hivewright Drone Works, Concord Fleetworks was founded in 12755 HE – a joint venture of the Assembly, Earthworks and Hivewright.\n\nThe Assembly protects the lives of its citizens, so its ships rely on two things: strong shields and drones. Concord ships are drone carriers – the drones fight, the pilot stays behind the shields. Their own guns are weak. Models up to the flagship Concordia, the only ship that controls eleven drones.",
		"ships": ["Demos", "Quirinus", "Concordia"],
		"see": ["fac_assembly", "maker_earthworks", "corp_hwd"]},
	"forge": {
		"name": "Forge of Return", "tag": "FOR", "kind": "state", "faction": "covenant", "founded": 12730, "unlock": "faction:covenant",
		"motto": "Faith is forged in fire.",
		"color": Color(0.9, 0.2, 0.2),
		"crest": {"shape": "gothic", "field": Color(0.55, 0.06, 0.1), "symbol": Color(1.0, 0.8, 0.3), "rim": Color(1.0, 0.8, 0.3), "symbol_id": "anvil_flame"},
		"text": "Built by the Covenant from scratch during the Dark Decades – by trial and error and at the price of many dead pilots, crews and engineers. Everyone knows of that bloody road, nobody in the Covenant dares to speak of it – and it worked: Covenant ships need not hide behind traditional designs and surpass them in several ways.\n\nThey are the exact antithesis of the Assembly's carriers: splendid and brutal, red and gold, with enormous reactors, weak hulls and synthetic red focus-crystal lasers. Covenant pilots reject drones – drones are an invention of the Cluster. The Cathedral, a mobile weapons platform with an anti-drone pulse, was built in answer to the Assembly's carriers.",
		"ships": ["Acolyte", "Templar", "Cathedral"],
		"see": ["fac_covenant", "maker_concord"]},
	"axiom": {
		"name": "Axiom Astronautics", "tag": "AXA", "kind": "state", "faction": "directorate", "founded": 12740, "unlock": "faction:directorate",
		"motto": "Every frontier is a hypothesis.",
		"color": Color(0.4, 0.95, 1.0),
		"crest": {"shape": "hex", "field": Color(0.05, 0.12, 0.16), "symbol": Color(0.4, 0.95, 1.0), "rim": Color(0.35, 0.85, 0.95), "symbol_id": "delta_orbit"},
		"text": "As old as the Meridian Directorate itself and, like it, run by a council of experts with a committee for every concern. It never stops developing.\n\nThe Directorate's patrols fly Earthworks and Hadrian Dynamics ships; Axiom builds research and exploration ships – highly futuristic, with keen sensors, low signatures and cloaking devices. Its prototype Threshold jumps without a gate through a small wormhole, fed by exotic matter from rare anomalies – but not through the Veil. That remains the goal of Project Bridge.",
		"ships": ["Parallax", "Threshold"],
		"see": ["fac_directorate", "cluster_veil"]},
}
