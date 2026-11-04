extends RefCounted
## The Codex (phase 0.5 package 18): in-game encyclopedia. Basics are known from the start, the
## rest unlocks when the pilot discovers it (GameState.codex). Every later package adds its entries.
##   cat     category id (CATEGORIES)
##   title   heading
##   text    English text; paragraphs separated by "\n\n"
##   unlock  "start" or an event id: "dock", "jump", "warp", "mining", "colossus", "haven", "notorious",
##           "raid", "ion", "contract", "bond", "faction:<id>", "corp:<id>"
##   image   {"crest": faction} | {"ship": hull} | {"icon": module icon key}  (optional)
##   see     related entry ids (cross references)
## Faction and corporation entries are generated from data/factions.gd and data/corporations.gd.

const FactionData = preload("res://data/factions.gd")
const CorpData = preload("res://data/corporations.gd")
const ServiceData = preload("res://data/station_services.gd")

const CATEGORIES := [
	["basics", "Basics"], ["history", "History"], ["factions", "Factions"],
	["corporations", "Corporations"], ["cluster", "The Cluster"], ["technology", "Technology"],
]

const ENTRIES := {
	# ---------------------------------------------------------------- Basics (known from the start)
	"basics_flight": {"cat": "basics", "title": "Flying and warping", "unlock": "start", "image": {"icon": "engine"},
		"text": "Click empty space to fly at sublight speed, click an object to select it – the panel top right lists what you can do: warp, approach, orbit, keep at range, lock, dock, jump.\n\nSystems are huge. Anything further than 40,000 km is reached by warp: the ship aligns, accelerates and crosses the system in seconds. Three zoom levels – Combat, Recon (radar) and System – show the same space at different scales.",
		"see": ["tech_warp", "tech_gates"]},
	"basics_combat": {"cat": "basics", "title": "Combat and locks", "unlock": "start", "image": {"icon": "w_kinetic"},
		"text": "Weapons only fire at a locked target. Lock up to three ships; the active lock is the one your modules act on. Switch modules on with the tiles at the bottom or the keys 1–9.\n\nShields are weak against optical weapons, armour against kinetic rounds, structure against explosives. Colossal asteroids block line of sight – use them as cover.",
		"see": ["basics_zones", "basics_reputation"]},
	"basics_zones": {"cat": "basics", "title": "No-fire zones", "unlock": "start", "image": {"icon": "o_shield"},
		"text": "Every station protects the space around it. Whoever opens fire inside a no-fire zone becomes an aggressor for 30 seconds and the station's batteries engage. Shooting back at an aggressor is self-defence.\n\nIn the space of the three powers such shots are also a crime.",
		"see": ["basics_law"]},
	"basics_reputation": {"cat": "basics", "title": "Standing", "unlock": "start", "image": {"icon": "o_targeting"},
		"text": "Every faction keeps a standing towards you, from Arch-enemy to Allied. Bounty bonds and contracts raise it; attacking its ships lowers it.\n\nStanding decides docking rights, prices, how patrols treat you, which contracts you are offered – and whether pirates leave you alone and let you into their havens.",
		"see": ["basics_law", "fac_assembly", "fac_hollow_crown"]},
	"basics_law": {"cat": "basics", "title": "Law and wanted status", "unlock": "start", "image": {"icon": "t_warrant"},
		"text": "The powers keep criminal records. Firing in no-fire zones, attacking or interdicting civilians and patrols makes you a Suspect – their patrols hunt you – then Wanted and finally Most Wanted, when their stations refuse you.\n\nRecords fade over time, or you pay the fine at a Bond Office of that faction. Pirate space has no law.",
		"see": ["basics_bonds", "basics_zones"]},
	"basics_bonds": {"cat": "basics", "title": "Bounty bonds", "unlock": "start", "image": {"icon": "t_warrant"},
		"text": "Bounties are not paid at once. The power responsible for a system puts the bounty on a pirate's head; destroying it issues a bond, cleared by the Sable Writ Exchange at any station of that power.\n\nBonds belong to you, survive the loss of a ship and never expire. A Warrant Scanner shows who is wanted and by whom.",
		"see": ["corp_swx", "basics_law"]},
	"basics_contracts": {"cat": "basics", "title": "Contracts", "unlock": "start", "image": {"icon": "t_analyzer"},
		"text": "BlackLedger posts freelance work on every Bulletin Board: courier runs, bounty hunts, supplies, surveys – and at trade hubs, convoy escorts. Government stations add faction contracts: escorting convoys, flying with patrols, intercepting smugglers and hunting notorious pirates.\n\nFaction contracts need standing and raise it more than ordinary work.",
		"see": ["basics_reputation", "cluster_notorious"]},

	# ---------------------------------------------------------------- History (from the station archives)
	"hist_leap": {"cat": "history", "title": "The Leap (12340 HE)", "unlock": "dock",
		"text": "Around 12340 of the Human Era – the calendar that counts from the dawn of civilisation – the hyperspace drive was mastered. Within a generation humanity left its home system for the stars.",
		"see": ["hist_expansion", "tech_gates"]},
	"hist_expansion": {"cat": "history", "title": "The Expansion (12400–12700 HE)", "unlock": "dock",
		"text": "Chartered corporations built jump gates, colony ships settled distant star clusters. One of them lay far out at the rim of known space, a dense cluster linked to Earth by a single long-range route: the Long Gate.\n\nThe charter houses of that age still run the station services today.",
		"see": ["hist_severance", "cluster_long_gate", "corp_kvx"]},
	"hist_severance": {"cat": "history", "title": "The Severance (12713 HE)", "unlock": "dock",
		"text": "In 12713 HE the Cluster was cut off. Long-range jumps have ended in the Veil ever since – a belt of unstable hyperspace around the Cluster. The local gates kept working; Earth fell silent.\n\nNobody knows what happened. The wreckage of the Long Gate drifts in a system at the rim.",
		"see": ["cluster_veil", "hist_dark_decades"]},
	"hist_dark_decades": {"cat": "history", "title": "The Dark Decades", "unlock": "dock",
		"text": "Without supplies from Earth the colonial administration collapsed. Shortages, riots, the first pirates. Out of the chaos rose three powers: the Cluster Assembly, the Covenant of Return and the Meridian Directorate.",
		"see": ["hist_today", "fac_assembly", "fac_covenant", "fac_directorate"]},
	"hist_today": {"cat": "history", "title": "The Cluster today (12900 HE)", "unlock": "dock",
		"text": "Almost two centuries after the Severance nobody alive has seen Earth. To some it is a myth, to the Covenant a holy goal, to most just a memory. The powers watch each other, pirates prey on the rims, and the corporations sell to everyone.",
		"see": ["cluster_cluster"]},

	# ---------------------------------------------------------------- The Cluster
	"cluster_cluster": {"cat": "cluster", "title": "The Cluster", "unlock": "start", "image": {"icon": "sensors"},
		"text": "Forty-eight systems linked by hyperspace routes. Everyone simply calls it \"the Cluster\"; its old catalogue name survives only in archives.\n\nSecurity follows the territory: deep inside a power's space patrols are everywhere, at the borders less so, and pirate space is lawless.",
		"see": ["hist_today", "cluster_security"]},
	"cluster_security": {"cat": "cluster", "title": "Security and territory", "unlock": "jump", "image": {"icon": "o_shield"},
		"text": "Each system shows its security from 1.0 (safe) to 0.0 (lawless). The three powers grow outward from their capitals; where they meet, systems are contested and shared. Two pirate factions hold remote corners around their havens.\n\nThe galaxy map's Territory layer shows who owns what.",
		"see": ["fac_assembly", "cluster_havens"]},
	"cluster_veil": {"cat": "cluster", "title": "The Veil", "unlock": "jump",
		"text": "A belt of unstable hyperspace around the Cluster. Every long-range jump since the Severance has ended there – ships that tried to cross it were never heard from again. The Meridian Directorate's Project Bridge searches for a way through.",
		"see": ["hist_severance", "fac_directorate"]},
	"cluster_long_gate": {"cat": "cluster", "title": "The Long Gate", "unlock": "jump",
		"text": "Once the only route between the Cluster and Earth. Its wreckage still drifts in a rim system – a reminder, a relic, and to some a promise.",
		"see": ["hist_severance", "cluster_veil"]},
	"cluster_stations": {"cat": "cluster", "title": "Stations", "unlock": "dock", "image": {"icon": "o_cargo"},
		"text": "Stations are built from modules; their type decides what they trade and which services they offer: trade hubs, industrial complexes, mining colonies, agricultural and research stations, military outposts, ice refineries and shipyards. Bigger tiers mean bigger stations, wider no-fire zones and more guns.\n\nEvery station flies the flag of the power that owns its system.",
		"see": ["corp_kvx", "basics_zones"]},
	"cluster_asteroids": {"cat": "cluster", "title": "Asteroid fields", "unlock": "mining", "image": {"icon": "t_mining"},
		"text": "Fields come in three classes: metallic close to the star, stony further out, icy beyond the frost line. Common ores are everywhere, rare ones only in unsafe space. Mining lasers work best on rock; ice needs an ice harvester.",
		"see": ["cluster_colossi", "corp_cmc"]},
	"cluster_colossi": {"cat": "cluster", "title": "Colossal asteroids", "unlock": "colossus", "image": {"icon": "t_survey"},
		"text": "Rocks thousands of kilometres long, lying in the asteroid fields. They are obstacles – ships fly around them – and they cast a radar shadow: nothing behind a colossus shows on the radar, can be locked or hit.\n\nPirates use them for ambushes. So can you.",
		"see": ["basics_combat", "pir_archetypes"]},
	"cluster_havens": {"cat": "cluster", "title": "Pirate havens", "unlock": "haven", "image": {"icon": "w_explosive"},
		"text": "Patched-together fortresses of wrecks in lawless space. Their guns fire on anyone who is not a friend of the faction that runs them. Pilots its pirates trust may dock – black market, weapons, repairs, no questions.",
		"see": ["fac_hollow_crown", "fac_severed", "basics_reputation"]},
	"cluster_notorious": {"cat": "cluster", "title": "Notorious pirates", "unlock": "notorious", "image": {"ship": "warden"},
		"text": "Named captains with their own paint, a special trait and an escort that grows the longer they survive. Their danger is rated in stars; their bounty rises with every month they stay free. The Bond Office lists them on wanted posters.\n\nWhen one falls, a successor takes over the crew sooner or later.",
		"see": ["cluster_raids", "pir_archetypes", "basics_bonds"]},
	"cluster_raids": {"cat": "cluster", "title": "Station raids", "unlock": "raid", "image": {"icon": "w_explosive"},
		"text": "The most feared captains – five stars – attack stations. The Sable Writ Exchange announces such raids minutes ahead. Raiders shoot the station's turrets first and knock others out with ion torpedoes; a station that falls stays offline until relief goods arrive.\n\nDefenders are paid. A won raid turns one of the captain's stars red.",
		"see": ["cluster_notorious", "tech_ion"]},

	# ---------------------------------------------------------------- Technology
	"tech_gates": {"cat": "technology", "title": "Hyperspace gates", "unlock": "jump", "image": {"icon": "hyperdrive"},
		"text": "Gates link neighbouring systems. Every route has a class; your hyperdrive must match it, and every jump costs fuel. Larger, heavier ships need more.",
		"see": ["hist_leap", "tech_warp"]},
	"tech_warp": {"cat": "technology", "title": "Warp drive", "unlock": "warp", "image": {"icon": "engine"},
		"text": "Inside a system ships travel by warp: align, accelerate, cross hundreds of thousands of kilometres in seconds. Heavy hulls align slowly. A warp interdictor can pull a ship out of warp – pirates use them to catch convoys.",
		"see": ["tech_gates", "basics_flight"]},
	"tech_scanners": {"cat": "technology", "title": "Scanners", "unlock": "mining", "image": {"icon": "t_survey"},
		"text": "Survey scanners map a place from afar, prospectors reveal the ores of an asteroid, warrant scanners read a ship's bounty and nature. A signature scanner slowly reveals hidden anomalies.",
		"see": ["cluster_asteroids", "basics_bonds"]},
	"tech_ion": {"cat": "technology", "title": "Ion weapons", "unlock": "ion", "image": {"icon": "w_optical"},
		"text": "Pirate gear, never sold by the corporations: ion disruptors tear at shields and drain the target's capacitor. The heaviest variant, the ion torpedo, is carried only by the most notorious captains – it knocks station turrets offline.",
		"see": ["pir_archetypes", "cluster_raids"]},
	"pir_archetypes": {"cat": "technology", "title": "Pirate tactics", "unlock": "faction:free_captains", "image": {"ship": "crow"},
		"text": "Pirates fly alone but not alike. Raiders strike and break off, brawlers close in, snipers keep their distance, ambushers wait in the rocks, leeches drain shields with ion weapons, and cowards run – calling everyone near for help. A Warrant Scanner tells you which one you face.",
		"see": ["tech_ion", "cluster_notorious"]},
}


