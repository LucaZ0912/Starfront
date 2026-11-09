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
		"text": "About two hundred and forty systems linked by hyperspace gates. Everyone simply calls it \"the Cluster\"; its old catalogue name survives only in archives.\n\nIn the middle lies the core, shared by the Cluster Assembly and the Covenant of Return, with the small enclave of the Meridian Directorate and a few pirate holdings. Round it runs the Rim, a ring of constellations no power holds; beyond the Rim the empty Far Reaches, and beyond them the Veil.\n\nSecurity follows the territory: deep inside a power's space patrols are everywhere, at the borders less so, and pirate space, the Rim and the Far Reaches are lawless.",
		"see": ["hist_today", "cluster_security", "cluster_rim"]},
	"cluster_security": {"cat": "cluster", "title": "Security and territory", "unlock": "jump", "image": {"icon": "o_shield"},
		"text": "Each system shows its security from 1.0 (safe) to 0.0 (lawless). The Assembly and the Covenant grow outward from their capitals; where they meet, a handful of border systems are contested – the old rivals have never settled them. The Meridian Directorate keeps to its enclave of a few systems round Durchbruch and has no disputed borders. Two pirate factions hold small strongholds of their own.\n\nThe galaxy map's Territory layer shows who owns what; zoomed right out it names every territory.",
		"see": ["fac_assembly", "cluster_havens"]},
	"cluster_rim": {"cat": "cluster", "title": "The Rim and the Far Reaches", "unlock": "rim", "image": {"icon": "sensors"},
		"text": "Round the core runs the Rim – constellations of a few systems each, close together and joined among themselves, with only one or two routes to their neighbours and into the core. No power claims them. Free settlements keep small outposts here, the pirates hold fortresses, and the rock is richer than anywhere in the core.\n\nBeyond the Rim lie the Far Reaches: a second ring of constellations, reached only through the Rim, where nobody lives at all. Their gates are old, their security nil, their dangers many – and at their outer edge the Veil begins.",
		"see": ["cluster_battlefields", "cluster_fortresses", "cluster_veil_edge"]},
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
	# package 42: Wirtschaft 2.0
	"cluster_economy": {"cat": "cluster", "title": "Economies and prosperity", "unlock": "jump", "image": {"icon": "distributor"},
		"text": "Every system lives from something. Its main economy – and often a secondary one – comes from what is there: the stations above all (an industrial complex makes an industrial system, a military outpost a military one), and then the worlds, moons, fields and belts. Ocean and jungle worlds feed the Cluster, metal worlds and asteroid fields are mined, gas giants power industry, red and toxic giants supply the chemists, earthlike worlds draw tourists and high-tech firms.

The nine economies: Agriculture, Mining, Industry, Refining, Chemistry, High-Tech, Research, Military and Tourism. The galaxy map highlights them – the coloured mark above a system is its main economy.

Prosperity runs in five levels – Impoverished, Poor, Average, Wealthy, Rich – shown as pips beside each system. It starts from a system's people, stations and security. Selling a system what it wants, buying what it makes, finishing its contracts and clearing its pirates raise it; a raid that knocks out a station costs it dearly; left alone it drifts back to where it started.\n\nProsperity shows: rich systems are busier, better patrolled and pay more for contracts, their markets keep bigger stocks and their outfitters better qualities; poor ones draw pirates and offer less. Military systems sell bigger and better weapons and armour, high-tech systems better modules.",
		"see": ["cluster_independent", "basics_market"]},
	"basics_market": {"cat": "basics", "title": "Markets and stocks", "unlock": "dock", "image": {"icon": "o_cargo"},
		"text": "Every market keeps stocks. Goods made here – green – are cheap and plentiful; goods wanted here – gold – are dear and scarce, and the station pays well for them. Neutral goods it buys at a fair price and sells only what traders have left.

What a market makes and wants comes from its station and from the economy of its system: an agricultural system sells grain and coffee and wants machinery and fertiliser; a mining system sells its ores and wants drill bits and explosives. Wealthy and rich systems want luxuries – wine, jewellery, gold, holo displays; some goods are needed everywhere.

Trade moves the stock: sell a hold full of anything and its price drops with every unit; buy a market empty and the price climbs. Over time the stocks drift back – the made goods are made again, the wanted ones used up.",
		"see": ["cluster_economy", "basics_munitions"]},
	"cluster_resorts": {"cat": "cluster", "title": "Resorts and sights", "unlock": "jump", "image": {"icon": "o_cargo"},
		"text": "Where the Cluster takes its holidays, there are resorts – near beautiful worlds, ringed giants and wondrous stars: red supergiants, neutron stars, black holes. The great ones are habitat rings: a wide ring with a landscape under a glass roof, meadows, forests, lakes and towns, whose lights shine on its night side. The smaller ones are biospheres, a glass dome over the same green world. The capitals and Perlmutt have theirs too, and safe, wealthy systems are likeliest to.\n\nA resort lives from its guests: it sells souvenirs, holo films and art, and pays well for luxuries, fine food and wine. Its system gains a tourist trade – Maison Aurelle's cruise liners come through the gates to see the sights and berth at the resort, and little sightseeing shuttles fly its guests out to the rings and back.\n\nWhat tourists come to see are the sights: beautiful worlds, the rings of the giants, the wondrous stars and the great landmarks – The Vote, the Pilgrim Gate, the Meridian Sphere.",
		"see": ["cluster_economy"]},
	"basics_on_foot": {"cat": "basics", "title": "On foot", "unlock": "on_foot", "image": {"icon": "face"},
		"text": "Docked at a station you can leave the ship and walk its deck: the lift from the dock opens onto a corridor with the shops along it, and above it, behind a railing, lies the bar with its great window onto space. People looking for a post wait in the bar with a \"!\" over their heads – walk up and talk to them. Walk with W A S D (Shift to run) and press E at a door, a terminal, a person or the lift. Everything works through the station window as before – the deck is the same station, seen on foot.

Every deck looks like its station: bright and clean on a research station, grey and stern on a military outpost, rust and crates on an industrial complex, neon and scrap in a pirate haven.",
		"see": ["cluster_stations"]},
	"basics_tourism": {"cat": "basics", "title": "Tourists and round trips", "unlock": "dock", "image": {"icon": "o_cargo"},
		"text": "Among the passenger contracts on the board are holidaymakers: tourists bound for a resort pay a third more, and wealthy systems send the most of them. Every group you bring raises the resort system's prosperity a little.\n\nRound trips go further: the sightseers board here, you take them to a sight in another system – a beautiful world, the rings of a giant, a wondrous star, a famous landmark – and stay close, out of warp, until they have seen it; then you bring them back to where they boarded. The deadline covers the whole trip; the more famous the sight, the better the pay.",
		"see": ["cluster_resorts"]},
	"basics_munitions": {"cat": "basics", "title": "Munitions Depot", "unlock": "dock", "image": {"icon": "w_mines"},
		"text": "Weapons that have to be reloaded are restocked at the Munitions Depot of Obsidian Ordnance, not on the market – so far the mines of the mine launchers.\n\nWhat a depot carries follows the economy of its system: military systems stock every kind and sell them cheapest, industrial systems and shipyards the common ones, high-tech systems the jammer mines; pirate havens sell everything, at a price. Where the economy does not support a depot, the service stays dark. Munitions you no longer need go back for half their price.",
		"see": ["basics_market"]},
	# package 39d: the manufacturers' systems and the independent systems
	"cluster_battlefields": {"cat": "cluster", "title": "Old battlefields", "unlock": "battlefield", "image": {"icon": "hull"},
		"text": "The powers fought over the Cluster for a century and a half after the Severance, and the Rim is where most of those fleets died. Their hulks still drift where they fell – burnt grey, holed, often broken in two – in fields of scrap round the place of the battle.\n\nA salvager takes them apart: salvage, alloys and weapon parts, now and then an old module still whole, and sometimes Pre-Severance Tech that research stations and high-tech worlds pay well for. A hulk once salvaged is gone for good.",
		"see": ["cluster_derelicts"]},
	"cluster_derelicts": {"cat": "cluster", "title": "Pre-Severance derelicts", "unlock": "relic", "image": {"icon": "hull"},
		"text": "Out in the Rim, and more often in the Far Reaches, lie the ships that brought people to the Cluster – colony and generation ships built on Earth, long dead: a spine kilometres long, a broken habitat ring, faded paint and the names of ships no one alive remembers.\n\nSalvaging one yields Pre-Severance Tech, research data and much scrap; the pieces that broke off hold a little more. Now and then the crew of a salvager finds a Relic of Earth aboard – the Covenant lays such things in the Cathedral of Return.",
		"see": ["cluster_battlefields", "cluster_veil_edge"]},
	"cluster_veil_edge": {"cat": "cluster", "title": "The edge of the Veil", "unlock": "veil", "image": {"icon": "hyperdrive"},
		"text": "Beyond the Far Reaches lies the Veil – the belt of unstable hyperspace that has closed the Cluster off since the Severance. The systems at its edge are marked violet on the galaxy map. A curtain of violet light hangs in their sky, and the sensors see things: an outline of a ship that is not there, an echo of your own transponder, voices on the comm band in no language the computer knows.\n\nNothing out there has ever been proven to be dangerous. Nothing has ever been explained either.",
		"see": ["cluster_rifts", "cluster_veil"]},
	"cluster_rifts": {"cat": "cluster", "title": "Veil rifts", "unlock": "veil_rift", "image": {"icon": "hyperdrive"},
		"text": "At the edge of the Veil, space is torn: a jagged violet rent, white at its heart, visible from far off. An analyzer reads far more in a rift than in any ordinary anomaly – Veil readings the Research Exchange buys – and more often than not exotic matter.",
		"see": ["cluster_veil_edge"]},
	"cluster_radiation": {"cat": "cluster", "title": "Radiation zones", "unlock": "hz_radiation", "image": {"icon": "o_shielded"},
		"text": "Round neutron stars and black holes, and here and there in the Rim, space is thick with radiation. Inside a radiation zone your shields drain; once they are gone the hull burns. A sickly yellow haze and a striped ring mark the zone on the system map.\n\nWhere a zone lies over an asteroid field, the rock is purer and richer – the price is the dose.",
		"see": ["basics_radiation"]},
	"cluster_ion_storms": {"cat": "cluster", "title": "Ion storms", "unlock": "hz_ion", "image": {"icon": "hyperdrive"},
		"text": "Blue clouds of charged gas that drift slowly through a system. Inside, the radar is jammed and lightning strikes ships – each strike knocks out shields and systems for a moment and scorches the hull. Ion storms are rare in the core and common in the Rim.",
		"see": ["cluster_radiation"]},
	"cluster_minefields": {"cat": "cluster", "title": "Old minefields", "unlock": "hz_mines", "image": {"icon": "hull"},
		"text": "The wars after the Severance left more than hulks: fields of mines, laid round battlefields and across the way to gates, still armed after a century. They belong to no one and go off against anyone – pirates and patrols alike. Point defence shoots them down; a red dashed ring marks a field on the system map.",
		"see": ["cluster_battlefields"]},
	"cluster_fortresses": {"cat": "cluster", "title": "Pirate fortresses", "unlock": "fortress", "image": {"icon": "hull"},
		"text": "Out in the Rim the pirate factions hold fortresses – hollowed-out rocks behind a ring of armoured bastions, far bigger than any haven, with heavy guns and a garrison of their own. The powers have put a bounty on each of them.\n\nDestroy the whole garrison and the fortress is broken: its guns fall silent and the bounty is yours as a bond. Half an hour later the pirates have rebuilt it.",
		"see": ["cluster_battlefields"]},
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
		"text": "Gates link neighbouring systems. Any jump drive takes any route – a better one (Mk II, Mk III) jumps faster and steadies an old gate's field – and every jump costs fuel. Larger, heavier ships need more.

Every route between two systems ends in a gate, and you can tell who keeps it: the Assembly's white-and-blue rings with their four pylons, the Covenant's crimson and gold with eight spires, the Directorate's silver octagons with green emitters, the plain yellow-striped gates of the independents.\n\nOut in the Rim nobody keeps them any more. The old gates there are rusted, missing plates, broken in places down to the bare frame, and their fields flicker; the pirates patch theirs with scrap. A jump through an old gate takes longer – and very rarely its field breaks down mid-jump: the ship is flung out somewhere in the target system and takes damage. It is never fatal, but it hurts.",
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
