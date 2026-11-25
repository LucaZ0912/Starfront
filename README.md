# Spacefarer: Beyond the Veil

_(Until 17 Nov 2026 the game was called Sternenfront.)_

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
- 0.7.51.1 (package 51): `data/gear.gd` – `SUITS`, `WEAPONS`, `BELT`, `FEATURES` (ids `<family>:<quality>`,
  consumables and grenades without), `stats(id)` / `describe(id)` / `all_ids()`, `LAYER_MULT` (shield → armour →
  health); `scripts/core/pilot_gear.gd` – `PilotGear` (`GameState.gear`: suit, weapons, belt, features, inv, lockers by
  ship uid, health/energy/oxygen/ammo; `totals()`, `equip_from_inv`, `unequip`, `store`, `fetch`); pilot window tab
  `TAB_GEAR` (`_gear`, `_locker_fit`).
- 0.7.51.2: service `gear` (corp `fkt`, `scripts/ui/station/gear_panel.gd`), `scripts/core/gear_shop.gd` – `GearShop.offer(st)`
  (cached in `st._gear_offer`), `sells`, `SELL_SHARE`; commands `gear_buy` {id}, `gear_sell` {slot}; `DeckGen.SHOPS` /
  `SettleGen.SHOPS` with `gear` (`SettleGen.TW` 76, `W` 104); `ChibiArt.frame` reads `look.suit` / `look.helmet`
  (`_blend`), `Walker.slung`, `GroundView.pilot_look()` / `needs_helmet()` / `_slung()`.
- 0.7.51.3: `GearData.ENV` / `env_of(type)` / `needs_helmet(env)`, `LIFE_SUPPORT`, `EXPOSURE_HURT`, `SUFFOCATE`;
  `PilotGear.env_step(delta, env, sprinting)`, `speed_mult`, `use_belt(i)`, `charge()`, `aboard()`, `stim_t`;
  `GroundView.env`, `indoors()`, `_env_step`, `_collapse` (used {kind "collapse"}), `use_belt`, `_outside_look`, zone
  kind `charge`; `scripts/ground/suit_hud.gd` – `SuitHud`; `main` calls `gear.aboard()` at landing, decks, take-off.
- 0.7.51.6: `BuildArt` sci-fi only – `ARCHES` hab/stack/hall/dome/terrace/spire/module/sinter (`ALIAS` maps the old
  names), `o.sealed` (portholes, `_airlock`), `_armour` / `_composite` / `_stone` / `_printed` walls, `_curtain`,
  `_hex_crown`; `SettleGen.sealed` (set by `build` from `Universe.has_atmosphere`), `_arch` by power and world;
  `ObjArt` stall, signpost, cable_pole, lookout, target and decals `awning`, `boardwalk` rebuilt.
- 0.7.51.11: `DeckGen.build_clinic(station, available)` (`CLINIC_W/H`, `_clinic_look`), level `clinic` in
  `GroundView.go_level` and the lift menu, zone id `wake` (`_clinic_spot`), `wake_in_clinic()` goes there; `clinic`
  left `DeckGen.SHOPS`, `look` skipped in the shop row where there is a clinic; objects `med_bed_occ`, `med_pod`,
  `med_cabinet`, `sculpt_chair`, `holo_bust`; `debug_ground_level` takes `clinic`.
- 0.7.51.13: zone id `xray` behind the clinic's `med_pod` – `GroundView._xray_step()` sets `Walker.xray` (drawn with
  `ChibiArt.skeleton(dir, f)`, above the scanner glass).
- 0.7.51.10: `ChibiArt` – `_armour` (combat plates), `_suit_detail`, `_helmet` (closed visor helmets, EVA helmet with
  gold visor, work helmet), `LIVERY` {power: [plate, light]} via look `livery`; gloves; `PilotGear.helmet` ("auto" /
  "always", saved) and `combat_t`; `GroundView.pilot_look()` uses both; guards in `_add_guards` wear
  `suit_mil_light` / `suit_mil_heavy` with their power's livery.
- 0.7.51.8: `gear_panel.gd` – static `view` ("" front, a category, "sell") and `group`; `CATS` (category → kinds →
  families), `front_height(view_h)`, inner class `ShopArt` (the drawn picture tiles: kind suit/weapon/feature/belt/group),
  `_list` / `_row` / `_columns` / `_value`; the front rebuilds when the window is resized.
- 0.7.51.7: `scripts/ui/gear_icons.gd` – `icon(id)` (24×24 by family, cached; preloaded, no class_name); `PilotWindow`
  Gear tab: `_gear` (suit mockup via `ChibiArt.frame`, bars, protection), `_gear_flow`, `_gear_tile`, `_gear_sel_detail`,
  selection `_gsel` {where suit/weapons/belt/features/inv/locker, idx}.
- 0.7.51.4: service `clinic` (corp `mhc`, `requires` "clinic" – not in settlements, `clinic_panel.gd`), command
  `clinic_heal` (`Commands.clinic_price()`), `DeckGen.SHOPS` with `clinic` (object `med_bed`), `GroundView` arrive
  "clinic" / `_clinic_spot()` / `wake_in_clinic()`; `main._wake_at(st)`, `_wake_after_loss` (`GameState.wake_pending`
  after `on_player_ship_lost`), `_fallen()` / `nearest_clinic_city(sys, body)`, `PilotGear.fall()`.
- 0.7.52.1 (package 52, fights on foot): `scripts/ground/ground_combat.gd` – `GroundCombat` (a Node2D in the view's
  world, z 40): the cover grid `cover` (0 none, 1 low – `LOW_KINDS`, 2 high – everything else that blocks; `NO_KINDS`
  thin posts), `sight(a, b)` {blocked, cover, at}; foes `spawn(kind, p, q)` (dicts {w Walker, st, mx, weapon, state
  idle/engage/move/cover/fight/flee/down, aware, goal, path …}), `_foe_step` / `_decide` / `_cover_spot` / `_wake`;
  `locks` (`MAX_LOCKS` 3), `active`, `lock(f)` / `unlock(f)` / `next_target()` / `_auto_lock()` (the nearest when a fight
  starts), `lock_t`; `fire(from, to, w)` (null = the pilot; pellets, shots resolved on arrival in `_resolve` – a dodge
  turns a hit into a miss), `_explode`, `_hurt_pilot` (`Commands.suit_god` holds it off) / `_hurt_foe`; `dodge(dir)`,
  `dodge_charges`, `max_dodges()` (Athletics), `swap_weapon()`, `weapon_i`, `in_cover`, `frozen`, `show_ai`, `kills`;
  `GearData` – `apply_damage(st, dmg, dtype)`, `hit_chance(w, firearms, dist, cover, moving, t_athletics, stim)`,
  `COVER_CUT`, `COVER_NEAR`, `SHIELD_WAIT`, `SHIELD_ENERGY`, `DODGE_*`, `LOCK_TIME`, `SHOT_SPEED`; `ft_jets` `dash` is a
  multiplier now (`dash_energy`); `PilotGear.shield` / `armor` (saved), `shield_wait`, `take_damage`, `shield_step`;
  `data/foes.gd` – `FOES` (bandit scrapper/rifleman/gunner/boss: suit, weapon, quality, firearms, athletics, role, flee,
  look), `DAMAGE` (foes' share of their weapon's damage), `SIGHT`, `HEAR`; `scripts/ground/combat_hud.gd` – `CombatHud`
  (lock cards, HOSTILES, cover line under `SuitHud.bottom_y`, weapons with dodge charges); `SuitHud` shows the shield
  and the new Armour bar as they are; `Walker.aim` / `aim_dtype` (the weapon in the hands, `_draw_aim`), `down`;
  `scripts/ground/arena_gen.gd` – `ArenaGen.build(body, site, len, beam)` (site `arena`, `foes`), `GroundMap.foe_spawns`;
  `ObjArt` kinds `barrier` (low) and `bulwark` (high); `GroundView.combat` / `combat_hud` / `combat_allowed()` (the arena
  only), `_on_click` (left: lock, right: let go), `_collapse(reason)` → `main._fallen(reason)` ("fight"); keys
  `foot_target` (Tab), `foot_dodge` (Space), `foot_swap` (Q); commands `debug_arena` {world, foes, body}, `debug_foe`
  {kind, n, quality, near}, `debug_combat` {do kill/end/freeze/ai/hurt}; codex `basics_foot_combat` (event
  `foot_fight`); skills Athletics and Firearms work; smoke group `foot_combat`.
