class_name CityStyle
extends RefCounted
## 0.7.50.6 (Luz): every power builds its cities its own way – four styles. And every city lies on the day or the
## night side of its world (where the planet map shows it), which sets its light.
##
## Independent: the cyberpunk sprawl – dark towers crowded together, neon of every colour, antennas, fire escapes.
## Assembly: a home, not a waiting room – light stone and glass, rounded tops and domes, terraces and roof gardens
##   full of green, warm windows, a few soft blue lights.
## Covenant: stone and faith – dark red-brown towers with pointed spires and buttresses, narrow gold-lit windows,
##   red banners, gold lamps; hardly any neon.
## Directorate: measured and clean – white towers on a strict grid, chamfered hexagonal crowns, even rows of cool
##   white windows, green light bands, solar roofs.

const STYLES := {
	"independent": {
		"name": "Independent", "night": Color(0.05, 0.06, 0.1), "day": Color(0.42, 0.44, 0.5),
		"roof": Color(0.17, 0.18, 0.23), "roof_day": Color(0.46, 0.47, 0.52),
		"win": [Color(1.0, 0.82, 0.5), Color(0.6, 0.85, 1.0)], "warm": 0.75,
		"neon": [Color(0.3, 0.95, 1.0), Color(1.0, 0.3, 0.72), Color(0.75, 0.45, 1.0), Color(1.0, 0.75, 0.3)], "neon_share": [0.1, 0.35, 0.5],
		"sign": "vertical", "crowns": ["antenna", "step", "flat"], "green": 0.12, "accent": Color(0.3, 0.95, 1.0),
		"facade": Color(0.2, 0.21, 0.27), "facade_day": Color(0.48, 0.47, 0.5), "lit": 0.42, "grid": false,
		"string": "lanterns", "escapes": true,
		"fronts": [["NOODLE BAR", Color(1.0, 0.75, 0.3)], ["CHROME & SOUL", Color(0.3, 0.95, 1.0)], ["PAWN", Color(1.0, 0.85, 0.3)],
			["HOTEL", Color(1.0, 0.3, 0.72)], ["PHARMACY", Color(0.4, 1.0, 0.55)], ["CYBERWARE", Color(0.75, 0.45, 1.0)],
			["KARAOKE", Color(1.0, 0.35, 0.6)], ["TEA HOUSE", Color(0.5, 1.0, 0.7)], ["ARCADE", Color(0.3, 0.8, 1.0)],
			["TAILOR", Color(1.0, 0.7, 0.5)], ["DUMPLINGS", Color(1.0, 0.55, 0.3)], ["BOOKS", Color(0.9, 0.85, 0.6)]],
	},
	"assembly": {
		"name": "Assembly", "night": Color(0.1, 0.13, 0.2), "day": Color(0.74, 0.77, 0.82),
		"roof": Color(0.26, 0.3, 0.36), "roof_day": Color(0.78, 0.8, 0.84),
		"win": [Color(1.0, 0.9, 0.7), Color(0.75, 0.88, 1.0)], "warm": 0.85,
		"neon": [Color(0.4, 0.68, 1.0), Color(0.95, 0.97, 1.0)], "neon_share": [0.04, 0.12, 0.2],
		"sign": "vertical", "crowns": ["dome", "terrace", "round"], "green": 0.65, "accent": Color(0.4, 0.68, 1.0),
		"facade": Color(0.34, 0.38, 0.46), "facade_day": Color(0.8, 0.8, 0.82), "lit": 0.5, "grid": false,
		"string": "bulbs",
		"fronts": [["CO-OP MARKET", Color(0.45, 0.9, 0.5)], ["COMMUNITY HALL", Color(0.4, 0.68, 1.0)], ["BAKERY", Color(1.0, 0.8, 0.45)],
			["GREENHOUSE", Color(0.45, 1.0, 0.55)], ["LIBRARY", Color(0.9, 0.85, 0.65)], ["CAFE", Color(1.0, 0.7, 0.45)],
			["VOTING BOOTH", Color(0.4, 0.68, 1.0)], ["FERRY TICKETS", Color(0.6, 0.85, 1.0)], ["FLOWERS", Color(1.0, 0.55, 0.7)],
			["TOOL LIBRARY", Color(1.0, 0.8, 0.3)], ["NOODLES", Color(1.0, 0.65, 0.35)], ["SCHOOL", Color(0.95, 0.95, 1.0)]],
	},
	"covenant": {
		"name": "Covenant", "night": Color(0.09, 0.05, 0.06), "day": Color(0.5, 0.38, 0.34),
		"roof": Color(0.24, 0.13, 0.13), "roof_day": Color(0.5, 0.33, 0.28),
		"win": [Color(1.0, 0.75, 0.35), Color(1.0, 0.55, 0.3)], "warm": 0.95,
		"neon": [Color(1.0, 0.8, 0.3), Color(0.9, 0.2, 0.22)], "neon_share": [0.0, 0.1, 0.18],
		"sign": "banner", "crowns": ["spire", "spire", "gothic"], "green": 0.05, "accent": Color(1.0, 0.8, 0.3),
		"facade": Color(0.26, 0.16, 0.15), "facade_day": Color(0.55, 0.42, 0.36), "lit": 0.3, "grid": false,
		"string": "pennants",
		"fronts": [["CHAPEL", Color(1.0, 0.8, 0.3)], ["RELIQUARY", Color(1.0, 0.7, 0.3)], ["PILGRIM HOSTEL", Color(0.95, 0.3, 0.3)],
			["CANDLES", Color(1.0, 0.85, 0.45)], ["ALMS HOUSE", Color(1.0, 0.75, 0.4)], ["SCRIPTORIUM", Color(0.95, 0.85, 0.6)],
			["ARMOURY", Color(0.95, 0.3, 0.25)], ["BREAD OF RETURN", Color(1.0, 0.75, 0.35)], ["ICONS", Color(1.0, 0.8, 0.3)],
			["HYMNALS", Color(0.95, 0.85, 0.6)], ["CONFESSION", Color(0.9, 0.25, 0.3)], ["SEXTON", Color(1.0, 0.7, 0.4)]],
	},
	"directorate": {
		"name": "Directorate", "night": Color(0.06, 0.09, 0.09), "day": Color(0.84, 0.87, 0.87),
		"roof": Color(0.2, 0.24, 0.24), "roof_day": Color(0.86, 0.88, 0.88),
		"win": [Color(0.88, 0.97, 1.0), Color(0.6, 1.0, 0.8)], "warm": 0.2,
		"neon": [Color(0.25, 0.85, 0.55), Color(0.85, 0.98, 1.0)], "neon_share": [0.1, 0.3, 0.45],
		"sign": "band", "crowns": ["hex", "flat", "hex"], "green": 0.3, "accent": Color(0.25, 0.85, 0.55),
		"facade": Color(0.26, 0.3, 0.31), "facade_day": Color(0.82, 0.85, 0.85), "lit": 0.55, "grid": true,
		"string": "holo",
		"fronts": [["INSTITUTE", Color(0.25, 0.85, 0.55)], ["CLINIC", Color(0.85, 0.98, 1.0)], ["EXAM HALL", Color(0.4, 0.9, 0.7)],
			["LAB SUPPLY", Color(0.6, 0.95, 1.0)], ["ARCHIVE", Color(0.85, 0.98, 1.0)], ["TERRAFORM CO.", Color(0.4, 1.0, 0.55)],
			["OPTICS", Color(0.6, 0.9, 1.0)], ["DATA CAFE", Color(0.25, 0.85, 0.55)], ["PHARMACY", Color(0.4, 1.0, 0.6)],
			["BRIDGE OFFICE", Color(0.5, 0.95, 0.8)], ["SURVEY", Color(0.85, 0.98, 1.0)], ["ROBOTICS", Color(0.6, 1.0, 0.8)]],
	},
}


