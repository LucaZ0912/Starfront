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
	"crater": {"names": ["The Great Crater", "Rimview", "Hollow Peak", "The Old Scar"], "what": "the rim of a great crater, the sky black above",
		"souvenir": "souv_crater", "events": {"rise": ["the planet rising over the rim", "any", 3.0, false], "stars": ["the star field over the crater", "night", 3.0, false],
			"shadow": ["the long shadows across the crater floor", "dusk", 2.0, false], "meteor": ["a meteor shower", "night", 0.6, true]}},
}
