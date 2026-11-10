# Sternenfront

2D space game for **Godot 4.3+** (GDScript, no external assets – pixel art and shaders are generated at runtime).
Mouse control like Dark Orbit, a galaxy of star systems linked by hyperspace routes like EVE,
modular ships and EVE-style active combat (lock targets, switch modules on), with a cyberpunk corporate flavour.

The game is developed in English; only the star system names stay German.

## Running
Open Godot 4.3 (or newer) → *Import* → select `project.godot` → F5.
The game starts in the main menu (Continue, New Game, Load Game, Settings, Quit).
Automated functional test: `godot --path . -- --smoketest` (skips the menu; ends with a save → load round trip).
Add `--headless` to run it without a window; run it windowed with `-- --smoketest --shots` to also save
screenshots of new UI to `Claude outputs/`.

## Combat & tools (manual control)
- Lock up to 3 targets (ships, asteroids, wrecks, anomalies). Lock time depends on your sensor
  resolution and the target's signature; the lock breaks beyond 125 % of sensor range.
- The module bar shows only **activatable** modules: weapons and tools (mining laser, analyser,
  salvager, repair beam). Passive modules (hull, engine, scanner sweep, cargo racks …) are hidden.
- Modules act on the **active** target: weapons need a hostile ship, mining lasers an asteroid,
  analysers an anomaly, salvagers a wreck; repair beams fix a locked friendly ship or yourself.
- Tile border: grey = off, green = working, amber = out of range, purple = not enough energy.
- Warping or docking clears all locks. NPC pirates still fight automatically.

## Scanners, mining gear and active equipment (phase 0.5 package 7)
- **Long-Range Survey Scanner** (S/M/L: 300k / 750k / 1.6M km): aimed at the place in the selection
  panel (asteroid field, planet, anomaly, gate, station, colossus) – no lock needed. After 5–8 s a
  survey window lists asteroids by ore and amount, ships by class and faction, wrecks and colossi. The
  result also appears in the place's selection panel and goes out of date after 5 minutes.
  **Survey Range Amplifier** (optional, ×1.5 / ×2.2) extends the range.
- **Prospector Scanner** (on a locked asteroid): reveals ores and deposit as an estimate (±20 %, the
  M version ±7 %). Unscanned asteroids only show size and class – "composition unknown".
- **Warrant Scanner** (on a locked NPC): shows whether a bounty is on its head, how much, and where it
  is paid. Not every pirate is wanted (75 %); the reward grows with hull value and lawlessness.
- **Ice Harvester** (S/M): full rate on icy asteroids, useless on rock. Mining lasers still work on ice
  at 25 %. **Strip Miner** (L tool): very high mining rate, cruisers only.
- **Ore Hold** (optional S/M/L): extra space for ore and ice only; ore fills it first, then the hold.
- **Mining Upgrades** (optional, metallic / silicate / cryo, +30 % / +60 %) for one asteroid class.
- **Active equipment** in the module bar: **Afterburner** (speed ×1.4–1.6), **Shield Booster** and
  **Armor Repairer** – they drain capacitor every second while switched on and turn off when it is empty.

## Bounty bonds (phase 0.5 package 9)
Bounties are no longer paid at once. Destroying a wanted pirate issues a **bond** from the
**Sable Writ Exchange [SWX]** ("Every head has a price."). A bond can only be redeemed at the
**Bond Office** tile of a station in the system where it was issued (for systems without a station:
the nearest system that has one). Bonds belong to the pilot, survive the loss of a ship and never
expire. The bond wallet is in the ship menu (Transactions → Bonds); docking in a system with
redeemable bonds reminds you. BlackLedger bounty contracts still pay their own reward on top.
Commands: `{"type": "bond_redeem", "id": ""}` (all) or with a bond id. From package 13 on bonds are
issued by a power and paid at any of its stations (see *Bounties & law*).

## Pirate archetypes (phase 0.5 package 14)
Pirates stay loners, but each one has an AI role with its own behaviour and loadout
(`data/pirate_archetypes.gd`, presets with an `"archetype"` key in `data/presets.gd`). Light loadouts
appear everywhere, medium ones below security 0.6, heavy (Warden) ones below 0.3.
- **Raider** – fast (pulse lasers, afterburner): presses the attack for ~7 s, breaks off for ~4.5 s, comes back.
- **Brawler** – armour and autocannons: closes in to knife-fight range.
- **Sniper** – rockets / railgun: holds its maximum weapon range and backs off when you close in.
- **Ambusher** – waits on the far side of a colossus (radar shadow) or among the rocks and only strikes
  prey within 45 % of its sensor range; its volleys in the first 5 s hit 60 % harder.
- **Leech** – **ion weapons** (new: *Ion Disruptor* S, *Ion Siphon* M): +60 % damage on shields, drain the
  target's capacitor and feed half of it to the shooter. Pirate gear – not sold by the corporations,
  found on wrecks or bought in Pirate Havens.
- **Coward** – flees below 55 % armour + structure, calls every idle pirate within 45,000 km to attack its
  attacker, and warps away once clear.
All pirates now also answer whoever shoots at them. The **Warrant Scanner** reveals the archetype (also
shown in the selection panel afterwards); paint follows the pirate faction. Debug menu → World → Spawn
lists every archetype loadout.

## Studio intro
The game starts with the **dlirius games** intro (`scenes/intro.tscn`, `scripts/ui/studio_intro.gd`): the
animated d from `dlirius/games.gif` (converted to `assets/intro/dlirius_sheet.png`, white → black
background, the black outline → silver) with a soft zap (`laser.wav`) for each of the 14 colour bars,
then "dlirius games" in silver with two brackets above it as wide as the lettering. A mouse click slams
the brackets together around the d (`hammer.wav`); a second click or any key skips to the main menu.
The sounds are synthesised. With `--smoketest` (or headless) the intro is skipped.

## Kanayama Heavy Industries ships (phase 0.5 package 25a)
- Every hull belongs to a manufacturer (`maker` in data/hulls.gd); shipyards stock hulls by the
  manufacturer's rules (`yards` / `small_yards` in data/manufacturers.gd). Earthworks: every shipyard.
  KHI: industrial complexes and shipyard complexes; mining colonies have a small yard with the Mogura,
  the Anaguma and the Earthworks Drillhead. The shipyard shows crest and motto of the maker.
- **Mogura** (S), **Anaguma** (M), **Iwakudaki** (L): yellow, bulky mining ships. Built in: ore hold
  (60 / 300 / 900 m³), **refinery** (0.15 / 0.4 / 1.0 ore per second at 70 / 80 / 90 % yield, 8 / 16 / 32 MW
  while on – switch it off in the module bar to keep raw ore; while working it sprays thin plumes of smoke
  sideways out of the exhaust pipes on its flanks) and a
  prospector. +10 % mining, but −25 % turn rate and +40 % warp alignment time.
- Built-in modules have a gold frame in the module bar, their own row in the ship menu and a power
  priority; they cannot be removed.

## Crew and The Bar (phase 0.5 package 31)
- Ships from **M** up have **crew posts** (2–10); some are **required** – without them the ship cannot undock.
  A newly bought ship comes with rookies (quality F) on the required posts.
- Every crew member is random: **name**, **portrait**, **profession** (Co-Pilot, Gunner, Engineer, Science Officer,
  Mining Foreman, Quartermaster, Drone Operator), **quality F–A** and **one rolled bonus** of the profession inside the
  frame of the quality (e.g. a Gunner: +7 % kinetic damage). Very rarely a **perk** (Second Profession, Lucky, Quick
  Learner, Loyal, Old Hand, Medic, Thrifty, Night Owl).
- They learn slowly from the right work (Co-Pilots from warps and jumps, Gunners from kills …) and step up a quality
  with a rolled improvement on top. The crew of the active ship takes a small **share** of sales, bounties and
  contract rewards (F 0.02 % … A 0.25 % each).
- **Ship menu → Modules → CREW:** the posts, the crew quarters of the station, assign and dismiss. **The Bar** on the
  concourse (Driftwood Taverns): 4–8 people looking for work, new faces every 20 minutes.
- Skill tree: a hull tile brings the professions its ships need; the Science Officer has a tile of its own.

## Economies and prosperity (phase 0.5 package 42a)

- `scripts/core/economy.gd` (`Economy`): per system a main and an optional secondary economy (`Economy.of(sid)`)
  from weighted factors – stations per tier (`STATION_WEIGHTS`, strongest), planets (`PLANET_WEIGHTS`), moons, fields,
  belts; the hand-made systems get a fixed lean (`SPECIAL`). A secondary economy needs 35 % of the main one's points.
- Nine economies: agri, mining, industry, refinery, chemistry, hightech, research, military, tourism.
- Prosperity 0–100 in five levels (`Economy.level`): starting value from population, stations, security, capitals
  and makers' homes (`base_prosperity`, cached); changes live in `GameState.prosperity` (saved).
- New planet type `metal` (Metal World): shader parameter `metal` – ore veins and glints.
- Galaxy map: economy filter, main-economy mark, prosperity pips, economy and prosperity in the system info.

## The content of the Rim (phase 0.5 package 40c)

- `Universe._rim_riches` (×`RIM_AMOUNT` / `FAR_AMOUNT`, purity, deep deposits, `L["rich"]`), `_rim_giant`, one or two
  more fields in `_generate_layout`.
- `_wreck_sites` → `L["sites"]`: `_battlefield` (hulks: `hulk`, `side`, `loot`, `mod_chance`) and `_derelict`
  (`relic` + fragments) by `BATTLE_SHARE` / `RELIC_SHARE`; warp targets of kind `site`. The view spawns a `site`
  celestial (scrap, drawn once) and a `wreck` per hulk with endless life; `complete_salvage` sets `salvaged`, kept in
  the save (`"salvaged"` per layout). `PixelArt.hulk_texture` / `relic_texture`. Good `old_tech`.
- `_mark_veil` (`VEIL_PER_CONSTELLATION` outermost of each Far Reaches constellation, `is_veil`), `_veil_rifts`
  (revealed anomalies with `veil`); `SpaceBackground.veil` (shader `veil`, `veil_dir`); `SystemView._veil_tick`
  (`Fx.ghost`, `VEIL_ECHOES`); galaxy map `_draw_veil_glow`.

## On foot (phase 0.5 Teil 7, package 49)

Slanted, cosy top-down view since 0.7.49.2.
- `scripts/ground/ground_map.gd` – `GroundMap`: tiles (`TILE` 16 art px, drawn ×`SCALE` 3), `T` (VOID, FLOOR, CAP
  = wall top, FACE = a wall's front face, GLASS = window front, DOOR, BLOCK), `floor_kind`, `free_at` (feet),
  `zones` (service / exit / crew / label, with `sign`, `vertical`), `objects` (standing furniture), `decals`,
  `face_deco`, `people`, `wander`, `spawn`, `pal`, `hull_top` (the station's structure from this row down, drawn by
  the view from `hull_texture()`; wall tops only where they border a room), `round_corners` (the window front's
  rounded corners), `window_rect` (the view draws space – nebula, star, planet – only there, clipped; black elsewhere), `lights`
  (light pools, additive, some flicker), `holos` (holographic adverts, `DeckGen.ADS`); neon strips along wall feet.
  The view draws shop signs and the BAR sign as neon (`_neon_text`, `_neon_rect`, `_flick`).
- 0.7.49.6: zones of kind `seat` (`seat` pos, `dir`) and `jukebox`; `GroundMap.lifts` (the view animates the doors:
  `_doors`, `_draw_lifts`, the ride back `_start_ride`/`_ride_step`; `use(true)` skips the ride for tests);
  `jukebox.gd` – `Jukebox.stream(i)` makes a looping lounge track (AudioStreamWAV, bus Music);
  `crew_talk.gd` – `CrewTalk`: a talk with one bar offer (questions, crew card, `crew_hire`), signals `closed`,
  `hired(index)`; the view's `open_talk(zone)`, `_on_hired` (the others' indexes move up, the hired one walks to the lift
  – `Walker.leave_to`).
- 0.7.49.7: `DeckGen.THEMES` (per station type: `bar` style lounge / mess / canteen / cafe / dive / garden / beach,
  `floor`, `corner`, `cor_floor`, `deco`, `props`, `seat`), `_bar_*` builders, `_seat()` (seat object + maybe a
  guest), `_seat_pos()`, `SEATS`; floor kinds 5–10 (plates, tiles, sand, grating, dark planks, water); many new
  `ObjArt` kinds; `GroundMap.path(a, b)` (AStarGrid2D) used by `Walker._follow`; `ChibiArt` frame 3 = sitting
  (`Walker.SIT_LIFT`); `dialogue_view.gd` – `DialogueView` (`open`, `say(text, [[label, Callable]])`, `choose(i)`,
  `close`): the conversation screen; the view's `talk` (DialogueView) and `talk_menu` (CrewTalk, via `talk_info`).