## 0.7.50.7: indoors – the deck colours of a city's hangar, street and bar (floor, floor2, shop floor, wood, carpet,
## wall, accent), how its bar is furnished (like DeckGen.THEMES) and the flags in its hangar [cloth, sign].
const DECK := {
	"independent": {"pal": [Color(0.2, 0.21, 0.26), Color(0.24, 0.25, 0.3), Color(0.36, 0.32, 0.3), Color(0.3, 0.2, 0.16), Color(0.35, 0.12, 0.3), Color(0.5, 0.52, 0.6), Color(0.3, 0.95, 1.0)],
		"theme": {"bar": "lounge", "floor": 3, "corner": 4, "cor_floor": 0, "deco": ["holo_pillar", "plant"],
			"props": ["lamp_post", "holo", "vending", "holo", "trash"], "seat": Color(0.6, 0.15, 0.42)},
		"flag": [Color(0.06, 0.06, 0.09), Color(1.0, 0.3, 0.72)], "flag_kind": "poster"},
	"assembly": {"pal": [Color(0.58, 0.57, 0.53), Color(0.63, 0.62, 0.57), Color(0.68, 0.64, 0.56), Color(0.55, 0.4, 0.25), Color(0.28, 0.42, 0.34), Color(0.9, 0.88, 0.84), Color(0.4, 0.68, 1.0)],
		"theme": {"bar": "garden", "floor": 3, "corner": 8, "cor_floor": 6, "deco": ["planter", "plant"],
			"props": ["planter", "lamp_post", "flower_bed", "holo"], "seat": Color(0.35, 0.5, 0.75)},
		"flag": [Color(0.16, 0.32, 0.72), Color(0.95, 0.97, 1.0)], "flag_kind": "flag", "sign": "circle"},
	"covenant": {"pal": [Color(0.3, 0.22, 0.2), Color(0.34, 0.25, 0.22), Color(0.38, 0.3, 0.25), Color(0.35, 0.2, 0.12), Color(0.45, 0.08, 0.12), Color(0.56, 0.43, 0.37), Color(1.0, 0.8, 0.3)],
		"theme": {"bar": "mess", "floor": 4, "corner": 2, "cor_floor": 9, "deco": ["banner", "plant"],
			"props": ["banner", "lamp_post", "banner", "holo"], "seat": Color(0.5, 0.1, 0.14)},
		"flag": [Color(0.62, 0.08, 0.12), Color(1.0, 0.8, 0.3)], "flag_kind": "flag"},
	"directorate": {"pal": [Color(0.74, 0.78, 0.79), Color(0.8, 0.84, 0.84), Color(0.8, 0.83, 0.83), Color(0.6, 0.62, 0.62), Color(0.2, 0.4, 0.35), Color(0.93, 0.95, 0.95), Color(0.25, 0.85, 0.55)],
		"theme": {"bar": "cafe", "floor": 6, "corner": 4, "cor_floor": 6, "deco": ["holo_pillar", "plant"],
			"props": ["holo_pillar", "lamp_post", "plant", "holo"], "seat": Color(0.85, 0.9, 0.92)},
		"flag": [Color(0.1, 0.42, 0.3), Color(0.85, 0.9, 0.92)], "flag_kind": "flag", "sign": "diamond"},
}


