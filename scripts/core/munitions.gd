class_name Munitions
extends RefCounted
## Package 42b: the Munitions Depot (Obsidian Ordnance) – ammunition for every weapon that has to be restocked (so
## far the mine launchers' mines). Munitions are not traded on the market any more. What a depot stocks and what it
## charges follow the system's economy: military systems carry everything and sell it cheaply, industrial ones the
## common kinds, high-tech ones the electronic ones; pirate havens sell all of it, dearly.

## Munitions: the weapon family that fires them, and what a depot needs to stock them.
const AMMO := {
	"mine_proximity": {"for": "w_minelayer", "need": "common"},
	"mine_timer": {"for": "w_minelayer", "need": "common"},
	"mine_jammer": {"for": "w_minelayer", "need": "electronic"},
	"mine_emp": {"for": "w_minelayer", "need": "heavy"},
}
const BUYBACK := 0.5                     # the depot takes munitions back for half their price


## What a station's depot sells: {munition: unit price before standing} – empty = no depot.
static func offer(station: Dictionary) -> Dictionary:
	var out := {}
	var type := String(station.get("type", ""))
	if type == "waystation":
		return out
	var haven := type == "pirate_haven"
	var sid := Market.system_of(station)
	var ec := Economy.of(sid)
	var m := String(ec["main"])
	var s := String(ec["second"])
	var tier := int(station.get("tier", 1))
	var mil_main := m == "military"
	var mil := mil_main or s == "military" or type == "military"
	var ind := m == "industry" or s == "industry" or type == "shipyard"
	var tech := m == "hightech" or s == "hightech"
	for cid in AMMO:
		var ok := haven
		match String(AMMO[cid]["need"]):
			"common":
				ok = ok or mil or ind or tier >= 3
			"electronic":
				ok = ok or mil or tech
			"heavy":
				ok = ok or mil_main or (type == "military" and tier >= 2) or (tech and tier >= 3)
		if not ok:
			continue
		var k := 1.15
		if haven:
			k = 1.3
		elif mil_main:
			k = 0.8
		elif mil:
			k = 0.9
		elif ind:
			k = 1.0
		out[cid] = maxi(int(round(float(GameData.commodities[cid]["price"]) * k)), 1)
	return out


## The weapons of a ship that fire this munition (slot keys).
static func launchers(fit: ShipFitting, cid: String) -> Array:
	var out: Array = []
	var fam := String(AMMO.get(cid, {}).get("for", ""))
	for slot in fit.modules:
		var mid := String(fit.modules[slot])
		if mid != "" and GameData.modules.has(mid) and String(GameData.modules[mid].get("family", "")) == fam:
			out.append(slot)
	return out
