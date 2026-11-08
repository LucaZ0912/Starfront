extends RefCounted
## The Codex (phase 0.5 package 18): in-game encyclopedia. Basics are known from the start, the
## rest unlocks when the pilot discovers it (GameState.codex). Every later package adds its entries.
##   cat     category id (CATEGORIES)
##   title   heading
##   text    English text; paragraphs separated by "\n\n"
##   unlock  "start" or an event id: "dock", "jump", "warp", "mining", "colossus", "haven", "notorious",
##           "raid", "ion", "contract", "bond", "faction:<id>", "corp:<id>", "cme" (package 37)
##   image   {"crest": faction} | {"maker": manufacturer} | {"ship": hull} | {"icon": module icon key}  (optional)
##   see     related entry ids (cross references)
## Faction, corporation and manufacturer entries are generated from data/factions.gd,
## data/corporations.gd and data/manufacturers.gd.

const FactionData = preload("res://data/factions.gd")
const CorpData = preload("res://data/corporations.gd")
const ServiceData = preload("res://data/station_services.gd")
const MakerData = preload("res://data/manufacturers.gd")

const CATEGORIES := [
	["basics", "Basics"], ["history", "History"], ["factions", "Factions"],
	["corporations", "Corporations"], ["cluster", "The Cluster"], ["technology", "Technology"],
	["pilot", "Pilot & Crew"],
]