## 0.7.50.9: the city guards – their uniform (main and accent colour of PilotArt.CLOTH), what they are called and
## what they say.
const GUARDS := {
	"independent": {"c1": 0, "c2": 13, "name": "Contract security",
		"lines": ["Contract security. Don't make me file a report.", "Keep it holstered, pilot – the city pays us to keep the peace.", "Trouble? Not on my street."]},
	"assembly": {"c1": 4, "c2": 3, "name": "City militia",
		"lines": ["Militia on duty – the city is safe, citizen.", "Weapons stay holstered in the city. The Assembly voted on it.", "Need directions? The lifts take you anywhere."]},
	"covenant": {"c1": 8, "c2": 10, "name": "Wardens of the Road",
		"lines": ["The road leads home. Walk it in peace.", "No blade, no gun drawn within these walls.", "The Hierarch's peace holds here, pilgrim."]},
	"directorate": {"c1": 3, "c2": 6, "name": "Civic order",
		"lines": ["Your permit is in order. Proceed.", "Discharging weapons inside the city is not permitted.", "Please keep to the marked walkways."]},
}


static func guards(st: Dictionary) -> Dictionary:
	return GUARDS[key_for(st)]


static func deck(st: Dictionary) -> Dictionary:
	return DECK[key_for(st)]


## The style of a city (a station dict with "city"): its power's, independent otherwise.
static func key_for(st: Dictionary) -> String:
	var f := String(st.get("faction", ""))
	return f if STYLES.has(f) else "independent"


static func of(st: Dictionary) -> Dictionary:
	return STYLES[key_for(st)]


## 0.7.50.7: the worlds turn – the sun goes round each one (a day of 20 to 40 minutes of play, each world its own
## length and hour), so the same city can be visited by day and by night. The light as the planet map shows it.
const LIGHT_A0 := 0.905                  # the angle at which the light comes from the upper left, in front