## All entries: the hand-written ones plus one per faction and corporation.
static func entries() -> Dictionary:
	var out: Dictionary = ENTRIES.duplicate(true)
	for fid in FactionData.FACTIONS:
		var f: Dictionary = FactionData.FACTIONS[fid]
		var rel: Array = []
		for o in FactionData.FACTIONS:
			if o != fid and (FactionData.FACTIONS[o]["kind"] == "power" or f["kind"] == "pirate"):
				rel.append("%s: %s" % [FactionData.FACTIONS[o]["short"], FactionData.relation_text(FactionData.relation(fid, o))])
		var see: Array = []
		for o2 in FactionData.FACTIONS:
			if o2 != fid:
				see.append("fac_" + o2)
		out["fac_" + fid] = {"cat": "factions", "title": f["name"], "unlock": "faction:" + fid, "image": {"crest": fid},
			"text": "%s – %s\n\n\"%s\"\n\n%s\n\nRelations: %s." % [f["gov"], "a power of the Cluster" if f["kind"] == "power" else "a pirate faction", f["motto"], f["desc"], ", ".join(PackedStringArray(rel)) if not rel.is_empty() else "at war with every power"],
			"see": see.slice(0, 3)}
	for cid in CorpData.CORPS:
		var c: Dictionary = CorpData.CORPS[cid]
		var icon := "o_cargo"
		var service := ""
		for svc in ServiceData.SERVICES:
			if svc["corp"] == cid:
				icon = svc["icon"]
				service = svc["title"]
		out["corp_" + cid] = {"cat": "corporations", "title": "%s [%s]" % [c["name"], c["tag"]], "unlock": "corp:" + cid if service != "" else "dock",
			"image": {"icon": icon},
			"text": "\"%s\"\n\n%s\n\n%s" % [c["slogan"], c["desc"], ("Monopoly on the station service: %s. Like every charter house it predates the Severance and serves all three powers alike." % service) if service != "" else "A charter house older than the Severance, trusted – or at least tolerated – by all three powers."],
			"see": ["hist_expansion", "cluster_stations"]}
	return out
