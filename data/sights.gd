extends RefCounted
## Package 54a (Luz): the sights on the ground – which kind on which world, their names, what they are, their
## souvenir and the events that can be seen there {id: [what, when (day / dusk / dawn / night / any), weight, rare]}.
## Pure data (Universe preloads it for the planet map). No class_name: preload it.

## The sights built so far (the others come in the next steps of 54a).
const READY := ["falls", "lagoon", "icecave", "arches", "lava", "crater"]
## The kind of sight on each kind of world.
const THEME_OF := {"jungle": "falls", "ocean": "lagoon", "ice": "icecave", "moon_ice": "icecave", "desert": "arches",
	"lava": "lava", "moon_volcanic": "lava", "barren": "crater", "dwarf": "crater", "moon_rock": "crater", "moon_captured": "crater",
	"metal": "crater", "terran": "falls"}
## Each sight: its names, its souvenir, its events {id: [name, when (day/night/any), weight, rare]}.
const SIGHTS := {
	"falls": {"names": ["The Glass Falls", "Veil Falls", "The Thousand Steps", "Thunder Basin", "The Emerald Curtain"],
		"what": "a waterfall pouring off a rock wall into a jungle pool", "souvenir": "souv_falls",
		"events": {"rainbow": ["a rainbow in the spray", "day", 4.0, false], "mist": ["morning mist over the pool", "dawn", 3.0, false],
			"fireflies": ["fireflies over the water", "night", 4.0, false], "herd": ["a herd drinking at the pool", "day", 1.0, true],
			"moonbow": ["a moonbow in the spray", "night", 0.6, true]}},
	"lagoon": {"names": ["Coral Lagoon", "The Blue Eye", "Pearl Shallows", "Seaglass Bay"], "what": "a coral lagoon with a jetty out over the reef",
		"souvenir": "souv_lagoon", "events": {"shoal": ["shoals of bright fish", "day", 4.0, false], "glow": ["glowing jellyfish", "night", 4.0, false],
			"sunset": ["the sun going down over the reef", "dusk", 3.0, false], "whale": ["a great sea creature passing the reef", "any", 0.8, true]}},
	"icecave": {"names": ["The Ice Cathedral", "Frost Hall", "The Blue Vault", "Crystal Nave"], "what": "a cave of glowing ice under a glacier",
		"souvenir": "souv_ice", "events": {"glow": ["the ice glowing deep blue", "any", 4.0, false], "aurora": ["an aurora over the glacier", "night", 3.0, false],
			"sundog": ["sun dogs over the ice field", "day", 2.0, false], "singing": ["the ice singing in the wind", "any", 0.7, true]}},
	"arches": {"names": ["The Red Arches", "Sunset Gate", "The Stone Bridges", "Wind Arches"], "what": "great arches of red stone in the desert",
		"souvenir": "souv_arches", "events": {"sunset": ["the sun setting through the arches", "dusk", 4.0, false], "stars": ["the stars over the arches", "night", 3.0, false],
			"dust": ["a dust devil crossing the plain", "day", 2.0, false], "storm": ["a sandstorm wall on the horizon", "day", 0.7, true]}},
	"lava": {"names": ["The Fire Terraces", "Ember Falls", "The Burning Steps", "Magma Fields"], "what": "terraces of glowing lava under a platform",
		"souvenir": "souv_lava", "events": {"flow": ["fresh lava running down the terraces", "any", 4.0, false], "glow": ["the lava glowing in the dark", "night", 3.0, false],
			"fountain": ["a lava fountain bursting up", "any", 0.8, true]}},
	"skyring": {"names": ["The Skyring Deck"], "what": "the observation deck on the cloud city's outer ring, over the giant's clouds",
		"souvenir": "souv_cloud", "events": {"glory": ["a glory – rings of colour round the city's shadow on the clouds", "day", 3.0, false],
			"lightning": ["lightning storms flickering deep in the clouds", "night", 4.0, false], "sunset": ["the star going down into the cloud tops", "dusk", 3.0, false],
			"moon": ["moonlight silver on the cloud tops", "night", 2.0, false], "floaters": ["a shoal of sky floaters drifting past", "day", 0.7, true]}},
	# 54c (Luz): the capitals' own places as sights – the Plaza of the Vote before the Senate, the Hierarch's palace
	"senate": {"names": ["The Plaza of the Vote"], "what": "the plaza before the Senate of the Assembly in Neo Kallipolis",
		"souvenir": "souv_senate", "events": {"session": ["the session letting out – senators coming down the steps", "day", 4.0, false],
			"demo": ["a demonstration crossing the plaza, banners high", "day", 2.0, false], "flag": ["the Assembly's flag lowered at dusk", "dusk", 3.0, false],
			"lights": ["the Senate's front lit blue in the night", "night", 4.0, false], "drones": ["a drone show over the plaza – the founders in light", "night", 0.7, true]}},
	"palace": {"names": ["The Palace of the Hierarch"], "what": "the forecourt of the Hierarch's palace in Aureola, over the red clouds of Compline",
		"souvenir": "souv_palace", "events": {"guard": ["the changing of the Hierarch's guard", "day", 4.0, false],
			"pilgrims": ["pilgrims kneeling on the sun mosaic", "day", 3.0, false], "sunset": ["the star going down red into the clouds", "dusk", 3.0, false],
			"vigil": ["a vigil of candles on the forecourt", "night", 4.0, false], "procession": ["the Hierarch's procession to the portal", "any", 0.6, true]}},
	# 54c (Luz): the Mirror Front on Curie – the edge of the terraforming, the orbital mirrors' beams on the new fields
	"mirror": {"names": ["The Mirror Front"], "what": "a terrace on the ridge where Curie's new green meets the old desert, under the orbital mirrors",
		"souvenir": "souv_mirror", "events": {"beams": ["the mirrors' beams sweeping over the fields", "day", 4.0, false],
			"drones": ["a swarm of seed drones sowing the front", "day", 2.0, false], "sunset": ["the long shadows of the towers over the sand", "dusk", 3.0, false],
			"stars": ["the mirrors crossing the night sky like slow stars", "night", 4.0, false], "rain": ["the first rain falling on the new fields", "any", 0.6, true]}},
	# 54c (Luz): the special stations' rooms as sights – The Vote's gallery over the drone shaft
	"vote": {"names": ["The Vote"], "what": "the gallery over The Vote's drone shaft, where the Assembly's ballots fly",
		"souvenir": "souv_vote", "events": {"stream": ["the ballot drones streaming up to the relays", "any", 4.0, false],
			"surge": ["a vote closing – a swarm of drones bursting up the shaft", "any", 1.5, false], "pulse": ["the beam flaring as a result goes out", "any", 2.0, false],
			"quiet": ["a quiet hour, the shaft's lights reflected in the glass", "any", 2.0, false], "all": ["every system reporting at once", "any", 0.5, true]}},
	"nave": {"names": ["The Cathedral of Return"], "what": "the nave of the Cathedral of Return, the Pilgrim Gate in its great window",
		"souvenir": "souv_nave", "events": {"mass": ["a mass at the altar, the faithful kneeling", "any", 4.0, false],
			"choir": ["the choir singing the Song of Return", "any", 3.0, false], "jump": ["a pilgrim ship jumping through the gate", "any", 2.0, false],
			"pilgrims": ["a new ship of pilgrims arriving, filling the pews", "any", 2.0, false], "lightfall": ["the gate's light falling bright through the window", "any", 0.6, true]}},
	"crater": {"names": ["The Great Crater", "Rimview", "Hollow Peak", "The Old Scar"], "what": "the rim of a great crater, the sky black above",
		"souvenir": "souv_crater", "events": {"rise": ["the planet rising over the rim", "any", 3.0, false], "stars": ["the star field over the crater", "night", 3.0, false],
			"shadow": ["the long shadows across the crater floor", "dusk", 2.0, false], "meteor": ["a meteor shower", "night", 0.6, true]}},
}