static func day_length(body: Dictionary) -> float:
	return 1200.0 + float(absi(hash(String(body.get("id", "")) + "day")) % 1200)


static func light_vec(body: Dictionary = {}, dt: float = 0.0) -> Vector3:
	if body.is_empty():
		return Vector3(-0.7, -0.5, 0.55).normalized()
	var ph := float(absi(hash(String(body.get("id", "")) + "sun")) % 1000) / 1000.0
	var a := LIGHT_A0 + TAU * fposmod((GameState.play_time + dt) / day_length(body) + ph, 1.0)
	return Vector3(-sin(a) * 0.86, -0.5, cos(a) * 0.86).normalized()


## How much daylight a site has (0 night … 1 day): where it lies on the planet's face and where the sun stands now.
static func daylight(site: Dictionary, body: Dictionary = {}, dt: float = 0.0) -> float:
	var lon := float(site.get("lon", 0.0))
	var lat := float(site.get("lat", 0.0))
	var n := Vector3(sin(lon) * cos(lat), -sin(lat), cos(lon) * cos(lat))
	return smoothstep(-0.12, 0.18, n.dot(light_vec(body, dt)))


## 0.7.50.8: is the sun coming up (true) or going down there?
static func rising(site: Dictionary, body: Dictionary) -> bool:
	var lon := float(site.get("lon", 0.0))
	var lat := float(site.get("lat", 0.0))
	var n := Vector3(sin(lon) * cos(lat), -sin(lat), cos(lon) * cos(lat))
	return n.dot(light_vec(body, 5.0)) > n.dot(light_vec(body))


## How much of dusk (or dawn) there is: 0 in full day or full night, 1 in the middle of the change.
static func dusk(day: float) -> float:
	return clampf(1.0 - absf(day * 2.0 - 1.0), 0.0, 1.0)


## The colour of the setting sun – the star's own light, reddened by the air.
static func sunset_color(star_col: Color) -> Color:
	return star_col.lerp(Color(1.0, 0.42, 0.16), 0.6)


static func star_color(sys_id: int) -> Color:
	if sys_id < 0:
		return Color(1.0, 0.85, 0.5)
	return Color(Universe.get_layout(sys_id)["star"].get("color", Color(1.0, 0.85, 0.5)))


## Minutes until the light changes at a site (sunrise or sunset) – for the planet map.
static func minutes_to_turn(site: Dictionary, body: Dictionary) -> int:
	var now := daylight(site, body) > 0.5
	var t0 := GameState.play_time
	var step := day_length(body) / 240.0
	for i in range(1, 241):
		GameState.play_time = t0 + step * i
		var d := daylight(site, body) > 0.5
		if d != now:
			GameState.play_time = t0
			return maxi(1, int(round(step * i / 60.0)))
	GameState.play_time = t0
	return -1


## A colour between the style's night and day tone: "tower", "roof" or "facade".
static func tone(style: Dictionary, key: String, day: float) -> Color:
	if key == "tower":
		return Color(style["night"]).lerp(Color(style["day"]), day)
	return Color(style[key]).lerp(Color(style[key + "_day"]), day)


## The sky over a city: top and horizon colours, by the world's air and the time of day.
static func sky(body: Dictionary, day: float, sunset: Color = Color(1.0, 0.45, 0.2)) -> Array:
	var bt := Universe.body_type(String(body.get("type", "")))
	var ac = bt.get("atmo", Color(0.5, 0.7, 1.0))
	var air: Color = ac if ac is Color else Color(0.5, 0.7, 1.0)
	air = Color(air.r, air.g, air.b)
	var n_top := Color(0.02, 0.025, 0.07).lerp(air, 0.08)
	var n_low := air.darkened(0.55).lerp(Color(1.0, 0.5, 0.3), 0.35)
	var d_top := air.darkened(0.15).lerp(Color(0.35, 0.55, 0.9), 0.3)
	var d_low := air.lightened(0.45).lerp(Color(1.0, 0.95, 0.85), 0.35)
	var dk := dusk(day)
	return [n_top.lerp(d_top, day).lerp(Color(0.32, 0.18, 0.4), dk * 0.45), n_low.lerp(d_low, day).lerp(sunset, dk * 0.85)]
