extends Node2D
## Package 62a, part 7 (Luz): a run of Survivor. The fights on foot cannot carry hundreds (each of theirs is a figure
## of its own with a way found for it), so the swarm lives here, as plain rows of numbers: where each one is, what
## it can still take, which kind it is. They walk straight at you, slide along what stands in their way, push each
## other apart (a grid of cells finds the neighbours), and are drawn in strips that sort among the figures and the
## objects, so that one behind a container is hidden by it.
## Your weapons fire by themselves. Who is put out drops a shard of light; shards near you fly to you; enough make a
## level, and the run stands still while you pick one of three cards (through the command bus, by seat).
## Part 7c-2, the stage: kinds that go about it in their own way (runners, haulers, spitters, bloaters,
## shieldbearers, howlers, an alpha every minute), what they throw and leave (acid, clouds), events by the clock
## (the flock, the ring, the sleepers, the wall, the blackout, supply drops), crates and what they hold, and the two
## bosses, each inside walls of light that close round you and it.
## This node draws what lies on the ground; `Over` what is above the figures; `Glow` what shines in the dark.
## No class_name: preload("res://scripts/ground/survivor_game.gd").

const SD = preload("res://data/survivor.gd")
const SArt = preload("res://scripts/ground/survivor_art.gd")
const SUI = preload("res://scripts/ground/survivor_ui.gd")
const SFX = preload("res://scripts/ground/survivor_fx.gd")
const NUM_MAX := 90                # numbers of damage on the screen at once
const NUM_LIFE := 0.75             # … and how long each stands
const DRONE_GAP := 0.075           # seconds between two shots of a drone's round
const S := GroundMap.SCALE
const TL := GroundMap.TILE
const CELL := 12.0                 # the grid that finds neighbours (art px)
const SEP := 9.0                   # how near two of the swarm may stand
const CHEST := Vector2(0, -15)
const DASH_TIME := 0.2             # the dodge: this long, at DASH_SPEED times your pace, and nothing touches you
const DASH_SPEED := 3.4
const DASH_BACK := 3.0             # seconds until a dodge is back (you have two)
const WALK := [1, 0, 2, 0]
const FACE := [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]
const STOMP_R := 54.0              # how far a hauler's stamp reaches
const HOWL_R := 90.0               # how far a howler's howl carries
const WIN_WAIT := 2.5              # seconds between The Brood's end and the end of the run
const ITEM_POP := 1.2              # seconds the sign of an item just taken shows (it springs up, stands, goes down to the display)

var view                           # the GroundView
var map: GroundMap
var run: Dictionary = {}           # SD.fresh()
var rng := RandomNumberGenerator.new()
var over := false
var survived := false
var frozen := false                # debug / tests: nobody comes, nobody walks
var quiet := false                 # debug / tests: nobody comes by the clock (who is there goes on as ever)
var cards: Array = []              # the three cards of a new level, while they are on the table
var pending := 0                   # levels made, their cards not yet picked
var step_ms := 0.0                 # what a step costs (smoothed), for the debug menu and the tests
# the swarm: `n` of them, in rows
var n := 0
var fp := PackedVector2Array()     # where (art px, the feet)
var fhp := PackedFloat32Array()    # what it can still take
var fmx := PackedFloat32Array()    # … and what it could take at first
var fk := PackedByteArray()        # its kind (index into SD.FOE_ORDER)
var fv := PackedByteArray()        # which of its looks
var fflash := PackedFloat32Array() # just hit: drawn bright for a moment
var fkb := PackedVector2Array()    # thrown back by a hit
var fdet := PackedFloat32Array()   # walking round something: seconds left (the sign: which way round)
var fface := PackedByteArray()     # which way it looks
var fst := PackedByteArray()       # where it is in what its kind does (0: as usual)
var ftm := PackedFloat32Array()    # … and its clock
var fal := PackedByteArray()       # 1: an alpha
var fsh := PackedFloat32Array()    # what is left of its shield
var fbo := PackedFloat32Array()    # a howler drives it on: seconds left
var fvel := PackedVector2Array()   # one that flies: its way
var ffr := PackedFloat32Array()    # frozen: seconds left (the Cryo Spray)
var fstun := PackedFloat32Array()  # stunned: seconds left (the Taser's shock)
var fovr := PackedFloat32Array()   # turned by an Override: seconds left (it fights for you)
# the shards on the ground: `sn` of them
var sn := 0
var sp := PackedVector2Array()
var sv := PackedInt32Array()
var stier := PackedByteArray()     # how each one looks (by what it is worth)
var spull := PackedByteArray()     # 1: it flies to you from wherever it lies (the Singularity sent it)
# what is to be seen for a moment
var rings: Array = []              # the pulse: {r, t}
var beams: Array = []              # the laser: {a, b, t}
var pops: Array = []               # one put out: {pos, t}
var nades: Array = []              # plasma grenades in the air: {a, b, t, r, dmg}
var blasts: Array = []             # … where one burst: {pos, r, t}
var shots: Array = []              # the drone's shots: {p, v, life, dmg, pierce}
var sweep: Dictionary = {}         # the superlaser while it sweeps: {a0, a, to, reach, t, len}
var blades: Array = []             # the silverblades in the air: {p, v, life, dmg}
var _slain := PackedInt32Array()   # (part 10a) how many of each kind this run has put out (by the kind's place in FOE_ORDER)
var orb_a := 0.0                   # the plasma orbs: where they stand on their round
var orb_pts: Array = []            # … and where they are now (the Fusion Halo's outer ring: `orb_out`)
var orb_out: Array = []
var orb_r := 0.0                   # … how wide their round is
var orbs_t := 0.0                  # … seconds they still circle
var _orb_more := 0                 # … one more this time (Overclock)
var _halo_t := 2.0                 # the Fusion Halo: seconds until its next burst
var halos: Array = []              # … its bursts on their way out: {c, r, from, to, dmg}
var nova_r := 0.0                  # the Nova Field's radius while it stands (0: none)
var mods: Dictionary = {}          # what your boni make of you and of all you carry (SD.mods)
var stg: Dictionary = {}           # part 8: what this stage is made of (SD.stage_data)
var _swarm_k := 0                  # … the kind that comes all the time
var _hunter_k := -1                # … and the hunter's place in the tables (it burns the ground under it)
# part 7c-3: four more weapons, five more boni
var mines: Array = []              # {p, arm (seconds until it is armed), life, r, dmg, again (it arms itself once more)}
var sentries: Array = []           # {p, life, cd, dmg, keep (the Battery: it stays while you stay near), face, flash}
var cones: Array = []              # the cryo's cone for a moment: {p, a, r, arc (PI: all round), t}
var wells: Array = []              # gravity wells: {p, r, life, t, dmg, tick, ult}
var zaps: Array = []               # the taser's shock for a moment: {p, r, t}
var holes: Array = []              # the Blackhole Gun's black holes on their way out: {p, v, r, t, tick, dmg}
# part 8b: what happens on AI Takeover
var shells: Array = []             # what comes down on a marked spot: {from (INF: out of the sky), pos, t, len, r, dmg, foes}
var booms: Array = []              # where a seeker went off this step (worked off after the step's hits)
var lights: Array = []             # the searchlights: {p, v, ph}
var search_t := 0.0                # … seconds they still hunt
var lit_t := 0.0                   # … seconds you have stood in one
var pods: Array = []               # landing pods: {pos, t (until it lands), husk (seconds its husk still stands)}
var klines: Array = []             # kill lines: {c (where its middle began), dir, s, far, half, gaps, warm}
var emp_t := 0.0                   # seconds none of your weapons charges
var ovr_t := 0.0                   # seconds an Override still holds (for the display)
var _ovr_hits: Array = []          # what the turned machines struck while they moved: [where, how hard, from where]
var _arming := false               # a seeker has armed itself this step
# part 8c: the bosses of AI Takeover
var fields: Array = []             # The Core's squares of the floor: {r (the square), t, len (it bursts then), done}
var _core_k := -1                  # The Core's place in the tables, and its pylons'
var _pylon_k := -1
var _guard_t := 0.0                # seconds The Core's shield still flares after something struck it
# part 9a (Luz, 23 Nov 2026): Whiteout
var bright := false                # a stage by day: what is only light would not show on it
var vents: Array = []              # steam vents: {pos, cool (seconds until it can burst again), t (seconds its steam still stands)}
var _slide := Vector2.ZERO         # your way on bare ice
var _lead := Vector2.ZERO          # where you will be in a moment, from where you are (a burrower heads there)
var _frozen_t := 0.0               # seconds until "frozen in" is said again
var _burrow_k := -1                # the burrower's place in the tables, and what it is made of (SD.FOES)
var _bur_pace := 3.0
var _bur_warn := 0.9
var _bur_r := 20.0
var _bur_dmg := 12.0
var _bur_up := 5.0
# part 7f (Luz, 23 Nov 2026): the crates in two kinds; what an item looks like
var last_draw: Array = []          # what the last weapon crate held (cards, as SD.draw_rewards makes them)
var item_pop: Dictionary = {}      # the sign of an item just taken, springing up over you: {id, t}
var nukes: Array = []              # an Atomic Bomb: {pos, r, t}
var scorches: Array = []           # … the earth it scorched: {pos, r, t}
var heals: Array = []              # a Medkit's moment: {t}
var shield_len := 1.0              # how long the Shield, the Stasis, the Overdrive last this time (for their clocks)
var stasis_len := 1.0
var over_len := 1.0
var shield_hit := 0.0              # something has just struck the Shield: seconds its flash still shows
var _od_tr := PackedVector2Array() # Overdrive: where you just were (the echoes behind you)
var _od_t := 0.0
var _wkb := PackedFloat32Array()   # (Luz, 24 Nov 2026) by what is hitting (`_src`): how much further its hits throw them back (SD.WEAPONS "kb")
var _kbk := 1.0                    # … and a factor on top for the hit of the moment
# part 9b (Luz, 24 Nov 2026): the rest of Whiteout
var _glider_k := -1                # the glider's place in the tables
var blizzard_t := 0.0              # seconds a blizzard still lasts (you see only a round about you)
var breaks: Array = []             # plates of ice that crack and break: {r (the plate), t, len (it breaks then), done}
var avas: Array = []               # avalanches: {c (where its front begins), dir, s (how far it has come), far, warm}
var in_cover := false              # an avalanche is on its way and something solid stands between it and you
# part 9c: the bosses of Whiteout
var _digs := PackedByteArray()     # by kind: 1 it can be under the ice (`fst` < 2: nothing reaches it there, no figure shows): the burrower, The Ice Worm
var in_storm := false              # you stand outside the eye of The Storm Heart's storm
# part 7d (Luz, 23 Nov 2026): the numbers of damage, the drone you see, what the ultimates leave behind
var nums: Array = []               # numbers of damage: {p (art px), h (how high over it), v, t, c (as in `fnc`)}
var fnum := PackedFloat32Array()   # by foe: what it took since its last number
var fnc := PackedByteArray()       # … from what (the weapon's place + 1; 0: something else), + 32: a shield took it, + 64: a hit twice as hard
var show_nums := true
var _num_t := 0.0
var _src := 0                      # what is hitting now (as in `fnc`)
var _wsrc := {}                    # a weapon's number for `_src`, by its id
var fxs: Array = []                # what an ultimate leaves for a moment: {kind, p, r, t, len, s (which one, for its sparks)}
var drones: Array = []             # the drones that fly with you: {p, a (where its gun looks), q (shots still to fire), cd, flash, tr (its trail), turn, dmg, pierce}
var shot_n := 0                    # shots the drones have fired, ever
var _mine_g := 0                   # the Minefield's rings, counted
var _bat_n := 0                    # the Battery's guns, counted (each takes the next place round you)
# the flood (Luz, 23 Nov 2026): from 13:00 on they come in absurd numbers
var foe_cap: int = 600             # how many of them there may be at once (the usual number until the flood begins, the flood's own after)
var flooding := false
var _flood_acc := 0.0
var cell_t := 0.0                  # the Shield Cell: seconds until it is charged again (0: charged)
var face_dir := Vector2.DOWN       # the way you walked last (the cryo sprays that way, mines fall behind you)
var _last_pp := Vector2.INF
var _xp_frac := 0.0                # what Scavenger and the fine tuning add to the shards, until it makes a whole one
var _shatter := false              # Absolute Zero: what is frozen shatters at the next hit
# what the others throw and leave
var globs: Array = []              # acid in the air: {p, v, life, clean (it leaves no pool)}
var pools: Array = []              # on the ground: {pos, r, t, life, kind ("acid" | "cloud"), dps}
var tele: Array = []               # warnings and shocks on the ground: {kind, pos, r, t, len, …}
var waves: Array = []              # a boss's rings of force: {pos, r, to, speed, dmg, hit}
# crates, sleepers, what a crate gave you
var crates: Array = []             # {pos, great, fall (seconds until it has landed)}
var sleepers: Array = []           # those lying in the colony: {pos, v}
var sleep_on := false              # … they rise when you come near (from the event on)
var shield_t := 0.0                # seconds nothing touches you (a crate's shield)
var stasis_t := 0.0                # seconds the others stand still
var over_t := 0.0                  # seconds your weapons fire twice as fast
var magnet_t := 0.0                # seconds every shard flies to you
var bombs: Array = []              # an atomic bomb's flash: {pos, r, t}
# what happens by the clock
var banner := ""                   # a word across the picture
var banner_t := 0.0
var flock_warn: Dictionary = {}    # a flock is about to come: {dir, t}
var blackout_t := 0.0
# the bosses
var barrier := Rect2()             # the field inside the walls of light
var barrier_on := false
var barrier_k := 0.0               # how far the walls have grown (0 … 1)
var boss_kind := ""                # which boss is here ("" none)
var bst: Dictionary = {}           # what it is doing: {st, t, …}
var boss_done: Dictionary = {}     # which bosses have come (kind: true)
var hurt_cd := 0.0
var dash_t := 0.0
var dash_dir := Vector2.ZERO
var dash_charges := 2.0
var kb_t := 0.0                    # you are thrown back: seconds left
var kb_dir := Vector2.ZERO
var hud: Control = null
var _over: Node2D = null
var _glow: Node2D = null
var _shtex: Array = []             # the shards' pictures: by kind, by frame
var _bands: Array = []
var _used: Array = []
var _marks: Array = []             # what is to be drawn round those in the picture: [what, where, how far, which]
var _w := 0
var _h := 0
var _solid := PackedByteArray()    # per tile: 1 nobody walks here
var _haz := PackedByteArray()      # per tile: 1 it holds you back, 2 it burns, 3 bare ice (you slide)
var _gw := 0
var _gh := 0
var _head := PackedInt32Array()
var _next := PackedInt32Array()
var _ki := {}                      # a kind's place in the tables below, by its name
var _spd := PackedFloat32Array()   # by kind
var _dmg := PackedFloat32Array()
var _rad := PackedFloat32Array()
var _xp := PackedInt32Array()
var _tough := PackedByteArray()    # by kind: the superlaser and the bomb do not put it out at once
var _beh := PackedByteArray()      # by kind: how it goes about it (SD.FOES "beh")
var _mass := PackedFloat32Array()  # by kind: how little a hit throws it back
var _nosep := PackedByteArray()    # by kind: it is not pushed about by the others (it flies, or it is a boss)
var _shield := PackedFloat32Array()
var _cnt := PackedInt32Array()     # by kind: how many are there now
var _tsz: Array = []               # by kind: the size of its picture (screen px)
var _tex: Array = []               # by kind, look, way, frame
var _wt := {}                      # seconds until each weapon fires again
var _wave_at := {}                 # by kind: when its next group comes
var _alpha_at: float = SD.ALPHA_EVERY
var _flock_at: float = SD.FLOCK_FROM
var _supply_at: float = SD.SUPPLY_FROM
var _ev_i := 0
var _acc := 0.0
var _tick := 0.0
var _flash := 0.0
var _frame := 0
var _burn := 12.0
var _dark0 = null                  # the stage's own darkness, kept through a blackout
var _win_t := -1.0


## One strip of the swarm (a tile deep), sorted among the figures by where it stands.
class Band extends Node2D:
	var game
	var ids := PackedInt32Array()

	func _draw() -> void:
		if game != null and is_instance_valid(game):
			game.draw_band(self)


## What is above the figures: beams, what flies, bars, your bar under your feet.
class Over extends Node2D:
	var game

	func _draw() -> void:
		if game != null and is_instance_valid(game):
			game.draw_over(self)


## What shines in the dark (added on top, like the lamps): the shards, the pulse's ring, acid, the walls of light.
class Glow extends Node2D:
	var game

	func _draw() -> void:
		if game != null and is_instance_valid(game):
			game.draw_glow(self)


func setup(p_view, p_map: GroundMap, p_run: Dictionary) -> void:
	view = p_view
	map = p_map
	run = p_run
	mods = SD.mods(run)
	rng.randomize()
	_w = map.w
	_h = map.h
	_solid.resize(_w * _h)
	_haz.resize(_w * _h)
	_haz.fill(0)
	for y in _h:
		for x in _w:
			_solid[y * _w + x] = 0 if GroundMap.walkable_t(map.t_at(x, y)) else 1
	for hz in map.get_meta("col_hazards", []):
		var code := 2 if String(hz["kind"]) == "burn" else (1 if String(hz["kind"]) == "slow" else (3 if String(hz["kind"]) == "ice" else 0))
		if code == 2:
			_burn = float(hz.get("dps", 12.0))
		for r in hz["rects"]:
			var rr: Rect2 = r
			for ty in range(int(rr.position.y / TL), int(ceil(rr.end.y / TL))):
				for tx in range(int(rr.position.x / TL), int(ceil(rr.end.x / TL))):
					if tx >= 0 and ty >= 0 and tx < _w and ty < _h:
						_haz[ty * _w + tx] = code
	_gw = int(ceil(_w * TL / CELL)) + 2
	_gh = int(ceil(_h * TL / CELL)) + 2
	_head.resize(_gw * _gh)
	var cap: int = maxi(foe_cap, SD.FLOOD_FOES) + 8      # (room for the flood of the last two minutes)
	_next.resize(cap)
	fp.resize(cap)
	fhp.resize(cap)
	fmx.resize(cap)
	fk.resize(cap)
	fv.resize(cap)
	fflash.resize(cap)
	fkb.resize(cap)
	fdet.resize(cap)
	fface.resize(cap)
	fst.resize(cap)
	ftm.resize(cap)
	fal.resize(cap)
	fsh.resize(cap)
	fbo.resize(cap)
	fvel.resize(cap)
	ffr.resize(cap)
	fstun.resize(cap)
	fovr.resize(cap)
	fnum.resize(cap)
	fnc.resize(cap)
	sp.resize(520)
	sv.resize(520)
	stier.resize(520)
	spull.resize(520)
	_last_pp = view.pilot.pos
	face_dir = FACE[clampi(int(view.pilot.dir), 0, 3)]
	for tr in 4:
		for fr in 4:
			_shtex.append(SArt.shard(tr, fr))
	for kind in SD.FOE_ORDER:
		var fd: Dictionary = SD.FOES[kind]
		_ki[String(kind)] = _spd.size()
		_spd.append(float(fd["speed"]))
		_dmg.append(float(fd["dmg"]))
		_rad.append(float(fd["r"]))
		_xp.append(int(fd["xp"]))
		_tough.append(1 if bool(fd.get("tough", false)) else 0)
		_beh.append(int(fd.get("beh", 0)))
		_mass.append(float(fd.get("mass", 1.0)))
		_nosep.append(1 if bool(fd.get("fly", false)) or bool(fd.get("boss", false)) else 0)
		_shield.append(float(fd.get("shield", 0.0)))
		_digs.append(1 if int(fd.get("beh", 0)) in [13, 25] else 0)
		_cnt.append(0)
		_tsz.append(Vector2(SArt.size_of(String(kind))) * 2.0)
		for v in 4:
			for d in 4:
				for f in 3:
					_tex.append(SArt.texture(String(kind), v, d, f))
	stg = SD.stage_data(String(run.get("stage", "outbreak")))
	_swarm_k = _ki[String(stg["swarm"])]
	_hunter_k = _ki["hunter"]
	_core_k = _ki["core"]
	_pylon_k = _ki["pylon"]
	_burrow_k = _ki["burrower"]
	_glider_k = _ki["glider"]
	var bur: Dictionary = SD.FOES["burrower"]
	_bur_pace = float(bur["pace"])
	_bur_warn = float(bur["warn"])
	_bur_r = float(bur["erupt_r"])
	_bur_dmg = float(bur["erupt"])
	_bur_up = float(bur["up"])
	bright = bool(map.get_meta("sv_bright", false))
	for vp0 in map.get_meta("sv_vents", []):
		vents.append({"pos": vp0, "cool": 0.0, "t": 0.0})
	_wkb.resize(16)
	_wkb.fill(1.0)
	for wq in SD.WEAPON_ORDER.size():
		_wsrc[String(SD.WEAPON_ORDER[wq])] = wq + 1
		_wkb[wq + 1] = float(SD.WEAPONS[String(SD.WEAPON_ORDER[wq])].get("kb", 1.0))
	for cp in map.get_meta("sv_crates", []):
		crates.append({"pos": cp, "great": false, "fall": 0.0, "ice": bool(map.get_meta("sv_frozen", false))})      # (part 9a: Whiteout's are frozen in)
	var sq := 0
	for slp in map.get_meta("sv_sleepers", []):
		sleepers.append({"pos": slp, "v": sq})
		sq += 1
	for b in _h:
		var bd := Band.new()
		bd.game = self
		bd.position = Vector2(0.0, (b + 0.5) * TL * S)
		view._sorted.add_child(bd)
		_bands.append(bd)
	_over = Over.new()
	_over.game = self
	_over.z_index = 6
	view._world.add_child(_over)
	_glow = Glow.new()
	_glow.game = self
	_glow.z_index = 5
	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = add_mat
	view._world.add_child(_glow)
	hud = SUI.Hud.new()
	hud.game = self
	view._ui.add_child(hud)


## The run's nodes outside this one go with it.
func drop() -> void:
	_blackout(false)
	if hud != null and is_instance_valid(hud):
		hud.queue_free()
	hud = null
	if _over != null and is_instance_valid(_over):
		_over.queue_free()
	if _glow != null and is_instance_valid(_glow):
		_glow.queue_free()
	for bd in _bands:
		if is_instance_valid(bd):
			(bd as Node).queue_free()
	_bands.clear()
	if view != null and is_instance_valid(view) and view.pilot != null and is_instance_valid(view.pilot):
		view.pilot.modulate = Color.WHITE
	queue_free()


func _process(delta: float) -> void:
	if over or view == null or not is_instance_valid(view) or map != view.map:
		return
	if view.minigame != null or view._lift_menu != null:
		return                                            # a window is up (the cards of a level, a question): the run stands still
	step(delta)


## Your step: thrown back you go where you are thrown; the dodge carries you where it began to go.
func move(dir: Vector2) -> Vector2:
	if kb_t > 0.0:
		_slide = kb_dir
		return kb_dir
	if dash_t > 0.0:
		_slide = dash_dir
		return dash_dir
	if _haz[_ti(view.pilot.pos)] == 3:                      # (part 9a) bare ice: you keep your way, and turn it only slowly
		_slide = _slide.move_toward(dir.limit_length(1.0), SD.ICE_TURN * get_process_delta_time())
		return _slide
	_slide = dir.limit_length(1.0)
	return dir


## … and your pace: the throw's, the dodge's, or your own, held back by what lies on the ground.
func speed() -> float:
	if kb_t > 0.0:
		return 2.6
	if dash_t > 0.0:
		return DASH_SPEED
	return (0.55 if _haz[_ti(view.pilot.pos)] == 1 else 1.0) * float(mods["speed"])


## The dodge: a quick step the way you walk (the way you look, standing); nothing touches you while it lasts.
func dash(dir: Vector2) -> bool:
	if dash_charges < 1.0 or dash_t > 0.0 or over:
		return false
	if dir.length() < 0.2:
		dir = FACE[clampi(int(view.pilot.dir), 0, 3)]
	dash_dir = dir.normalized()
	dash_t = DASH_TIME
	kb_t = 0.0
	dash_charges -= 1.0
	Audio.play("ui_click", "survivor: a dodge", -8.0)
	return true


## Half of what you see of the field (art px); never less than a small picture's worth, so that nobody appears
## beside you where the window is small.
func _half() -> Vector2:
	var h: Vector2 = view.get_viewport().get_visible_rect().size / (float(S) * maxf(0.2, float(view.zoom))) * 0.5
	return Vector2(maxf(h.x, 240.0), maxf(h.y, 140.0))


func _ti(p: Vector2) -> int:
	return clampi(int(p.x) >> 4, 0, _w - 1) + clampi(int(p.y) >> 4, 0, _h - 1) * _w


## Can something hurt you now? (Not in a dodge, not under a crate's shield, not right after a hit.)
func can_hurt() -> bool:
	return hurt_cd <= 0.0 and dash_t <= 0.0 and shield_t <= 0.0


## A word across the picture for a moment.
func say(key: String, text: String = "") -> void:
	banner = text if text != "" else String((stg.get("banners", {}) as Dictionary).get(key, SD.BANNERS.get(key, key.to_upper())))
	banner_t = 3.2


