class_name Weather
extends RefCounted
## Package 54e (Luz): dynamic weather – for now only to look at (no effect on sight, the suit or stealth). Each region of
## a world has its own: a deterministic spell per region and stretch of play time (SPELL seconds), drawn from what the
## world's type allows – rain and thunderstorms on green worlds, snow and blizzards on ice, sandstorms in the desert,
## ash on lava worlds, acid rain on toxic ones, nothing where there is no air. Over a gas giant the cloud cities get the
## giant's own gas whipping across the deck, with lightning (Luz). The planet map hints at it (an icon per place).

const SPELL := 360.0                 # how long a spell of weather lasts (seconds of play)
const RAMP := 40.0                   # how long it takes to set in or clear

## Per world type: [kind, weight] – what can come.
const TABLE := {
	"green": [["clear", 5.0], ["cloudy", 3.0], ["rain", 3.0], ["storm", 1.4], ["fog", 1.2]],
	"ice": [["clear", 4.0], ["cloudy", 2.0], ["snow", 3.0], ["blizzard", 1.5]],
	"desert": [["clear", 6.0], ["dust", 2.5], ["sandstorm", 1.5]],
	"lava": [["clear", 3.0], ["ash", 3.0]],
	"toxic": [["cloudy", 3.0], ["acid", 3.0], ["fog", 1.5]],
	"cloud": [["clear", 4.0], ["gaswind", 3.0], ["gasstorm", 2.0]],
}
const TYPE_KIND := {"terran": "green", "ocean": "green", "jungle": "green", "ice": "ice",
	"desert": "desert", "lava": "lava", "toxic": "toxic"}

## What each looks like in words and as the map's icon.
const NAMES := {"clear": ["Clear", "☀"], "cloudy": ["Overcast", "☁"], "rain": ["Rain", "🌧"], "storm": ["Thunderstorm", "⛈"],
	"fog": ["Fog", "🌫"], "snow": ["Snow", "🌨"], "blizzard": ["Blizzard", "❄"], "dust": ["Dust haze", "🌫"],
	"sandstorm": ["Sandstorm", "🌪"], "ash": ["Ash fall", "🌋"], "acid": ["Acid rain", "☣"],
	"gaswind": ["Gas winds", "💨"], "gasstorm": ["Gas storm", "⛈"]}

## Kinds people put up their holo umbrellas for (Luz: when it rains or there is a thunderstorm – a gas storm too).
const WET := ["rain", "storm", "acid", "gasstorm"]

static var debug_kind := ""          # the debug menu's override ("" – the world's own)


## The world's weather class ("" – no weather: no air).
static func world_class(body: Dictionary, cloud: bool = false) -> String:
	if cloud:
		return "cloud"
	var t := String(body.get("type", ""))
	if bool(body.get("terraform", false)):
		return "green"
	if TYPE_KIND.has(t) and Universe.has_atmosphere(body):
		return String(TYPE_KIND[t])
	return ""


## The region a place lies in – places close together share their weather.
static func region(body: Dictionary, place: Dictionary) -> String:
	var lon := float(place.get("lon", 0.0))
	var lat := float(place.get("lat", 0.0))
	return "%s:%d:%d" % [String(body.get("name", "")), int(floor(lon * 1.6)), int(floor(lat * 1.6))]


static func _pick(cls: String, key: String, spell: int) -> String:
	var tab: Array = TABLE.get(cls, [])
	if tab.is_empty():
		return "clear"
	var tot := 0.0
	for e in tab:
		tot += float(e[1])
	var rng := RandomNumberGenerator.new()                 # well mixed: neighbouring spells differ
	rng.seed = hash(key) * 1000003 + spell * 7919
	rng.randf()
	var r := rng.randf() * tot
	for e2 in tab:
		r -= float(e2[1])
		if r <= 0.0:
			return String(e2[0])
	return String(tab[0][0])


## The weather now: {kind, k (0 … 1, how strong), name, icon, cls}. `t` – play time (default: now).
static func at(body: Dictionary, place: Dictionary, cloud: bool = false, t: float = -1.0) -> Dictionary:
	var cls := world_class(body, cloud)
	if cls == "":
		return {"kind": "clear", "k": 0.0, "name": "", "icon": "", "cls": ""}
	if t < 0.0:
		t = GameState.play_time
	var key := region(body, place) if not cloud else String(place.get("id", body.get("name", "")))
	var spell := int(floor(t / SPELL))
	var kind := _pick(cls, key, spell)
	var k := 1.0
	var into := t - spell * SPELL
	if into < RAMP and _pick(cls, key, spell - 1) != kind:
		k = into / RAMP
	elif into > SPELL - RAMP and _pick(cls, key, spell + 1) != kind:
		k = (SPELL - into) / RAMP
	if debug_kind != "":
		kind = debug_kind
		k = 1.0
	if kind == "clear":
		k = 0.0
	var nm: Array = NAMES.get(kind, ["", ""])
	return {"kind": kind, "k": clampf(k, 0.0, 1.0), "name": String(nm[0]), "icon": String(nm[1]), "cls": cls}


## Is it raining (or worse) – people put their umbrellas up.
static func wet(w: Dictionary) -> bool:
	return WET.has(String(w.get("kind", ""))) and float(w.get("k", 0.0)) > 0.35
