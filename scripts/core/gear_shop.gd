class_name GearShop
extends RefCounted
## Package 51 (0.7.51.2): what a Gear shop (the personal outfitter) carries – by the place and its economy, like the
## ship outfitter: the best quality by Economy.max_quality (C at small places; B and A at bigger stations, in high-tech
## and rich systems, A in military ones); combat suits and heavy weapons in military systems and at the bigger
## stations; a settlement carries the plain things (civilian, work and survey suits, sidearms, tools, consumables).
## Grenades and consumables are always there. Laid out once per station (seeded by its id).

const GearData = preload("res://data/gear.gd")
const SMALL_SUITS := ["suit_civil", "suit_work", "suit_survey"]
const SMALL_WEAPONS := ["wp_pistol", "wp_laser_pistol", "wp_shotgun"]
const HEAVY_WEAPONS := ["wp_sniper", "wp_launcher", "wp_beam"]
const SELL_SHARE := 0.5               # what the shop pays for used gear


## {family: [qualities]} for the pieces with a quality, plus the plain belt items: {family: [""]}.
static func offer(st: Dictionary) -> Dictionary:
	if st.has("_gear_offer"):
		return st["_gear_offer"]
	var sid := -1
	if String(st.get("id", "")).begins_with("land:"):
		sid = GameState.current_system                   # a city or settlement: the system you are in
	elif not st.is_empty():
		sid = Market.system_of(st)
	var qmax := 3
	if not st.is_empty():
		qmax = Economy.max_quality(st, sid) if st.has("tier") else 3
	var small := bool(st.get("settlement", false))
	var tier := int(st.get("tier", 1))
	var military := false
	if sid >= 0:
		var ec := Economy.of(sid)
		military = ec.get("main", "") == "military" or ec.get("second", "") == "military"
	military = military or String(st.get("type", "")) == "military"
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(st.get("id", "gear"))) + 51
	var out := {}
	var land := String(st.get("faction", ""))
	if land == "" and sid >= 0 and sid < Universe.systems.size():
		land = String(Universe.systems[sid].get("faction", ""))
	for f in GearData.SUITS:
		if small and not f in SMALL_SUITS:
			continue
		var own := String(GearData.SUITS[f].get("faction", ""))          # 0.7.52.14: a power's own armour
		if own != "" and (own != land or not (military or tier >= 2 or bool(st.get("city", false)))):
			continue
		if f == "suit_mil_heavy" and not military:
			continue
		if f == "suit_mil_light" and not (military or tier >= 2 or bool(st.get("city", false))):
			continue
		out[f] = _qualities(rng, qmax)
	for w in GearData.WEAPONS:
		if bool(GearData.WEAPONS[w].get("builtin", false)):
			continue
		if small and not w in SMALL_WEAPONS:
			continue
		if w in HEAVY_WEAPONS and not (military or tier >= 3):
			continue
		if rng.randf() < 0.2 and not w in SMALL_WEAPONS:
			continue                                         # not every shop has everything
		out[w] = _qualities(rng, qmax)
	for ft in GearData.FEATURES:
		if small and not ft in ["ft_thermo", "ft_o2", "ft_battery"]:
			continue
		if rng.randf() < 0.25:
			continue
		out[ft] = _qualities(rng, qmax)
	for dr in GearData.DRONES:                            # 0.7.52.11: drones where combat suits are sold
		if small or not (military or tier >= 2 or bool(st.get("city", false))):
			continue
		out[dr] = _qualities(rng, qmax)
	for b in GearData.BELT:
		if String(GearData.BELT[b]["kind"]) == "tool":
			out[b] = _qualities(rng, qmax)
		elif b in ["gr_frag", "gr_emp", "gr_shield"] and small and not military:
			continue                                         # no war gear at an outpost's counter
		else:
			out[b] = [""]
	st["_gear_offer"] = out
	return out


## A run of qualities up to the best (some shops start higher, none skips the plain ones entirely).
static func _qualities(rng: RandomNumberGenerator, qmax: int) -> Array:
	var lo := rng.randi_range(0, mini(2, qmax))
	var out: Array = []
	for i in range(lo, qmax + 1):
		out.append(GearData.QUALITIES[i])
	return out


static func id_of(family: String, q: String) -> String:
	return family if q == "" else "%s:%s" % [family, q]


static func sells(st: Dictionary, id: String) -> bool:
	var o := offer(st)
	var f := GearData.family(id)
	return o.has(f) and GearData.quality(id) in (o[f] as Array)
