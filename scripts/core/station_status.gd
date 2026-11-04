extends RefCounted
## Stations knocked out by a pirate raid (phase 0.5 package 15, raid event).
## A raided station stays dockable but offline – no service works – for one hour, or until the
## relief goods it needs (amount by type and tier) have been delivered. Deliveries may come in
## any portion, so small ships can help too; each unit pays twice its base price, completing the
## relief pays a bonus and raises the standing with the station's faction.
## Owned by GameState (GameState.stations), saved with the pilot.

const FactionData = preload("res://data/factions.gd")

const DOWN_TIME := 3600.0
const PRICE_MULT := 2.0
const BONUS_PER_TIER := 5000
const REP_BONUS := 6.0
## extra relief good by station type (alloys and electronics are always needed)
const EXTRA := {"trade": "food", "industry": "iron_ingot", "mining_colony": "medicine", "agri": "water",
	"research": "medicine", "ice_refinery": "cryo_coolant", "shipyard": "titanium_ingot"}

var down := {}                  # station id -> {system, name, type, tier, faction, until, need {item: n}, got {item: n}}


func reset() -> void:
	down.clear()


func to_dict() -> Dictionary:
	return down.duplicate(true)


func from_dict(d: Dictionary) -> void:
	down = d.duplicate(true)


static func relief_needs(st: Dictionary) -> Dictionary:
	var tier := int(st.get("tier", 1))
	var need := {"alloys": 20 * tier, "electronics": 12 * tier}
	var extra := String(EXTRA.get(String(st.get("type", "")), "food"))
	need[extra] = int(need.get(extra, 0)) + 25 * tier
	return need


func knock_out(st: Dictionary, sid: int) -> void:
	down[st["id"]] = {"system": sid, "name": st["name"], "type": st["type"], "tier": int(st.get("tier", 1)),
		"faction": String(st.get("faction", "")), "until": GameState.play_time + DOWN_TIME,
		"need": relief_needs(st), "got": {}}


## Entry of a station that is offline right now ({} = working). Expired entries are cleared.
func status(st_id: String) -> Dictionary:
	if not down.has(st_id):
		return {}
	var e: Dictionary = down[st_id]
	if GameState.play_time >= float(e["until"]):
		down.erase(st_id)
		GameState.news.add("%s is back online – its crews finished the repairs." % e["name"], "world", int(e["system"]))
		return {}
	return e


func is_down(st_id: String) -> bool:
	return not status(st_id).is_empty()


## Reason why services do not work at this station ("" = they do).
func down_error(st: Dictionary) -> String:
	var e := status(String(st.get("id", "")))
	if e.is_empty():
		return ""
	return "%s is offline after a pirate raid (%d min left) – only relief deliveries are accepted." % [e["name"], int(ceil((float(e["until"]) - GameState.play_time) / 60.0))]


func missing(st_id: String, item: String) -> int:
	var e := status(st_id)
	if e.is_empty():
		return 0
	return maxi(0, int(e["need"].get(item, 0)) - int(e["got"].get(item, 0)))


static func unit_price(item: String) -> int:
	return int(round(float(GameData.commodities[item]["price"]) * PRICE_MULT))


## Delivers up to `amount` (-1 = all in the hold) of `item` from ship `f`. Returns the payout or -1.
func deliver(st_id: String, item: String, amount: int, f: ShipFitting) -> int:
	var e := status(st_id)
	if e.is_empty() or f == null:
		return -1
	var n := mini(missing(st_id, item), int(floor(float(f.cargo.get(item, 0.0)) + 0.001)))
	if amount >= 0:
		n = mini(n, amount)
	if n <= 0:
		return -1
	f.remove_cargo(item, float(n))
	e["got"][item] = int(e["got"].get(item, 0)) + n
	var pay := n * unit_price(item)
	GameState.add_credits(pay)
	GameState.log_msg("Relief delivery to %s: %d %s (+%s)." % [e["name"], n, GameData.item_name(item), GameData.fmt_credits(pay)], GameState.COL_GOOD)
	var done := true
	for k in e["need"]:
		done = done and int(e["got"].get(k, 0)) >= int(e["need"][k])
	if done:
		down.erase(st_id)
		var bonus := BONUS_PER_TIER * int(e["tier"])
		GameState.add_credits(bonus)
		GameState.log_msg("%s is back online thanks to your relief deliveries! Bonus %s." % [e["name"], GameData.fmt_credits(bonus)], GameState.COL_GOOD)
		GameState.news.add("%s is back online thanks to relief deliveries by %s." % [e["name"], GameState.pilot_name], "world", int(e["system"]))
		GameState.rep.change(String(e["faction"]), REP_BONUS, "you restored %s" % e["name"])
	return pay