## One step of the run.
func step(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	_frame += 1
	var pp: Vector2 = view.pilot.pos
	if (boss_kind == "" or boss_kind != String(stg.get("end", ""))) and _win_t < 0.0:
		run["t"] = minf(SD.RUN_TIME, float(run["t"]) + delta)      # (the clock stands at the end of the stage while its last one lives: The Brood, The Core)
	hurt_cd = maxf(0.0, hurt_cd - delta)
	dash_t = maxf(0.0, dash_t - delta)
	kb_t = maxf(0.0, kb_t - delta)
	shield_t = maxf(0.0, shield_t - delta)
	stasis_t = maxf(0.0, stasis_t - delta)
	over_t = maxf(0.0, over_t - delta)
	magnet_t = maxf(0.0, magnet_t - delta)
	banner_t = maxf(0.0, banner_t - delta)
	cell_t = maxf(0.0, cell_t - delta)
	var stepped := pp - _last_pp
	if stepped.length_squared() > 0.0004 and stepped.length_squared() < 400.0:      # (a step, not a jump to another place)
		face_dir = stepped.normalized()
	if delta > 0.0 and stepped.length_squared() < 400.0:
		_lead = _lead.lerp(stepped / delta * 0.55, minf(1.0, delta * 6.0))      # (where you will be in half a second, if you go on like this)
	_last_pp = pp
	dash_charges = minf(2.0, dash_charges + delta / DASH_BACK)
	if blackout_t > 0.0:
		blackout_t -= delta
		if blackout_t <= 0.0:
			_blackout(false)
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			view.pilot.modulate = Color.WHITE
	if view.input_enabled and Input.is_action_just_pressed("foot_dodge"):
		dash(Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down"))
	if float(run["hp"]) > 0.0 and float(mods["regen"]) > 0.0:
		run["hp"] = minf(SD.HEALTH + float(mods["hp"]), float(run["hp"]) + float(mods["regen"]) * delta)      # (the Nanite Weave: health comes back slowly)
	if not frozen:
		_director(delta, pp)
		if stasis_t <= 0.0:                                # (a crate's stasis: they all stand still)
			_move(delta, pp)
			_boss(delta, pp)
			_thrown(delta, pp)
	_grid()
	if not frozen and stasis_t <= 0.0 and _frame % 2 == 0:
		_separate()
	_src = 0
	_weapons(0.0 if emp_t > 0.0 else delta * (2.0 if over_t > 0.0 else 1.0), pp)      # (an EMP: nothing charges)
	_src = int(_wsrc.get("drone", 0))
	_drones(delta, 0.0 if emp_t > 0.0 else delta * (2.0 if over_t > 0.0 else 1.0), pp)
	_fly(delta, pp)
	_devices(delta, pp)
	_src = 0
	if not frozen:
		_events(delta, pp)
	_shards(delta, pp)
	_ground(delta, pp)
	_crates(delta, pp)
	if not vents.is_empty():
		_vents(delta, pp)
	_walls(delta)
	_num_t -= delta
	if _num_t <= 0.0:                                       # what each one took since its last number: a new number over it
		_num_t = 0.22
		var nh := _half() + Vector2(20.0, 40.0)
		for i in n:
			if fnum[i] >= 0.5:
				if absf(fp[i].x - pp.x) < nh.x and absf(fp[i].y - pp.y) < nh.y:
					_num(fp[i], fk[i], fnum[i], fnc[i])
				fnum[i] = 0.0
				fnc[i] = 0
	_fx(delta)
	_to_bands(view.pilot.pos)
	queue_redraw()
	_over.queue_redraw()
	_glow.queue_redraw()
	hud.queue_redraw()
	step_ms = lerpf(step_ms, float(Time.get_ticks_usec() - t0) / 1000.0, 0.05)
	if _win_t >= 0.0:
		_win_t -= delta
		if _win_t <= 0.0:
			end(true)                                         # The Brood is out: you held the stage
	elif float(run["hp"]) <= 0.0:
		if bool(run.get("revive", false)):
			_revive(view.pilot.pos)                           # (the last chance, bought at the console: once a run)
		else:
			end(false)
	elif pending > 0 and view.minigame == null:
		_offer()


# ---------------------------------------------------------------- who comes when

## A point just outside what you see, on free ground (INF: none found).
func edge_point(pp: Vector2) -> Vector2:
	var half := _half() + Vector2(26.0, 34.0)
	for k in 8:
		var p := pp
		match rng.randi() % 4:
			0:
				p += Vector2(rng.randf_range(-half.x, half.x), -half.y)
			1:
				p += Vector2(rng.randf_range(-half.x, half.x), half.y)
			2:
				p += Vector2(-half.x, rng.randf_range(-half.y, half.y))
			_:
				p += Vector2(half.x, rng.randf_range(-half.y, half.y))
		if p.x < 40.0 or p.y < 40.0 or p.x > _w * TL - 40.0 or p.y > _h * TL - 40.0:
			continue
		if _solid[_ti(p)] != 0:
			continue
		return p
	return Vector2.INF


## A free spot at `p` or as near to it as can be (within `r`; `p` itself when none is found).
func near_free(p: Vector2, r: float = 40.0) -> Vector2:
	for q in 14:
		var c := p if q == 0 else p + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(4.0, r)
		if c.x > 40.0 and c.y > 40.0 and c.x < _w * TL - 40.0 and c.y < _h * TL - 40.0 and _solid[_ti(c)] == 0:
			return c
	return p


## One more of the swarm (k: its kind), at p. Its place in the rows, or -1 when the field is full.
func add_foe(k: int, p: Vector2) -> int:
	if n >= foe_cap:
		return -1
	fp[n] = p
	fhp[n] = SD.foe_hp(String(SD.FOE_ORDER[k]), float(run["t"]))
	fmx[n] = fhp[n]
	fk[n] = k
	fv[n] = rng.randi() % (2 if _shield[k] > 0.0 else 4)       # (a shieldbearer's other two looks: its shield broken)
	fflash[n] = 0.0
	fkb[n] = Vector2.ZERO
	fdet[n] = 0.0
	fface[n] = 0
	fst[n] = 0
	ftm[n] = rng.randf_range(1.0, 2.6) if (_beh[k] == 3 or _beh[k] == 9 or _beh[k] == 14) else 0.0
	fal[n] = 0
	fsh[n] = _shield[k]
	fbo[n] = 0.0
	fvel[n] = Vector2.ZERO
	ffr[n] = 0.0
	fstun[n] = 0.0
	fovr[n] = 0.0
	fnum[n] = 0.0
	fnc[n] = 0
	_cnt[k] = _cnt[k] + 1
	n += 1
	return n - 1


## One of the swarm goes out of the rows (the last one takes its place).
func _remove(i: int) -> void:
	_cnt[fk[i]] = _cnt[fk[i]] - 1
	n -= 1
	if i != n:
		fp[i] = fp[n]
		fhp[i] = fhp[n]
		fmx[i] = fmx[n]
		fk[i] = fk[n]
		fv[i] = fv[n]
		fflash[i] = fflash[n]
		fkb[i] = fkb[n]
		fdet[i] = fdet[n]
		fface[i] = fface[n]
		fst[i] = fst[n]
		ftm[i] = ftm[n]
		fal[i] = fal[n]
		fsh[i] = fsh[n]
		fbo[i] = fbo[n]
		fvel[i] = fvel[n]
		ffr[i] = ffr[n]
		fstun[i] = fstun[n]
		fovr[i] = fovr[n]
		fnum[i] = fnum[n]
		fnc[i] = fnc[n]


## One of the swarm becomes an alpha: it can take far more, hits harder, drops a crate.
func make_alpha(i: int) -> void:
	if i < 0 or i >= n:
		return
	fal[i] = 1
	fhp[i] = fhp[i] * SD.ALPHA_HP
	fmx[i] = fhp[i]


## Who comes when: the shamblers all the time, the other kinds in groups, an alpha every minute, the flock, supply
## drops, what happens by the clock, the bosses. While a boss's walls of light stand, nobody new comes.
func _director(delta: float, pp: Vector2) -> void:
	var t := float(run["t"])
	if quiet or barrier_on or _win_t >= 0.0:
		return
	var end_b := String(stg["end"])
	var soft_b := String(stg["soft"])
	if t >= SD.RUN_TIME:
		if end_b == "":
			_win_t = 0.01                                     # (a stage with no last one yet: the time is up, you held it)
		elif not boss_done.has(end_b):
			boss_start(end_b)
		return
	if soft_b != "" and t >= SD.SOFT_BOSS and not boss_done.has(soft_b):
		boss_start(soft_b)
		return
	_acc += SD.spawn_rate(t) * delta
	while _acc >= 1.0:
		_acc -= 1.0
		if n >= foe_cap:
			_acc = 0.0
			break
		var p := edge_point(pp)
		if p != Vector2.INF:
			add_foe(_swarm_k, p)
	if t >= SD.FLOOD_FROM:                                  # the flood: from here to the end they come in absurd numbers, weak ones, more at once than ever before
		if not flooding:
			flooding = true
			foe_cap = maxi(foe_cap, SD.FLOOD_FOES)
			say("flood")
			Audio.play("sv_alarm", "survivor: the flood", -4.0)
		_flood_acc += SD.FLOOD_RATE * delta
		while _flood_acc >= 1.0:
			_flood_acc -= 1.0
			if n >= foe_cap:
				_flood_acc = 0.0
				break
			var fp9 := edge_point(pp)
			if fp9 != Vector2.INF:
				var fi9 := add_foe(_swarm_k, fp9)
				if fi9 >= 0:
					fhp[fi9] = fhp[fi9] * SD.FLOOD_HP
					fmx[fi9] = fhp[fi9]
	for w in stg["waves"]:
		var kind := String(w["kind"])
		if t < float(w["from"]) or t < float(_wave_at.get(kind, float(w["from"]))):
			continue
		_wave_at[kind] = t + float(w["every"]) * maxf(0.5, 1.0 - (t - float(w["from"])) / 900.0) * rng.randf_range(0.85, 1.15)
		spawn_kind(kind, rng.randi_range(int(w["n"][0]), int(w["n"][1])), int(w["cap"]))
	if t >= _alpha_at:
		_alpha_at = t + SD.ALPHA_EVERY
		var here: Array = SD.kinds_at(t, String(run.get("stage", "outbreak")))
		var able: Array = (stg["alpha"] as Array).filter(func(k): return k in here)
		var made := spawn_kind(String(able[rng.randi() % able.size()]), 1, 9999)
		if made >= 0:
			make_alpha(made)
			say("alpha")
			Audio.play("sv_alarm", "survivor: an alpha", -12.0)
	if String(stg["flock"]) != "" and t >= _flock_at:
		_flock_at = t + SD.FLOCK_EVERY
		event("flock")
	if t >= _supply_at:
		_supply_at = t + SD.SUPPLY_EVERY * (1.0 - 0.08 * float(mods.get("luck", 0)))      # (Lucky Find: they come sooner)
		event("supply")
	var evs: Array = stg["events"]
	while _ev_i < evs.size() and t >= float(evs[_ev_i]["t"]):
		event(String(evs[_ev_i]["kind"]))
		_ev_i += 1


## A group of a kind just outside the picture (not more than `cap` of them at once). The place of the last one in
## the rows, or -1.
func spawn_kind(kind: String, count: int, cap: int = 9999) -> int:
	if not _ki.has(kind):
		return -1
	var k: int = _ki[kind]
	var at := edge_point(view.pilot.pos)
	var last := -1
	if at == Vector2.INF:
		return -1
	for q in count:
		if _cnt[k] >= cap:
			break
		last = add_foe(k, near_free(at, 26.0))
	return last


## Something happens (the clock calls this, and the debug menu): "flock", "ring", "wall", "sleepers", "blackout",
## "supply".
func event(kind: String) -> void:
	var pp: Vector2 = view.pilot.pos
	var half := _half()
	match kind:
		"flock":                                            # screechers, in a wedge, straight through where you stand
			var a := rng.randf() * TAU
			var hunters := String(stg["flock"]) in ["hunter", "glider"]      # (part 8b: on AI Takeover hunters come, along a line shown first; part 9b: on Whiteout gliders)
			flock_warn = {"dir": Vector2.from_angle(a), "t": 1.5 if hunters else 1.3, "at": pp}
			Audio.play("sv_alarm" if hunters else "sv_screech", "survivor: the flock", -10.0)
		"ring":                                             # a ring of shamblers closes round you
			var rad := half.length() + 16.0
			for q in 56:
				var p := pp + Vector2.from_angle(q * TAU / 56.0) * rad
				if p.x > 40.0 and p.y > 40.0 and p.x < _w * TL - 40.0 and p.y < _h * TL - 40.0 and _solid[_ti(p)] == 0:
					add_foe(0, p)
		"wall":                                             # a dense row comes across the field from one side
			var side := rng.randi() % 4
			for q2 in 60:
				var along := (float(q2 / 2) / 29.0 - 0.5) * 2.0
				var deep := float(q2 % 2) * 12.0
				var p2 := pp
				match side:
					0:
						p2 += Vector2(along * half.x, -half.y - 30.0 - deep)
					1:
						p2 += Vector2(along * half.x, half.y + 34.0 + deep)
					2:
						p2 += Vector2(-half.x - 28.0 - deep, along * half.y)
					_:
						p2 += Vector2(half.x + 28.0 + deep, along * half.y)
				if p2.x > 40.0 and p2.y > 40.0 and p2.x < _w * TL - 40.0 and p2.y < _h * TL - 40.0 and _solid[_ti(p2)] == 0:
					add_foe(0, p2)
		"sleepers":
			sleep_on = true
		"blackout":
			blackout_t = SD.BLACKOUT_TIME
			_blackout(true)
		"supply":
			crates.append({"pos": near_free(pp + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(140.0, 230.0), 50.0), "great": false, "fall": 1.2, "mark": true})
		"searchlight":                                      # (part 8b) two searchlights come hunting for a while
			search_t = SD.SEARCH_TIME
			lit_t = 0.0
			lights.clear()
			for q3 in 2:
				lights.append({"p": pp + Vector2.from_angle(rng.randf() * TAU) * (half.length() * 0.8), "v": Vector2.ZERO, "ph": rng.randf() * TAU})
		"reinforce":                                        # landing pods come down in a ring round you
			var a2 := rng.randf() * TAU
			for q4 in 8:
				var pp2 := pp + Vector2.from_angle(a2 + q4 * TAU / 8.0) * rng.randf_range(92.0, 128.0)
				if pp2.x > 40.0 and pp2.y > 40.0 and pp2.x < _w * TL - 40.0 and pp2.y < _h * TL - 40.0 and _solid[_ti(pp2)] == 0:
					pods.append({"pos": pp2, "t": 1.1 + q4 * 0.12, "husk": 0.0})
					tele.append({"kind": "spot", "pos": pp2, "r": 14.0, "t": 0.0, "len": 1.1 + q4 * 0.12})
		"killline":                                         # a line of light crosses the field from one side, gaps in it
			var kd: Vector2 = [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP][rng.randi() % 4]
			var far := absf(kd.x) * half.x + absf(kd.y) * half.y + 40.0
			var hl := absf(kd.y) * half.x + absf(kd.x) * half.y + 60.0
			klines.append({"c": pp - kd * far, "dir": kd, "s": 0.0, "far": far * 2.0, "half": hl, "gaps": [rng.randf_range(-hl + 60.0, -40.0), rng.randf_range(40.0, hl - 60.0)], "warm": 1.4})
		"emp":                                              # nothing of yours charges for a while
			emp_t = SD.EMP_TIME
			Audio.play("sv_emp", "survivor: the EMP", -6.0)
			tele.append({"kind": "emp", "pos": pp, "r": half.length(), "t": 0.0, "len": 0.5})
		"blizzard":                                         # (part 9b) for a while you see only a round about you
			blizzard_t = SD.BLIZZARD_TIME
			Audio.play("sv_steam", "survivor: a blizzard", -8.0)
		"icebreak":                                         # plates of ice crack, the one you stand on among them, and break
			var cell: float = SD.BREAK_CELL
			var mine := Vector2i(int(floor(pp.x / cell)), int(floor(pp.y / cell)))
			var plates := {mine: true}
			for q7 in 14:
				if plates.size() < 7:
					plates[mine + Vector2i(rng.randi_range(-3, 3), rng.randi_range(-2, 2))] = true
			var pq := 0
			for pc in plates:
				breaks.append({"r": Rect2(Vector2(pc) * cell, Vector2(cell, cell)), "t": 0.0, "len": SD.BREAK_WARN + 0.22 * pq, "done": false})
				pq += 1
		"avalanche":                                        # a wall of snow from one side; behind something solid you are safe
			var ad: Vector2 = [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP][rng.randi() % 4]
			var afar := absf(ad.x) * half.x + absf(ad.y) * half.y + 70.0
			avas.append({"c": pp - ad * afar, "dir": ad, "s": 0.0, "far": afar * 2.0 + 80.0, "warm": SD.AVA_WARN})
		_:
			return
	say(kind)
	if kind != "flock":
		Audio.play("sv_alarm", "survivor: %s" % kind, -12.0)


## The lamps go out, or come on again.
func _blackout(on: bool) -> void:
	if view == null or not is_instance_valid(view):
		return
	var dr = view._dark_rect
	if dr != null and is_instance_valid(dr):
		if on and _dark0 == null:
			_dark0 = dr.color
			dr.color = Color(0.2, 0.21, 0.3)
		elif not on and _dark0 != null:
			dr.color = _dark0
			_dark0 = null
	if view._lights != null and is_instance_valid(view._lights):
		view._lights.modulate = Color(1, 1, 1, 0.22) if on else Color(1, 1, 1, 1)


# ---------------------------------------------------------------- how they go about it

## They walk at you (each kind in its own way); what stands in their way they slide along, or walk round for a
## moment.
func _move(delta: float, pp: Vector2) -> void:
	if not flock_warn.is_empty():                           # the flock: announced, then it comes
		flock_warn["t"] = float(flock_warn["t"]) - delta
		if float(flock_warn["t"]) <= 0.0:
			_flock()
	if sleep_on and _frame % 12 == 0:                       # those who lay there rise when you come near
		var sq := sleepers.size() - 1
		while sq >= 0:
			var sl: Dictionary = sleepers[sq]
			if (sl["pos"] as Vector2).distance_squared_to(pp) < 78.0 * 78.0:
				var ri := add_foe(_swarm_k, sl["pos"])
				if ri >= 0:
					fhp[ri] = fhp[ri] * 1.5
					fmx[ri] = fhp[ri]
					fv[ri] = int(sl["v"]) % 4
					pops.append({"pos": sl["pos"], "t": 0.0})
				sleepers.remove_at(sq)
			sq -= 1
	var gone: Array = []
	var hurt_ok := can_hurt()
	for i in n:
		var k := fk[i]
		var b := _beh[k]
		if fflash[i] > 0.0:
			fflash[i] -= delta
		if b >= SD.BOSS_BEH:
			continue                                          # (a boss: its own step)
		if ffr[i] > 0.0 or fstun[i] > 0.0:                  # frozen or stunned: it stands where it is, and touches nobody
			ffr[i] = maxf(0.0, ffr[i] - delta)
			fstun[i] = maxf(0.0, fstun[i] - delta)
			continue
		var p := fp[i]
		if fovr[i] > 0.0:                                   # (part 8b) turned by an Override: it goes for the machines near it and leaves you be
			fovr[i] -= delta
			if fovr[i] <= 0.0:
				fst[i] = 0
				ftm[i] = 0.0
			if ((_frame + i) % 6) == 0:                         # (now and then it looks for the nearest one that is not turned)
				var tb := -1
				var td := 70.0 * 70.0
				for j in touching(p, 70.0):
					if j < n and j != i and fovr[j] <= 0.0 and _beh[fk[j]] < SD.BOSS_BEH and _beh[fk[j]] != 5:
						var dj := fp[j].distance_squared_to(p)
						if dj < td:
							td = dj
							tb = j
				if tb >= 0:
					fvel[i] = (fp[tb] - p).normalized()
					if td < pow(_rad[k] + _rad[fk[tb]] + 6.0, 2.0):
						_ovr_hits.append([fp[tb], maxf(4.0, _dmg[k]) * 3.0, p])
				else:
					fvel[i] = Vector2.ZERO
			var oq := p + fvel[i] * _spd[k] * delta
			if _solid[(int(oq.x) >> 4) + (int(oq.y) >> 4) * _w] == 0:
				fp[i] = oq
			if fvel[i] != Vector2.ZERO:
				fface[i] = (3 if fvel[i].x > 0.0 else 2) if absf(fvel[i].x) > absf(fvel[i].y) * 1.2 else (0 if fvel[i].y > 0.0 else 1)
			continue
		if b == 5:                                          # it flies straight on, over everything, and is gone
			p += fvel[i] * delta
			fp[i] = p
			ftm[i] -= delta
			if ftm[i] <= 0.0:
				gone.append(i)
			elif hurt_ok and _dmg[k] > 0.0 and p.distance_squared_to(pp) < pow(_rad[k] + 4.5, 2.0):
				_hurt(_dmg[k])
				hurt_ok = false
			if k == _glider_k:                                # (part 9b) a glider lets chunks of ice fall along its way, each onto a mark
				fbo[i] -= delta
				if fbo[i] <= 0.0:
					fbo[i] = 0.16
					if p.x > 24.0 and p.y > 24.0 and p.x < _w * TL - 24.0 and p.y < _h * TL - 24.0 and _solid[_ti(p)] == 0 and shells.size() < 80:
						var gr := float(SD.FOES["glider"]["chunk_r"])
						shells.append({"from": p, "pos": p, "t": 0.0, "len": 0.75, "r": gr, "dmg": float(SD.FOES["glider"]["chunk"]), "foes": 0.0, "ice": true})
						if tele.size() < 90:
							tele.append({"kind": "spot", "pos": p, "r": gr, "t": 0.0, "len": 0.75})
			continue
		if b == 13 and fst[i] < 2:                          # (part 9a) the burrower under the ice: nothing reaches it, it touches nobody
			var ud := pp + _lead - p                          # (it heads for where you will be in a moment)
			var ul := ud.length()
			if fst[i] == 0:
				if ul > 9.0 or _solid[_ti(p)] != 0:
					fp[i] = p + ud * (_spd[k] * _bur_pace / maxf(ul, 0.5)) * delta
				else:                                           # it is there: it stops, a mark shows where it will break out
					fst[i] = 1
					ftm[i] = _bur_warn
			else:
				ftm[i] -= delta
				if ftm[i] <= 0.0:
					_erupt(i)
					if hurt_ok and p.distance_squared_to(pp) < _bur_r * _bur_r:
						_hurt(_bur_dmg * (1.5 if fal[i] != 0 else 1.0))
						hurt_ok = false
			continue
		var d := pp - p
		var dl := d.length()
		var v := Vector2.ZERO
		if b == 0:
			if dl > 0.5:
				v = d * (_spd[k] / dl)
		elif dl > 0.5 or fst[i] != 0:                       # (one in the middle of what its kind does goes on with it, even standing right on you)
			v = _want(i, b, k, d, maxf(dl, 0.6), delta)
		if fbo[i] > 0.0:                                    # (a howler drives it on)
			fbo[i] -= delta
			v *= 1.5
		var det := fdet[i]
		if det != 0.0:
			v = v.rotated(1.25 if det > 0.0 else -1.25)
			fdet[i] = move_toward(det, 0.0, delta)
		if _haz[(int(p.x) >> 4) + (int(p.y) >> 4) * _w] == 1:
			v *= 0.55
		if nova_r > 0.0 and dl < nova_r:
			v *= 0.6                                         # (the Nova Field slows all in it)
		var kb := fkb[i]
		if kb != Vector2.ZERO:
			v += kb
			fkb[i] = kb * maxf(0.0, 1.0 - delta * 9.0) if kb.length_squared() > 4.0 else Vector2.ZERO
		var q := p + v * delta
		if _solid[(int(q.x) >> 4) + (int(q.y) >> 4) * _w] != 0:
			if absf(v.x) > 2.0 and _solid[(int(q.x) >> 4) + (int(p.y) >> 4) * _w] == 0:
				q = Vector2(q.x, p.y)
			elif absf(v.y) > 2.0 and _solid[(int(p.x) >> 4) + (int(q.y) >> 4) * _w] == 0:
				q = Vector2(p.x, q.y)
			else:
				q = p
			if det == 0.0:
				fdet[i] = 0.7 if (i & 1) == 0 else -0.7
		fp[i] = q
		if absf(d.x) > absf(d.y) * 1.2:
			fface[i] = 3 if d.x > 0.0 else 2
		else:
			fface[i] = 0 if d.y > 0.0 else 1
		if hurt_ok and _dmg[k] > 0.0 and dl < _rad[k] + 5.0:
			_hurt(_dmg[k] * (1.5 if fal[i] != 0 else 1.0))
			hurt_ok = false
		elif shield_t > 0.0 and _dmg[k] > 0.0 and dl < _rad[k] + 5.0:
			shield_hit = 0.18                                 # (part 7f) one of them is at the Shield: it flashes
	gone.reverse()
	for gi in gone:
		_remove(gi)


## Where one that does not just walk at you wants to go (its pace in the length of the way; ZERO: it stands).
func _want(i: int, b: int, k: int, d: Vector2, dl: float, delta: float) -> Vector2:
	match b:
		1:                                                  # the runner: fast, in a zigzag
			return d.rotated(sin(float(run["t"]) * 5.0 + i * 1.3) * 0.6) * (_spd[k] / dl)
		2:                                                  # the hauler: near you it winds up, then it stamps
			ftm[i] -= delta
			if fst[i] == 1:
				if ftm[i] <= 0.0:
					_stomp(i)
					fst[i] = 0
					ftm[i] = 2.6
				return Vector2.ZERO
			if dl < 46.0 and ftm[i] <= 0.0:
				fst[i] = 1
				ftm[i] = 0.9
				return Vector2.ZERO
			return d * (_spd[k] / dl)
		3:                                                  # the spitter: it keeps its distance, and spits
			ftm[i] -= delta
			if fst[i] == 1:
				if ftm[i] <= 0.0:
					if globs.size() < 300:
						globs.append({"p": fp[i], "v": d * (70.0 / dl), "life": 3.6, "clean": false})
					Audio.play("sv_spit", "survivor: a spitter", -16.0)
					fst[i] = 0
					ftm[i] = rng.randf_range(2.2, 3.0)
				return Vector2.ZERO
			if ftm[i] <= 0.0 and dl < 230.0 and dl > 30.0:
				fst[i] = 1
				ftm[i] = 0.5
				return Vector2.ZERO
			if dl < 90.0:
				return d * (-_spd[k] * 0.8 / dl)
			if dl > 150.0:
				return d * (_spd[k] / dl)
			return Vector2.ZERO
		10:                                                 # (part 8b) the bulwark: it walks at you; now and then it stops and lobs a shell onto where you stand
			ftm[i] -= delta
			if fst[i] == 1:
				if ftm[i] <= 0.0:
					var sr := float(SD.FOES["bulwark"]["shell_r"])
					shells.append({"from": fp[i], "pos": fp[i] + d, "t": 0.0, "len": 1.2, "r": sr, "dmg": float(SD.FOES["bulwark"]["shell"]), "foes": 0.0})
					tele.append({"kind": "spot", "pos": fp[i] + d, "r": sr, "t": 0.0, "len": 1.2})
					Audio.play("sv_shell", "survivor: a bulwark's shell", -12.0)
					fst[i] = 0
					ftm[i] = rng.randf_range(3.6, 5.0)
				return Vector2.ZERO
			if ftm[i] <= 0.0 and dl < 240.0 and dl > 50.0:
				fst[i] = 1
				ftm[i] = 0.5
				return Vector2.ZERO
			return d * (_spd[k] / dl)
		11:                                                 # (part 8b) the seeker: it rolls straight at you; near you it arms itself, then it goes off
			if fst[i] == 1:
				ftm[i] -= delta
				if ftm[i] <= 0.0:
					fst[i] = 2
					_arming = true
				return d * (_spd[k] * 0.25 / dl)
			if fst[i] == 2:
				_arming = true
				return Vector2.ZERO
			if dl < 18.0:
				fst[i] = 1
				ftm[i] = 0.35
				Audio.play("sv_mine", "survivor: a seeker arms", -14.0)
			return d * (_spd[k] / dl)
		12:                                                 # (part 8b) the jammer: it keeps well back; the machines near it carry a shield while it lives
			ftm[i] -= delta
			if ftm[i] <= 0.0:
				ftm[i] = 0.5
				var jam := float(SD.FOES["jammer"]["jam"])
				for j in touching(fp[i], float(SD.FOES["jammer"]["jam_r"])):
					if j < n and j != i and _beh[fk[j]] != 12 and _beh[fk[j]] != 5 and _beh[fk[j]] < SD.BOSS_BEH and fovr[j] <= 0.0:
						fsh[j] = maxf(fsh[j], jam)
			if dl < 140.0:
				return d * (-_spd[k] / dl)
			if dl > 200.0:
				return d * (_spd[k] / dl)
			return Vector2.ZERO
		8:                                                  # (part 8) the scout: it runs in a zigzag; near you it crouches, then it leaps straight on
			match fst[i]:
				1:
					ftm[i] -= delta
					if ftm[i] <= 0.0:
						fst[i] = 2
						ftm[i] = 0.34
					return Vector2.ZERO
				2:
					ftm[i] -= delta
					if ftm[i] <= 0.0:
						fst[i] = 3
						ftm[i] = 0.6
					return fvel[i] * 190.0
				3:
					ftm[i] -= delta
					if ftm[i] <= 0.0:
						fst[i] = 0
					return Vector2.ZERO
			if dl < 52.0:
				fst[i] = 1
				ftm[i] = 0.28
				fvel[i] = d / dl
				return Vector2.ZERO
			return d.rotated(sin(float(run["t"]) * 5.0 + i * 1.3) * 0.5) * (_spd[k] / dl)
		9:                                                  # (part 8) the gunner: it keeps its distance, takes aim along a line, fires three bolts along it
			ftm[i] -= delta
			if fst[i] == 1:
				if ftm[i] <= 0.0:
					fst[i] = 2
				return Vector2.ZERO
			if fst[i] >= 2:
				if ftm[i] <= 0.0:
					if globs.size() < 300:
						globs.append({"p": fp[i], "v": fvel[i] * 150.0, "life": 2.0, "clean": true, "bolt": true, "dmg": float(SD.FOES["gunner"]["bolt"])})
					Audio.play("sv_shot", "survivor: a gunner", -18.0)
					if fst[i] >= 4:
						fst[i] = 0
						ftm[i] = rng.randf_range(2.4, 3.4)
					else:
						fst[i] = fst[i] + 1
						ftm[i] = 0.16
				return Vector2.ZERO
			if ftm[i] <= 0.0 and dl < 210.0 and dl > 40.0:
				fst[i] = 1
				ftm[i] = 0.7
				fvel[i] = d / dl
				return Vector2.ZERO
			if dl < 80.0:
				return d * (-_spd[k] * 0.8 / dl)
			if dl > 140.0:
				return d * (_spd[k] / dl)
			return Vector2.ZERO
		14:                                                 # (part 9b) the shardthrower: it keeps its distance, raises its arm (lines show where), throws needles of ice in a fan
			ftm[i] -= delta
			if fst[i] == 1:
				if ftm[i] <= 0.0:
					var st_d: Dictionary = SD.FOES["shardthrower"]
					var cnt := int(st_d["fan"]) + (2 if fal[i] != 0 else 0)
					for q8 in cnt:
						if globs.size() < 300:
							globs.append({"p": fp[i], "v": fvel[i].rotated((q8 - (cnt - 1) * 0.5) * float(st_d["spread"])) * 130.0, "life": 2.2, "clean": true, "bolt": true, "needle": true,
								"dmg": float(st_d["needle"])})
					Audio.play("sv_ice", "survivor: a shardthrower", -16.0)
					fst[i] = 0
					ftm[i] = rng.randf_range(2.8, 3.8)
				return Vector2.ZERO
			if ftm[i] <= 0.0 and dl < 200.0 and dl > 40.0:
				fst[i] = 1
				ftm[i] = 0.7
				fvel[i] = d / dl
				return Vector2.ZERO
			if dl < 80.0:
				return d * (-_spd[k] * 0.8 / dl)
			if dl > 150.0:
				return d * (_spd[k] / dl)
			return Vector2.ZERO
		13:                                                 # (part 9a) the burrower above the ice: it comes at you for a while, then it dives again
			ftm[i] -= delta
			if fst[i] == 3:
				if ftm[i] <= 0.0:
					fst[i] = 0
				return Vector2.ZERO
			if ftm[i] <= 0.0:
				fst[i] = 3
				ftm[i] = 0.45
				return Vector2.ZERO
			return d * (_spd[k] / dl)
		4:                                                  # the howler: it stands and howls: those near it walk faster
			if fst[i] == 0:
				if dl > 170.0:
					return d * (_spd[k] / dl)
				fst[i] = 1
				ftm[i] = 0.0
			ftm[i] -= delta
			if ftm[i] <= 0.0:
				ftm[i] = 0.4
				for j in touching(fp[i], HOWL_R):
					if j < n and j != i and _beh[fk[j]] < 5:
						fbo[j] = 0.7
				if _frame % 3 == 0:
					Audio.play("sv_howl", "survivor: a howler", -18.0)
			if dl > 260.0:
				fst[i] = 0
			return Vector2.ZERO
	return d * (_spd[k] / dl)


## (Part 9a) Is this one a burrower under the ice? (Nothing reaches it there: no hit, no cold, no shock; it is
## not in the grid of cells, so nothing that looks for who stands near finds it.)
func _under(i: int) -> bool:
	return _digs[fk[i]] != 0 and fst[i] < 2


## (Part 9a) A burrower breaks out of the ice: from now on it is above for a while.
func _erupt(i: int) -> void:
	fst[i] = 2
	ftm[i] = _bur_up
	if tele.size() < 90:
		tele.append({"kind": "erupt", "pos": fp[i], "r": _bur_r, "t": 0.0, "len": 0.45})
	Audio.play("sv_ice", "survivor: a burrower breaks out", -10.0)


## A hauler stamps: who stands near takes it and is thrown back.
func _stomp(i: int) -> void:
	var p := fp[i]
	var pp: Vector2 = view.pilot.pos
	tele.append({"kind": "stomp", "pos": p, "r": STOMP_R, "t": 0.0, "len": 0.4})
	Audio.play("sv_stomp", "survivor: a stamp", -8.0)
	if can_hurt() and p.distance_to(pp) < STOMP_R:
		_hurt(22.0 * (1.5 if fal[i] != 0 else 1.0))
		throw_you((pp - p).normalized(), 0.28)


## You are thrown back, for a moment, that way.
func throw_you(dir: Vector2, secs: float) -> void:
	if dir.length() < 0.1:
		dir = Vector2.DOWN
	kb_dir = dir.normalized()
	kb_t = secs


## The flock comes: a wedge of screechers from one side, straight through where you stood.
func _flock() -> void:
	var dir: Vector2 = flock_warn["dir"]
	var at: Vector2 = flock_warn["at"]
	flock_warn = {}
	var far := _half().length() + 40.0
	var cnt := 9 + int(float(run["t"]) / 150.0)
	var k: int = _ki[String(stg["flock"]) if String(stg["flock"]) != "" else "screecher"]
	var side := dir.orthogonal()
	if String(stg["flock"]) in ["hunter", "glider"]:        # (part 8b) one hunter, later two abreast: each burns along its line; (part 9b) gliders: one more of them
		var hn := (1 if float(run["t"]) < 480.0 else 2) + (1 if String(stg["flock"]) == "glider" else 0)
		for hq in hn:
			var hi := add_foe(k, at - dir * far + side * (float(hq) - float(hn - 1) * 0.5) * 46.0)
			if hi < 0:
				break
			fvel[hi] = dir * _spd[k]
			ftm[hi] = (far * 2.0 + 160.0) / _spd[k]
			fface[hi] = 3 if dir.x > 0.0 else 2
		tele.append({"kind": "strafe", "pos": at, "dir": dir, "r": far, "n": hn, "t": 0.0, "len": (far * 2.0 + 160.0) / _spd[k]})
		Audio.play("sv_beam", "survivor: hunters", -8.0)
		return
	for q in cnt:
		var off := float(q) - float(cnt - 1) * 0.5
		var i := add_foe(k, at - dir * (far + absf(off) * 12.0) + side * off * 15.0)
		if i < 0:
			break
		fvel[i] = dir * _spd[k]
		ftm[i] = (far * 2.0 + 160.0) / _spd[k]
		fface[i] = 3 if dir.x > 0.0 else 2


## What they throw: acid on its way (it hurts you where it meets you, and lies in a pool where it lands), a boss's
## rings of force, warnings running out.
func _thrown(delta: float, pp: Vector2) -> void:
	var q := globs.size() - 1
	while q >= 0:
		var g: Dictionary = globs[q]
		var p: Vector2 = (g["p"] as Vector2) + (g["v"] as Vector2) * delta
		g["p"] = p
		g["life"] = float(g["life"]) - delta
		var gone := false
		if p.distance_squared_to(pp) < 64.0 and can_hurt():
			_hurt(float(g.get("dmg", 9.0)))
			gone = true
		elif float(g["life"]) <= 0.0 or _solid[_ti(p)] != 0:
			gone = true
			if not bool(g["clean"]) and pools.size() < 60:
				pools.append({"pos": p - (g["v"] as Vector2) * delta, "r": 13.0, "t": 0.0, "life": 2.6, "kind": "acid", "dps": 12.0})
		if gone:
			globs.remove_at(q)
		q -= 1
	q = waves.size() - 1
	while q >= 0:
		var w: Dictionary = waves[q]
		w["r"] = float(w["r"]) + float(w["speed"]) * delta
		if not bool(w["hit"]) and absf((w["pos"] as Vector2).distance_to(pp) - float(w["r"])) < 9.0 and can_hurt():
			w["hit"] = true
			_hurt(float(w["dmg"]))
			throw_you(pp - (w["pos"] as Vector2), 0.2)
		if float(w["r"]) >= float(w["to"]):
			waves.remove_at(q)
		q -= 1


## The grid of cells: who stands in which (for the pushing apart, and for what your weapons touch).
func _grid() -> void:
	_head.fill(-1)
	for i in n:
		if _digs[fk[i]] != 0 and fst[i] < 2:                # (part 9a) one under the ice is in no cell
			_next[i] = -1
			continue
		var p0 := fp[i]
		var c := clampi(int(p0.x / CELL), 0, _gw - 1) + clampi(int(p0.y / CELL), 0, _gh - 1) * _gw      # (one that flies may be beyond the edge of the ground: it goes into the cell at the edge)
		_next[i] = _head[c]
		_head[c] = i


## They push each other apart: each one against those in its own cell and the cells after it.
func _separate() -> void:
	var r2 := SEP * SEP
	for i in n:
		if _nosep[fk[i]] != 0 or (_digs[fk[i]] != 0 and fst[i] < 2):
			continue
		var p := fp[i]
		var cx := int(p.x / CELL)
		var cy := int(p.y / CELL)
		for o in 5:
			var j := -1
			match o:
				0:
					j = _next[i]
				1:
					j = _head[cx + 1 + cy * _gw]
				2:
					j = _head[cx - 1 + (cy + 1) * _gw]
				3:
					j = _head[cx + (cy + 1) * _gw]
				_:
					j = _head[cx + 1 + (cy + 1) * _gw]
			while j >= 0:
				var d := p - fp[j]
				var l2 := d.length_squared()
				if l2 < r2 and _nosep[fk[j]] == 0:
					if l2 < 0.01:
						d = Vector2(0.5 - float(i & 1), 0.3)
						l2 = d.length_squared()
					var l := sqrt(l2)
					var m := d * ((SEP - l) / l * 0.5)
					var a := p + m
					if _solid[(int(a.x) >> 4) + (int(a.y) >> 4) * _w] == 0:
						p = a
					var b := fp[j] - m
					if _solid[(int(b.x) >> 4) + (int(b.y) >> 4) * _w] == 0:
						fp[j] = b
				j = _next[j]
		fp[i] = p


## A hit: a shield takes it first; else thrown back a little, and out when nothing is left.
func _hit(i: int, dmg: float, from: Vector2) -> void:
	if fk[i] == _core_k and boss_kind == "core" and _cnt[_pylon_k] > 0:      # (part 8c) The Core behind its shield: nothing reaches it while a pylon stands
		_guard_t = 0.3
		return
	if _digs[fk[i]] != 0 and fst[i] < 2:
		return                                            # (part 9a) one under the ice (a burrower, The Ice Worm): nothing reaches it
	fflash[i] = 0.12
	if _shatter and ffr[i] > 0.0 and _beh[fk[i]] < 6:        # Absolute Zero: what is frozen shatters at the next hit
		ffr[i] = 0.0
		fsh[i] = 0.0
		dmg = dmg * 4.0 if (_tough[fk[i]] != 0 or fal[i] != 0) else 1000000.0
		if tele.size() < 90:
			tele.append({"kind": "break", "pos": fp[i], "r": 12.0, "t": 0.0, "len": 0.25})
	var hard := false
	var crit := float(mods.get("crit", 0.0))
	if crit > 0.0 and dmg < 100000.0 and rng.randf() < crit:  # the Capacitor: now and then twice as hard
		dmg *= 2.0
		fflash[i] = 0.22
		hard = true
	if fsh[i] > 0.0:
		fnum[i] += minf(dmg, fsh[i])                        # (what it took, for its number)
		fnc[i] = _src | 32 | (64 if hard else 0)
		fsh[i] -= dmg
		if fsh[i] <= 0.0:                                   # the shield breaks
			fsh[i] = 0.0
			if _shield[fk[i]] > 0.0:
				fv[i] = 2 + (fv[i] & 1)                           # (a shieldbearer's own shield: its picture without it)
			tele.append({"kind": "break", "pos": fp[i], "r": 14.0, "t": 0.0, "len": 0.3})
			Audio.play("sv_break", "survivor: a shield breaks", -12.0)
		return
	fnum[i] += minf(dmg, fhp[i])
	fnc[i] = _src | (64 if (hard or (fnc[i] & 64) != 0) else 0)
	fhp[i] -= dmg
	var m := _mass[fk[i]] * (0.4 if fal[i] != 0 else 1.0)
	var d := fp[i] - from
	var wk := _wkb[_src & 15] * _kbk                         # (the Pulse throws far; what pulls them in does not throw at all)
	if m > 0.0 and wk > 0.0 and d.length_squared() > 0.01:
		fkb[i] = d.normalized() * 46.0 * m * wk * float(mods.get("kb", 1.0))      # (the Mass Driver: thrown back further)
	if fhp[i] <= 0.0:
		_num(fp[i], fk[i], fnum[i], fnc[i])                # (its last number at once: it is gone in a moment)
		fnum[i] = 0.0
		_kill(i)


## (Part 10a, Luz) How many of each kind this run has put out so far: {kind: count}. (For the collection.)
func slain() -> Dictionary:
	var out := {}
	for k in _slain.size():
		if _slain[k] > 0:
			out[String(SD.FOE_ORDER[k])] = _slain[k]
	return out


## One is out: shards where it stood (and what its kind leaves); the last of the rows takes its place.
func _kill(i: int) -> void:
	var k := fk[i]
	var p := fp[i]
	var kind := String(SD.FOE_ORDER[k])
	run["kills"] = int(run["kills"]) + 1
	if _slain.size() <= k:
		_slain.resize(SD.FOE_ORDER.size())
	_slain[k] += 1
	if pops.size() < 60:
		pops.append({"pos": p, "t": 0.0})
	if fal[i] != 0:                                         # an alpha: a great shard, a crate
		run["alphas"] = int(run.get("alphas", 0)) + 1
		_drop(p, 20)
		crates.append({"pos": near_free(p, 14.0), "great": false, "fall": 0.0, "mark": true, "weapon": true})      # (part 7f: a weapon crate)
	elif kind != boss_kind:                                 # (a boss leaves a burst of shards instead: see _boss_out)
		_drop(p, _xp[k])
	if kind == "seeker":                                    # (part 8b) a seeker put out goes off where it is
		booms.append(p)
	if kind == "pylon" and boss_kind == "core" and bst.has("aims"):      # (part 8c) a pylon falls: what it aimed goes with it; the last one takes the shield with it
		bst["aims"] = (bst["aims"] as Array).filter(func(a): return (a["from"] as Vector2).distance_squared_to(p) > 4.0)
		if blasts.size() < 40:
			blasts.append({"pos": p, "r": 26.0, "t": 0.0})
		if _cnt[k] <= 1:
			bst["aims"] = []
			bst["warm"] = 1.6
			say("shield")
			Audio.play("sv_break", "survivor: the shield falls", -2.0)
	if kind == "bloater" and pools.size() < 60:             # a bloater bursts: a cloud that stays for a while
		pools.append({"pos": p, "r": 44.0, "t": 0.0, "life": 5.0, "kind": "cloud", "dps": 10.0})
		Audio.play("sv_spit", "survivor: a bloater bursts", -10.0)
	var was_boss := kind == boss_kind
	_remove(i)
	if was_boss:
		_boss_out(kind, p)


func _drop(p: Vector2, value: int) -> void:
	if sn >= 500:                                           # the ground is full of them: the one furthest from you comes here, with what it was worth
		var pp: Vector2 = view.pilot.pos                     # (Luz, 24 Nov 2026: it used to join one by lot, anywhere on the field: late in a run nobody seemed to drop a shard)
		var far := 0
		var fd := -1.0
		for q in sn:
			var dq := sp[q].distance_squared_to(pp)
			if dq > fd:
				fd = dq
				far = q
		sp[far] = p
		sv[far] = sv[far] + value
		stier[far] = SD.shard_tier(sv[far])
		spull[far] = 0
		return
	sp[sn] = p
	sv[sn] = value
	stier[sn] = SD.shard_tier(value)
	spull[sn] = 0
	sn += 1


func _hurt(dmg: float) -> void:
	if shield_t > 0.0:
		return
	if float(mods.get("cell", 0.0)) > 0.0 and cell_t <= 0.0:   # the Shield Cell takes this one, then charges again
		cell_t = float(mods["cell"])
		hurt_cd = SD.HURT_GAP
		tele.append({"kind": "break", "pos": view.pilot.pos, "r": 18.0, "t": 0.0, "len": 0.3})
		Audio.play("sv_break", "survivor: the shield cell", -10.0)
		return
	run["hp"] = float(run["hp"]) - dmg
	hurt_cd = SD.HURT_GAP
	_flash = 0.15
	view.pilot.modulate = Color(1.0, 0.45, 0.45)
	Audio.play("ui_error", "survivor: hit", -10.0)


# ---------------------------------------------------------------- the bosses

## A boss comes: walls of light close round a field about you, it stands in it with you. Nobody new comes while
## they stand (those already there stay).
func boss_start(kind: String) -> void:
	if not _ki.has(kind) or boss_kind != "":
		return
	var pp: Vector2 = view.pilot.pos
	var hb: Vector2 = SD.BARRIER * 0.5
	var want := pp + (Vector2(0.0, -96.0) if kind in ["core", "heart"] else Vector2.ZERO)      # (part 8c: The Core stands in the middle of its field, you south of it; part 9c: so does The Storm Heart)
	var c := Vector2(clampf(want.x, 48.0 + hb.x, _w * TL - 48.0 - hb.x), clampf(want.y, 48.0 + hb.y, _h * TL - 48.0 - hb.y))
	barrier = Rect2(c - hb, SD.BARRIER)
	barrier_on = true
	barrier_k = 0.0
	boss_done[kind] = true
	boss_kind = kind
	var spot := c + (c - pp).normalized() * 90.0 + Vector2(0.0, -30.0)
	if kind in ["foreman", "warden", "worm"]:
		spot = c + Vector2(0.0, -hb.y * 0.55)
	elif kind in ["core", "heart"]:
		spot = c
	var at := near_free(spot, 40.0)
	if at.distance_to(pp) < 70.0:
		at = near_free(pp + Vector2(0.0, -110.0), 30.0)
	var i := add_foe(_ki[kind], at)
	if i < 0:                                               # (the field is full: one of the swarm makes room)
		_make_room()
		i = add_foe(_ki[kind], at)
	bst = {"st": "walk", "t": 2.0, "n": 0, "ring": 2.0, "spawn": 1.5, "spiral": 0.0, "a": 0.0, "flock": 6.0,
		"warm": 1.6, "salvo": 3.5, "stomp": 0.0, "fire": 2.2, "next": 0, "aims": [], "field": 2.0}      # (part 8c: what The Warden and The Core keep count of)
	fields.clear()
	in_storm = false
	if kind == "worm" and i >= 0:                           # (part 9c) it begins under the ice
		bst["st"] = "under"
		bst["t"] = 2.2
		bst["trail"] = PackedVector2Array()
		bst["spots"] = []
		bst["si"] = 0
		fst[i] = 0
	if kind == "heart":                                     # … the eye of its storm, wide open
		bst["eye"] = SD.EYE_MAX
		bst["tick"] = 0.5
		bst["strike"] = 1.5
		bst["ring"] = 2.4
		bst["spawn"] = 3.0
		bst["flock"] = 5.0
	if kind == "core":                                      # (part 8c) its four pylons round it
		bst["spawn"] = 4.0
		for off in [Vector2(-104.0, -62.0), Vector2(104.0, -62.0), Vector2(-104.0, 66.0), Vector2(104.0, 66.0)]:
			if n >= foe_cap:
				_make_room()
			add_foe(_pylon_k, near_free(at + off, 16.0))
	say(kind)
	Audio.play("sv_alarm", "survivor: %s" % kind, -6.0)


## Where the boss stands in the rows (-1: none).
func boss_i() -> int:
	if boss_kind == "":
		return -1
	var k: int = _ki[boss_kind]
	for i in n:
		if fk[i] == k:
			return i
	return -1


## What the display says of the boss: {} or {"name", "k" (what is left of it, 0 … 1), "phase"}.
func boss_info() -> Dictionary:
	var i := boss_i()
	if i < 0:
		return {}
	var k := clampf(fhp[i] / maxf(1.0, fmx[i]), 0.0, 1.0)
	var out := {"name": String(SD.FOES[boss_kind]["name"]), "k": k, "phase": 1 if k > 0.66 else (2 if k > 0.33 else 3)}
	if boss_kind == "core":                                 # (part 8c) The Core: behind its shield while a pylon stands ("shield": how many), then its cross, then the floor
		out["shield"] = _cnt[_pylon_k]
		out["phase"] = 1 if _cnt[_pylon_k] > 0 else (2 if k > SD.CORE_LAST else 3)
	if boss_kind == "worm":                                 # (part 9c) The Ice Worm: under the ice, or above it
		out["under"] = fst[i] < 2
	return out


func _boss(delta: float, pp: Vector2) -> void:
	var i := boss_i()
	if i < 0:
		return
	var p := fp[i]
	var d := pp - p
	var dl := maxf(1.0, d.length())
	var t := float(bst["t"]) - delta
	bst["t"] = t
	if absf(d.x) > absf(d.y) * 1.2:
		fface[i] = 3 if d.x > 0.0 else 2
	else:
		fface[i] = 0 if d.y > 0.0 else 1
	if boss_kind == "worm":                                 # (part 9c) the bosses of Whiteout
		_worm(i, p, delta, pp)
		return
	if boss_kind == "heart":
		_heart(i, p, delta, pp)
		return
	if can_hurt() and dl < _rad[fk[i]] + 6.0:                 # to touch it hurts
		_hurt(_dmg[fk[i]])
		throw_you(d, 0.22)
	if boss_kind == "warden":
		_warden(i, p, d, dl, delta, pp)
		return
	if boss_kind == "core":
		_core(p, delta, pp)
		return
	if boss_kind == "foreman":
		match String(bst["st"]):
			"walk":                                           # it comes at you; then, in turn: a charge, a blow on the ground, containers
				_boss_go(i, d * (_spd[fk[i]] / dl), delta)
				if t <= 0.0:
					var nx := int(bst["n"]) % 3
					bst["n"] = int(bst["n"]) + 1
					if nx == 0:
						bst["st"] = "aim"
						bst["t"] = 0.9
						bst["dir"] = d / dl
					elif nx == 1:
						bst["st"] = "wind"
						bst["t"] = 0.8
					else:
						bst["st"] = "throw"
						bst["t"] = 1.1
						bst["spots"] = [pp, near_free(pp + Vector2.from_angle(rng.randf() * TAU) * 60.0, 20.0), near_free(pp + Vector2.from_angle(rng.randf() * TAU) * 90.0, 20.0)]
						for sp0 in bst["spots"]:
							tele.append({"kind": "spot", "pos": sp0, "r": 28.0, "t": 0.0, "len": 1.1})
			"aim":                                            # the line it will charge along (it follows you until just before)
				if t > 0.3:
					bst["dir"] = d / dl
				if t <= 0.0:
					bst["st"] = "charge"
					bst["t"] = 0.85
					Audio.play("sv_stomp", "survivor: the charge", -6.0)
			"charge":
				var before := fp[i]
				_boss_go(i, (bst["dir"] as Vector2) * 300.0, delta)
				if can_hurt() and fp[i].distance_to(pp) < 20.0:
					_hurt(24.0)
					throw_you(bst["dir"], 0.3)
				if t <= 0.0 or fp[i].distance_to(before) < 1.0:
					bst["st"] = "walk"
					bst["t"] = 1.6
			"wind":                                           # it raises both arms; then a ring of force runs out from it
				if t <= 0.0:
					waves.append({"pos": p, "r": 12.0, "to": 180.0, "speed": 170.0, "dmg": 18.0, "hit": false})
					tele.append({"kind": "stomp", "pos": p, "r": 40.0, "t": 0.0, "len": 0.4})
					Audio.play("sv_stomp", "survivor: the blow", -4.0)
					bst["st"] = "walk"
					bst["t"] = 1.8
			"throw":                                          # containers come down where the marks lie
				if t <= 0.0:
					for sp1 in bst["spots"]:
						blasts.append({"pos": sp1, "r": 28.0, "t": 0.0})
						if can_hurt() and (sp1 as Vector2).distance_to(pp) < 28.0:
							_hurt(20.0)
					Audio.play("sv_boom", "survivor: containers", -6.0)
					bst["st"] = "walk"
					bst["t"] = 2.0
	else:                                                   # The Brood: it stays where it is; what it does goes by what is left of it
		var ph := int(boss_info()["phase"])
		bst["ring"] = float(bst["ring"]) - delta
		bst["spawn"] = float(bst["spawn"]) - delta
		bst["spiral"] = float(bst["spiral"]) - delta
		bst["flock"] = float(bst["flock"]) - delta
		if ph != 2 and float(bst["ring"]) <= 0.0:              # rings of acid with a gap to slip through
			bst["ring"] = 3.2 if ph == 1 else 2.4
			var cnt := 18
			var gap := rng.randi() % cnt
			var gap2 := (gap + cnt / 2) % cnt if ph == 3 else gap
			var a0 := rng.randf() * TAU
			for q in cnt:
				if absi(q - gap) <= 1 or absi(q - gap + cnt) <= 1 or absi(q - gap - cnt) <= 1 or (ph == 3 and absi(q - gap2) <= 1):
					continue
				if globs.size() < 300:
					globs.append({"p": p + Vector2(0.0, -10.0), "v": Vector2.from_angle(a0 + q * TAU / cnt) * (55.0 if ph == 1 else 70.0), "life": 6.0, "clean": true})
			Audio.play("sv_spit", "survivor: the brood spits", -8.0)
		if ph >= 2 and float(bst["spiral"]) <= 0.0:            # two arms of acid turning round it
			bst["spiral"] = 0.11 if ph == 2 else 0.2
			bst["a"] = float(bst["a"]) + 0.3
			for arm in 2:
				if globs.size() < 300:
					globs.append({"p": p + Vector2(0.0, -10.0), "v": Vector2.from_angle(float(bst["a"]) + arm * PI) * 60.0, "life": 5.5, "clean": true})
		if float(bst["spawn"]) <= 0.0:                         # what it lets out
			bst["spawn"] = 2.6 if ph == 1 else 4.0
			var kk: int = _ki["shambler"] if ph == 1 else _ki["runner"]
			for q2 in (3 if ph == 1 else 2):
				if n < foe_cap - 20:
					add_foe(kk, near_free(p + Vector2.from_angle(rng.randf() * TAU) * 34.0, 14.0))
		if ph == 3 and float(bst["flock"]) <= 0.0 and flock_warn.is_empty():
			bst["flock"] = 9.0
			event("flock")


## (Part 9c) Needles of ice: a fan of `cnt` from `from` round the way `dir`, `spread` apart …
func _needle_fan(from: Vector2, dir: Vector2, cnt: int, spread: float, pace: float, dmg: float) -> void:
	for q in cnt:
		if globs.size() < 300:
			globs.append({"p": from, "v": dir.rotated((q - (cnt - 1) * 0.5) * spread) * pace, "life": 5.0, "clean": true, "bolt": true, "needle": true, "dmg": dmg})


## … and a ring of `cnt` all round `from`, beginning at `a0`, without those whose place is in `gaps`.
func _needle_ring(from: Vector2, cnt: int, a0: float, pace: float, dmg: float, gaps: Array = []) -> void:
	for q in cnt:
		if gaps.any(func(gq): return absi(q - int(gq)) <= 1 or absi(q - int(gq)) >= cnt - 1):
			continue
		if globs.size() < 300:
			globs.append({"p": from, "v": Vector2.from_angle(a0 + q * TAU / cnt) * pace, "life": 6.0, "clean": true, "bolt": true, "needle": true, "dmg": dmg})


## A spot The Ice Worm can break out at: inside its field, on free ground.
func _worm_spot(v: Vector2) -> Vector2:
	var inside := barrier.grow(-26.0)
	return near_free(Vector2(clampf(v.x, inside.position.x, inside.end.x), clampf(v.y, inside.position.y, inside.end.y)), 20.0)


## (Part 9c, Luz) The Ice Worm. Under the ice nothing reaches it: it circles you there, its long shape showing
## through. Then marks show where it will break out (one; from two thirds down three; from one third down five), and
## it breaks out at each in turn: who stands there is hurt and thrown, and from two thirds down needles of ice fly
## out all round. After the last it stays above for a while, and can be hurt; then it dives again.
func _worm(i: int, p: Vector2, delta: float, pp: Vector2) -> void:
	var wd: Dictionary = SD.FOES["worm"]
	var ph := int(boss_info()["phase"])
	var er := float(wd["erupt_r"])
	var t := float(bst["t"])
	if fst[i] == 2 and can_hurt() and p.distance_to(pp) < _rad[fk[i]] + 6.0:      # above the ice: to touch it hurts
		_hurt(_dmg[fk[i]])
		throw_you(pp - p, 0.22)
	if fst[i] < 2:                                          # under the ice: its body follows its head
		bst["tr_t"] = float(bst.get("tr_t", 0.0)) - delta
		if float(bst["tr_t"]) <= 0.0:
			bst["tr_t"] = 0.05
			var tr: PackedVector2Array = bst.get("trail", PackedVector2Array())
			tr.insert(0, p)
			if tr.size() > 16:
				tr.resize(16)
			bst["trail"] = tr
	match String(bst["st"]):
		"under":                                            # it circles you
			fst[i] = 0
			bst["a"] = float(bst["a"]) + delta * (1.6 + 0.4 * ph)
			var inside := barrier.grow(-24.0)
			var want := pp + Vector2.from_angle(float(bst["a"])) * 62.0
			fp[i] = p.move_toward(Vector2(clampf(want.x, inside.position.x, inside.end.x), clampf(want.y, inside.position.y, inside.end.y)), 170.0 * delta)
			if t <= 0.0:
				var spots: Array = [_worm_spot(pp + _lead)]
				var more := 0 if ph == 1 else (2 if ph == 2 else 4)
				var a0 := rng.randf() * TAU
				for q in more:
					spots.append(_worm_spot(pp + Vector2.from_angle(a0 + q * TAU / more) * (62.0 if ph == 2 else 76.0)))
				bst["spots"] = spots
				bst["si"] = 0
				bst["st"] = "mark"
				bst["t"] = float(wd["warn"])
				Audio.play("sv_alarm", "survivor: the worm's marks", -12.0)
		"mark":                                             # it breaks out at each mark in turn
			if t <= 0.0:
				var spots2: Array = bst["spots"]
				var si := int(bst["si"])
				var at: Vector2 = spots2[si]
				fp[i] = at
				fst[i] = 2
				fflash[i] = 0.12
				bst["trail"] = PackedVector2Array()
				tele.append({"kind": "erupt", "pos": at, "r": er * 1.25, "t": 0.0, "len": 0.5})
				Audio.play("sv_ice", "survivor: the worm breaks out", -4.0)
				Audio.play("sv_stomp", "survivor: the worm breaks out", -8.0)
				if can_hurt() and at.distance_to(pp) < er:
					_hurt(float(wd["erupt"]))
					throw_you(pp - at, 0.3)
				if ph >= 2:
					_needle_ring(at + Vector2(0.0, -6.0), 10, rng.randf() * TAU, 105.0, float(wd["needle"]))
				if si + 1 < spots2.size():
					bst["si"] = si + 1
					bst["t"] = 0.55                               # (it shows there for a moment; then it is at the next)
				else:
					bst["spots"] = []
					bst["st"] = "up"
					bst["t"] = 3.2 - 0.4 * (ph - 1)
					bst["spit"] = float(bst["t"]) * 0.5
		"up":                                               # above the ice: it can be hurt; from two thirds down it throws a fan of needles
			fst[i] = 2
			if ph >= 2 and float(bst.get("spit", -1.0)) > 0.0 and t <= float(bst["spit"]):
				bst["spit"] = -1.0
				_needle_fan(p + Vector2(0.0, -10.0), (pp - p).normalized(), 5, 0.22, 125.0, float(wd["needle"]))
				Audio.play("sv_ice", "survivor: the worm's needles", -12.0)
			if t <= 0.0:
				bst["st"] = "under"
				bst["t"] = 2.6 - 0.4 * (ph - 1)
				bst["a"] = (p - pp).angle()
				fst[i] = 0
				tele.append({"kind": "erupt", "pos": p, "r": er * 0.8, "t": 0.0, "len": 0.35})


## (Part 9c, Luz) The Storm Heart: a crystal in the eye of a storm. It does not move. The eye closes as the Heart is
## worn down; out in the storm you lose health twice a second, shield or no. Rings of needles with a gap to slip
## through; from two thirds down bolts of lightning onto marks; from one third down two arms of needles turning
## round it, and Gliders. Mites come in at the eye's edge all the while.
func _heart(i: int, p: Vector2, delta: float, pp: Vector2) -> void:
	var hd: Dictionary = SD.FOES["heart"]
	var bi := boss_info()
	var ph := int(bi["phase"])
	var d := pp - p
	if can_hurt() and d.length() < _rad[fk[i]] + 6.0:
		_hurt(_dmg[fk[i]])
		throw_you(d, 0.22)
	var eye := move_toward(float(bst["eye"]), lerpf(SD.EYE_MIN, SD.EYE_MAX, float(bi["k"])), 14.0 * delta)
	bst["eye"] = eye
	in_storm = d.length() > eye
	bst["tick"] = float(bst["tick"]) - delta
	if in_storm and float(bst["tick"]) <= 0.0:
		bst["tick"] = 0.5
		run["hp"] = float(run["hp"]) - SD.STORM_DMG
		_flash = 0.15
		view.pilot.modulate = Color(0.7, 0.85, 1.4)
	bst["ring"] = float(bst["ring"]) - delta
	bst["spiral"] = float(bst["spiral"]) - delta
	bst["spawn"] = float(bst["spawn"]) - delta
	bst["strike"] = float(bst["strike"]) - delta
	bst["flock"] = float(bst["flock"]) - delta
	if ph != 3 and float(bst["ring"]) <= 0.0:                # rings of needles, a gap to slip through
		bst["ring"] = 2.8 if ph == 1 else 2.2
		_needle_ring(p + Vector2(0.0, -8.0), 18, rng.randf() * TAU, 58.0 if ph == 1 else 70.0, float(hd["needle"]), [rng.randi() % 18])
		Audio.play("sv_ice", "survivor: the heart's needles", -10.0)
	if ph == 3 and float(bst["spiral"]) <= 0.0:              # two arms of needles turning round it
		bst["spiral"] = 0.15
		bst["a"] = float(bst["a"]) + 0.3
		for arm in 2:
			_needle_fan(p + Vector2(0.0, -8.0), Vector2.from_angle(float(bst["a"]) + arm * PI), 1, 0.0, 64.0, float(hd["needle"]))
	if ph >= 2 and float(bst["strike"]) <= 0.0:              # lightning onto a mark where you are going
		bst["strike"] = 1.5 if ph == 2 else 1.05
		var sat := pp + _lead * 0.6
		shells.append({"from": Vector2.INF, "pos": sat, "t": 0.0, "len": 0.9, "r": float(hd["strike_r"]), "dmg": float(hd["strike"]), "foes": 0.0, "zap": true})
		tele.append({"kind": "spot", "pos": sat, "r": float(hd["strike_r"]), "t": 0.0, "len": 0.9})
	if float(bst["spawn"]) <= 0.0:                            # mites come in at the eye's edge
		bst["spawn"] = 4.5
		for q in 3:
			var mp := p + Vector2.from_angle(rng.randf() * TAU) * (eye * 0.9)
			if n < foe_cap - 20 and barrier.grow(-10.0).has_point(mp) and _solid[_ti(mp)] == 0:
				add_foe(_swarm_k, mp)
	if ph == 3 and float(bst["flock"]) <= 0.0 and flock_warn.is_empty():
		bst["flock"] = 10.0
		event("flock")


## How far a point lies from the stretch between two others.
func _near_line(pt: Vector2, a: Vector2, b: Vector2) -> float:
	return pt.distance_to(Geometry2D.get_closest_point_to_segment(pt, a, b))


## How far a beam from `from` along `dir` runs before it meets the walls of light (`far` at most, and where no walls
## stand): for the pictures of a boss's beams, which end at the walls.
func _ray_len(from: Vector2, dir: Vector2, far: float) -> float:
	if not barrier_on:
		return far
	var best := far
	if dir.x > 0.001:
		best = minf(best, (barrier.end.x - from.x) / dir.x)
	elif dir.x < -0.001:
		best = minf(best, (barrier.position.x - from.x) / dir.x)
	if dir.y > 0.001:
		best = minf(best, (barrier.end.y - from.y) / dir.y)
	elif dir.y < -0.001:
		best = minf(best, (barrier.position.y - from.y) / dir.y)
	return maxf(0.0, best)


## The field is full and a boss or one of its own must come: one of the swarm makes room.
func _make_room() -> void:
	for j in n:
		if _beh[fk[j]] < SD.BOSS_BEH:
			_remove(j)
			return


## (Part 8c) The Warden: it walks at you on four legs. A laser arm turns round it all the while (two of them in its
## last third): dodge through it, or walk with it close by. Again and again a salvo of rockets onto marks. Come near
## and it rears up and stamps: a ring of force runs out from it.
func _warden(i: int, p: Vector2, d: Vector2, dl: float, delta: float, pp: Vector2) -> void:
	var fd: Dictionary = SD.FOES["warden"]
	var ph := int(boss_info()["phase"])
	bst["warm"] = maxf(0.0, float(bst["warm"]) - delta)
	bst["a"] = fposmod(float(bst["a"]) + float([0.8, 1.0, 1.15][ph - 1]) * delta, TAU)
	if float(bst["warm"]) <= 0.0 and can_hurt():            # the arm: to touch it hurts, and throws you outwards
		for arm in (2 if ph == 3 else 1):
			if _near_line(pp, p, p + Vector2.from_angle(float(bst["a"]) + arm * PI) * float(fd["arm"])) < 6.0:
				_hurt(float(fd["arm_dmg"]))
				throw_you(pp - p, 0.18)
				break
	bst["salvo"] = float(bst["salvo"]) - delta
	if float(bst["salvo"]) <= 0.0:                          # a salvo: one rocket onto where you stand, the others round you
		bst["salvo"] = float([6.0, 5.0, 4.2][ph - 1])
		for q in int([5, 7, 9][ph - 1]):
			var at := pp if q == 0 else near_free(pp + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(34.0, 120.0), 16.0)
			var fly := 1.0 + q * 0.11
			shells.append({"from": p, "pos": at, "t": 0.0, "len": fly, "r": float(fd["rocket_r"]), "dmg": float(fd["rocket"]), "foes": 0.0, "rocket": true})
			tele.append({"kind": "spot", "pos": at, "r": float(fd["rocket_r"]), "t": 0.0, "len": fly})
		Audio.play("sv_shell", "survivor: the warden's rockets", -8.0)
	bst["stomp"] = maxf(0.0, float(bst["stomp"]) - delta)
	if String(bst["st"]) == "wind":                         # it rears up; then it stamps
		if float(bst["t"]) <= 0.0:
			waves.append({"pos": p, "r": 12.0, "to": float(fd["stomp_r"]), "speed": 190.0, "dmg": float(fd["stomp"]), "hit": false})
			tele.append({"kind": "stomp", "pos": p, "r": 40.0, "t": 0.0, "len": 0.4})
			Audio.play("sv_stomp", "survivor: the warden stamps", -4.0)
			bst["st"] = "walk"
			bst["stomp"] = 3.6
	else:
		_boss_go(i, d * (_spd[fk[i]] / dl), delta)
		if dl < 62.0 and float(bst["stomp"]) <= 0.0:
			bst["st"] = "wind"
			bst["t"] = 0.75


## (Part 8c) The Core: it stands in the middle of four pylons. While one of them stands a shield is over it, and the
## pylons fire beams along lines they show first. Then a cross of four laser arms turns round it, and it calls
## machines. From under half of it on, squares of the floor light up before they burst.
func _core(p: Vector2, delta: float, pp: Vector2) -> void:
	var fd: Dictionary = SD.FOES["core"]
	var ph := int(boss_info()["phase"])
	_guard_t = maxf(0.0, _guard_t - delta)
	# ---- the pylons' beams: a line that follows you until just before, then the beam along it
	var aims: Array = bst["aims"]
	var qa := aims.size() - 1
	while qa >= 0:
		var am: Dictionary = aims[qa]
		am["t"] = float(am["t"]) - delta
		var from: Vector2 = am["from"]
		if String(am["st"]) == "aim":
			if float(am["t"]) > 0.3:
				am["dir"] = (pp - from).normalized() if pp.distance_squared_to(from) > 1.0 else Vector2.DOWN
			if float(am["t"]) <= 0.0:
				am["st"] = "fire"
				am["t"] = 0.35
				Audio.play("sv_beam", "survivor: a pylon's beam", -10.0)
		else:
			if can_hurt() and _near_line(pp, from, from + (am["dir"] as Vector2) * 700.0) < 6.0:
				_hurt(float(fd["beam"]))
			if float(am["t"]) <= 0.0:
				aims.remove_at(qa)
		qa -= 1
	# ---- the floor: what has lit up bursts when its time is up
	var boomed := false
	var qf := fields.size() - 1
	while qf >= 0:
		var fl: Dictionary = fields[qf]
		fl["t"] = float(fl["t"]) + delta
		if float(fl["t"]) >= float(fl["len"]) + 0.25:
			fields.remove_at(qf)
		elif float(fl["t"]) >= float(fl["len"]) and not bool(fl.get("done", false)):
			fl["done"] = true
			boomed = true
			if can_hurt() and (fl["r"] as Rect2).has_point(pp):
				_hurt(float(fd["field"]))
		qf -= 1
	if boomed:
		Audio.play("sv_boom", "survivor: the floor bursts", -8.0)
	if ph == 1:                                             # behind its shield: the pylons fire in turn, the faster the fewer stand
		bst["fire"] = float(bst["fire"]) - delta
		if float(bst["fire"]) <= 0.0:
			var py: Array = []
			for j in n:
				if fk[j] == _pylon_k:
					py.append(fp[j])
			if not py.is_empty():
				bst["fire"] = 0.7 + 0.3 * py.size()
				bst["next"] = int(bst["next"]) + 1
				var src: Vector2 = py[int(bst["next"]) % py.size()]
				aims.append({"from": src, "dir": (pp - src).normalized() if pp.distance_squared_to(src) > 1.0 else Vector2.DOWN, "t": 0.9, "st": "aim"})
		return
	# ---- the cross: four arms of light turning round it
	bst["warm"] = maxf(0.0, float(bst["warm"]) - delta)
	bst["a"] = fposmod(float(bst["a"]) + (0.45 if ph == 2 else 0.34) * delta, TAU)
	if float(bst["warm"]) <= 0.0 and can_hurt():
		for arm in 4:
			if _near_line(pp, p, p + Vector2.from_angle(float(bst["a"]) + arm * PI * 0.5) * SD.CROSS_LEN) < 6.0:
				_hurt(float(fd["beam"]))
				break
	# ---- what it calls
	bst["spawn"] = float(bst["spawn"]) - delta
	if float(bst["spawn"]) <= 0.0:
		bst["spawn"] = 5.0 if ph == 2 else 8.0
		var kk: int = _ki["enforcer"] if ph == 2 else _ki["scout"]
		for q2 in (3 if ph == 2 else 2):
			if n < foe_cap - 20:
				add_foe(kk, near_free(p + Vector2.from_angle(rng.randf() * TAU) * 40.0, 14.0))
	# ---- the floor: the square you stand in lights up, and of the others of its colour on the board more than half:
	# the squares beside yours stay dark
	if ph == 3:
		bst["field"] = float(bst["field"]) - delta
		if float(bst["field"]) <= 0.0:
			bst["field"] = 2.6
			var cs := SD.FIELD_CELL
			var cols := int(barrier.size.x / cs)
			var rows := int(barrier.size.y / cs)
			var mx := clampi(int((pp.x - barrier.position.x) / cs), 0, cols - 1)
			var my := clampi(int((pp.y - barrier.position.y) / cs), 0, rows - 1)
			for fy in rows:
				for fx in cols:
					if (fx + fy) % 2 == (mx + my) % 2 and ((fx == mx and fy == my) or rng.randf() < 0.6):
						fields.append({"r": Rect2(barrier.position + Vector2(fx, fy) * cs, Vector2(cs, cs)), "t": 0.0, "len": SD.FIELD_WARN})
			Audio.play("sv_alarm", "survivor: the floor lights up", -14.0)


## A colour of the rainbow that belongs to a place: a comet of the Plasma Rain and its burst are of one colour.
## (`from`, `wide`: the stretch of the rainbow to pick from; all of it when not said.)
func _hue_at(p: Vector2, from: float = 0.0, wide: float = 1.0) -> Color:
	return SFX.hue(from + wide * fposmod(p.x * 0.0071 + p.y * 0.0113, 1.0), 0.15)


## A number of damage over one of them (the newest pushes the oldest out when there are too many).
func _num(p: Vector2, k: int, v: float, c: int) -> void:
	if not show_nums or v < 0.5:
		return
	if nums.size() >= NUM_MAX:
		nums.pop_front()
	var top := float(_tsz[k].y) * (0.55 if _beh[k] >= SD.BOSS_BEH else 1.0) + (40.0 if _beh[k] == 5 else 0.0)
	var at := p + Vector2(fposmod(p.x * 7.13 + _frame * 3.7 + nums.size() * 2.3, 18.0) - 9.0, -fposmod(p.y * 3.31 + nums.size() * 1.7, 7.0))      # (set a little apart: over a knot of them they stand side by side)
	nums.append({"p": at, "h": top, "v": int(round(v)), "t": 0.0, "c": c})


## What an ultimate leaves for a moment (a burst, frost, a crush): `kind` says how it is drawn, `secs` how long.
func _fx_add(kind: String, p: Vector2, r: float, secs: float) -> void:
	if fxs.size() >= 60:
		fxs.pop_front()
	fxs.append({"kind": kind, "p": p, "r": r, "t": 0.0, "len": secs, "s": p.x * 0.37 + p.y * 0.11 + _frame})


## As many drones fly with you as you are owed (one; the Carrier Swarm: three).
func _drone_fleet(want: int, pp: Vector2) -> void:
	while drones.size() > want:
		drones.pop_back()
	while drones.size() < want:
		drones.append({"p": pp, "a": 0.0, "q": 0, "cd": 0.0, "flash": 0.0, "tr": PackedVector2Array(), "turn": 0.0, "dmg": 0.0, "pierce": false})


## The drones that fly with you (Luz, 23 Nov 2026): each keeps its place by you; with a round to fire it turns its gun
## once round and fires shot by shot, not all at once (`wd`: the weapons' own time: it stands still under an EMP).
func _drones(delta: float, wd: float, pp: Vector2) -> void:
	var cnt := drones.size()
	if cnt == 0:
		return
	var reach := float(SD.WEAPONS["drone"]["reach"]) * float(mods["area"])
	var tnow := float(run["t"])
	for q in cnt:
		var dr: Dictionary = drones[q]
		var want := pp + (Vector2(-13.0, -9.0) if cnt == 1 else Vector2.from_angle(tnow * 1.1 + q * TAU / cnt) * 24.0)
		var p: Vector2 = (dr["p"] as Vector2).lerp(want, minf(1.0, delta * 7.0))
		if p.distance_squared_to(want) > 200.0 * 200.0:     # (you were set down somewhere else: it is with you at once)
			p = want
		dr["p"] = p
		dr["flash"] = maxf(0.0, float(dr["flash"]) - delta)
		var tr: PackedVector2Array = dr["tr"]
		tr.insert(0, p)
		if tr.size() > 9:
			tr.resize(9)
		dr["tr"] = tr
		if int(dr["q"]) <= 0:
			dr["cd"] = 0.0
			continue
		if wd <= 0.0:
			continue                                          # (an EMP: it holds its fire)
		dr["a"] = fposmod(float(dr["a"]) + float(dr["turn"]) * wd, TAU)
		dr["cd"] = float(dr["cd"]) - wd
		while float(dr["cd"]) <= 0.0 and int(dr["q"]) > 0:
			var ang := float(dr["a"]) + float(dr["turn"]) * float(dr["cd"])      # (where its gun looked when this shot was due)
			dr["cd"] = float(dr["cd"]) + DRONE_GAP / float(mods.get("spin", 1.0))      # (the Gyroscope: its gun turns faster, so its round is fired sooner)
			dr["q"] = int(dr["q"]) - 1
			dr["flash"] = 0.06
			if shots.size() < 140:
				shots.append({"p": p, "v": Vector2.from_angle(ang) * 190.0, "life": reach / 190.0, "dmg": float(dr["dmg"]), "pierce": bool(dr["pierce"])})
				shot_n += 1
				if shot_n % 2 == 0:
					Audio.play("sv_shot", "survivor: the drone", -20.0)


## A boss takes a step (what stands in its way stops it; the walls of light hold it in).
func _boss_go(i: int, v: Vector2, delta: float) -> void:
	var p := fp[i]
	var q := p + v * delta
	if barrier_on and barrier_k >= 1.0:
		var inner := barrier.grow(-14.0)
		q = Vector2(clampf(q.x, inner.position.x, inner.end.x), clampf(q.y, inner.position.y, inner.end.y))
	if _solid[_ti(q)] != 0:
		if _solid[_ti(Vector2(q.x, p.y))] == 0:
			q = Vector2(q.x, p.y)
		elif _solid[_ti(Vector2(p.x, q.y))] == 0:
			q = Vector2(p.x, q.y)
		else:
			q = p
	fp[i] = q


## A boss is out: a burst of shards, the walls fall; The Foreman leaves a great crate; with The Brood the run is won.
func _boss_out(kind: String, p: Vector2) -> void:
	var outs: Array = run.get("bosses", [])
	outs.append(kind)
	run["bosses"] = outs
	boss_kind = ""
	bst = {}
	barrier_on = false
	globs.clear()
	waves.clear()
	fields.clear()
	for q in 14:
		_drop(near_free(p + Vector2.from_angle(q * TAU / 14.0) * rng.randf_range(10.0, 44.0), 10.0), int(SD.FOES[kind]["xp"]) / 14)
	bombs.append({"pos": p, "r": 120.0, "t": 0.0})
	say("free")
	Audio.play("sv_bomb", "survivor: a boss is out", -4.0)
	in_storm = false
	if kind in ["foreman", "warden", "worm"]:
		crates.append({"pos": near_free(p, 16.0), "great": true, "fall": 0.0, "mark": true, "weapon": true})
	else:
		_win_t = WIN_WAIT
		for i in range(n - 1, -1, -1):                        # what it let out goes with it
			pops.append({"pos": fp[i], "t": 0.0})
			_remove(i)


## The walls of light: they grow, they hold you in (to touch one hurts), they fall.
func _walls(delta: float) -> void:
	if barrier_on:
		barrier_k = minf(1.0, barrier_k + delta / 1.0)
		if barrier_k >= 1.0:
			var inner := barrier.grow(-6.0)
			var pp: Vector2 = view.pilot.pos
			if not inner.has_point(pp):
				var held := Vector2(clampf(pp.x, inner.position.x, inner.end.x), clampf(pp.y, inner.position.y, inner.end.y))
				view.pilot.pos = held
				view.pilot.position = held * S
				if can_hurt():
					_hurt(4.0)
					throw_you(barrier.get_center() - held, 0.12)
	elif barrier_k > 0.0:
		barrier_k = maxf(0.0, barrier_k - delta / 0.6)


# ---------------------------------------------------------------- crates and what they hold

func _crates(delta: float, pp: Vector2) -> void:
	var drew := false
	var q := crates.size() - 1
	while q >= 0:
		var c: Dictionary = crates[q]
		if float(c["fall"]) > 0.0:
			c["fall"] = float(c["fall"]) - delta
		elif (c["pos"] as Vector2).distance_squared_to(pp) < 15.0 * 15.0:
			if bool(c.get("ice", false)):                     # (part 9a) frozen in: only the steam of the vent beside it thaws it
				if _frozen_t <= 0.0:
					_frozen_t = 6.0
					say("frozen")
			elif bool(c.get("weapon", false)) and (drew or view.minigame != null):
				pass                                            # (part 7f) a weapon crate waits while a window is up: its draw gets the picture to itself
			else:
				crates.remove_at(q)
				drew = drew or bool(c.get("weapon", false))
				open_crate(c)
		q -= 1
	for bm in bombs:
		bm["t"] = float(bm["t"]) + delta
	bombs = bombs.filter(func(b): return float(b["t"]) < 0.6)
	_items(delta, pp)


## (Part 7f) The clocks of what is drawn for an item: its sign springing up, the Atomic Bomb's cloud and the earth it
## scorched, a Medkit's moment, the flash of a Shield that was struck, the echoes behind you in an Overdrive.
func _items(delta: float, pp: Vector2) -> void:
	shield_hit = maxf(0.0, shield_hit - delta)
	if not item_pop.is_empty():
		item_pop["t"] = float(item_pop["t"]) + delta
		if float(item_pop["t"]) > ITEM_POP:
			item_pop = {}
	if not nukes.is_empty():
		for nk in nukes:
			nk["t"] = float(nk["t"]) + delta
		nukes = nukes.filter(func(x): return float(x["t"]) < SFX.NUKE_LIFE)
	if not scorches.is_empty():
		for sc in scorches:
			sc["t"] = float(sc["t"]) + delta
		scorches = scorches.filter(func(x): return float(x["t"]) < SFX.SCORCH_LIFE)
	if not heals.is_empty():
		for hl in heals:
			hl["t"] = float(hl["t"]) + delta
		heals = heals.filter(func(x): return float(x["t"]) < 0.9)
	if over_t > 0.0:
		_od_t -= delta
		if _od_t <= 0.0:
			_od_t = 0.09
			_od_tr.insert(0, pp)
			if _od_tr.size() > 5:
				_od_tr.resize(5)
	elif not _od_tr.is_empty():
		_od_tr = PackedVector2Array()


## (Part 9a) The steam vents of Whiteout: step on one that is ready and it bursts.
func _vents(delta: float, pp: Vector2) -> void:
	_frozen_t = maxf(0.0, _frozen_t - delta)
	for v in vents:
		v["cool"] = maxf(0.0, float(v["cool"]) - delta)
		v["t"] = maxf(0.0, float(v["t"]) - delta)
		if float(v["cool"]) <= 0.0 and (v["pos"] as Vector2).distance_squared_to(pp) < SD.VENT_STEP * SD.VENT_STEP:
			vent_burst(v)


## A vent bursts: its steam scalds all of them near it, reaches the burrowers under the ice there and throws them
## out of it, melts a shell of ice at once, and thaws a crate frozen in beside it. It does nothing to you. Then the
## vent rests.
func vent_burst(v: Dictionary) -> void:
	var vp: Vector2 = v["pos"]
	v["cool"] = SD.VENT_REST
	v["t"] = SD.VENT_TIME
	var r2 := SD.VENT_R * SD.VENT_R
	var dmg := SD.VENT_DMG * (1.0 + float(run["t"]) / 200.0)      # (it grows with the time, as what they can take does)
	_src = 0
	for i in range(n - 1, -1, -1):
		if i < n and _beh[fk[i]] != 5 and fp[i].distance_squared_to(vp) < r2:
			if fk[i] == _burrow_k and fst[i] < 2:
				_erupt(i)
				fstun[i] = 1.5
			if _shield[fk[i]] > 0.0 and fsh[i] > 0.0:           # (a shell of ice melts in it at once)
				fsh[i] = 0.0
				fv[i] = 2 + (fv[i] & 1)
			_hit(i, dmg, vp)
	for c in crates:
		if bool(c.get("ice", false)) and (c["pos"] as Vector2).distance_squared_to(vp) < r2:
			c["ice"] = false
			tele.append({"kind": "break", "pos": c["pos"], "r": 24.0, "t": 0.0, "len": 0.4})
			Audio.play("sv_break", "survivor: a crate thaws", -8.0)
	Audio.play("sv_steam", "survivor: a steam vent", -5.0)


## A crate is opened. An item crate: its item does its work at once; returns {"kind": "item", "id"}. A weapon
## crate (part 7f): its draw; returns {"kind": "draw", "n", "rewards"}.
func open_crate(c: Dictionary) -> Dictionary:
	tele.append({"kind": "break", "pos": c["pos"], "r": 20.0, "t": 0.0, "len": 0.35})
	Audio.play("sv_crate", "survivor: a crate", -8.0)
	if bool(c.get("weapon", false)):
		return open_draw(bool(c.get("great", false)))
	var got: Dictionary = SD.crate_roll(run, rng)
	give(String(got["id"]))
	return got


## (Part 7f, Luz) A weapon crate's draw: one, three or five levels of what you carry, by lot. They are yours at once;
## the window shows the reels turning while the run stands still. `count` > 0: that many (the debug menu, the tests).
func open_draw(great: bool, count: int = 0) -> Dictionary:
	var cnt: int = count if count > 0 else SD.draw_count(run, rng, great)
	var symbols: Array = (run["weapons"] as Array).map(func(w): return String(w[0])) + (run["boni"] as Array).map(func(b): return String(b[0]))
	var rewards: Array = SD.draw_rewards(run, rng, cnt)
	for rw in rewards:
		SD.apply(run, rw)
	mods = SD.mods(run)
	last_draw = rewards
	Audio.play("sv_level", "survivor: a weapon crate", -6.0)
	if view != null and is_instance_valid(view) and view.minigame == null:
		var dw = SUI.Draw.new()
		dw.setup({"rewards": rewards, "great": great, "symbols": symbols})
		dw.finished.connect(func(_took: bool): view._close_game())
		view._open_game(dw)
	return {"kind": "draw", "n": cnt, "rewards": rewards}


## What a crate held does its work: "shield", "magnet", "medkit", "bomb", "stasis", "overdrive".
func give(id: String) -> void:
	if not SD.ITEMS.has(id):
		return
	var it: Dictionary = SD.ITEMS[id]
	var pp: Vector2 = view.pilot.pos
	match id:
		"shield":
			shield_t = float(it["time"]) * float(mods.get("dur", 1.0))
			shield_len = shield_t
		"magnet":
			magnet_t = 3.0
		"medkit":
			run["hp"] = minf(SD.max_hp(run), float(run["hp"]) + float(it["heal"]))
			heals.append({"t": 0.0})
		"stasis":
			stasis_t = float(it["time"]) * float(mods.get("dur", 1.0))
			stasis_len = stasis_t
			tele.append({"kind": "stasis", "pos": pp, "r": _half().length() + 40.0, "t": 0.0, "len": 0.7})
		"overdrive":
			over_t = float(it["time"]) * float(mods.get("dur", 1.0))
			over_len = over_t
		"override":                                         # (part 8b) the machines near you fight for you for a while
			var or2 := pow(float(it["r"]), 2.0)
			ovr_t = float(it["time"]) * float(mods.get("dur", 1.0))
			for oi in n:
				if fp[oi].distance_squared_to(pp) < or2 and _beh[fk[oi]] < SD.BOSS_BEH and _beh[fk[oi]] != 5:
					fovr[oi] = ovr_t
					fst[oi] = 0
					ftm[oi] = 0.0
					fkb[oi] = Vector2.ZERO
					fvel[oi] = Vector2.ZERO
					fsh[oi] = 0.0 if _shield[fk[oi]] <= 0.0 else fsh[oi]
			tele.append({"kind": "override", "pos": pp, "r": float(it["r"]), "t": 0.0, "len": 0.5})
		"thermal":                                          # (part 9b) all the ice round you melts: shells, the ice over a burrower, the ice over a crate; and the heat hurts them
			var th2 := pow(float(it["r"]), 2.0)
			var thd := float(it["dmg"]) * (1.0 + float(run["t"]) / 200.0)
			_src = 0
			for ti in range(n - 1, -1, -1):
				if ti < n and _beh[fk[ti]] != 5 and fp[ti].distance_squared_to(pp) < th2:
					if _under(ti) and fk[ti] == _burrow_k:
						_erupt(ti)
						fstun[ti] = 1.5
					if fsh[ti] > 0.0:
						fsh[ti] = 0.0
						if _shield[fk[ti]] > 0.0:
							fv[ti] = 2 + (fv[ti] & 1)
					_hit(ti, thd, pp)
			for tc in crates:
				if bool(tc.get("ice", false)) and (tc["pos"] as Vector2).distance_squared_to(pp) < th2:
					tc["ice"] = false
			tele.append({"kind": "thermal", "pos": pp, "r": float(it["r"]), "t": 0.0, "len": 0.6})
		"bomb":                                             # all round you are out (the tough ones take a heavy blow)
			var r2 := pow(float(it["r"]), 2.0)
			for i in range(n - 1, -1, -1):
				if i < n and fp[i].distance_squared_to(pp) < r2:
					fsh[i] = 0.0
					_hit(i, float(it["tough"]) if (_tough[fk[i]] != 0 or fal[i] != 0) else 1000000.0, pp)
			bombs.append({"pos": pp, "r": float(it["r"]), "t": 0.0})
			nukes.append({"pos": pp, "r": float(it["r"]), "t": 0.0})      # (part 7f: its flash, its ball of fire, its cloud)
			scorches.append({"pos": pp, "r": float(it["r"]) * 0.34, "t": 0.0})
			globs = globs.filter(func(g): return (g["p"] as Vector2).distance_squared_to(pp) > r2)
			Audio.play("sv_bomb", "survivor: the bomb", -2.0)
	say("", String(it["name"]).to_upper())
	item_pop = {"id": id, "t": 0.0}                         # (part 7f) its sign springs up over you
	if id != "bomb":
		Audio.play("sv_item", "survivor: %s" % id, -8.0)


# ---------------------------------------------------------------- your weapons

func _weapons(delta: float, pp: Vector2) -> void:
	var area := float(mods["area"])
	var cdk := float(mods["cd"])
	var dk := float(mods["dmg"])
	var dur := float(mods.get("dur", 1.0))
	nova_r = 0.0
	_shatter = false
	orb_pts.clear()
	orb_out.clear()
	if not drones.is_empty() and SD.weapon_level(run, "drone") == 0:
		drones.clear()
	for w in run["weapons"]:
		var id := String(w[0])
		_src = int(_wsrc.get(id, 0))
		var lv := int(w[1])
		var st: Dictionary = SD.stats(id, lv)
		var ult := lv >= SD.ULT
		if id == "cryo" and ult:
			_shatter = true
		if id == "pulse" and ult:
			nova_r = float(st["r"]) * 1.15 * area             # the Nova Field: it stands for good
		if id == "drone":
			_drone_fleet(3 if ult else 1, pp)                   # (the drone flies with you from the moment you carry it)
		if id == "blade" and ult:                           # the Silver Storm (Luz, 23 Nov 2026): one more blade, they stay for good, and their trails cut too
			var keep := 0
			for bl0 in blades:
				if bool(bl0.get("u", false)):
					keep += 1
					bl0["dmg"] = float(st["dmg"]) * dk
			while keep < int(st["n"]) + 1:
				blades.append({"p": pp, "v": _blade_dir(pp, keep) * 320.0 * float(mods.get("spin", 1.0)), "life": 1.0, "dmg": float(st["dmg"]) * dk,
					"tr": PackedVector2Array(), "u": true})
				keep += 1
			continue
		if id == "orbs" and (ult or orbs_t > 0.0):          # plasma orbs on their round while their time lasts (the Fusion Halo: for good)
			_orbs(delta, pp, int(st["n"]) + (0 if ult else _orb_more), float(st["r"]) * area, float(st["dmg"]) * dk, ult)
			if not ult:
				orbs_t -= delta
				if orbs_t <= 0.0:
					_wt[id] = float(st["every"]) * cdk             # (they are gone: now the interval runs)
			continue
		var left := float(_wt.get(id, 0.6)) - delta
		if left > 0.0:
			_wt[id] = left
			continue
		_wt[id] = float(st["every"]) * cdk
		match id:
			"pulse":                                         # a field round you: all in it
				if ult:
					_wt[id] = 0.35 * cdk                           # (… and it burns without a pause)
					var rn2 := nova_r * nova_r
					_kbk = 0.3                                     # (it burns without a pause: each burn throws them back only a little)
					for i in range(n - 1, -1, -1):
						if i < n and fp[i].distance_squared_to(pp) < rn2:
							_hit(i, float(st["dmg"]) * 0.45 * dk, pp)
					_kbk = 1.0
				else:
					var r := float(st["r"]) * area
					rings.append({"r": r, "t": 0.0})
					Audio.play("sv_pulse", "survivor: the pulse", -18.0)
					var r2 := r * r
					for i in range(n - 1, -1, -1):
						if i < n and fp[i].distance_squared_to(pp) < r2:
							_hit(i, float(st["dmg"]) * dk, pp)
			"laser":                                         # beams at the nearest
				var want := int(st["n"]) + _more()
				var reach2 := pow(float(SD.WEAPONS["laser"]["reach"]) * area, 2.0)
				var best: Array = []                            # [distance squared, which], the nearest first
				for i in n:
					var d2 := fp[i].distance_squared_to(pp)
					if d2 > reach2 or (best.size() >= want and d2 >= float(best[-1][0])) or _under(i):
						continue
					var at := best.size()
					while at > 0 and d2 < float(best[at - 1][0]):
						at -= 1
					best.insert(at, [d2, i])
					if best.size() > want:
						best.pop_back()
				if best.is_empty():
					_wt[id] = 0.2                                # (nobody in reach: it looks again in a moment)
					continue
				Audio.play("sv_laser", "survivor: the laser", -18.0)
				var ids: Array = best.map(func(b): return int(b[1]))
				ids.sort()
				ids.reverse()                                   # (from the back of the rows: one put out moves the last into its place)
				var ldmg := float(st["dmg"]) * dk
				for i2 in ids:
					if i2 >= n:
						continue
					var from: Vector2 = fp[i2]
					beams.append({"a": pp + CHEST, "b": from + CHEST, "t": -0.1, "c": 3} if ult else {"a": pp + CHEST, "b": from + CHEST, "t": 0.0})      # (the Prism Array's beams stand a moment longer, in split light)
					_hit(i2, ldmg, pp)
					if ult:                                       # the Prism Array: the beam jumps on, twice
						for hop in 2:
							var nb := -1
							var nd := 70.0 * 70.0
							for j in n:
								var dj := fp[j].distance_squared_to(from)
								if dj < nd and dj > 4.0 and not _under(j):
									nd = dj
									nb = j
							if nb < 0:
								break
							var to2: Vector2 = fp[nb]
							beams.append({"a": from + CHEST, "b": to2 + CHEST, "t": -0.1, "c": 4 + hop})
							_hit(nb, ldmg * 0.7, from)
							from = to2
			"plasma":                                        # grenades thrown near you (the Plasma Rain: all over what you see)
				var half := _half()
				for g in (8 if ult else int(st["n"]) + _more()):
					var tgt := pp + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(30.0, 100.0)
					if ult:
						tgt = pp + Vector2(rng.randf_range(-half.x, half.x), rng.randf_range(-half.y, half.y)) * 0.9
					for tr in 6:                                    # (at one of them, if one is near enough)
						if n <= 0:
							break
						var c := rng.randi() % n
						var dd := fp[c] - pp
						if (ult and absf(dd.x) < half.x and absf(dd.y) < half.y) or (not ult and dd.length() < 120.0):
							tgt = fp[c]
							break
					nades.append({"a": pp, "b": tgt, "t": 0.0, "r": float(st["r"]) * area, "dmg": float(st["dmg"]) * dk, "u": ult})
			"drone":                                         # the drones that fly with you get a round to fire: each turns its gun once round and fires shot by shot (the Carrier Swarm: three drones, their shots going through)
				var cnt := int(st["n"]) + _more() * 2
				var each := int(ceil(cnt * 2.0 / 3.0)) if ult else cnt
				for dr in drones:
					if int(dr["q"]) <= 0:
						dr["turn"] = TAU / (each * DRONE_GAP / float(mods.get("spin", 1.0)))
					dr["q"] = mini(int(dr["q"]) + each, each * 2)
					dr["dmg"] = float(st["dmg"]) * dk
					dr["pierce"] = ult
			"superlaser":                                    # a beam sweeps a quarter of the round (the Sunlance: all of it)
				var sa := rng.randf() * TAU
				var way := 1.0 if rng.randf() < 0.5 else -1.0
				sweep = {"a0": sa, "a": sa, "to": sa + (TAU if ult else PI * 0.5) * way, "reach": float(st["reach"]) * area, "t": 0.0, "len": 1.5 if ult else 0.6, "u": ult}
				Audio.play("sv_beam", "survivor: the superlaser", -8.0)
			"blade":                                         # blades dart away from you
				Audio.play("sv_blade", "survivor: a blade", -14.0)
				for b2 in int(st["n"]) + _more():
					blades.append({"p": pp, "v": _blade_dir(pp, b2) * 320.0 * float(mods.get("spin", 1.0)), "life": float(st["time"]) * dur, "dmg": float(st["dmg"]) * dk, "tr": PackedVector2Array()})
			"mines":                                         # mines where you walk (the Minefield: a ring of them round you, each arming itself once more)
				var mdmg := float(st["dmg"]) * dk
				var mr := float(st["r"]) * area
				var mlife := float(SD.WEAPONS["mines"]["time"]) * dur
				if ult:
					var mc := 8 + _more()
					var ma := rng.randf() * TAU
					_mine_g += 1
					for q2 in mc:
						var mp := pp + Vector2.from_angle(ma + q2 * TAU / mc) * 62.0 * area
						if mp.x > 20.0 and mp.y > 20.0 and mp.x < _w * TL - 20.0 and mp.y < _h * TL - 20.0 and _solid[_ti(mp)] == 0:
							mines.append({"p": mp, "arm": 0.5, "life": mlife, "r": mr, "dmg": mdmg, "again": true, "g": _mine_g, "q": q2, "m": mc})
				else:
					for q3 in int(st["n"]) + _more():
						var mp2 := pp - face_dir * 8.0 + (Vector2.ZERO if q3 == 0 else Vector2.from_angle(rng.randf() * TAU) * 16.0)
						if _solid[_ti(mp2)] != 0:
							mp2 = pp
						mines.append({"p": mp2, "arm": 0.5, "life": mlife, "r": mr, "dmg": mdmg, "again": false})
				while mines.size() > 40:
					mines.pop_front()
				Audio.play("sv_mine", "survivor: a mine laid", -18.0)
			"sentry":                                        # a small gun set down (the Battery: three that stay while you stay near)
				var sdmg := float(st["dmg"]) * dk
				if ult:
					_wt[id] = 1.0
					if sentries.size() < 3:
						sentries.append({"p": near_free(pp + Vector2.from_angle(-PI * 0.5 + _bat_n * TAU / 3.0) * 36.0, 12.0), "life": 1.5, "cd": 0.2, "dmg": sdmg, "keep": true, "face": 0, "flash": 0.0})
						_bat_n += 1                                   # (the Battery's guns stand in a triangle round you: its field of light lies between them)
						Audio.play("sv_item", "survivor: a gun set down", -14.0)
				else:
					for q4 in int(st["n"]):
						sentries.append({"p": near_free(pp + (Vector2.ZERO if q4 == 0 else Vector2.from_angle(rng.randf() * TAU) * 26.0), 12.0), "life": float(st["time"]) * dur, "cd": 0.2,
							"dmg": sdmg, "keep": false, "face": 0, "flash": 0.0})
					while sentries.size() > 4:
						sentries.pop_front()
					Audio.play("sv_item", "survivor: a gun set down", -14.0)
			"cryo":                                          # a cone of cold the way you walk (Absolute Zero: a wave all round)
				var cr := float(st["reach"]) * area * (1.5 if ult else 1.0)
				var arc := float(SD.WEAPONS["cryo"]["arc"])
				var fa := face_dir.angle()
				for j in touching(pp, cr):
					if j >= n or (not ult and absf(wrapf((fp[j] - pp).angle() - fa, -PI, PI)) > arc):
						continue
					var n0 := n
					_hit(j, float(st["dmg"]) * dk, fp[j])            # (from where it stands: the cold does not throw it back)
					if n == n0:
						freeze(j, float(st["time"]) * dur)
				cones.append({"p": pp, "a": fa, "r": cr, "arc": PI if ult else arc, "t": 0.0})
				if ult:
					_fx_add("frost", pp, cr, 1.6)
				Audio.play("sv_freeze", "survivor: the cryo spray", -14.0)
			"taser":                                         # a shock into a small field right before you (Chain Lightning: it jumps on from each one, three times)
				var tr0 := float(st["reach"]) * area
				var tarc := float(SD.WEAPONS["taser"]["arc"])
				var tang := face_dir.angle()
				var tdmg := float(st["dmg"]) * dk
				var tst := float(SD.WEAPONS["taser"]["stun"]) * dur
				var struck: Array = []
				for j5 in touching(pp, tr0):                      # (Luz, 23 Nov 2026: a cone, not a round field)
					if j5 >= n or absf(wrapf((fp[j5] - pp).angle() - tang, -PI, PI)) > tarc:
						continue
					var n5 := n
					struck.append(fp[j5])
					_hit(j5, tdmg, pp)
					if n == n5:
						stun(j5, tst)
				zaps.append({"p": pp, "a": tang, "r": tr0, "arc": tarc, "t": 0.0})
				if ult:
					for sp0 in struck.slice(0, 5):
						var zfrom: Vector2 = sp0
						for zhop in 3:
							var zb := -1
							var zd := 64.0 * 64.0
							for j6 in touching(zfrom, 64.0):
								var zj := fp[j6].distance_squared_to(zfrom)
								if j6 < n and zj < zd and zj > 9.0:
									zd = zj
									zb = j6
							if zb < 0:
								break
							var zto: Vector2 = fp[zb]
							beams.append({"a": zfrom + CHEST, "b": zto + CHEST, "t": -0.08, "c": 2})
							var n6 := n
							_hit(zb, tdmg * 0.6, zfrom)
							if n == n6:
								stun(zb, tst)
							zfrom = zto
				Audio.play("sv_taser", "survivor: the taser", -16.0)
			"blackhole":                                     # a black hole the way you look (Event Horizon: three, spread like a fan)
				for q6 in (3 if ult else 1):
					var ha := face_dir.angle() + ((q6 - 1) * 0.5 if ult else 0.0)
					if holes.size() < 6:
						holes.append({"p": pp + Vector2.from_angle(ha) * 14.0, "v": Vector2.from_angle(ha) * float(SD.WEAPONS["blackhole"]["speed"]), "r": float(st["r"]) * area, "t": 0.0,
							"tick": 0.0, "dmg": float(SD.WEAPONS["blackhole"]["tough"]) * dk, "u": ult, "tr": PackedVector2Array()})
				Audio.play("sv_hole", "survivor: a black hole", -6.0)
			"orbs":                                          # the plasma orbs come and circle you for a while
				orbs_t = float(st["time"]) * dur
				_orb_more = _more()
				Audio.play("sv_pulse", "survivor: the plasma orbs", -14.0)
			"gravity":                                       # a sphere thrown among them (at the nearest one, or ahead of you)
				var gp := near_free(pp + face_dir * 70.0, 20.0)
				var gbest := 150.0 * 150.0
				for i3 in n:
					var gd := fp[i3].distance_squared_to(pp)
					if gd < gbest and gd > 900.0 and not _under(i3):
						gbest = gd
						gp = fp[i3]
				wells.append({"p": gp, "r": float(st["r"]) * area, "life": float(st["time"]) * dur, "t": 0.0, "dmg": float(st["dmg"]) * dk, "tick": 0.0, "ult": ult})
				Audio.play("sv_well", "survivor: a gravity well", -12.0)


## (Luz, 24 Nov 2026) The way a new blade darts: at one of them, the nearest first (the nth blade of a volley at the
## nth nearest), so that it cuts somebody; by lot only when nobody is near.
func _blade_dir(pp: Vector2, nth: int) -> Vector2:
	var near: Array = []
	for j in touching(pp, 300.0):
		if j < n and _beh[fk[j]] != 5:
			near.append([fp[j].distance_squared_to(pp), j])
	if near.is_empty():
		return Vector2.from_angle(rng.randf() * TAU)
	near.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
	var d: Vector2 = fp[int(near[nth % near.size()][1])] - pp
	return d.normalized() if d.length_squared() > 1.0 else Vector2.from_angle(rng.randf() * TAU)


## Who of the swarm stands within `r` of `p` (by the grid of cells; the highest place in the rows first, so that
## one put out does not upset the places still to come).
func touching(p: Vector2, r: float) -> Array:
	var out: Array = []
	var cx := int(p.x / CELL)
	var cy := int(p.y / CELL)
	var rc := int(ceil(r / CELL))
	var r2 := r * r
	for yy in range(maxi(0, cy - rc), mini(_gh - 1, cy + rc) + 1):
		for xx in range(maxi(0, cx - rc), mini(_gw - 1, cx + rc) + 1):
			var j := _head[xx + yy * _gw]
			while j >= 0:
				if j < n and fp[j].distance_squared_to(p) < r2:
					out.append(j)
				j = _next[j]
	out.sort()
	out.reverse()
	return out


## What the superlaser touches is out (the tough ones and the alphas take a heavy hit instead; a shield breaks).
func _zap(i: int, from: Vector2) -> void:
	_hit(i, float(SD.WEAPONS["superlaser"]["tough"]) * float(mods["dmg"]) if (_tough[fk[i]] != 0 or fal[i] != 0) else 1000000.0, from)


## The plasma orbs on their round about you, burning what they touch (Luz, 23 Nov 2026; this was the Silver Storm's
## round before). The Fusion Halo: a second ring further out, turning the other way; every few seconds a ring of
## plasma bursts out from it.
func _orbs(delta: float, pp: Vector2, cnt: int, r: float, dmg: float, halo: bool) -> void:
	orb_a += delta * float(SD.WEAPONS["orbs"]["turn"]) * float(mods.get("spin", 1.0))
	orb_r = r
	for q in cnt:
		var bp := pp + Vector2.from_angle(orb_a + q * TAU / cnt) * r
		orb_pts.append(bp)
		for j in touching(bp, 12.0):
			if j < n:
				_hit(j, dmg * delta * 18.0, pp)
	if not halo:
		return
	for q2 in cnt:
		var bp2 := pp + Vector2.from_angle(-orb_a * 0.8 + (q2 + 0.5) * TAU / cnt) * r * 1.65
		orb_out.append(bp2)
		for j2 in touching(bp2, 12.0):
			if j2 < n:
				_hit(j2, dmg * delta * 18.0, pp)
	_halo_t -= delta
	if _halo_t <= 0.0:
		_halo_t = float(SD.WEAPONS["orbs"]["burst"])
		halos.append({"c": pp, "r": r * 1.65, "from": r * 1.65, "to": r * 1.65 + 120.0, "dmg": dmg * 2.0})
		Audio.play("sv_pulse", "survivor: the halo bursts", -8.0)


## What is in the air: grenades, the drone's shots, the superlaser's sweep, the blades.
func _fly(delta: float, pp: Vector2) -> void:
	_src = int(_wsrc.get("plasma", 0))
	var q := nades.size() - 1
	while q >= 0:
		var nd: Dictionary = nades[q]
		nd["t"] = float(nd["t"]) + delta / 0.5
		if float(nd["t"]) >= 1.0:                          # it lands and bursts: all round it
			var at: Vector2 = nd["b"]
			var r2 := float(nd["r"]) * float(nd["r"])
			for i in range(n - 1, -1, -1):
				if i < n and fp[i].distance_squared_to(at) < r2:
					_hit(i, float(nd["dmg"]), at)
			blasts.append({"pos": at, "r": float(nd["r"]), "t": 0.0})
			if bool(nd.get("u", false)):
				_fx_add("plasma", at, float(nd["r"]), 0.55)
			Audio.play("sv_boom", "survivor: a grenade", -16.0)
			nades.remove_at(q)
		q -= 1
	_src = int(_wsrc.get("drone", 0))
	q = shots.size() - 1
	while q >= 0:
		var sh: Dictionary = shots[q]
		var p: Vector2 = (sh["p"] as Vector2) + (sh["v"] as Vector2) * delta
		sh["p"] = p
		sh["life"] = float(sh["life"]) - delta
		var gone := float(sh["life"]) <= 0.0 or _solid[_ti(p)] != 0
		if not gone:
			var hit := touching(p, 13.0)                        # (Luz, 24 Nov 2026: a shot strikes a little further round itself)
			if not hit.is_empty():
				if bool(sh["pierce"]):                         # (it goes through: a little to each one it passes)
					for j in hit:
						if j < n:
							_hit(j, float(sh["dmg"]) * delta * 12.0, p - (sh["v"] as Vector2) * 0.05)
				else:
					_hit(int(hit[0]), float(sh["dmg"]), p - (sh["v"] as Vector2) * 0.05)
					gone = true
		if gone:
			shots.remove_at(q)
		q -= 1
	_src = int(_wsrc.get("superlaser", 0))
	if not sweep.is_empty():
		var tt := float(sweep["t"]) + delta
		sweep["t"] = tt
		var prev := float(sweep["a"])
		var k := minf(1.0, tt / float(sweep["len"]))
		var cur := lerpf(float(sweep["a0"]), float(sweep["to"]), k)
		sweep["a"] = cur
		var sgn := -1.0 if cur < prev else 1.0
		var span := absf(cur - prev)
		var rr2 := pow(float(sweep["reach"]), 2.0)
		for i in range(n - 1, -1, -1):
			if i >= n:
				continue
			var d := fp[i] - pp
			var l2 := d.length_squared()
			if l2 > rr2 or l2 < 1.0:
				continue
			var off := wrapf(d.angle() - prev, -PI, PI) * sgn
			var wide := 0.05 + 7.0 / sqrt(l2)
			if off >= -wide and off <= span + wide:
				_zap(i, pp)
		if k >= 1.0:
			sweep = {}
	_src = int(_wsrc.get("orbs", 0))
	q = halos.size() - 1
	while q >= 0:                                           # the Fusion Halo's bursts: each a ring running out, hurting who it passes
		var hal: Dictionary = halos[q]
		var hr0 := float(hal["r"])
		var hr1 := hr0 + 230.0 * delta
		hal["r"] = hr1
		var hc0: Vector2 = hal["c"]
		for j4 in touching(hc0, hr1):
			if j4 < n:
				var dj4 := fp[j4].distance_to(hc0)
				if dj4 >= hr0 and dj4 < hr1:
					_hit(j4, float(hal["dmg"]), hc0)
		if hr1 >= float(hal["to"]):
			halos.remove_at(q)
		q -= 1
	_src = int(_wsrc.get("blade", 0))
	var half := _half() * 0.95
	q = blades.size() - 1
	while q >= 0:
		var bl: Dictionary = blades[q]
		var bp: Vector2 = (bl["p"] as Vector2) + (bl["v"] as Vector2) * delta
		if absf(bp.x - pp.x) > half.x or absf(bp.y - pp.y) > half.y:      # at the edge of the picture: it bounces, and darts back at you (a little off)
			bp = Vector2(clampf(bp.x, pp.x - half.x, pp.x + half.x), clampf(bp.y, pp.y - half.y, pp.y + half.y))
			bl["v"] = (pp - bp).normalized().rotated(rng.randf_range(-0.45, 0.45)) * 320.0 * float(mods.get("spin", 1.0))
		bl["p"] = bp
		bl["life"] = float(bl["life"]) - delta
		var storm_b := bool(bl.get("u", false))
		if storm_b:
			bl["life"] = 1.0                                    # (the Silver Storm's blades stay for good)
		var btr: PackedVector2Array = bl.get("tr", PackedVector2Array())      # (where it was: its trail, thin and long; the Silver Storm's longer still)
		btr.insert(0, bp)
		if btr.size() > (64 if storm_b else 40):
			btr.resize(64 if storm_b else 40)
		bl["tr"] = btr
		if storm_b:                                           # (… and its trail cuts what it touches)
			for tq in range(4, btr.size(), 4):
				for j3 in touching(btr[tq], 7.0):
					if j3 < n:
						_hit(j3, float(bl["dmg"]) * delta * 7.0, btr[tq])
		for j2 in touching(bp, 11.0):
			if j2 < n:
				_hit(j2, float(bl["dmg"]) * delta * 18.0, bp)
		if float(bl["life"]) <= 0.0:
			blades.remove_at(q)
		q -= 1


## The shards: those near you fly to you (all of them, under a crate's magnet); enough of them make a level.
func _shards(delta: float, pp: Vector2) -> void:
	var mag2: float = pow(SD.MAGNET * float(mods["mag"]), 2.0)
	var all := magnet_t > 0.0
	var k := sn - 1
	while k >= 0:
		var d := pp - sp[k]
		var l2 := d.length_squared()
		if l2 < 64.0:
			_xp_frac += float(sv[k]) * float(mods.get("xp", 1.0))    # (Scavenger and the fine tuning: a shard is worth more)
			var whole := int(_xp_frac + 0.0001)
			_xp_frac -= whole
			run["xp"] = int(run["xp"]) + whole
			sn -= 1
			sp[k] = sp[sn]
			sv[k] = sv[sn]
			stier[k] = stier[sn]
			spull[k] = spull[sn]
			if _frame % 2 == 0:
				Audio.play("sv_shard", "survivor: a shard", -22.0)
		elif all or spull[k] != 0:
			sp[k] = sp[k] + d * (minf(sqrt(l2), 520.0 * delta) / sqrt(l2))
		elif l2 < mag2:
			sp[k] = sp[k] + d * (170.0 * delta / sqrt(l2))
		k -= 1
	while SD.level_up(run):
		pending += 1


## What lies on the ground works on all: embers burn you and them alike; acid and a bloater's cloud eat at you
## (twice a second).
func _ground(delta: float, pp: Vector2) -> void:
	for pl in pools:
		pl["t"] = float(pl["t"]) + delta
	pools = pools.filter(func(q): return float(q["t"]) < float(q["life"]))
	_tick += delta
	if _tick < 0.5:
		return
	_tick = 0.0
	var safe := dash_t > 0.0 or shield_t > 0.0
	if _haz[_ti(pp)] == 2 and not safe:
		run["hp"] = float(run["hp"]) - _burn * 0.5
		_flash = 0.15
		view.pilot.modulate = Color(1.0, 0.55, 0.35)
	if not safe:
		for pl2 in pools:
			if (pl2["pos"] as Vector2).distance_to(pp) < float(pl2["r"]):
				run["hp"] = float(run["hp"]) - float(pl2["dps"]) * 0.5
				_flash = 0.15
				view.pilot.modulate = Color(0.6, 1.0, 0.5)
				break
	for i in range(n - 1, -1, -1):
		if i < n and _beh[fk[i]] != 5 and _beh[fk[i]] < SD.BOSS_BEH and _haz[_ti(fp[i])] == 2:      # (not those that fly: they are over it, and may be beyond the edge of the ground)
			_hit(i, _burn * 0.5, fp[i])


func _fx(delta: float) -> void:
	for ai in 6:
		var arr: Array = [rings, beams, pops, blasts, cones, zaps][ai]
		var life: float = [0.35, 0.12, 0.3, 0.3, 0.4, 0.18][ai]
		var q: int = arr.size() - 1
		while q >= 0:
			arr[q]["t"] = float(arr[q]["t"]) + delta
			if float(arr[q]["t"]) > life:
				arr.remove_at(q)
			q -= 1
	var nq := nums.size() - 1
	while nq >= 0:
		nums[nq]["t"] = float(nums[nq]["t"]) + delta
		if float(nums[nq]["t"]) > NUM_LIFE:
			nums.remove_at(nq)
		nq -= 1
	nq = fxs.size() - 1
	while nq >= 0:
		fxs[nq]["t"] = float(fxs[nq]["t"]) + delta
		if float(fxs[nq]["t"]) > float(fxs[nq]["len"]):
			fxs.remove_at(nq)
		nq -= 1
	var tq := tele.size() - 1
	while tq >= 0:
		tele[tq]["t"] = float(tele[tq]["t"]) + delta
		if float(tele[tq]["t"]) > float(tele[tq]["len"]):
			tele.remove_at(tq)
		tq -= 1


# ---------------------------------------------------------------- a new level

func _offer() -> void:
	cards = SD.offers(run, rng)
	var lu = SUI.LevelUp.new()
	lu.setup({"cards": cards, "level": int(run["level"]) - pending + 1, "run": run, "game": self})
	lu.finished.connect(func(_took: bool):
		view._close_game()
		cards = []
		pending = maxi(0, pending - 1))
	view._open_game(lu)
	Audio.play("sv_level", "survivor: a new level", -4.0)


## A card of the level is taken (the command bus calls this). "" or why not.
func pick(i: int) -> String:
	if cards.is_empty() or i < 0 or i >= cards.size():
		return "There is no card to take."
	var e := String(SD.apply(run, cards[i]))
	if e == "":
		mods = SD.mods(run)                               # (a bonus changes what all your weapons do)
	return e


## Overclock: does this volley fire one more? (1 or 0)
func _more() -> int:
	var m := float(mods.get("more", 0.0))
	return 1 if m > 0.0 and rng.randf() < m else 0


## One of the swarm is stunned for `secs` by a shock (the tough ones and the alphas for half as long; a boss never).
func stun(i: int, secs: float) -> void:
	if i < 0 or i >= n or _beh[fk[i]] >= SD.BOSS_BEH or _under(i):
		return
	fstun[i] = maxf(fstun[i], secs * (0.5 if (_tough[fk[i]] != 0 or fal[i] != 0) else 1.0))


## One of the swarm freezes for `secs` (the tough ones and the alphas for half as long; a boss never).
func freeze(i: int, secs: float) -> void:
	if i < 0 or i >= n or _beh[fk[i]] >= SD.BOSS_BEH or _under(i):
		return
	ffr[i] = maxf(ffr[i], secs * (0.5 if (_tough[fk[i]] != 0 or fal[i] != 0) else 1.0))


## (Part 8b) What happens on AI Takeover while it happens: the searchlights hunt you (stand in one too long and a
## shell comes down where you stand); shells land on their marks; landing pods come down and open; a kill line
## crosses the field; what an Override turned does its work; seekers go off.
## (Part 9b) What happens on Whiteout while it happens: the blizzard runs out; plates of ice break; an avalanche crosses
## the field.
func _wo_events(delta: float, pp: Vector2) -> void:
	blizzard_t = maxf(0.0, blizzard_t - delta)
	var q := breaks.size() - 1
	while q >= 0:
		var bk: Dictionary = breaks[q]
		bk["t"] = float(bk["t"]) + delta
		if not bool(bk["done"]) and float(bk["t"]) >= float(bk["len"]):
			bk["done"] = true
			var br: Rect2 = bk["r"]
			var bdmg := SD.BREAK_FOES * (1.0 + float(run["t"]) / 200.0)
			for j in touching(br.get_center(), br.size.x * 0.75):
				if j < n and br.has_point(fp[j]) and _beh[fk[j]] != 5:
					_hit(j, bdmg, fp[j])
			if can_hurt() and br.has_point(pp):
				_hurt(SD.BREAK_DMG)
			Audio.play("sv_ice", "survivor: the ice breaks", -8.0)
		elif float(bk["t"]) >= float(bk["len"]) + 4.0:
			breaks.remove_at(q)
		q -= 1
	in_cover = false
	q = avas.size() - 1
	while q >= 0:
		var av: Dictionary = avas[q]
		var ad: Vector2 = av["dir"]
		for k in range(1, 8):                                 # cover: something solid close by, on the side it comes from
			if _solid[_ti(pp - ad * (k * 8.0))] != 0:
				in_cover = true
		if float(av["warm"]) > 0.0:
			av["warm"] = float(av["warm"]) - delta
		else:
			var s0 := float(av["s"])
			var s1 := s0 + SD.AVA_SPEED * delta
			av["s"] = s1
			var base: Vector2 = av["c"]
			var along := (pp - base).dot(ad)
			if along >= s0 and along < s1 + 6.0 and not in_cover and can_hurt():
				_hurt(SD.AVA_DMG)
				throw_you(ad, 0.45)
			var admg := SD.AVA_FOES * (1.0 + float(run["t"]) / 200.0)
			_kbk = 4.0                                          # (it carries them off with it)
			for i in range(n - 1, -1, -1):
				if i < n and _beh[fk[i]] < SD.BOSS_BEH and _beh[fk[i]] != 5:
					var al := (fp[i] - base).dot(ad)
					if al >= s0 and al < s1:
						_hit(i, admg, fp[i] - ad)
			_kbk = 1.0
			if s1 >= float(av["far"]):
				avas.remove_at(q)
		q -= 1


func _events(delta: float, pp: Vector2) -> void:
	if blizzard_t > 0.0 or not breaks.is_empty() or not avas.is_empty():
		_wo_events(delta, pp)
	emp_t = maxf(0.0, emp_t - delta)
	ovr_t = maxf(0.0, ovr_t - delta)
	# ---- what the turned machines struck (they were noted while they moved)
	for oh in _ovr_hits:
		for j in touching(oh[0], 5.0):
			if j < n and fovr[j] <= 0.0:
				_hit(j, float(oh[1]), oh[2])
				break
	_ovr_hits.clear()
	# ---- seekers that have armed themselves go off; one that goes off hurts the machines round it, and you
	if _arming:
		_arming = false
		for i in range(n - 1, -1, -1):
			if i < n and _beh[fk[i]] == 11 and fst[i] == 2:
				_hit(i, 1000000.0, fp[i])
	var guard := 0
	while not booms.is_empty() and guard < 60:
		guard += 1
		var bp: Vector2 = booms.pop_back()
		var br := float(SD.FOES["seeker"]["boom_r"])
		for j2 in touching(bp, br):
			if j2 < n:
				_hit(j2, float(SD.FOES["seeker"]["boom_foes"]), bp)
		if can_hurt() and bp.distance_to(pp) < br:
			_hurt(float(SD.FOES["seeker"]["boom"]))
		if blasts.size() < 40:
			blasts.append({"pos": bp, "r": br, "t": 0.0})
		Audio.play("sv_boom", "survivor: a seeker goes off", -12.0)
	# ---- the searchlights: each hunts you, slower than you walk; too long in a light, and a shell is on its way
	if search_t > 0.0:
		search_t -= delta
		var in_light := false
		for l in lights:
			var lp: Vector2 = l["p"]
			var to_you := pp - lp
			var wl := to_you.length()
			var steer := to_you / maxf(wl, 1.0) * 40.0 + Vector2.from_angle(float(l["ph"]) + float(run["t"]) * 0.9) * 22.0
			l["v"] = (l["v"] as Vector2).lerp(steer, minf(1.0, delta * 1.2))
			l["p"] = lp + (l["v"] as Vector2) * delta
			if wl < SD.SEARCH_R:
				in_light = true
		lit_t = lit_t + delta if in_light else maxf(0.0, lit_t - delta * 0.6)
		if lit_t >= SD.SEARCH_LIT:
			lit_t = 0.0
			shells.append({"from": Vector2.INF, "pos": pp, "t": 0.0, "len": 1.0, "r": 34.0, "dmg": 22.0, "foes": 60.0})
			tele.append({"kind": "spot", "pos": pp, "r": 34.0, "t": 0.0, "len": 1.0})
			Audio.play("sv_alarm", "survivor: you are marked", -8.0)
		if search_t <= 0.0:
			lights.clear()
			lit_t = 0.0
	# ---- shells: a bulwark's, the artillery's: they come down on their marks
	var q := shells.size() - 1
	while q >= 0:
		var sh: Dictionary = shells[q]
		sh["t"] = float(sh["t"]) + delta
		if float(sh["t"]) >= float(sh["len"]):
			var at: Vector2 = sh["pos"]
			var sr := float(sh["r"])
			if float(sh["foes"]) > 0.0:
				for j3 in touching(at, sr):
					if j3 < n:
						_hit(j3, float(sh["foes"]), at)
			if can_hurt() and at.distance_to(pp) < sr:
				_hurt(float(sh["dmg"]))
			if bool(sh.get("zap", false)):                    # (part 9c) a bolt of The Storm Heart's lightning
				tele.append({"kind": "zap", "pos": at, "r": sr, "t": 0.0, "len": 0.25})
				Audio.play("sv_taser", "survivor: lightning", -6.0)
			elif bool(sh.get("ice", false)):                  # (part 9b) a glider's chunk of ice: it bursts in pieces
				if tele.size() < 90:
					tele.append({"kind": "erupt", "pos": at, "r": sr, "t": 0.0, "len": 0.3})
				Audio.play("sv_ice", "survivor: ice comes down", -14.0)
			else:
				if blasts.size() < 40:
					blasts.append({"pos": at, "r": sr, "t": 0.0})
				Audio.play("sv_boom", "survivor: a shell lands", -8.0)
			shells.remove_at(q)
		q -= 1
	# ---- landing pods: each comes down on its mark, opens, and three of the swarm step out; its husk stands a while
	q = pods.size() - 1
	while q >= 0:
		var pd: Dictionary = pods[q]
		if float(pd["husk"]) > 0.0:
			pd["husk"] = float(pd["husk"]) - delta
			if float(pd["husk"]) <= 0.0:
				pods.remove_at(q)
		else:
			pd["t"] = float(pd["t"]) - delta
			if float(pd["t"]) <= 0.0:
				var pat: Vector2 = pd["pos"]
				pd["husk"] = 3.0
				if can_hurt() and pat.distance_to(pp) < 16.0:
					_hurt(10.0)
				for q2 in 3:
					add_foe(_swarm_k, near_free(pat + Vector2.from_angle(rng.randf() * TAU) * 12.0, 10.0))
				tele.append({"kind": "stomp", "pos": pat, "r": 22.0, "t": 0.0, "len": 0.35})
				Audio.play("sv_stomp", "survivor: a pod lands", -10.0)
		q -= 1
	# ---- the kill line: it warms up at the edge, then crosses the field; to touch it (not in a gap, not in a dodge) hurts
	q = klines.size() - 1
	while q >= 0:
		var kl: Dictionary = klines[q]
		if float(kl["warm"]) > 0.0:
			kl["warm"] = float(kl["warm"]) - delta
		else:
			kl["s"] = float(kl["s"]) + SD.LINE_PACE * delta
			var kd: Vector2 = kl["dir"]
			var rel := pp - ((kl["c"] as Vector2) + kd * float(kl["s"]))
			var lat := rel.dot(kd.orthogonal())
			if can_hurt() and absf(rel.dot(kd)) < 5.0 and absf(lat) < float(kl["half"]) and not (kl["gaps"] as Array).any(func(g): return absf(lat - float(g)) < SD.LINE_GAP * 0.5):
				_hurt(20.0)
			if float(kl["s"]) >= float(kl["far"]):
				klines.remove_at(q)
		q -= 1


## (Part 8b) A kill line as it stands now: its stretches of light between its gaps, as pairs of points on the screen.
func _line_parts(kl: Dictionary) -> Array:
	var kd: Vector2 = kl["dir"]
	var c: Vector2 = ((kl["c"] as Vector2) + kd * float(kl["s"])) * S
	var across := kd.orthogonal()
	var cuts: Array = (kl["gaps"] as Array).duplicate()
	cuts.sort()
	var out: Array = []
	var from := -float(kl["half"])
	for g in cuts:
		out.append([c + across * from * S, c + across * (float(g) - SD.LINE_GAP * 0.5) * S])
		from = float(g) + SD.LINE_GAP * 0.5
	out.append([c + across * from * S, c + across * float(kl["half"]) * S])
	return out


## What you set down and what you throw among them: mines, the sentry's guns, gravity wells.
func _devices(delta: float, pp: Vector2) -> void:
	_src = int(_wsrc.get("mines", 0))
	var q := mines.size() - 1
	while q >= 0:                                           # a mine: armed, it goes off when one of them steps on it
		var mn: Dictionary = mines[q]
		mn["life"] = float(mn["life"]) - delta
		var arm := maxf(0.0, float(mn["arm"]) - delta)
		mn["arm"] = arm
		var mp: Vector2 = mn["p"]
		var trod := false
		if arm <= 0.0 and ((_frame + q) & 1) == 0:
			for j0 in touching(mp, 9.0):
				if j0 < n and _beh[fk[j0]] != 5:                  # (what flies does not step on it)
					trod = true
					break
		if trod:
			for j in touching(mp, float(mn["r"])):
				if j < n:
					_hit(j, float(mn["dmg"]), mp)
			if blasts.size() < 40:
				blasts.append({"pos": mp, "r": float(mn["r"]), "t": 0.0})
			if mn.has("g"):
				_fx_add("fire", mp, float(mn["r"]), 0.5)
			Audio.play("sv_boom", "survivor: a mine goes off", -16.0)
			if bool(mn["again"]):                               # (the Minefield: it arms itself once more)
				mn["again"] = false
				mn["arm"] = 1.2
			else:
				mines.remove_at(q)
		elif float(mn["life"]) <= 0.0:
			mines.remove_at(q)
		q -= 1
	var wd := 0.0 if emp_t > 0.0 else delta * (2.0 if over_t > 0.0 else 1.0)
	var reach := float(SD.WEAPONS["sentry"]["reach"]) * float(mods["area"])
	_src = int(_wsrc.get("sentry", 0))
	q = sentries.size() - 1
	while q >= 0:                                           # a gun: it fires at whoever is nearest to it
		var s: Dictionary = sentries[q]
		var spos: Vector2 = s["p"]
		if bool(s["keep"]):                                   # (the Battery: it stays while you stay near)
			s["life"] = 1.5 if spos.distance_squared_to(pp) < 150.0 * 150.0 else float(s["life"]) - delta
		else:
			s["life"] = float(s["life"]) - delta
		s["cd"] = float(s["cd"]) - wd
		s["flash"] = maxf(0.0, float(s["flash"]) - delta)
		if float(s["cd"]) <= 0.0:
			s["cd"] = float(SD.WEAPONS["sentry"]["rate"]) * float(mods["cd"])
			var near: Array = touching(spos, reach)
			if not near.is_empty():
				near.sort_custom(func(a, b): return fp[a].distance_squared_to(spos) < fp[b].distance_squared_to(spos))
				var aim: Array = near.slice(0, 1 + _more())
				aim.sort()
				aim.reverse()
				for j2 in aim:
					if j2 >= n:
						continue
					var tp: Vector2 = fp[j2]
					beams.append({"a": spos + Vector2(0.0, -9.0), "b": tp + CHEST, "t": 0.0, "c": 6 if bool(s["keep"]) else 1})
					var dd := tp - spos
					s["face"] = (3 if dd.x > 0.0 else 2) if absf(dd.x) > absf(dd.y) else (0 if dd.y > 0.0 else 1)
					_hit(j2, float(s["dmg"]), spos)
				s["flash"] = 0.07
				Audio.play("sv_shot", "survivor: a gun fires", -22.0)
		if float(s["life"]) <= 0.0:
			if pops.size() < 60:
				pops.append({"pos": spos, "t": 0.0})
			sentries.remove_at(q)
		q -= 1
	var edge := _half() + Vector2(40.0, 40.0)
	_src = int(_wsrc.get("blackhole", 0))
	q = holes.size() - 1
	while q >= 0:                                           # a black hole: it drifts on to the edge of the picture and swallows what comes near it
		var h: Dictionary = holes[q]
		var hpos: Vector2 = (h["p"] as Vector2) + (h["v"] as Vector2) * delta
		h["p"] = hpos
		if bool(h.get("u", false)) and _frame % 3 == 0:        # (the Event Horizon: the wake it leaves)
			var htr: PackedVector2Array = h.get("tr", PackedVector2Array())
			htr.insert(0, hpos)
			if htr.size() > 14:
				htr.resize(14)
			h["tr"] = htr
		h["t"] = float(h["t"]) + delta
		h["tick"] = float(h["tick"]) + delta
		var htick := float(h["tick"]) >= 0.25
		if htick:
			h["tick"] = 0.0
		var hr := float(h["r"])
		for j4 in touching(hpos, hr):
			if j4 >= n:
				continue
			var k4 := fk[j4]
			var d4 := hpos - fp[j4]
			var l4 := d4.length()
			if _beh[k4] >= SD.BOSS_BEH:                                   # (a boss is not pulled: it is torn at while it stands in it)
				if htick:
					_hit(j4, float(h["dmg"]), fp[j4])
				continue
			if l4 < 9.0:                                        # at its middle: swallowed (the tough ones and the alphas are torn at instead)
				if _tough[k4] != 0 or fal[j4] != 0:
					if htick:
						_hit(j4, float(h["dmg"]), fp[j4])
				else:
					fsh[j4] = 0.0
					_hit(j4, 1000000.0, fp[j4])
				continue
			var hto := fp[j4] + d4 * (minf(l4, 150.0 * clampf(_mass[k4] + 0.35, 0.4, 1.3) * (0.4 + 0.6 * (1.0 - l4 / hr)) * delta) / l4)
			if _beh[k4] == 5 or _solid[_ti(hto)] == 0:
				fp[j4] = hto
		if absf(hpos.x - pp.x) > edge.x + hr or absf(hpos.y - pp.y) > edge.y + hr or float(h["t"]) > 40.0 or hpos.x < 0.0 or hpos.y < 0.0 or hpos.x > _w * TL or hpos.y > _h * TL:
			holes.remove_at(q)
		q -= 1
	_src = int(_wsrc.get("gravity", 0))
	q = wells.size() - 1
	while q >= 0:                                           # a gravity well: it pulls all near it to its middle and wears them down
		var w: Dictionary = wells[q]
		var wp: Vector2 = w["p"]
		var wr := float(w["r"])
		w["t"] = float(w["t"]) + delta
		w["tick"] = float(w["tick"]) + delta
		var tick := float(w["tick"]) >= 0.5
		if tick:
			w["tick"] = 0.0
		var done := float(w["t"]) >= float(w["life"])
		var crush := done and bool(w["ult"])                  # (the Singularity: at its end it crushes what it has pulled in)
		for j3 in touching(wp, wr):
			if j3 >= n:
				continue
			var k := fk[j3]
			if _nosep[k] == 0:                                  # (what flies and a boss are not pulled)
				var d := wp - fp[j3]
				var l := d.length()
				if l > 2.0:
					var to := fp[j3] + d * (minf(l, 64.0 * clampf(_mass[k] + 0.3, 0.35, 1.3) * delta) / l)
					if _solid[_ti(to)] == 0:
						fp[j3] = to
			if crush:
				_hit(j3, float(w["dmg"]) * 12.0 if (_tough[k] != 0 or fal[j3] != 0) else 1000000.0, fp[j3])
			elif tick:
				_hit(j3, float(w["dmg"]), fp[j3])
		if done:
			if crush:
				var pr2 := wr * wr * 2.0
				for sq in sn:                                     # … and sends you the shards
					if sp[sq].distance_squared_to(wp) < pr2:
						spull[sq] = 1
				if blasts.size() < 40:
					blasts.append({"pos": wp, "r": wr, "t": 0.0})
				_fx_add("crush", wp, wr, 0.6)
				Audio.play("sv_boom", "survivor: the singularity", -8.0)
			wells.remove_at(q)
		q -= 1


## (Part 7c-3) The last chance, bought at the console: once a run you stand up again with half your health; a
## shock clears the ground round you.
func _revive(pp: Vector2) -> void:
	run["revive"] = false
	run["revived"] = true
	run["hp"] = SD.max_hp(run) * 0.5
	shield_t = maxf(shield_t, 2.5)
	hurt_cd = SD.HURT_GAP
	for i in range(n - 1, -1, -1):
		if i < n and fp[i].distance_squared_to(pp) < 120.0 * 120.0:
			fsh[i] = 0.0
			_hit(i, 150.0 if (_tough[fk[i]] != 0 or fal[i] != 0) else 1000000.0, pp)
	globs = globs.filter(func(g): return (g["p"] as Vector2).distance_squared_to(pp) > 120.0 * 120.0)
	bombs.append({"pos": pp, "r": 120.0, "t": 0.0})
	say("", "LAST CHANCE")
	Audio.play("sv_level", "survivor: up again", -2.0)


## The cards of the level are drawn anew (the command bus calls this; rerolls are bought at the console). "" or
## why not.
func reroll() -> String:
	if cards.is_empty():
		return "There is no card to take."
	if int(run.get("rerolls", 0)) <= 0:
		return "No reroll left in this run."
	run["rerolls"] = int(run["rerolls"]) - 1
	cards = SD.offers(run, rng)
	Audio.play("sv_item", "survivor: a reroll", -8.0)
	return ""


## The run is over: you are out, or you held the stage to its end.
func end(p_survived: bool) -> void:
	if over:
		return
	over = true
	survived = p_survived
	_blackout(false)
	view._sv_over()


## Debug / tests: the field empty again: nobody, nothing in the air, nothing on the ground.
func clear_swarm() -> void:
	n = 0
	for q in _cnt.size():
		_cnt[q] = 0
	globs.clear()
	pools.clear()
	waves.clear()
	tele.clear()
	nades.clear()
	shots.clear()
	blades.clear()
	blasts.clear()
	beams.clear()
	mines.clear()
	sentries.clear()
	wells.clear()
	cones.clear()
	zaps.clear()
	holes.clear()
	shells.clear()
	booms.clear()
	lights.clear()
	pods.clear()
	klines.clear()
	fields.clear()
	halos.clear()
	fxs.clear()
	nums.clear()
	_ovr_hits.clear()
	search_t = 0.0
	lit_t = 0.0
	emp_t = 0.0
	ovr_t = 0.0
	sweep = {}
	flock_warn = {}
	breaks.clear()
	avas.clear()
	blizzard_t = 0.0


## Debug / tests: `count` of the swarm round you at once (of a kind: shamblers when none is named).
func swarm(count: int, kind: String = "") -> int:
	var made := 0
	var pp: Vector2 = view.pilot.pos
	var k: int = _ki.get(kind, _swarm_k)
	for q in count * 4:
		if made >= count or n >= foe_cap:
			break
		var p := pp + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(70.0, 260.0)
		if p.x < 40.0 or p.y < 40.0 or p.x > _w * TL - 40.0 or p.y > _h * TL - 40.0 or _solid[_ti(p)] != 0:
			continue
		add_foe(k, p)
		made += 1
	return made


# ---------------------------------------------------------------- the pictures

## Who of the swarm is in the picture goes into the strip it stands in; what is to be drawn round some of them
## (a hauler winding up, a spitter about to spit, a howler's howl, an alpha, bars) is noted.
func _to_bands(pp: Vector2) -> void:
	for b in _used:
		var ob: Band = _bands[b]
		ob.ids.resize(0)
		ob.queue_redraw()
	_used.clear()
	_marks.clear()
	var half := _half() + Vector2(30.0, 70.0)
	var x0 := pp.x - half.x
	var x1 := pp.x + half.x
	var y0 := pp.y - half.y
	var y1 := pp.y + half.y
	for i in n:
		var p := fp[i]
		if p.x < x0 or p.x > x1 or p.y < y0 or p.y > y1:
			continue
		if _digs[fk[i]] != 0 and fst[i] < 2:                # (part 9a) under the ice: no figure, a shape on the ground
			if fk[i] == _burrow_k:
				_marks.append(["burrow", p, -1.0 if fst[i] == 0 else clampf(1.0 - ftm[i] / _bur_warn, 0.0, 1.0), i])
			continue
		var b2 := clampi(int(p.y) >> 4, 0, _h - 1)
		var bd: Band = _bands[b2]
		if bd.ids.is_empty():
			_used.append(b2)
		bd.ids.append(i)
		var k := fk[i]
		var bh := _beh[k]
		if bh == 2 and fst[i] == 1:
			_marks.append(["wind", p, 1.0 - ftm[i] / 0.9, i])
		elif bh == 3 and fst[i] == 1:
			_marks.append(["spit", p, 1.0 - ftm[i] / 0.5, i])
		elif bh == 4 and fst[i] == 1:
			_marks.append(["howl", p, 0.0, i])
		elif bh == 9 and fst[i] == 1:
			_marks.append(["aim", p, clampf(1.0 - ftm[i] / 0.7, 0.0, 1.0), i])
		elif bh == 8 and fst[i] == 1:
			_marks.append(["leap", p, 0.0, i])
		elif bh == 14 and fst[i] == 1:
			_marks.append(["fan", p, clampf(1.0 - ftm[i] / 0.7, 0.0, 1.0), i])
		elif bh == 12:
			_marks.append(["jam", p, 0.0, i])
		elif bh == 11 and fst[i] != 0:
			_marks.append(["arm", p, 0.0, i])
		elif bh == 5 and k == _hunter_k:
			_marks.append(["beam", p, 0.0, i])
		if fovr[i] > 0.0:
			_marks.append(["ovr", p, 0.0, i])                 # (part 7f) turned by an Override: a sign over it
		if fal[i] != 0:
			_marks.append(["alpha", p, fhp[i] / maxf(1.0, fmx[i]), i])
		elif (bh == 2 or bh == 10 or bh == 24) and fhp[i] < fmx[i]:
			_marks.append(["bar", p, fhp[i] / maxf(1.0, fmx[i]), i])
	for b3 in _used:
		(_bands[b3] as Band).queue_redraw()


func draw_band(band: Band) -> void:
	var by := band.position.y
	var tk := int(float(run["t"]) * 3.0) if stasis_t <= 0.0 else 0
	var tkf := int(float(run["t"]) * 10.0) if stasis_t <= 0.0 else 0      # (wings beat faster than feet walk)
	var still := Color(0.6, 0.85, 1.4)
	for i in band.ids:
		if i >= n:
			continue
		var p := fp[i]
		var k := fk[i]
		var at := Vector2(p.x * S, p.y * S - by)
		var sz: Vector2 = _tsz[k]
		if fal[i] != 0:
			sz *= 1.45
		var tex: Texture2D = _tex[((k * 4 + fv[i]) * 4 + fface[i]) * 3 + (0 if (ffr[i] > 0.0 or fstun[i] > 0.0) else WALK[((tkf if _beh[k] == 5 else tk) + i) & 3])]
		var sw := _rad[k] * 4.0 * (1.45 if fal[i] != 0 else 1.0)
		band.draw_rect(Rect2(at + Vector2(-sw * 0.5, -3.0), Vector2(sw, 6.0)), Color(0, 0, 0, 0.3))
		var lift := 40.0 if _beh[k] == 5 else 0.0               # (one that flies: above its shadow)
		var col := Color(3.0, 3.0, 3.0) if fflash[i] > 0.0 else (still if (stasis_t > 0.0 or ffr[i] > 0.0) else (Color(1.25, 1.0, 1.3) if fal[i] != 0 else Color.WHITE))
		if fstun[i] > 0.0 and fflash[i] <= 0.0:
			col = Color(1.7, 1.6, 0.8)                           # (stunned by a shock: lit yellow)
		if fovr[i] > 0.0 and fflash[i] <= 0.0:
			col = Color(0.7, 1.7, 0.85)                          # (turned by an Override: it is yours for now)
		if k == _burrow_k and fst[i] == 3:
			col.a = clampf(ftm[i] / 0.45, 0.0, 1.0)              # (part 9a: a burrower going back under the ice)
		band.draw_texture_rect(tex, Rect2(at + Vector2(-sz.x * 0.5, -sz.y - lift), sz), false, col)


## (Luz, 24 Nov 2026) Where something of theirs hurts you on the ground: always the same clear red round, whatever
## colour the thing itself has. (Nothing of yours draws red on the ground, so that the two are never mistaken.)
func _danger(c: Vector2, r: float, a: float = 1.0) -> void:
	draw_circle(c, r, Color(1.0, 0.1, 0.08, 0.14 * a))
	draw_arc(c, r, 0.0, TAU, 48, Color(1.0, 0.14, 0.1, 0.95 * a), 3.0)


## On the ground: what lies there (those who sleep, pools, crates), warnings, the pulse's field, the shards.
func _draw() -> void:
	if view == null or not is_instance_valid(view) or view.pilot == null:
		return
	var pp: Vector2 = view.pilot.pos
	var pc: Vector2 = pp * S
	var half := (_half() + Vector2(60.0, 60.0)) * S
	var tnow := float(run["t"])
	for sl in sleepers:                                     # those lying in the colony
		var lp: Vector2 = (sl["pos"] as Vector2) * S
		if absf(lp.x - pc.x) < half.x and absf(lp.y - pc.y) < half.y:
			var lt: Texture2D = SArt.lying(int(sl["v"]))
			draw_texture_rect(lt, Rect2(lp + Vector2(-32.0, -18.0), Vector2(64.0, 28.0)), false, Color(0.8, 0.8, 0.85))
	for pl in pools:                                        # acid, a bloater's cloud
		var k0 := float(pl["t"]) / float(pl["life"])
		var fade := clampf((1.0 - k0) * 3.0, 0.0, 1.0) * clampf(float(pl["t"]) * 5.0, 0.0, 1.0)
		var pr := float(pl["r"]) * S
		var pq: Vector2 = (pl["pos"] as Vector2) * S
		if String(pl["kind"]) == "acid":
			draw_circle(pq, pr, Color(0.35, 0.8, 0.2, 0.4 * fade))
			_danger(pq, pr, fade)
		else:
			for cq in 6:
				var off := Vector2.from_angle(cq * TAU / 6.0 + tnow * 0.4) * pr * 0.42
				draw_circle(pq + off, pr * (0.6 + 0.08 * sin(tnow * 2.0 + cq)), Color(0.4, 0.75, 0.25, 0.16 * fade))
			_danger(pq, pr, fade)
	for sc8 in scorches:                                    # (part 7f) the earth an Atomic Bomb scorched
		SFX.scorch_ground(self, (sc8["pos"] as Vector2) * S, float(sc8["r"]) * S, float(sc8["t"]) / SFX.SCORCH_LIFE, tnow)
	for nk8 in nukes:                                       # … its ring of force running out over the ground
		SFX.nuke_ground(self, (nk8["pos"] as Vector2) * S, float(nk8["r"]) * S, float(nk8["t"]))
	for hl8 in heals:                                       # a Medkit: a ring of green running out from you
		SFX.heal_ground(self, pc, float(hl8["t"]) / 0.9)
	for cn in cones:                                        # the cryo's cone of cold (Absolute Zero: a wave all round) for a moment
		var kc := float(cn["t"]) / 0.4
		var cpos: Vector2 = (cn["p"] as Vector2) * S
		var crr := float(cn["r"]) * S * (0.4 + 0.6 * minf(1.0, kc * 2.5))
		if float(cn["arc"]) > 3.0:
			SFX.zero_ground(self, cpos, crr, kc, cpos.x * 0.01)      # (Absolute Zero: a front of ice, spikes on it, crystals behind it)
		else:
			var pts := PackedVector2Array([cpos])
			for sgi in 9:
				pts.append(cpos + Vector2.from_angle(float(cn["a"]) - float(cn["arc"]) + sgi * float(cn["arc"]) * 0.25) * crr)
			draw_colored_polygon(pts, Color(0.6, 0.9, 1.0, 0.24 * (1.0 - kc)))
			pts.append(cpos)
			draw_polyline(pts, Color(0.85, 0.97, 1.0, 0.8 * (1.0 - kc)), 2.0)
			for fl in 7:                                          # (flakes of ice in it)
				var fa2 := float(cn["a"]) + (fposmod(fl * 0.618, 1.0) * 2.0 - 1.0) * float(cn["arc"]) * 0.85
				draw_rect(Rect2(cpos + Vector2.from_angle(fa2) * crr * (0.35 + 0.6 * fposmod(fl * 0.37 + kc, 1.0)) - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), Color(1, 1, 1, 0.8 * (1.0 - kc)))
	for wl in wells:                                        # a gravity well: the ground under it, rings running in to its middle
		var wq: Vector2 = (wl["p"] as Vector2) * S
		var wrr := float(wl["r"]) * S * minf(1.0, float(wl["t"]) * 4.0)
		draw_circle(wq, wrr, Color(0.3, 0.15, 0.55, 0.14))
		draw_arc(wq, wrr, 0.0, TAU, 48, Color(0.7, 0.5, 1.0, 0.55), 2.0)
		for rq in 3:
			var rk := 1.0 - fposmod(tnow * 0.9 + rq / 3.0, 1.0)
			draw_arc(wq, wrr * rk, 0.0, TAU, 40, Color(0.75, 0.55, 1.0, 0.4 * (1.0 - rk) + 0.08), 2.0)
	for hl in holes:                                        # a black hole: the ground under it darkens, rings run in to its middle
		var hq: Vector2 = (hl["p"] as Vector2) * S
		var hrr := float(hl["r"]) * S * minf(1.0, float(hl["t"]) * 3.0)
		draw_circle(hq, hrr, Color(0.0, 0.0, 0.02, 0.3))
		draw_circle(hq, hrr * 0.55, Color(0.0, 0.0, 0.02, 0.3))
		draw_arc(hq, hrr, 0.0, TAU, 56, Color(1.0, 0.94, 0.55, 0.5), 2.0)      # (yours: never red or near it on the ground)
		if bool(hl.get("u", false)):                          # (the Event Horizon: what it draws in, the wake it leaves)
			var wake8 := PackedVector2Array()
			for wp8 in hl.get("tr", PackedVector2Array()):
				wake8.append((wp8 as Vector2) * S)
			SFX.horizon_ground(self, hq, hrr, tnow, wake8, float(hl["v"].angle()))
		for hq2 in 4:
			var hk2 := 1.0 - fposmod(tnow * 1.3 + hq2 / 4.0, 1.0)
			draw_arc(hq, hrr * hk2, tnow * 2.0 + hq2, tnow * 2.0 + hq2 + 4.2, 28, Color(1.0, 0.94, 0.6, 0.35 * (1.0 - hk2) + 0.06), 2.0)
	for mn in mines:                                        # a mine: a flat disc, its light blinking once it is armed
		var mq: Vector2 = (mn["p"] as Vector2) * S
		if absf(mq.x - pc.x) > half.x or absf(mq.y - pc.y) > half.y:
			continue
		var armed := float(mn["arm"]) <= 0.0
		var mt: Texture2D = SArt.mine(armed and fposmod(tnow * 2.0 + mq.x * 0.013, 1.0) < 0.5)
		draw_texture_rect(mt, Rect2(mq + Vector2(-mt.get_width(), -mt.get_height() - 1.0), Vector2(mt.get_width(), mt.get_height()) * 2.0), false, Color(1, 1, 1) if armed else Color(0.7, 0.7, 0.78))
	for tl in tele:                                         # warnings and shocks
		var kt := float(tl["t"]) / float(tl["len"])
		var tp: Vector2 = (tl["pos"] as Vector2) * S
		match String(tl["kind"]):
			"stomp":
				draw_arc(tp, float(tl["r"]) * S * (0.3 + 0.7 * kt), 0.0, TAU, 40, Color(1.0, 0.14, 0.1, 0.95 * (1.0 - kt)), 6.0)
				draw_circle(tp, float(tl["r"]) * S * (0.3 + 0.7 * kt), Color(1.0, 0.1, 0.08, 0.16 * (1.0 - kt)))
			"spot":
				draw_circle(tp, float(tl["r"]) * S, Color(1.0, 0.1, 0.08, 0.16 + 0.12 * kt))
				draw_arc(tp, float(tl["r"]) * S, 0.0, TAU, 32, Color(1.0, 0.14, 0.1, 0.95), 3.0)
				draw_arc(tp, float(tl["r"]) * S * (1.0 - kt), 0.0, TAU, 32, Color(1.0, 0.5, 0.45, 0.9), 2.0)
			"break":
				draw_arc(tp + Vector2(0.0, -24.0), 8.0 + float(tl["r"]) * S * kt * 0.6, 0.0, TAU, 16, Color(0.8, 0.95, 1.0, 0.9 * (1.0 - kt)), 3.0)
			"strafe":                                         # (part 8b) the line a hunter burns along, fading behind it
				var sd0: Vector2 = tl["dir"]
				var hn0 := int(tl.get("n", 1))
				for hq0 in hn0:
					var so0 := tp + sd0.orthogonal() * (float(hq0) - float(hn0 - 1) * 0.5) * 46.0 * S
					draw_line(so0 - sd0 * 2600.0, so0 + sd0 * 2600.0, Color(1.0, 0.3, 0.2, 0.1 * (1.0 - kt)), 56.0)
					draw_line(so0 - sd0 * 2600.0, so0 + sd0 * 2600.0, Color(1.0, 0.45, 0.3, 0.5 * (1.0 - kt)), 2.0)
			"override":                                       # an Override goes out from you
				draw_arc(tp, float(tl["r"]) * S * kt, 0.0, TAU, 56, Color(0.3, 1.0, 0.5, 0.9 * (1.0 - kt)), 6.0)
			"emp":                                            # an EMP runs over the field
				draw_arc(tp, float(tl["r"]) * S * kt, 0.0, TAU, 72, Color(0.7, 0.85, 1.0, 0.9 * (1.0 - kt)), 12.0)
			"thermal":                                        # (part 9b) a Thermal Charge: a round of heat running out, gold and white
				draw_circle(tp, float(tl["r"]) * S * kt, Color(1.0, 0.92, 0.6, 0.2 * (1.0 - kt)))
				draw_arc(tp, float(tl["r"]) * S * kt, 0.0, TAU, 64, Color(1.0, 0.95, 0.7, 0.95 * (1.0 - kt)), 9.0)
				draw_arc(tp, float(tl["r"]) * S * kt * 0.8, 0.0, TAU, 56, Color(1.0, 1.0, 1.0, 0.6 * (1.0 - kt)), 4.0)
			"stasis":                                         # (part 7f) a Stasis begins: its wave runs out over the field
				SFX.stasis_ground(self, tp, float(tl["r"]) * S, kt)
			"erupt":                                          # (part 9a) a burrower breaks out: the ice bursts, pieces of it fly
				var er0 := float(tl["r"]) * S * (0.4 + 0.6 * kt)
				draw_circle(tp, er0, Color(0.45, 0.75, 1.0, 0.3 * (1.0 - kt)))
				draw_arc(tp, er0, 0.0, TAU, 36, Color(0.95, 0.99, 1.0, 0.95 * (1.0 - kt)), 5.0)
				draw_arc(tp, er0 * 0.6, 0.0, TAU, 28, Color(0.15, 0.3, 0.6, 0.7 * (1.0 - kt)), 3.0)
				for eq in 9:
					var ed0 := Vector2.from_angle(eq * TAU / 9.0 + tp.x * 0.01)
					var ep0 := tp + ed0 * float(tl["r"]) * S * (0.3 + 1.2 * kt) + Vector2(0.0, -90.0 * sin(kt * PI))
					draw_rect(Rect2(ep0 - Vector2(4.0, 4.0), Vector2(8.0, 8.0)), Color(0.9, 0.97, 1.0, 1.0 - kt))
					draw_rect(Rect2(ep0 - Vector2(4.0, 0.0), Vector2(8.0, 4.0)), Color(0.4, 0.65, 0.95, 1.0 - kt))
	for bk8 in breaks:                                      # (part 9b) a plate of ice: it cracks (red: it will hurt), breaks, lies open a while
		var br8: Rect2 = bk8["r"]
		var bs8 := Rect2(br8.position * S, br8.size * S).grow(-3.0)
		if bool(bk8["done"]):
			var bf8 := clampf(1.0 - (float(bk8["t"]) - float(bk8["len"])) / 4.0, 0.0, 1.0)
			draw_rect(bs8, Color(0.03, 0.1, 0.24, 0.75 * bf8))
			draw_rect(bs8.grow(-10.0), Color(0.1, 0.25, 0.45, 0.5 * bf8))
			draw_rect(bs8, Color(0.9, 0.97, 1.0, 0.8 * bf8), false, 3.0)
		else:
			var bk9 := clampf(float(bk8["t"]) / float(bk8["len"]), 0.0, 1.0)
			draw_rect(bs8, Color(1.0, 0.1, 0.08, 0.1 + 0.2 * bk9))
			draw_rect(bs8, Color(1.0, 0.14, 0.1, 0.95), false, 3.0)
			var bc8 := bs8.get_center()
			for cq8 in 7:
				var ca8 := cq8 * TAU / 7.0 + br8.position.x * 0.01
				var ce8 := bc8 + Vector2.from_angle(ca8) * bs8.size.x * 0.62 * bk9
				draw_line(bc8, ce8, Color(0.06, 0.14, 0.36, 0.9), 2.0)
				draw_line(ce8, ce8 + Vector2.from_angle(ca8 + 0.9) * bs8.size.x * 0.16 * bk9, Color(0.06, 0.14, 0.36, 0.8), 1.5)
	for av8 in avas:                                        # an avalanche: where its front stands (red: it will hurt), the way it goes
		var ad8: Vector2 = av8["dir"]
		var ac8: Vector2 = ((av8["c"] as Vector2) + ad8 * float(av8["s"])) * S
		var ao8 := ad8.orthogonal() * 3000.0
		var warm8 := float(av8["warm"]) > 0.0
		draw_line(ac8 - ao8, ac8 + ao8, Color(1.0, 0.14, 0.1, (0.45 + 0.5 * absf(sin(tnow * 12.0))) if warm8 else 0.95), 6.0)
		draw_line(ac8 - ao8 + ad8 * 20.0, ac8 + ao8 + ad8 * 20.0, Color(1.0, 0.1, 0.08, 0.12), 40.0)
		for aq8 in 5:                                         # (arrows across the field: it goes this way)
			var ap8 := pc + ad8.orthogonal() * (aq8 - 2) * 150.0 + ad8 * (fposmod(tnow * 160.0, 120.0) - 60.0)
			draw_polyline(PackedVector2Array([ap8 - ad8 * 16.0 + ad8.orthogonal() * 16.0, ap8, ap8 - ad8 * 16.0 - ad8.orthogonal() * 16.0]), Color(1.0, 0.14, 0.1, 0.55 if warm8 else 0.3), 4.0)
	for vt in vents:                                        # (part 9a) a steam vent: a hole in the ice, wet rock round it; ready, its rim glows; bursting, a ring of steam runs out
		var vq: Vector2 = (vt["pos"] as Vector2) * S
		if absf(vq.x - pc.x) > half.x + 200.0 or absf(vq.y - pc.y) > half.y + 200.0:
			continue
		var vready := float(vt["cool"]) <= 0.0
		draw_set_transform(vq, 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, 24.0, Color(0.15, 0.19, 0.27, 0.92))
		draw_circle(Vector2.ZERO, 15.0, Color(0.03, 0.04, 0.07))
		draw_arc(Vector2.ZERO, 15.0, PI, TAU, 16, Color(0.4, 0.46, 0.58, 0.9), 2.0)
		if vready:
			draw_circle(Vector2.ZERO, 11.0, Color(1.0, 0.88, 0.4, 0.3 + 0.2 * sin(tnow * 4.0)))      # (the heat down in it)
			draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 28, Color(1.0, 0.92, 0.5, 0.65 + 0.3 * sin(tnow * 4.0)), 2.5)
			draw_arc(Vector2.ZERO, SD.VENT_STEP * S * 1.25, 0.0, TAU, 32, Color(1.0, 0.92, 0.55, 0.4), 1.5)
		else:
			draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 28, Color(0.35, 0.45, 0.6, 0.7), 2.0)
			draw_arc(Vector2.ZERO, 30.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - float(vt["cool"]) / SD.VENT_REST), 32, Color(0.2, 0.5, 0.9, 0.8), 3.0)      # (how far its rest has run)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if float(vt["t"]) > 0.0:
			var vk := 1.0 - float(vt["t"]) / SD.VENT_TIME
			var vr := SD.VENT_R * S * minf(1.0, vk * 3.5)
			draw_circle(vq, vr, Color(1.0, 1.0, 1.0, 0.35 * (1.0 - vk)))
			draw_arc(vq, vr, 0.0, TAU, 56, Color(1.0, 1.0, 1.0, 0.95 * (1.0 - vk)), 7.0)
			draw_arc(vq, vr + 5.0, 0.0, TAU, 56, Color(0.25, 0.45, 0.8, 0.5 * (1.0 - vk)), 3.0)
	if not flock_warn.is_empty() and String(stg["flock"]) in ["hunter", "glider"]:      # (part 8b) hunters are coming: the line they will burn along; (part 9b) gliders: the line their ice falls along
		var fa0: Vector2 = (flock_warn["at"] as Vector2) * S
		var fd0: Vector2 = flock_warn["dir"]
		var hn1 := (1 if tnow < 480.0 else 2) + (1 if String(stg["flock"]) == "glider" else 0)
		for hq1 in hn1:
			var fo0 := fa0 + fd0.orthogonal() * (float(hq1) - float(hn1 - 1) * 0.5) * 46.0 * S
			draw_line(fo0 - fd0 * 2600.0, fo0 + fd0 * 2600.0, Color(1.0, 0.25, 0.2, 0.1), 56.0)
			draw_line(fo0 - fd0 * 2600.0, fo0 + fd0 * 2600.0, Color(1.0, 0.35, 0.25, 0.4 + 0.5 * absf(sin(tnow * 14.0))), 2.0)
	for lt0 in lights:                                      # a searchlight's patch on the ground
		var lq: Vector2 = (lt0["p"] as Vector2) * S
		draw_circle(lq, SD.SEARCH_R * S, Color(1.0, 0.97, 0.8, 0.07))
		draw_arc(lq, SD.SEARCH_R * S, 0.0, TAU, 44, Color(1.0, 0.14, 0.1, 0.9), 3.0)      # (its edge in red: stand in it and a shell comes)
	for pd0 in pods:                                        # a landing pod: its shadow as it comes down, its husk once it has opened
		var pq0: Vector2 = (pd0["pos"] as Vector2) * S
		if float(pd0["husk"]) > 0.0:
			var hk0 := clampf(float(pd0["husk"]), 0.0, 1.0)
			draw_rect(Rect2(pq0 + Vector2(-20.0, -18.0), Vector2(16.0, 20.0)), Color(0.14, 0.15, 0.2, hk0))
			draw_rect(Rect2(pq0 + Vector2(4.0, -18.0), Vector2(16.0, 20.0)), Color(0.14, 0.15, 0.2, hk0))
			draw_rect(Rect2(pq0 + Vector2(-20.0, -18.0), Vector2(16.0, 3.0)), Color(0.3, 0.32, 0.4, hk0))
			draw_rect(Rect2(pq0 + Vector2(4.0, -18.0), Vector2(16.0, 3.0)), Color(0.3, 0.32, 0.4, hk0))
			draw_rect(Rect2(pq0 + Vector2(-4.0, -12.0), Vector2(8.0, 14.0)), Color(0.03, 0.03, 0.05, hk0))
		else:
			draw_circle(pq0, 8.0 + 16.0 * (1.0 - clampf(float(pd0["t"]) / 2.0, 0.0, 1.0)), Color(0, 0, 0, 0.35))
	for mk0 in _marks:                                      # (part 8) a gunner takes aim: the line its bolts will run along; a scout crouches: the way it will leap
		var mi0 := int(mk0[3])
		if mi0 >= n:
			continue
		if String(mk0[0]) == "burrow":                        # (part 9a) a burrower under the ice: a dark shape, the ice cracking over it; where it stopped, the round it will break out of
			var bq0: Vector2 = (mk0[1] as Vector2) * S
			var bk0 := float(mk0[2])
			if bk0 < 0.0:
				var bd0 := (pc + _lead * S - bq0).normalized()
				for bt0 in 4:
					draw_set_transform(bq0 - bd0 * bt0 * 15.0, 0.0, Vector2(1.0, 0.55))
					draw_circle(Vector2.ZERO, 18.0 - bt0 * 3.6, Color(0.06, 0.12, 0.32, 0.5 - bt0 * 0.1))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				for bc0 in 3:
					var ba0: float = bc0 * 2.1 + float(mi0) + floorf(tnow * 8.0) * 1.7
					draw_line(bq0 + Vector2.from_angle(ba0) * 4.0, bq0 + Vector2.from_angle(ba0) * 20.0, Color(0.95, 0.98, 1.0, 0.9), 2.0)
			else:
				var br0 := _bur_r * S
				draw_circle(bq0, br0, Color(1.0, 0.2, 0.12, 0.2))
				draw_circle(bq0, br0 * bk0, Color(1.0, 0.35, 0.15, 0.3))
				draw_arc(bq0, br0, 0.0, TAU, 36, Color(1.0, 0.25, 0.15, 0.95), 3.0)
				for bc1 in 7:
					var ba1 := bc1 * TAU / 7.0 + float(mi0)
					draw_line(bq0, bq0 + Vector2.from_angle(ba1) * br0 * (0.25 + 0.75 * bk0), Color(0.08, 0.16, 0.4, 0.85), 2.0)
			continue
		if String(mk0[0]) == "jam":                           # (part 8b) a jammer's field: who stands in it carries a shield
			draw_arc((mk0[1] as Vector2) * S, float(SD.FOES["jammer"]["jam_r"]) * S, 0.0, TAU, 48, Color(0.4, 0.7, 1.0, 0.22 + 0.12 * sin(tnow * 4.0)), 2.0)
		elif String(mk0[0]) == "arm":                         # a seeker about to go off: how far its burst will reach
			draw_circle((mk0[1] as Vector2) * S, float(SD.FOES["seeker"]["boom_r"]) * S, Color(1.0, 0.3, 0.2, 0.1))
			draw_arc((mk0[1] as Vector2) * S, float(SD.FOES["seeker"]["boom_r"]) * S, 0.0, TAU, 32, Color(1.0, 0.35, 0.25, 0.5 + 0.4 * absf(sin(tnow * 18.0))), 2.0)
		if String(mk0[0]) == "fan":                           # (part 9b) a shardthrower raises its arm: the lines its needles will fly along
			var f0: Vector2 = (mk0[1] as Vector2) * S + Vector2(0.0, -30.0)
			var fcnt := int(SD.FOES["shardthrower"]["fan"]) + (2 if fal[mi0] != 0 else 0)
			for fq in fcnt:
				var fd9 := fvel[mi0].rotated((fq - (fcnt - 1) * 0.5) * float(SD.FOES["shardthrower"]["spread"]))
				draw_line(f0, f0 + fd9 * 220.0 * S, Color(1.0, 0.14, 0.1, 0.3 + 0.5 * float(mk0[2])), 2.0)
				draw_line(f0, f0 + fd9 * 220.0 * S, Color(1.0, 0.14, 0.1, 0.08), 10.0)
		if String(mk0[0]) == "aim":
			var a0: Vector2 = (mk0[1] as Vector2) * S + Vector2(0.0, -30.0)
			draw_line(a0, a0 + fvel[mi0] * 230.0 * S, Color(1.0, 0.25, 0.2, 0.25 + 0.45 * float(mk0[2])), 2.0)
			draw_line(a0, a0 + fvel[mi0] * 230.0 * S, Color(1.0, 0.25, 0.2, 0.08), 12.0)
		elif String(mk0[0]) == "leap":
			var l0: Vector2 = (mk0[1] as Vector2) * S
			draw_line(l0, l0 + fvel[mi0] * 64.0 * S, Color(1.0, 0.5, 0.3, 0.35), 8.0)
	for mk in _marks:                                       # a hauler winds up: the ring its stamp will reach, filling
		if String(mk[0]) == "wind":
			var mp: Vector2 = (mk[1] as Vector2) * S
			draw_circle(mp, STOMP_R * S, Color(1.0, 0.3, 0.2, 0.1))
			draw_arc(mp, STOMP_R * S, 0.0, TAU, 40, Color(1.0, 0.35, 0.25, 0.9), 2.0)
			draw_circle(mp, STOMP_R * S * float(mk[2]), Color(1.0, 0.45, 0.2, 0.16))
	if boss_kind == "foreman" and not bst.is_empty():
		var bi := boss_i()
		if bi >= 0:
			var bp0: Vector2 = fp[bi] * S
			match String(bst["st"]):
				"aim":                                           # the line of its charge
					var e := bp0 + (bst["dir"] as Vector2) * 260.0 * S
					draw_line(bp0, e, Color(1.0, 0.3, 0.2, 0.35), 34.0)
					draw_line(bp0, e, Color(1.0, 0.6, 0.4, 0.8), 2.0)
				"wind":
					draw_arc(bp0, 180.0 * S, 0.0, TAU, 64, Color(1.0, 0.4, 0.25, 0.5), 2.0)
					draw_circle(bp0, 180.0 * S * (1.0 - float(bst["t"]) / 0.8), Color(1.0, 0.45, 0.2, 0.1))
	if boss_kind == "worm" and not bst.is_empty():          # (part 9c) The Ice Worm: its long shape under the ice; the marks where it will break out
		var w9i := boss_i()
		if w9i >= 0:
			if fst[w9i] < 2:
				var w9t: PackedVector2Array = bst.get("trail", PackedVector2Array())
				for w9q in range(w9t.size() - 1, -1, -1):
					draw_set_transform(w9t[w9q] * S, 0.0, Vector2(1.0, 0.58))
					draw_circle(Vector2.ZERO, 30.0 - w9q * 1.3, Color(0.05, 0.1, 0.3, 0.42 - w9q * 0.018))
				draw_set_transform(fp[w9i] * S, 0.0, Vector2(1.0, 0.58))
				draw_circle(Vector2.ZERO, 34.0, Color(0.04, 0.08, 0.26, 0.6))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				for w9c in 5:
					var w9a := w9c * 1.26 + floorf(tnow * 8.0) * 1.7
					draw_line(fp[w9i] * S + Vector2.from_angle(w9a) * 8.0, fp[w9i] * S + Vector2.from_angle(w9a) * 34.0, Color(0.95, 0.98, 1.0, 0.9), 2.0)
			var w9s: Array = bst.get("spots", [])
			var w9r := float(SD.FOES["worm"]["erupt_r"]) * S
			for w9j in range(int(bst.get("si", 0)), w9s.size()):
				var w9p: Vector2 = (w9s[w9j] as Vector2) * S
				_danger(w9p, w9r)
				if w9j == int(bst.get("si", 0)):
					draw_circle(w9p, w9r * clampf(1.0 - float(bst["t"]) / float(SD.FOES["worm"]["warn"]), 0.0, 1.0), Color(1.0, 0.2, 0.12, 0.3))
				for w9k in 6:
					draw_line(w9p, w9p + Vector2.from_angle(w9k * TAU / 6.0 + w9j) * w9r * 0.85, Color(0.06, 0.14, 0.36, 0.75), 2.0)
	if boss_kind == "heart" and not bst.is_empty():         # (part 9c) The Storm Heart: the edge of the eye of its storm (red: out there it hurts)
		var h9i := boss_i()
		if h9i >= 0:
			var h9c: Vector2 = fp[h9i] * S
			var h9r := float(bst["eye"]) * S
			draw_arc(h9c, h9r, 0.0, TAU, 96, Color(1.0, 0.14, 0.1, 0.95), 4.0)
			draw_arc(h9c, h9r + 14.0, 0.0, TAU, 96, Color(1.0, 0.1, 0.08, 0.14), 28.0)
			SFX.dashes(self, h9c, h9r - 12.0, tnow * 0.6, 40, 0.5, Color(0.85, 0.95, 1.0, 0.5), 2.0)
	if (boss_kind == "warden" or boss_kind == "core") and not bst.is_empty():      # (part 8c) the bosses of AI Takeover: what lies on the ground of their field
		var c8i := boss_i()
		if c8i >= 0:
			var c8q: Vector2 = fp[c8i] * S
			var c8warm := float(bst["warm"]) > 0.0
			if boss_kind == "warden":
				var c8len := float(SD.FOES["warden"]["arm"]) * S
				for c8arm in (2 if int(boss_info()["phase"]) == 3 else 1):      # its laser arm: where it burns over the ground
					var c8d := Vector2.from_angle(float(bst["a"]) + c8arm * PI)
					var c8tip := c8q + c8d * _ray_len(fp[c8i], c8d, c8len / S) * S
					draw_line(c8q, c8tip, Color(1.0, 0.2, 0.15, 0.06 if c8warm else 0.3), 30.0)
					draw_line(c8q, c8tip, Color(1.0, 0.55, 0.4, 0.3 if c8warm else 0.95), 2.0 if c8warm else 5.0)
				draw_arc(c8q, c8len, 0.0, TAU, 72, Color(1.0, 0.3, 0.2, 0.14), 1.5)      # (how far it reaches)
				if String(bst["st"]) == "wind":                 # it rears up: how far its stamp will run
					var c8sr := float(SD.FOES["warden"]["stomp_r"]) * S
					draw_arc(c8q, c8sr, 0.0, TAU, 56, Color(1.0, 0.4, 0.25, 0.7), 2.0)
					draw_circle(c8q, c8sr * (1.0 - clampf(float(bst["t"]) / 0.75, 0.0, 1.0)), Color(1.0, 0.45, 0.2, 0.13))
			else:
				for c8f in fields:                              # the floor: a square lights up, brighter and brighter, then it bursts
					var c8r: Rect2 = c8f["r"]
					var c8sq := Rect2(c8r.position * S, c8r.size * S).grow(-3.0)
					if bool(c8f.get("done", false)):
						draw_rect(c8sq, Color(1.0, 0.85, 0.6, 0.85 * clampf(1.0 - (float(c8f["t"]) - float(c8f["len"])) / 0.25, 0.0, 1.0)))
					else:
						var c8k := clampf(float(c8f["t"]) / float(c8f["len"]), 0.0, 1.0)
						draw_rect(c8sq, Color(1.0, 0.25, 0.15, 0.08 + 0.3 * c8k))
						draw_rect(c8sq, Color(1.0, 0.45, 0.3, 0.5 + 0.5 * c8k), false, 2.0)
						draw_rect(c8sq.grow(-c8sq.size.x * 0.5 * (1.0 - c8k)), Color(1.0, 0.65, 0.45, 0.55), false, 2.0)
				if _cnt[_pylon_k] == 0:                          # its cross: four arms of light turning round it
					for c8arm2 in 4:
						var c8d2 := Vector2.from_angle(float(bst["a"]) + c8arm2 * PI * 0.5)
						var c8tip2 := c8q + c8d2 * _ray_len(fp[c8i], c8d2, SD.CROSS_LEN) * S
						draw_line(c8q, c8tip2, Color(1.0, 0.2, 0.15, 0.06 if c8warm else 0.28), 30.0)
						draw_line(c8q, c8tip2, Color(1.0, 0.55, 0.4, 0.3 if c8warm else 0.95), 2.0 if c8warm else 5.0)
				for c8am in bst.get("aims", []):                # a pylon takes aim: the line its beam will run along; then the beam
					var c8a: Vector2 = (c8am["from"] as Vector2) * S
					var c8b: Vector2 = c8a + (c8am["dir"] as Vector2) * _ray_len(c8am["from"], c8am["dir"], 700.0) * S
					if String(c8am["st"]) == "aim":
						draw_line(c8a, c8b, Color(1.0, 0.25, 0.2, 0.25 + 0.55 * (1.0 - clampf(float(c8am["t"]) / 0.9, 0.0, 1.0))), 2.0)
						draw_line(c8a, c8b, Color(1.0, 0.25, 0.2, 0.07), 14.0)
					else:
						draw_line(c8a, c8b, Color(1.0, 0.3, 0.2, 0.5), 18.0)
						draw_line(c8a, c8b, Color(1.0, 0.92, 0.86, 0.95), 5.0)
	for wv in waves:                                        # a ring of force running out
		draw_arc((wv["pos"] as Vector2) * S, float(wv["r"]) * S, 0.0, TAU, 72, Color(1.0, 0.14, 0.1, 0.95), 7.0)
		draw_arc((wv["pos"] as Vector2) * S, float(wv["r"]) * S - 10.0, 0.0, TAU, 72, Color(1.0, 0.3, 0.25, 0.45), 4.0)
	var plv: int = SD.weapon_level(run, "pulse")
	for fx0 in fxs:                                         # (part 7d) what an ultimate leaves on the ground for a moment
		var fk0 := clampf(float(fx0["t"]) / float(fx0["len"]), 0.0, 1.0)
		var fp0: Vector2 = (fx0["p"] as Vector2) * S
		match String(fx0["kind"]):
			"plasma":
				SFX.burst_ground(self, fp0, float(fx0["r"]) * S, fk0, _hue_at(fx0["p"]))
			"fire":
				SFX.burst_ground(self, fp0, float(fx0["r"]) * S, fk0, _hue_at(fx0["p"], 0.0, 0.16))
			"frost":
				SFX.frost_ground(self, fp0, float(fx0["r"]) * S, fk0, float(fx0["s"]))
	var links := {}                                         # the Minefield: light from mine to mine of one ring
	for mn8 in mines:
		if mn8.has("g") and float(mn8["arm"]) <= 0.0:
			if not links.has(mn8["g"]):
				var row8: Array = []
				row8.resize(int(mn8["m"]))
				links[mn8["g"]] = row8
			(links[mn8["g"]] as Array)[int(mn8["q"])] = (mn8["p"] as Vector2) * S
	for lk8 in links:
		SFX.mine_links(self, links[lk8], tnow)
	var guns8: Array = []                                   # the Battery: light from gun to gun and to you
	for sy8 in sentries:
		if bool(sy8["keep"]):
			guns8.append((sy8["p"] as Vector2) * S)
	if not guns8.is_empty():
		SFX.battery_ground(self, pc, guns8, tnow)
	if not orb_pts.is_empty():                              # the plasma orbs: the round they keep to (the Fusion Halo: two, in every colour)
		SFX.orbs_ground(self, pc, orb_r * S, tnow, not orb_out.is_empty())
		if not orb_out.is_empty():
			SFX.orbs_ground(self, pc, orb_r * 1.65 * S, -tnow, true)
	for hal8 in halos:                                      # … a burst of the halo, running out
		SFX.halo_ground(self, (hal8["c"] as Vector2) * S, float(hal8["r"]) * S, clampf((float(hal8["r"]) - float(hal8["from"])) / maxf(1.0, float(hal8["to"]) - float(hal8["from"])), 0.0, 1.0), tnow)
	if not sweep.is_empty() and bool(sweep.get("u", false)):      # the Sunlance: what it burns into the ground where its beam ends
		SFX.sun_ground(self, pc, float(sweep["a"]), float(sweep["reach"]) * S, -1.0 if float(sweep["to"]) < float(sweep["a0"]) else 1.0, float(sweep["a0"]))
	if nova_r > 0.0:                                        # the Nova Field stands
		SFX.nova_ground(self, pc, nova_r * S, tnow, clampf(float(_wt.get("pulse", 0.0)) / 0.35, 0.0, 1.0))
	elif plv > 0:
		draw_arc(pc, float(SD.stats("pulse", plv)["r"]) * float(mods["area"]) * S, 0.0, TAU, 64, Color(0.0, 0.3, 0.75, 0.3) if bright else Color(0.35, 0.8, 1.0, 0.16), 2.0)
	for bl in blasts:                                       # a grenade's burst
		var kb2 := float(bl["t"]) / 0.3
		draw_circle((bl["pos"] as Vector2) * S, float(bl["r"]) * S * (0.5 + 0.5 * kb2), Color(0.45, 1.0, 0.7, 0.35 * (1.0 - kb2)))
		draw_arc((bl["pos"] as Vector2) * S, float(bl["r"]) * S * (0.5 + 0.5 * kb2), 0.0, TAU, 40, Color(0.85, 1.0, 0.92, 0.9 * (1.0 - kb2)), 4.0)
	for nd in nades:                                        # … where one is about to land, its shadow on the way
		if bool(nd.get("u", false)):                          # (the Plasma Rain: it comes down out of the sky: a mark that closes in)
			SFX.comet_mark(self, (nd["b"] as Vector2) * S, float(nd["r"]) * S, float(nd["t"]), tnow, _hue_at(nd["b"]))
			continue
		draw_arc((nd["b"] as Vector2) * S, float(nd["r"]) * S, 0.0, TAU, 32, Color(0.45, 1.0, 0.7, 0.25), 1.5)
		draw_circle((nd["a"] as Vector2).lerp(nd["b"], float(nd["t"])) * S, 5.0, Color(0, 0, 0, 0.3))
	for rg in rings:
		var k := float(rg["t"]) / 0.35
		var rr := float(rg["r"]) * S * (0.35 + 0.65 * k)
		if bright:
			draw_arc(pc, rr, 0.0, TAU, 64, Color(0.0, 0.25, 0.7, 0.55 * (1.0 - k)), 11.0)      # (part 9a: by day a ring of light needs a darker one under it)
		draw_arc(pc, rr, 0.0, TAU, 64, Color(0.5, 0.9, 1.0, 0.85 * (1.0 - k)), 5.0)
		draw_circle(pc, rr, Color(0.35, 0.8, 1.0, 0.1 * (1.0 - k)))
	for cr in crates:                                       # a crate (one still falling: its shadow, growing)
		var cp: Vector2 = (cr["pos"] as Vector2) * S
		var fall := float(cr["fall"])
		if fall > 0.0:
			draw_circle(cp, 10.0 + 14.0 * (1.0 - fall / 1.2), Color(0, 0, 0, 0.35))
		else:
			var ct: Texture2D = SArt.crate(bool(cr["great"]) or bool(cr.get("weapon", false)), false)      # (part 7f: a weapon crate is golden)
			var cs := Vector2(ct.get_width(), ct.get_height()) * 2.0
			draw_rect(Rect2(cp + Vector2(-cs.x * 0.5, -3.0), Vector2(cs.x, 6.0)), Color(0, 0, 0, 0.3))
			draw_texture_rect(ct, Rect2(cp + Vector2(-cs.x * 0.5, -cs.y + 2.0), cs), false)
			if bool(cr.get("ice", false)):                        # (part 9a) frozen in: a block of ice over it
				var it9: Texture2D = SArt.ice_block()
				var is9 := Vector2(it9.get_width(), it9.get_height()) * 2.0
				draw_texture_rect(it9, Rect2(cp + Vector2(-is9.x * 0.5, -is9.y + 8.0), is9), false)
	var fr := int(tnow * 6.0)                               # the shards: small cells of energy, hovering a little over the ground
	for q in sn:
		var s := sp[q] * S
		var tex: Texture2D = _shtex[stier[q] * 4 + ((fr + q) & 3)]
		var sz := Vector2(tex.get_width(), tex.get_height()) * 2.0
		if bright:
			draw_circle(s + Vector2(0.0, -9.0), 11.0, Color(0.04, 0.1, 0.3, 0.3))      # (part 9a) by day its light does not show: a shade behind it instead
		draw_rect(Rect2(s + Vector2(-5.0, 1.0), Vector2(10.0, 3.0)), Color(0, 0, 0, 0.3))
		draw_texture_rect(tex, Rect2(s + Vector2(-sz.x * 0.5, -sz.y - 2.0 + sin(tnow * 3.0 + q * 1.7) * 2.0), sz), false)