- 0.7.49.8: levels – `GroundView.go_level("hangar" | "commercial", arrive)`, `level`; `DeckGen.build_hangar(station,
  ship_len, ship_beam)` (walkway, glass front over the bay – `GroundMap.under_glass`, `ship_at`; stairs zone `exit` /
  `ship`, lifts zone `lift`); zones of kind `lift` open the lift panel (`_open_lift_menu`, `_choose_level`), the ride
  ends on the other level; the exit (stairs) walks there and fades. Waystations: `DeckGen._dome_room` (a semicircle
  of glass – two round corners of radius `BAR_Y0` meeting – and a diner), the others `_bar_room`; `_place_crew`.
  Floor kinds 11 (hangar), 12 (diner checkers); decals `pad`, `stairs`; face deco `bay_door`.
- 0.7.49.9: `DeckGen.HANGAR_SERVICES` (hangar, shipyard) are shops on the hangar walkway (`build_hangar(…, available)`,
  `_shop(…, cap_y)` at any row) and left out of the commercial level; `GroundMap.bay_rect` (the view lays a haze
  gradient over the bay), decal `bay` (tiny crates and lights far below); no people in the bay.
- 0.7.49.10: `bay_life.gd` – `BayLife` (Node2D in art px over the bay): loaders, repair drones with sparks, the fuel
  truck and its hose; set up by the view from `bay_rect`, `ship_at` and the ship's size.
- 0.7.49.11: `ChibiArt` now draws the tall "C3" figures (18×40, `CHAR_SCALE` 2 screen px per pixel – the walker
  scales by it, not by `GroundMap.SCALE`), black outline (`_outline`) and neon rim light (`_rim`, `RIM_L`/`RIM_R`);
  frames 0 stand, 1–2 walk, 3 sit (`HIP_SIT`).
- 0.7.49.12: seats in `ObjArt` measured from the footprint's bottom (seat top ~7 px = the figures' hips); `bench_back`
  (the front backrest of a bench whose sitters face away, added by `DeckGen._seat`); objects may carry `sort_dy`
  (tiles) – sorted that much lower but drawn in the same place (in front of a sitter).
- 0.7.49.13: the bartender – `GroundView.open_bartender()` (sitting at a stool or E at the bar zone), `DRINKS`,
  `BAR_TALK`, `_order` (credits, `Walker.drink_t` animation, `GameState.pilot["alcohol"]`/`["alcohol_t"]` for a later
  debuff); `StationUI.on_foot` (set by `main._on_deck_use`: only the service, *Back to the deck*, no concourse; the
  station hotkey is ignored while `main.ground` exists); `DeckGen.hangar_no(station, uid)`, `GroundView._hangar_uid` /
  `_hangar_stale()` / `on_service_closed()` (after a ship swap: the toast, the lift to the new hangar).
- 0.7.49.14: `GroundView._camera(delta)` eases (`_cam_c`); seated on the hangar bench it looks at `map.ship_at`; the
  sky sprites (`_star_spr`, `_planet_spr`) are placed in the visible part of `_window` each frame.

## Landing (phase 0.5 Teil 7, package 50)

- `Universe.landable(body)`, `has_atmosphere(body)`, `descents(system)` (a beacon over every solid planet and moon,
  warp target kind `descent`), `find_body`, `landing_sites(system, body)` (`SITE_KINDS`: city, outpost, mine, ruins,
  crash, research – with lon/lat on the visible face).
- `SystemView`: celestial kind `descent` (`Celestial._draw_descent`), `descents` (body id → beacon), the order
  `descend` (Ship: fly to the beacon, then `view.start_descent`), `start_descent` / `start_ascent` /
  `_update_descent` (speed-up, sinking, `DescentFx` – flame and heat), signals `descended(body_id)`, `ascended`.
  Down there the fit is "docked" at `land:<body id>`.
- `scripts/ui/planet_map.gd` – `PlanetMap` (CanvasLayer 11): the planet, its places, the list; signals `land(site)`,
  `back`. `main`: `_on_descended`, `land_at(body, site)`, `take_off()`.
- `DeckGen.build_landing(body, site, ship_len, ship_beam)` / `palette_for_body`: the landing field (floor kinds 13
  ground, 14 pad concrete, 15 gravel; decals `pad_marks`, `ramp`; the ground all round as the "hull"); the view's
  level `landing` (`GroundView.setup_landing`), the ramp = zone `exit`, the place itself = zone `soon` for now.
- 0.7.50.3: `main.fade(col, secs)` (a fade layer over everything); `SystemView.descent_ending(atmo)` (the flash),
  zoom during descent/ascent (`z0`); `PlanetMap` intro (planet turns in, places light up, list fades in);
  `scripts/ui/flight_scene.gd` – `FlightScene` (`ground_texture(body)`, `cloud_texture`, the place drawn on its
  patch of land), `main.fly_down_to(body, site)` → `land_at(…, touchdown)`; `GroundView` touchdown (`_touchdown_step`,
  `_dust_burst`, shake) and lift-off (in the ramp ride, `LIFT_TIME`).
- 0.7.50.4: `FlightScene.lander` (site kind != city → the landing drone, `lander_texture()`, launched at `DRONE_AT`),
  `_draw_city_lights` (a city only as its lights; the ship shrinks into them); `GroundView.setup_landing(…, by_lander)`.
- 0.7.50.5 (package 50b): a city is a station on the ground – `Universe.city_station(sys, body, site)` (cached, kind by
  `CITY_TYPES`), id = the landed state `land:<body>|<site>`, so `Universe.find_station` / `Commands.docked_station()`
  find it and every service works; `scripts/ui/city_hatch.gd` – `CityHatch` (down/up), `main._city_hatch`,
  `enter_city`, `leave_city`, `_open_ground_at(st)`; `GroundView` city levels `hangar` / `street` / `tower`
  (`is_city()`, `tower_floor()`), `DeckGen.build(…, mode)` with `_street_north` (face deco `storefront`),
  `scripts/ground/city_skyline.gd` – `CitySkyline` behind the tower bar's glass.
- 0.7.50.6: `scripts/ground/city_style.gd` – `CityStyle` (`STYLES` independent/assembly/covenant/directorate, `key_for`,
  `daylight(site)` from the planet map's light, `tone`, `sky`); city dict `day`; `scripts/ground/city_canyon.gd` –
  `CityCanyon` above the street (`map.window_rect` open to the sky); `FlightScene.ground_data` (picture + sea mask),
  the place locked to the ground (`_place_at`, `_dist`, `_nearest_land`), `_draw_city_day`; `CityHatch` towers
  (`_draw_tower`).
- 0.7.50.7: `FlightScene.CITY_FORMS` / `_build_city` (ground plan points, kinds `CP`), `CityStyle.light_vec(body)` /
  `day_length` / `minutes_to_turn` (the sun goes round each world over `GameState.play_time`; planet shader uniform
  `light_z`), `CityStyle.DECK` (deck palette, bar theme, hangar flags; `DeckGen.palette_for` for cities), face deco
  `flag`.
- 0.7.50.8: `GroundView._update_city_day` / `_apply_day` (twice a second: `CitySkyline.set_day(d, rising)`,
  `CityCanyon.set_day`, the street tint, the lights in `_city_lights`); `CityStyle.rising`, `dusk`, `sunset_color`,
  `star_color`; `CityStyle.sky(body, day, sunset)`; the skyline's sun (`_draw_sun`, its own parallax).
- 0.7.50.9: `CityStyle.GUARDS` (uniform, name, lines), `GroundView._add_guards` (posted by lifts and stairs, patrols;
  count by system security), `Walker.guard` / `patrol` (`_patrol`, the slung rifle), zone kind `guard`.
- 0.7.50.10: settlements – `scripts/ground/settle_gen.gd` (`SettleGen.build`, `SPECIAL` by economy, `BOUNDS` by world,
  `GroundMap.pads`), `scripts/ground/pad_traffic.gd` (`PadTraffic`: the other drones on the free pads),
  `Universe.city_station` also for outposts, mines and camps (`settlement: true`, `SETTLED_KINDS`), `main.land_at` →
  `GroundView.setup_settlement` (level `settlement`, `is_town()`), `main._services_for`; new objects `tree`, `rock`,
  `lava_rock`, `dune`, `crystal`, `house`, `tower_rig`, `silo`, `greenhouse`, `dish`.
- 0.7.50.11: `scripts/ground/build_art.gd` – `BuildArt.paint` (object kind `building`, `arch` prefab/container/quonset/
  dome/pitched/adobe/stone/module, `storeys`, `seed`, own `rise`); `SettleGen._arch` / `_building` / `_nature`;
  objects `shrub`, `stall`, `rover`, `signpost`, `cable_pole`, trees with `species` (broad/conifer/palm) and `vines`,
  rock groups; face deco `awning`.
- 0.7.50.12: settlement map 94 wide (`SettleGen.TW` town, the rest the economy area), `SettleGen._econ` (by
  `economy(site, sys)`, `site.economy` overrides; `GROWS`), `GroundMap.econ` {kind, rect, pit/step/heap, fields,
  stacks, crane, road, flare, launch, loop, pens}; `scripts/ground/econ_life.gd` – `EconLife` (vehicles, crane,
  flame, rocket, boats, smoke); decals `pit`, `field`, `canal`, `yard`, `pen`, `piperun`, `cable`, `boardwalk`;
  objects `fence`, `smokestack`, `flare`, `lookout`, `heap`, `target`, `tank_vehicle`.
- 0.7.50.13: scale ~15 art px a metre (a person ~27 px): `BuildArt.STOREY` / `DOOR_W` / `DOOR_H` / `CONT_H`;
  `scripts/ground/vehicle_art.gd` – `VehicleArt.texture(kind, col)` (haul, haul_full, excavator, combine, tanker, apc,
  boat); the mine as decal `pit_edge` with `econ.bands`; objects take an own `rise` (lamp posts, signposts, poles,
  stalls, rovers, trees, dishes, silos, chimneys to their height).
- 0.7.50.14: `VehicleArt` sci-fi (`GLOW`, `HEAT`, `HOVER` – EconLife bobs those and lights the ground), the
  excavator's arm and cutter claw in `EconLife._excavator`; light accents in `ObjArt` (chimneys, tanks, dishes, rig,
  fence, armoured vehicles, rover) and `BuildArt.paint` (eaves strip, door panel).
- 0.7.50.15: `scripts/ground/lander_art.gd` – `LanderArt.texture()` (the drone, 42×30, `FANS`, `C`) and
  `draw_ramp(ci, centre, sc, open, t, a)` / `ramp_top()` / `ramp_foot()`; `GroundView._hatch` / `_hatch_node` /
  `_drone_ramp_zone()` (spawn and way in along the ramp), `_open_takeoff_menu` / `_choose_takeoff` (zone `dest`
  orbit/map, `animate`); `main.take_off(dest)`, `leave_city(dest)`, `drone_up(body, site, dest)` →
  `FlightScene.open_up` (`_update_up`, `CATCH_AT`, the tractor beam); `scripts/ground/pad_lights.gd` – `PadLights`
  (edge lights and status per pad, reads `PadTraffic`); `GroundMap.pad_rects`, decal `landing_pad` (`n`),
  objects `fuel_point`, `cargo_loader`; `SettleGen.PAD` 10×7, `FIELD`, map 98 wide.
