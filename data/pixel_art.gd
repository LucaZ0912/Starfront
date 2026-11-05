extends RefCounted
## Ship pixel art. Every ship faces RIGHT.
## Only the TOP half including the centre row is drawn – the bottom half is mirrored
## automatically and shaded darker. The outline is generated automatically.
##
## Chars:  . empty   h hull   H hull light   d hull dark   D very dark
##         a faction colour   c/C cockpit   e nozzle   f engine glow
##         w weapon   g gun barrel   y light yellow   r light red   m mining gear
##         k/K cargo container   s/S solar panel

const SHIPS := {
	# Scout corvette – slim, swept wings
	"dragonfly": [
		"......a...........",
		".....hha..........",
		"....dhhhH.........",
		"...ddhhhhH........",
		"fe..dhhhhhH.......",
		"fedddhhhhhhhHH....",
		"fedhhhhhhhhhhhccC.",
		"fedhhhhaahhhhhhcCH",
	],
	# Fighter corvette – forward-swept wings with guns
	"hornet": [
		"...........wgggg....",
		"..aa......dhhH......",
		"..dhH....dhhhh......",
		"...dhhH.dhhhhh......",
		"....dhhhhhhhH.......",
		"ffeedhhhhhhhhHH.....",
		"ffedhhhhhhhhhhhccC..",
		"ffedhhaahhhhhhhhcCHw",
	],
	# Pirate raider – jagged spiked wings
	"crow": [
		"dh................",
		".dhh.......wggg...",
		"..dhhH....dhhh....",
		"...dhhhhhhhhh.....",
		"fe..dhhhhhhhhH....",
		"fedddhhhhaahhhhcC.",
		"fedhhhhhhaahhhhhcw",
	],
	# Passenger shuttle – small, round-nosed, a stripe of windows (phase 0.5 package 11)
	# Drone – a tiny disc with a sensor eye
	"drone": [
		"..aa...",
		"edhhhc.",
		"edhhhCc",
	],
	"shuttle": [
		"....aa........",
		"...dhhhH......",
		"fe.dhhhhhH....",
		"fedhhyhyhyhcC.",
		"fedhhhhhhhhhcCH",
	],
	# Bulk freighter – long spine with three container stacks
	"freighter": [
		"......kKkKkKkK..kKkKkKkK..kKkKkKkK..............",
		"......kkkkkkkk..kkkkkkkk..kkkkkkkk..............",
		"......kKkKkKkK..kKkKkKkK..kKkKkKkK..............",
		"......dd....dd..dd....dd..dd....dd..............",
		"ffe..dhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhH..........",
		"ffeedhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhH........",
		"ffeedhhhaaaaaahhhhhhhhhhhhhhhhhhhhhhhhhhhH......",
		"ffeddhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhcC...",
		"ffedhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccC..",
		"ffedhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccCy",
	],
	# Hauler – boxy with container modules
	"mule": [
		"...kKkKkKkKkKkK...............",
		"...kkkkkkkkkkkk...............",
		"...kKkKkKkKkKkK...............",
		"..dhhhhhhhhhhhhhhH............",
		"ffeddhhhhhhhhhhhhhhH..........",
		"ffeddhhhhhhhhhhhhhhhhH........",
		"ffedhhhaaaahhhhhhhhhhhhH......",
		"ffedhhhhhhhhhhhhhhhhhhhhhcC...",
		"ffedhhhhhhhhhhhhhhhhhhhhhccCH.",
		"ffedhhhhhhhhhhhhhhhhhhhhhhccCy",
	],
	# Mining frigate – drill heads at the front, ore bunker amidships
	"drillhead": [
		"...aa.....................",
		"..dhhh...............mm...",
		"..dhhhH...........dhmmmm..",
		"...dhhhH........dhhhmmmmmy",
		"ffeedhhhhHHHHhhhhhhhh.....",
		"ffeddhhhhhhhhhhhhhhhhH....",
		"ffedhhhhhhhhhhhhhhhhhhcC..",
		"ffedhhhhhkkkkkhhhhhhhhccC.",
		"ffedhhhhhkKKKkhhhhhhhhhcCm",
		"ffedhhhhhkkkkkhhhhhhhhhhCm",
	],
	# Combat frigate – angular with turrets
	"warden": [
		"..aaa.......................",
		"..dhhH......................",
		"..dhhhH.......ww............",
		"...dhhhH....dhhhgggggg......",
		"....dhhhhHHhhhhh............",
		"ffeeddhhhhhhhhhhhHH.........",
		"ffeddhhhhhhhhhhhhhhhH.......",
		"ffedhhhhaaaaahhhhhhhhhH.....",
		"ffedhhhhhhhhhhhhhhhhhhhhcC..",
		"ffedhhhhhhhwwhhhhhhhhhhhccCH",
		"ffedhhhhhhwggggggghhhhhhhccC",
	],
	# Heavy cruiser – long, several gun batteries
	"bastion": [
		"....aaaa..............................",
		"....dhhhH.............................",
		"....dhhhhH............................",
		"....ddhhhhH...........ww..............",
		".....ddhhhhH.......dhhhhgggggggg......",
		"......dhhhhhHHHHHhhhhhhh..............",
		"fffeeedhhhhhhhhhhhhhhhhhH.............",
		"fffeeddhhhhhhhhhhhhhhhhhhhHH..........",
		"fffeddhhhhhhaaaaaaaahhhhhhhhhH........",
		"fffedhhhhhhhhhhhhhhhhhhhhhhhhhhH......",
		"fffedhhhhhhwwhhhhhhhhwwhhhhhhhhhhH....",
		"fffedhhhhhwggggggghhwgggggggghhhhhhcC.",
		"fffedhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhccC",
		"fffedhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhcC",
		"fffedhhhhyhhhhhhhhhyhhhhhhhhhhhhhhhhhC",
	],
}