## The four sides of the walls of light as they stand now (each from its corners towards its middle).
func _wall_lines() -> Array:
	var out: Array = []
	if barrier_k <= 0.0:
		return out
	var r := barrier
	var cs: Array = [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for q in 4:
		var a: Vector2 = cs[q]
		var b: Vector2 = cs[(q + 1) % 4]
		out.append([a * S, a.lerp(b, 0.5 * barrier_k) * S])
		out.append([b * S, b.lerp(a, 0.5 * barrier_k) * S])
	return out


## What shines in the dark: each shard in its own light, a trail behind one on its way to you; the pulse's ring;
## acid; an alpha; a crate's beacon; the walls of light; in a blackout the eyes of those who come.
func draw_glow(o: Node2D) -> void:
	if view == null or not is_instance_valid(view) or view.pilot == null:
		return
	var gt: Texture2D = view.glow_texture()
	var pp: Vector2 = view.pilot.pos
	var mag2: float = pow(SD.MAGNET * float(mods["mag"]), 2.0)
	var tnow := float(run["t"])
	var all := magnet_t > 0.0
	for q in sn:
		var tier := stier[q]
		var col: Color = SArt.SHARD_COL[tier]
		var s := sp[q] * S + Vector2(0.0, -12.0 + sin(tnow * 3.0 + q * 1.7) * 2.0)
		var r := 20.0 + tier * 7.0
		o.draw_texture_rect(gt, Rect2(s - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(col, 0.5))
		var d := pp - sp[q]
		var l2 := d.length_squared()
		if (all or l2 < mag2) and l2 > 64.0:
			o.draw_line(s, s - d * ((46.0 if all else 18.0) / sqrt(l2)), Color(col, 0.75), 3.0 if all else 2.0)      # (part 7f: under a Magnet each draws a long trail of light)
	var pc := pp * S
	for rg in rings:
		var k := float(rg["t"]) / 0.35
		o.draw_arc(pc, float(rg["r"]) * S * (0.35 + 0.65 * k), 0.0, TAU, 64, Color(0.3, 0.7, 1.0, 0.5 * (1.0 - k)), 9.0)
	if nova_r > 0.0:
		SFX.nova_glow(o, gt, pc, nova_r * S, tnow, clampf(float(_wt.get("pulse", 0.0)) / 0.35, 0.0, 1.0))
	var ch8: Vector2 = CHEST * S
	for bm8 in beams:                                       # (part 7d) the Prism Array's split light, the Chain Lightning
		var bc8 := int(bm8.get("c", 0))
		var bk8 := clampf(1.0 - float(bm8["t"]) / 0.12, 0.0, 1.0)
		if bc8 >= 3 and bc8 <= 5:
			SFX.prism_glow(o, gt, (bm8["a"] as Vector2) * S, (bm8["b"] as Vector2) * S, bc8 - 3, bk8, tnow)
		elif bc8 == 2:
			SFX.chain_glow(o, gt, (bm8["a"] as Vector2) * S, (bm8["b"] as Vector2) * S, bk8, float(_frame / 2) * 3.1 + (bm8["a"] as Vector2).x * 0.13 + (bm8["b"] as Vector2).y * 0.07)
	if not sweep.is_empty() and bool(sweep.get("u", false)):      # the Sunlance
		SFX.sun_glow(o, gt, pc + ch8, float(sweep["a"]), float(sweep["reach"]) * S, tnow)
	for bl8 in blades:                                      # a silverblade's trail of silver light
		var tr8 := PackedVector2Array()
		for tp8 in bl8.get("tr", PackedVector2Array()):
			tr8.append((tp8 as Vector2) * S + ch8 * 0.7)
		if bool(bl8.get("u", false)):                         # (the Silver Storm: its trail beats in every colour)
			SFX.rainbow_ribbon(o, tr8, tnow + float(bl8["v"].angle()), 0.6, 22.0)
			o.draw_texture_rect(gt, Rect2((bl8["p"] as Vector2) * S + ch8 * 0.7 - Vector2(40.0, 40.0), Vector2(80.0, 80.0)), false, Color(SFX.hue(tnow * 0.7), 0.8))
		else:
			SFX.ribbon(o, tr8, Color(0.75, 0.9, 1.0, 0.45), 11.0)
	var halo8 := not orb_out.is_empty()                     # the plasma orbs: each in its light, a trail behind it along the round
	for oq8 in orb_pts.size() + orb_out.size():
		var outer8 := oq8 >= orb_pts.size()
		var op8: Vector2 = ((orb_out[oq8 - orb_pts.size()] if outer8 else orb_pts[oq8]) as Vector2) * S + ch8 * 0.7
		var oc8: Color = SFX.hue(tnow * 0.5 + oq8 * 0.17, 0.15) if halo8 else SFX.WCOL["orbs"]
		var ot8 := PackedVector2Array()
		var oa8 := (op8 - (pc + ch8 * 0.7)).angle()
		var or8 := (op8 - (pc + ch8 * 0.7)).length()
		for ok8 in 12:
			ot8.append(pc + ch8 * 0.7 + Vector2.from_angle(oa8 - ok8 * 0.085 * (-0.8 if outer8 else 1.0)) * or8)
		if halo8:
			SFX.rainbow_ribbon(o, ot8, tnow + oq8, 0.6, 24.0)
		else:
			SFX.ribbon(o, ot8, Color(oc8, 0.55), 20.0)
		SFX.orb_glow(o, gt, op8, 13.0 if halo8 else 11.0, oc8)
	for hal9 in halos:                                      # a burst of the halo: its light
		o.draw_arc((hal9["c"] as Vector2) * S, float(hal9["r"]) * S, 0.0, TAU, 72, Color(SFX.hue(tnow * 0.6, 0.2), 0.4), 18.0)
	var bat8: Array = []                                    # the Battery: a glow under each gun, along its shots
	for sy9 in sentries:
		if bool(sy9["keep"]):
			bat8.append((sy9["p"] as Vector2) * S)
	if not bat8.is_empty():
		SFX.battery_glow(o, gt, bat8, tnow)
	for bm9 in beams:
		if int(bm9.get("c", 0)) == 6:
			var bk9 := clampf(1.0 - float(bm9["t"]) / 0.12, 0.0, 1.0)
			o.draw_line((bm9["a"] as Vector2) * S, (bm9["b"] as Vector2) * S, Color(0.3, 0.8, 1.0, 0.5 * bk9), 16.0)
			o.draw_texture_rect(gt, Rect2((bm9["b"] as Vector2) * S - Vector2(34.0, 34.0), Vector2(68.0, 68.0)), false, Color(0.5, 0.9, 1.0, 0.9 * bk9))
	for mn9 in mines:                                       # the Minefield: each of its mines stands in a light of its own
		if mn9.has("g") and float(mn9["arm"]) <= 0.0:
			o.draw_texture_rect(gt, Rect2((mn9["p"] as Vector2) * S - Vector2(30.0, 34.0), Vector2(60.0, 60.0)), false, Color(1.0, 0.86, 0.3, 0.45 + 0.2 * sin(tnow * 5.0 + float(mn9["q"]))))
	for dr8 in drones:                                      # a drone's lights (the Carrier Swarm: each draws a trail)
		var dg8: Vector2 = (dr8["p"] as Vector2) * S + Vector2(0.0, -52.0)
		var many8 := drones.size() > 1
		o.draw_texture_rect(gt, Rect2(dg8 - Vector2(22.0, 22.0), Vector2(44.0, 44.0)), false, Color(1.0, 0.8, 0.35, 0.6) if many8 else Color(0.3, 0.9, 1.0, 0.45))
		if float(dr8["flash"]) > 0.0:
			o.draw_texture_rect(gt, Rect2(dg8 - Vector2(34.0, 34.0), Vector2(68.0, 68.0)), false, Color(1.0, 0.9, 0.6, 0.9))
		if many8:
			var dt8 := PackedVector2Array()
			for dp8 in dr8["tr"]:
				dt8.append((dp8 as Vector2) * S + Vector2(0.0, -52.0))
			SFX.ribbon(o, dt8, Color(1.0, 0.75, 0.3, 0.5), 12.0)
	for sh8 in shots:                                       # a shot that goes through whoever it hits: a streak of light
		if bool(sh8["pierce"]):
			var sg8: Vector2 = (sh8["p"] as Vector2) * S + ch8
			o.draw_line(sg8 - (sh8["v"] as Vector2).normalized() * 40.0, sg8, Color(1.0, 0.7, 0.25, 0.5), 10.0)
	for fx1 in fxs:                                         # what an ultimate leaves for a moment: its flash
		var fk1 := clampf(float(fx1["t"]) / float(fx1["len"]), 0.0, 1.0)
		var fp1: Vector2 = (fx1["p"] as Vector2) * S
		match String(fx1["kind"]):
			"plasma":
				SFX.burst_glow(o, gt, fp1, float(fx1["r"]) * S, fk1, _hue_at(fx1["p"]))
			"fire":
				SFX.burst_glow(o, gt, fp1, float(fx1["r"]) * S, fk1, _hue_at(fx1["p"], 0.0, 0.16))
			"crush":
				SFX.burst_glow(o, gt, fp1 + Vector2(0.0, -18.0), float(fx1["r"]) * S * 0.8, fk1, Color(0.7, 0.45, 1.0))
			"frost":
				o.draw_texture_rect(gt, Rect2(fp1 - Vector2(1.0, 1.0) * float(fx1["r"]) * S * 1.2, Vector2(2.4, 2.4) * float(fx1["r"]) * S), false, Color(0.6, 0.9, 1.0, 0.3 * (1.0 - fk1)))
	for nd8 in nades:                                       # a comet of the Plasma Rain: its light
		if bool(nd8.get("u", false)):
			var nk8 := float(nd8["t"])
			var ng8: Vector2 = (nd8["b"] as Vector2) * S - Vector2(-90.0, 760.0) * (1.0 - nk8 * nk8)
			o.draw_texture_rect(gt, Rect2(ng8 - Vector2(46.0, 46.0), Vector2(92.0, 92.0)), false, Color(_hue_at(nd8["b"]), 0.95))
	for wl8 in wells:                                       # the Singularity: a wider, deeper light
		if bool(wl8["ult"]):
			var wg8: Vector2 = (wl8["p"] as Vector2) * S + Vector2(0.0, -18.0)
			o.draw_texture_rect(gt, Rect2(wg8 - Vector2(70.0, 70.0), Vector2(140.0, 140.0)), false, Color(0.7, 0.4, 1.0, 0.55 + 0.15 * sin(tnow * 7.0)))
	for hl8 in holes:                                       # the Event Horizon: its disc of light burns brighter
		if bool(hl8.get("u", false)):
			var hg8: Vector2 = (hl8["p"] as Vector2) * S + Vector2(0.0, -20.0)
			o.draw_texture_rect(gt, Rect2(hg8 - Vector2(150.0, 70.0), Vector2(300.0, 140.0)), false, Color(1.0, 0.6, 0.25, 0.5))
	for bl in blasts:
		var kb := float(bl["t"]) / 0.3
		var br := float(bl["r"]) * S * 2.0 * (0.6 + 0.4 * kb)
		o.draw_texture_rect(gt, Rect2((bl["pos"] as Vector2) * S - Vector2(br, br) * 0.5, Vector2(br, br)), false, Color(0.4, 1.0, 0.65, 0.6 * (1.0 - kb)))
	for g in globs:                                         # acid on its way (a gunner's bolt: red)
		var gp: Vector2 = (g["p"] as Vector2) * S + Vector2(0.0, -20.0)
		o.draw_texture_rect(gt, Rect2(gp - Vector2(22.0, 22.0), Vector2(44.0, 44.0)), false, Color(1.0, 0.3, 0.2, 0.8) if g.has("bolt") else Color(0.5, 1.0, 0.3, 0.7))
	if String(run.get("stage", "")) == "takeover":           # (part 8) the machines' red eyes in the dark; tracers of a far fight over the field
		for b0 in _used:
			for i0 in (_bands[b0] as Band).ids:
				if i0 < n and _beh[fk[i0]] < SD.BOSS_BEH:
					var ey := fp[i0] * S + Vector2(2.0, -_tsz[fk[i0]].y + 13.0)
					o.draw_rect(Rect2(ey + Vector2(-2.0, -1.0), Vector2(4.0, 3.0)), Color(0.2, 1.0, 0.4, 0.9) if fovr[i0] > 0.0 else Color(1.0, 0.15, 0.1, 0.9))
					if fsh[i0] > 0.0 and _shield[fk[i0]] <= 0.0:          # (a jammer's shield round it)
						o.draw_arc(fp[i0] * S + Vector2(0.0, -_tsz[fk[i0]].y * 0.5), _tsz[fk[i0]].y * 0.42, 0.0, TAU, 12, Color(0.4, 0.7, 1.0, 0.4), 2.0)
		var vh := _half() * S
		for tq0 in 4:
			var tph := tnow * 0.55 + tq0 * 0.31
			var tk0 := fposmod(tph, 1.0)
			if tk0 > 0.22:
				continue
			var ts := int(floor(tph)) * 7 + tq0 * 13
			var ta0 := Vector2((fposmod(sin(ts * 12.9898) * 43758.5453, 1.0) * 2.0 - 1.0) * vh.x, (fposmod(sin(ts * 78.233) * 12543.21, 1.0) * 2.0 - 1.0) * vh.y)
			var tdir := Vector2.from_angle(-0.5 + fposmod(sin(ts * 3.7) * 911.7, 1.0) * 1.0 + (PI if ts % 2 == 0 else 0.0))
			var th0 := pc + ta0 + tdir * (tk0 / 0.22 - 0.5) * vh.x * 1.6
			o.draw_line(th0, th0 - tdir * 150.0, Color(0.7, 0.4, 1.0, 0.5), 3.0)
			o.draw_line(th0, th0 - tdir * 60.0, Color(0.95, 0.85, 1.0, 0.8), 1.5)
	for pl in pools:
		var pr := float(pl["r"]) * S * 2.4
		o.draw_texture_rect(gt, Rect2((pl["pos"] as Vector2) * S - Vector2(pr, pr) * 0.5, Vector2(pr, pr)), false, Color(0.4, 0.9, 0.25, 0.18 * clampf(1.0 - float(pl["t"]) / float(pl["life"]), 0.0, 1.0)))
	for mk in _marks:
		var mp: Vector2 = (mk[1] as Vector2) * S
		match String(mk[0]):
			"alpha":                                          # an alpha stands in a light of its own
				o.draw_texture_rect(gt, Rect2(mp + Vector2(-70.0, -100.0), Vector2(140.0, 140.0)), false, Color(1.0, 0.35, 0.8, 0.45 + 0.15 * sin(tnow * 5.0)))
			"spit":                                           # a spitter's sack lights up before it spits
				o.draw_texture_rect(gt, Rect2(mp + Vector2(-26.0, -70.0), Vector2(52.0, 52.0)), false, Color(0.5, 1.0, 0.3, float(mk[2])))
	for cr in crates:                                       # a crate's beacon: a beam of light straight up, so that you find it
		var cp: Vector2 = (cr["pos"] as Vector2) * S
		var ccol := Color(1.0, 0.85, 0.35) if (bool(cr["great"]) or bool(cr.get("weapon", false))) else Color(0.35, 0.95, 1.0)
		if bool(cr.get("weapon", false)) and float(cr["fall"]) <= 0.0:      # (part 7f) a weapon crate: rays of gold turning round it
			SFX.flare(o, cp + Vector2(0.0, -44.0), 22.0 + 5.0 * sin(tnow * 5.0), tnow * 0.8, 4, Color(1.0, 0.8, 0.3, 0.45), 1.5)
		var up := float(cr["fall"]) <= 0.0
		o.draw_rect(Rect2(cp + Vector2(-3.0, -150.0), Vector2(6.0, 140.0)), Color(ccol, 0.16 if up else 0.4))
		o.draw_rect(Rect2(cp + Vector2(-1.0, -150.0), Vector2(2.0, 140.0)), Color(ccol, 0.3 if up else 0.6))
		o.draw_texture_rect(gt, Rect2(cp + Vector2(-40.0, -50.0), Vector2(80.0, 80.0)), false, Color(ccol, 0.4 + 0.15 * sin(tnow * 4.0)))
	for bm in bombs:                                        # the bomb: a flash, a ring running out
		var kq := float(bm["t"]) / 0.6
		var bq: Vector2 = (bm["pos"] as Vector2) * S
		var brr := float(bm["r"]) * S
		o.draw_texture_rect(gt, Rect2(bq - Vector2(brr, brr) * 1.6, Vector2(brr, brr) * 3.2), false, Color(1.0, 0.95, 0.8, 0.9 * (1.0 - kq)))
		o.draw_arc(bq, brr * kq, 0.0, TAU, 72, Color(1.0, 0.8, 0.5, 0.9 * (1.0 - kq)), 14.0)
	for nk9 in nukes:                                       # (part 7f) the Atomic Bomb: its flash, the fire in its cloud
		SFX.nuke_glow(o, gt, (nk9["pos"] as Vector2) * S, float(nk9["r"]) * S, float(nk9["t"]))
	if over_t > 0.0:                                        # Overdrive: you stand in gold
		SFX.overdrive_glow(o, gt, pc + Vector2(0.0, -36.0), tnow)
	for zp in zaps:                                         # the taser's shock: a cone of yellow white light
		SFX.taser_glow(o, gt, (zp["p"] as Vector2) * S + Vector2(0.0, -20.0), float(zp["a"]), float(zp["r"]) * S, float(zp["arc"]), clampf(1.0 - float(zp["t"]) / 0.18, 0.0, 1.0))
	for hl in holes:                                        # a black hole: the light it bends round itself
		var hg: Vector2 = (hl["p"] as Vector2) * S + Vector2(0.0, -20.0)
		o.draw_arc(hg, 30.0, 0.0, TAU, 32, Color(1.0, 0.65, 0.3, 0.55), 8.0)
		o.draw_texture_rect(gt, Rect2(hg - Vector2(110.0, 110.0), Vector2(220.0, 220.0)), false, Color(1.0, 0.5, 0.2, 0.22))
	for lt1 in lights:                                      # (part 8b) a searchlight: its patch of light, the beam it comes down in
		var lg: Vector2 = (lt1["p"] as Vector2) * S
		var lr := SD.SEARCH_R * S
		o.draw_texture_rect(gt, Rect2(lg - Vector2(lr, lr) * 1.5, Vector2(lr, lr) * 3.0), false, Color(1.0, 0.96, 0.8, 0.5))
		o.draw_colored_polygon(PackedVector2Array([lg + Vector2(-lr * 0.8, 0.0), lg + Vector2(lr * 0.8, 0.0), lg + Vector2(lr * 0.25 + 300.0, -1600.0), lg + Vector2(-lr * 0.25 + 300.0, -1600.0)]),
			Color(1.0, 0.96, 0.8, 0.06))
	for kl1 in klines:                                      # a kill line: light between its gaps (dim and blinking while it warms up)
		var warming := float(kl1["warm"]) > 0.0
		for seg in _line_parts(kl1):
			o.draw_line(seg[0], seg[1], Color(1.0, 0.2, 0.3, (0.12 + 0.12 * absf(sin(tnow * 12.0))) if warming else 0.55), 14.0)
			o.draw_line(seg[0] + Vector2(0.0, -30.0), seg[1] + Vector2(0.0, -30.0), Color(1.0, 0.2, 0.3, 0.05 if warming else 0.22), 6.0)
	for mk2 in _marks:
		var mq2: Vector2 = (mk2[1] as Vector2) * S
		match String(mk2[0]):
			"beam":                                           # a hunter's beam where it meets the ground
				o.draw_line(mq2 + Vector2(0.0, -44.0), mq2, Color(1.0, 0.3, 0.25, 0.8), 7.0)
				o.draw_texture_rect(gt, Rect2(mq2 - Vector2(46.0, 46.0), Vector2(92.0, 92.0)), false, Color(1.0, 0.35, 0.2, 0.85))
			"arm":                                            # a seeker about to go off
				o.draw_texture_rect(gt, Rect2(mq2 + Vector2(-34.0, -46.0), Vector2(68.0, 68.0)), false, Color(1.0, 0.25, 0.15, 0.4 + 0.5 * absf(sin(tnow * 18.0))))
			"jam":                                            # a jammer's core
				o.draw_texture_rect(gt, Rect2(mq2 + Vector2(-28.0, -106.0), Vector2(56.0, 56.0)), false, Color(0.35, 0.7, 1.0, 0.5 + 0.3 * sin(tnow * 4.0)))
	if (boss_kind == "warden" or boss_kind == "core") and not bst.is_empty():      # (part 8c) the bosses' light
		var g8i := boss_i()
		if g8i >= 0:
			var g8q: Vector2 = fp[g8i] * S
			var g8warm := float(bst["warm"]) > 0.0
			if boss_kind == "warden":
				if not g8warm:
					for g8arm in (2 if int(boss_info()["phase"]) == 3 else 1):
						var g8d := Vector2.from_angle(float(bst["a"]) + g8arm * PI)
						var g8tip := g8q + g8d * _ray_len(fp[g8i], g8d, float(SD.FOES["warden"]["arm"])) * S
						o.draw_line(g8q + Vector2(0.0, -10.0), g8tip + Vector2(0.0, -10.0), Color(1.0, 0.3, 0.2, 0.55), 12.0)
						o.draw_texture_rect(gt, Rect2(g8tip - Vector2(40.0, 50.0), Vector2(80.0, 80.0)), false, Color(1.0, 0.35, 0.2, 0.8))
				o.draw_texture_rect(gt, Rect2(g8q + Vector2(-30.0, -150.0), Vector2(60.0, 60.0)), false, Color(1.0, 0.3, 0.2, 0.7))      # (the lens of its laser)
			else:
				if _cnt[_pylon_k] > 0:                            # its shield: a dome of pale light, fed by the pylons
					var g8d := g8q + Vector2(0.0, -64.0)
					o.draw_texture_rect(gt, Rect2(g8d - Vector2(130.0, 130.0), Vector2(260.0, 260.0)), false, Color(0.4, 0.7, 1.0, 0.3 + (0.45 if _guard_t > 0.0 else 0.0)))
					for g8j in n:
						if fk[g8j] == _pylon_k:
							var g8p: Vector2 = fp[g8j] * S + Vector2(0.0, -106.0)
							o.draw_line(g8p, g8d, Color(0.4, 0.7, 1.0, 0.25 + 0.15 * sin(tnow * 6.0 + g8j)), 5.0)
							o.draw_texture_rect(gt, Rect2(g8p - Vector2(26.0, 26.0), Vector2(52.0, 52.0)), false, Color(0.5, 0.8, 1.0, 0.75))
				elif not g8warm:
					for g8arm2 in 4:
						var g8d2 := Vector2.from_angle(float(bst["a"]) + g8arm2 * PI * 0.5)
						var g8tip2 := g8q + g8d2 * _ray_len(fp[g8i], g8d2, SD.CROSS_LEN) * S
						o.draw_line(g8q + Vector2(0.0, -10.0), g8tip2 + Vector2(0.0, -10.0), Color(1.0, 0.3, 0.2, 0.5), 12.0)
				o.draw_texture_rect(gt, Rect2(g8q + Vector2(-70.0, -158.0), Vector2(140.0, 140.0)), false, Color(1.0, 0.3, 0.2, 0.45 + 0.15 * sin(tnow * 5.0)))      # (its eye)
				for g8am in bst.get("aims", []):
					if String(g8am["st"]) == "fire":
						var g8a: Vector2 = (g8am["from"] as Vector2) * S + Vector2(0.0, -8.0)
						o.draw_line(g8a, g8a + (g8am["dir"] as Vector2) * _ray_len(g8am["from"], g8am["dir"], 700.0) * S, Color(1.0, 0.4, 0.3, 0.7), 14.0)
	for mn in mines:                                        # a mine's light
		if float(mn["arm"]) <= 0.0:
			var mg: Vector2 = (mn["p"] as Vector2) * S + Vector2(0.0, -4.0)
			o.draw_texture_rect(gt, Rect2(mg - Vector2(14.0, 14.0), Vector2(28.0, 28.0)), false, Color(1.0, 0.3, 0.25, 0.35 + 0.25 * sin(tnow * 6.0 + mg.x)))
	for wl in wells:                                        # a gravity well: violet
		var wg: Vector2 = (wl["p"] as Vector2) * S
		var wgr := float(wl["r"]) * S * 1.5
		o.draw_texture_rect(gt, Rect2(wg - Vector2(wgr, wgr), Vector2(wgr, wgr) * 2.0), false, Color(0.55, 0.3, 1.0, 0.3))
	for cn in cones:                                        # the cold: pale blue
		var wave := float(cn["arc"]) > 3.0
		var cg: Vector2 = (cn["p"] as Vector2) * S + (Vector2.ZERO if wave else Vector2.from_angle(float(cn["a"])) * float(cn["r"]) * S * 0.55)
		var cgr := float(cn["r"]) * S * (1.3 if wave else 0.8)
		o.draw_texture_rect(gt, Rect2(cg - Vector2(cgr, cgr), Vector2(cgr, cgr) * 2.0), false, Color(0.6, 0.9, 1.0, 0.45 * (1.0 - float(cn["t"]) / 0.4)))
	for sy0 in sentries:                                    # a gun fires: a flash at its muzzle
		if float(sy0["flash"]) > 0.0:
			o.draw_texture_rect(gt, Rect2((sy0["p"] as Vector2) * S + Vector2(-24.0, -44.0), Vector2(48.0, 48.0)), false, Color(0.5, 0.9, 1.0, 0.8))
	if float(mods.get("cell", 0.0)) > 0.0 and cell_t <= 0.0:    # the Shield Cell, charged: a thin frame of light round you
		o.draw_polyline(SUI.hexpts(pc + Vector2(0.0, -36.0), 44.0, tnow * 0.6), Color(0.5, 0.9, 1.0, 0.4), 3.0)
	for ln in _wall_lines():                                # the walls of light
		o.draw_line(ln[0], ln[1], Color(1.0, 0.25, 0.15, 0.45 + 0.2 * sin(tnow * 9.0)), 12.0)
	if shield_t > 0.0:                                      # a crate's shield round you: its light (part 7f: the dome itself stands over the figures)
		o.draw_texture_rect(gt, Rect2(pc + Vector2(-96.0, -132.0), Vector2(192.0, 192.0)), false, Color(0.35, 0.8, 1.0, 0.35 + 0.5 * clampf(shield_hit / 0.18, 0.0, 1.0)))
	if blackout_t > 0.0:                                    # in the dark: their eyes
		for b in _used:
			for i in (_bands[b] as Band).ids:
				if i < n:
					var ep := fp[i] * S + Vector2(0.0, -_tsz[fk[i]].y + 16.0)
					if _beh[fk[i]] == 5:                              # (one that flies: its eyes sit in its hull, above its shadow)
						ep = fp[i] * S + Vector2(0.0, -_tsz[fk[i]].y + 26.0 - 40.0)
					o.draw_rect(Rect2(ep + Vector2(-4.0, 0.0), Vector2(3.0, 3.0)), Color(0.9, 1.0, 0.4, 0.9))
					o.draw_rect(Rect2(ep + Vector2(2.0, 0.0), Vector2(3.0, 3.0)), Color(0.9, 1.0, 0.4, 0.9))


func draw_over(o: Node2D) -> void:
	var tnow := float(run["t"])
	if not vents.is_empty() or bright:
		var vpc: Vector2 = view.pilot.pos * S
		var vhalf := (_half() + Vector2(90.0, 200.0)) * S
		if bright:                                            # (part 9a) by day a beacon of light alone would not show: a beam with a body to it
			for cr9 in crates:
				var cp9: Vector2 = (cr9["pos"] as Vector2) * S
				if absf(cp9.x - vpc.x) > vhalf.x or absf(cp9.y - vpc.y) > vhalf.y:
					continue
				var cc9 := Color(0.85, 0.55, 0.05) if (bool(cr9["great"]) or bool(cr9.get("weapon", false))) else (Color(0.4, 0.55, 0.8) if bool(cr9.get("ice", false)) else Color(0.0, 0.45, 0.95))
				o.draw_rect(Rect2(cp9 + Vector2(-3.0, -150.0), Vector2(6.0, 140.0)), Color(cc9, 0.3))
				o.draw_rect(Rect2(cp9 + Vector2(-1.0, -150.0), Vector2(2.0, 140.0)), Color(cc9.lightened(0.6), 0.7))
		for vt in vents:                                      # steam over a vent: a wisp while it is ready, a column when it bursts
			var vq: Vector2 = (vt["pos"] as Vector2) * S
			if absf(vq.x - vpc.x) > vhalf.x or absf(vq.y - vpc.y) > vhalf.y + 300.0:
				continue
			if float(vt["t"]) > 0.0:
				var vk := 1.0 - float(vt["t"]) / SD.VENT_TIME
				for sq in 10:
					var sup := sq * 30.0 + vk * 130.0
					var swob := sin(tnow * 7.0 + sq * 1.3) * (5.0 + sq * 2.2)
					var srr := (15.0 + sq * 5.0) * (0.55 + 0.45 * minf(1.0, vk * 4.0))
					var sal := clampf((1.0 - vk) * 2.4, 0.0, 1.0) * (0.97 - sq * 0.05)      # (it stands thick for the first half, then it thins)
					o.draw_circle(vq + Vector2(swob + 3.0, -sup + 4.0), srr + 4.0, Color(0.2, 0.36, 0.7, sal * 0.9))      # (a rim of shade round each puff: white alone would not show on snow)
					o.draw_circle(vq + Vector2(swob, -sup), srr, Color(1.0, 1.0, 1.0, sal))
			elif float(vt["cool"]) <= 0.0:
				for wq in 3:
					var wk := fposmod(tnow * 0.5 + wq / 3.0, 1.0)
					var wp := vq + Vector2(sin(tnow * 2.0 + wq * 2.1) * 5.0, -8.0 - wk * 52.0)
					o.draw_circle(wp + Vector2(2.0, 2.0), 7.5 + wk * 8.0, Color(0.24, 0.4, 0.72, 0.5 * (1.0 - wk)))
					o.draw_circle(wp, 5.0 + wk * 8.0, Color(1.0, 1.0, 1.0, 0.8 * (1.0 - wk)))
	for bm in beams:
		var k := clampf(1.0 - float(bm["t"]) / 0.12, 0.0, 1.0)
		var cold: bool = bm.has("c")                          # (a sentry's shot: thin and cyan)
		var bcode := int(bm.get("c", 0))
		if bcode == 2:                                        # (the Chain Lightning: bolts that fork, a star where they strike)
			SFX.chain_over(o, (bm["a"] as Vector2) * S, (bm["b"] as Vector2) * S, k, float(_frame / 2) * 3.1 + (bm["a"] as Vector2).x * 0.13 + (bm["b"] as Vector2).y * 0.07)
			continue
		if bcode >= 3 and bcode <= 5:                         # (the Prism Array: split light)
			SFX.prism_over(o, (bm["a"] as Vector2) * S, (bm["b"] as Vector2) * S, bcode - 3, k, tnow)
			continue
		if bcode == 6:                                        # (the Battery: a heavier shot)
			SFX.battery_shot(o, (bm["a"] as Vector2) * S, (bm["b"] as Vector2) * S, k, SFX.hue(tnow * 0.3 + (bm["a"] as Vector2).x * 0.01, 0.2))
			continue
		o.draw_line((bm["a"] as Vector2) * S, (bm["b"] as Vector2) * S, Color(0.3, 0.85, 1.0, k) if cold else Color(1.0, 0.3, 0.25, k), 3.0 if cold else 5.0)
		o.draw_line((bm["a"] as Vector2) * S, (bm["b"] as Vector2) * S, Color(0.9, 1.0, 1.0, k) if cold else Color(1.0, 0.9, 0.8, k), 1.0 if cold else 2.0)
	for pq in pops:
		var k2 := float(pq["t"]) / 0.3
		o.draw_arc((pq["pos"] as Vector2) * S + Vector2(0, -18), 6.0 + 16.0 * k2, 0.0, TAU, 14, Color(0.7, 1.0, 0.5, 0.7 * (1.0 - k2)), 3.0)
	var ch: Vector2 = CHEST * S
	for g in globs:                                         # acid in the air (a gunner's bolt: a short red streak)
		var gp: Vector2 = (g["p"] as Vector2) * S + Vector2(0.0, -20.0)
		if g.has("needle"):                                   # (part 9b) a needle of ice: pale, a dark edge to it
			var nd9 := (g["v"] as Vector2).normalized()
			o.draw_line(gp - nd9 * 20.0, gp + nd9 * 2.0, Color(0.05, 0.12, 0.3), 6.0)
			o.draw_line(gp - nd9 * 18.0, gp, Color(0.8, 0.95, 1.0), 3.0)
			continue
		if g.has("bolt"):
			var gd := (g["v"] as Vector2).normalized()
			o.draw_line(gp - gd * 16.0, gp, Color(1.0, 0.25, 0.2), 4.0)
			o.draw_line(gp - gd * 9.0, gp, Color(1.0, 0.9, 0.8), 2.0)
			continue
		o.draw_circle(gp, 7.0, Color(0.3, 0.75, 0.15))
		o.draw_circle(gp + Vector2(-2.0, -2.0), 3.0, Color(0.8, 1.0, 0.5))
	for mk in _marks:
		var mp: Vector2 = (mk[1] as Vector2) * S
		var top: float = _tsz[fk[int(mk[3])]].y if int(mk[3]) < n else 80.0
		match String(mk[0]):
			"howl":                                           # a howler's howl: rings of sound going out from it
				for q in 3:
					var hk := fposmod(tnow * 1.6 + q / 3.0, 1.0)
					o.draw_arc(mp + Vector2(0.0, -top * 0.7), HOWL_R * S * hk, 0.0, TAU, 36, Color(1.0, 0.5, 0.4, 0.5 * (1.0 - hk)), 2.0)
			"alpha":                                          # an alpha: its bar, a mark over its head
				top *= 1.45
				o.draw_rect(Rect2(mp + Vector2(-26.0, -top - 12.0), Vector2(52.0, 6.0)), Color(0.05, 0.05, 0.08, 0.85))
				o.draw_rect(Rect2(mp + Vector2(-25.0, -top - 11.0), Vector2(50.0 * float(mk[2]), 4.0)), Color(1.0, 0.4, 0.85))
				o.draw_colored_polygon(PackedVector2Array([mp + Vector2(-9.0, -top - 16.0), mp + Vector2(-5.0, -top - 26.0), mp + Vector2(0.0, -top - 18.0), mp + Vector2(5.0, -top - 26.0),
					mp + Vector2(9.0, -top - 16.0)]), Color(1.0, 0.85, 0.35))
			"bar":
				o.draw_rect(Rect2(mp + Vector2(-22.0, -top - 10.0), Vector2(44.0, 5.0)), Color(0.05, 0.05, 0.08, 0.85))
				o.draw_rect(Rect2(mp + Vector2(-21.0, -top - 9.0), Vector2(42.0 * float(mk[2]), 3.0)), Color(1.0, 0.6, 0.3))
			"ovr":                                            # (part 7f) turned by an Override: a small green sign over it
				SFX.ovr_mark(o, mp + Vector2(0.0, -top - 12.0), tnow)
	for zp2 in zaps:                                        # the taser's shock: a cone of lightning from you, the way you look
		SFX.taser_over(o, (zp2["p"] as Vector2) * S + Vector2(0.0, -20.0), float(zp2["a"]), float(zp2["r"]) * S, float(zp2["arc"]), clampf(1.0 - float(zp2["t"]) / 0.18, 0.0, 1.0),
			float(_frame / 2))
	for hl2 in holes:                                       # a black hole: nothing in its middle, a disc of light turning round it
		var hc: Vector2 = (hl2["p"] as Vector2) * S + Vector2(0.0, -20.0)
		var hgrow := minf(1.0, float(hl2["t"]) * 3.0)
		if bool(hl2.get("u", false)):                         # (the Event Horizon: a wider disc in three layers, streaks falling in)
			SFX.horizon_over(o, hc, hgrow, tnow, float(hl2["v"].angle()))
			continue
		o.draw_set_transform(hc, -0.35, Vector2(1.0, 0.36))
		o.draw_arc(Vector2.ZERO, 34.0 * hgrow, 0.0, TAU, 40, Color(1.0, 0.75, 0.4, 0.9), 5.0)
		o.draw_arc(Vector2.ZERO, 44.0 * hgrow, tnow * 2.5, tnow * 2.5 + 3.6, 28, Color(1.0, 0.9, 0.7, 0.7), 3.0)
		o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		o.draw_circle(hc, 17.0 * hgrow, Color(0.0, 0.0, 0.0))
		o.draw_arc(hc, 17.0 * hgrow, 0.0, TAU, 28, Color(1.0, 0.85, 0.6), 2.0)
		o.draw_set_transform(hc, -0.35, Vector2(1.0, 0.36))
		o.draw_arc(Vector2.ZERO, 34.0 * hgrow, 0.2, PI - 0.2, 24, Color(1.0, 0.75, 0.4, 0.9), 5.0)
		o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if boss_kind == "core" and _cnt[_pylon_k] > 0:           # (part 8c) The Core's shield: a dome over it while a pylon stands
		var o8i := boss_i()
		if o8i >= 0:
			var o8c: Vector2 = fp[o8i] * S + Vector2(0.0, -64.0)
			var o8a := 0.5 + (0.45 if _guard_t > 0.0 else 0.0)
			o.draw_arc(o8c, 86.0, PI, TAU, 40, Color(0.6, 0.85, 1.0, o8a), 3.0)
			o.draw_arc(o8c, 86.0, 0.0, PI, 40, Color(0.6, 0.85, 1.0, o8a * 0.4), 2.0)
			for o8q in 3:
				o.draw_arc(o8c, 86.0 * (0.4 + 0.2 * o8q), PI + 0.3 + tnow * 0.4 + o8q, PI + 1.5 + tnow * 0.4 + o8q, 14, Color(0.7, 0.9, 1.0, 0.3), 1.5)
	for sh0 in shells:                                      # (part 8b) a shell on its way: a bulwark's in an arc, the artillery's straight down out of the sky
		var sk0 := clampf(float(sh0["t"]) / float(sh0["len"]), 0.0, 1.0)
		var sto: Vector2 = (sh0["pos"] as Vector2) * S
		if (sh0["from"] as Vector2) == Vector2.INF:
			if sk0 > 0.55 and not bool(sh0.get("zap", false)):      # (lightning shows only when it strikes)
				var sy2 := sto + Vector2(130.0, -1400.0) * (1.0 - (sk0 - 0.55) / 0.45)
				o.draw_line(sy2 + Vector2(14.0, -150.0), sy2, Color(1.0, 0.8, 0.5, 0.9), 4.0)
				o.draw_circle(sy2, 5.0, Color(1.0, 0.95, 0.8))
		else:
			var sp4 := ((sh0["from"] as Vector2) * S + Vector2(0.0, -70.0)).lerp(sto, sk0) + Vector2(0.0, -sin(sk0 * PI) * 170.0)
			if bool(sh0.get("rocket", false)):                    # (part 8c) one of The Warden's rockets: a flame behind it
				var sk1 := maxf(0.0, sk0 - 0.05)
				var sp5 := ((sh0["from"] as Vector2) * S + Vector2(0.0, -70.0)).lerp(sto, sk1) + Vector2(0.0, -sin(sk1 * PI) * 170.0)
				o.draw_line(sp4, sp4 + (sp5 - sp4) * 1.6, Color(1.0, 0.7, 0.35, 0.9), 4.0)
			o.draw_circle(sp4, 6.0, Color(0.15, 0.15, 0.18))
			o.draw_circle(sp4 + Vector2(-1.5, -1.5), 2.5, Color(1.0, 0.5, 0.3))
	for pd1 in pods:                                        # a landing pod on its way down
		if float(pd1["husk"]) <= 0.0:
			var pq2: Vector2 = (pd1["pos"] as Vector2) * S + Vector2(0.0, -float(pd1["t"]) * 1100.0)
			o.draw_line(pq2 + Vector2(0.0, -44.0), pq2 + Vector2(0.0, -130.0), Color(1.0, 0.7, 0.4, 0.5), 6.0)
			o.draw_rect(Rect2(pq2 + Vector2(-13.0, -44.0), Vector2(26.0, 44.0)), Color(0.16, 0.17, 0.22))
			o.draw_rect(Rect2(pq2 + Vector2(-13.0, -44.0), Vector2(26.0, 5.0)), Color(0.3, 0.32, 0.4))
			o.draw_rect(Rect2(pq2 + Vector2(-13.0, -6.0), Vector2(26.0, 6.0)), Color(0.09, 0.09, 0.12))
			o.draw_rect(Rect2(pq2 + Vector2(-3.0, -30.0), Vector2(6.0, 4.0)), Color(1.0, 0.25, 0.2))
	for kl2 in klines:                                      # a kill line's bright core, the posts at its gaps
		if float(kl2["warm"]) <= 0.0:
			for seg2 in _line_parts(kl2):
				o.draw_line(seg2[0], seg2[1], Color(1.0, 0.75, 0.75), 3.0)
				for end2 in 2:
					o.draw_rect(Rect2((seg2[end2] as Vector2) + Vector2(-4.0, -34.0), Vector2(8.0, 36.0)), Color(0.2, 0.2, 0.26))
					o.draw_rect(Rect2((seg2[end2] as Vector2) + Vector2(-3.0, -38.0), Vector2(6.0, 6.0)), Color(1.0, 0.3, 0.35))
	for mk3 in _marks:
		if String(mk3[0]) == "beam":                          # a hunter's beam: down from it to the ground
			o.draw_line((mk3[1] as Vector2) * S + Vector2(0.0, -44.0), (mk3[1] as Vector2) * S + Vector2(0.0, -2.0), Color(1.0, 0.92, 0.88), 2.5)
	if lit_t > 0.0 and view != null and is_instance_valid(view) and view.pilot != null:      # you stand in a searchlight: how long until you are marked
		var lc0: Vector2 = view.pilot.pos * S + Vector2(0.0, -36.0)
		o.draw_arc(lc0, 62.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(lit_t / SD.SEARCH_LIT, 0.0, 1.0), 40, Color(1.0, 0.25, 0.2, 0.95), 5.0)
	for sy in sentries:                                     # a sentry's gun: on three legs, turned to whoever it fires at (it blinks before it goes)
		var syq: Vector2 = (sy["p"] as Vector2) * S
		var stx: Texture2D = SArt.sentry(int(sy["face"]), float(sy["flash"]) > 0.0)
		var ssz := Vector2(stx.get_width(), stx.get_height()) * 2.0
		o.draw_rect(Rect2(syq + Vector2(-12.0, -3.0), Vector2(24.0, 6.0)), Color(0, 0, 0, 0.3))
		o.draw_texture_rect(stx, Rect2(syq + Vector2(-ssz.x * 0.5, -ssz.y + 2.0), ssz), false,
			Color(1, 1, 1, 1.0 if (bool(sy["keep"]) or float(sy["life"]) > 1.5 or fposmod(tnow * 6.0, 1.0) < 0.6) else 0.35))
	for wl2 in wells:                                       # a gravity well: a dark sphere, light bent round it
		var wc: Vector2 = (wl2["p"] as Vector2) * S + Vector2(0.0, -18.0)
		var grow := minf(1.0, float(wl2["t"]) * 4.0) * (1.0 + 0.08 * sin(tnow * 9.0))
		if bool(wl2["ult"]):                                  # (the Singularity: arms of light winding into a dark heart)
			SFX.sing_over(o, wc, float(wl2["r"]) * S, tnow, grow)
			continue
		o.draw_circle(wc, 13.0 * grow, Color(0.05, 0.02, 0.12))
		o.draw_arc(wc, 13.0 * grow, 0.0, TAU, 24, Color(0.8, 0.6, 1.0), 2.0)
		o.draw_arc(wc, 19.0 * grow, tnow * 3.0, tnow * 3.0 + 2.2, 12, Color(0.75, 0.55, 1.0, 0.8), 2.0)
		o.draw_arc(wc, 19.0 * grow, tnow * 3.0 + PI, tnow * 3.0 + PI + 2.2, 12, Color(0.75, 0.55, 1.0, 0.8), 2.0)
	for cr in crates:                                       # a crate still falling
		if float(cr["fall"]) > 0.0:
			var ct: Texture2D = SArt.crate(bool(cr["great"]) or bool(cr.get("weapon", false)), false)      # (part 7f: a weapon crate is golden)
			var cs := Vector2(ct.get_width(), ct.get_height()) * 2.0
			o.draw_texture_rect(ct, Rect2((cr["pos"] as Vector2) * S + Vector2(-cs.x * 0.5, -cs.y - float(cr["fall"]) * 520.0), cs), false)
	if boss_kind == "foreman" and String(bst.get("st", "")) == "throw":      # The Foreman's containers, on their way down onto their marks
		var kc := clampf(1.0 - float(bst["t"]) / 1.1, 0.0, 1.0)
		var cols: Array = [Color(0.78, 0.36, 0.12), Color(0.2, 0.42, 0.6), Color(0.72, 0.6, 0.16)]
		var ci := 0
		for sp3 in bst.get("spots", []):
			var body: Color = cols[ci % cols.size()]
			var cq: Vector2 = (sp3 as Vector2) * S + Vector2(0.0, -(1.0 - kc * kc) * 640.0)
			var box := Rect2(cq + Vector2(-34.0, -46.0), Vector2(68.0, 46.0))
			o.draw_rect(box, body)
			o.draw_rect(Rect2(box.position, Vector2(box.size.x, 7.0)), body.lightened(0.25))
			o.draw_rect(Rect2(box.position + Vector2(0.0, box.size.y - 7.0), Vector2(box.size.x, 7.0)), body.darkened(0.35))
			for rb in 6:
				o.draw_rect(Rect2(box.position + Vector2(5.0 + rb * 11.0, 9.0), Vector2(3.0, box.size.y - 18.0)), body.darkened(0.25))
			o.draw_rect(box, Color(0.08, 0.07, 0.08), false, 2.0)
			ci += 1
	for nd in nades:                                        # a grenade in the air
		var kn := float(nd["t"])
		if bool(nd.get("u", false)):                          # (the Plasma Rain: a comet out of the sky)
			SFX.comet(o, (nd["b"] as Vector2) * S, kn, _hue_at(nd["b"]))
			continue
		var np: Vector2 = (nd["a"] as Vector2).lerp(nd["b"], kn) * S + Vector2(0.0, -sin(kn * PI) * 90.0 - 36.0 * (1.0 - kn))
		o.draw_circle(np, 6.5, Color(0.45, 1.0, 0.7))
		o.draw_circle(np, 3.0, Color(0.95, 1.0, 0.95))
	for sh in shots:                                        # the drone's shots
		var sp2: Vector2 = (sh["p"] as Vector2) * S + ch
		SFX.tracer(o, sp2, (sh["v"] as Vector2).normalized(), bool(sh["pierce"]), SFX.hue(tnow * 0.8 + float(sh["v"].angle()) * 0.16, 0.15))
	for dq in drones.size():                                # (part 7d) the drones that fly with you
		var dr: Dictionary = drones[dq]
		SFX.drone(o, SArt.drone(int(tnow * 20.0) + dq, drones.size() > 1), (dr["p"] as Vector2) * S, 52.0 + sin(tnow * 3.0 + dq * 2.0) * 4.0, float(dr["a"]), float(dr["flash"]) > 0.0,
			drones.size() > 1)
	if not sweep.is_empty() and view != null and is_instance_valid(view) and view.pilot != null:      # the superlaser, sweeping
		var so: Vector2 = view.pilot.pos * S + ch
		var way := -1.0 if float(sweep["to"]) < float(sweep["a0"]) else 1.0
		if bool(sweep.get("u", false)):                       # (the Sunlance: a beam like a sun's)
			SFX.sun_over(o, so, float(sweep["a"]), float(sweep["reach"]) * S, way, float(sweep["a0"]), tnow)
		else:
			for tq in range(6, 0, -1):                           # (what it leaves behind for a moment)
				var ta := float(sweep["a"]) - way * tq * 0.045
				if (ta - float(sweep["a0"])) * way < 0.0:
					continue
				o.draw_line(so, so + Vector2.from_angle(ta) * float(sweep["reach"]) * S, Color(1.0, 0.35, 0.65, 0.22 - tq * 0.03), 18.0)
			var se: Vector2 = so + Vector2.from_angle(float(sweep["a"])) * float(sweep["reach"]) * S
			o.draw_line(so, se, Color(1.0, 0.3, 0.6, 0.55), 30.0)
			o.draw_line(so, se, Color(1.0, 0.75, 0.9), 14.0)
			o.draw_line(so, se, Color(1, 1, 1), 5.0)
	var spin := tnow * 14.0
	for bl9 in blades:                                      # the silverblades: each with a trail of silver behind it (Luz, 23 Nov 2026)
		var tr9 := PackedVector2Array()
		for tp9 in bl9.get("tr", PackedVector2Array()):
			tr9.append((tp9 as Vector2) * S + ch * 0.7)
		if bool(bl9.get("u", false)):                         # (the Silver Storm: a larger blade, its trail in every colour, beating)
			SFX.rainbow_ribbon(o, tr9, tnow + float(bl9["v"].angle()), 0.95, 9.0)
			SFX.blade(o, (bl9["p"] as Vector2) * S + ch * 0.7, spin, 23.0, SFX.hue(tnow * 0.7, 0.1))
		else:
			SFX.ribbon(o, tr9, Color(0.86, 0.93, 1.0, 0.85), 5.0)
			SFX.blade(o, (bl9["p"] as Vector2) * S + ch * 0.7, spin, 17.0, Color(0.4, 0.95, 1.0))
	if not orb_pts.is_empty() and view != null and is_instance_valid(view) and view.pilot != null:      # the plasma orbs (the Fusion Halo: two rings, lightning from orb to orb)
		var halo9 := not orb_out.is_empty()
		for ring9 in (2 if halo9 else 1):
			var pts9: Array = orb_out if ring9 == 1 else orb_pts
			for oq9 in pts9.size():
				var oc9: Vector2 = (pts9[oq9] as Vector2) * S + ch * 0.7
				var col9: Color = SFX.hue(tnow * 0.5 + (oq9 + ring9 * pts9.size()) * 0.17, 0.15) if halo9 else SFX.WCOL["orbs"]
				if halo9 and pts9.size() > 1:
					var nx9: Vector2 = (pts9[(oq9 + 1) % pts9.size()] as Vector2) * S + ch * 0.7
					SFX.bolt(o, oc9, nx9, float(_frame / 2) * 2.3 + oq9 * 7.0 + ring9 * 31.0, 12.0, Color(col9, 0.75), 2.5)
				SFX.orb(o, oc9, 13.0 if halo9 else 11.0, col9, tnow, oq9 * 3.0 + ring9 * 17.0)
	for ln in _wall_lines():                                # the walls of light: a bright line, posts at the corners
		o.draw_line(ln[0], ln[1], Color(1.0, 0.5, 0.35), 3.0)
		o.draw_line(ln[0] + Vector2(0.0, -26.0), ln[1] + Vector2(0.0, -26.0), Color(1.0, 0.4, 0.3, 0.5), 2.0)
	if barrier_k > 0.0:
		for cq in [barrier.position, Vector2(barrier.end.x, barrier.position.y), barrier.end, Vector2(barrier.position.x, barrier.end.y)]:
			var cc: Vector2 = (cq as Vector2) * S
			o.draw_rect(Rect2(cc + Vector2(-5.0, -40.0), Vector2(10.0, 42.0)), Color(0.2, 0.22, 0.28))
			o.draw_rect(Rect2(cc + Vector2(-3.0, -44.0), Vector2(6.0, 6.0)), Color(1.0, 0.4, 0.3))
	if view != null and is_instance_valid(view) and view.pilot != null:
		var pc: Vector2 = view.pilot.pos * S
		var hpk := clampf(float(run["hp"]) / (SD.HEALTH + float(mods["hp"])), 0.0, 1.0)
		o.draw_rect(Rect2(pc + Vector2(-26.0, 8.0), Vector2(52.0, 6.0)), Color(0.05, 0.05, 0.08, 0.85))
		o.draw_rect(Rect2(pc + Vector2(-25.0, 9.0), Vector2(50.0 * hpk, 4.0)), Color(1.0, 0.3, 0.3) if hpk < 0.35 else Color(0.4, 1.0, 0.5))
		var chest9 := pc + Vector2(0.0, -36.0)                  # (part 7f) what a crate's item looks like while it lasts
		if over_t > 0.0:
			var od9 := PackedVector2Array()
			for op9 in _od_tr:
				od9.append(op9 * S)
			SFX.overdrive_over(o, chest9, tnow, od9, over_t < 1.2)
		if magnet_t > 0.0:
			SFX.magnet_over(o, chest9, tnow, clampf(magnet_t / 0.5, 0.0, 1.0))
		for hl9 in heals:
			SFX.heal_over(o, chest9, float(hl9["t"]) / 0.9)
		if stasis_t > 0.0:
			SFX.stasis_clock(o, chest9, clampf(stasis_t / maxf(0.1, stasis_len), 0.0, 1.0), tnow)
		if shield_t > 0.0:
			SFX.shield_dome(o, chest9, 58.0, tnow, shield_t < 1.2, clampf(shield_hit / 0.18, 0.0, 1.0))
	for fx2 in fxs:                                         # (part 7d) what an ultimate leaves for a moment: sparks, a crush
		var fk2 := clampf(float(fx2["t"]) / float(fx2["len"]), 0.0, 1.0)
		var fp2: Vector2 = (fx2["p"] as Vector2) * S
		match String(fx2["kind"]):
			"plasma":
				SFX.burst_over(o, fp2, float(fx2["r"]) * S, fk2, _hue_at(fx2["p"]), float(fx2["s"]))
			"fire":
				SFX.burst_over(o, fp2, float(fx2["r"]) * S, fk2, _hue_at(fx2["p"], 0.0, 0.16), float(fx2["s"]))
			"crush":
				SFX.crush_over(o, fp2 + Vector2(0.0, -18.0), float(fx2["r"]) * S, fk2)
	if not nums.is_empty():                                 # the numbers of damage, each in the colour of what dealt it
		var nfont := ThemeDB.fallback_font
		for nm in nums:
			var nc := int(nm["c"])
			var ncol: Color = SFX.PLAIN if (nc & 15) == 0 else SFX.WCOL[String(SD.WEAPON_ORDER[(nc & 15) - 1])]
			SFX.number(o, nfont, (nm["p"] as Vector2) * S + Vector2(0.0, -float(nm["h"]) - 6.0), int(nm["v"]), ncol, float(nm["t"]) / NUM_LIFE, (nc & 64) != 0, (nc & 32) != 0)
	for nk7 in nukes:                                       # (part 7f) the Atomic Bomb: its flash, its ball of fire, its cloud, over everything
		SFX.nuke_over(o, (nk7["pos"] as Vector2) * S, float(nk7["r"]) * S, float(nk7["t"]))
	for av9 in avas:                                        # (part 9b) an avalanche: a wall of snow rolling behind its front
		if float(av9["warm"]) > 0.0:
			continue
		var ad9: Vector2 = av9["dir"]
		var ac9: Vector2 = ((av9["c"] as Vector2) + ad9 * float(av9["s"])) * S
		var mid9: Vector2 = ac9 + ad9.orthogonal() * (view.pilot.pos * S - ac9).dot(ad9.orthogonal())
		for row9 in 3:
			for pq9 in 31:
				var pp9 := mid9 + ad9.orthogonal() * (pq9 - 15) * 62.0 - ad9 * (40.0 + row9 * 58.0) + Vector2(sin(tnow * 6.0 + pq9 * 1.7 + row9) * 9.0, cos(tnow * 5.0 + pq9) * 9.0 - 26.0)
				var pr9 := 50.0 + 12.0 * sin(pq9 * 2.3 + row9 * 1.1 + tnow * 3.0)
				o.draw_circle(pp9 + Vector2(4.0, 5.0), pr9 + 4.0, Color(0.3, 0.45, 0.75, 0.55 - row9 * 0.12))
				o.draw_circle(pp9, pr9, Color(0.97, 0.99, 1.0, 0.95 - row9 * 0.2))
	for tz9 in tele:                                        # (part 9c) lightning strikes: a bolt out of the storm
		if String(tz9["kind"]) == "zap":
			var zk9 := 1.0 - float(tz9["t"]) / float(tz9["len"])
			var zp9: Vector2 = (tz9["pos"] as Vector2) * S
			SFX.bolt(o, zp9 + Vector2(40.0, -900.0), zp9, float(_frame / 2) * 2.3 + zp9.x, 46.0, Color(0.75, 0.9, 1.0, zk9), 7.0)
			o.draw_circle(zp9, float(tz9["r"]) * S * (0.6 + 0.4 * zk9), Color(0.85, 0.95, 1.0, 0.6 * zk9))
	if boss_kind == "heart" and not bst.is_empty() and boss_i() >= 0:      # The Storm Heart: all outside the eye is storm, driving round it
		var hc9: Vector2 = fp[boss_i()] * S + Vector2(0.0, -30.0)
		var hr9 := float(bst["eye"]) * S
		for hq9 in 4:
			o.draw_arc(hc9, hr9 + hq9 * 26.0 + 13.0, 0.0, TAU, 96, Color(0.88, 0.93, 1.0, 0.16 + 0.19 * hq9), 28.0)
		o.draw_arc(hc9, hr9 + 104.0 + 1400.0, 0.0, TAU, 96, Color(0.88, 0.93, 1.0, 0.9), 2800.0)
		for hs9 in 60:
			var ha9 := SFX.h(hs9 * 1.9) * TAU + tnow * (0.5 + 0.5 * SFX.h(hs9 * 3.3))
			var hd9 := hr9 + 20.0 + SFX.h(hs9 * 6.1) * 520.0
			o.draw_arc(hc9, hd9, ha9, ha9 + 0.1 + 26.0 / hd9, 4, Color(1.0, 1.0, 1.0, 0.8), 2.5)
		for hs8 in 16:                                        # (… and a few flakes inside the eye, turning slowly)
			var ha8 := SFX.h(hs8 * 2.7) * TAU + tnow * 0.3
			var hd8 := hr9 * (0.3 + 0.65 * SFX.h(hs8 * 4.9))
			o.draw_arc(hc9, hd8, ha8, ha8 + 14.0 / hd8, 3, Color(1.0, 1.0, 1.0, 0.45), 2.0)
	if blizzard_t > 0.0:                                    # a blizzard: all but a round about you is white; snow drives across
		var bz := minf(1.0, blizzard_t / 1.2) * minf(1.0, (SD.BLIZZARD_TIME - blizzard_t) / 1.0)
		var bc9: Vector2 = view.pilot.pos * S + Vector2(0.0, -36.0)
		var br9: float = SD.BLIZZARD_R * S
		for bq9 in 4:
			o.draw_arc(bc9, br9 + bq9 * 26.0 + 13.0, 0.0, TAU, 64, Color(0.88, 0.93, 1.0, bz * (0.2 + 0.2 * bq9)), 28.0)
		o.draw_arc(bc9, br9 + 104.0 + 1100.0, 0.0, TAU, 64, Color(0.88, 0.93, 1.0, 0.95 * bz), 2200.0)
		for sq9 in 70:
			var sx9 := fposmod(SFX.h(sq9 * 1.7) * 2400.0 + tnow * (700.0 + 500.0 * SFX.h(sq9 * 3.1)), 2400.0) - 1200.0
			var sy9 := (SFX.h(sq9 * 5.3) - 0.5) * 1400.0 + sx9 * 0.18
			o.draw_line(bc9 + Vector2(sx9, sy9), bc9 + Vector2(sx9 + 34.0, sy9 + 6.0), Color(1.0, 1.0, 1.0, 0.75 * bz), 2.0)