- 0.7.50.16: `DescentFx` drawn new (`_draw_flame` at the ship's scale `_ss`, `_draw_heat` at `_hs`: bow shock bands
  along the shell's normal, wake, streaks, `_sparks`; additive `CanvasItemMaterial`); `FlightScene` sizes by the
  hull's `length` (`DRONE_M`, `DRONE_MIN_PX`, `_ship_m`, `_home_y`, `_ship_len_px`, `_ship_flame`).
- 0.7.50.17: `FlightScene._build_town` / `_draw_town` (points `_town_pts` of kind `TP`, laid out in town units
  `TOWN`, `_tp` / `_road` only on land, `_land_dir`; `PADS_AT`; economy from `SettleGen.economy`), `town_day`,
  `_ground.modulate` darkens at night; no flame on the way down (`SystemView._update_descent`, `_draw_fx`).
- `GroundMap.texture()` renders floors and walls once.
- `obj_art.gd` – `ObjArt.make(o, pal)`: furniture sprites (tables, chairs, stools, counters, sofa, jukebox, plants …).
- `chibi_art.gd` – `ChibiArt.frame(look, dir, f)`: small 16×24 figures from the portrait look, 4 directions × 3 frames.
- `deck_gen.gd` – `DeckGen.build(station, available, crew)`: lift lobby (west) → corridor → shops below (`_shop`,
  dock office terminals) and the bar above behind a railing (window front, counter, tables, crew from the bar
  offers), palette per station type (`PALETTES`).
- `walker.gd` – `Walker`: `step(dir, delta, mult)` sliding along walls, facing, NPC wandering, `marker` ("!").
- `ground_view.gd` – `GroundView` (CanvasLayer 12): space beyond the glass (background shader, the system's star and
  the station's planet), y-sorted furniture and people, signs, prompt; signal `used(zone)` (service / crew / exit).
- `main.gd`: `open_deck()` (from `StationUI.walk_requested`), `close_deck()`, `_on_deck_use`, `_check_deck` (closes the
  deck when the ship is no longer docked there). Keys: `walk_*`, `interact` in the "On foot" group – `Keybinds._context`.

## Thrust burst (0.6.75.2)

- `Ship.boost()` / `boost_error()` / `boost_mult()`: `BOOST_TIME`, `BOOST_MULT`, `BOOST_ACCEL`, `BOOST_COOLDOWN`,
  `BOOST_CAP`; `boost_glow` draws `_boost_flame` behind every drive. NPCs: `_npc_boost` (`NPC_BOOST_CHANCE`,
  `NPC_BOOST_COOLDOWN`). Key action `boost` (default Shift – `Keybinds.event_to_desc` accepts Shift now), handled in
  `main.gd` (not exact, so the modifier itself counts). `SystemView.shake`. Sound `boost`.

## Speed curve (0.6.75.1)

- `ShipFitting._compute`: speed = `SPEED_BASE` × (thrust ÷ mass ÷ `SPEED_REF_TW`) ^ `SPEED_EXP` × speed_mult × power
  ratio (300 km/s, 0.2883 kN/t, 0.5). Plasma Drive anchor thrust 2,500 kN at size 5.

## Package 40e (0.6.40.10)

- Debug: `Commands._c_debug_p40` (`to`: rim / far / veil / fortress / battlefield / derelict / radiation / ion_storm /
  minefield; `_place_after_load`), `_c_debug_fortress`, `_c_debug_misjump` (`GameState.debug_misjump`).
- Performance: `SystemView._radar_cands` (gathered every 0.25 s or on a big move / zoom), `MIN_ROCK_PX` in
  `_cull_asteroids`; `PixelArt.haze_texture` for radiation and ion storms; old mines check every 0.2 s.

## Hazard wards (0.6.40.9)

- Families `o_rad_ward` / `o_ion_ward` (anchors `o_rad_ward_s` / `o_ion_ward_s`, `craft_only` – never in `_make_shop`),
  `rad_ward` / `ion_ward` set by `ModuleData.WARD_BY_QUALITY`; ship stats keep the best one. Recipes in
  `Industry.FAMILY_MIX`. Skill tree tiles `rad_insulation` / `hull_lining` with `unlocks.blueprints`
  (`TreeData.tile_of_blueprint`, checked in `GameState.fab_tree_error`); metrics `rad_time`, `ion_hits`.

## The dangers of the Rim (phase 0.5 package 40d)

- `Universe._hazards` → `L["hazards"]` (`radiation` with `strength` / `field`, `ion_storm` with `vel`, `minefield` with
  `mines`) by `RAD_SHARE` / `ION_SHARE` / `MINE_SHARE` / `MINES_AT_BATTLE`; warp targets of kind `hazard`.
- `_plan_fortresses` (`FORTRESS_COUNT` in the Rim, `fortress`, `fortress_gov`), `_add_fortress` (a haven with
  `art: pirate_fortress`, `fortress`, `bounty`); `StationArt._fortress`.
- `SystemView._spawn_hazards` (hazard celestials, old mines `Mine.setup_old` – faction `derelict`, the garrison),
  `_hazard_tick`, `hazard_banner` (HUD), `_garrison_lost` → `GameState.fortress_broken` / `fortress_down`
  (`FORTRESS_REBUILD`), `FORTRESS_RANGE`. `Celestial._draw_hazard`.

## Territories by the lore (0.6.40.7)

- `_assign_territory`: the capital with the fewest routes (≤ `DIRECTORATE_SYSTEMS` − 1, else another candidate) goes to
  the Directorate, which takes only its ring and does not grow; pirates grow to `PIRATE_SYSTEMS` (3); the Assembly and
  the Covenant grow without limit, leftovers go to an Assembly / Covenant neighbour. Contested: up to
  `CONTESTED_SYSTEMS` on the Assembly–Covenant front (never next to the Directorate or a capital ring); every other
  unowned core system is independent.

## No route classes (0.6.40.6)

- `Universe._link` sets every route to 1; `GameState.can_jump` only needs a jump drive (and fuel, and entry permits);
  `jump_fuel` is the drive's own. `drive_class` is the drive's grade Mk I–III: `DRIVE_TIME` in `jump_duration(from, f)`,
  `DRIVE_MISJUMP` on the misjump roll; `drive_grade(f)`.
- Galaxy map: `veil_rect` (a ColorRect under the map's drawing, `shaders/veil_clouds.gdshader`, `_update_veil`).

## Gates (phase 0.5 package 40b)

- `Universe.gate_style(sid)`: a power's own style, `pirate` for pirate systems, `old` for the empty Rim, else
  `independent`; stored as `"style"` in each gate of the layout. `old_gate(sid)` – old or pirate.
- `PixelArt.gate_texture_styled(cls, style)` (`GATE_STYLES`, 81 × 81); the old field flickers in `Celestial`, and
  `gate_flash` makes a gate flare when a ship comes through.
- `GameState.jump_duration(from)` – ×`OLD_GATE_TIME` through an old gate; `begin_jump` rolls a misjump
  (`MISJUMP_OLD` / `MISJUMP_PIRATE`), `_misjump` flings the ship to a random spot and deals `MISJUMP_DAMAGE`
  (structure never below 25 %). `pending_arrival` → `SystemView.play_arrival` (gate exit or misjump, after
  `ARRIVAL_DELAY`); `Fx.misjump`.

## The cluster (phase 0.5 package 40a)

- `Universe._place_systems`: `CORE_SYSTEMS` in an ellipse (`CORE_R`), `BELT_CONSTELLATIONS` constellations of
  `BELT_SIZE` systems on a ring (`BELT_RING`); `systems[i]["belt"]`, `["constellation"]`. `MAP_SIZE` 3600 × 2400.
- `_build_routes`: spanning tree + extras in the core, a tree (+ a loop) per constellation, one route to each
  neighbouring constellation (20 % none), one or two into the core.
- `_assign_territory` works on the core only (capitals inside it; a capital's neighbours forced to its power);
  `_plan_settlements` – free settlements (independent) in the Rim; `_name_systems` – `SYSTEM_NAMES` for inhabited
  systems, `CATALOG_PREFIX` / `EXPLORERS` + `EXPLORER_PLACES` for the rest. `GALAXY_VERSION` 9.
- **The Far Reaches** (0.6.40.3): `OUTER_CONSTELLATIONS` constellations of `OUTER_SIZE` systems on a second ring
  (`OUTER_RING`), `systems[i]["outer"]`, `is_outer`; belt systems too, but routes only into the Rim, no settlements,
  no research posts, security 0.0–0.15. ~240 systems in all, `GALAXY_VERSION` 10.
- Galaxy map: `view_zoom` / `view_center`, `zoom_at`, `_to_map`; drag to pan. Below `OVERVIEW_ZOOM` (`is_overview`):
  no system names, territories always on, `_draw_faction_names` (at `faction_centres()`, stacked so they never
  overlap) and `_draw_ring_names` / `_arc_text` – the ring names along the ellipses.

## Tourist traffic (phase 0.5 package 43c)

- `Traffic.tourists`: cruise liners (`CRUISE_PRESETS`, through a gate) and sightseeing shuttles (out of the resort)
  fly to a sight (`Tourism.sights`), linger `VIEW_TIME`, then dock at the resort – or, without one, leave through a
  gate. Counts from `system_profile` (`cruise`, `tour_shuttles`).

## Tourist flights and round trips (phase 0.5 package 43b)

- `Missions.generate_passenger`: from Average prosperity a share (`TOUR_SHARE`) are round trips (`generate_tour`),
  others tourist flights to a resort (`TOURIST_SHARE` + 8 % per level, pay ×`TOURIST_PAY`, `m["tourist"]`).
- A round trip is a passenger contract back to the giving station with `m["tour"]` = {system, sight, body, t, done};
  `GameState._update_tours` counts the time near the sight (`Missions.sight_place` – range by body) out of warp;
  `can_turn_in` waits for `done`. Prosperity: +0.6 per tourist group delivered, +0.4 per sight seen.

## Resorts and sights (phase 0.5 package 43a)

- Station type `resort` (`data/commodities.gd`): sells souvenirs, holo films, artworks; wants luxuries, fine food,
  wine, perfume, gold; tourism weight 5 per tier (`Economy.STATION_WEIGHTS`).
- `Universe._add_resort` (own RNG, after the waystation): `resort_appeal` – beautiful worlds, a ringed giant, a
  wondrous star, security, capital – against `RESORT_SCORE`; always in `RESORT_SPECIALS`. Variant (`station["resort"]`,
  art `resort_ring` / `resort_star` / `resort_fun`) from what is there.
- `StationArt._resort_habitat` (tier 3) / `_resort_biosphere`: `landscape()` paints meadows, forests, lakes and towns
  from value noise (materials LAND, FOREST, WATER, TOWN), `roof_ribs()` the glass roof (ROOF); `night_dir` puts half
  of it in night in `_render` (towns lit).
- `scripts/core/tourism.gd` (`Tourism`): `sights(sid)` – worlds, rings, stars, landmarks (`SIGHT_ARTS`) with appeal;
  `resorts(sid)`.

## Prosperity at work (phase 0.5 package 42c)

- `Economy.change(sid, d, why)` moves prosperity (news on a new level); `Economy.drift(dt)` pulls it back to the base
  (`DRIFT` 2 h), called by GameState every 30 s. Sources: `on_trade` (wanted goods sold, made goods bought),
  contracts (`CONTRACT_GAIN`), kills (`KILL_GAIN`), raids (`RAID_LOSS`, in `StationStatus.knock_out`).
- `Universe.system_profile` = `system_profile_raw` + prosperity: traffic ×0.7…1.3, pirates +2…−2, an extra patrol
  from Wealthy. The starting prosperity uses the raw profile.
- Contract offers per station ±1 and pay ×0.85…1.15 by level (`GameState.offers_for`).
- Outfitters: `Economy.max_quality(station, sid)` and `Economy.prepare_station` (once, from `Universe.find_station`).
- Convoys pick goods by market role (`ConvoySim._make`); Warmup prepares all layouts and market roles behind the
  loading screen (`queue_layouts`).

## Markets with stocks (phase 0.5 package 42b)

- `scripts/core/market.gd` (`Market`): role of a good at a station (`produce` / `consume` / `neutral`) from the
  station type and the system's economies (`econ` / `wants` / `lux` / `basic` in `data/commodities.gd`; older goods
  via `OLD_GOODS_ECON` / `COMPONENT_ECON`; ores and gases by what the system has).
- Stock target from price, tier and prosperity; equilibrium: produce = target, consume = ¼ target, neutral = 0. A stock
  relaxes back with `RELAX` (30 min game time). Price = good's price × role level (`M0`) × stock factor (±50 %) ×
  prosperity; the station pays `SPREAD` of what it asks. Quotes price a whole trade along the stock.
- `GameState.market_stock` keeps traded stocks (saved); `Market.sync(station)` rewrites the old `station["market"]`
  table for code that reads it.
- Sixteen market categories (`MARKET_CATEGORIES`, `GOODS_CATEGORY`, `Market.category_of`); raw materials have their
  own consumers (`RAW_WANTS`). `Warenliste.md` lists every good.
- Munitions Depot (`scripts/core/munitions.gd`, `munitions_panel.gd`): `Munitions.AMMO` (munition → weapon family),
  `Munitions.offer(station)` from the system's economy; munitions are off the market (`Market.on_market`).

## Mining expansion (phase 0.5 package 41)

- **New ores:** copper, tungsten, gold, uraninite, spodumene, graphite, quartz, monazite, nitrogen ice, dry ice in the
  fields; osmium and palladium only as deep deposits in colossi (Deep Core Drill). Each refines to a material.
- **Purity:** asteroids are low / medium / high grade (×0.7 / ×1 / ×1.4 ore).
- **Gas:** a harvest band round every giant (dashed rings). A Gas Collector draws gas in while you move through it;
  deeper gives more but heat and pressure hurt armour and hull (past shields); storms double gas and heat. Each giant
  class has its own three gases (`Universe.GAS_YIELDS`).
- **Storage:** gases need twice the room in cargo racks, their own in Gas Tanks; radioactive goods belong in Shielded
  Cargo Racks – otherwise the red RADIATION banner and alarm (`HUD.radiation_banner`).
- **Components:** made from materials at any station with fabricators (Manufacturing → Components, `Industry.COMPONENTS`).
- **KHI Kujira:** L gas freighter, 1,600 m³ gas tanks, built-in scoop, 60 % heat resistance, raised bridge on the nose.
- The collector opens the ship's drone hatch and the gas streams in through it; ships without a hatch take it in on the underside.

## Landfall – the Assembly's capital (phase 0.5 package 39a)
- The capital of the Cluster Assembly is a hand-made system: **Landfall** (a yellow G star) with Pnyx, **Agora** (the
  brightest city lights in the Cluster), the ocean world Ekklesia and the deep-blue ice giant **Boulé** with its moons
  Ostrakon and Kleros. Where it lies is still up to the cluster generator.
- **Closed:** its gates (and Threshold wormholes) let in only pilots with the Assembly's **entry permit** – given from
  Friendly standing on, taken away only at Arch-enemy.
- **The Vote** over Agora: the great trade hub, ringed by four relay stations; drones fly between them, and every few
  minutes a blue beam shoots a ballot drone out to a gate.
- **The Senate** (a service in The Vote): every 30–60 minutes a bill comes to the vote; a passed bill holds for an hour
  in all of the Assembly's territory (prices, fuel and repairs, Concord ships, bounties, patrols) – always with an
  upside and a price. Vote Yes or No, give party donations (a little sway) – or bribe the tellers: it settles the vote
  unless it comes out (45 %: the money is gone, standing −30).
- **Concord Yards** at Ostrakon: the only yard that sells the **Concordia**; beside it the **Res Publica**, Concord
  Fleetworks' supercarrier the size of a station, still in her berth – a spinal railgun down her bow, drone hatches
  all over her hull.
- Contracts: **ballot couriers** from Assembly stations to The Vote (deadline, thieves on the way) and **drone field
  trials** at the Concord Yards (pirates destroyed by your drones in Assembly space).
- Debug → World: to Landfall, give/take the permit, ballot drone, new bill, vote now (with or without a bribe found out).

## The manufacturers' systems (phase 0.5 package 39d)
- **Altwerft** (Assembly): the Earthworks Second Yard. **Independent systems** (yellow on the map): **Erzhalde**
  (Kanayama Works – a building site), **Perlmutt** (Atelier Aurelle – ivory and gold round a biosphere dome),
  **Schwarzwacht** (Hadrian Foundry – black with red lights, weapon platforms being built by drones).
- Each yard sells all of its maker's ships and builds them in its berths.

## Durchbruch – the Directorate's capital (phase 0.5 package 39c)
- A blue-white star with a **Dyson sphere under construction** round it – frame rings of silver collector plates and
  scaffolding; its hub, the **Meridian Sphere**, is the only station built round a star. Closed like the other capitals.
- **Curie** half terraformed (green on one side, desert on the other) under three solar mirrors.
- **Axiom Yards** with ships testing their cloaks and small jump gates being built round the yard; the Threshold only
  there.
- **Research Exchange:** research data (from analysed anomalies) and exotic matter for credits and standing.
- Contracts: measurement probes, exotic matter, prototype test flights. Debug → World: Durchbruch & the Research Exchange.

## Heimkehr – the Covenant's capital (phase 0.5 package 39b)
- Under a red supergiant: Lauds (lava), the red gas giant Compline with the desert moon **Vesper** (pilgrim cities) and
  Nones, the ice world Matins. Closed like Landfall: the Covenant's entry permit from Friendly on.
- **Cathedral of Return** over Vesper – old church forms in modern sci-fi: stained glass, a golden rose window, spires.
- **Pilgrim Gate:** points home; its light never goes out, pilgrims pass through in an endless line.
- **Forge of Return** at Lauds – furnaces and a farm of red focus crystals; the only yard that sells the Cathedral.
  Beside it the **Lux Aeterna**, the Covenant's capital ship (crimson and gold, a habitat ring at her heart).
- **The Curia:** the Hierarch's edicts, tithes (and a petition for the next edict), indulgences, relics of Earth
  (found in anomalies) for a blessing – cheaper prices at Covenant stations.
- Contracts: pilgrim convoys, crystal transports, relic recoveries. Debug → World: Heimkehr & the Curia.

## Planets (phase 0.5 package 38)
- Eleven planet types – terran, ocean and jungle worlds, deserts, ice worlds, lava worlds, barren rock, gas giants,
  toxic giants, ice giants and dwarf planets – each with seas, clouds, caps, storms, lava or craters, and every planet
  a shade of its own. Inhabited worlds glow with city lights on their night side.
- The Collection lists every planet type and, in a category of their own, every moon type you have seen. Its tiles grow with the screen.

## Stars (phase 0.5 package 37)
- **Twelve star types:** blue O and B stars down to red M dwarfs, pink brown dwarfs, red supergiants, white dwarfs,
  **neutron stars** with glowing magnetic field lines and sweeping jets, and **black holes** with an accretion disc and
  a gravitational lens. All animated: boiling surfaces, sunspots, prominences and flares.
- **Coronal mass ejections:** a star erupts, a shockwave races through the system – sensors jammed, shields weakened.
- The **solar collector** draws by the star's brightness; a **black hole** pulls ships in – too close and there is no
  escape.

## Moons (phase 0.5 package 36)
- Planets have **moons** – gas giants two or three: rocky moons with craters, ice moons, volcanic moons and captured
  asteroids. They are far bigger than colossi and can be warped to; some stations orbit a moon, some moons have a small
  asteroid field, and pirates like to hide behind them.
- Each time you jump in, the planets and moons stand somewhere else on their orbits – stations and fields move along.

## System scale and belts (phase 0.5 package 35)
- Systems are **6 million km** across the radius – three times as big as before; warps are faster to match.
- Most systems have an **asteroid belt** and a **Kuiper belt** – scenery on the system map and in the background.
  The mineable **asteroid fields** lie in them: metal and stone in the asteroid belt, ice in the Kuiper belt; bigger,
  denser and in five styles (clustered, band, dense core, boulder field, gravel field).
- Busier systems; a short loading screen at the start makes the pictures ahead of time.

## Collection and wanted posters (phase 0.5 package 34)
- Notorious pirates have a face and Piloting & Gunnery that grow with their stars. Their **wanted posters** in every
  Bond Office: WANTED, the mugshot, the stars, DEAD OR ALIVE, the reward, ship and escort.
- **Pilot window → Pilot → Collection:** every crew perk that has served with you (the others show "???") and the
  posters of the notorious pirates you destroyed. Codex category **Pilot & Crew**.

## Wingmen (phase 0.5 package 33)
- **The Bar → Pilots for hire:** wingmen with their own ship (loadout shown), two skills and two traits (Daredevil,
  Cautious, Disciplined, Hothead, Sharpshooter, Loyal, Greedy). A contract runs 30, 60 or 120 minutes: paid up front,
  plus a share of your income (F 2 % … A 20 %). At most two – the second with Leadership 3; Leadership also makes them
  better and cheaper. Needs the skill tree tile **Wing Command**.
- They fly in formation, warp and jump with you, follow whom you follow and dock with you. Orders in the **WINGMEN**
  panel: aggressive, defensive, passive, **attack my target [N]**, passive **[Y]**. If a wingman dies, the ship is
  gone and the contract ends.
- **Citadel:** put a Hadrian S ship (Talon) on its launch platform in the hangar; a Co-Pilot with the perk Wingman
  flies it – launch and recall it in space. Destroyed, it can be recalled at a hangar for 10 %.

## Losing the ship (phase 0.5 package 31a)
- Every crew member rolls to survive – better quality, better odds (perks Lucky and Medic help). The survivors wait
  in an **escape pod** at the wreck (in the overview, on the radar) until its signal fades, 5–22 minutes by quality.
  Fly within 2,500 km and the pod comes aboard.
- You come back at the **last station you docked at**, in a Dragonfly. **Aegis Mutual** offers to rebuild the lost
  ship for **10 %** of its value (hull, modules, drones); otherwise you keep the Dragonfly. Crew perks: **Cargo
  Insurance** (the hold comes back too), **Insurance Agent** (5 % cheaper).

## Perks and the skill tree (phase 0.5 package 30)
- **Skill tree:** a real tree in the Pilot window – the Pilot Licence is the trunk, Shields grow above it, then the
  branches by activity: Defence, Combat, Mining, Industry, Flight, Exploration, Security, Trade and Drones; mastery
  (qualities, module sizes by pilot level) are the roots. Tiles open by doing – e.g. 1,000 ore mined opens the
  mining ships, 5,000 mined and 2,000 refined the KHI Anaguma. A tile glows when its achievements are met and is
  confirmed. Drag the tree with the mouse or walk it with W/A/S/D.
- **Everything can be bought, but used only with its tile:** a ship without it stays docked, a module without it
  stays offline, a core module without it cannot be fitted (fitted ones keep working). Station manufacturing and
  larger blueprints come through the Industry branch.
- **Perks:** 24 special abilities in six groups, one perk point per pilot level (e.g. Prospector's Eye: rare
  ore as a bonus while mining; Market Insider: the best price next door).

## Skills and the Pilot window (phase 0.5 package 29)
- Twelve skills (Piloting, Gunnery, Engineering, Science, Navigation, Mining, Trading, Leadership, Negotiation,
  Electronics, Athletics, Firearms) grow by doing and rise by themselves; every level gives +1 % on the skill's
  effect on your own ships (up to +10 %). All experience also feeds the **pilot level** – every level a perk point
  (perks come with package 30). See it all in the **Pilot window [U]**.
- The window opens on the **Pilot** tab: Info (portrait, name, level, attributes and all statistics – finances,
  flight & combat, work, contracts), **Standings** and **Codex**; then Skills, Perks and the Skill tree.

## The pilot (phase 0.5 package 28)
- A new game starts with creating the pilot: a pixel construction kit (body, skin, nine hair styles and colours,
  eyes, brows, beard, scars, freckles, outfit and colours, implants, tattoos, headgear) makes a 48 × 48 portrait
  and a small top-down figure; name, call sign and five attributes (Strength, Dexterity, Intelligence, Charisma,
  Reflexes – all from 3, 8 points to hand out, at most 8).
- The **Image Studio** (Visage Clinics) at stations changes the looks for a fee; the attributes stay. The concourse
  shows the portrait. Debug menu → Character.
- Menus work with the keyboard: W/A/S/D move, Enter presses, Q/E switch tabs.

## Audio (phase 0.5 package 28a)
- Game events play sounds: engine, warp, jumps, docking, weapons, hits, explosions, modules, drones, interface,
  alarms and the hum of space – 36 synthesised placeholders for now (`tools/audio/make_placeholders.py`), listed with
  the planned sound in `docs/audio/sound_list.md`; a real sound with the same name replaces a placeholder.
- Volume sliders for master, music, atmosphere and effects in the settings. Debug menu → Audio: play every sound,
  live channel levels, event log.

## Outfitter (phase 0.5 package 27)
- Category tiles (weapons, tools, core, optional, drone hangar, storage) → the ship's slots → the module
  families in stock as tiles → size · quality tiles → a short description and how the ship's values change.
  **Buy & fit** puts the module straight into the slot. A footer shows the ship's key values and power.
- Every module family has a short description; the ship info shows the current speed.

## Station concourse (phase 0.5 package 27)
- After docking the concourse shows three columns: the **commander** (portrait and career are placeholders for
  now) and the **news** on the left, the **docked ship** with hull, armor, fuel, cargo and drones and the ship
  services (refuel and repair with one click, drone bay, outfitter, hangar) in the middle, the **station** –
  faction, standing, economy, your balance – and its services as long tiles on the right.

## Waystations – station type 0 (phase 0.5 package 26)
- Small stations in most systems, out on the way to a gate: round **landing pads** instead of hangar bays,
  only for S and M ships. Ships land on a pad and sink through its hatch, and rise through it when they leave –
  one ship per pad at a time, the others wait.
- A fixed small set of services: market, fuel, repair and hangar – no shipyard, no outfitter.

## Axiom Astronautics – the Directorate's research and jump ships (phase 0.5 package 25g)
- **Parallax** (S, from Neutral) and **Threshold** (L, from Allied), sold only at Directorate shipyards:
  sensors +25 %, signature −25 %, power use −15 %, a built-in **cloaking device** (invisible and
  untargetable; using a weapon, tool or module ends it; uses energy). With a Drone Cloak Emitter the
  drones cloak too.
- **Parallax:** the galaxy map marks every system within four jumps with undiscovered anomalies.
- **Threshold:** an artificial black hole in its round core opens a **wormhole** – jump without a gate up to
  eight jumps far for one unit of **exotic matter** per jump (from rare "Exotic Matter Signature"
  anomalies); 120 s cooldown; sometimes the wormhole collapses early and drops you anywhere in the system.
- Axiom research ships fly in Directorate systems and cloak when attacked. Debug: +10 exotic matter.

## Forge of Return – the Covenant's flying temples (phase 0.5 package 25f)
- **Acolyte** (S, from Neutral), **Templar** (M, from Friendly), **Cathedral** (L, from Allied): crimson
  battlements with crystal batteries around a radiant ivory-and-gold nave with stained glass. Sold only at
  Covenant shipyards; no drone hangars; reactor +80 % (Cathedral +120 %), weak hulls.
- **Focus-crystal lasers** (size 1–4): red beams, high damage, long range, very power-hungry; only at
  Covenant outfitters, only for Covenant ships. With crystals in every hardpoint the Acolyte and Templar
  join their beams into one **focus lance** (+30 %).
- **Cathedral:** anti-drone pulse (every 30 s, 5,000 km, every drone drifts for 15 s – friend or foe) and
  an auto mode (the lasers fire on their own at up to six enemies or the targets locked when switched on).
- Covenant patrols fly Forge ships in their systems. Debug menu → Ship: nearby NPC carriers launch drones.

## Concord Fleetworks – the Assembly's drone carriers (phase 0.5 package 25e)
- **Demos** (S, from Neutral), **Quirinus** (M, from Friendly), **Concordia** (L, from Allied – the only ship
  with eleven drones, in Assembly blue). Sold only at Assembly shipyards, and only with the standing.
- Drones: hull, damage, mining, repair, cargo and fuel doubled, control range doubled (up to the recon
  range). The ships' own guns do half damage; shields +60 % but three times the downtime.
- Several hangar doors: drones rise from all of them at once and land in the nearest one.
- NPC carriers fight with their drones: Assembly patrols (Concord ships in Assembly systems, now and then
  a Goliath) launch them in a fight and call them back afterwards.
- Debug menu → Ship: fill the drone hangar.

## Hadrian Dynamics – warships (phase 0.5 package 25d)
- **Talon** (S dropship), **Maul** (M gunboat), **Goliath** (M destroyer with the guns of a cruiser) and
  **Citadel** (L fleet carrier): strong in combat, weak at everything else (few tool slots, small cargo,
  no ore hold, −50 % mining, salvage and analysis, high signature).
- **Reflective hull:** 10 / 15 / 20 % (S / M / L) of the damage to the armour goes back to the attacker;
  M and L +20 % explosive resistance. Talon: rockets and torpedoes fire 30 % faster. Goliath and Citadel:
  built-in point defence, sold only at military stations, shipyard complexes and tier-3 stations.
- Pirates fly worn-out, rusty copies (never the Goliath); Directorate patrols fly Hadrian ships too.
- Debug menu → World: spawn any ship next to you (hostile or neutral).

## Maison Aurelle – passenger transport (phase 0.5 package 25c)
- **Passenger cabins** (optional modules, size 1–10): bulk, business and luxury suites; more seats with
  size and quality. Luxury suites fit only into Maison Aurelle ships. Occupied cabins cannot be removed.
- **Bulletin board → Passengers:** transport contracts (own limit of 8 groups). Bulk groups fill the bulk
  seats of all cabins together; every business or luxury group needs a free cabin of its class that seats
  all of them. Pay per passenger and jump: 60 / 220 / 700 cr. Each contract has a deadline; a late
  arrival or losing the ship with the passengers aboard costs standing with the issuing faction.
- **Pearl** (S), **Boulevard** (M), **Opal** (M) and **Empress** (L): fast, luxurious, expensive; built-in
  afterburner (Pearl, Boulevard, Opal), Empress with fast warp, strong shields, +25 % on luxury contracts,
  half-size cargo racks and white drones with their own shield. The Empress carries a park with trees and a
  pool under a glass dome (animated). Sold at trade hubs of rich, safe
  Assembly and Covenant systems; Boulevard liners fly between the stations there.

## Kanayama-maru – heavy industry ship (phase 0.5 package 25b)
- KHI's L-class industry ship (950,000 cr, KHI yards of tier 3), built like a carrier: a tall rear block
  with the bridge, in front of it a flat flight deck – the drones roll down the whole runway one after the
  other, break away past the bow and land on the deck again. Nine drones (+25 % mining, +5 m³ cargo,
  KHI yellow), a 1,200 m³ ore hold, a refinery as good as a station's, a prospector, very slow to turn and
  to align for warp.
- **Building takes time everywhere:** 15 s × size^1.2 per module, 40 s per drone. Station jobs keep
  running and end up in station storage (queue in the manufacturing panel; jobs are saved).
- **On-board factory** (built in, 30 MW while on): builds what an industrial complex builds (up to size 7)
  and drones from your cargo; only while switched on and in space. Modules go into the cargo hold,
  drones into the hangar. Ship menu → **Industry** (the tab only shows on ships with a factory).
- **On-board market** (built in, 6 MW while open): set goods and prices in Ship menu → **Market** (only on ships
  with a market). While it
  is open and the ship stands still, traders of the system come over every 25–50 s and buy if the price is
  fair (up to about 0.9–1.5 × the base price). Offers worth more than 60,000 cr attract pirates.

## Ship manufacturers (phase 0.5 package 24)
Seven manufacturers are planned (`data/manufacturers.gd`) – their ships follow in package 25:
**Earthworks** (EWK, all ships so far), **Kanayama Heavy Industries** (KHI, mining & industry),
**Maison Aurelle** (AUR, luxury & passengers), **Hadrian Dynamics** (HDY, warships) and the state
manufacturers **Concord Fleetworks** (CFW, Assembly – drone carriers), **Forge of Return** (FOR,
Covenant – weapon platforms) and **Axiom Astronautics** (AXA, Directorate – research). Each has a crest
(scripts/core/crest_art.gd, `CrestArt.maker_texture`) and a codex entry with its history.
The recon radar now always shows **10,000 km** – also the limit of every drone control range.

## Drones (phase 0.5 package 23)
- **Drone hangar** – a new core slot on every ship (module *Drone Hangar 1–9*, quality = more room:
  size × 3 drones at C, ×0.6 at F … ×1.5 at A). How many drones fly at once is set by the hull:
  S 1, Mule 3, Drillhead/Warden 4, Longhaul 5, Bastion 9. The hangar has three equipment slots for all
  drones: a **weapon** (size 1), a **mining laser / ice harvester** (size 1) and a **bonus slot** for
  drone modules (Relay +range, Cargo Pod, Armor, Shield Emitter, Weapon Booster, Targeting Array,
  Fuel Cell, Thrusters) – fitted in the ship menu (Modules → *Drone hangar*, below Optional). Standard fits come with a pulse laser and a mining laser; the start ship has
  two drones.
- **Drones:** small and weak (60 hull, no shield without an emitter, 5 m³ cargo), one sealed fuel load
  of 5 minutes (idle 0.8×, working 1×, fighting 1.2×; none used in the hangar) – empty or shot down
  means lost. They act within **9,000 km** of the ship; further out they fly back and drop their target.
  At rest they fly a symmetric formation (mirrored pairs left and right, an odd one right behind on
  the centre line). They fire their real weapon, mine with the same beam as the ship and show an engine glow.
- **Drone window** (top left edge): folded until drones are out. Role tiles **Combat / Mining / Repair**
  (any time, for all drones) and the behaviour:
  - Combat: *Defend* (ships that attacked you or that you attacked), *Attack target* (your active
    lock), *Fire at will* (everything nearby except allies – civilians too, which is a crime), *Rest*.
  - Mining: *Auto* (find asteroids, mine, deliver to the ship), *Work on target* (your locked asteroid), *Rest*.
  - Repair (built-in beam): *Auto* (you, allies and neutral ships), *Work on target*, *Allies only*,
    *Self only*, *Rest*.
  - **Recall** brings them all home. Keys: **K** launches one drone per press (up to the maximum),
    **P** recalls; "Launch all drones" has no key by default – set one in Settings → Controls.
- **Warp, jumps, docking:** while the ship aligns for a warp or spools the jump drive, the drones fly into
  the hangar and come straight out again after the warp / jump; drones too far away are left behind.
  Docking takes them in.
- Drones keep out of the radar shadow of colossi: no targets behind them; a drone in a shadow flies back.
- **Drone Bay** (Hivewright Drone Works, HWD, every station): buy drones (2,400 cr), sell used ones (worth
  less with less fuel), repair their hulls – fuel cannot be refilled.

## Multi-focus (phase 0.5 package 22)
- **Every weapon and tool keeps the target that was active when it was switched on.** Lock several
  targets, make one active, switch weapons on, make the next one active, switch more on – they fight
  different ships at once. Pressing the key of a running module whose target is not the active one
  moves it to the active target; pressed again it switches off. A lost lock only switches off the
  modules that worked on it.
- A **new lock becomes the active target**. If a target leaves the sensor range (or hides in a radar
  shadow), the modules on it stay on and wait (orange); it is **locked again automatically** when it is
  back within 60 s and they resume.
- **Lock slots** grow with the sensor suite: 3 (size 1–2), 4 (3–4), 5 (5–6), 6 (7–8).
- Module tile borders: green = working on the active target, yellow = on another target, orange = out
  of range, purple = not enough energy, red = no power.
- Module tiles show their target (T1, T2 …), lock cards and the brackets in space show the lock number
  and how many modules work on it.
- **NPCs:** bigger ships (hull M and up, three weapons or more) share their weapons out over several
  hostile ships near their target.

## Power management (phase 0.5 package 21)
- **Hard limit:** the usable reactor output (output × distributor efficiency) can never be exceeded.
- **Passive vs. active:** core equipment, passive optional modules and scanners always draw power;
  weapons, point defense, mine launchers, tools and active optional modules only **while in use**
  (switched on; NPCs: weapons while fighting, beams always, the jammer while jamming).
- **Priority groups 1–4** per module (default: core 1, weapons and shields 2, tools and active
  equipment 3, the rest 4). On an overload **group 4 shuts down first, then 3, then 2**; group 1 stays
  on (only if group 1 alone is too much, everything is throttled). Shut-down passive modules have no
  effect (e.g. no shield from a shut-down generator), shut-down active modules stay switched on but idle
  (red tile) until there is power again. The chat reports every shutdown and restart.
- **Ship menu → Modules → POWER MANAGEMENT:** a bar of the output with one segment per group
  (passive + active at most as one block, white line = output); modules that need no power are in group 0, a forecast (idle / everything on)
  and the list of all modules (icon, name, size · quality, active/passive, MW) with the priority buttons
  1–4. The HUD shows "Power x / y MW (passive + active)" and the groups that are off. Priorities are
  saved with the ship (command `set_priority`).

## New module types (phase 0.5 package 20)
- **Shield variants:** *Shield Generator* (balanced), *Capacitive Shield* (≈ +40 % capacity, slow
  regeneration) and *Fast-Cycle Shield* (≈ −30 % capacity, almost twice the regeneration).
- **Shield downtime** (every ship, NPCs too): a shield that is shot down stays **offline** for a while,
  then restarts at **50 %**. Downtime = type factor (balanced 1.0, capacitive 1.35, fast-cycle 0.6) ÷
  quality × (4 + √max shield / 3) s, 3–60 s (ship info shows it). Shield boosters cannot bring a collapsed
  shield back; a shield transfer beam on the ship makes the downtime run out 3× as fast.
- **Point Defense Turret** (weapon slot, size 1–3): switch it on in the module bar – it shoots down
  hostile rockets, torpedoes (also ion torpedoes) and mines in range by itself (intercept chance ~60–80 %,
  a little energy per shot). Not a gun against ships. Patrols sometimes carry it.
- **Shield Transfer Beam** (tool, 1–3): on a locked friendly ship it charges that ship's shield from
  **your capacitor** (never from your shield); it only uses energy while it actually transfers.
- **Cargo Scanner** (tool, 1–2): reads the manifest of a locked ship; smugglers show **unregistered
  cargo**. Part of a pirate's cargo survives in its wreck.
- **Solar Collector** (optional, 1–4, passive): refuels in space – full rate within 4 star radii,
  dropping with the square of the distance.
- **Mine Launcher** (weapon slot, 1–3): lays mines from the **cargo hold** behind the ship – click its tile
  to lay one, **right-click** to pick the type and the timer. At most 3/6/9 mines per launcher at once;
  mines vanish after 5 minutes and only threaten ships hostile to you. Mines are goods (military outposts,
  shipyards, pirate havens): **Proximity** (armed after 3 s, explodes near a hostile ship), **Timed**
  (5–60 s), **Jammer** (jams hostile radar within 6,000 km for 45 s), **EMP** (shields collapse,
  capacitor and modules dead for 8 s).
- **Radar Jammer** (optional, 1–4, active): hostile ships in its radius lose their radar picture and can
  lock/engage only at half sensor range. **Pirates use it against you** (about one in five): your radar
  shows static and "RADAR JAMMED", the contact list only shows ships within 3,000 km and your locks
  reach half as far. Status flags (SHIELD DOWN, EMP, JAMMED) show in the ship panel, on lock and group
  tiles and in the selection panel.

## Modules: family + size + quality (phase 0.5 package 19)
Every module is a **family** (Pulse Laser, Ion Drive, Shield Generator …), a **size** and a **quality**,
e.g. *Pulse Laser 2 · C* (id `w_pulse:2:C`). `data/modules.gd` defines 53 families; `build_all()`
generates every allowed size and quality – about 1,700 modules (`GameData.modules`).
- **Sizes:** weapons and tools 1–4, optional 1–8 (cargo and ore hold 10), core slots 1–10 (sensors 1–8,
  hyperdrive 1–6). Each family has its own range (e.g. Photon Lance 3–4). Values follow curves from an
  anchor (the old S/M/L module): performance ∝ size^1.3, mass ^1.2, power ^1.1, price ^1.6; ranges grow
  slowly. Hyperdrive size sets the jump class (1–2 → 1, 3–4 → 2, 5–6 → 3).
- **Quality F–A** (S/S+ later in the endgame): performance ×0.80 … ×1.16, power ×0.94 … ×1.08, price
  ×0.55 … ×2.0. Mass: **D is the lightest, F the heaviest, B as heavy as A** (A performs better).
- **Slots:** every hull lists the maximum size of every single slot (`slot_sizes` in `data/hulls.gd`) –
  core slots too. **Smaller modules fit bigger slots**, bigger never. The Modules tab shows each slot's
  maximum ("≤4") and every module's size and quality.
- **Where to get them:** outfitters stock their speciality in the sizes their tier allows (weapons/tools
  2/3/4, optional 3/6/8, core 4/7/10 for tier 1/2/3), each size in a few qualities – F–C everywhere,
  B from tier 2, A at tier 3 or military outposts. Manufacturing builds quality C blueprints; the result's
  quality is rolled (mostly C, sometimes better or worse). Loot comes in any quality.
- **Hulls (Earthworks + NPC):** Dragonfly, Hornet, Mule, Drillhead, Warden, Bastion, Skiff, Longhaul
  (Earthworks) and the pirates' Carrion Crow. Skiff and Longhaul are now sold at shipyards, the Carrion
  Crow in Pirate Havens.
- **Saves:** save version 2 – saves of an older alpha are refused with a note and never offered by
  Continue (alpha rule: no migrations that would hold back reworks).

## Codex (phase 0.5 package 18)
An in-game encyclopedia – Pilot window [U] → Pilot → **Codex**, and **Codex** in the main menu (there: everything
discovered in any of your games, collected in `user://codex.cfg`). 45 entries in six categories: Basics,
History, Factions, Corporations, The Cluster, Technology – with crest, ship or icon pictures and
"see also" links (`data/codex.gd`; faction and corporation entries are generated from their data).
- **Basics** are known from the start; everything else unlocks on discovery (`GameState.codex`, saved):
  the history from the station archives (first dock), a faction on first meeting its ships or space,
  a corporation when you use its service, colossi, pirate havens, notorious pirates, station raids,
  ion weapons, warp, gates and mining when you first encounter them.
- New entries: "📖 New Codex entry" at the top of the HUD and in the log; unread entries are marked gold
  in the list. Undiscovered ones show as "???".
- Later packages add their entries to `data/codex.gd` (unlock = "start", an event or "faction:/corp:<id>").

## Faction contracts (phase 0.5 package 17)
Below BlackLedger's offers, the Bulletin Board of every government station lists three **faction
contracts** issued by the station's power (`Missions.generate_faction`, accepted with the usual
`mission_accept`). They need standing, pay by danger and raise the standing by 4 (instead of 2.5);
failing one costs 2. Contracts aimed at a pirate faction pull its standing down.
- **Escort** (Neutral): a real convoy (2–4 freighters + an escort ship) leaves this station for one 1–2
  jumps away. Stay with it – in its system, undocked – for at least 60 % of the journey; pirates ambush
  escorted convoys now and then (more likely in unsafe space). Report at the destination station.
  The pay is shared out per freighter: each one lost costs its share (all lost = failed).
  The convoy first **gathers outside its station** and waits until you follow it (within 8,000 km) or
  have been within 1,000 km of it for 3 seconds, then sets off ("Convoy departing" in the ticker); the waiting time does not count
  against you. Your convoy is marked **green**: a ring around each ship in combat view, green diamonds
  with "YOUR CONVOY" on the recon radar and the system map.
  The **lead ship** (the one the others follow) has a double green ring and the tag *CONVOY LEAD*
  (radar: "YOUR CONVOY (lead)").
  **Follow** (button in the selection panel for green ships, command `follow`; any convoy ship means its
  lead ship): you stay with it –
  when it warps you go into warp with it at once (no aligning) and arrive together; when it jumps
  through a gate you jump after it and follow it again in the next system. The convoy's own ships use
  the same behaviour, so the convoy stays together. Whenever the convoy starts aligning for its next
  warp it says so in the ticker ("Convoy aligning for warp to … – stay close!").
  **Formation:** followers fly a fixed **V formation** behind the ship they follow (the pilot takes the
  first slot) and keep their slot for the **whole warp** – they slide into it during the first 1.5 s
  and drop out together with the lead. The lead of your group announces every warp and jump in the chat
  ("Aligning for warp to … – hold formation", "Spooling jump drive – jumping to …").
  **Group warp speed:** whoever follows a ship (directly or along a chain) warps with it – the lead ship
  sets its warp time by the **slowest** warp drive of everyone following it.
  **Your group** (convoy, patrol, the ship you follow, anyone following you) shows as small green tiles at
  the **top left** – name, LEAD tag, distance, shield/armor/structure; click selects, right-click follows.
  **After an attack** the convoy never scatters: it **holds position** while any pirate is within its
  recon (sensor) range and sets off again once it is clear **and** you are with it – following it within
  8,000 km or right next to it (2,000 km). If you never come back it moves on after 2 minutes of quiet.
  **Pirate interceptions:** in each system the escorted convoy may be **pulled out of warp** halfway
  (more likely in unsafe space) – the convoy and everyone following it drop out right next to the lead
  ship, the drives are
  disrupted for 15 s and 3–4 pirates close in; or pirates **wait at the gate** through which the convoy
  arrives.
  **Trade hubs** also post escort contracts on BlackLedger's board (about 30 % of their offers): an
  independent trader's convoy of 2–4 freighters *without* an escort ship – same rules, no faction needed.
- **Patrol** (Neutral): the contract gets its **own patrol group**. It meets you at the issuing station
  (rolling out of its bays) or at a named place in the system (a gate or field), marked green with a
  *PATROL LEAD*, and waits until you follow it (within 8,000 km) or have been within 1,000 km for 3 s –
  then "Patrol departing" and it flies its rounds. **Follow** works as with convoys (also in warp).
  Fly within 10,000 km of the group for 3 minutes, then report back; the patrol is released and leaves.
  If the group is destroyed, the contract fails.
- **Intercept** (Neutral): an unregistered Hollow Crown hauler appears in a system up to two jumps away
  and runs for the gate farthest from it. Destroy it before it jumps or the 20 minutes run out (a Warp
  Interdictor helps). If someone else kills it, it counts only if you had hit it.
- **Hunt** (Friendly): kill a named notorious pirate; pays 20,000 cr + half its bounty + 10,000 per star,
  on top of the SWX bond. Fails if someone else gets the target.

## World reactions & news ticker (phase 0.5 package 16)
- **News** (`scripts/core/news.gd`, `GameState.news`, saved): *alerts* (station raids – these also stay
  in the log), *Cluster news* (bounty campaigns, convoys under way, pirate activity, notorious
  pirates: new captains, sightings, rising danger, deaths, stations back online) and *radio* chatter of
  the system you are in (distress calls, patrol responses, reinforcements, captains sighted, ships lost).
- **Ticker** at the bottom of the ship panel (bottom left): every new item scrolls through once; with
  nothing new the ticker is hidden. Radio chatter only reaches the ticker when it happens within
  26,000 km of your ship (about one asteroid field across) – everything else goes to the archive only.
  Raids, Cluster news and notorious captains sighted in your system always run. The **Info** tab of the ship menu shows the last six; every station has a
  **News Archive** tile (Lumen Newsnet [LNN]) with the full feed, filters and running campaigns.
- **Bounty campaigns:** every 2.5–5 min a world event; often a power raises bounties in one of its
  systems by 50 % for 30 minutes – pirates spawned there carry the higher bounty.
- **Distress calls:** an attacked civilian or patrol radios for help (at most every 25 s per ship);
  convoys report "Convoy under attack near …". Civilians within 25,000 km move away from the attacker.
- **Escalation** in power space (not in lawless pirate space): the nearest patrol group of the authority
  answers the call (flies there, fights the culprit if it is hostile to it, stays two minutes); rising
  *heat* brings **reinforcements** (2 ships) and then a **task force** (3 heavy ships) through a gate or
  out of a station – they leave again after five minutes. The Covenant escalates fastest (×1.5), the
  Assembly's militias slowest (×0.8); safe systems faster than unsafe ones. Heat fades over time.
- **Wrecks for everyone:** destroyed civilians leave their cargo (food, electronics, alloys …), patrols
  weapon parts and sometimes a module.
- Debug menu → World → *Raid in 5 min* / *Raid now* (`debug_raid`): a notorious pirate comes to your
  system, rises to 5 stars and raids a station (not a military outpost).

## Notorious pirates (phase 0.5 package 15)
Five named pirate captains roam the Cluster (`scripts/core/notorious.gd`, `GameState.notorious`, saved):
name and nickname (»the Butcher«), their own paint, an archetype, a heavy loadout, escorts in formation
and one **trait**: *Shield Breaker* (+60 % damage on shields), *Never Alone* (two extra escorts),
*Iron Hide* (−40 % damage taken), *Ghost* (locks take 2.5× as long), *Overcharged* (weapons cycle 40 %
faster) or *Regenerator* (fast shields, self-repairing armour).
- **Danger 1–5 stars:** 2 / 2 / 3 / 4 / 5 escorts (heavier escort ships from 2 stars on), and the captain
  takes 85 % … 50 % damage. A new game starts with two 1-star, two 2-star and one 3-star captain; every
  30 minutes a captain survives it gains a star and its new escorts warp in. Successors start at 1–2 stars.
- **Bounty** is independent of the stars: a base of 40,000–80,000 cr that rises by 500 cr every 4 minutes
  the captain lives. Posters show *Wanted since*.
- **Roaming:** everywhere except the home systems (the three capitals and your start system). Lawless
  space (security ≤ 0.65) for 6–12 min per system; safer systems only for 2–4 min visits, lurking in the
  asteroid fields. They never leave while you are in their system. Entering it (or them arriving) spawns
  them with their escorts; the log warns you.
- **Station raids:** 5-star captains arriving in a system with a station (not a military outpost) raid it
  half the time. An **SWX ALERT** in the log announces the raid **5 minutes ahead**; then it lasts 3–5 min.
  - Fought live when you are in the system: the station gets a **hull bar** (15,000 per tier) and its
    turrets 1,200 HP each. Raiders bombard the turrets first, then the hull; the captain's **Ion Torpedo**
    (new weapon, 5-star captains only – cannot be fitted by pilots or found as loot) knocks a turret
    offline for 25 s every 10 s. Raiders count as aggressors, so working turrets fire back. Turret
    markers: red ✕ = shot down, violet ring = ion-disabled, green bar = turret health. An HUD line shows
    hull %, working turrets and the time left.
  - **Station falls:** the captain's bounty rises by 100,000 cr and one of its stars turns **red**. The
    station is **offline for one hour** – you can dock, but no service works – unless the **relief goods**
    it needs (alloys, electronics and one type-specific good, amounts by tier) arrive earlier. Deliver
    any portion (also with small ships) right on the concourse: every unit pays **twice its base price**;
    completing the relief pays 5,000 cr per tier and raises your standing with the station's faction
    (`scripts/core/station_status.gd`, `GameState.stations`, command `relief_deliver`).
  - **Captain about to lose** (below 30 % armour + structure): breaks off, the raiders flee and jump out,
    and the captain hides for 15 minutes (posters: "whereabouts unknown"). The station also holds when
    time runs out or the captain dies.
  - **Defending pays:** if you hit any raider and the station holds, you get 20,000 cr and standing
    with the station's faction.
  - Away from the system the raid is decided by chance (the higher the tier, the likelier it holds).
- **Wanted posters** at every Bond Office: portrait in their paint, stars, faction, archetype, trait,
  bounty, escorts, wanted since, last sighting with a course button, current raid. The galaxy map marks
  their systems with a pulsing ☠ and lists them (with stars and raids) in the system info. Sightings,
  raids and deaths are collected in `notorious.news` for the news ticker (package 16).
- Destroying one issues the bounty bond (from the power responsible for the system) and leaves a wreck
  with three of its modules, rare ingots and plenty of parts. After 20–40 minutes a **successor** takes
  over the crew. Escorts of a dead captain fight on as ordinary pirates.
- Debug menu → World → *Summon notorious pirate* (`debug_notorious`).

## Bounties & law (phase 0.5 package 13)
- **Bounties come from the powers:** the power holding the system (contested: the first claiming power,
  pirate space: the power whose territory is nearest) puts the bounty on a pirate. The Covenant pays
  25 % more, the Assembly 10 % less (`bounty` in `data/factions.gd`). The Warrant Scanner shows the issuer.
- **Bonds** carry the issuing faction and its crest. The Sable Writ Exchange stays the clearing house: a bond
  is redeemed at the Bond Office of **any station of the issuing faction** (not in pirate havens). Bonds
  from older saves keep the old rule (the system where they were issued). The bond wallet and the Bond
  Office show where each bond is paid (nearest system) with a course button.
- **Criminal record per power** (`scripts/core/law.gd`, `GameState.law`, saved): crimes are recorded with
  the power whose law applies – the system owner; in contested systems the power whose ship or station
  was wronged. Pirate space is lawless. Points: fire in a no-fire zone 1, first shot at a civilian 1 /
  patrol 2 (only if it was no threat), destroying such a civilian 2 / patrol 3, interdicting a lawful ship 1.
  **Suspect** (1–2 points): its patrols attack you, even inside no-fire zones. **Wanted** (3–5): also no
  contracts at its stations. **Most Wanted** (6+): its stations refuse docking. One point fades every
  5 min without a new crime; the fine (2,000 cr per point) clears the record at a Bond Office of that
  faction (command `fine_pay`). Status in Pilot window → Pilot → Standings and at the Bond Office; debug menu
  (Pilot tab) sets records (`debug_wanted`).

## Factions & territory (phase 0.5 package 10)
The year is 12900 HE. Almost two centuries ago the Severance cut the Cluster off from Earth; three
governments and several pirate factions have risen since (`data/factions.gd`, separate from the
service corporations):
- **Cluster Assembly** – direct democracy, blue/white. **Covenant of Return** – theocratic
  autocracy, crimson/gold. **Meridian Directorate** – technocracy, green/silver.
- **Hollow Crown** (smuggling cartel) and **The Severed** (nihilist cult) hold pirate territory;
  **Free Captains** own no systems and only appear as pirates.

The territory is generated deterministically from the seed: the powers grow from three capitals
(~12 systems each), the pirate factions hold ~4 remote systems each, and a few frontier systems
stay contested. Security follows from the owner and the distance to its capital (pirate space is
lawless); Pirate Havens exist only in pirate territory. The pilot starts in an Assembly border
system. Stations fly the flag of the system owner (in contested systems the claimants share the
stations; stations in pirate space are independent free ports) and show it as a flickering
**holo banner** with the faction's coat of arms (`CrestArt`). Pirates wear the paint of their
faction. The galaxy map has a **Territory** layer (striped = contested) with crests at the
capitals; HUD, station header, galaxy info and ship menu show the controlling faction.
Saves from galaxy version 2 are moved to the new cluster like before.

## Population & traffic (phase 0.5 package 11)
Every system has a profile (`Universe.system_profile`): population from its planets (earthlike
worlds carry by far the most), its stations and their economy, the controlling faction. From it
`Traffic` (scripts/world/traffic.gd) populates the system the player is in – never more than
60 NPC ships:
- **Shuttles** (new hull *Skiff*) between populated planets and stations.
- **Miners** from Mining Colonies / Ice Refineries: they fly to the fields, mine real asteroids
  (competing with you for ore) and return.
- **Patrols** of the controlling faction in its paint (contested systems: one per claimant) touring
  stations, gates and fields; bigger and better ships around military stations. At each waypoint they
  fly a slow beat (half speed, 1.5–3 min) – round stations and gates on a ring well outside the
  structure (never across it), zig-zagging through asteroid fields – then warp on. They attack
  pirates (also inside no-fire zones, without becoming aggressors).
- **Trade convoys** (new hull *Longhaul*, plus escorts for the powers) run between producing and
  consuming stations along real routes. `ConvoySim` (scripts/core/convoy_sim.gd) simulates them
  coarsely across the cluster; in your system they become real ships that fly to the gate and jump
  or dock at their destination. Not saved – rebuilt on load.
**Loiterers** stay around one place: haulers holding near stations, two-ship patrols sweeping the
asteroid fields, patrol frigates watching the gates. Every system with asteroid fields has a couple
of freelance miners, mining systems many more. Traffic and patrols fly slower than the pilot and
take noticeably longer to align for warp.
**Contacts** tab (next to the overview, right): every ship in the system with role, faction and
distance – ⇢ marks ships in warp. **Warp Interdictor** (tool S/M, one in the start storage): select a
ship in warp (in space or in Contacts), activate the module: the target freezes, you warp after it
at reduced speed and play a timing game (press E or click inside the green window; bigger hulls are
harder). Win → the target drops out of warp and its warp drive is disrupted for 45 s. Interdicting a lawful
ship (civilian or patrol) is a crime (package 13).
The galaxy map shows population, traffic, patrols and convoys per system; the **Territory [T]** and
**Convoys** switches on the map turn the overlays on and off (remembered in the settings).

## Reputation (phase 0.5 package 12)
Every faction keeps a **standing** towards the pilot from −100 to +100 (`scripts/core/reputation.gd`,
owned by `GameState.rep`, saved with the pilot). Five tiers: **Arch-enemy** (< −60), **Hostile** (−60),
**Neutral** (−20), **Friendly** (+20), **Allied** (+60). New pilots start Neutral (0) with the powers and
slightly negative (−10) with the pirate factions.
- **Sources:** redeeming bounty bonds (+0.5 … +4 with the issuing power – the power holding or claiming the
  system; bonds now record it), completed BlackLedger contracts (+2.5 with the faction of the issuing
  station), opening fire on a ship that was not hostile (−4, once per ship), destroying a civilian (−10) or
  patrol (−12), destroying a pirate (−1.5 per size class with its pirate faction). **Pull effect:** only
  contracts aimed at another faction cost standing with it (bounty contracts against the pirate faction
  holding the target system, −1.5). Customs violations will hook into `rep.change()` later.
- **Docking:** arch-enemies are refused at the faction's stations (free ports never refuse).
- **Prices** at the faction's stations (market, outfitter, shipyard, fuel, repair): Hostile +10 % / sales
  −10 %, Friendly −5 % / +3 %, Allied −10 % / +6 %. Station panels show the standing line.
- **Patrols:** attack Hostile and worse, *scan* Neutral pilots (cyan beam + log, at most every 2 min per
  faction) and ignore Friendly ones. They also fight anyone who opened fire on one of their faction's
  ships (90 s) – inside no-fire zones as well (law enforcement).
- **Contracts:** no BlackLedger contracts at a Hostile faction's stations; Friendly +10 %, Allied +20 % reward
  (fixed when accepted). **Military gear:** L modules at Military Outposts need Friendly standing.
- **Pirates:** a pirate faction's ships leave Friendly pilots alone, and its **Pirate Havens** stop shooting
  and let you dock – black market (type `pirate_haven`: weapon parts and salvage cheap, food, medicine,
  electronics, alloys, water, xeno lattice and helium-3 in demand), outfitter, refinery, fuel, repair,
  hangar; no shipyard, bond office or bulletin board. Free Captains own no havens.
- **Attacking anyone:** weapons now work on every ship, not only hostile ones – the log warns before you fire
  on a ship that is not hostile. That ship and (for 90 s) its faction fight back.
- **Pilot window → Pilot → Standings** shows crest, tier, value bar and the current effects for every faction; the
  station header shows your standing with its owner, the selection panel your standing with a ship's
  faction (and HOSTILE if it would attack you).
- Debug menu (Pilot tab): ±25 or set a value for one or all factions – command `{"type": "debug_rep",
  "faction": "assembly", "value": 40}` (or `"amount"`; faction `""` = all).

## Controls are rebindable
All hotkeys are Godot input actions (`scripts/autoload/keybinds.gd`) with up to two bindings each –
keys or middle / side mouse buttons. Change them in **Settings → Controls** (main menu or pause menu);
they are stored in `user://keybinds.cfg`. "Reset to defaults" restores the table above.
A clean middle-mouse click (no drag) re-centres the camera on your ship (same as Space).

## Saving & loading
- Saves live in `user://saves/*.sav` (Windows: `%APPDATA%\Godot\app_userdata\Sternenfront\saves`).
- Format: Godot text (`var_to_str`), versioned. The galaxy is regenerated from its seed; only
  changes are stored (pilot, fleet, storage, contracts, asteroid deposits, anomaly progress).
- Autosave when docking and when arriving in a system (can be turned off in Settings).
- **F5** quicksave, **F9** quickload, **Esc** pause menu with Save / Load / Settings / Main Menu.
- No saving during a hyperspace jump.

## Test system (debug builds)
**Main menu → Test System (Debug)** starts a sandbox that never touches your real galaxy or saves:
one system *Testfeld* without gates, containing every station type in all three tiers,
Pirate Havens of all tiers, every planet type, three asteroid fields (metallic, stony, icy) with every ore and
every asteroid size and shape, nine colossi (all class/shape combinations), revealed anomalies and
loose rock. You start with 10M credits and a Bastion in the hangar; saving is disabled and no pirates
spawn (use the debug menu, F12). Code: `Universe.generate_test()` / `build_test_layout()`.

## Debug menu (F12)
Cheats for testing everything quickly, including endgame content. Available when running from
the editor (debug builds); disabled in exported release builds (`Commands.cheats_enabled`).
- **Pilot:** credits (+10k … +10M), complete contract objectives, reroll the bulletin board, game speed ×0.5–×10
- **Ship:** god mode, refill everything, empty cargo, any hull (incl. the pirate Carrion Crow) with or without standard fit, board immediately
- **Items:** any module (or one of every module) into station storage, any commodity into the cargo hold
- **World:** teleport to any system (docks at its first station), reveal anomalies, spawn pirates, destroy all pirates

All cheats are `debug_*` commands on the command bus, so a multiplayer server can simply refuse them.

## Command bus (multiplayer groundwork)
Every player action is a plain dictionary sent through `Commands.execute(cmd)`
(`scripts/autoload/commands.gd`), e.g. `{"type": "goto", "id": "st_12_0"}` or
`{"type": "market_buy", "item": "food", "amount": 10}`. Commands contain only ids, numbers and
strings, validate themselves and return an error text. UI and input code never change the game
state directly. In multiplayer the client will send the same dictionaries to the server.
Commands: move, approach, orbit, keep_range, warp_to, dock, jump, lock, unlock, target, activate,
deactivate, toggle_module, attack, goto, course, stance, undock, rename_pilot, rename_ship, board, ship_buy,
fit_module, unfit_module, jettison, market_buy, market_sell, module_buy, module_sell, refine, build,
mission_accept, mission_turn_in, mission_abandon, bond_redeem, fine_pay, refuel, repair (+ `debug_*` cheats such as
debug_rep, debug_wanted).

## Star cluster
48 systems linked by hyperspace routes. Station types and tiers are planned for the whole cluster
when the galaxy is generated, so **every station type exists in every tier (1–3) at least once**,
and Pirate Havens exist in all three tiers. The galaxy map shows each system's stations as coloured
squares (bigger = higher tier, red diamond = Pirate Haven); the legend buttons highlight every
system with a given economy, and the info panel lists what each station sells and buys.
Saves from the older 22-system cluster are moved automatically: all ships are docked at the home
Trade Hub, station storage is merged there, open contracts are cancelled.

## Core ideas
- **One pilot, one ship.** Other ships are parked in station hangars and swapped there
  (Station → *Hangar* → *Board*). New ships are bought at the shipyard.
- **A system is one huge continuous space** (1 unit = 1 km, radius 2M km).
  At sublight speed the trip from the star to the edge takes 1–2 hours – you *can* fly for hours.
- **Warp** to objects (star, planets, stations, gates, asteroid fields, discovered anomalies) happens
  live in the same view: the ship aligns, accelerates, the camera zooms out, you watch the ship cross
  the system, and the camera zooms back in on arrival.
- **HUD top bar:** three icon buttons top right – **Ship** [I], **Pilot** [U] (glows green when skill tree tiles
  or perk points wait) and **Map** [M]; credits and the system on the left.
- **Three fixed zoom levels** (mouse wheel or F1–F3):
  - *Combat* and *Recon* (local): star and planets are sky bodies in the background; the background
    stays identical between both levels. Recon shows the ship as a navigation arrow plus a radar sweep.
  - *System*: everything on one flat map with orbits, icons and labels.
- **Gate jumps** between systems: hyperspace tunnel → galaxy map with the ship on its route → arrival at the gate.

## Controls
| Input | Action |
|---|---|
| Click object / overview entry | warp there (far) or approach, then act |
| … station / gate / asteroid / anomaly / wreck | dock / jump / mine / analyse / salvage |
| Click empty space | sublight flight |
| Click object / overview entry | select it – the panel top right lists its actions (Warp to, Approach, Orbit, Keep at range, Lock target, Dock, Jump) |
| Click a locked target (top centre) | make it the active target · right-click: unlock |
| Mouse wheel / F1–F4 | zoom level: Combat → Recon → Orbit (a planet and its moons; not in warp) → System |
| WASD | fly the ship in that direction (screen up = north); release: it stops |
| Arrow keys / middle mouse, Space | pan camera, recentre on ship |
| Tab | cycle through everything within sensor range – ships first (nearest first), then asteroids, wrecks and anomalies; with nothing selected it starts with the ships again |
| V / C | cycle hostile / friendly ships (sensor range, otherwise up to 50,000 km) |
| B | select the nearest station within 5,000 km |
| K / P | launch one drone / recall all drones |
| I | ship menu |
| L, M, H | station, galaxy map & route planning, help |
| Esc | close window / pause menu |
| F5 / F9 | quicksave / quickload |
| 1 – 9 / click a module tile | switch an active module on/off (bottom centre) |
| R | lock the selected target (again: unlock; nothing selected: the nearest hostile ship) |
| Q / X / J / G / F | approach / warp to / jump / dock / follow the selected object; in warp X twice within 5 s = emergency shutdown |
| Click an ally tile (top left) | select it · right-click: follow |

## Ship menu (I) – seven tabs
1. **Info** – pilot name (renamable), credits, net worth, ship/fleet/storage value, location,
   career statistics (kills, jumps, ore mined, anomalies analysed, contracts, refined, built, earned,
   play time), active contracts and your fleet.
2. **Modules** – fitted modules as pixel-art tiles grouped into Core, Weapons, Tools, Optional;
   module properties on the left. While docked: select slot → select stored module → *Fit* / *Unfit*.
3. **Ship** – complete statistics: Defence, Offence, Navigation, Power, Sensors & Utility, Weapons & Tools.
4. **Inventory** – cargo hold (with value and jettison), storage at this station, storage elsewhere.
5. **Transactions** – *Contracts*: every accepted contract with client, progress, where to hand it in,
   course buttons and abandon; *Bonds*: the bond wallet for bounty bonds (filled from package 9 on).
6. **Standing** – reputation with every faction (crest, tier, value, effects; package 12).
7. **Codex** – the in-game encyclopedia (package 18).

Mining lasers and ice harvesters fire an animated beam (pulsing core, travelling energy packets,
sparks at the impact); the mined amount rises from the asteroid as a small "+x Ore" number.

## Stations
Approaching a station plays a docking animation (the ship spirals into the docking ring), then the
**concourse** opens: a grid of service tiles. Each service is a monopoly of one corporation:

| Service | Corporation | What it does |
|---|---|---|
| Market | Kessler-Vance Exchange [KVX] | buy/sell goods, prices depend on the station economy |
| Outfitter | Synapse Armaments [SYN] | buy modules into storage, sell stored modules |
| Shipyard | Hadal Orbital Yards [HOY] | bare hulls or standard fits, delivered to the hangar |
| Refinery | Crucible Metallurgy Combine [CMC] | ore → ingots; yield depends on station type |
| Manufacturing | Molten Lotus Fabrication [MLF] | build modules from materials; cheaper with local inputs |
| Bulletin Board | BlackLedger Contracts [BLC] | courier, bounty, supply and survey contracts |
| Bond Office | Sable Writ Exchange [SWX] | redeem bounty bonds issued in this system |
| Hangar | Vaultline Storage [VLT] | board/rename parked ships |
| Fuel Depot | Pyre Fuel Syndicate [PYRE] | refuel |
| Repair Bay | Mendex Nanorepair [MDX] | repair armour and structure |

Ship insurance is handled by Aegis Mutual.

**Station types and art** (`scripts/core/station_art.gd`): stations are assembled from modular
pixel-art parts (hub, rings, docking arms with hangar bays, solar wings, greenhouse domes, furnaces,
silos, tanks, cooling towers, dishes, armour, turrets, shipyard gantries …). Type and tier decide the
parts, so every type has its own silhouette: Trade Hub (big rings, neon advertising), Industrial
Complex (factory blocks, chimneys), Mining Colony (furnaces, ore silos, grabber arms holding rocks),
Agricultural Station (greenhouse domes, huge solar wings), Research Station (labs, dishes, sensor
booms), Military Outpost (armoured octagon, turret batteries, hangar gates), **Ice Refinery** (frosted
tanks, steaming cooling towers – near icy fields) and **Shipyard Complex** (three construction docks
with hulls being built). Tier 1 is ~960 km across, tier 3 ~1,600 km, the shipyard ~1,760 km.
Lights blink, neon signs scroll, chimneys smoke, cooling towers steam, welders spark and shuttles
fly in and out of the bays.
- **Docking:** the ship lines up in front of the nearest hangar bay (wide enough for an L hull),
  glides in and disappears in the dark hangar; undocking rolls out of a bay.
- **No-fire zone:** 15,000 / 22,000 / 30,000 km around tier 1 / 2 / 3 stations (dashed amber ring).
  Opening fire inside it (shooter or target inside) flags you as an **aggressor** for 30 s and the
  station's defence batteries fire on you. Shooting back at an aggressor is self-defence. Pirates
  follow the same rule and do not start fights with ships under a station's protection.
- **Pirate Havens** in lawless systems (security < 0.3): patched-together wreck fortresses whose guns
  fire on anyone within 7,000 km – unless you are Friendly with the haven's pirate faction; then you
  may dock (package 12). Which services exist depends on the station type
(trade hub, industrial complex, mining colony, agricultural, research, military outpost).

## Industry & missions
- **Raw materials** (`data/commodities.gd`): 18 ores and ices in three asteroid classes –
  *Metallic* (iron, nickel, titanium, cobalt, platinum, iridium), *Stony / silicate* (silicate rock,
  bauxite, olivine, rare earth ore, xeno crystals, neodymium) and *Icy* (water, ammonia, methane,
  deuterium, helium-3 ice, cryo crystals). Each has a rarity (common / uncommon / rare).
- **Asteroid fields** (`scripts/autoload/universe.gd`): each field is *metallic*, *stony* or *icy* and holds
  several ores of its class (both common ones, one or two uncommon ones; rare ores only in systems with
  security < 0.5, more the lower it is). Metallic fields lie close to the star, icy fields beyond the frost
  line (hot stars push it outward). Ordinary mining lasers work on ice at only 25 %.
- **Asteroids** come in clumps of 70–130 per field, in three size classes (small / medium / large) and
  procedural shapes (round, potato, contact binary, angular fragment, ice shard). Metallic rock shows
  veins and glints, stony rock craters, ice a translucent rim, cracks and sparkle. Large asteroids
  often hold a second ore; mining yields both in proportion. Asteroids are only drawn near the camera.
- **Loose asteroids** outside the fields: dense clusters of rock spaced around every planet (class by planet
  type – ice around gas giants, metal around lava worlds) and clusters at gates, stations and anomalies.
  Most are scenery drawn in bulk (`layout["debris"]`); some are real, mineable asteroids ("loose rock").
- **Colossal asteroids** ("Colossus K-17", up to ~2,800 km long) in all three classes – *metallic* (dark
  iron, glowing metal veins, glints), *stony* (ochre strata, dense crater fields) and *icy* (bright ice,
  blue crevasses, frost sparkle, halo). They lie inside asteroid fields, usually in groups of two or three,
  ringed by richer rim rock, and are not listed on the system map. Three shape families
  (`scripts/core/colossus_shape.gd`): elongated *potato*, *contact binary* (two lobes and a neck) and
  angular *shard* with flat facets. The same outline polygon is drawn by the shader
  (`shaders/colossus.gdshader`, lit by the star, pixel detail adapts to the zoom) and used for collisions,
  radar shadow and cover. They are in the **foreground**: ships cannot fly through them (autopilot follows
  the surface around them), and the rock turns see-through while you hug it.
  - **Radar shadow:** a colossus blocks the line of sight. Nothing behind it shows on the radar (Recon
    zoom draws the shadow cone), cannot be locked, and existing locks break when the target slips behind it.
    Pirates obey the same rule – hide behind a colossus to break contact.
    A rock lying completely in the shadow of a nearer one does not show on the radar either.
  - Autopilot and NPCs keep a safety distance (~300 km) from the surface, go round one side until
    clear and switch sides or pick a new patrol point if they make no progress.
  - **Cover:** projectiles burst on the rock, beams hit the surface instead of the target.
- **Refining** (`scripts/core/industry.gd`): every ore has its own product (ingots, silicon,
  aluminium, rare earths, deuterium, helium-3, cryo coolant …). Efficiency depends on station type
  *and* asteroid class: mining colonies are best for metallic/stony, agricultural stations only
  process ice. The market has filter tabs (local economy, in hold, goods, metallic, stony, icy).
- **Manufacturing**: each station type fabricates certain slot categories. Recipes are derived from the
  module's value and slot mix; large modules need xeno lattice. Inputs the station itself produces
  lower the fee. Finished modules go to station storage.
- **Contracts** (`scripts/core/missions.gd`): courier (sealed cargo to another station), bounty
  (kill pirates in a system), supply (deliver goods here), survey (analyse anomalies). Max 5 active.

## Project layout
```
data/              hulls, modules, commodities (+ station types), presets, corporations, factions, pirate_archetypes,
                   station_services, pixel_art (ships), module_icons
scripts/autoload   GameData, Universe (galaxy, system layouts, warp targets), GameState (fleet, hangar, missions, stats),
                   Commands (command bus), SaveGame (saves, settings, scene flow)
scripts/core       ShipFitting, PixelArt, StationArt, CrestArt, ColossusShape, ConvoySim, Industry, Missions, Reputation, Law, Notorious
scripts/world      SystemView, Traffic, Ship, Celestial, Projectile, Fx, SpaceBackground, TransitOverlay
scripts/ui         HUD, ShipMenu, GalaxyMap, MainMenu, PauseMenu, SaveBrowser, SettingsPanel, UI helpers
scripts/ui/station StationUI (concourse) + one panel script per service
shaders/           planet, star, colossus, background, hyperspace, scanlines
```

## Performance rules (0.6.41.5)

The game logic runs on one CPU core; rendering is cheap. Measured costs came from GDScript `_draw` and per-frame loops:
- Redraw only what is on screen: `SystemView.on_screen(rect)` / `on_screen_at(pos, radius)` (the visible world rect
  of this frame, with a margin). Effects, stations, structures, gates and NPC ships use it.
- No loops over all celestials (~1,700 in a system) every frame – throttle (hover: on mouse move or 10×/s) or test the
  cheap things first (visible, distance).
- Per-ship work that rarely changes (power plan) runs a few times a second for NPC ships.
- Nothing is redrawn that would be a few pixels on screen (`SystemView.cam_zoom`); NPC ships below a pixel are hidden.
- Many small shapes (dashes) go into one `draw_multiline` (`SystemView.dashed_ring`), not one draw call each.
- Measuring: scratch scripts time frames with vsync off and switch parts on and off in turn (A/B).

## Extending
- **New station service**: add an entry to `data/station_services.gd` and a panel script extending
  `StationServicePanel` (implement `build()`). The tile appears automatically.
- **New corporation**: `data/corporations.gd`.
- **New module**: a new family in `data/modules.gd` (anchor values + reference size + size range); every
  size and quality is generated, the icon is picked by slot/type automatically.
- **New hull**: `data/hulls.gd` + pixel art in `data/pixel_art.gd` (+ optional `std_<id>` preset).
- **Points of interest / dungeons**: new entries in `Universe.warp_targets()`.

## Roadmap
Solo-playable, co-op shared world with optional PvP. Phase 0 (menu, save/load, command bus) is done;
next is phase 1: a network prototype (host + client with ENet).
