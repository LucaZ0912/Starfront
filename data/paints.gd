extends RefCounted
## Package 61d (Luz, 22 Nov 2026): the paints of Second Skin, the paint shop in Centauria's Commercial Hall.
## A paint is a scheme for the colours every hull is drawn from (its four hull shades, its accent, its engine glow), so
## it fits every ship, also those to come; a ship's drones wear it too. The yards' own colours stay as they are.
## Fixed paints only. The key of a paint is also the key its pictures are kept under (PixelArt: "pt_…").
## "pt_rust" is no scheme but the run-down look of Dan's ships (rust, primer, scratches).

const ORDER := ["pt_midnight", "pt_bone", "pt_lapis", "pt_pelagia", "pt_kiln", "pt_glacia", "pt_ember", "pt_alley", "pt_static", "pt_grand", "pt_hazard",
	"pt_ghost", "pt_rust"]

const PAINTS := {
	"pt_midnight": {"name": "Midnight and Gold", "text": "Black as the gap between stars.", "hull": Color(0.17, 0.17, 0.2), "acc": Color(1.0, 0.78, 0.2)},
	"pt_bone": {"name": "Bone and Blood", "text": "Seen from far off. Meant to be.", "hull": Color(0.88, 0.86, 0.8), "acc": Color(0.92, 0.18, 0.22)},
	"pt_lapis": {"name": "Lapis", "text": "The blue of the giant overhead.", "hull": Color(0.14, 0.27, 0.66), "acc": Color(0.9, 0.93, 1.0)},
	"pt_pelagia": {"name": "Pelagia", "text": "Sea below, sand at the edge.", "hull": Color(0.12, 0.5, 0.53), "acc": Color(0.92, 0.84, 0.62)},
	"pt_kiln": {"name": "Kiln", "text": "Fired, not painted.", "hull": Color(0.43, 0.16, 0.12), "acc": Color(1.0, 0.54, 0.16)},
	"pt_glacia": {"name": "Glacia", "text": "Cold and clean.", "hull": Color(0.92, 0.95, 0.98), "acc": Color(0.55, 0.82, 1.0)},
	"pt_ember": {"name": "Ember", "text": "Still warm underneath.", "hull": Color(0.23, 0.23, 0.26), "acc": Color(1.0, 0.48, 0.16)},
	"pt_alley": {"name": "Neon Alley", "text": "For ships that come out at night.", "hull": Color(0.24, 0.25, 0.3), "acc": Color(1.0, 0.36, 0.66)},
	"pt_static": {"name": "Static", "text": "Matte, with a nasty edge.", "hull": Color(0.11, 0.11, 0.12), "acc": Color(0.62, 1.0, 0.22)},
	"pt_grand": {"name": "Grand Centauria", "text": "The house always wins.", "hull": Color(0.42, 0.21, 0.72), "acc": Color(1.0, 0.82, 0.3)},
	"pt_hazard": {"name": "Hazard", "text": "Keep your distance.", "hull": Color(0.95, 0.78, 0.12), "acc": Color(0.1, 0.1, 0.1)},
	"pt_ghost": {"name": "Ghost", "text": "Hard to pick out against the dust.", "hull": Color(0.72, 0.74, 0.76), "acc": Color(0.55, 0.57, 0.6)},
	"pt_rust": {"name": "Rust Bucket", "text": "Dan would approve.", "hull": Color(0.54, 0.35, 0.23), "acc": Color(1.0, 0.54, 0.22)},
}

const FACTORY_NAME := "Factory Silver"
const FACTORY_TEXT := "As she left the yard."
const PRICES := {1: 2500, 2: 8000, 3: 20000}          # by the hull's size; anything larger: PRICE_MAX
const PRICE_MAX := 40000


## What a paint is called ("" the factory's colours; a ship's own story paint has no name here).
static func name_of(id: String) -> String:
	if id == "":
		return FACTORY_NAME
	return String((PAINTS.get(id, {}) as Dictionary).get("name", "Her own colours"))


static func text_of(id: String) -> String:
	if id == "":
		return FACTORY_TEXT
	return String((PAINTS.get(id, {}) as Dictionary).get("text", ""))


## The price before the standing: by the hull's size, the same for every paint; the rust at half of it; back to
## the factory's colours for nothing.
static func price(hull_size: int, id: String) -> int:
	if id == "":
		return 0
	var base := int(PRICES.get(hull_size, PRICE_MAX))
	return base / 2 if id == "pt_rust" else base
