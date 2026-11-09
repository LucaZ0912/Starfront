class_name Market
extends RefCounted
## Wirtschaft 2.0, package 42b: station markets with real stocks.
## Every good has a role at a station – made here (the station's type, or the system's main or secondary economy;
## ores only where the system's fields hold them, gases only where a giant gives them), wanted here (the station's
## type, the economies that need it, luxuries in wealthy systems, basic needs everywhere) or neutral. Each has a
## stock that drifts back to its level over game time: made goods fill up, wanted goods are used up, neutral goods
## are carried off. The price follows the stock – selling a hold full of anything pushes its price down.
## Only stocks that were traded are kept (GameState.market_stock: station id -> {good: [stock, play time]}).

const CommodityData = preload("res://data/commodities.gd")

const RELAX := 1800.0                    # seconds of game time for a stock to go most of the way back (e-folding)
const M0 := {"produce": 0.78, "consume": 1.7, "neutral": 1.15}      # price level by role (× the good's price)
const SPREAD := 0.82                     # what the station pays of what it asks
const SWING := 0.5                       # how hard the stock moves the price
const ROLE_NAMES := {"produce": "made here", "consume": "wanted here", "neutral": ""}

static var _info_cache := {}             # "station|level" -> {good: info}


# ---------------------------------------------------------------- What a good is

static func econ_of(cid: String) -> String:
	var c: Dictionary = GameData.commodities.get(cid, {})
	if c.has("econ"):
		return String(c["econ"])
	if CommodityData.OLD_GOODS_ECON.has(cid):
		return String(CommodityData.OLD_GOODS_ECON[cid][0])
	if CommodityData.COMPONENT_ECON.has(cid):
		return String(CommodityData.COMPONENT_ECON[cid][0])
	match String(c.get("category", "")):
		"ore", "gas":
			return "mining"
		"refined":
			return "refinery"
	return ""


static func wants_of(cid: String) -> Array:
	var c: Dictionary = GameData.commodities.get(cid, {})
	if c.has("wants"):
		return c["wants"]
	if CommodityData.RAW_WANTS.has(cid):
		return CommodityData.RAW_WANTS[cid]
	if CommodityData.OLD_GOODS_ECON.has(cid):
		return CommodityData.OLD_GOODS_ECON[cid][1]
	if CommodityData.COMPONENT_ECON.has(cid):
		return CommodityData.COMPONENT_ECON[cid][1]
	match String(c.get("category", "")):
		"ore":
			return ["refinery"]
		"gas":
			return ["chemistry", "industry"]
		"refined":
			return ["industry", "hightech"]
	return []


static func is_flag(cid: String, flag: String) -> bool:
	var c: Dictionary = GameData.commodities.get(cid, {})
	if c.has(flag):
		return bool(c[flag])
	if CommodityData.OLD_GOODS_ECON.has(cid):
		return bool(CommodityData.OLD_GOODS_ECON[cid][2].get(flag, false))
	return false


## The market category of a good (CommodityData.MARKET_CATEGORIES) – "" for munitions and the like.
static func category_of(cid: String) -> String:
	if CommodityData.GOODS_CATEGORY.has(cid):
		return String(CommodityData.GOODS_CATEGORY[cid])
	var c: Dictionary = GameData.commodities.get(cid, {})
	match String(c.get("category", "")):
		"ore":
			return "ices" if String(c.get("class", "")) == "icy" else "ores"
		"gas":
			return "gases"
		"components":
			return "components"
		"refined":
			return "metals"
	return ""


static func category_name(cat: String) -> String:
	for c in CommodityData.MARKET_CATEGORIES:
		if c[0] == cat:
			return String(c[1])
	return cat.capitalize()


## Goods of the market (munitions go to the Munitions Depot – package 42b).
static func on_market(cid: String) -> bool:
	return GameData.is_tradeable(cid) and String(GameData.commodities[cid].get("category", "")) != "munitions"


## The economy a good belongs to in the market's filters ("" = raw materials and the rest).
static func sector_of(cid: String) -> String:
	var cat := String(GameData.commodities.get(cid, {}).get("category", ""))
	if cat in ["ore", "gas", "refined"]:
		return ""
	return econ_of(cid)


static func system_of(station: Dictionary) -> int:
	var parts := String(station.get("id", "")).split("_")
	return int(parts[1]) if parts.size() > 1 else GameState.current_system


# ---------------------------------------------------------------- Role, level and stock

## {role, target, eq} of a good at a station (cached per station and prosperity level).
static func info(station: Dictionary, cid: String) -> Dictionary:
	var sid := system_of(station)
	var lv := Economy.level(sid)
	var key := "%s|%d|%d" % [String(station["id"]), lv, Universe.seed_value]
	if not _info_cache.has(key):
		_info_cache[key] = {}
	var cache: Dictionary = _info_cache[key]
	if not cache.has(cid):
		cache[cid] = _make_info(station, sid, lv, cid)
	return cache[cid]


static func clear_cache() -> void:
	_info_cache.clear()


static func _h(station: Dictionary, cid: String, salt: String) -> float:
	return float(hash([String(station["id"]), cid, salt, Universe.seed_value]) % 10000) / 10000.0


static func role(station: Dictionary, cid: String) -> String:
	return String(info(station, cid)["role"])


