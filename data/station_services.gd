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
	{"id": "repair", "title": "Repair Bay", "corp": "mdx", "icon": "t_repair",
		"panel": "res://scripts/ui/station/service_panel.gd", "requires": "", "mode": "repair"},
]
