extends RefCounted
## Station services shown as tiles on the station concourse. Fully data-driven:
## add an entry here + a panel script to add a new service.
##   corp:      owning corporation (data/corporations.gd)
##   icon:      module icon key (data/module_icons.gd)
##   panel:     script of the service panel (scripts/ui/station/*)
##   requires:  "" = always available, "shipyard" / "refinery" / "manufacturing" = depends on station type
##   mode:      optional parameter handed to the panel

const SERVICES := [
	{"id": "market", "title": "Market", "corp": "kvx", "icon": "o_cargo",
		"panel": "res://scripts/ui/station/market_panel.gd", "requires": ""},
	{"id": "outfitter", "title": "Outfitter", "corp": "syn", "icon": "w_kinetic",
		"panel": "res://scripts/ui/station/outfitter_panel.gd", "requires": ""},
	{"id": "shipyard", "title": "Shipyard", "corp": "hoy", "icon": "hull",
		"panel": "res://scripts/ui/station/shipyard_panel.gd", "requires": "shipyard"},
	{"id": "refinery", "title": "Refinery", "corp": "cmc", "icon": "t_mining",
		"panel": "res://scripts/ui/station/refinery_panel.gd", "requires": "refinery"},
	{"id": "manufacturing", "title": "Manufacturing", "corp": "mlf", "icon": "distributor",
		"panel": "res://scripts/ui/station/manufacturing_panel.gd", "requires": "manufacturing"},
	# package 51: the personal outfitter – suits, weapons, tools for the pilot on foot
	{"id": "gear", "title": "Gear", "corp": "fkt", "icon": "o_armor",
		"panel": "res://scripts/ui/station/gear_panel.gd", "requires": ""},
	{"id": "bonds", "title": "Bond Office", "corp": "swx", "icon": "t_warrant",
		"panel": "res://scripts/ui/station/bond_panel.gd", "requires": ""},
	{"id": "bulletin", "title": "Bulletin Board", "corp": "blc", "icon": "t_analyzer",
		"panel": "res://scripts/ui/station/bulletin_panel.gd", "requires": ""},
	{"id": "news", "title": "News Archive", "corp": "lnn", "icon": "sensors",
		"panel": "res://scripts/ui/station/news_panel.gd", "requires": ""},
	{"id": "hangar", "title": "Hangar", "corp": "vlt", "icon": "o_armor",
		"panel": "res://scripts/ui/station/hangar_panel.gd", "requires": ""},
	{"id": "fuel", "title": "Fuel Depot", "corp": "pyre", "icon": "o_fuel",
		"panel": "res://scripts/ui/station/service_panel.gd", "requires": "", "mode": "fuel"},
	{"id": "drones", "title": "Drone Bay", "corp": "hwd", "icon": "drone",
		"panel": "res://scripts/ui/station/drone_panel.gd", "requires": ""},
	# package 42b: ammunition for the weapons that have to be restocked (mines) – stock follows the economy
	{"id": "munitions", "title": "Munitions Depot", "corp": "obx", "icon": "w_mines",
		"panel": "res://scripts/ui/station/munitions_panel.gd", "requires": "munitions"},
	{"id": "repair", "title": "Repair Bay", "corp": "mdx", "icon": "t_repair",
		"panel": "res://scripts/ui/station/service_panel.gd", "requires": "", "mode": "repair"},
	{"id": "look", "title": "Image Studio", "corp": "vsg", "icon": "face",
		"panel": "res://scripts/ui/station/look_panel.gd", "requires": ""},
	# package 31: hiring crew (part 7 makes the bar much more)
	{"id": "bar", "title": "The Bar", "corp": "dwt", "icon": "bar",
		"panel": "res://scripts/ui/station/bar_panel.gd", "requires": ""},
	# package 39a: only in The Vote (Landfall) – bills, votes, donations … and bribes
	{"id": "senate", "title": "The Senate", "corp": "sen", "icon": "senate",
		"panel": "res://scripts/ui/station/senate_panel.gd", "requires": "senate"},
	# package 39b: only in the Cathedral of Return (Heimkehr) – edicts, tithes, indulgences, relics
	{"id": "curia", "title": "The Curia", "corp": "cur", "icon": "curia",
		"panel": "res://scripts/ui/station/curia_panel.gd", "requires": "curia"},
	# package 39c: only in the Meridian Sphere (Durchbruch) – research data and exotic matter
	{"id": "exchange", "title": "Research Exchange", "corp": "rex", "icon": "t_analyzer",
		"panel": "res://scripts/ui/station/exchange_panel.gd", "requires": "exchange"},
]