const ENTRIES := {
	# ---------------------------------------------------------------- Pilot & crew (phase 0.5 part 5, package 34)
	"pilot_skills": {"cat": "pilot", "title": "Skills and the pilot level", "unlock": "start", "image": {"icon": "face"},
		"text": "Twelve skills grow by doing – flying, fighting, mining, trading, science and more. Every level adds +1 % to what the skill does on your own ships. All experience also feeds the pilot level, and every pilot level brings a perk point.\n\nThe Pilot window [U] shows it all: the pilot with statistics, standings, the codex and the collection, then skills, perks and the skill tree.",
		"see": ["pilot_perks", "pilot_tree"]},
	"pilot_perks": {"cat": "pilot", "title": "Perks", "unlock": "start", "image": {"icon": "o_targeting"},
		"text": "Perks are special abilities in six groups – combat, flight, industry, science, commerce, command. A perk point per pilot level buys one; some need a skill level first.",
		"see": ["pilot_skills"]},
	"pilot_tree": {"cat": "pilot", "title": "The skill tree", "unlock": "start", "image": {"icon": "hull"},
		"text": "Ships and modules can be bought anywhere – flying and using them needs the skill tree. The Pilot Licence is the trunk; above Shields the branches split by activity: defence, combat, mining, industry, flight, exploration, security, trade and drones. Mastery are the roots.\n\nA tile opens once the tile below it is open and its achievements are met – then it glows and you confirm it. A ship without its tile stays docked; a module without it stays offline.",
		"see": ["pilot_skills", "crew_crew"]},
	"crew_crew": {"cat": "pilot", "title": "Crew", "unlock": "crew", "image": {"icon": "face"},
		"text": "Ships from M upwards carry crew. Every hull has its posts – Co-Pilot, Gunner, Engineer, Science Officer, Mining Foreman, Quartermaster, Drone Operator – and some of them must be filled before the ship may undock. A new ship comes with rookies on those.\n\nEvery spacer is someone: a name, a face, a profession, a quality from F to A and one rolled bonus. They learn slowly from the right work and step up. Very rarely one has a perk. The crew of your active ship takes a small share of your income.",
		"see": ["corp_dwt", "crew_loss", "crew_collection"]},
	"crew_wingmen": {"cat": "pilot", "title": "Wingmen", "unlock": "wingmen", "image": {"icon": "w_kinetic"},
		"text": "Pilots for hire wait at the bars: real characters with their own ship and loadout, two skills and two traits that colour how they fly. A contract runs 30, 60 or 120 minutes, paid up front, plus a share of your income – much more than crew.\n\nThey fly in formation, warp and jump with you and fight near you: aggressive, defensive or passive, or straight at your target. If a wingman dies, the ship is gone and the contract ends.",
		"see": ["crew_crew", "crew_platform"]},
	"crew_platform": {"cat": "pilot", "title": "The Citadel's launch platform", "unlock": "platform", "image": {"ship": "hdy_talon"},
		"text": "Hadrian Dynamics built the Citadel around a launch platform. Any Hadrian S ship fits on it, fitted as you like, and a Co-Pilot with the rare perk Wingman flies it – launched and recalled from the bridge.\n\nLose it, and Aegis Mutual rebuilds it at the next hangar for a tenth of its value.",
		"see": ["crew_wingmen", "maker_hadrian"]},
	"crew_loss": {"cat": "pilot", "title": "Losing the ship", "unlock": "pod", "image": {"icon": "o_shield"},
		"text": "When a ship breaks apart, every crew member has a chance to reach an escape pod – the better they are, the better the odds, and the longer the pod's signal lasts. Warp to the pod and fly close to take them aboard.\n\nYou wake at the last station you docked at. Aegis Mutual offers to rebuild the lost ship for a tenth of its value – or you start over in a Dragonfly.",
		"see": ["crew_crew"]},
	"crew_collection": {"cat": "pilot", "title": "The collection", "unlock": "collection", "image": {"icon": "t_warrant"},
		"text": "Pilot window → Pilot → Collection keeps what a career gathers: every crew perk that has served with you, and the wanted posters of the notorious pirates you destroyed.",
		"see": ["crew_crew", "cluster_notorious"]},
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
	# package 41: the mining expansion
	"basics_gas": {"cat": "basics", "title": "Gas harvesting", "unlock": "gas", "image": {"icon": "t_gas"},
		"text": "Round every gas giant, ice giant, red and toxic giant lies a harvest band in its upper atmosphere – dashed on the map. Fly through it with a gas collector switched on and keep moving: the scoop draws the gas in. The deeper you dive, the more you get – but below the inner ring heat and pressure wear on armour and hull, past every shield. Now and then a storm sweeps the band (the ring turns orange): twice the gas, twice the heat.\n\nGas giants give hydrogen and helium (rarely helium-3), ice giants nitrogen and neon (rarely xenon), red giants hydrogen and sulfur dioxide (rarely phosphine), toxic giants chlorine and ammonia (rarely fluorine). Gases take twice the room in ordinary cargo racks – gas tanks hold them at their own volume. KHI's Kujira carries 1,600 m³ and dives deeper than any other ship.",
		"see": ["basics_components"]},
	"basics_components": {"cat": "basics", "title": "Components and purity", "unlock": "mining", "image": {"icon": "distributor"},
		"text": "Every asteroid has a purity – low, medium or high – that the prospector reads: purer rock gives more ore for the same effort. Colossi often hide a deep deposit of osmium or palladium that only a deep core drill reaches.\n\nAt any station with fabricators, refined materials become components: circuit boards, battery cells, armour plating, carbon fiber, ion propellant, magnet coils, fusion cells, precision optics, cryo systems – and from radioactive materials fuel rods, tritium and medical isotopes.",
		"see": ["basics_radiation", "basics_gas"]},
	"basics_radiation": {"cat": "basics", "title": "Radioactive goods", "unlock": "mining", "image": {"icon": "o_shielded"},
		"text": "Uraninite and monazite, enriched uranium, thorium and what is made from them are radioactive. Carried in ordinary racks or the ore hold, they expose the crew – a red warning and an alarm say so. Shielded cargo racks hold them safely, but take far less per size than ordinary racks.",
		"see": ["basics_components"]},
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
	# package 39a: Landfall
	"cluster_landfall": {"cat": "cluster", "title": "Landfall", "unlock": "jump", "image": {"icon": "senate"},
		"text": "The capital of the Cluster Assembly – the system where the first colonists set down. Agora, its crowded Earth-like world, shines brighter at night than any other world in the Cluster. Above it hangs The Vote: the great trade hub where the ballots of every Assembly citizen come together, ringed by relay stations whose drones carry the votes out to the gates.

Out at the deep-blue ice giant Boulé lie the Concord Yards, where Concord Fleetworks builds its carriers – and the Res Publica, a supercarrier the size of a station, still in her berth. Only there is the Concordia sold.

Landfall is closed: its gates let in only pilots holding the Assembly's entry permit, given from Friendly standing on and taken away only from arch-enemies.",
		"see": ["fac_assembly", "cluster_senate"]},
	"cluster_senate": {"cat": "cluster", "title": "The Senate", "unlock": "permit", "image": {"icon": "senate"},
		"text": "Every citizen of the Assembly votes on every law. Every half hour or hour a bill comes to the vote in The Vote; a passed bill holds for an hour in all of the Assembly's territory – cheaper goods, higher bounties, subsidised ships … and always a price to pay for it.

With an entry permit you vote too. A party donation sways the vote a little. A bribe settles it – unless it comes out, and then the money is gone and the Assembly's trust with it.",
		"see": ["cluster_landfall", "fac_assembly"]},
	# package 39d: the manufacturers' systems and the independent systems
	"cluster_independent": {"cat": "cluster", "title": "Independent systems", "unlock": "jump", "image": {"icon": "hull"},
		"text": "Not every system belongs to a power. The independent ones – yellow on the galaxy map – govern themselves; no power patrols them, and no power's law is kept there but their own.\n\nThe private manufacturers have made their homes in such systems: Kanayama Heavy Industries builds its mining ships at Kanayama Works in Erzhalde, Maison Aurelle finishes its liners at the Atelier Aurelle in Perlmutt, and Hadrian Dynamics forges its warships and weapon platforms at the Hadrian Foundry in Schwarzwacht. Only Earthworks stayed with the Assembly: its Second Yard in Altwerft, built in 12696 HE, was the first shipyard in the Cluster.\n\nEvery manufacturer's yard sells all of its ships.",
		"see": ["cluster_security"]},
	# package 39c: Durchbruch
	"cluster_durchbruch": {"cat": "cluster", "title": "Durchbruch", "unlock": "jump", "image": {"icon": "t_analyzer"},
		"text": "The capital of the Meridian Directorate, round a blue-white star – and round that star the Directorate is building a Dyson sphere. Frame rings of the shell circle it already, closed with silver collector plates where they are finished, still bare scaffolding where they are not. At its hub, the Meridian Sphere, the Research Exchange buys what pilots learn out there. It is the only station in the Cluster built round a star itself.\n\nCurie, the showcase world, is half terraformed: green with seas on one side, still desert on the other, three solar mirrors steering light onto the new land. At Meitner the Axiom Yards build sleek research ships – the Threshold only there – and small jump gates, a ring of them in every stage of construction round the yard.\n\nDurchbruch is closed: its gates let in only pilots with the Directorate's entry permit, given from Friendly standing on.",
		"see": ["fac_directorate", "cluster_exchange"]},
	"cluster_exchange": {"cat": "cluster", "title": "The Research Exchange", "unlock": "permit", "image": {"icon": "t_analyzer"},
		"text": "Every anomaly you analyse leaves you with data the Directorate wants – the Research Exchange in the Meridian Sphere pays for it in credits and standing. It also buys exotic matter, and sells it back to pilots it trusts most (Allied).",
		"see": ["cluster_durchbruch", "fac_directorate"]},
	# package 39b: Heimkehr
	"cluster_heimkehr": {"cat": "cluster", "title": "Heimkehr", "unlock": "jump", "image": {"icon": "curia"},
		"text": "The capital of the Covenant of Return, under a red supergiant whose eruptions the faithful take for trials sent to them. Its heart is Vesper, a desert moon of the red gas giant Compline, crowded with pilgrim cities; above it rises the Cathedral of Return – pale stone, stained glass and a rose window ringed in gold, the sun over the road.

Off the cathedral stands the Pilgrim Gate. It leads nowhere – it points home, and the light it throws towards Earth never goes out. Pilgrims pass through it in an endless line.

Near the lava world Lauds the Forge of Return glows, where the Covenant's warships and focus crystals are made – and the Lux Aeterna, its capital ship, lies in her berth. Only there is the Cathedral sold.

Heimkehr is closed: its gates let in only pilots with the Covenant's entry permit, given from Friendly standing on.",
		"see": ["fac_covenant", "cluster_curia"]},
	"cluster_curia": {"cat": "cluster", "title": "The Curia", "unlock": "permit", "image": {"icon": "curia"},
		"text": "Nobody votes in the Covenant. Every half hour or hour the Hierarch proclaims an edict that holds in all of its territory until the next one – a blessing and a burden in one.

The faithful have their ways all the same. Tithes earn standing, and who gives enough may petition for the next edict. An indulgence – dearer than any fine – wipes out every crime against the Covenant. And relics of Earth, found in anomalies all over the Cluster, are laid in the Cathedral of Return for a blessing: cheaper prices at every Covenant station.",
		"see": ["cluster_heimkehr", "fac_covenant"]},
	"cluster_stations": {"cat": "cluster", "title": "Stations", "unlock": "dock", "image": {"icon": "o_cargo"},
		"text": "Stations are built from modules; their type decides what they trade and which services they offer: trade hubs, industrial complexes, mining colonies, agricultural and research stations, military outposts, ice refineries and shipyards. Bigger tiers mean bigger stations, wider no-fire zones and more guns.\n\nEvery station flies the flag of the power that owns its system.",
		"see": ["corp_kvx", "basics_zones"]},
	"cluster_asteroids": {"cat": "cluster", "title": "Asteroid fields", "unlock": "mining", "image": {"icon": "t_mining"},
		"text": "Fields come in three classes: metallic close to the star, stony further out, icy beyond the frost line. Common ores are everywhere, rare ones only in unsafe space. Mining lasers work best on rock; ice needs an ice harvester.",
		"see": ["cluster_colossi", "corp_cmc"]},
	# package 37: stars
	"cluster_cme": {"cat": "cluster", "title": "Coronal mass ejections", "unlock": "cme", "image": {"icon": "o_shield"},
		"text": "Now and then a star hurls a cloud of plasma into space. The sensors give about half a minute's warning; then the shockwave races out through the whole system.

Where it passes, sensors go blind for a while and shields falter – close to the star they collapse. A ship in warp is torn out of it (emergency shutdown), cloaks fail for a while, drones are knocked out for a few seconds and mines go off.

Brown dwarfs, white dwarfs, neutron stars and black holes do not erupt. The star classes you have seen are in the Collection (Pilot window).",
		"see": ["cluster_colossi"]},
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
	# ship manufacturers (package 24)
	for mid in MakerData.MAKERS:
		var m: Dictionary = MakerData.MAKERS[mid]
		var who := "State manufacturer of the %s" % FactionData.FACTIONS[m["faction"]]["name"] if m["kind"] == "state" else "Independent megacorp"
		out["maker_" + mid] = {"cat": "corporations", "title": "%s [%s]" % [m["name"], m["tag"]], "unlock": m["unlock"],
			"image": {"maker": mid},
			"text": "\"%s\"\n\n%s – shipbuilder since %d HE.\n\n%s\n\nKnown models: %s." % [m["motto"], who, int(m["founded"]), m["text"], ", ".join(PackedStringArray(m["ships"]))],
			"see": m["see"]}
	return out