- 0.7.52.2: `GroundCombat.tactics` (0 off, 1 your sight, 2 the target's – `tac_viewer()`), `cycle_tactics()`,
  `cast(from, reach)` (`TAC_RAYS` rays, lit stretches – high cover ends a ray, low cover and `COVER_NEAR` behind it
  break it), `lit_in(rays, from, p)`, `_vis` cache, `tac_node` (drawn on the ground under `_sorted`); `GroundView`
  `_tab_held` / `TAB_HOLD` (tap cycles, hold closes); keys `foot_target` R, `foot_tactics` Tab (`Keybinds.LAYOUT` 5,
  `LAYOUT_RESETS` "foot_"); `debug_combat` do `tactics` {mode}.
- 0.7.52.3: `scripts/ground/weapon_art.gd` – `WeaponArt.art(family)` {tex, grip, muzzle, len} (pixel pictures per weapon
  family, outlined, cached); `Walker.aim_weapon`, `aim_geom(bob)` {hand, ang, scale, art, muzzle}, `_draw_aim`,
  `muzzle_art()` – `GroundCombat.fire` starts every shot there; `FoeData.DAMAGE` 0.12, `FOES[*].health`;
  `GroundCombat.tac_reach()` (both tactical views at the weapon in hand's range, ring labelled).
- 0.7.52.4: `FoeData.TIERS` (green/yellow/red: health, damage, firearms, quality, col), `TIER_ORDER`, `tier_quality(q, tier)`,
  `parse("kind@tier")`; `GroundCombat.spawn(kind, p, quality, tier)` (foe dict `tier`, `dmg`), the ring drawn in
  `_draw_tactics` on `tac_node`; arena site `foes` and `debug_arena` take "kind@tier", `debug_foe` takes `tier`.
- 0.7.52.5: `FoeData` – kinds `pirate_*` / `guard_*`, fields `livery`, `grenades`, `aim`, `rof`, `sight`; `ROLES` / `ROLE`
  {pref, cover}, `GRENADE_CAMP`, `THROWER_CAMP`, `MORALE_BREAK`; `ChibiArt.LIVERY.pirate`; `GroundCombat` – `_decide`
  by role, `_decide_flank`, `_leader_of`, `_cover_spot(…, leader, rad)`, morale in `_hurt_foe`, `camp_t`; grenades
  `grenade_press(i)` / `grenade_release()` / `throw_grenade(from, at, id)` / `_detonate`, `THROW_RANGE`, `gr_hold`,
  `gr_aim`, `aim_at`, `grenades`, `clouds` (`smoke_between`, `SMOKE_CUT`), `domes` (`dome_between`), `blast_share(at, p, r)`;
  the sniper's aiming line in `_draw`; `GroundView.mouse_art()`, belt keys press/release; `debug_gear` {grenades};
  smoke group `foot_tactics`.
- 0.7.52.6: `GroundCombat.cast` – rays end at shield domes seen from outside, stretches carry a smoke flag
  ([t0, t1, smoked], drawn grey and hatched); `dome_between(a, b)` – any shot from outside crossing a dome; the red view
  (`_tac_source`) at the foe's weapon's range.
- 0.7.52.7: `_draw_tactics_view` draws the shadows (gaps between lit stretches, out to the reach) in the other side's colour
  (`shade`), smoke stretches yellow.
- 0.7.52.8: `GroundView.zoom` / `tac_zoom` / `TAC_ZOOM_OUT` (`_world.scale`, eased in `_camera`; `mouse_art` and clicks divide by it),
  wheel in `_on_click`, key `foot_zoom` (Z); `debug_combat` tactics {zoom}.
- 0.7.52.9: suits' `grenades` places; `GearData.is_grenade(id)`, grenade stacks 10; `PilotGear.grenades` / `gr_sel`,
  `grenade()`, `next_grenade()` (equip routes grenades there; saved); `GroundCombat.grenade_down()` / `grenade_up()` /
  `grenade_aiming()` / `GR_HOLD`, `nearest_target()`, the bars over foes in `_draw`, softer `shade` / `smoke_col`;
  keys `foot_run`, `foot_belt_1..4`, `foot_target_near` (Shift+R), `foot_grenade` (X) – `Keybinds` descriptors take
  `shift`, `LAYOUT` 6; `KeybindPanel.tab` "space"/"ground" (`_set_tab`, `_shift_pending`, `_bind`).
- 0.7.52.11: `GearData.DRONES` / `DRONE_KINDS` (kind "drone": laser heat/heat_max/cool, kinetic mag/reload, kamikaze
  radius; shield, armor, rebuild, speed), suits' `drones` place; `PilotGear.drones`; `scripts/ground/drone_art.gd` –
  `DroneArt.art(kind)` / `draw(ci, kind, at, hover, t)`; `GroundCombat.drone` {is_drone, id, kind, pos, alt, st, mx,
  state launch/hover/return/reload/dive/down, heat, over, ammo …}, `drone_rebuild`, `drone_recalled`, `drone_id()`,
  `drone_alive()`, `drone_command()`, `_drone_step`, `_drone_fire`, `_hurt_drone`, `_chance_at_drone`, `_draw_drone`;
  `fire()` takes the drone as a target, `_explode(…, spare_pilot)`; `CombatHud._draw_drone_panel`; key `foot_drone` (C);
  `debug_gear` {drone}, `debug_combat` do drone_kill / drone_ready; smoke group `foot_drones`.
- 0.7.52.12: drone states `docked` (on the back, off) / `dock` / `launch` / `hover` / `return` / `reload` / `dive` / `down`,
  `drone_flying()`, `_drone_make`, `_drone_up`, `drone["head"]` (turned in `DroneArt.draw(…, heading)`),
  `DroneArt.draw_docked(ci, kind, back, dir, sc)`; `PilotGear.charge()` fills the rounds too (supply points, aboard);
  zone title "Supply point – energy, oxygen and ammunition".
- 0.7.52.13: `SuitHud.tile(ci, rect, icon, key, name, sub, border, bar, bar_col)` (the belt as tiles), `CombatHud._draw_tiles`
  (weapons, grenades, drone), `_label`, `_draw_dodges`; `GroundView._log` / `log_event(text, col)` (bottom right;
  `_say_toast` and `GameState.message` go there), `near_zoom` / `ZOOM_NEAR` / `zoom_step(d)`.
- 0.7.52.14: suit `suit_mil_pathfinder` (`faction`, `builtin` "wp_arm_laser"), weapon `wp_arm_laser` (`builtin`, `pierce`,
  `charge`); `PilotGear._fit_slots` puts a suit's built-in weapon in the first place (it never goes to the pockets),
  `unequip` refuses it; `GearShop.offer` – a power's own suit only in its lands; `gear_buy` – only for Friendly pilots;
  `ChibiArt._pathfinder` / `_pathfinder_helmet`, look `arm_up`; `WeaponArt` "wp_arm_laser" (the raised arm),
  `Walker.aim_geom` raises it from the shoulder; `GroundCombat.arm_charge`, `arm_laser_id()`, `arm_charge_k()`,
  `arm_raised()`, `_arm_step`, `_fire_arm` (shot kind "armbeam"); `CombatHud._charge_frame`; smoke group `foot_pathfinder`.
- 0.7.52.15: sound `w_arm_laser` (tools/audio/make_placeholders.py, docs/audio/sound_list.md); the "armbeam" shot carries
  `cuts` (where it enters cover) – `_fx_step` sprays sparks there while it lasts, `_draw` makes them glow.
- 0.7.53.1 (package 53a): `data/poi.gd` (THEMES, DANGER, TARGETS, MAP_CHANCE, `site_name`), `scripts/ground/dungeon_gen.gd`
- 0.7.53.2 (package 53a rework): `DungeonGen.build_outside` (the ruin's facade in the north, `ruin_gate` with lock open/panel/computer, zone `dungeon_in`) and `build_inside` (zone `dungeon_out`, `rust_door`, `crystals`, EMP/cache panels); GroundView level `dungeon`, `_poi_map` keeps both maps per site; `GroundMap.style` ("precursor": rusted floors fk 17, faces, dark caps); `scripts/ground/fog.gd` (fog bands, `burst`); `GroundCombat.emp`; `GameState.museum_finds`; theme data in `data/poi.gd` (`THEMES`, `MUSEUM_RELICS`).
- 0.7.53.3 (package 53b): theme structure and layers in `data/poi.gd` (`cols`, `rows`, `room_chance`, `corr`, `canal`, `loops`, `cover`, `layers`, `PoiData.layer(theme, depth)`, `levels`), theme `sewer` (sewer above, `hideout` below); `DungeonGen.build_inside(body, site, depth)` (junctions, canal, flood, tripwires, hatch/ladder, dealer office), `build_alley`, `site_targets`; floors 18–23 and styles `sewer`, `hideout`, `alley` in `GroundMap`; ExploreNode kinds `grate_door`, `steel_door`, `keypad`, `valve`, `tripwire`, `ladder`, `hatch`, `manhole`, terminals `pump`, `dealer`; GroundView `depth`, level `alley` (city lift), zones `dungeon_down`/`dungeon_up`, `_drain`, `_wires_step`, `_wade`, map meta `dark`/`seen`; `GameState.city_poi`.
- 0.7.53.4: theme key `descent` ("lift" / "hatch"), `stores`, DANGER `cap`; `DungeonGen._ancient_lift`; ExploreNode `ancient_lift` (`_draw_ancient_lift`, `sink`); GroundView `_sink`, `_sink_step`, `_lift_here`, effect and hack action `lift`.
- 0.7.53.5: theme keys `turret`, `alarm`; ExploreNode `turret`, `alarm`; GroundView `_turrets_step`, `raise_alarm` (also on a traced hack and a tripwire).
- 0.7.53.6: theme `wreck` (`spine` layout, `descent` "hole", `hulls`), `DungeonGen.build_wreck_outside` (`ship_edge`, `ship_covers`, map meta `wreck`, `plumes`), `shaders/wreck.gdshader`, GroundView `_add_wreck`, `_hazards_step`, `_open_power_menu`/`_route_power`; ExploreNode `breach`, `airlock`, `bulkhead`, `blackbox`, `generator`, `conduit`, `gas`, `deck_hole`; floor 24, style `ship`, decals `furrow`, `crater`, `debris`; ObjArt `container`, `locker_down`, `seats`; FogNode `plumes`.
- 0.7.53.7: theme `mine` (`rails`, `rubble`, `descent` "cage"), `DungeonGen.build_minehead`, `_corridor(..., rails)`; `GameState.settle_poi`; SettleGen zone `mine_path` (meta `mine_path_front`); GroundView level `minehead`, `_fuses_step`, `blast_near`, `shot_lands` (called by GroundCombat), `_take_one`; ExploreNode `cage`, `mine_gen`, `vein`, `rubble`, `loose_rock`, `tnt`, `mine_gate`; floors 25–27, style `mine`, decal `rails`; ObjArt `shaft_house`, `winding_house`, `ore_bin`; `PoiData.MUSEUM_RELICS["mine"]`.
- 0.7.53.9: theme `maint` (`descent` "stairs", `outside` "lift", `passive_foes`), FoeData `maint_drone` (`drone`), GroundCombat passive/provoked foes; GroundView `_town_kind`, `_drones_step`/`_draw_drones`, `_restart_reactor`, city lift level `maint`; `GameState.maint_sites`/`maint_site`; ExploreNode `crank_door`, `fuse_box`, `reactor` (`_draw_reactor`), `stairs_down`, `stairs_up`, `service_lift`, `steam`; style `maint`; ObjArt `valve_box`, `cable_drum`.
- 0.7.53.11: theme `pirate` (`outside` "cliff", `hangar`, `cells`, `descent` "ramp", target `loot_room`), `DungeonGen.build_cliff`, `parked_covers`, map meta `parked`; `scripts/ground/parked_art.gd` (a ship made plastic: height from its outline, lit); ExploreNode `pirate_gate`, `searchlight`, `ramp_down`, `cells`; style `pirate`, face decos `skull_banner`, `graffiti`; ObjArt `watchtower`, `glider`, `fire_barrel`.
- 0.8.55.1 (package 55): data/story.gd (`MISSIONS`, `CHARACTERS`, `DIALOGUES`, `TIPS`, `SECRETS`), scripts/core/story.gd
  (`GameState.story`: `start`, `event`, `set_flag`, `tip`, `find_secret`, `track`, `keys`, `goal_lines`, signals `show`
  and `changed`; events from docking, jumps, locks and "near" goals), `StoryUI` (scripts/ui/story_ui.gd: dialogue with
  pause, radio, tips, tracker, marker), the pilot window's Journal tab (`TAB_JOURNAL`, `jsub`, `jsel`), key `journal`
  (O), commands `story_track`, `story_tips`, `debug_story`; smoke group `story55`.
- 0.8.58.1 (package 58, part 1): `scripts/ground/dan_work.gd` (phases `board` → `tour1` → `tour2` → `part2`, flag
  `w58_phase`; static `give_ship`), `scripts/ui/guided_tour.gd` (steps with `key`, `title`, `text`, `task`, `hint`;
  `tour_confirm`, layer 28, `menu_nav_blocked`); StationUI `tour_targets`, `_box_of`; ShipFitting `paint`, `lent`
  (saved); PixelArt `paint_key`, `fleet_texture`; StoryUI `radio_held` (`until_flag`, `until_step`, `until`),
  `radio_scale`, `radio_avoid`, `radio_typing`, `radio_finish_typing`, its own layer 30; Traffic `_convoy_call`;
  character `convoy_pilot`; mission `darling`; main `_start_dan_work`; smoke group `w58a`.
- 0.8.58.2 (package 58, part 2): dan_work phases `part2` → `drones` → `mine` → `home` → `part3` (`_pick_field`,
  `_warp_steps`, `_drone_steps`, `SCRAP_GOAL`); HUD `tour_targets` (`drone_panel`, `drone_roles`, `drone_modes`,
  `warp_button`, `ov_<id>`), `_mark_objectives`; Pad drone wheel (◯ held: `_circ_t`, `_drone_items`, ids `dw:…`);
  `GameState.crew_hire_locked()` (flag `crew_open`); smoke groups `w58b`, `padshot` (render only).
- 0.8.58.3 (package 58, parts 3–4): dan_work phases `rest` → `part3` → `brine` → `convoy` → `call` → `back` → `party`
  → `maul` → `crew` → `contact` (`ground_mode`, `_story_rescue` via `GameState.story_guard`, `_three_months`,
  `_give_maul`, `_crew_tour`); story mission `fight`; `scripts/ground/quarters_gen.gd` (`rooms`, `build`, `RoomDoor`,
  `CleanBot`), `scripts/ground/sleeper.gd`, commands `room_rent` / `room_sleep`, `GameState.lodging` / `slept`;
  walker `dancing`, `bubble`; ChibiArt frames 4/5 (lying); `PixelArt.rundown_texture` (paint `ossa_rust`); traffic
  `story_ambush`, `caller`; SystemView `cam_off_ship`, `target_ref`; main `ask_city_takeoff`; ship menu
  `tour_targets`; smoke groups `w58c`, `w58d`, `q58`, `cam58`.
- 0.8.58.4 (package 58, part 5): dan_work phases `contact` → `follow` → `listen` → `found` (`_listen_field`,
  `_spawn_hope`, `_hope_wait`, `_clear_field`, `_settle_start` / `_settle_step`, `_listen_start`, `_wave`,
  `_light_pirate`, `_hope_leave`, `WAVES`); `scripts/world/listener_fx.gd`; character `silas`, dialogue `silas_meet`;
  `Audio.stream_once` (loop sounds as one-shots); Drone `_role` (target reset on a role change); debug tab Story;
  smoke group `w58e`.
- 0.8.58.7 (package 58, part 8): `scripts/world/roost.gd` (the Red Talon Roost: parts as anchored pirate Ships with
  `art_draw`, pool, `_open_core`, `_wave` with `MAX_ALIVE`, `_start_boom`, `_BossBar`); Ship `anchored`, `art_draw`,
  `untargetable`, `damage_hook`, `warp_hold`, `ignore_drones`, `_lod_skip` (far NPCs every `LOD_EVERY`-th frame);
  `Universe.story_beacons`; dan_work phase `strike` → `after58` (`_rv_waiting`, `_rv_scene`, `_warp_talk` timed by
  `story_ui.radio_left()`, `_fight_start`, `_allies_step`, `_strike_party`, `_party8_step` / `_party8_end`);
  `MinigameData.SPECIAL` / `specials`, collection key `special`; `GroundView.ask_window`, `GroundMap.bar_rect`;
  smoke group `w58h` (W58H_SHOTS, W58H_PERF).
- 0.8.60.1 (packages 59 and 60): dan_work phases `bar59` → `imre` → `farewell` → `jump59` → `jumped59` → `arrive59` →
  `office59` → `bar59c` → `wake59` → `free` (`_p59_*`, `_cit_run`, `_cit_transfer`, `start_place`);
  `scripts/world/threshold_jump_fx.gd` with `shaders/whirl.gdshader` (modes "in" / "out"; Ship meta `fx_hidden`);
  `scripts/ground/office_gen.gd` (level "office", `office_faction`); `scripts/ui/licence_stamp.gd`;
  `data/acquaintances.gd` (people, events on story flags, `value`, `level`, `add`, `played_with`, `refresh`; state in
  the story's flags `acq_*`), Pilot window tab `TAB_ACQ` with `_AcqBar`; story text `{start_faction_name}`; smoke
  groups `w59a`, `w59b`, `w59c`, `acq60`.
- 0.8.62.31 (package 62a, part 11c): `data/survivor.gd`: the bosses `apex` ("beh" 27) and `mastermind` ("beh" 28), the
  stage's `soft` and `end`, `CORE_BOSS`; `survivor_game.gd`: `_lab_boss_start()` (called by `boss_start` on a stage
  with walls), `_lock_wait`, `_lock_reg`, `_apex()`, `_mastermind()`, `_mind_ring()`, `_hurl()`, `hurls`,
  `_boss_pull`, `_remove_object()`, `_alarm()`; a thrown `mind` passes what stands in a hall; `lab_art.gd`: the
  great tank burst (`seed` 9); `survivor_art.gd` `_apex`, `_mastermind`; smoke test group `collabc62a`.
- 0.8.63.1 (package 63): hulls `ew_190sl`, `aur_mistral`, `aur_soleil`, `aur_sovereign` (`data/hulls.gd`) with the new
  traits `boosts`, `jump_fuel_mult`, `multi_drive`, `hatch_chars`, `casino_prize`; standard fits `std_<hull>`; their
  pictures come from `tools/art/package63_art.py` (writes into `data/pixel_art.gd` before `# PACKAGE63_END`; `--show`
  prints, `--mock` renders sheets into `Claude outputs`); palette chars `i % W` (obsidian), `=` and `<` (the pulsing
  gold line, animated in `PixelArt._animate`), `+ - _` (chrome); `Ship.boost_used`, `boost_max()`, `boost_left()`;
  command `prize_buy` and `GroundView._ctr_prize()`; `GameData.fmt_int()`; smoke group `ships63` (pictures of the
  four in flight with `SHIPS63_SHOTS=1`).
- 0.8.64.1 (package 64a): `GameState.tree_locked()` (story flag `intro_stage` without `cit_licence`) shuts
  `tile_ready()` and `tree_unlock()`; `GameState.tree_start_over()` (called at the stamp in `dan_work.gd`) empties the
  tree and erases every key of `TreeData.METRICS` from `GameState.stats`; the Pilot window's `_tree()` shows a note
  while it is shut; smoke group `tree64a`. The plan of package 64: `Claude outputs/steckbrief_64_centauria_einfuehrung.md`.
- 0.8.64.2 (package 64b): `GameState.fern_closed()` and `entry_error()` (Fern until the story flag `fern_called`);
  `dan_work.gd`: `_fern_lead()` (every frame in the phase "free"), `_fern_meet()`, `_lead_walk()` (Rook's walker
  along `GroundMap.path` to a named point of the level, `FERN_SAY`, `FERN_BEHIND`), the flags `fern_radio`,
  `fern_rook`; `ground_mode()` puts Rook on `zplaza`, `zalley` and `zbar`; a story person's place may be
  `{"meta": name, "off": tiles}` (a named point of the level); dialogues `rook_fern`, `luz_meet`, `luz_again`;
  command `debug_fern`; smoke group `fern64b` (pictures with `FERN64_SHOTS=1`).
- 0.8.64.3 (package 64b): `CityStyle.story_night` (a city by its name held in the night) and `Weather.story_place`
  / `story_kind` (the story's weather at a place; `Weather.debug_kind` goes before it), set by
  `dan_work._fern_weather()` and cleared in its `_exit_tree()`; `debug_fern` with "land", "stairs", "alley", "bar",
  "done" (`Commands._debug_fern_land()`).
- 0.8.64.4 (package 64c): `dan_work.gd`: `_luz_job_step()` (every frame in the phase "free"), `_luz_brief()`,
  `_luz_report()`, `_luz_spawn()`, `_luz_fail()`, `_luz_got_away()`, `_luz_show()` (the display), `luz_foe()`,
  `luz_marked()`, `luz_rv_pos()`, the constants `LUZ_*`; flags `luz_job`, `luz_sys`, `luz_rv`, `luz_data`,
  `luz_away`, `luz_done`; the mission `luz_test`; the waypoint `luz_rv` in `Universe.story_beacons` (put back when
  missing, they are not saved); the convoy's ships carry the meta `luz_convoy`, no `gov`, `provoked`; story texts
  know `{foe_name}` and `{luz_sys}`; `debug_fern` with "job", "job_given", "job_rv", "job_away", "job_done"; smoke
  group `luz64c` (pictures with `LUZ64_SHOTS=1`).
- 0.8.64.5 (package 64d): `dan_work.gd`: `_luz_party()` (`_party64`, the bar's `ground_mode()` for it), flag
  `luz_round`; the round's jobs: the story flag `rj` (a dictionary of numbers and words: kind, who, sys, seed, pay,
  foe, stage "go" / "deliver" / "back", brief, back, stn), `rj()`, `rj_offers(who)`, `rj_take()`, `rj_drop()`,
  `_rj_step()` (every frame), `_rj_spawn()`, `_rj_pay()`, `rj_marked()`, `_round_talk()` (through
  `GroundView.ask_window`), `_bcn_on()` / `_bcn_off()` (a story waypoint, ids `rj_rv`, `rj_loot`), constants `RJ_*`;
  the mission `round_job` with the text keys `{rj_brief}` and `{rj_back}`; `debug_fern` with "party", "round",
  "rj_intel", "rj_raid", "rj_smuggle", "rj_rv", "rj_back", "rj_drop" (`Commands._debug_ship_to()`); smoke group
  `round64d` (pictures with `ROUND64_SHOTS=1`).
- 0.8.64.6 (package 64e): `CentauriaGen.build_luzroom()` (level `zroom`, `RoomFx`: the wall and the window with
  the street, `R_WIN`), `build_stairs()` (level `zstair`, `StairFx`; arrivals `from_below` / `from_above`); the map
  meta `zoom` (a level's own camera zoom); `GroundView._stair_step()` / `_stair_done()` (the walk), zone kinds
  `room_bed` (`_room_sleep_begin()`, command `luz_sleep`, story flag `luz_slept`) and `room_window`
  (`_room_watch`); the bar's zone `bar_back` leads up once the story flag `luz_room` is set; `dan_work`:
  `_luz_show_room()` (`_room64`), dialogue `luz_room`; `ObjArt`: `q_bed` with `shabby`, the kind `floor_mess`;
  `debug_fern` with "room"; smoke group `room64e` (pictures with `ROOM64_SHOTS=1`).
- 0.8.64.7 (package 64f): `ColData.story_mate_open(id)` (the story flag `<id>_mate`; `mates()` leaves the others
  out); `dan_work`: `_rook_col_step()` (after the flag `luz_slept`), `rook_waits()`, `_rook_col_talk()`, the flags
  `rook_invited` and `rook_mate`, the mission and the dialogue `rook_col`; `debug_fern` with "col_invite" and
  "col_done"; smoke group `rook64f` (a picture with `ROOK64_SHOTS=1`).
- 0.8.64.8 (package 64g): `MinigameData.SPECIAL` with `luz`, `ratte` (billiards), `rook`, `kraut` (darts), found
  by the story flag `luz_bar_st` (Centauria's id, set by `dan_work._bar_flag()`) from the flag `luz_round`;
  `MinigameData.luz_place()` and `LUZ_SCORE` (the top row of `arcade_board()` there); smoke group `games64g`.
- 0.8.75.21 (the narrow layout): `UI.NARROW_W` (1200), `UI.narrow(node)` (is its picture narrower?),
  `UI.wrap_long(root)` (every line of text too wide for the half wraps). `PilotWindow` and `ShipMenu`: `_narrow()`,
  `_nw(wide, narrow)` for a measure that depends on the picture, the frame's margins set in `_rebuild()`.
  **Rule for a new page:** no fixed width without `_nw(…)`, and run `--only=winlook` (in a window) before it is
  done: it must name no page. The group saves "Claude outputs/winlook_<page>_<w>x<h>.png".
- 0.8.75.20 (their ship menu, their map): `ShipMenu.seat` and `GalaxyMap.seat` (open, rebuild / refresh and the
  map's drawing run in `GameState.with_seat(seat, …)`); `main.ship_menu2`, `galaxy2`, `_win2(kind)`,
  `_toggle_two(kind)` (one of theirs at a time), `GameState.ship_along()`. `Players.win_key(seat, action)` (a
  window's word for a key or button), `Players.button(seat, name)` (a controller button by its name; the smoke test
  presses it as `"1:btn:r1"`). The second player's menu driver hands a window that reads the controller itself its
  `pad_button` and `pad_stick` (the galaxy map).
- 0.8.75.19 (a window in its player's half): `scripts/ui/win_half.gd` (a SubViewportContainer per player over
  their half, `main.halves`; hidden while empty; passes on only its own player's input and runs it, and the
  `_process` of what stands in it, in that player's name) and `scripts/ui/seat_menu.gd` (the second player's
  controller in their windows: the wheel, steps, confirm, back, tabs, scroll; asked through `Players`).
  `main.halves_on()`, `_halves_step()` (the first player's `pilot_window`, `ship_menu`, `galaxy` move into
  `halves[0]` while the picture is in two and back under main otherwise), `pilot_window2`, `toggle_pilot_window(tab,
  seat)`, `open_journal(seat)`, `win_action()`, `win_back()`, `pause_for()`, `_event_seat()`.
  `GameState.with_seat(seat, f)`. `MenuNav`: a menu belongs to a player (`seat_of(menu)`, `active_menu(seat)`),
  `try_key()`, and a menu in a half keeps its own highlight (`is_soft`, `current`, `press`, `_light`), because the
  engine has one keyboard focus for the whole game window, across SubViewports. **Rule for a window that shall be
  the second player's too:** give it `var seat`, build it in `GameState.with_seat(seat, …)` (rebuild, and anything
  that runs from a signal, a timer or a draw), write keys with `Players.key_text(seat, …)`, and never read the
  ground's `pilot` for "my figure". `PilotWindow` is done this way; `ShipMenu` and `GalaxyMap` are next.
  `GroundView.two_busy`.
- 0.8.75.18 (the dangers of a place for two): the place's own steps ask about both pilots without changing whose
  turn it is: `GroundView._pilots_up()` (the seats here and on their feet), `pilot_w(s)`, `down_of(s)`,
  `GroundCombat.hidden_of(s)`, `sneaking_of(s)`. Only what happens to one pilot runs in their turn: `_say_to(s, …)`,
  `_hurt_as(s, …)`, `_turret_at()` (a turret's shot carries `seat`). `_hazards_step()` is `_hazards_for(s)` per
  pilot; a trip wire keeps `warned` and `warned2`. **Rule:** a danger never reads `pilot.pos` for "who is there":
  it goes through `_pilots_up()`.
- 0.8.75.17 (the real fight for two): **whose turn it is.** `GroundView.seat_now` and `seat_to(s)`: between
  `seat_to(1)` and `seat_to(0)` "the pilot" is the second player: `pilot` and `two` change places, so do `zone`,
  `_seat`, `_stand_pos` and the vars in `_side` (`col_lost`, `col_down`, `_revive`, `_tab_held`, `_team_held`,
  `_drone_held`, `_socket` …), GameState is theirs (`act_as(seat, true)`: quiet, no signal, the ship stays), the
  fight's own vars are theirs (`GroundCombat.swap_vars()` over `SEAT_VARS`, the other's wait in `_other`), and
  `Pad.device` is their controller. Always in pairs inside one piece of work; never across an `await`, a level
  change or a window that opens. `GroundCombat.with_seat(s, f)` wraps it. `step()` is `_pilot_pre` per seat, the
  foes (`_foe_seat(f)`: the pilot it deals with), `_team_step` per seat, `_pilot_post` per seat. To the other side
  a pilot is `px`, an entry of `allies_up()` (never of `allies`): `fire()`, `_hurt_ally()` and `revive()` hand it on
  to the pilot in their turn. Shots, grenades and the arm laser's beam carry `seat`. `team_up()` is your own team.
  Down: `col_down` (anywhere, not only the hologram), `col_down_start()`, `col_revive()`, `_col_down_step()`,
  `combat.all_down` and `_both_down()`. The second player's step where weapons are allowed: `_two_fight()` (their
  keys asked each frame, the same calls as the first player's events), `_pilot_walk()` shared. Per pilot in the
  picture: `own_node` and `tac_node` on visibility layers 2 and 4, the halves' viewports cull with 1|2 and 1|4.
  `CombatHud.seat`, `combat_hud2`. `GameState.col_own_gear2`. Removed: `spawn_p2`, `p2()`, `_p2_step`, `p2_*`,
  `_split_hud_draw`, `col_revive_k`. **Next with the same means:** the second player's step where no weapons are
  allowed (`_two_keep`'s own walking code) can run under `seat_to(1)` too, and so can the places' dangers.
- 0.8.75.16 (the same parts for both): `SuitHud.seat` (it reads `GameState.gear_of(seat)` and names the belt's keys
  by `Players.key_text(seat, …)`); `Players.key_text(player, action, ctx)`; `GroundView._hint_for(seat)`. The
  split overlay holds the second player's `plate2`, `title2`, `hint2`, `suit2` (a real SuitHud), `prompt2` and
  their own log (`_log2`, `_log2_buf`, `two_say()`; `log_event()` writes there while `GameState.acting == 1`).
  `two_belt(n)`, `_two_env()`. `_split_hud_draw()` now draws only in a fight. **Rule for what comes:** do not build
  a second version of anything for the second player; run the first player's code and display per seat.
- 0.8.75.15 (stage 3, third part): `GameState.fleet2`, `active_uid2`, `storage2` (those of whoever is not acting;
  `act_as()` swaps them with `fleet`, `active_uid`, `storage` and puts the second player's active ship where the
  first one's stands); `fleet_of(seat)`, `storage_seat(seat)` (`storage_of(station_id)` is the older, other
  function); `new_pilot2()` makes the »Wingmate«; saved as `fleet2`, `active_uid2`, `storage2`. On foot
  `_split_hud_draw()` draws the one display for a fight's figure or, where no weapons are allowed, for
  `_two_stats()` (read from `gear_of(1)`).
- 0.8.75.14 (stage 3, second part): `GameState.acting` and `act_as(seat)` swap `pilot` / `pilot2`, `gear` /
  `gear2`, `credits` and `coins` so that all of the game's pilot code works for the second player; `pilot_of()`,
  `gear_of()`, `coins_of()`, `credits_of()` answer by seat whoever is acting; `to_dict()` always saves with the
  first player first. `Players.act_seat` is whose device `Pad` follows. `GroundView`: `two_zone`, `two_seat`,
  `two_use()` (kinds in `TWO_OWN` open as the second player: `two_acting` until every window is shut, then
  `_two_done()`), `two_prompt()`. Smoke group `split9` (pictures with `SPLIT9_SHOTS=1`).
- 0.8.75.13 (stage 3, first part): `GroundView.two` (the second player's Walker where `combat` is null),
  `wants_two()`, `_two_scene()`, `p2_walker()`, `_two_look()`, `_two_keep(delta)` (called first in `_process()`:
  makes the figure, walks it by `Players.move(1)`, opens and closes the split picture); `p2_may_act()` now also
  outside a match. `GroundCombat.step()` spawns the second player with `spawn_p2(false)` (their own `gear2`)
  wherever a fight is set up; outside the hologram they do not die of lying. Smoke group `split8` (pictures with
  `SPLIT8_SHOTS=1`).
- 0.8.75.12 (the second player's own money): `pilot2["credits"]`, `pilot2["coins"]` (set in `new_pilot2()`, read
  back in `from_dict()`), `GameState.coins_of(seat)`, `add_coins(seat, n)`, `credits_of(seat)`. The tables check
  and pay per seat; `roulette_spin` pays seat 1 through `add_coins`; `col_fight_end` and `sv_end` pay both;
  `debug_casino` with `coins2`.
- 0.8.75.11 (stage 2, roulette and blackjack): both games set `two` in `setup()` and seat the second player as
  seat 1 (`"p2": true`, not a guest); `player_seat()`, `stake_sum()`; `_guests_bet()` skips them. Roulette:
  `chip2`, `cur` (the marks), `mouse_seat()`, `_two_step()`; `roulette_spin` merges both players' bets and pays
  the sum. Blackjack: `chip2`, `key_seat()`, `act(seat, what)`, `_two_step()`. Smoke group `split7` (pictures with
  `SPLIT7_SHOTS=1`).
- 0.8.75.10 (stage 2, billiards and darts): `MinigameLobby._two_seat()` (an opponent of kind "p2"; the stake is
  0); `minigame_end` ends such a game without streak or credits. `pool_game.gd` and `darts_game.gd`: `two`
  (the opponent is the second player and split screen is on); billiards `_two_hand()` in the states "aim" and
  "place" of turn 1 (never "ai" / "place_ai"); darts `_hand()` and `_two_pad()`. Smoke group `split6` (pictures
  with `SPLIT6_SHOTS=1`).
- 0.8.75.9: `survivor_game.gd`: `TWO_BACK`, `back_t` (the hold-key revive and `TWO_REVIVE` are gone); the second
  player's touch test goes by `_rad` for bosses; `two_open()` tests at the Mastermind's ring, the Warden's arm,
  the Core's cross, the lines; the barrier clamps `two`. `ground_combat.gd`: `spawn_p2()` takes shield and armour
  from `gear.totals()` and sets `regen`, `speed`, `sprint`, `dash`, `features`, `drone_id`; `_p2_drone_step()`
  (it borrows `_drone_fire()` and `_draw_drone_one()` by swapping `drone`), state `p2reload`.
- 0.8.75.8 (the rest of stage 1): `survivor_game.gd`: `TWO_SWARM`, `swarm_k()` in `_director()`; `give_seat`
  (set in `_crates()`, read in `give()`); `two_open()` and, before every `if can_hurt() and … pp …: _hurt(x)` of
  the stage, the same test at `two.pos` with `two_hurt(x)`; a wave's `hit2`. `Prep.slots()` leaves out
  "features" and "drones" for seat 1. The versus card gets the second player as the first of `mates`. Smoke group
  `split5`.
- 0.8.75.7: `GroundView._split_hud_draw()` draws the second player's whole display over their half (bars, dodge,
  target card, the fight, belt and weapon tiles through `SuitHud.tile`); `_split_key(action)` is the key or button
  of their device; `_split_label()`.
- 0.8.75.6 (Survivor for two after Luz's rules): `run["boni2"]` and `mods2` (the second player's boni and what
  they do), `_remods()`, `two_max()`, `apply_for(seat, card)` (the one way a card goes into an arsenal);
  `run_of(1)` carries their boni and health; `_weapons()` wraps `_weapons_run()`, which sets `mods` to the owner's
  for each weapon. `card_seat` flips after every card (one card a level). `open_draw()` draws for `draw_seat`
  (tests) or by lot, kept in `last_draw_seat`. `SD.second_weapon(col)`, the record's `weapon2`, `sv_weapon` with
  seat 1; `ColosseumUI.SvPrep.seat`, `pick_seat()`, `weapon_of()`. The sidearm is gone.
- 0.8.75.5 (split screen, stage 1, an arsenal each in Survivor): `run["own2"]` holds the ids of the second
  player's weapons; `owner_of(id)`, `owner_up(id)`, `wpos(id)`, `weapons_of(seat)`, `run_of(seat)` (a player's view
  of the run for `SD.offers` / `SD.apply`: their weapons, a `pool_w` without the other's). `_weapons(delta,
  pp_focus)` sets `pp` and `fdir` per weapon from its owner and skips it while they are down. `card_seat` and
  `_offer()` / `pick()` deal a card each per level; `LevelUp.seat` / `who`, polled from `Players` for seat 1.
  The pulse's rings carry their place (`"p"`); the superlaser and the Nova Field are drawn at `wpos()`.
  `Players.pressed()` no longer asks the InputMap for actions it does not have. Smoke group `split4` (pictures
  with `SPLIT4_SHOTS=1`).
- 0.8.75.4 (split screen, stage 1, the second player's gear in a match): the Colosseum's state has `fit2`
  (`col_equip` with seat 1; `col_ready` checks both); `ColosseumUI.Prep.seat`, `fit_key()`, `pick_seat()`,
  `seat_rect()`. `spawn_p2(true)` builds `CD.gear_of(fit2)` and gives the ally `gear`, `weapons`, `wi`,
  `grenades`, `belt`, `energy(_max)`, `ammo(_max)`, `stations`; `p2_swap()`, `p2_grenade()`, `p2_belt()`,
  `p2_station()`, `p2_charge()` on "foot_swap", "foot_grenade", "foot_belt_1…4", "interact". Smoke group `split3`
  (pictures with `SPLIT3_SHOTS=1`).
- 0.8.75.3 (split screen, stage 1, Survivor): `survivor_game.gd` has the second player as `two` (a Walker) with
  `two_hp`, `two_down`, `one_down`, `rev_k`: `two_join()` in `setup()`, `_two_step()` each step (`Players.move(1)`,
  "foot_dodge", the sidearm into `shots`, `touching()` for what hurts them, "interact" beside whoever is down),
  `two_hurt()`, `_one_goes_down()`, `_one_back()`, `_two_back()`, `_two_draw()` from `draw_over()`. `focus_pos()`
  is whom the stage is after (the second player while the first is down); `_hurt()` and `can_hurt()` follow it;
  the view's `story_cam` carries the picture. Smoke group `split2` (pictures with `SPLIT2_SHOTS=1`).
- 0.8.75.2 (split screen, stage 1, matches): `GroundCombat.spawn_p2(arena)` makes the second player a member of
  `allies` with the key `p2` (`p2()`, `p2_up()`); `_ally_step()` hands them to `_p2_step()` (`Players.move(1)`,
  "foot_dodge", "foot_target", "interact" beside the pilot down) and the shared `_ally_shoot()`. The view:
  `_split_open()` moves `_world` into a SubViewport for the left half and adds a second one on the same world with
  a camera on the second player (`_split_step()`, `_split_close()`, `_split_hud_draw()`); `_ui` is narrowed to the
  left half and `CombatHud` measures its parent. `col_down`, `col_down_start()`, `col_revive_hold()`,
  `col_revive()`, `p2_may_act()`. Smoke group `split1` (pictures with `SPLIT1_SHOTS=1`).
- 0.8.75.1 (package 75, split screen, stage 0; Steckbrief `Claude outputs/steckbrief_splitscreen.md`): the
  autoload `Players` (`scripts/autoload/players.gd`, before `Pad`): `split`, `devices` ("kbm" or "pad:<id>"),
  `start_split()` / `stop_split()`, `pad_of()`, `on_keys()`, `owns(player, event)`, and the questions a view asks:
  `pressed()`, `just_pressed()`, `just_released()` (an InputMap action plus the controller's context), `move()`,
  `aim()`; `sim` for tests. `Pad` follows the first player's device only while `Players.split`.
  `GameState.pilot2` / `gear2`, `new_pilot2()`, `has_pilot2()` (saved as `pilot2`, `gear2`; the save's meta carries
  `pilot2`). `SaveGame.start_split(slot, d0, d1, pilot2_data)`, `pilot2_of(slot)`; `start_pending()` switches split
  screen on, `to_menu()` off. The creator's mode "p2". `main_menu.gd`: `_show_split()`, `_build_split()`.
  `scripts/ui/split_view.gd` (preload it): two SubViewports on one world, `cams`, `add_world()`, `set_split()`,
  `to_screen()`. Pictures of the menu: `Claude outputs/_furn/split0.tscn` (windowed). Smoke group `split0`
  (pictures with `SPLIT0_SHOTS=1`).
- 0.8.64.9 to 0.8.64.11 (after Luz's play): the fire group settings list `stats()["locked"]`; `tree_locked()` only
  while the intro runs; `dan_work._convoy_weaken()`, `LUZ_SPAWN`; `_lead_walk()` now leads by itself
  (`_lead_follow()`, `_lead_go()`); `_hub_talk(who)` with the dialogues `<who>_hub`, the answer flag `hub_do`, the
  text keys `{ratte_gossip}`, `{kraut_fact}`, `{luz_music}`, `{rook_talk}` (lists in `data/story.gd`, the drawn
  line in the flags `hub_i_<key>`); `scripts/ui/round_jobs.gd` (`open(ground, dan_work, who)`: the work as one of
  the ground's menus); acquaintances `ratte`, `kraut`, `JOB_POINTS`; `scripts/ground/bar_music.gd` (preloaded as
  `BarMusic`: `TRACKS`, `list_for(level, night)`, `stream(id)` rendered in a thread) and `GroundView._bg_step()`;
  `Claude outputs/_furn/musik.tscn` writes the tracks as WAV; smoke group `music64`.
- 0.8.62.30 (package 62a, part 11b): `data/survivor.gd`: the kinds `trooper` ("beh" 16), `brain` ("beh" 17), `saucer`,
  `LAB_EVENTS`, `LOCK_TIME`, `PURGE_*`, `BREACH_TANKS`, `GRID_*`, `SEAL_FOES`, the item `seal`; `survivor_lab.gd`: the
  map meta `sv_grids`; `survivor_game.gd`: `lock_t`, `lock_r`, `lock_doors`, `seal_t`, `seal_r`, `seal_doors`,
  `purge`, `grids`, `pull`, `hold_t`, `_lab_step()`, `_shut(p, q)`, `_doors_of()`, `_reg_name()`, `_burn_line()`,
  `_breach()`, `_swap_object()`, `_lab_ground()`, `_lab_over()`, `_lab_glow()`, `_field()`; the events `lockdown`,
  `purge`, `breach`; a thrown `ray` with `r2`; `survivor_art.gd` `_trooper`, `_brain`, `_saucer_small`;
  `survivor_ui.gd`: the HUD's notes in the laboratory, the icon `seal`; smoke test group `collabb62a`.
- 0.8.62.29 (package 62a, part 11a): the stage `lab` in `data/survivor.gd` (`STAGES`, `STAGE_DATA`, `LAB_WAVES`, the kinds
  `lgm`, `grey` ("beh" 15), `specimen`); `scripts/ground/survivor_lab.gd` builds its map (`room(c, r)`, `RW`, `RH`,
  `CL`, `CW`; map metas `sv_walls`, `sv_regions`, `sv_links`, `sv_room_ids`); `scripts/ground/lab_art.gd` draws it
  (the map's style `lab`: `floor_tile` for floor kinds 51 and 52, `face_tile`, `cap_tile`, `decal` for kinds
  beginning with `lab_`; the furniture `OBJ_KINDS` through `ObjArt`); `survivor_game.gd`: `walls_on`, `_wall`,
  `_reg`, `_regs`, `_links`, `_hop`, `_hop2`, `_wall_setup()`, `_steer(p, pp, i)`, `_sees(a, b)`, `_free_len`,
  `_reach`, `_bounce`, `_orb_at`, `_sweep_len`, `_sweep_bounce`; `survivor_art.gd` `_lgm`, `_grey`, `_specimen`;
  `survivor_ui.gd` `Intro._vista_lab`; `colosseum_vr.gd`: the hazard look `nutrient`; smoke test group `collab62a`;
  sheets without a window: `Claude outputs/_furn/lab.tscn`.
- 0.8.62.28 (package 62a, parts 10b and 10c): `data/survivor.gd` `rig_tier(col)`, `RIG_STEPS`, `RIG_NAMES`, `RIG_SUIT`
  (the record's `suit`, `rig_force`); `chibi_art.gd`: a look's `sv` (0 … 10) or the suit `suit_survivor` is drawn by
  `_sv_frame` on a canvas padded by `SV_PAD`; `sv_tier(look)`, `glow(look, dir, f)` (four masks of lights), `sv_hue`;
  `walker.gd` `_sv_glow`, `_sv_blade_idle`, `sv_blade`; `ground_view.gd` `pilot_look()` in Survivor; `data/gear.gd`
  `suit_survivor`, `wp_silverblade` (`blade`, `charge`, `time`); `ground_combat.gd` `blade`, `blade_cool`,
  `blade_id()`, `blade_k()`, `blade_flying()`, `_fire_blade`, `_blade_next`, `_blade_step`, `_draw_blade`;
  `game_state.gd` `sv_give_suit()`; `colosseum_ui.gd` `SvPrep.rig_rect()`; debug `sv` values `rig:+`, `rig:-`,
  `rig:auto`, `rig:<n>`, `all`; smoke test group `colrig62a`; the sheet of all steps:
  `Claude outputs/_furn/rig.tscn`.
- 0.8.62.27 (package 62a, part 10a): `data/survivor.gd` `FOE_HOME`, `FOE_INFO`, `foe_home()`, the record's `slain`,
  `settle()` returns `new_foes`; `survivor_game.gd` `_slain`, `slain()`; `pilot_window.gd` `_collection_survivor`,
  `_sv_slain`, `_sv_met`, `_count_text`; debug `sv` value `slain`; smoke test group `colcoll62a`.
- 0.8.62.26 (package 62a, part 9c): `data/survivor.gd` foes `worm` (`beh` 25; `warn`, `erupt`, `erupt_r`, `needle`) and
  `heart` (`beh` 26; `needle`, `strike`, `strike_r`), `EYE_MAX` / `EYE_MIN` / `STORM_DMG`, Whiteout's `soft` / `end`;
  `survivor_game.gd` `_worm`, `_heart`, `_worm_spot`, `_needle_fan`, `_needle_ring`, `_digs` (who can be under the
  ice), `in_storm`, `bst` keys `trail` / `spots` / `si` / `spit` (worm) and `eye` / `tick` / `strike` (heart),
  `boss_info()["under"]`, shells with `zap`, tele kind `zap`; `survivor_art.gd` `_iceworm`, `_stormheart`; smoke
  test group `colwhitec62a`.
- 0.8.62.25 (package 62a, part 9b): `data/survivor.gd` foes `shardthrower` (`beh` 14; `needle`, `fan`, `spread`) and
  `glider` (`chunk`, `chunk_r`), `WO_EVENTS`, `BLIZZARD_*`, `BREAK_*`, `AVA_*`, item `thermal`; `survivor_game.gd`
  events `blizzard` / `icebreak` / `avalanche`, `_wo_events`, `breaks`, `avas`, `blizzard_t`, `in_cover`, mark `fan`,
  globs with `needle`, shells with `ice`, tele kind `thermal`; `survivor_art.gd` `_shardthrower`, `_glider`; icon
  `thermal`; smoke test group `colwhiteb62a`.
- 0.8.62.24 (fixes of 24 Nov 2026): `GameState.on_foot` (in the save), `GroundView.save_spot` / `restore_spot`,
  `main._resume_landed` (a load puts you back where you stood); `survivor_game.gd` `_drop` (a full field: the
  furthest shard comes here), `_wkb` / `_kbk` (a weapon's `kb`), `_blade_dir`, `_danger` (their red round on the
  ground); `data/survivor.gd` `draw_rewards` gives a ready fusion first, weapon key `kb`; `survivor_fx.gd` `hue`
  leaves red out; `SvPrep.press` goes on to the next place; smoke test group `colfix62a`.
- 0.8.62.23 (package 62a, part 10): `colosseum_ui.gd` classes `Choose` (`picked`: "match" | "survivor") and `SvPrep`
  (Survivor's own room: `sv_stage_rect`, `sv_weapon_rect`, `pick_sv_stage`, `pick_sv_weapon`, `move`, `press`, `focus`
  0 stages / 1 weapons / 2 READY); `Prep` lists `modes()` (no Survivor) and has `col_focus` 3 (READY);
  `ground_view.gd` `_col_choose_open`, `_col_prep_open` opens the room of the mode you are in.
- 0.8.62.22 (package 62a, part 7f, the crates): `data/survivor.gd` `crate_roll(run, rng)` (always an item; `CRATE_UP`
  is gone), `DRAW_ODDS`, `DRAW_LUCK`, `draw_count`, `draw_rewards`, each item's `col`, Lucky Find's words and lines;
  `survivor_game.gd` crates with `weapon` (an alpha's, a boss's), `open_crate` / `open_draw(great, count)`,
  `last_draw`, `item_pop` (`ITEM_POP`), `_items`, `nukes`, `scorches`, `heals`, `shield_len` / `stasis_len` /
  `over_len`, `shield_hit`, `_od_tr`, tele kind `stasis`, mark `ovr`; `survivor_ui.gd` class `Draw` (the reels;
  `press`, `stop_at`, `done_at`, `sign_at`), the sign of an item in the HUD; `survivor_fx.gd` `nuke_ground` /
  `nuke_glow` / `nuke_over` (`NUKE_LIFE`), `scorch_ground` (`SCORCH_LIFE`), `shield_dome`, `magnet_over`,
  `heal_over` / `heal_ground`, `stasis_ground` / `stasis_clock`, `overdrive_over` / `overdrive_glow`, `ovr_mark`;
  debug `sv: draw:<n>`; smoke test group `colcrate62a`.
- 0.8.62.21 (package 62a, part 9a, Whiteout): `data/survivor.gd` stage `whiteout` (in `stage3`'s place; each open stage
  has a `col` now), `STAGE_DATA["whiteout"]`, `WO_WAVES`, foes `mite` / `burrower` (`beh` 13; `pace`, `warn`, `erupt`,
  `erupt_r`, `up`) / `rimeback` (`shield`), `ICE_TURN`, `VENT_STEP` / `VENT_R` / `VENT_DMG` / `VENT_TIME` /
  `VENT_REST`, banner `frozen`; `survivor_stage.gd` `_whiteout` (map metas `sv_vents`, `sv_frozen`, `sv_bright`;
  hazard kind `ice` with `look` `floe` and `floes`; decor kinds `track`, `drift`, `hair`, `melt`);
  `colosseum_vr.gd` `VrFx` draws those; `obj_art.gd` `_snow` (an object with `"snow": true`); `survivor_game.gd`
  `_haz` code 3 and `_slide` in `move()`, `_lead`, `vents` / `_vents` / `vent_burst`, crates with `ice`,
  `_under` / `_erupt` (a burrower under the ice is in no cell of the grid and takes no hit), tele kind `erupt`,
  mark `burrow`, `bright`; `survivor_art.gd` `_mite`, `_burrower`, `_rimeback`, `_ice`, `ice_block()`;
  `survivor_ui.gd` `Intro._vista_whiteout`; `survivor_sound.gd` `sv_steam`, `sv_ice`; debug `sv: vent`,
  `sv: stage:whiteout`; smoke test group `colwhite62a`.
- 0.8.62.20 (package 62a, part 7e): `data/survivor.gd` weapon `orbs` (`turn`, `burst`), bonus `gyro` (`mods` `spin`), the
  taser's `reach` and `arc` in place of `r`, the Silver Storm's words; `survivor_game.gd` `_orbs` (in `_storm`'s
  place), `orb_pts` / `orb_out` / `orb_r` / `orbs_t` / `halos`, blades with `u` (the Silver Storm's: for good, their
  trail cuts), `zaps` as cones (`a`, `arc`), `_hue_at`; `survivor_fx.gd` rewritten: `hue`, `rainbow_ribbon`,
  `rainbow_dashes`, `orb`, `orbs_ground`, `halo_ground`, `taser_over`, every ultimate in changing colours;
  icons `orbs`, `gyro`; `Console.items()` and `Prep.sv_weapon_rect` seven to a row.
- 0.8.62.19 (package 62a, part 7d, what you see of your weapons; the flood): `scripts/ground/survivor_fx.gd` (new,
  only drawing: `WCOL`, `number`, `ribbon`, `bolt`, `star`, `flare`, `fill`, the functions of each ultimate);
  `survivor_game.gd` `nums` / `fnum` / `fnc` / `_num` / `_src` / `show_nums` (the numbers of damage), `fxs` /
  `_fx_add`, `drones` / `_drones` / `_drone_fleet` / `shot_n` / `DRONE_GAP`, `foe_cap` / `flooding`, marks on what
  an ultimate throws (`u`, beams' `c` 3 to 6, mines' `g` / `q` / `m`, trails `tr`); `data/survivor.gd`
  `FLOOD_FROM` / `FLOOD_RATE` / `FLOOD_FOES` / `FLOOD_HP`, the Drone's words; `survivor_art.gd` `drone`;
  `debug_casino {sv: "flood"}`; smoke group `colfx62a`.
- 0.8.62.18 (package 62a, part 8c, the bosses of AI Takeover): `data/survivor.gd` (`FOES` `warden` (`beh` 22, `arm`,
  `arm_dmg`, `rocket`, `rocket_r`, `stomp`, `stomp_r`), `core` (`beh` 23, `beam`, `field`), `pylon` (`beh` 24);
  `STAGE_DATA` takeover `soft` / `end`; `CROSS_LEN`, `CORE_LAST`, `FIELD_CELL`, `FIELD_WARN`; `CORE_BOSS`);
  `survivor_game.gd` `_warden`, `_core`, `fields`, `_guard_t`, `_near_line`, `_ray_len`, `_make_room`, `boss_info`
  with `shield`, rockets among `shells` (`rocket`), the clock stands while a stage's `end` lives; `survivor_art.gd`
  `_warden`, `_core`, `_pylon`; `debug_casino {sv: "warden" | "core"}`; smoke group `coltakec62a`.
- 0.8.62.17 (package 62a, part 8b, the rest of AI Takeover): `data/survivor.gd` (`FOES` `bulwark` (`beh` 10, `shell`,
  `shell_r`), `seeker` (`beh` 11, `boom`, `boom_r`, `boom_foes`), `jammer` (`beh` 12, `jam`, `jam_r`), `hunter`
  (flies); `TK_EVENTS`, `STAGE_DATA` `banners`; `SEARCH_TIME` / `SEARCH_LIT` / `SEARCH_R`, `EMP_TIME`, `LINE_PACE` /
  `LINE_GAP`; item `override` with `stage`, `crate_roll` by the run's stage); `survivor_game.gd` `_events`
  (searchlights, shells, pods, kill lines, seekers' bursts, what an Override turned), `fovr`, `shells`, `booms`,
  `lights`, `pods`, `klines`, `emp_t`, `ovr_t`, `_line_parts`, marks `jam` / `arm` / `beam`, warnings `strafe` /
  `override` / `emp`; fixed: `_grid` and the fire in `_ground` no longer look up ground under those that fly beyond
  its edge; `survivor_art.gd` `_bulwark`, `_seeker`, `_jammer`, `_hunter`; sounds `sv_shell`, `sv_emp`;
  `debug_casino {sv: "searchlight" | "reinforce" | "killline" | "emp"}`; smoke group `coltakeb62a`.
- 0.8.62.16 (package 62a, part 8a, AI Takeover): `data/survivor.gd` (`STAGES` with `need`, `STAGE_DATA` /
  `stage_data`, `TK_WAVES`, `kinds_at(t, stage)`, `stage_open`, `cur_stage`, `record` with `beaten`, `settle` with
  `opened`; `FOES` `enforcer`, `scout` (`beh` 8), `gunner` (`beh` 9, `bolt`); `BOSS_BEH` 20); `survivor_stage.gd`
  `_takeover` (meta `sv_decor`, `sv_landmark`); `obj_art.gd` kinds `tank_trap`, `rubble`, `wreck_car`,
  `dropship_wreck`; `ColosseumVR.VrFx.decor`, the `oil` look; `survivor_art.gd` `_enforcer`, `_scout`, `UNIT`;
  `survivor_game.gd` `stg`, `_swarm_k`, marks `aim` / `leap`, bolts among `globs`; `SurvivorUI.Intro._vista_takeover`;
  `debug_casino {sv: "stage:<id>"}`; smoke group `coltake62a`.
- 0.8.62.15 (package 62a, part 7c-4): `data/survivor.gd` weapons `taser` (`stun`), `blackhole` (`speed`, `tough`,
  `from`: the level of a run from which its card comes), boni `capacitor`, `massdriver`; `mods` with `crit`, `kb`;
  `TUNE` `xp` renamed "XP", new `coins` (used in `reward`); `can_begin`; `survivor_game.gd` `fstun`, `stun`,
  `zaps`, `holes`; `debug_casino {sv: "carry:taser" | "carry:blackhole" | …}`.
- 0.8.62.14 (package 62a, part 7c-3, what is round Survivor): `data/survivor.gd` (ten `WEAPONS`, eleven `BONI`;
  `FREE_WEAPONS`, `FREE_BONI`, `UNLOCK_COST`, `TUNE`, `TUNE_ORDER`, `REROLL_COST`, `REVIVE_COST`, `CORE_*`; `record`
  with `cores`, `own`, `tune`, `reroll`, `revive`, `stage`; `owned`, `price`, `buy`, `cores`, `tune_rank`,
  `tune_text`, `progress`; `fresh(stage, weapon, col)` with `pool_w` / `pool_b` / `tune` / `rerolls` / `revive`;
  `mods` with `dur`, `more`, `cell`, `xp`, `luck`); `survivor_game.gd` (`mines`, `sentries`, `cones`, `wells`,
  `ffr`, `spull`, `cell_t`, `face_dir`, `_devices`, `freeze`, `_revive`, `reroll`, `_more`); `survivor_art.gd`
  `mine`, `sentry`; `SurvivorUI.Console` (laid out 1760 by 900, scaled down in a smaller window), `LevelUp.reroll`;
  `ColosseumUI.Prep.sv_stage_rect` / `pick_sv_stage`; lobby prop `svconsole`, zone `sv_console`,
  `GroundView._sv_console`; commands `sv_buy {what, id}`, `sv_reroll`, `sv_stage {id}`; `debug_casino {sv: "cores" |
  "unlock" | "lock" | "carry:<id>" | "carry:ult"}`; smoke group `colmeta62a`.
- 0.8.62.13 (package 62a, part 7c-2, Survivor's stage): `data/survivor.gd` (`FOES` with `beh`, `mass`, `shield`,
  `fly`, `boss`; `FOE_ORDER`, `WAVES`, `EVENTS`, `ALPHA_*`, `FLOCK_*`, `SUPPLY_*`, `SOFT_BOSS`, `BARRIER`, `BANNERS`,
  `ITEMS`, `ITEM_ORDER`, `crate_roll`, `kinds_at`, `foe_hp`); `survivor_stage.gd` metas `sv_crates`, `sv_sleepers`;
  `survivor_art.gd` (`_figure`, `_limb`, a picture per kind, `crate`, `lying`, `SIZES`); `survivor_game.gd`
  rewritten (rows per foe for what it is doing, ways by `beh`, `_director`, `event`, `boss_start` / `_boss` /
  `boss_info`, the walls of light, `crates` / `open_crate` / `give`, `globs`, `pools`, `tele`, `waves`, `quiet`);
  `scripts/core/survivor_sound.gd` (sounds made in code, ids `sv_*`, through `Audio.stream`);
  `SurvivorUI.Hud._stage`; `debug_casino {sv: <kind> | <event> | "foreman" | "brood" | "item:<id>"}`; smoke group
  `colstage62a`.
- 0.8.62.12 (package 62a, part 7c-1, Survivor's look): `SLOTS` 5; `data/survivor.gd` `weapon_lines`, `bonus_lines`,
  `card_lines`, `fusion`, `shard_tier`; `survivor_art.gd` `shard(tier, frame)`; `survivor_game.gd` `Glow` (a node
  that adds light on top of the dark), `draw_glow`, `stier`; `survivor_ui.gd` rewritten (`card_color`, `hexpts`,
  `hex_frame`, `brackets`; `Hud`, `LevelUp`, `Intro` with `_vista`, `Result`).
- 0.8.62.11 (package 62a, part 7b, Survivor's arsenal): `data/survivor.gd` (six `WEAPONS` with `bonus`, `ult`,
  `ult_text`; `BONI`, `BONUS_ORDER`, `ULT`, `bonus_level`, `mods`, `max_hp`, `ult_ready`, `first_weapon`, `progress`;
  cards of kind `bonus`, `bonus_up`, `ult`), `survivor_game.gd` (`_grid`, `touching`, `_fly`, `_zap`, `_storm`;
  `nades`, `blasts`, `shots`, `sweep`, `blades`, `storm_pts`, `nova_r`, `mods`), `survivor_ui.gd` (`Intro`, more
  `icon`s), `colosseum_ui.gd` (`Prep.sv_weapon_rect`, `pick_sv_weapon`); command `sv_weapon {id}`;
  `GroundView._col_enter` (the entrance ends in a fight or in Survivor's stage); `ColosseumData.crowd` goes by
  `SurvivorData.progress` in Survivor.
- 0.8.62.10 (package 62a, part 7a, Survivor): `data/survivor.gd` (`STAGES`, `WEAPONS`, `FOES`, `need`, `spawn_rate`,
  `foe_hp`, `fresh`, `stats`, `level_up`, `offers`, `apply`, `reward`, `settle`, `record`), `scripts/ground/`
  `survivor_stage.gd` (`build(stage, seed)`: 200 x 140 tiles), `survivor_game.gd` (the run: the swarm as packed
  rows `fp`, `fhp`, `fk` …, a grid of cells for the pushing apart, `Band` strips sorted among the figures, `step`,
  `add_foe`, `swarm`, `dash`, `pick`, `end`), `survivor_art.gd` (`texture(kind, look, dir, frame)`), `survivor_ui.gd`
  (`Hud`, `LevelUp`, `Result`); level `zcolsv`, `GroundView.survivor`, `_sv_start`, `_sv_over`, `_sv_done`;
  commands `sv_pick {i}`, `sv_end`; state `GameState.col["sv"]` (`best`, `runs`, `kills`); `VrFx.tw` / `th`; debug
  `debug_casino {sv: "start" | "level" | "swarm" | "minute" | "end"}`; smoke group `colsurv62a`.
- 0.8.62.9 (package 62a, part 5): `data/colosseum.gd` (`SETTINGS` with `hazard` / `danger`, `LAYOUTS`, `layout`,
  `force`; `MATES`, `mates`, `team`, `mate_quality`, `mate_member`, `TEAM_SIZE`; `switch_mode` and `runs` (a run per
  mode), `mode_name`, `sim_win`; `opponents(..., mode)`, `reward(round, mode)`), `colosseum_vr.gd`
  (`build(setting, seed, layout)`, map metas `col_hazards`, `col_haz_state`, `col_lava`, `col_layout`, `live`,
  `ground_at`), `colosseum_ui.gd` (`Prep.pick_mate`, `Versus.mates`); command `col_team {id}`;
  `GroundView._col_hazard_step`, `_col_move`, `_col_fight_sim`, fight state "watch"; an arena ally carries
  `"arena": true` (`GroundCombat`: out at once, the others turn on your team when you are out); debug
  `debug_casino {col_map: id, col_plan: id}`; smoke group `colteam62a`. Part 6 (same version): the arena's wheel
  `GroundCombat.ARENA_WHEEL`, `wheel_fields()`, `wheel_pick(centre, mouse, inner, fields)`, orders `own`, `wing`
  (`wing`, `wing_st`), `cover` (`dug`), `retreat` (`back`, `refill`), `_nearest_foe`, `_hide_spot`; an ally with
  `energy` / `ammo` uses `foe_power` and `_foe_recharge` like a foe; the ground on all: `ground_at`, `_walk`,
  `_reach`, `_safe`, `_off_burn`, `ColosseumVR.weigh` (weights on the path grid); smoke group `colorder62a`.
- 0.8.62.8 (package 62a, part 4): `data/colosseum.gd` (`RANKS`, `rank`, `rank_state`, `allowed`, `crowd`, `BOSSES`,
  `SETTINGS`, `opponents(round, n, salt)`, `foe_of`, `setting`, `reward`, `settle`, `gear_of`),
  `scripts/ground/colosseum_vr.gd` (`build(setting, seed)`, `VrFx`), `colosseum_ui.gd` `Versus`, `Result`; level
  `zcolvr`; foes `col_rusher`, `col_rifle`, `col_gunner`, `col_champion`, `col_boss`; `GameState.col_gear_on()`,
  `col_gear_off()`, `col_own_gear`; command `col_fight_end`; `GroundView._col_intro_step`, `_col_fight_start`,
  `_col_fight_step`, `_col_fight_over`, `col_lost`; debug `debug_casino {col_xp: n, col_fight: "win" | "lose"}`;
  smoke group `colfight62a`. Energy: map meta `col_stations` (`{at, cool, i}`), zones `col_charge`, `STATIONS`,
  `STATION_COOL`, `FOE_RESERVE`; a foe with `energy` / `ammo` (`GroundCombat.foe_power`, `_foe_recharge`); the sound
  `crowd_applause` is made in `scripts/core/crowd_sound.gd` (`applause_db`).
- 0.8.62.7 (package 62a, part 3): `data/colosseum.gd` (`BASE`, `Q_COST`, `START_POINTS`, `PLAY`, `MODES`, `cost`,
  `fit_cost`, `equip`, `options`, `totals`, `opponents`, `reward`), `scripts/ground/colosseum_ui.gd` (`Play`,
  `Prep`), `colosseum_gen.gd` `build_arena`, `draw_arena_ground`; level `zcolar`; `GameState.col`, `col_state()`;
  commands `col_play`, `col_equip`, `col_mode`, `col_ready`; the story's character `marshal` and the dialogues
  `col_marshal`, `col_marshal_back` (flag `col_go`); `GroundView._col_walk_step`, `_col_prep_done`; debug
  `debug_casino {place: "arena", col_points: n}`; smoke group `colprep62a`.
- 0.8.62.6 (package 62a, part 2): `colosseum_gen.gd`: `build_lobby(station, open)`, `build_stands`, `draw_arena`
  (`WAVE`, `TEST`), `ArenaSky`, `ColFx` parts `hall_floor`, `hall_wall`, `st_floor` and props `regdesk`,
  `screenwall`, `barrier` (`open`, `gate`); levels `zcolin`, `zcolst`; `GameState.col_registered`; command
  `col_register`; zones `col_register`, `col_fgate`; the scene `GroundView._col_scene_step`; debug
  `debug_casino {place: "lobby" | "stands", col_reg: bool}`; smoke group `colin62a`.
- 0.8.62.5 (package 62a, part 1): `scripts/ground/colosseum_gen.gd` (`build_plaza`, `draw_colosseum`, `draw_screen`,
  `card`, `FIGHTERS`, the nodes `ColSky`, `ColScope`, `ColFx`); level `zcol`; `RoofFx` and `MetroFx` take any plaza
  (map metas `roof_mid`, `roof_closed`, `ctr_metro_line`, `ctr_metro_stop`, `ctr_metro_tick`); debug command
  `debug_casino {place: "colosseum"}`; smoke group `col62a` (`COL_SHOTS=1` for pictures).
- 0.8.62.4 (package 62b): `data/races.gd` (`clock`, `phase`, `next_open`, `race(n)` made from its number alone,
  `progress`, `standing`, `speaker`, `form`, `odds`, `bet_won`, `due`), `scripts/ground/race_art.gd` (the broadcast,
  drawn), `scripts/ground/race_bets.gd` (a counter), `scripts/ground/race_watch.gd` (a seat in the cinema); commands
  `race_bet`, `race_collect`, `race_wait`; `GameState.race_bets`, `race_shift`; zones `ctr_bets`, `ctr_watch`;
  `CAS_RTP=1` with `--only=casino62` prints what the bets give back over many races.
- 0.8.62.3 (package 62, part 3): `data/casino.gd` (cards as `[rank, suit]`, `new_deck`, `bj_total`, `bj_back`,
  `bj_guest`, `bj_luck`, `hand_value`, `hand_name`, `poker_equity`, `poker_pots`, `poker_ai`, `poker_guests`,
  `POKER_SPECIAL`, `tell_luck`), `scripts/ground/casino_cards.gd` (drawn cards and chips),
  `scripts/ground/blackjack_game.gd` (`bet`, `deal`, `move`), `scripts/ground/poker_game.gd` (`sit`, `move`, `next`,
  `stand_up`, side pots, the rake); commands `bj_bet`, `bj_deal`, `bj_move`, `poker_sit`, `poker_move`,
  `poker_next`, `poker_leave` (with `seat`, for co-op); zones `ctr_blackjack`, `ctr_poker` (`hi`).
- 0.8.62.2 (package 62, part 2): `data/casino.gd` (`spin`, `roll`, `settle`, `bet_pays`, `slot_luck`, `wheel_luck`,
  pay tables, chips, limits), `scripts/ground/slot_game.gd`, `scripts/ground/roulette_game.gd` (seats, `place`,
  `clear`, `spin_result`); commands `slot_spin`, `roulette_bet`, `roulette_clear`, `roulette_spin` (with `seat`,
  for co-op); `GameState.casino_jackpot`, `casino_spins`, `casino_stats`, `casino_rng()`, `casino_book()`; perk
  `lucky_hand`; zones `ctr_slot`, `ctr_roulette` (`hi`).
- 0.8.62.1 (package 62, part 1): `CentauriaGen.build_casino(station, storey, night)` (level `zcasino`,
  `GroundView.ctr_floor`; `CAS_W`, `CAS_IW` (the hall), `CAS_HH`, `CAS_FLOORS`, `CAS_ALT` (heights on the tower);
  metas `cas_floor`, `cas_window`, `cas_views`, `cas_canvas`, `cas_props`, `cas_lifts`, `cas_inlay`, `cas_chandelier`,
  `from_plaza`, the lounge's `cas_terrace`, `cas_pool`, `cas_door`, `cas_dfloor`, `cas_rug`, `cas_pods`, `cas_dark`,
  `cas_open`; zones `ctr_clift`, `ctr_cashier`, `cas_out`), `CasinoView` (the view behind the glass; with `canvas`
  one picture for several windows) and `CasinoFx` (parts wall / inlay / over / prop / lift / pool / terrace /
  tfront / dfloor / club); the lifts: no `map.lifts` there, `GroundView._clift` (the ride's steps),
  `_ctr_floor_go(floor, quick)`, `_cas_doors`, `CentauriaGen.LiftRide` (the ride outside the tower),
  `TowerArt.draw(…, back)`; looks `_staff_look`, `_rich_look`, `_dancer_look`; the plaza's zone `ctr_casino_in` and
  meta `from_casino`; `GameState.coins`, `casino_vip`, `COIN_BUY`, `COIN_SELL`; commands `coins_buy`, `coins_sell`,
  `debug_casino` (`to`, `vip`, `coins`); smoke group `casino62` (shots `cas62_*` under `CTR_SHOTS=1`, the lounge
  and the ride only under `CTR_SHOTS=vip`).
- 0.8.61.5 (package 61d): `GroundView.is_museum_city()` is Centauria; service `paint` (`data/station_services.gd`,
  only in Centauria), `data/paints.gd` (`ORDER`, `PAINTS`, `price`), `scripts/ui/station/paint_panel.gd`, command
  `paint_ship`; PixelArt `shop_paint` (paint keys `pt_…` in `_colors`, `engine_glow`, `paint_key`); the Hall's west
  pavilion (`"shop"` in `hall_pavs`, `HallFx.shop`).
- 0.8.61.4 (package 61b): `CentauriaGen.build_alleys` (level `zalley`; metas `alley_fronts`, `stream`, `from_plaza`,
  `from_bar`; zones `alley_gate`, `bar_in`) and `build_punkbar` (level `zbar`; metas `bar_stage`, `dark`,
  `from_street`; zones `bar_out`, `bar_back`), drawn classes `AlleyFx` (parts `floor`, `wall`, `over`) and `BarFx`
  (parts `wall`, `stage`, `neon`, `prop`; consts `BAR_SPOTS`, `BAND`, metas `bar_band`, `bar_crew`); Walker `stream` (a crowd walking in lanes, out at one end and in at the other);
  story characters `ratte`, `kraut`, `band_voice`, `band_guitar`, `band_bass`, `band_drums`, dialogues `ratte_talk`, `kraut_talk`; dan_work puts Luz, Ratte and Kraut into
  `zbar` in phase `free`.
- 0.8.61.3 (package 61a, the rest): `CentauriaGen.build_hall` (level `street` in Centauria; metas `hall_fronts`,
  `hall_pavs`, `hall_holo`, `from_plaza`; zone `hall_out`), drawn classes `HallFx` (parts `wall`, `pav`, `holo`) and
  `HallSky`; the lift menu's meta `levels`; FlightScene `_place_centauria`, `_draw_centauria` (`_ctr_marks`).
- 0.8.61.2 (package 61a): `scripts/ground/centauria_gen.gd`: the timetable (`LINES`, `state`, `next_at`, `doors`,
  `board_text`), the maps `build_station`, `build_plaza`, `build_car`, the sky `draw_sky` / `draw_lapis`, and the drawn
  classes `TowerArt`, `PlazaSky`, `TowerScope`, `FacadeFx`, `RoofFx`, `MetroFx`, `RailFx`, `CarScreen`, `Panorama`.
  GroundView levels `zstation`, `ztrain`, `zplaza` (`ctr_stop`, `ctr_line`, `is_centauria()`; zone kinds `ctr_board`,
  `ctr_alight`, `ctr_up`, `ctr_exit`, `ctr_down`, `ctr_scope`); map decal `terrace_lit`; Fern's moons Ember and
  Glacia; smoke group `ctr61a` (shots with `CTR_SHOTS=1`).
- 0.8.61.1 (package 61): Universe special system `fern` (`_place_fern`, `SPECIAL_BODIES["fern"]`, body keys `lapis`
  and `fern_city`, the forced asteroid belt in `_make_belts`); planet shader `grand` (Lapis' rings, set in
  `Celestial.make_planet_sprite`); dan_work phase `free`: `_fern_step`, `_fern_call` (`FERN_LEVEL`), `_luz_talk`,
  Luz in `ground_mode` for the city named Centauria; story mission `fern`, character `luz`; smoke group `fern61`.
- 0.8.58.6 (package 58, part 7): dan_work phase `relay` → `strike` (`_relay_body`, `_relay_site`, `_relay_begin`,
  `_relay_step`, `_relay_intro` with `_intro_walk` / `_intro_zap`, `_overload_fx` / `_OverloadFx`, `_foot_rescue`);
  POI theme `relay` (`DungeonGen.build_relay_outside`, target `relay` with `computer_wall`, `_air_shaft`);
  `GameState.story_foot_guard`, story sites in `pois_for`; turrets as fixed foes (`_turret_target`); tripwire warning;
  `HackGame.start_won` and pad input; the story marker over planets (`Universe.warp_target`); smoke groups `relay58`,
  `w58g`, `hackpad`, `grmove`.
- 0.8.58.5 (package 58, part 6): dan_work phases `report` → `brief` → `gear` → `sim` → `relay` (`_briefing`,
  `_brief_stage`, `_brief_action`, `_shot_first`, `_lend_ground_gear`, `LENT_GEAR`, `_gear_tour`, `_sim_start`,
  `_sim_step` with stages fight / to_start / sneak / ask / free, `SNEAK_GUARDS`); `scripts/ground/pool_fx.gd`;
  `ArenaGen.build_sim`, GroundView level `sim` (`sim_foes`, `sim_lost`, `holo_foe`, `wheel_point`, story `near_lift`,
  `pool_clear`); PilotWindow `tour_targets`; dialogue `no_dim`; characters `rook`, dialogues `dan_report`, `briefing`,
  `rook_sim`, `rook_more`; `Pad.action_text` over every context; Ship arming during a lock; smoke groups `w58f`,
  `arm58`.
- 0.8.56.10: Kit `bar_tile`, `tile_row`, `amount_block`, `MineGlyph`, `picture(..., max_px)`; DronePanel `pick`,
  ServicePanel `pick_uid`, MunitionsPanel `pick`.
- 0.8.56.9: BondPanel.wanted_poster(c, sid, course, width) scales by `_k`; the restyle (`_build_restyle`) sizes the
  portrait and the hologram by the screen.
- 0.8.56.8: Industry `REFINE_RATE`, `refine_factor`, `refine_time`, `component_time`, `station_build_time`,
  `queue_station_job`, `fmt_secs`; station jobs carry `lane` ("refinery" / "fab"), `type` ("refine" / "component" /
  "module"), `out_id`, `out`, `done`, `id`; GameState `_advance_station_jobs` (one job per lane, leftover time goes
  on), `jobs_at(station, lane)`, `jobs_ready`, `collect_job`, `next_job_id`; command `job_collect`; Kit `tile`,
  `grid`, `cargo_bar`, `production`, `Ingot`, `good_color`; Refinery / Manufacturing panels with `tab`.
- 0.8.56.7: MarketPanel rebuilt (static `filter`, `pick`; `_rows`, `_pick`, `_show_card`, `max_buy`, `_trade_block`
  with HSlider + SpinBox); smoke `stationwin` buys through it.
- 0.8.56.6: `scripts/ui/station/svc_kit.gd` (window building blocks: `picture`, `detail`, `stats`, `tags`, `chips`,
  `strip`); StationUI `fit_window`, `line_limit`, `tame` (long labels wrap after every build); Shipyard static
  `size_f`, `role_f`, `pick`, `role_of`, Hangar `pick_uid`, both with `menu_tab`; smoke group `stationwin`.
- 0.8.56.5: every answer in `dan_help` and `intro_doc` has its 4th entry (said at length); smoke `intro56e`
  goes on past the spoken lines.
- 0.8.56.4 (package 56, part 4): `scripts/ground/intro_six.gd` (sequence 6, part 1: `begin("bar"|"talk"|"load")`,
  `_mode()`, phases `bar`, `talking`, `fade`); `main._start_intro_six`, flag `intro_stage` "six"; story missions
  `prologue` and `ticket`, characters `patron_a/b/c`, dialogue answers' 5th entry (`if`, `not`, `gold`), Story
  `done_log`, `complete`, `goto_step`, action `start`; StoryUI `answer_ok`; GroundView story_mode `no_crew`;
  `scripts/ui/transactions_view.gd` (from the ship menu into the journal); pilot window journal tabs `transactions`
  and `completed`; smoke group `intro56f`.
- 0.8.56.3 (package 56, part 3): `scripts/ground/intro_five.gd` (sequence 5: phases `deck`, `ask`, `out`, `launch`,
  `lessons`, `ambush`, `fight`, `debrief`/`down`, `home_*`, `back`; static `tidy()` gives the drone back); story mission
  `flight_training` (`lessons`: done steps keep their text), dialogues `tut_start`, `dan_help`, `intro_doc_again`,
  `tut_hangar_back`, a line's `next`; Story.keys `{move}`, `{zoom}`, `{views}`, `{journal}`; hull and preset
  `dan_drone` / `tut_dan_drone`; Ship `story_spare` + signal `spared`, `align_scale`; SystemView `story_cam`,
  `story_follow`, `story_leash`, `story_zoom`, the pad latch; GroundView story_mode `lift_only` (a list), `lift_labels`,
  `ship_art`, `ship_talk`, `ship_title`, people `at_ship`/`talk`, `spawn_ship`, no crew zones when quiet; DialogueView
  `say(text, [], cont)`; PixelArt `use_rust`; smoke group `intro56e`.
- 0.8.56.2 (package 56, part 2): `scripts/ground/intro_four.gd` (sequence 4: phases `bed1` … `talk4`, `begin`,
  `_skip_to_walk`); GroundView `story_mode` (`quiet`, `hide_pilot`, `lift_only`, `levels` with `bed`, `awake`,
  `people`, `spawn`), `story_people`, `story_cam`, signal `story_talk`, zone kind `story`; `main._start_intro_four`;
  GameState.new_game with `intro` (Beyond, docked at Dan's, flag `intro_stage`); DeckGen palette/theme `dusty`;
  ObjArt `med_bed_occ` with `patient`/`awake`; DialogueView `set_speaker`; story dialogues with a line's `who`
  ("you" = the pilot) and an answer's 4th entry (said at length); the creator's `_build_restyle`; smoke group
  `intro56d`.
- 0.8.56.1 (package 56, part 1): `scripts/ui/intro_one.gd` (sequence 1 + the title card: `SHOTS`, `title_continue`,
  `skip`), `intro_two.gd` (`STEPS`, `step_time`), `intro_three.gd`; `scripts/core/earth_art.gd` (Earth from continent
  outlines, `world_at` for an Earth-like world), `scripts/core/holo_art.gd` (a ship computer's hologram),
  `shaders/veil_edge.gdshader` (`amount`, `centre`); StationArt `gold_ship_new`, `gold_ship_small` (tier 2 damaged),
  `long_gate`; `PixelArt.rust_texture`; story characters `doc`, `ship_ai` (`holo`), `Story.portrait_of`; the creator's
  scanner (`_build_scan`, ScanBed, Vitals, AttrBar); `ChibiArt.HAIR_MAPS` / `_hair`; PilotArt `LIPSTICK`, `BLUSH`,
  `EYE_MAKEUP`, hair "Sidecut", headgear "Eye patch"; sound `ui_type`; main menu `BACKDROPS` (`force_backdrop`);
  smoke group `intro56`.
- 0.8.57.1 (package 57): Universe `POCKET`, `_place_pocket`, `is_pocket`, Beyond's bodies and Dan's station in the
  SPECIAL_* tables, `_gold_wrecks` (layout `gold_wrecks`), the wreck belt (`_has_wreck_belt`, `_make_wreck_field`,
  field `wreck`, asteroid shape "scrap"), wreck colossi (`wreck`, `stage`, `rot`; `wreck_colossus_poly`,
  `wreck_colossus_scale`, `WRECK_SHIP_NAMES`); StationArt `dusty_duty`, `gold_colossus`, `wreck_piece` (`_gold_ship`,
  `piece_geom`, `piece_tears`, `piece_outline` – the collision outline from the same geometry, `hit_profile`), material
  `STEEL`, baking on the WorkerThreadPool (`prebuild`, `is_ready`, `reap` – SystemView waits in `_exit_tree`);
  `Celestial.make_wreck_colossus_sprite`, `PixelArt.scrap_sprite`; commands `debug_gold_wreck`,
  `debug_wreck_colossus`; smoke group `beyond57`.
- 0.7.80.1 (package 80): autoload `Pad` (scripts/autoload/pad.gd: devices, glyphs, settings and bindings in
  user://controller.cfg, contexts space/ground/menu/minigame, combinations, `pad_button`/`pad_stick`/`pad_buttons` of
  games and menus, the wheels `scripts/ui/pad_wheel.gd`, the prompts `scripts/ui/pad_hint.gd`, `rumble`, test
  simulation `sim_*`); `ControllerPanel` (Settings → Controller); MenuNav row/column first, `restore`, plain-node
  menus; SystemView `is_map`, `map_flick`, `_draw_map_pick`; HUD `_mark_selected`; GalaxyMap `pick_towards`; gear
  shop tiles are buttons; smoke group `pad80`.
- 0.7.79.1 (package 79): ShipFitting `fire_groups`, `fg_custom`, `FIRE_GROUPS`, `fire_groups_auto`, `groups_of`,
  `group_slots`, `set_fire_group`, `clear_fire_groups`, `auto_fire_groups`; commands `fire_group`, `fire_group_set`,
  `fire_group_auto`, `fire_group_clear`; HUD `FIRE_COLORS`, `_make_group_tile`, `_group_tiles` (keys `module_1` …
  `module_8` = fire groups, `module_9` gone); ShipMenu `_build_fire_groups` (`mod_view` "groups"); smoke group `firegroups79`.
- 0.7.54.18 (review 7): GameState `poi_state`, `poi_site_state`, `poi_flag`/`set_poi_flag`, `reset_ground_state`,
  `museum_give_suit`; GroundView `_poi_caches`, `_poi_restore`, `poi_save`, `leave_ground` (called from Main `close_deck`
  and `prepare_save`), fuses/wires kept as map metas; GroundCombat cached view cones (`f["vp"]`); DeckGen `shuffled`;
  Commands `souvenirs_bought`; smoke group `review7`.
- 0.7.54.17 (package 54e): `scripts/core/weather.gd` (class `Weather`: `at(body, place, cloud, t)`, `TABLE`, `wet`,
  `debug_kind`), `scripts/ground/weather_fx.gd` (class `WeatherFx`: tint, haze, particles, `strike`), `shaders/weather_haze.gdshader`;
  GroundView `WEATHER_LEVELS`, `_setup_weather`, `weather_now`; Walker `umbrella_on`/`_draw_umbrella`; PlanetMap
  `_draw_weather`; sounds `amb_rain`, `amb_wind`, `thunder`; command `debug_weather`.
- 0.7.54.16 (package 54c, part 7 – done): StationRooms `build_yard_gallery`, `YARDS`, `yard_kind`;
  `scripts/ground/dock_window.gd` (the work from `StationArt.build`, map meta `dock_view`); GroundView level `ygallery`
  (stations with `capital_yard`); sight theme `yard`, souvenir `souv_yard`; `debug_station_room` rooms `yard_concord`,
  `yard_forge`, `yard_axiom`.
- 0.7.54.15 (package 54c, part 6): StationRooms `build_control`, `scripts/ground/sphere_window.gd` (the star in the
  system's colour, the shell, construction ships; map meta `sphere_view`); GroundView level `control` (stations with
  `exchange`), zone `exchange_desk` (`_open_exchange_menu`); objects `console_row`, `sphere_holo`; decal `light_band`;
  sight theme `sphere`, souvenir `souv_sphere`; `debug_station_room` room `control`.
- 0.7.54.14 (package 54c, part 5): StationRooms `build_nave`, `scripts/ground/gate_window.gd` (the Pilgrim Gate from
  `StationArt.build` in the window, map meta `gate_view`); GroundView level `nave` (stations with `curia`); face deco
  `nave_window`; object `altar_cov`; sight theme `nave`, souvenir `souv_nave`; `debug_station_room` room `nave`.
- 0.7.54.13 (package 54c, part 4): `scripts/ground/station_rooms.gd` (`build_vote_gallery`), `scripts/ground/vote_shaft.gd`
  (the shaft in the window, map meta `shaft_view`); GroundView level `vgallery` (stations with `senate`), guards on
  `guard_posts` outside towns too; decal `glass_floor`; object `vote_booth`; sight theme `vote`, souvenir `souv_vote`,
  `Missions.ground_sights` kind `station`; Commands `debug_station_room`.
- 0.7.54.12 (package 54c, part 3): sight themes `senate`, `palace`, `mirror` (`data/sights.gd`), souvenirs
  `souv_senate`, `souv_palace`, `souv_mirror`; the plazas' map meta `sight`; `Missions.ground_sights` kind `capital`;
  the Mirror Front: Universe site on Curie (theme `mirror`), SightGen `VISTA["mirror"]`, `_pv_mirror`; SightFx
  `_senate`, `_palace`, `_mirror_over`; WildGen vista biome `mirror`; Commands `DEBUG_SIGHT_WORLD["mirror"]`.
- 0.7.54.11 (package 54c, part 2): `scripts/ground/palace_gen.gd` (`build_platform` with `rim_at`, map metas `rim_curve`,
  `rim_warm`; `build_lobby`, `build_throne(…, allied)`, `build_station`); CloudGen `STOPS[3]` "The Palace",
  `others(stop, palace)`; GroundView levels `pplaza`, `pnarthex`, `throne`, zones `curia_chancery`, `relic_office`,
  `audience`, `audience_denied` (`_open_curia_menu`), `museum_go` key `stop`, map meta `guard_suit`; Curia
  `audience(what, id)`, `sealed`, `AUDIENCE_BLESSING`, `audience_words()`; Commands `curia_audience`, `debug_capital`
  keys `here`, `stop`; suit `suit_mil_hierarch` (ChibiArt `_cape_frame`); art: face decos `palace_front`, `palace_gate`,
  `cov_lancet`, `cov_banner`, `cov_pilaster`, `edict_scroll`, `throne_window`, `sun_halo`; decals `cov_rail`,
  `cov_steps`, `cov_plinth`, `sun_mosaic`, `pool_red`; objects `brazier`, `tithe_chest`, `reliquary`, `candle_rack`,
  `throne_small`, `baldachin`, `regalia_table`, `kneeler`, `font`, `lectern`, `candelabrum`.
- 0.7.54.10 (package 54c, part 1): `scripts/ground/capital_gen.gd` (`build_senate_plaza`, `build_senate_lobby`,
  `build_senate_gallery`, `_stand_sign`), `scripts/ground/senate_chamber.gd` (the chamber drawn in the gallery's window,
  map meta `senate_view`); Universe `CAPITAL_CITIES`, `_name_capital`, station key `capital`; GroundView levels `kplaza`,
  `senate`, `sgallery`, `capital_kind()`, zones `senate_info`, `party_office`, `lobbyist`, `senate_stand`
  (`_open_senate_menu` → `senate_donate`/`senate_bribe`/`senate_vote`), map metas `scanners` (`_scanner_step`) and
  `guard_posts` (guards only there, even with `no_guards`), sign key `stand`; GroundMap `_mix`; Commands
  `debug_capital`.
- 0.7.54.9 (package 54b done): Commands `_mg_tip(who, rng)` (anomaly near → revealed, or a trade tip from
  `Market.buy_price`/`sell_price` within two jumps), `MG_TIP_CHANCE`, `mg_last_tip`; `minigame_end` key `tip` (forced, for
  tests); sounds `pool_cue`, `pool_ball`, `pool_cushion`, `pool_pocket`, `dart_throw`, `dart_hit`, `card_deal`,
  `card_shuffle`, `arcade_coin`, `arcade_laser`, `arcade_boom`, `arcade_pickup`, `arcade_bank`
  (`python tools/audio/make_placeholders.py <ids>` makes only those).
- 0.7.54.8 (package 54b, part 3): `scripts/ground/drift_game.gd` (Drift: `deal`, `move(what, card)`, `total`,
  `has_warp`, `ai_choice`, `_showdown` → `minigame_end` with `pot`); zone `drift` (`DeckGen._drift_zone`, lounges and
  garden bars); the lobby seats `others` at the card table; Commands `drift_move`.
- 0.7.54.7 (package 54b, part 2): `scripts/ground/rock_hopper.gd` (Rock Hopper: `step(dt)`, `add_rock`, `_crack`,
  `_laser_hit`, the refinery `centre()`, drones, `_game_over` → Commands `minigame_end` with `score`); `MinigameData`
  game `rockhopper` (mode `arcade`, `arcade_board(place, best)`), `GameState.minigame_best` keys `rockhopper` and
  `rh:<cabinet>`; zone `arcade` (`DeckGen._arcade`, ObjArt `arcade`) in the diner and the beach bar.
- 0.7.54.6 (package 54b, part 1): `data/minigames.gd` (GAMES with modes and rules, TIERS by the win streak, `stakes`,
  `max_stake`, `guests(place, game, streak, hour)`, `solo(mode)`); `scripts/ui/minigame_lobby.gd` (signals `start(cfg)`,
  `closed`); `scripts/ground/pool_game.gd` (billiards: `rack`, `shoot(angle, power, spin)`, `_physics`, `_shot_over`
  rules, `_ai_choose`, `legal_targets`); `scripts/ground/darts_game.gd` (`score_at`, `target(v, ring)`, `throw_at`,
  `ai_aim`); GroundView `open_minigame(game, place)` (lobby → game → lobby, via `_open_game`); zones `pool`, `darts`
  (`DeckGen._pool_table`, `_dart_board`, ObjArt `dart_board`); `GameState.minigame_streak`, `minigame_wins`,
  `minigame_best`; Commands `minigame_begin`, `minigame_end`, `pool_shot`, `dart_throw`, `debug_minigame`.
- 0.7.54.5 (package 54a): `data/sights.gd` (pure data: `READY`, `THEME_OF` world type → sight, `SIGHTS` names, what,
  souvenir, events {id: [text, when, weight, rare]}); `scripts/ground/sight_gen.gd` (`theme_for`, `event_for(theme,
  id, visit, day)`, `build` → `_falls`, `_lagoon`, `_icecave`, `_vista` (arches, lava, crater: scenery north of row
  `RIM`, the sky left clear), `_terrace`, `paint_extra` – WildGen.paint calls it for map meta `sight_paint`);
  `scripts/ground/sight_fx.gd` (two layers: under the map – the lagoon's life, the vistas' sky; over it – the event,
  camera flashes); map meta `sight` {theme, event, focus, id, …}, zones `viewpoint`, `sight_info`, `souvenir`;
  site kind `sight` in `Universe.landing_sites`; `GameState.sight_photos`, `sight_visits`; Commands `sight_photo`,
  `souvenir_buy`, `sight_tour`, `debug_sight`, `debug_excursion`, `debug_shuttle`, `debug_cloud` keys `sight_event`,
  `sight_day`; commodities `souv_*`; `Missions.ground_sights`, `_excursion` (tour key `ground`), `generate_shuttle`;
  CloudGen Skyring deck as sight `skyring`; ObjArt `crystal` reworked.
- 0.7.54.4: `CloudSea.CloudSky` for the sky bar – `bar`, `style`, `day`, `star_col`, `make_towers(seed)`, `_draw_star`
  (the star, its veils, the cloud tops at the horizon), `_draw_towers` (by `CloudFlightArt.STYLE_COLS`); GroundView sets
  the sky's light at once.
- 0.7.54.3: FlightScene `open_cloud(body, site, rising)` (cloud mode: `shaders/cloud_deck.gdshader` decks, the
  platforms from `scripts/ui/cloud_flight_art.gd` – `platform(r, seed, style, look, gate, day)`, lights by the hour –,
  `_approach`, `_draw_cloud_fx`; site key `debug_day`); `main._city_hatch` skips the hatch for giants, `_cloud_climb`.
  POI theme `skymaint` (style: `GroundMap._sky_cap`/`_sky_face`; ObjArt `lift_tank`, `rotor_ring`), GroundView
  `_underdeck`, explore reactor `rotor`, `GameState.underdeck_site`, `maint_site` by the city; Missions "reactivate"
  under cloud cities ("Rotor restart"). `CloudGen._plaza_style` (face deco key `style`, ObjArt `lantern`);
  `debug_cloud` level `cunder` (`job`).
- 0.7.54.2: `CloudGen.STOPS` has a third stop (Harvester Deck) – `others(stop)`, `build_station(…, 2)` →
  `build_harvest` (meta `works`, `intakes`, `catwalk`, `berth`, `freighter`, `rim_y2`; zone `gas_exchange`; floor 50,
  decals `cat_rail`, `pipe_steps`, face decos `control_window`, `exchange`; ObjArt `gas_tank`, `compressor`,
  `gas_column`, `gas_flare`, `winch`), `freighter_in(station)` (each half hour of play, `debug_freighter`);
  `ParkedArt.make(…, floating)`; CloudSea `_add_freighter`, intakes, `platforms` (the stations passing aboard,
  `_draw_platform`), `CarShell.draw_bogie`; GroundView `rail_to`, `_open_rail_menu`/`_board`, `rail_speed`, `rail["dist"]`,
  `_open_gas_menu`; Commands `gas_buy`, `gas_offer`, `gas_price`, `GAS_DISCOUNT`; `debug_cloud` stop 2 and `freighter`.
- 0.7.54.1 (package 54, cloud cities): `Universe.is_giant`, `can_land` (descent beacons over giants with `cloud_city` –
  set in `_city_lights` for inhabited systems), `CLOUD_KINDS`, `cloud_sites` (1–2 sites, kind `city`, `cloud`);
  `city_station` marks `cloud` / `giant`. `scripts/ground/cloud_gen.gd` – `build_plaza` (shops `_shop_n` north of the
  plaza, `PLAZA_MORE` deck beyond its ends), `build_station(station, stop)` (`STOPS` Central/Skyring, zones `board`,
  `scope`, meta `car`, `beam_y`, `rail_front`), `build_car(station, to_stop)` (zone `alight`, meta `car_shell`),
  `giant_look`, `breathable`; floors 47–49, style `cloud*` (`GroundMap._cloud_face`, meta `rim_y`), face decos
  `cloud_front`, `cloud_lifts`, `departures`, `ticket`, `cloud_window`, `car_doors`, `car_board`, `gangway`,
  `force_gate`. `scripts/ground/cloud_sea.gd` (under the map: `shaders/cloud_sea.gdshader`, far platforms, spindles,
  beam and masts, the waiting car, lightning; `CloudSky` with `shaders/cloud_sky.gdshader` in windows; `CarShell`).
  GroundView levels `cplaza`, `cstation`, `ctrain` (`rail`, `_rail_step`, `RAIL_RUN`), `is_cloud`, `cloud_env`
  (`GearData.cloud_env`), map meta `few_guards`; `DeckGen.build_hangar` gate for cloud cities. Commands
  `debug_cloud`, `debug_skyrail`.
- 0.7.53.36: GroundCombat `peaceful(f)` / `hunt(f)` (key `hunted`) – R, Shift+R, auto-fire, drones and the team leave peaceful animals be; GroundView `_on_click` (first click marks, second hunts); `_draw_tactics` draws the view cones only while sneaking.
- 0.7.53.35 (package 53f-2): `scripts/ground/wild_gen.gd` (the wild: `build` – jungle/coast/ice, terrain per tile `ter` (OPEN, WATER, FORD, CLIFF, THICKET, CHASM, RIDGE, BOARD, CAVE, BRIDGE), water depth `sdf` in tiles, paths, clearings, fords, islands, crevasses, bridges; the find `wild_find` (shrine/pod/nest); animals from the theme's `animals` [kind, n, herd/pack/solo]; meta `wild`, `tint`, `water`, `see`, `alpha_i`; `paint` – the painter GroundMap calls for style "wild" (floor kind 46), `_carve` leaves the water clear; `mm_col`), `scripts/ground/wild_art.gd` (leaves, crowns, ferns, rocks, cliff faces, palms, trunks, floes, cracks, ice chunks, ridge slabs, the crashed drone; `paint_obj` for ObjArt kinds wild_tree, palm, wild_log, driftwood, ice_block, wild_rock, lander_wreck), `shaders/wild_water.gdshader` (GroundView `_add_wild_water`); PoiData themes `wild_jungle`, `wild_coast`, `wild_ice` (outside "wild", no inside), `wild_theme(body_type)`, site kind `wilds`; FoeData animals (`wild` flee/territory, `terr`, `ambush`, `rooted`, `loot.items`, `loot.cargo`); GroundCombat `_wild_step`, `_wild_walk`, `_graze`, `_wild_flee_spot`, cover from meta `see`; GearData `GOODS` (kind "goods"); commodities `exotic_hides`, `game_meat`; job goal `hunt` (site `hunt_kind`, `hunt_n`, `hunt_alpha`; `Missions.HUNT_KINDS`), GroundView `_hunt_step`, `_wild_find`; Walker `_side` (animals side on).
- 0.7.53.34 (package 53f-1): `scripts/ground/creature_art.gd` (sec_robot, pre_robot – `alert` red, necrotic – steam by time, rat, rat_brood, crawler, specimen; own rim and outline; `texture` cache); FoeData kinds `sec_robot`, `pre_robot`, `necrotic`, `mut_rat`, `rat_brood`, `cave_crawler`, `specimen` (keys `creature`, `armor_v`, `shield_v`, `loot`, `rise`, `regen`, `swarm`, `chest`); weapons `wp_claws`, `wp_bite` (`melee`); GroundCombat `_melee`, `_creature_step`, `_rise_step`, `_loot`; Walker `creature`/`alert`/`_draw_creature`; themes' `creatures` {kinds, share}, `DungeonGen._foe_pick`, swarms, site `pest`; job goal `pest`.
- 0.7.53.33: `shoulder_drones()` true for every suit, `both_arms()` (the Senate's `shoulder_drones` key) – one drone on the right arm (GroundCombat, DroneBuddy).
- 0.7.53.32: DebugMenu sections fold (`_section` → button + box, `_box`, `_toggle_section`, static `_open`, `_all_sections`); World tab reordered, Ground tab split.
- 0.7.53.31: ChibiArt `_archivist` (body details), `_archivist_helmet`, `_archivist_frame` (hood, scarf, wrap, antenna on a canvas padded by `ARCH_PAD`); suit `suit_archivist` colours graphite and white.
- 0.7.53.30: GroundView `_curator_give`/`_curator_tell`/`_curator_rewards`, `_cur_trip`/`_cur_pending`/`_curator_step` (map meta `curator_pos`), Walker `goto_to`/`goto_done`; `DialogueView.portrait_tex` (a case's piece); decal `museum_roof` with dome, attics, urns; `_tint2` (the roof plaza's Museum roof); benches `face` 1.
- 0.7.53.29: ObjArt `m_rail` running north–south on an edge (`arch` "e"/"w"), `MuseumGen._rail(..., edge)`.
- 0.7.53.28: seat zones `npc_ok` (bench, sofa, `museum_bench` in `DeckGen.SEATS`), Walker `_seat_z`/`_sit_t` (strollers take a free bench, zone `closed` while taken); map meta `no_guards` (Museum rooms) – two posted guards at the hall's doors; museum benches non-blocking.
- 0.7.53.27: curator as `DialogueView` (`_open_curator`, `_curator_options`/`_rooms`/`_finds`/`_sell`/`_hint`, map meta `curator_look`); `MuseumGen._exit` (decal `museum_exit`, no stairs down); ObjArt `holo_ship` (a hull's picture as a hologram, no outline), `curator_desk` with its top; arches dark.
- 0.7.53.26: Museum rooms each a map – `MuseumGen.build_hall`/`build_minerals`/`build_floor1`/`build_floor2` (levels `museum`, `museum_min`, `museum_1`, `museum_2`), zone `museum_go` (`to`, `at` – arrival at map meta `from_*`), face decos `museum_gate`, `arch_min`, `arch_down`, decal `museum_arch_s`, floor 45 (stairs down); `build_main` gone; `debug_museum` `to` minerals/first/second.
- 0.7.53.25 (package 53e): `data/museum.gd` (48 `EXHIBITS` with room, rarity, `art`; `RARITY` prices, `ROOMS`, `HINTS`, `PERKS`, `roll_kind`, `room_for_theme`), `scripts/core/exhibit_art.gd` (a 24 × 24 picture per exhibit); `scripts/ground/museum_gen.gd` (`build_plaza`, `build_main` – one map for the hall and the floors above, `build_basement`); GroundView levels `mplaza`/`museum`/`museum_down`, zones `museum_in`/`museum_out`/`museum_down`/`museum_up`/`curator`, `is_museum_city`, `_museum_case`, `_open_curator`; explore `vitrine`/`niche`/`monolith_cast`; floors 34–44 (marble, parquet, stairs, slate, runner, basement), styles `museum`/`museum_dark`, plaza meta `museum_x`; ObjArt `statue`, `statue_precursor`, `bust`, `column`, `curator_desk`, `museum_bench`, `rope`, `m_rail`, `globe`, `geode_big`, `ship_model`, `poster`, `skull_cast`, `idol_cast`; `GameState.museum_donated`, `museum_donate`/`museum_sell`/`museum_perk`; `PoiData.museum_roll`/`museum_pick` (`MUSEUM_RELICS` gone); suit `suit_archivist` (`builtin_belt`, `cloak_mul`); command `debug_museum`.
- 0.7.53.24: explore `cracked_wall` (map meta `hidden_wall`, hint `hinted` from a tablet or monolith scan, `?` on the minimap), crate `hidden`; red sites `cols`/`rows` + 1, one more store.
- 0.7.53.23: theme `darkones` (kind `darkruin`, style `darkones` – `_dark_face`, floor 33, `round_rooms`/`_fill_round`, descent `maw` with `spiral_up`, door `membrane`, `gate_lock` "symbols", target `dark_relic`, traps `glyphs`, `cult_foes`/`cult_leader`), explore `symbol_pillar`/`monolith`/`membrane`/`maw`/`spiral_up`/`glyph_trap`/`sleeper`, GroundView `_symbol_menu`/`_touch_symbol`/`_dark_wave`, monolith visions, foes `cultist`/`cult_zealot`/`cult_priest` (livery `cult`), goal `investigate`, Museum relics `darkones`.
- 0.7.53.22: theme key `patrols` / `reinforce` (map metas `routes`, `reinforce`), `GroundCombat._patrol_step` (foe `route`, `walk_a`), `GroundView._reinforce_step`.
- 0.7.53.20: theme `research` (kind `research_st`, outside `station` – `DungeonGen.build_station_outside`, `pressurized`, `leaks`, traps `lab`, target `research_logs`), GroundMap floors 31/32, style `research` (`_module_face`, `_module_roof` with meta `roofs`), ObjArt `lab_bench`/`cryo_tank`/`sample_cabinet`/`dome`/`radio_mast`/`crawler`, explore `leak`/`seal_panel`, cells style `research`, GroundView `_out_env`/`_in_leak`, goal `recover`, rescue variant `research`, `Universe.SITE_KINDS` `pirate`/`research_st`.
- 0.7.53.19: theme `corp` (data/poi.gd: layers offices/security/vault, `cams`, `keycard`, `beams`, `security`, `carpet_share`, descent `keylift`, door `vault_door`, target `corp_vault`), `DungeonGen.build_plaza`, GroundMap floors 28/29/30 and styles `corp`/`plaza`, ObjArt `office_desk`/`partition`/`server_rack`/`pillar_corp`/`glass_rail`, explore `camera`/`laser_gate`/`keycard`/`vault_door`/`service_door`, GroundView level `plaza` (`_town_kind` "corp"), `_cams_step`, `GameState.corp_poi`/`corp_site_for`, foes `corp_*` (livery `corp`), `Missions.ground_offer(..., variant)`, commands `debug_mission`, debug tab Missions.
- 0.7.53.18: `GroundCombat.view_reach`, `NOTICE_STAND`, `NOISE_WALK/RUN`; unaware foes always `_watch`; `_wake` call-outs need sight; `lock()` never wakes; `_pilot_fire` on any lock.
- 0.7.53.17: heist variant `theme: sewer` with `site.city` (`GameState.sewer_site_for`, GroundView's city site switch), the safe crate as the target; city job sites never on the planet map.
- 0.7.53.16: `PilotGear.health_step` (`GearData.HEAL_WAIT/RATE/CAP`); explore `power_socket` + zone `socket`, `GroundView._socket_step` / `charging()` (no `_pilot_fire`); `Missions.generate_ground`, `GameState.ground_offers_for` (offers key `#g`), bulletin tab 2 "On foot".
- 0.7.53.15: drones with a velocity (`vel`, `_drone_pv`) in `GroundCombat._drone_step_one`; `main.ship_keys_locked()`; the gate used sets the outside map's `door_front`.
- 0.7.53.14: `GearData.LIFE_STRAIN` (energy beyond the suit's protection; exposure only without energy), suit energies +30 %; `PilotGear.carried_value` / `basic_kit`, `GameState.fall_offer` / `fall_open` / `fall_decide` / signal `pilot_fell`, command `fall_decide`; `loss_window` with a foot mode.
- 0.7.53.13: rescue job (goal `rescue`, `site.prisoner`): cells first on level 0, explore `cells` with `prisoner` (lock picked via `_fuses`), GroundView `_hostage` with `_spawn_hostage` / `_hostage_step` / `_hostage_blast`, the event `rescued` on reaching the outside.
- 0.7.53.12: `Missions.ground_offer` (type `ground`, goals relic/salvage/bounty_foot/heist/spy/reactivate, `site`), `GameState.ground_goal`, `maint_site_for`, mission sites in `pois_for`; GroundView `_mission_window`, `_mission_event`, `_mission_step`; command `debug_ground_job`.
  (DungeonGen.build: grid rooms, `_corridor` three wide, `_faces`, roles, things; `map` meta "poi" for the targets window);
  `GameState.poi_visits`, `poi_used`, `pois_for()`, `poi_use()`; `Universe.landing_sites` appends them (no fixed ruins);
  site key `poi`; explore kind `crate` (`welded`), `CutGame.inside` "loot"; `GroundView._poi_setup`, `_poi_window`,
  `_poi_reveal`, `_draw_minimap`, `poi_seen`, `_loot`, `_poi_target_done`; commands `debug_poi`, `debug_poi_reveal`;
  smoke group `poi`.
- 0.7.52.29: `GroundMap._duct_tile()` (a duct tile by its neighbours).
- 0.7.52.28: `GroundMap.refresh_texture()`; duct tiles keep their wall until `open_vent`; `vent_end` key `vent`,
  `open_k` (the hatch flips open near you).
- 0.7.52.27: panel key `wall` (set for a door's box); explore kinds `vent` (key `duct`: tiles) and `vent_end`;
  `CutGame.inside` "duct"; floor kind 16 (air duct); `GroundView.open_vent()`, `_duct_step()` (sneaking in a duct);
  `VaultGen.DUCT`.
- 0.7.52.26: member gear key `belt` (tools; `member_equip` / `member_unequip("belt", i)`), ally keys `cloak_id`,
  `cloak_t`, `cloak_cd` (cloaking with you in `GroundCombat.cloak()`); Gear page tiles `m_belt`.
- 0.7.52.25: blast door lamp (one, by state); `scripts/ground/drone_buddy.gd` (DroneBuddy – the drones where there
  is no fight: `command(i)`, docked / launch / hover / dock; `GroundView.buddy`); belt tool `tl_cloak`,
  `GroundCombat.cloak()`, `cloak_t`, `cloak_cd`, `pilot_hidden()`, `CLOAK_TIME`, `CLOAK_CD`, `_cloak_step`; smoke group
  `foot_cloak`.
- 0.7.52.24: belt item `cs_breach` (kind "breach", taken in `GroundView._open_hack`); suits' `belt` 3 (combat 4);
  `ExploreNode._draw_blastdoor` redrawn (octagon, three parts; small/wide by the gap's width); `VaultGen.DOOR_SMALL`.
- 0.7.52.23: `scripts/ground/vault_gen.gd` (VaultGen, `DOOR`, `CAGE`; site key `vault`), explore kinds `blastdoor`
  (`tiles`, `open_k`) and `cage`, keys `door` / `cage` on a panel, relic or terminal, `no_zone`; `GroundView.open_door()`,
  `cage_off()`, `_named_lights` (a light with an `id`); hack action `lasers`; command `debug_vault`; smoke group `foot_vault`.
- 0.7.52.22 (package 52b): `scripts/ground/cut_game.gd` (CutGame: `SHAPES`, `shape_path()`, `step(delta, mv, burn)`,
  `cut_share()`, signal `finished`), `scripts/ground/hack_game.gd` (HackGame: grid, `move()`, tracers, `state`,
  `actions`, signal `finished`), `scripts/ground/explore.gd` (the things' nodes, `add()`, `INSCRIPTIONS`);
  `GroundMap.explore`; zone kind "explore"; `GroundView.spawn_explore()`, `add_explore()`, `belt_tool()`,
  `explore_use()`, `_open_game()` / `_close_game()` (`minigame` takes the keys), `_cut_done`, `_open_hack`,
  `_hack_done`, `_explore_effect`, `_scan_start` / `_scan_step` / `scan_done`; command `debug_explore`; smoke group
  `foot_explore`.
- 0.7.52.21 (package 52b): `GroundCombat.sneaking`, `toggle_sneak()`, `look_of(f)` (foe keys `look0`, `look_ph`,
  `notice`), `spots(f, p)`, `_watch`, `view_poly(f)`, `_draw_sneak`, `_draw_notice`, consts `SNEAK_ATTACK`, `SNEAK_RANGE`,
  `VIEW_HALF`, `CLOSE`, `NOTICE_TIME`; `lock()` does not wake while sneaking; shot key `sneak`; `Walker.crouch`; keybind
  `foot_sneak` (Ctrl; `Keybinds.event_to_desc` lets Ctrl be bound); smoke group `foot_sneak`.
- 0.7.52.20 (package 52a): `CrewData.TEAM_*`, `ABILITIES`, `STANCES`, `DOWN_TIME`, `REVIVE_FEE`; `PilotGear.team`,
  `team_members()`, `team_toggle()`, `member_gear()` (static), `member_equip()`, `member_unequip()`; member keys `gear`,
  `stance`, `dead` (`CrewCore.effect` gives nothing while dead); `GroundCombat.allies` (dicts with `ally`), `spawn_team()`,
  `spawn_ally()`, `allies_up()`, `_ally_step`, `_ally_decide`, `_ally_target`, `_foe_target` (foes go for a much nearer
  member; `f["tp"]`), `_chance_between`, `_hurt_ally`, `revive_near()`, `revive()`, `_ally_dies()`, `leave()`, `order()`,
  `use_ability()` (foe keys `supp`, `scan_t`, `jam_t`), `wheel_pick()`, `TEAM_COL`; `GroundView._team_keys`,
  `wheel_centre()`, `WHEEL_SLOW`; `CombatHud._draw_team`, `_draw_wheel`; keybind `foot_team` (V); `Commands.dead_crew()`,
  `revive_fee()`, command `clinic_revive`; debug `debug_combat` `team`, `team_down`, `team_revive`, `team_ready`, `team_die`.
- 0.7.52.19: `GroundCombat.drone_kamikaze_up(i)`, `drone_recall(i)`; `GroundView._drone_held` (tap on release, held `TAB_HOLD`: back).
- 0.7.52.18: suits `suit_mil_senate_eyes` / `suit_mil_senate_hand` (`faction` "assembly", `shoulder_drones`);
  `ChibiArt._senate`, `_senate_helmet`, `_senate_frame` (a bigger canvas `SENATE_PAD` for crest and cloak; `_px` clips to
  the image); `GroundCombat.drones` / `drone_rebuilds` / `drone_slot` with `pick_drone(i)` (the drone functions act on
  the picked place), `drone_places()`, `drone_command(i)`, `_dock_at(i)`, `shoulder_drones()`, `_nearest_drone`;
  `DroneArt.draw_arm`; keybind `foot_drone_2` (Shift+C); debug `drone_kill` takes `place`; smoke group `foot_senate`.
- 0.7.52.17: the arm beam holds `ARM_HOLD` 2.5 s – shot key `to` (its target), `_arm_tick` (one of `ARM_TICKS` burns,
  each rolled), `_arm_geometry` (muzzle, end, cuts, runs; renewed every 0.08 s in `_fx_step`).
- 0.7.52.16: `GroundCombat._beam_runs(ga, gb, ma, mb)` – the visible stretches of the arm beam (hidden on a cover piece's
  picture when the beam's ground point is behind the piece's front edge); shot key `runs`.
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

## The intro (phase 1 package 56)
- New Game starts with the story: sequence 1 (the memory – Earth, the Expansion's fleets, the Long Gate, the Veil,
  the Mayday), the title card (waits for a key), sequence 2 (Beyond – the portal, the burning Earthworks 190SL, the
  ship's computer as a hologram, Dan tows her away), sequence 3 (the medic, ceiling lights) – then the character
  creator as Dan's medical scanner. On their own timing; hold Esc (Options) to skip.
- Sequence 4 (Dan's station): the infirmary – asleep, "a few weeks later" awake, "a few days later" on your feet; the lift
  only to the bar, Dan at the window; the talk ends with the choice of the flight tutorial.
- Sequence 5 (the flight training): in Old Betty to a wreck field, flying Dan's remote drone – the journal, flying, the
  views, fire groups, mining, unloading, an ambush by two pirates; every lesson kept in the journal.
- Looks: hairstyles drawn per view on foot, the sidecut, make-up (lipstick, blush, eye make-up), the eye patch; Visage
  Clinics in the scanner's style.
- Main menu: one of four scenes at random. Debug: F12 → World → Intro (package 56).

## Beyond – the pocket in the Veil (phase 1 package 57)
- Out in the Veil, apart from the Cluster: Beyond, Driftwood and Hollow, linked only among themselves. Beyond has Dan's
  Dusty Duty Store round the icy moon Rime (Hush, an ice giant), Brine (an ocean world with one city) and Cinder.
- The Gold Fleet's wrecks lie there big as planets (Beyond, Driftwood). The wreck belt holds Wreck Fields: wreck
  colossi – sections of Gold Fleet ships, obstacles and cover like the rock colossi, minable with a mining laser – and
  hull scrap mined like asteroids.
- Debug: F12 → World → Beyond (package 57).

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

## Bar games (phase 0.5 package 54b)

At a pool table (dives, lounges) or a dartboard (mess halls, canteens) **E** opens the game's lobby: choose the mode,
who plays (a guest of the bar or one of your crew; a seat for co-op comes later) and the stake. The stakes open with
your win streak at that game – medium from 10 wins in a row, high from 25 – and the guests get better with it.
**Billiards:** mouse aims, hold the left button for power and let go, right button + drag (or WASD) for spin; 8-ball,
9-ball or practice. **Darts:** the hand sways (Reflexes, drinks); hold the right button to hold your breath, click to
throw; 301, 501 or around the clock. **Rock Hopper** (the arcade cabinets in diners and beach bars, 1 cr a game): W thrust,
mouse or A/D turn, left button the drill laser, right button the tractor beam – crack the rocks, haul the ore home to
the refinery; the cabinet keeps tonight's best. **Drift** (card tables in lounges and garden bars): D draw, H hold,
W warp (then click the card to swap) – closest to 21 takes the pot.

## Sights on the ground (phase 0.5 package 54a)

On most jungle, ocean, ice, desert, lava and barren worlds (and moons of those kinds) the planet map shows a **sight**
(✦). Land, walk to the viewing terrace and look out: the Glass Falls, the Coral Lagoon, the Ice Cathedral, the Red
Arches, the Fire Terraces, the Great Crater – and in the cloud cities the Skyring deck. What is to be seen changes by
visit and hour (rare views among them); at the railing **E** takes a photo (a travel magazine buys each new one), the
holo shows your collection, the stall sells the place's souvenir. On the passenger board: **excursions** (land with the
sightseers, step up to the viewpoint, bring them back) and **shuttle runs** between a station and a city's hangar.

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
- Saves live in `user://saves/*.sav` (Windows: `%APPDATA%\Godot\app_userdata\Spacefarer- Beyond the Veil\saves`).
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
- **Ground** (0.7.51.5, packages 49–51): a status line (place, level, the world outside, daylight, the suit's bars);
  open the deck of the docked station or city, jump to a level (hangar, commercial level, shopping street, tower
  bar); descend at once to any body; land straight at a city, outpost, mine, research camp or landing field – as
  another world type, with a settlement's economy forced, at a chosen hour (a debug place is added if the body has
  none); set the time of day; gear by family and quality into the pockets, fill the belt, refill, empty the pockets;
  set health / energy / oxygen / ammunition; suit invulnerable; force the world outside; collapse now; wake in the
  clinic. Commands `debug_deck`, `debug_ground_level`, `debug_descend`, `debug_land`, `debug_daytime`, `debug_gear`,
  `debug_env`, `debug_collapse`, `debug_wake_clinic`; `Universe.debug_bodies` / `debug_sites` / `debug_body_as()`,
  `CityStyle.debug_shift`, `Commands.suit_god`.

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