static func _role(station: Dictionary, sid: int, lv: int, cid: String) -> String:
	var t: Dictionary = GameData.station_types.get(String(station["type"]), {})
	if cid in t.get("produces", []):
		return "produce"
	if cid in t.get("consumes", []):
		return "consume"
	if String(station["type"]) == "pirate_haven":
		return "neutral"                     # the pirates' own trade only
	var c: Dictionary = GameData.commodities[cid]
	var cat := String(c.get("category", ""))
	if cat in ["munitions", "loot", "data", "mission"]:
		return "neutral"
	var ec := Economy.of(sid)
	var m := String(ec["main"])
	var s := String(ec["second"])
	var e := econ_of(cid)
	var made := false
	if cat == "ore":
		made = (m == "mining" or s == "mining") and _system_ores(sid).has(cid) and not c.get("deep", false)
	elif cat == "gas":
		made = (m == "mining" or s == "mining") and _system_gases(sid).has(cid)
	elif e != "":
		made = e == m or (e == s and _h(station, cid, "second") < 0.6)
	if made:
		return "produce"
	var w := wants_of(cid)
	if m in w or (s in w and not cat in ["ore", "gas", "refined"]):
		return "consume"                     # raw materials are wanted by the main economy only
	if is_flag(cid, "lux") and lv >= 3:
		return "consume"
	if is_flag(cid, "basic") and lv >= 1:
		return "consume"
	return "neutral"


static func _system_ores(sid: int) -> Dictionary:
	var out := {}
	for f in Universe.get_layout(sid)["fields"]:
		for o in f.get("ores", []):
			out[o] = true
	return out


static func _system_gases(sid: int) -> Dictionary:
	var out := {}
	for p in Universe.get_layout(sid)["planets"]:
		for g in Universe.GAS_YIELDS.get(String(p["type"]), {}):
			out[g] = true
	return out


static func _make_info(station: Dictionary, sid: int, lv: int, cid: String) -> Dictionary:
	var r := _role(station, sid, lv, cid)
	var price := maxf(float(GameData.commodities[cid]["price"]), 1.0)
	var tier := float(station.get("tier", 1))
	var base := clampf(600.0 / sqrt(price), 6.0, 300.0) * (0.5 + 0.5 * tier)     # dear goods: fewer units, but not a handful
	var pros := 0.6 + 0.2 * lv
	var target := base * pros
	var eq := target
	match r:
		"consume":
			target = base * pros * 0.8
			eq = target * 0.25
		"neutral":
			target = base * 0.6
			eq = 0.0
	return {"role": r, "target": maxf(target, 1.0), "eq": eq, "level": lv}


## The stock of a good at a station now (it drifts back to its level over game time).
static func stock(station: Dictionary, cid: String) -> float:
	var inf := info(station, cid)
	var eq := float(inf["eq"])
	var st: Dictionary = GameState.market_stock.get(String(station["id"]), {})
	if st.has(cid):
		var rec: Array = st[cid]
		var dt := maxf(0.0, GameState.play_time - float(rec[1]))
		return eq + (float(rec[0]) - eq) * exp(-dt / RELAX)
	# never traded: around its level (a neutral good now and then in stock too)
	var hv := _h(station, cid, "stock")
	match String(inf["role"]):
		"produce":
			return eq * (0.75 + 0.5 * hv)
		"consume":
			return eq * (0.5 + hv)
	return float(inf["target"]) * 0.6 if hv < 0.12 else 0.0


static func set_stock(station: Dictionary, cid: String, v: float) -> void:
	var id := String(station["id"])
	if not GameState.market_stock.has(id):
		GameState.market_stock[id] = {}
	GameState.market_stock[id][cid] = [maxf(v, 0.0), GameState.play_time]


# ---------------------------------------------------------------- Prices

## The price factor at a given stock (× the good's price).
static func mult(station: Dictionary, cid: String, at_stock: float) -> float:
	var inf := info(station, cid)
	var t := float(inf["target"])
	var f := 1.0
	if inf["role"] == "neutral":
		f = clampf(1.0 - SWING * at_stock / t, 0.5, 1.0)
	else:
		f = clampf(1.0 + SWING * (float(inf["eq"]) - at_stock) / t, 0.5, 1.5)
	return float(M0[inf["role"]]) * f * (0.9 + 0.05 * int(inf["level"]))


## What the station asks per unit now (-1 = nothing in stock / not traded).
static func buy_price(station: Dictionary, cid: String) -> int:
	if not on_market(cid) or stock(station, cid) < 1.0:
		return -1
	return maxi(int(round(float(GameData.commodities[cid]["price"]) * mult(station, cid, stock(station, cid)))), 1)


## What the station pays per unit now.
static func sell_price(station: Dictionary, cid: String) -> float:
	if not on_market(cid):
		return 0.0
	return float(GameData.commodities[cid]["price"]) * mult(station, cid, stock(station, cid)) * SPREAD


## The whole price of buying `n` (the stock falls while you buy – priced at the middle).
static func quote_buy(station: Dictionary, cid: String, n: float) -> int:
	var s0 := stock(station, cid)
	return maxi(int(round(float(GameData.commodities[cid]["price"]) * mult(station, cid, s0 - n * 0.5) * n)), 1)


## The whole pay for selling `n` (the stock rises while you sell).
static func quote_sell(station: Dictionary, cid: String, n: float) -> float:
	var s0 := stock(station, cid)
	return float(GameData.commodities[cid]["price"]) * mult(station, cid, s0 + n * 0.5) * SPREAD * n


static func bought(station: Dictionary, cid: String, n: float) -> void:
	set_stock(station, cid, stock(station, cid) - n)


static func sold(station: Dictionary, cid: String, n: float) -> void:
	set_stock(station, cid, stock(station, cid) + n)


## Writes the current prices into station["market"] (for everything that reads the old table).
static func sync(station: Dictionary) -> void:
	var mk: Dictionary = station.get("market", {})
	for cid in GameData.commodities:
		if not on_market(cid):
			mk.erase(cid)
			continue
		mk[cid] = {"buy": buy_price(station, cid), "sell": int(round(sell_price(station, cid)))}
	station["market"] = mk
