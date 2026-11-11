# Sternenfront – Changelog

Versions follow **alpha Phase.Teil.Paket.laufende Nummer** (see Roadmap.md → Arbeitsweise & Übergabe).
Every update gets its own entry, a commit and a git tag `v<version>`.

## alpha 0.7.52.16 – 2026-11-11

**The arm laser vanishes into the cover it cuts (Luz).** The beam now disappears where it enters a piece of cover and
shows again only past the end of that piece's picture – also behind the top of a tall bulwark; in front of cover it
stays in sight. With the glowing cut and its sparks it looks as if it really cuts through.

## alpha 0.7.52.15 – 2026-11-11

**The Red Arm Laser: a deep hiss and sparks where it cuts (Luz).**

- **Its own sound** (`w_arm_laser`): a deep, rushing hiss with a dark rumble under it and a faint sizzle on top –
  instead of the light laser "pew".
- **It visibly cuts through cover**: wherever the beam goes through a crate, a barrier, a bulwark or a wall, the cut
  glows white-hot and a spray of sparks flies out to the sides and onwards, falling, for as long as the beam lasts.
- The target's lock card shows the arm laser's real chance through cover (it cuts through, cover does not count).

## alpha 0.7.52.14 – 2026-11-11

**The Covenant's Pathfinder armour (Luz's idea, after the mockup she approved).**

- **Pathfinder Armour** (Forge of Return): red plate edged in gold, close-fitting and straight-lined – a gold pointed
  arch on the chest, a gold belt line and knee caps, a sleek helmet with a gold crest and a **pointed-arch visor** in
  gold. Strong plate (armour 130 at C – more than the heavy combat suit), shield 45, normal walking speed; 3 weapon
  places, 2 grenade places, 2 on the belt, 2 features – **no drone place** (the Covenant will not have them).
- **The Red Arm Laser** sits in its first weapon place, built in: it cannot be taken off, it goes with the suit. A heavy
  beam from the left forearm (120 damage at C) that **cuts through any cover**, even bulwarks and walls. Then it takes
  **30 seconds** to charge – also while another weapon is in hand. Its tile's frame is drawn round in yellow as it
  charges; full, it is ready. While it is the weapon in hand the pilot **raises the left arm** towards the target, the
  beam leaves the emitter at the wrist.
- **Only in the Covenant's lands** (its bigger stations and cities, and military ones) and **only for pilots it calls
  Friendly**.
- Smoke test group `foot_pathfinder`.

## alpha 0.7.52.13 – 2026-11-11

**Tiles along the bottom, the events on the right, a closer zoom (Luz).**

- **Tiles as in space combat** along the bottom: the **weapons** (the one in hand framed green), a little apart the
  **grenades** (the one in hand framed red), then the **drone** (its state, heat or rounds, the time to a new one) –
  each with its picture, name and what it holds; Q, X and C go through them as before. The belt's places stay on 1, 2, 3
  … – now tiles too, bottom left. The weapons panel on the right is gone; the dodge charges sit under the suit's bars.
- **The events on the right**, as in space: everything that used to pop up in the middle at the bottom – and the
  game's messages – runs into a log at the bottom right, with the time. The "[E] …" prompts of the place you stand at
  stay in the middle.
- **A closer zoom (×1.5)** in the fight and in the tactical view: the mouse wheel steps through the zoom (the fight:
  normal and near; the tactical view: out, normal and near), Z switches near and back (in the tactical view: out and
  back).

## alpha 0.7.52.12 – 2026-11-11

**Drones that turn and sit on your back; ammunition to be had (Luz).**

- **The drone turns where it flies** – and towards its target when it fires: the whole picture with its rotors turns.
- **Switched off on your back** until you press **C**: its underside against you – from behind you see it flat on your
  back, from the side its edge behind you, from the front you hide it. C sends it up; C again brings the laser and
  kinetic drones back to your back and switches them off. The **kamikaze** takes C twice: once to take off, once to send
  it at your target. A kinetic drone reloading on your back takes off again afterwards (C meanwhile: it stays there).
  On your back foes cannot shoot it.
- **Ammunition refilled**: the supply points by the pads (were "charging points") now fill energy, oxygen **and
  rounds**, and so does your ship when you go aboard – before, only ammunition boxes did.

## alpha 0.7.52.11 – 2026-11-11

**Ground combat drones (package 52.6, after the mockup Luz approved).**

- **A drone place on both combat suits** for a drone module, quality F–A (more damage, heat it bears or rounds it
  holds, shield and armour). In the Gear shop under Features → Combat drones, where combat suits are sold; on the gear
  page a row of its own.
- **They take off from your back** and hover at your shoulder – small quadcopters about 0.6 m across, spinning rotors,
  a blinking light, a shadow on the ground.
  - **Laser drone** (Axiom): fires at your target by itself; every shot heats it, full it must cool off.
  - **Kinetic drone** (Hadrian): a quick slug gun; its magazine empty, it flies back to your back and **reloads from
    your suit's rounds**.
  - **Kamikaze drone** (Forge of Return): waits at your shoulder; **C** sends it diving at your target, where it bursts
    (it spares you).
- **C** – the drone's command (rebindable): the kamikaze dives, the others are called back to your back or sent out
  again.
- **Foes shoot at it** – half the time when it is nearer to them than you are. Shot down, it falls; **a new one** takes
  off after 20 s (the kamikaze after 50 s).
- A drone panel beside the weapons: what it does, shield, armour, heat or rounds, the time to a new one.
- **More rounds and energy for every suit** (Luz): e.g. the light combat suit 240 rounds and 170 energy (was 160 /
  120), the civilian suit 100 / 140 (was 60 / 100).
- Debug (F12 → Ground → Combat): a laser, kinetic or kamikaze drone in any quality, shoot it down, a new one now.
  Codex entry; smoke test group `foot_drones`.

## alpha 0.7.52.10 – 2026-11-11

**Fix: ruins and crash sites in the approach without settlement pads.** Seen from above on the way down, a ruin or a
crash site now shows only the one landing field the drone sets down on – not the four pads of a settlement.

## alpha 0.7.52.9 – 2026-11-11

**Grenade places, the grenade on X, Shift+R, small bars over foes, softer radar colours, the controls in two tabs
(Luz).**

- **Grenades have places of their own** on every suit, apart from the belt's consumables and tools: civilian, survey
  and work suits 1, the light combat suit **2 grenade places + 3 on the belt**, the heavy one 3 + 2. Grenades go there
  when put on (the gear page shows them as their own row); **grenades stack up to 10**, in the pockets and in their
  places.
- **One grenade in hand**, as with the weapons: **X** tapped takes the next kind, **X held** shows the arc to the mouse,
  let go throws it. The weapons panel shows the grenade in hand and how many. The number keys are the belt's alone.
- **Shift+R** locks the foe nearest to you; R still goes round them all.
- **Small shield and health bars** right over every foe's head.
- **The tactical view's colours a little softer** – the red, the green and the yellow.
- **Controls in two tabs, Space and Ground**, and every key on foot can be changed: walking, use, **run** (its own now,
  apart from the ship's thrust), **belt places 1–4**, next target, nearest target, grenade, dodge, other weapon, tactics,
  zoom. Bindings can be Shift+key (hold Shift while pressing the key; Shift alone when let go on its own). Saved on-foot
  bindings reset once to the new defaults.
- Debug "Fill the grenade places"; smoke tests extended.

## alpha 0.7.52.8 – 2026-11-11

**The tactical view zoomed out on demand (Luz).** While the tactical view is open, **Z** or the mouse wheel (down)
zooms the camera out to half – the whole reach of your weapon and the cover around it in sight; Z again or the wheel
(up) brings it back. It eases in and out, goes back to normal when the view closes and is remembered for the next time.
The legend shows the key; the key can be rebound ("On foot").

## alpha 0.7.52.7 – 2026-11-11

**The tactical view in the other side's colours (Luz).** In your green view the shadows – where foes are covered from
you – are now red; in a foe's red view the shadows – where you are safe from it – are green. The ground behind smoke
shows yellow and hatched in both. Legend and codex follow.

## alpha 0.7.52.6 – 2026-11-11

**Shield domes and smoke in the tactical view; the foe's view at its own weapon's reach (Luz).**

- **Shield domes** cast their shadow in the tactical view when seen from outside: in a foe's red view everything in
  the dome and behind it is dark – safe from it; from inside, your own green view goes out freely. In the fight, too, a
  shot from outside that crosses a dome now breaks on it, even when its target stands beyond it.
- **Smoke** marks, from the chosen side, the area behind the cloud – grey and hatched: shots into or through it aim
  badly (a third of their chance). The legend says so.
- **The red view reaches as far as the foe's own weapon** (labelled with its name and metres), so you can see how far
  it can shoot; your green view stays at your weapon's reach.

## alpha 0.7.52.5 – 2026-11-11

**Grenades, pirates and guards, and foe types with tactics of their own (package 52, the next round).**

- **Throwing grenades:** hold a grenade's belt key – a dashed arc to where the mouse points (up to ~13 m) and the
  blast's reach; let go to throw. A quick tap throws at the locked target. **Frag** (explosive, less further out, half
  behind low cover, nothing behind high cover), **EMP** (knocks shields down), **smoke** (a cloud: shots through it keep
  a third of their chance, foes do not see through it), **shield grenade** (a dome: fire and blasts from outside break
  on it and wear it down, your own fire goes out through it).
- **Foe types, each with its own tactic:** rusher (closes in, sidesteps), rifleman (cover facing you, moves on when
  flanked), **holder** (keeps its spot, sprays in bursts), **flanker** (runs round to your open side while the others
  pin you), **thrower** (keeps back and throws frag grenades as soon as you settle behind cover – their grenades show
  where they will land in red), **leader** (further back; its band keeps near it and loses heart when it falls), and
  Luz's **sniper** (90 % of its reach, in cover, far better aim, far slower fire – a red aiming line warns of its shot).
  Anyone with grenades throws one if you sit too long behind the same cover.
- **Pirates (Red Talon):** raider (flanker), gunner (holder), grenadier (thrower), sniper, captain (leader) – combat
  suits in black plate with red lights. **Guards:** trooper, heavy, sergeant (they only fight where weapons are allowed
  – for now the arena). The bandits' gunner holds, their boss leads.
- **Debug:** "Arena: pirate crew", "Arena: guard squad", "Arena: one sniper", "Grenades on the belt"; every foe kind in
  the spawn list. Codex entry, smoke test group `foot_tactics`.

## alpha 0.7.52.4 – 2026-11-11

**Threat tiers – a coloured ring at every foe's feet (Luz).**

- Every foe has a tier: **green** (very easy), **yellow** (middling) or **red** (dangerous), shown as a ring on the
  ground at its feet (with a dark edge, readable on any ground) and as a dot on its lock card.
- The tier scales the foe: body ×1 / ×1.6 / ×2.5, damage ×1 / ×1.7 / ×2.7, aim (Firearms) +0 / +2 / +4 and its gear's
  quality +0 / +1 / +2 steps (a rifleman's E rail carbine becomes a C one at red).
- Debug (F12 → Ground → Combat): **"Arena: 2 green + 1 yellow"** and **"Arena: 2 yellow + 1 red"**; the tier can be
  chosen when spawning foes. Codex entry and smoke test extended.
- Roadmap: the new foe types with their own tactics (flanker, thrower, leader – and Luz's **sniper**: 90 % of its
  reach, in cover, far better aim, far slower fire) moved to the next round; **ground combat drones** (laser, kinetic,
  kamikaze – launched from the pilot's back) noted for the end of the combat mechanics.

## alpha 0.7.52.3 – 2026-11-10

**Weapons with detail, shots from the tip, mightier fights, the tactical view at your weapon's reach (Luz).**

- **Every hand weapon has its own pixel picture** at the figures' fineness and in real size (pistols ~0.3 m, rifles
  ~1 m, the Long Rail ~1.5 m), in its maker's look: Axiom white with cyan cells, coils and emitters; Hadrian gunmetal
  with amber sights, rails and magazines; Forge of Return dark bronze with red glow seams, the scatter gun's double bore
  and pump, the Long Rail's scope and bipod; Concord's blue-white cutting beam with its focusing head; the olive
  grenade launcher with its drum. Held at chest height, turned straight at the target and mirrored when aiming left;
  facing away, the weapon is behind the body.
- **Shots leave the very tip of the weapon** – lasers, slugs and shells, for you and for the foes – in line with the
  barrel.
- **Mightier fights:** foes hit for 12 % of their weapon's damage (was 30 %) and have weaker bodies (scrapper 55,
  rifleman 60, gunner 65, boss 100 against your 100) – one against three is fairly easy with decent gear; standing in
  the open still hurts.
- **The tactical view reaches exactly as far as the weapon in your hands** – the green view and the red one (the
  target's sight within your reach) – with a clear ring at the reach, labelled with the weapon and its metres.

## alpha 0.7.52.2 – 2026-11-10

**The tactical view on Tab, the next target on R (Luz).**

- **R** locks the next target now (as R locks in space); a click still locks any foe.
- **Tab** opens the **tactical view**, drawn like the radar in space and lying on the ground under people and cover: a
  disc as far as your weapon reaches, with rings and a sweep. **Green** is everything in your sight; every piece of
  cover leaves its **radar shadow** – nothing behind bulwarks and walls, and right behind crates, barriers, rocks and
  barrels the dark band where a foe is covered from you (beyond it you shoot over the cover again). So you see where
  they hide and how to get round them.
- **Tab again** switches to the **red view – the locked target's sight** (its own weapon's reach): red it can hit, its
  shadows are where you are safe from it; the line at the top tells you whether you stand in its sight. Tab again goes
  back to your sight; **holding Tab** closes the view.
- Saved key bindings of the on-foot fight keys reset once to the new defaults. Debug: the tactical view from the
  Combat section; codex entry and smoke test extended.

## alpha 0.7.52.1 – 2026-11-10

**Package 52 begins – fights on foot (hybrid, after the mockup Luz approved).** For now in the **debug arena**
(F12 → Ground → Combat; the real places to fight come once the system stands – Luz).

- **Locking as in space:** when a fight starts the nearest foe is locked by itself (Luz: yes); Tab locks the next, a
  click on a foe locks it, a right click lets it go – up to three targets with red brackets (T1–T3), the active one
  thick, a short lock-on arc; lock cards top centre with name, distance, hit chance, their weapon and the bars for
  shield, armour and health.
- **The weapon fires by itself** at the active target when it is in reach and in sight; the hit chance comes from the
  weapon's steadiness, **Firearms**, the distance (past about half the reach it falls off), and the target – running,
  on a stimulant, in cover. Lasers draw the suit's energy, slug guns and launchers ammunition; Q puts the other weapon
  in hand. Shots fly (lasers at once), misses fly past and stop at high cover, damage numbers in the colour of the
  layer they reached.
- **Shield → armour → health** with the damage types' weights as on the ships; the suit's shield comes back after four
  quiet seconds on its energy, armour is mended aboard. The suit's bars now show shield and armour as they are.
- **Cover from the map:** crates, rocks, barrels and the new plated **barriers** are low cover – you shoot over them,
  shots at someone right behind them mostly end in them ("blocked", sparks); the new **bulwarks**, walls and the ship
  are high cover – no sight through them. A green half-ring and the line "IN COVER / PARTLY IN COVER / OUT IN THE OPEN"
  show where you stand.
- **Dodge on Space** (Luz: yes): a quick jump in your walking direction (sideways to the target if you stand), no shot
  lands during it; charges and their recharge from **Athletics**, jump jets make it ×1.6 longer.
- **Bandits** (Dust Rats): the scrapper rushes in with a scatter gun, the rifleman takes cover at range, the gunner
  sprays from a spot, the boss leads from cover with a laser rifle and a real shield. They notice you (sight, shots
  heard), call to each other, seek cover facing you and move on when you get round it, run when badly hurt, and fall.
- **Going down in a fight:** you wake in the clinic ("You went down in the fight"), the pockets emptied.
- **The weapon in the hands** of whoever fights, pointed at the target; the helmet closes for the fight.
- **Debug (F12 → Ground → Combat):** open the arena (world type to choose, with three bandits or empty), spawn any foe
  (quality, number, far or near), all foes down, end the fight, freeze them, the **AI view** (low and high cover, sight
  lines, states, layers, both hit chances), hit yourself or go down now, Firearms/Athletics 0/5/10; the status line
  shows the fight.
- Codex entry "Fighting on foot"; Athletics and Firearms now work (skill tree); keys Tab / Space / Q in the "On foot"
  group; smoke test group `foot_combat`.

## alpha 0.7.51.20 – 2026-11-10

**Fix (Luz): the hangar's guide line no longer runs through the wall by the lifts** – it stops at the wall and goes on
behind it.

## alpha 0.7.51.19 – 2026-11-10

**The hangar's wall by the lifts thinner (Luz).** The wall that sets the lifts apart is now a single tile thin, its top
along the end of the glass front and its face reaching down into the walkway; the glass runs its full length again.

## alpha 0.7.51.18 – 2026-11-10

**The hangar's lifts in a room of their own (Luz).** Between the glass front and the lifts the wall now juts out a row
into the walkway – two tiles wide, at full height – so the lifts sit in their own alcove; the walkway past it stays two
rows wide, nobody is placed inside the wall.

## alpha 0.7.51.17 – 2026-11-10

**Fix (Luz): the hangar's wall ends at full height.** On the hangar walkway the walls at both ends of the glass front
(by the stairs and by the lifts) now show their face like every other wall instead of only their top.

## alpha 0.7.51.16 – 2026-11-10

**Fix (Luz): more walls at full height.** The lift lobby's wall where it ends at the corridor (stations, cities) now
shows its face like every other wall; in the settlements the shop block's outer wall on its south side shows its full
height out in the open instead of only its top.

## alpha 0.7.51.15 – 2026-11-10

**Fix (Luz): the shops' back walls as high as every other wall** – on the stations' commercial level, in the cities'
shopping streets and in the settlements. Each shop's back wall now shows two rows of face like the lobby, the clinic
and the hangar; the shops are a row deeper so there is as much room inside as before, and their doors go through the
whole wall.

## alpha 0.7.51.14 – 2026-11-10

**Fix (Luz): the clinic's scanner out of the doorway.** The auto-surgeon with its scanner screen moved two tiles to
the left, clear of the treatment room's door (the easter egg moved with it).

## alpha 0.7.51.13 – 2026-11-10

**The clinic's lobby walled, and an easter egg (Luz).**
- The lift lobby is walled off from the corridor – a full-height wall face like the others (the end of the wall by
  the reception too); the way in leads through the reception.
- The auto-surgeon has a scanner screen at its head – glass in a frame with a scan line. **Step behind it and you
  show as a skeleton.**

## alpha 0.7.51.12 – 2026-11-10

**Fix (Luz): the clinic's walls along the corridor as high as the others.** The wall between the wards (and the
aesthetics studio) and the corridor showed only its top; it now shows its face to the corridor like every other wall,
its doors cut through it. The corridor and the rooms south of it moved down two rows.

## alpha 0.7.51.11 – 2026-11-10

**The clinic, a level of its own (Leitlinien 4, Luz).** Mercy Hall is no longer a room in the shop row – the lift
takes you there, on stations and in cities that have one ("Clinic – Mercy Hall, treatment and recovery").
- **The lobby** by the lifts; **the reception** with the hall's sign, screens, its counter with a nurse and a
  doctor (the treatment window), waiting seats and plants.
- **The wards** (Ward 1 and 2) along the corridor: two beds each with their patients (on the pillow, a drip, the
  monitor), a medicine cabinet, staff by the beds.
- **The recovery room** – where you come to now, beside a bed (after a lost ship, after a fall on foot); **the
  treatment room** with the auto-surgeon (a capsule under glass, its arm, its screen); **the pharmacy** with its
  cabinets and counter.
- **Aesthetics – Visage** (Luz): the image studio moved in as a room of the clinic – a sculpting chair under its
  scanner ring, a holographic bust of the face being made, a stylist, a sofa; the character editor opens there. Where
  a station has a clinic, the image studio leaves the shop row.
- Doctors in white coats, nurses in sky blue; clean light floors and walls, the clinic's colour in its signs and
  lights. The lifts name the clinic; F12 → Ground can go straight to it.
- Smoke test: the clinic's level (treatment window, image studio, recovery room, lifts), not in the shop row, the
  image studio in the shop row only without a clinic, waking in the recovery room, the debug level.

## alpha 0.7.51.10 – 2026-11-10

**The suits each their own, the combat suits dangerous, the helmet when you want it (Luz).**
- **Combat suits:** plates over a black undersuit – a chest plate with its seam and lights, a segmented belly,
  pauldrons, thigh, knee and shin plates, gauntlets. The **Light Combat Suit** white with cyan lights, its closed
  helmet with a broad dark visor and jaw guard – in profile the visor juts forward and the back flares; the **Heavy
  Combat Suit** gunmetal with red lights, broader, its pauldrons standing out past the arms, an antenna off its pack,
  a T-slit visor lit red.
- **Civilian and Survey Suits:** a hard white EVA helmet with a gold sun visor (the survey helmet with lamps and a
  camera at its side); the survey suit's cyan seams and shoulder sensor pod. **Work Suit:** reflective bands, a chest
  box with its lights, a hard yellow helmet with a lamp. Gloves on every suit.
- **The powers' guards** wear the combat suits in their power's colours, helmets on – Independent gunmetal with neon
  cyan, Assembly pale blue-grey with blue, Covenant dark red with gold, Directorate white with green; some posted
  guards in the heavy suit.
- **Helmet: When needed / Always** on the Gear page (saved): when needed it is on where the air cannot be breathed
  and in a fight (the fight trigger is ready for combat on foot, which comes later); always – outside and aboard.
- Smoke test: every suit looks its own with and without its helmet, the guards' four liveries, the helmet setting
  saved.

## alpha 0.7.51.9 – 2026-11-10

**Fix (Luz): the Gear shop showed itself twice, one under the other.** The shop did not clear itself when it was
rebuilt – after a purchase or when the window changed its size the new front was stacked under the old one. It now
starts afresh on every rebuild. Smoke test: after rebuilds there are still exactly four tiles in front.

## alpha 0.7.51.8 – 2026-11-10

**The Gear shop rebuilt (Luz, with a sketch).** Three steps deep, with pictures, instead of one long list.
- **The front:** four big picture tiles in a showroom lit in the shop's colour – **Suits** (the pilot standing in a
  suit on a lit plinth), **Weapons** (a gun rack), **Features** (the suit's modules), **Belt** (tools, grenades,
  consumables) – each with how many pieces this shop has; under them *Sell from your pockets*. The tiles share the
  window's width and grow with its height (they follow the window when it is resized).
- **A category's kinds** as picture tiles: Suits – Civilian & work, Combat; Weapons – Lasers, Slug guns, Explosive;
  Features – Defence, Movement, Life support & supply; Belt – Tools, Grenades, Consumables. A kind the shop does not
  carry is dimmed.
- **A kind's list:** each piece with its picture, name and description, its numbers in columns (weapons: damage,
  rate, range, what a shot uses; suits: slots, shield, armour, energy, air, speed; features and belt: their effect)
  and a button per quality F–A in the quality's colour with its price – the numbers at that quality on the button's
  tooltip; qualities this shop does not carry are greyed.
- A path along the top (GEAR › WEAPONS › SLUG GUNS) with *‹ Back*, the free pocket places and your credits.
- Smoke test: four tiles in front, three kinds of weapons, a list with quality buttons, buying from it, the front's
  height following the window.

## alpha 0.7.51.7 – 2026-11-10

**The Gear page like the ship menu (Luz).** The pilot window's Gear tab now follows the pattern of the ship menu's
FITTING – tiles with pictures instead of lists of buttons.
- **Left, the suit as a mockup:** the pilot standing in the suit they wear (helmet on), its name in the quality's
  colour, maker, quality and slots; health, shield, armour, energy, oxygen and ammunition as coloured bars; the
  protection against heat, cold, toxic air and vacuum as bars; walking speed.
- **Below it, the piece picked** (like "Select a module"): its picture, name, where it sits, everything it does – and
  the buttons for it: *Take off → pockets* (worn), *Put on* and *→ Locker* (in the pockets), *← Into the pockets*
  (in the locker).
- **Right, tiles:** Suit, Weapons, Belt (each place with its key 1–n), Features, the 12 places of the Pockets and the
  ship's Locker (aboard or in the hangar) – frame and corner in the quality's colour (F–A), stacks with ×n, the tile
  picked framed green.
- **A pixel icon for every piece** (new `gear_icons.gd`, 24×24 like the module icons): the suits in their colours,
  lasers glowing cyan, slug guns in steel, the launcher, grenades, scanner, cutting torch, mining laser, medkit,
  stimulant, energy cell, oxygen, ammunition, and the features (shield generator, plates, sprint booster, jump jets,
  temperature regulator, oxygen reserve, ammunition pack, battery).
- Smoke test: every piece has its icon, the page shows a tile for the suit, each slot and each pocket place, and
  picking a piece in the pockets and *Put on* puts it on.

## alpha 0.7.51.6 – 2026-11-10

**Sci-fi buildings on the ground (Luz: "buildings that look like suburban houses won't do at all").** Every building
of the settlements rebuilt as a real sci-fi building, at the realistic scale (a storey ~2.6 m, doors 2 m) – no pitched
roofs, planks, shutters, flower boxes, rubble stone or adobe any more.
- **Eight architectures:** Independent – the armoured **hab** (big plates with bolted seams, heat-exchanger fins on
  the roof, deep rounded windows, a pressure door under a plated canopy, neon sign, cables), **stacked hab pods**
  with light seams and a steel stair, **pressure halls** of armour segments with glowing seams; Assembly – the
  **terrace** of pale composite and glass (a glass front per storey, a terrace with a glass railing, roof gardens, a
  glass dome) and **habitat domes** with a glazed crown; Covenant – the **spire** of great dark red-brown slabs,
  buttresses with gold lines of light, lancet windows lit gold, a parapet of pointed merlons and a spire, red
  banners, a metal blast door in a pointed gold frame; Directorate – white **modules** with a hexagonal crown and
  solar panels; dry worlds – **printed regolith** (smooth, faint layers, rounded, slot windows behind louvres, a
  portal round the door, sand filters).
- **Worlds without air:** every window a porthole, every door an airlock (hazard frame, hatch, green status light);
  domes and pressure halls more often.
- **The other things in the street, sci-fi too:** the wooden power pole is a steel power mast with its energy line,
  the striped canvas awnings over the shops are plated canopies lit underneath, market stalls have a metal counter
  and a holo sign, the signpost is a pylon of lit arrow plates, the lookout tower steel with a glazed cab, the fish
  farms' walkway steel grating on pontoons, the practice targets project rings of light.
- Smoke test: every settlement building is one of the sci-fi architectures, sealed exactly on airless worlds, and
  every architecture paints (sealed and not).

## alpha 0.7.51.5 – 2026-11-10

**Debug functions for packages 49–51** (F12 → new tab **Ground**) – every package brings its debug functions
(Leitlinien 1.5); these were missing for walking, landing, cities, settlements, gear and the clinic.
- **Status line:** where you are on foot (place, level, the world outside, daylight), docked at, health, energy,
  oxygen, ammunition, the suit.
- **On foot (49, 50):** open the deck of the docked station (in a city its hangar); straight to a level – hangar or
  commercial level on a station, hangar, shopping street or tower bar in a city.
- **Landing (50):** descend at once to any body of the system (the planet map opens); land straight at a city,
  outpost, mine, research camp or landing field – optionally seeing the body as another world type, with a
  settlement's economy forced, at a chosen hour. If the body has no such place, a debug place is added (not saved).
  Set the time of day where you are (day, dusk, night, dawn) – every world turns on with it.
- **Gear, the world outside, the clinic (51):** any piece by family and quality (F–A) into the pockets, fill the belt,
  refill the suit, empty the pockets; set health, energy, oxygen or ammunition to a percentage; **suit invulnerable**
  (the world outside does not hurt – energy and oxygen still drain); force the world outside on the current map
  (any world type, or back to the place's own); collapse now; wake in the clinic of the station or city you are
  docked at.
- The debug menu keeps itself inside the screen (seven tabs, narrower tab buttons).
- Smoke test: a check for all the new debug commands; `--only=debug_shot` (windowed) saves a picture of the tab.

## alpha 0.7.51.4 – 2026-11-10

**The clinic, and where you wake (Luz).** Package 51 is complete.
- **The Clinic (Mercy Hall)** is a real room on every station's commercial level and in every city's shopping
  street – two beds with their monitors along the wall; treatment heals what is hurt (paid by what is missing).
  Settlements have none.
- **Ship lost:** after the buy-back window you wake in the clinic of the last station you docked at.
- **Fallen on foot:** you wake in the clinic of the nearest city in the system (your ship is taken to its hangar) –
  if there is none, at the last station (the ship with you). What was in your pockets is gone; you come to weak.
- A codex entry on suits and personal gear.

## alpha 0.7.51.3 – 2026-11-10

**The world outside: energy, oxygen, what gets through.**
- **Each kind of world has its air and its hazards:** terran, ocean and jungle worlds good to breathe; deserts hot;
  ice worlds cold and thin; lava worlds hot and toxic; metal worlds toxic; rocks, dwarfs and most moons airless
  and cold; icy moons bitterly cold; volcanic moons hot, toxic, almost airless.
- **Outside** (landing fields and settlements – not under a roof, not in a city or on a station) **the suit works:**
  its life support keeps out what it can and draws energy for it; what gets through (by the suit's protection)
  hurts; where the air cannot be breathed the oxygen tank empties – empty, you suffocate. The shield generator draws
  energy all the time, the sprint booster while running. If the energy runs out, the life support stops.
- **The helmet goes on** where the air is not to be breathed or poisoned – and the townsfolk and guards out there
  wear suits and helmets too.
- **On foot, the suit's bars:** health, shield, energy, oxygen (where it is used), ammunition; the hazards and how
  much of each gets through; the belt along the bottom, its places on the **number keys** – medkits, stimulants
  (quicker for 20 s), energy cells, oxygen cartridges and the new **ammunition boxes** work; warnings when energy,
  air or health run low.
- **Charging points** by every landing pad (the fuel points) fill the suit's energy and oxygen; back aboard, the
  ship charges the suit and the medbay sees to you.
- The suit's weight and plates slow you, a stimulant and a sprint booster speed you up.
- If your body gives out outside, for now the landing drone's autopilot carries you back up (the clinic follows).

## alpha 0.7.51.2 – 2026-11-10

**The Gear shop, and the pilot in the suit.**
- **Gear (Fieldkit Outfitters)** – the personal outfitter: a walk-in shop on the stations' commercial level, in the
  cities' shopping streets and in every settlement (the settlements' street grew a shop longer). Suits, weapons,
  features and tools by family, a button per quality with its price; grenades and consumables; sell what is in
  your pockets for half the price. What you buy goes into your pockets.
- **What a shop carries follows the place:** the best quality as the ship outfitter's (C at small places, B and A at
  bigger stations, in high-tech and rich systems, A in military ones); combat suits and heavy weapons in military
  systems and at the bigger stations; a settlement sells the plain things (civilian, work and survey suits,
  sidearms, tools, consumables – war gear only in military systems).
- **The pilot walks about in the suit:** its colours, plates on a combat suit, the life-support pack on the back,
  the straps over the shoulders; the first weapon slung across the back (a laser glowing); a helmet with its glass
  dome is ready for 0.7.51.3 (outside on worlds whose air is not to be breathed). A new suit shows at once.

## alpha 0.7.51.1 – 2026-11-10

**Package 51 begins: personal equipment (Luz: the suit like a ship).**
- **The suit is the pilot's hull:** its class sets how many weapon slots, belt places and feature slots there are
  and how well it keeps out heat, cold, toxic air and vacuum – the **Civilian Spacesuit** (1 weapon · 2 belt ·
  1 feature), the **Survey Suit** (1 · 3 · 2, the best life support), the **Work Suit** (1 · 4 · 1, plated), the
  **Light Combat Suit** (2 · 3 · 2, quick, a strong shield) and the **Heavy Combat Suit** (3 · 2 · 3, heavy plate, a
  deep magazine – slow and short of air). Quality F–A gives a better base shield, more ammunition, more armour,
  more energy and oxygen.
- **Every suit has energy** (shields, tools and the life support will draw on it) **and an oxygen tank.**
- **Weapons F–A, no sizes:** optical (laser pistol, laser rifle, cutting beam – strong against shields, on the suit's
  energy), kinetic (slug pistol, burst gun, rail carbine, scatter gun, long rail – strong against armour, on
  ammunition), explosive (grenade launcher – strong against the body, bursts). Shooting comes with package 52.
- **The belt:** frag, EMP, smoke and **shield grenades** (a dome of shield that turns fire from outside and lets
  yours out), tools F–A (scanner, cutting torch, mining laser), medkits, stimulants, energy cells, oxygen cartridges
  – stacked, on the number keys.
- **Features** (the suit's modules): shield generator, armour plates, sprint booster, jump jets, temperature
  regulator, oxygen reserve, ammunition pack, battery pack.
- **Pockets** (12 places) and **a locker in every ship** (12 / 20 / 30 places by the ship's size), at hand aboard and
  in the hangar beside her.
- **The pilot window has a Gear tab:** the suit and what it adds up to (health, shield, armour, energy, oxygen,
  ammunition, speed, protection), its slots, the pockets and the locker – click to put on, take off, store, fetch;
  point at a piece for what it does. A suit change puts what no longer fits into the pockets.
- New pilots start in a civilian suit (F) with a laser pistol, two medkits and an energy cell.

## alpha 0.7.50.17 – 2026-11-10

**The small places from the air (Luz: "far too big – small lights like the cities, with what marks them, bound to
the land").**
- **Settlements in the flight down are small now and drawn like the cities:** a short street of houses (roofs by
  day, lit windows by night, now and then one going dark), its lamps, the way to its four pads with their blinking
  lights – and beside it **what it lives from**: an open pit with its terraces and the lights of the haul trucks
  going round, fields in their colours with their rows (glowing greenhouses where nothing grows outside), halls with
  smoking stacks and a red light on top, a tank farm with its flare, a dish array with its beacons, a training yard
  with a vehicle crossing it, gardens. Fish pens out on the water where the sea is near.
- **Bound to the land:** houses, roads and the economy area only on land (the area goes towards the land and away
  from the pads), the pens only on the sea.
- Ruins and crash sites small and dark too (scattered walls; the furrow the wreck ploughed, a fire on it).
- **Night lies over the land** in the flight to a city or a settlement at night.
- **No engine flame on the way down** – neither in space nor in the flight (Luz); on the way up it stays.

## alpha 0.7.50.16 – 2026-11-10

**The way down and the sizes (Luz: "the flame far too big", "the shuttle gigantic next to the Threshold").**
- **The descent's flame keeps to the ship's size** – it shrinks with her as she sinks (it used to stay as big as
  the heat round her). Drawn new: its glow, a rounded flame in four layers, the white-hot core, shock diamonds.
- **The heat of the way down, drawn new and in more detail:** a bow shock shaped round her nose in three layers
  (white-hot at the stagnation point, orange, a dim red edge), flickering at its rim; a plasma wake streaming back
  from it, swaying and thinning out, turbulent bands in it; streaks flowing over the shell; sparks of the ablating
  hull shed behind her; a soft glow of ionised air round it all – added light, so it glows.
- **The landing drone and the ship to their real sizes:** the drone (~10 m) beside the ship by her real length –
  next to a scout it is a third of her, next to a Threshold (124 m) a speck under her belly. For the catch the view
  comes in close: the drone big enough to see, a big ship filling the sky over it; she flies higher on the screen,
  the drone climbs up to her from below. Her flame starts at her tail, as big as she is.
- The 2D anti-aliasing setting is gone (the Compatibility renderer does not support it – Godot warned about it on
  every start).

## alpha 0.7.50.15 – 2026-11-10

**Taking off, the landing drone, the pads (Luz, after playing).**
- **Taking off asks where to:** at the drone's ramp (or the stairs to your ship in a city's hangar) a small panel –
  **1. back to orbit** or **2. to the planet map** to pick another place on the same world, without the climb to
  orbit and the way down again.
- **The landing drone is a dropship now:** a fuselage for four (four portholes along its side) with the vehicle bay
  aft under a roof hatch, the cockpit canopy wrapped round its nose, four ducted lift fans on stub wings, two
  thrusters at the tail, a dorsal spine with a sensor housing and a mast, red and green nav lights, a band in the
  line's colour – about 8 m long, as big as it must be for four people and a vehicle.
- **Its ramp is animated:** after the touchdown the side door slides up (the lit cabin behind – seats, the rover's
  flank) and the ramp folds down on its struts, its rail lights running; you walk down it. Going back you walk up
  it, it folds up behind you, then the drone lifts off. The other drones on the pads lower and raise theirs too.
- **The drone is caught by the ship:** back up by the drone, it climbs off the pad while the ground falls away
  below, the clouds close in, the ship comes down over it out of the sky, takes it up into her bay on a tractor
  beam – a flash as the clamps close – and pulls away. Then orbit or the planet map.
- **The landing pads in detail** (and bigger, for the new drone): slabs each a little their own with seams, cracks
  and stains, the scorch of the lift-offs round the middle, the touchdown ring with its H, a hazard band round the
  edge with a white line inside, corner brackets, the pad's number painted big, edge lights in their housings,
  drainage grates, tie-down rings, a fuel hatch; a fuel point by each pad, a hover cargo loader on the apron.
- **The pads' lights live:** dim and steady while a pad is clear, a running chase towards it while a drone comes
  in (outwards while one lifts off), cyan while one stands on it – and beside each PAD sign its status: CLEAR,
  INBOUND, DEPARTING, OCCUPIED, YOUR DRONE.
- The settlements' landing field: two pads north of the street, two south of it, the street running out between
  them; the town begins east of it.
- The hint under the title fits the place (no more "the stairs in the hangar" in a settlement).

## alpha 0.7.50.14 – 2026-11-10

**Settlements in the future (Luz: "the vehicles look very 21st century – make them sci-fi").**
- **The machines, new:** the **ore hauler** runs on two armoured track pods with glowing seams between their plates,
  a chamfered hexagonal hopper with hazard chevrons and a light line, heat vents glowing along its spine, a canopy dome
  with a glowing visor band, a sensor mast (crystals glinting in its ore when loaded); the **mining platform** floats
  on three anti-grav pads with a glowing reactor behind its vents – its articulated arm with glowing joints and a
  light line, a **cutter claw** with a plasma edge; the **harvester glider** hovers on its glowing skirt with an
  intake rotor and a cutter bar of light; a **hover tanker** on skids with a capsule tank and glowing ports; a **hover
  tank** with a twin-barrelled turret in its energy coil; a **hydrofoil** work boat with its jets.
- Whatever floats bobs gently and lights the ground below it.
- **The plants:** exhaust towers with plated rings and light between them and a hot vent on top, tanks with a light
  band and status lights, dishes with a glowing emitter, the rig's derrick with an energy core, fence posts with
  lights, the parked armoured vehicles and rovers on hover skirts and skids.
- **The buildings:** a light strip under the eaves of the prefab halls, modules, quonsets and containers, and a lit
  access panel beside every door.

## alpha 0.7.50.13 – 2026-11-10

**Settlements to scale (Luz: "the sizes are all off").**
- One scale for everything in the settlements, set by the people (about 15 art px a metre): a storey ~2.6 m, doors
  2 m high, windows about a metre, street lamps ~4 m, trees 7–10 m, a container 12 m long and 2.6 m high.
- **Buildings** grew to it: taller fronts, bigger doors with glass and canopies, windows with transoms, curtains and
  now and then someone inside, shutters with slats, stone windows as tall pointed arches, wider houses; containers,
  domes (portholes, an airlock as big as a door) and quonsets to match.
- **The machines are drawn new, at their real size** (pixel pictures with wheels, cabs, ladders, beacons):
  a **haul truck** with tyres taller than a person, the **excavator** with its boom, stick and bucket, a **combine
  harvester** with its turning reel, a **tanker**, an eight-wheeled **armoured vehicle**, a **work boat**.
- **The mine is seen from its rim** (as Luz suggested): the berm with its marker posts, then the pit falls away –
  rock faces with their strata, benches with tyre tracks and safety berms, the haul road cut down across the faces;
  a haul truck on the first bench, the excavator loading another on the next, a third far down – the deeper, the more
  in the haze.
- The other areas to scale: 12 m containers two high under a ten-metre gantry crane carrying one, chimneys 13–15 m,
  great tanks with stairs winding up, big dishes with ribs and their feed, armoured vehicles, a lookout tower,
  silos; the trees at the bottom edge stay low (no longer hiding the shops).

## alpha 0.7.50.12 – 2026-11-10

**Settlements: what the place lives from, around it.**
- East of every settlement, behind a fence where the street ends (a lookout with a railing, a sign), lies its
  **economy area** – alive:
  - **Mining:** an **open pit** stepping down in terraces (strata in their faces, a pool at the bottom), the ramp
    winding into it; a big **excavator** at the bottom swinging its arm, **haul trucks** winding up and down the ramp
    (loaded on the way up, dust behind them), a **conveyor** running to the ore heaps, the headframe.
  - **Farming:** **fields** of different crops (golden grain, green, dark green, purple) with an irrigation channel and
    silos; a **harvester** working its rows (the cut rows behind it), **crop drones** spraying. Where nothing grows
    outside (ice, rock, lava, toxic worlds, airless moons): **hydroponics** – rows of greenhouses and domes.
  - **Industry:** halls with smoking **chimneys**, a pipe run, rows of stacked **containers** under a **gantry crane**
    moving a container along its rails, pallets and barrels, a truck on its round.
  - **Refinery / chemistry:** a **tank farm** with pipe runs between the tanks and a **flare** burning.
  - **Research / high tech:** a **dish array** with cables between the dishes, a control building, a rover, and a
    **launch pad** – now and then a rocket goes up (the countdown lights, flame and smoke).
  - **Military:** a **training yard** with targets, parked armoured vehicles, one on its round, a patrol drone.
  - **Tourism:** **gardens** with trees, palms, flower beds, a fountain, a lookout tower, birds.
  - **On ocean worlds:** **fish pens** floating on the sea with a boardwalk between them and a boat going round – or
    an **offshore rig** on its platform with its flare.

## alpha 0.7.50.11 – 2026-11-10

**Settlements in detail – every building its own (Luz: "too chibi, too boxy").**
- **Eight architectures**, each building drawn on its own (roof from above, front below, its own seed): **prefab**
  halls under corrugated metal (ridges, rivets, rust streaks, a canopy over the door, pipes, a neon sign), **stacked
  containers** in different colours with a ladder, **quonset** halls (a ribbed half-barrel roof, the door in the end
  wall), **habitat domes** in rings with portholes and an airlock in hazard stripes, **gabled houses** with tiled roofs
  (moss on the tiles), plastered or planked walls, shutters and flower boxes, **adobe** with a parapet, rounded
  corners, deep windows, an arched door and a canvas awning, **stone houses** with slate roofs and gold-lit
  pointed-arch windows, and white **modules** with a long window band and a light strip.
- Which one by the power that built it (independent: prefab, containers, quonsets; Assembly: gabled houses, domes;
  Covenant: stone; Directorate: modules, domes) and by the world (adobe in the desert, domes and quonsets on ice,
  rock and lava worlds); one or two storeys, each its own colours.
- **On the roofs:** air units with fans, water tanks, solar panels, antennas with their lights, small dishes, vents
  and skylights, planters, laundry lines. **On the walls:** windows with frames, sills and curtains, the sky in the
  dark ones, meter boxes, pipes, lamps over the doors, steps, grime along the foot.
- **Two rows of houses** now, the special building with two storeys; between them market stalls with striped
  awnings and goods, power poles, crates and barrels, undergrowth; a parked rover by the pads, a signpost.
- **The world's edge in detail:** trees of several kinds and sizes (broad crowns of many clumps with vines and
  flowers in the jungle, conifers in the woods, palms), ferns and bushes with berries in the gaps; groups of boulders
  with facets and cracks (moss on toxic worlds, glowing seams on lava worlds); dunes with rocks; on ice worlds
  snowdrifts, ice shards of every height and snowy rocks.
- The shops along the street each have their own striped awning; the prompt on foot has a dark outline (readable on
  snow and sand).

## alpha 0.7.50.10 – 2026-11-10

**Settlements – the small places come alive.**
- Outposts, mines and research camps are now **settlements under the open sky**, one walkable map: your landing drone
  comes down on one of its **four landing pads** – on the others, other landing drones come and go (dropping in from
  above with their shadows closing in, setting down in a puff of dust, waiting, lifting off), their beacons blinking.
- **The street** runs from the pads past the settlement: its **shops** on the south side – walk in, as on a station
  (market, outfitter, bar, repair bay, bulletin board, news, as the place has them) – houses on the north side with
  lit windows, lamp posts, crates, the fuel pump by the pads.
- **The building it is known for**, by what it lives from (a mine always mines, a research camp researches, an
  outpost lives from its system's economy): an ore depot with its headframe, ore cart and spoil (mining), an agri
  co-op with greenhouses and a silo, a workshop, a refinery outlet or chem plant with its silos, a tech lab or
  research station with its dish, a recruitment office with banners (signs on crew), a lookout hotel.
- **What bounds it is its world:** dense jungle on jungle worlds, woods on terran ones, **the sea round its platforms**
  on ocean worlds (a gangway between them, buoys blinking), dunes in the desert, ice shards on ice worlds, a crater's
  rocks on barren worlds and moons, cooled lava glowing on lava worlds.
- Guards walk their rounds (one posted by your drone), its people go about; a settlement works like a station (its
  own market, by the kind of place); in its power's colours; day and night as in the cities.
- Ruins and crash sites stay landing fields for now – they become POIs (package 53).
- Codex: **Settlements**.

## alpha 0.7.50.9 – 2026-11-10

**City guards.**
- Guards stand in the cities now – posted by the lifts and the stairs to your ship, others walking their rounds
  through the hangar, the shopping street and the tower bar; more of them the safer the system. They wear their
  power's uniform (contract security in a free city, the Assembly's militia in navy and white, the Covenant's Wardens
  of the Road in crimson and gold, the Directorate's civic order in white and green), an armoured suit and a visor,
  a rifle slung across the chest and a lamp blinking on the shoulder.
- Walk up to one and speak to them ([E]) – they have a word for you, in their power's way. Weapons stay holstered in
  the city.
- The hangar flags carry their power's sign: the Assembly's ring, the Covenant's sun road, the Directorate's compass.

## alpha 0.7.50.8 – 2026-11-10

**Sunset from the tower bar – the day goes on while you are in the city.**
- The time of day in a city now goes on while you walk in it (before, it was fixed when you came down): the sky
  outside, the street's light and the light falling through the bar's glass follow the sun as it goes round.
- **Dusk and dawn:** the sky turns to the colour of the star's setting light (a red dwarf's deep red, a blue star's
  violet, a yellow sun's orange), the towers glow in it, the sun sinks low and big behind the towers in the west (or
  rises in the east), the light through the bar's window turns to sunset, and the windows of the city come on one by
  one – the red lights on the tops start blinking, the neon brightens. At dawn the other way round.
- The street: its light warms at dusk and darkens into night (the lamps and neon taking over), and brightens at
  dawn.

## alpha 0.7.50.7 – 2026-11-10

**Cities: a ground plan for every kind of world, the worlds turn, bar and hangar in the city's style.**
- **Ground plans from the air:** a city's form now follows its world – on terran worlds it spreads out round its
  heart; on **ocean worlds** it crowds along the coast with piers reaching out into the sea and platforms floating on
  it; in the **jungle** (and on lava worlds) its quarters lie in clearings, roads running between them; in the
  **desert** it is a dense square behind its wall with an oasis inside; on **ice and toxic worlds** its quarters sit
  under domes linked by tubes; on **barren worlds and rocky moons** it stands on a crater's rim and in its middle;
  metal worlds are a grid. And its streets follow who built it: crooked avenues (independent), ring roads and parks
  (Assembly), spokes to a great cathedral square (Covenant), a strict grid (Directorate). By night its lights, by day
  its roofs, parks and streets – always only on land (piers and platforms only on the sea).
- **The worlds turn:** the sun goes round every world – a day lasts 20 to 40 minutes of play, each world its own
  length and hour – so the same city can be visited by day and by night. The planet map shows where the sun stands
  now (the night side dark, the cities there glowing) and says for each city "Day there now · sunset in about N min"
  or "Night there now · sunrise in about N min".
- **The bar and the hangar in the city's style:** the decks take the power's colours and the bar its furnishing –
  a neon lounge (independent), a garden bar with planters (Assembly), long tables on red carpet with banners
  (Covenant), a bright cafe with holo pillars (Directorate); the hangar hangs its power's flags on its walls (blue with
  the white hand, red with the gold sign, green and white – neon posters in a free city).

## alpha 0.7.50.6 – 2026-11-10

**The cities refined: four building styles, day and night, a street canyon, a city that stands up.**
- **Four styles – who built the city:** **independent** cities are the cyberpunk sprawl (dark crowded towers, neon of
  every colour, antennas, fire escapes, paper lanterns over the street); the **Assembly** builds light stone and glass
  with domes, terraces and roof gardens, green balconies, warm windows and strings of bulbs; the **Covenant** builds
  dark red-brown stone with pointed spires and pinnacles, narrow gold-lit windows under pointed arches, long red
  banners with the gold sign and pennants over the street; the **Directorate** builds white towers on a strict grid
  with chamfered hexagonal crowns, solar roofs, whole floors of cool white light and green light bands. The street's
  made-up shop fronts follow the style too (co-op market and voting booth; chapel, reliquary and pilgrim hostel;
  institute, exam hall and data cafe …).
- **Day and night:** every city lies on the day or the night side of its world – where the planet map shows it –
  and keeps it: the flight down, the landing hatch, the street and the view from the tower bar are lit by day (sun,
  clouds, glass catching the sky, the street bright, the neon faint, sunlight falling into the bar) or by night (lit
  windows, glowing neon, red lights blinking on the tops, the street dark under its lamps).
- **The street canyon:** the shopping street is no longer a room – above the shop fronts the buildings rise into the
  sky, storey on storey of windows, balconies, fire escapes, air units, signs and banners, a strip of sky at the top
  with speeders crossing it, strings of lights hanging along the street.
- **The landing hatch's city stands up:** towers seen a little from the south – their fronts with floors of windows,
  their roofs in the style's way (domes and roof gardens, ridged roofs with spires, hexagonal roofs with solar panels,
  air units and flyer pads), their shadows on the ground by day.
- **The flight down:** the city now lies on the ground and comes with it (no longer faster than the ground), always
  on land – its lights (by night) or its roofs (by day) only where there is land, never on the sea; the dark rings
  round it are gone.
- The tower bar's window front is square in a city (no space-station corners); the title on foot has a dark plate.

## alpha 0.7.50.5 – 2026-11-10

**Package 50b begins: the cities – down through a landing hatch, into the city's hangars, its shopping street and
the bar high up in its towers.**
- **The landing hatch:** most ships are far too big for a city's streets, so a city takes them in below the ground.
  Seen from above – the roofs of the city at night all round (towers with air units, roof gardens, flyer pads, neon
  edges, blinking warning lights; streets with their lamps and cars) – your ship comes down over a giant hatch with
  hazard stripes; its lamps blink amber, its two leaves slide apart, the shaft below shows frames of light running down
  into the deep; she sinks into it, darker and smaller, and the hatch closes over her (lamps green while it is open).
- **A city works like a station:** it has its own market, outfitter, shipyard, bonds, bar with crew to hire, news and
  bulletin board – its kind follows the world it stands on (trade cities on terran and ocean worlds, industry on
  deserts and lava worlds, ice refineries on ice, mining towns on barren rock, research on toxic worlds …).
- **The city's hangar:** you arrive beside your ship, as on a station (the hangar and shipyard shops on its walkway).
- **The lifts:** Hangar · Shopping street · Tower bar.
- **The shopping street:** busy – the real shops on its south side, on its north side a row of made-up shop fronts
  (noodle bar, cyberware, karaoke, tea house, pawn, hotel …) with lit windows, striped awnings and neon names, lamp
  posts, vending machines and plants between them.
- **The tower bar:** the bar high up in the city's towers (its floor on the title) – out of its window front the city
  at night: towers far and near with their lit windows, neon running down them and red lights blinking on their tops,
  speeders in their lanes with light trails, drones drifting past; the layers move at their own pace as you walk.
- **Leaving:** down the stairs to your ship – the hatch opens, she rises out of the shaft, it closes under her and she
  climbs back to orbit.
- Codex: **Cities**.

## alpha 0.7.50.4 – 2026-11-10

**Cities as lights, and a landing drone for the small places.**
- **Into a city:** no more drawn blocks – the city comes up out of the dusk as its lights: fine strings of light
  along its avenues, hundreds of tiny warm windows, densest and brightest in its heart, now and then one going out.
  Your ship sinks into them, growing smaller and smaller until she is a speck among the lights.
- **The landing drone:** every ship carries one. Small places (outposts, mines, ruins, wrecks, camps) are not landed
  at by the ship herself: halfway down the drone bay flashes, the small lander drops out of it with its own flame,
  your ship pulls up and away, and you follow the drone down. It sets down on the pad in its cloud of dust; to get
  back up you board the landing drone, which flies you back to your ship.

## alpha 0.7.50.3 – 2026-11-10

**The landing gets its way down – no more hard cuts.**
- **Into the planet:** as the ship sinks, the camera follows her down (zooms in); at the end the heat flares into a
  white flash that turns to black (on airless moons just black), and out of the black the planet map fades in – the
  planet turning into place, its places lighting up one after the other with a little flash, then the list.
- **The flight down (seen from above):** after picking a place you fly down to it – the planet's own ground passes
  below (seas and coasts and continents, dunes, ice, glowing lava cracks, craters – in its colours) and comes closer,
  your ship's shadow closes in on her, clouds drift between you and the ground where there is air, the last of the
  entry heat fades, the engine burns; at the end the place itself comes into view on its patch of land – the blocks
  and lit windows of a city, the domes of an outpost or camp, a pit mine, ruins, a wreck with its scorch mark – and
  its landing pad, its lights blinking, slides under you.
- **Touchdown:** the ship comes down onto the pad from above – big at first, near to you, her shadow meeting her –
  sets down in a cloud of dust (in the ground's colour) with a jolt, and you walk down her ramp.
- **Lift-off:** up the ramp, dust, the ship rises off the pad, bigger, and is gone upwards; a white flash, and she
  climbs out of the planet into orbit while the camera pulls back.

## alpha 0.7.50.2 – 2026-11-10

- **Fix – no way down at the beacon:** a selected descent beacon now has a **Descend** button (also the dock key);
  the ship flies to the beacon – warping first if it is far – and goes down. Before, only *Warp to* and *Approach*
  were offered.

## alpha 0.7.50.1 – 2026-11-10

**Teil 7, package 50 begins: down to the planets.**
- **Descent beacons:** over the middle of every planet and moon with solid ground (not the gas giants) hangs a descent
  beacon – a small probe with three blinking arms and rings pulsing out from it; from there the planet below looks
  its biggest. It is in the overview (▼) and a warp target; click it, and the ship flies there and goes down.
- **The way down:** the ship speeds up along its heading, flame bright, then sinks – smaller and smaller – into the
  world below. On worlds with an atmosphere it glows: a bow shock of heat in front of it, plasma streaming past, a
  glowing ball sinking away. On airless moons it just drops, cold and quiet.
- **The planet map:** below, the planet fills the screen, its places marked on its face – cities (on worlds people
  like, more where the night side glitters), outposts, mines, ruins, crash sites, research camps – and listed beside
  it with a word about each. Pick one and land, or go back to orbit.
- **Landing:** you stand on the landing field at the place: the planet's own ground all round, a concrete pad with
  your ship on it, her ramp down, lights along the pad, fuel and crates, and a gravel path to the place itself. Walk
  up the ramp and the ship climbs back to orbit – out of the planet, small and glowing, growing, on its way.
- While you are down, your ship counts as docked (safe, hidden); a game saved on the ground opens the planet map
  again. The cities themselves – streets, shops, people – come with the next update.
- Codex: Landing on planets.

## alpha 0.7.49.14 – 2026-11-10

- **A look at your ship:** sit down on the bench in the hangar and the camera glides over to your ship and centres
  it; stand up and it glides back to you.
- **The view from the bar:** the star and the planet the station circles now always stand in the part of the window
  front you can see – whatever the screen size and wherever you stand – as things far away do.
- The camera on the deck eases now instead of jumping.

## alpha 0.7.49.13 – 2026-11-09

**The bar works, the station window stays shut on foot, every ship its own hangar.**
- **At the bar:** sit down on a bar stool (or E at the counter) and the bartender talks to you: *A drink, please*
  (Nebula Ale, Pulsar Punch, Void Whisky, Orbital Cola – a few credits; the glass goes up to your mouth; alcohol is
  noted for a debuff to come and wears off with time), *What's new?* (funny, useful or nonsensical bar talk) and
  *Who's looking for work here?* (the crew window). The bartender has a name.
- **On foot, no way back into the station window:** a service opened from the deck shows only that service – its
  button says *‹ Back to the deck*, closing it puts you back on your feet; the station hotkey does nothing while you
  walk.
- **Ship swap:** every ship has its own hangar number at a station. Board another ship at the hangar service and,
  leaving the shop, you are told where it stands ("Your active ship, the …, stands in Hangar 07 – the lift takes
  you there"); the lift offers that hangar, the old ship's hangar is no longer a way aboard (its stairs tell you
  where to go).
- **The hangar bench** stands by the glass and faces the ship – no longer in front of a shop's door.
- Talks and panels on the deck are drawn above the neon signs.
- Roadmap: **minigames** noted as a package of their own (54b – billiards at the dive's pool table first).

## alpha 0.7.49.12 – 2026-11-09

**Seats sized for the new figures.** Every piece of furniture you can sit on is rebuilt to the tall figures: the seat
at hip height, the backrest up to the shoulders – chairs (backrest on the side away from the table), bar stools (a
foot ring), benches, the sofa (cushions, arms), crates, sun loungers. Benches whose sitters turn their backs to you
(the far side of the long tables) now have their backrest in front of them – a rail at the small of the back, the
sitters' shoulders and heads above it – instead of none.

## alpha 0.7.49.11 – 2026-11-09

**New figures on foot (Luz's choice "C3").** The little chibis are gone: people are now tall and slim – about six
heads, 18 × 40 px, drawn finer than the deck (2 screen px per pixel), so they stand about as tall as before and fit
the doors and furniture. Black outlines and a **neon rim light** – cyan from the left, pink from the right, as if the
station's signs lit them. Broad shoulders, a narrower waist, arms with elbows and hands, a face with eyes, brows, nose
and mouth, boots with a shine; the jacket open over the shirt, the flight suit with its zip and a chest light, the
coat's tails, the armour's shoulder plates; every hair style, beard and headgear of the portrait. Front, back and
side, two walking steps (legs and arms swing), and a sitting pose with bent legs.

## alpha 0.7.49.10 – 2026-11-09

**Life down in the hangar bay** – roughly to scale, tiny next to the ship:
- **Loaders** – little yellow forklifts – drive between the crate stacks along the bay's walls and the ship, a crate
  on their forks on the way there, empty on the way back, a light blinking.
- **Repair drones** fly to spots on the hull, hover there and weld – sparks falling.
- A **fuel truck** stands at the stern, its hose to the ship, fuel pulsing along it.

## alpha 0.7.49.9 – 2026-11-09

**The hangar feels far below – and gets its own shops.**
- **No people down in the bay:** the mechanics and the person-sized crates, barrels and machines are gone; ships are
  giants, and the bay is far below the walkway. Its floor has small plates now, tiny crates and carts line its walls,
  little lights its edges, and a haze lies over it – thicker towards the far wall –, the ship in it too.
- **Hangar and shipyard on the walkway:** where the station has them, the **Hangar** service and the **Shipyard** are
  shops on the south side of the hangar walkway (door, neon sign, counter, keeper) – no longer up on the commercial
  level.

## alpha 0.7.49.8 – 2026-11-09

**The hangar, levels with a lift, and the waystations' own deck.**
- **The hangar:** getting out of the ship you now stand in the hangar – on a raised walkway along a glass front, and
  below it, in the closed bay, **your own ship** (nose to the bay doors' side, its shadow on the floor, landing marks,
  crates, a machine, mechanics, lamps). The walkway is as long as your ship needs. At the west end the **stairs**
  lead down to the ship – you start there, and E there takes you back aboard and to the station window. At the east
  end are the **lifts**.
- **Lifts with a choice:** E at a lift opens a little panel: *Hangar* or *Commercial level* (1 / 2, the level you are
  on is marked). You step in, the doors close, and you come out of the lift on the other level, the doors opening.
  The commercial level is the deck built so far (shops, corridor, bar); its lifts work the same.
- **Waystations** have a deck of their own: instead of the wide bar a round **glass dome** out front, completely
  rounded, and under it a **diner** – checkered floor, a long counter with the cook behind it and red stools, booths
  in the corners, the jukebox under the glass, a neon *Diner · open 24/7* over the door; in the corridor vending
  machines and lamps.

## alpha 0.7.49.7 – 2026-11-09

**Every station type its own deck, people who find their way, sitting properly, conversations after Luz's mockup.**
- **Station themes** – the bar, its floor, the window's corners and what stands about follow the station type:
  - *Trade hubs:* the lounge – round tables, a sofa, a rug, plants along the window.
  - *Military outposts:* a mess hall – long tables with benches, steel deck plates, banners and lockers, almost
    square window corners.
  - *Research stations:* a bright café – little tables for two, white tiles, holo pillars, specimen tanks.
  - *Industrial complexes and shipyards:* a canteen – long tables, grating or deck plates, pipes, vending machines,
    engine parts on display.
  - *Mining colonies and pirate havens:* a dive – a pool table, barrels for tables, crates to sit on, worn dark
    planks, ore carts, barrels, cages and rubbish in the corridor.
  - *Agri stations:* picnic tables among planters full of crops, flower beds.
  - *Ice refineries:* the lounge in icy tiles with ice sculptures and glowing heaters.
  - *Resorts:* a **beach bar** – sand, a pool in the middle, sun loungers under parasols, palms, little tables for
    two, a fountain and flower beds in the corridor.
- **Sitting properly:** chairs stand at the tables (the backrest away from the table); whoever sits – a guest or you
  – sits *on* the seat with the legs bent, no longer sinking into the floor in front of it. Benches at the long
  tables, crates in the dive and sun loungers can be sat on too.
- **Finding the way:** people walk along paths round walls and furniture (A* over the deck) instead of bumping into
  walls, and now and then go shopping – into the shops, up to the counter.
- **Conversations (Luz's mockup):** talking to someone at the bar opens a conversation screen – the one you talk to
  large in a frame on the left, what they say typed out in the box along the bottom, your answers in a box above it
  on the right (1–9 or click; E / Space shows the whole line). For now: **Info** (opens the questions, the record and
  signing on, as before) and **Goodbye**. The screen is meant for all conversations to come (Teil 8).

## alpha 0.7.49.6 – 2026-11-09

**On the deck: talk to the crew, sit down, the jukebox, lifts with doors.**
- **Talking to the crew:** E at someone with a "!" in the bar starts a conversation with just them – their portrait
  and how they greet you (a rookie is nervous, an elite knows their worth). Ask *What do you do on a ship?*, *How
  good are you?* (bonus, quality, what they learn from, their perk), *What would you cost?* (price and share of
  income) and *Show me your record* (the full crew card), then sign them on – into the station's crew quarters or
  straight onto your ship. Once hired, they pick up their bag and head for the lift. Esc ends the talk.
- **Sit down:** every free chair, bar stool, the sofa and the lobby bench – E to sit, E or a step to get up.
- **The jukebox** plays: three lounge tracks (Neon Rain, Dock Nine Blues, Low Orbit Lounge), E for the next one,
  after the last it falls silent. The music is made in the game, no files.
- **Lifts with doors:** you step out of the lift when you get off the ship; the doors slide open when you come near
  (green lamp) and shut behind you; E at the lift and you walk in, the doors close, and you are back on your ship.
- **Dock office:** the terminals stand along the back wall now, no longer in the doorway.

## alpha 0.7.49.5 – 2026-11-09

**The deck goes a little cyberpunk – neon by default, coloured by the station type.**
- **Neon shop signs:** the shop names are no longer labels but neon signs mounted on the wall over each door –
  glowing tube letters in the shop's colours on a dark plate with brackets, a pool of light below; now and then one
  stutters. Closed shops' signs are dark.
- **The BAR sign** is a tall neon sign: pink tube letters in a cyan neon frame, glowing, one letter flickering now
  and then.
- **Neon and light everywhere:** a neon strip runs along the foot of every wall and its light spills onto the floor
  (in the station type's accent colour); the corridor's guide line glows; lamp posts, the jukebox, the bar counter
  and the tables cast pools of light; the cold light of the planet falls in through the window front.
- **Holographic adverts** hover over the corridor wall between the shops – made-up brands of the cluster (Neuro+,
  Orbital Cola, Synth Noodles, Chrome & Soul …), see-through, with scan lines and the odd jolt.

## alpha 0.7.49.4 – 2026-11-09

**The deck feels closed in now.**
- **Space only through the glass:** everything above the window front's frame is black – the stars, the nebula, the
  star and the planet are seen only through the windows.
- **Even bigger windows:** the window front is seven rows tall, its rounded corners wider; the planet fills it.

## alpha 0.7.49.3 – 2026-11-09

**The deck, second round of Luz's notes.**
- **A real panorama:** the bar's window front is much taller (five rows instead of three) and its two upper corners
  are properly rounded – a curved glass gallery with the star and a bigger planet outside.
- **The lifts sit inside the station:** the lift lobby lies deep in the structure, no longer against open space.
- **The station goes on:** round the deck, to every side and below, the station's structure continues (hull plates,
  seams, vents, small lights) – only above the bar's window front is there space. Walls are one tile thick; the solid
  mass behind them is part of that structure.

## alpha 0.7.49.2 – 2026-11-09

**Package 49 reworked: the deck in a slanted, cosy view, laid out after Luz's sketch.**
- **Slanted view:** walls show their front face, furniture stands up (tables, chairs, sofas, counters, plants, the
  jukebox …) and people walk behind and in front of it, sorted by depth. People are new small figures (big head,
  four directions, walking steps) built from the same look as the portraits – your own pilot looks like the pilot
  you created.
- **The new layout:** you step out of the **lift lobby** on the left (two lift doors, News Archive and Bulletin Board,
  a bench) – the lift takes you back to your ship. It opens onto the **corridor**; below it are the **shops** (Dock
  Office with the ship-service terminals, Market, Outfitter, Shipyard, Bond Office, Image Studio, Refinery,
  Manufacturing … whatever the station offers), each with its door, sign, shelves, counter and keeper. Above the
  corridor, behind a railing, lies **the big bar**: wooden floor, round tables with guests, a sofa, a rug, a jukebox,
  the bar counter with a tall neon "BAR" sign, the bartender and stools.
- **The window front:** the whole north wall of the bar is glass – outside is the system you are in: its nebula, its
  star and the planet the station circles.
- **Crew in the bar:** the people on offer stand in the bar with a "!" over their head – walk up to them and press E
  to talk about hiring them.
- Each station type keeps its own colours (floors, walls, accent lights).

## alpha 0.7.49.1 – 2026-11-09

**Teil 7, package 49: on foot – the ground view and walkable station decks.**
- **Walk the deck:** a new button in the station window gets the pilot out of the ship onto the station's deck – the
  space view keeps running below. Everything still works through the station window as before.
- **The deck:** an **airlock** where your own ship lies docked beyond the window (nose to the hatch, docking tube),
  a **promenade** with kiosks (News Archive, Bulletin Board), planters, benches, pillars and holo adverts, and the
  **shops and the bar as rooms** on both sides, each behind a door with a lit sign in its corporation's colours: Market
  (crates, counter), Outfitter (weapon racks), Shipyard (a ship in the dock window), Bond Office, Image Studio
  (mirror), Refinery/Manufacturing (machines), the Senate, the Curia and the Research Exchange where the station has
  them, and **the Bar** (wooden floor, bar counter with bottles, stools, tables, guests). The ship services (fuel,
  repair, drones, munitions, hangar) are terminals in the **Dock Office**. Only what the station offers gets a door;
  a raided station's shops show "closed".
- **People:** a bartender, shopkeepers, guests at the bar and passers-by strolling the promenade (random looks).
- **Every station type looks its own:** bright and clean on a research station, grey and stern with red lights on a
  military outpost, rust and crates on industry and mining, wood and green on agri stations, icy blue on ice
  refineries, ivory and gold with a fountain at resorts, neon and scrap in pirate havens.
- **Controls:** W A S D (or arrows) to walk, Shift to run, **E** at a door, a terminal or the airlock; the pilot has a
  green ring. A door opens its service window over the deck; closing it is back on the deck; the airlock leads back
  to the ship and the station window. New key group "On foot" (keys may do one thing on foot and another in space).
- Codex: On foot. Smoke tests for the deck (doors reachable, walls, a shop, back to the ship).

## alpha 0.6.75.4 – 2026-11-09

**Fixes from the code review of Teil 6** (`reviews/teil6_review.md`) – all twelve findings.
- **W1 – save size:** the save held every asteroid of every system ever generated (the warmup makes all inhabited ones):
  3.6 MB after 17 minutes, rewritten after every jump. Now only what differs from the generated layout is saved
  (mined or broken rock, colossi dug into, anomalies scanned, salvaged wrecks); untouched systems are left out –
  about 70 KB after loading a new game.
- **W2 – fixed wrecks:** a battlefield hulk or derelict whose loot did not fit into the hold vanished with the rest –
  the Relic of Earth too. Now it stays (salvage again after making room), and things wanted by a contract or a
  blessing come aboard first.
- **M1:** a radiation zone is laid only over fields that stay put (moon fields move with their moon).
- **M2:** a coronal mass ejection no longer sets off the old minefields.
- **M3:** a misjump no longer repairs a battered hull up to 25 %.
- **M4:** planets and moons keep clear of wreck sites, hazards and anomalies when their orbits are rolled.
- **Small:** misjump state cleared on a new game and on loading; the thrust message reads "Not while warping or
  docking."; a fortress garrison has no cowards, and one that fled far away no longer holds the fortress; when the
  polls close only that contract's ballot crates are taken, not other couriers' sealed cargo; the unused price table
  (`Market.sync`) is gone; the arrival animation's timer belongs to the view.

## alpha 0.6.75.3 – 2026-11-09

**Fix: crash when a target died ("Left operand of 'is' is a previously freed instance").** Reported by Luz: attacking
pirates in the Far Reaches with the Citadel and its nine drones, the game crashed as the last pirate went down.
- A lock could still point at a ship destroyed in the same frame (it is cleared on the next tick); drones and modules
  asked for it in between and checked "is it a ship?" on the freed object. `locked_node` now returns nothing then.
- Every place that receives an attacker or shooter (damage, EMP, a ship destroyed or attacked, a fortress garrison
  lost) now treats one that is already gone as "nobody" instead of touching it.
- **Drone shots are quieter and thinned out** (at most one drone shot sound every 0.18 s, −9 dB) – nine drones
  firing pulse lasers sounded like a weapon played a million times.

## alpha 0.6.75.2 – 2026-11-09

**Thrust burst.** Every ship can kick its drives for a moment – **Shift** (rebindable; Shift can be bound now).
- **2.5 s** of **×1.8 top speed** and three times the acceleration; from a standstill the ship shoots straight ahead.
  Costs **a fifth of the capacitor**, then **15 s** to recharge; not in warp, not docked. Works on top of an afterburner.
- A long **yellow-orange flame** behind every drive (about as long as the ship), a flash behind the stern on ignition,
  a short camera shake and a roaring ignition sound (`boost`, placeholder); the flame cools off after the burst.
- HUD: next to the speed – "▶▶ THRUST" while it burns, a recharge bar, "thrust ready [Shift]".
- **NPCs use it rarely:** pirates and patrols now and then when fleeing from an attacker close behind or closing on a
  far target (a 6 % chance every 2 s, 35 s cooldown) – the pilot can still catch up or get away.

## alpha 0.6.75.1 – 2026-11-09

**Interim part 6½, package 75: speed.**
- The **Plasma Drive** had less thrust than an Ion Drive of the same size (1,400 kN at size 5 against 1,843) – now
  2,500 kN at size 5, about 35 % above the Ion Drive (still more power-hungry and less agile).
- **New speed curve:** speed follows the square root of thrust per mass (was linear), set to 300 km/s at 0.2883 kN
  per tonne. Double the thrust is about 41 % faster instead of twice as fast. The standard fits now average about
  **300 km/s** (S 271, M 331, L 297, was S ~250, M ~250, L ~180); with the best engine S ~560, M ~430, L ~325 –
  big ships stay slower at their best, but they all meet in the middle. Small ships with oversized engines no longer
  reach 1,000–1,600 km/s.
- `Balancing_Kernmodule.md`: all core modules by size and quality, how the values scale, the speed formula.

## alpha 0.6.40.10 – 2026-11-09

**Package 40e: codex, debug, tests, balance and performance** – package 40 (the new cluster) is done.
- **Codex:** "The Cluster" and "Security and territory" tell of the new cluster (about 240 systems; the core shared by
  the Assembly and the Covenant, the Directorate's enclave, the Rim, the Far Reaches, the Veil); new entry **The Rim
  and the Far Reaches** (unlocked on entering the Rim).
- **Debug menu – "The new cluster (package 40)":** to the Rim, the Far Reaches, the Veil's edge, a pirate fortress
  (outside its guns), an old battlefield, a pre-Severance derelict, a radiation zone, an ion storm, an old minefield
  (the next one each click); the next jump misjumps; break / rebuild the fortress here; hazard wards (A); Pre-Severance Tech.
- **Balance:** the Far Reaches get one extra asteroid field, not two; Veil rifts hold exotic matter less often
  (40 % instead of 60 %) and give 3–6 Veil readings instead of 4–8; no waystations in the Far Reaches or in fortress
  systems.
- **Performance** (uncapped, 1600 × 900): zoomed out in a Rim system 65 → 157 fps, in the core 111 → 257 fps – the
  radar gathers the objects in its range four times a second instead of walking every asteroid each frame, and rocks
  smaller than about two pixels are no longer drawn; radiation zones 122 → 202 fps and ion storms draw a haze texture
  instead of dozens of big circles; old minefields 208 → 373 fps – old mines look for ships five times a second and
  redraw only on screen. Loading a new game: 13.2 s (as before).

## alpha 0.6.40.9 – 2026-11-09

**Hazard wards from specialised blueprints.**
- Two new optional modules (size 1), **never sold – only built** at a station's fabricators:
  - **Radiation Insulation** – keeps part of a radiation zone's dose off (shield drain and hull burn), recipe of
    tungsten, armour plating and electronics.
  - **Shielded Hull Lining** – a conductive lining against ion storms: fewer lightning strikes, shorter knock-outs,
    less damage, and the radar is jammed less often; recipe of copper, magnet coils and circuits.
  - The effect depends on the **quality**: F 50 %, E 58 %, D 66 %, C 74 %, B 82 %, A 90 % (the best one fitted counts).
- **Two new tiles in the Industry branch of the skill tree** (after Station Manufacturing) hold the specialised
  blueprints: *Radiation Insulation* (10 modules built, 120 s spent in radiation zones) and *Shielded Hull Lining*
  (10 modules built, 5 ion-storm lightning strikes taken). New achievement metrics for both.

## alpha 0.6.40.8 – 2026-11-09

**Package 40d: the dangers of the Rim.** A new game is needed.
- **Radiation zones** – always round neutron stars and black holes, now and then elsewhere (a quarter of the Rim,
  more in the Far Reaches), often over an asteroid field: inside, shields drain and then the hull burns; the rock
  under a zone is purer and richer. A yellow-green haze with a striped ring; a big warning banner.
- **Ion storms** – blue clouds with lightning that drift slowly through a system: radar jammed, lightning strikes
  knock out shields and systems for a moment and scorch the hull.
- **Old minefields** – round old battlefields or across the way to a gate: 18–30 rusted mines of a forgotten war,
  armed against anyone (pirates and patrols too); point defence shoots them down. A red dashed ring.
- **Pirate fortresses** – six in the Rim, held by the Hollow Crown and the Severed: a hollowed-out rock behind seven
  armoured bastions, heavy guns with a long reach, a garrison of 6–8 ships. Destroy the whole garrison and the
  fortress is **broken**: its guns fall silent and its **bounty (150,000 cr)** is paid as a bond; half an hour later
  it is rebuilt. Fortress systems count as inhabited (German names) and have patched pirate gates.
- Hazards are warp targets (you arrive at their edge), named in the system info of the galaxy map; fortresses are
  marked with a red square. Codex: Radiation zones, Ion storms, Old minefields, Pirate fortresses. Smoke tests.

## alpha 0.6.40.7 – 2026-11-09

**Territories by the lore.** A new game is needed.
- **The Assembly and the Covenant share the core** between them and grow without limit; where they meet, a few
  border systems are **contested** – the only contested systems in the cluster.
  The two stay about the same size (the bigger one cedes border systems to the smaller).
- **The Meridian Directorate is a small enclave:** its capital (one with at most three routes) and the systems round
  it – **at most 4 systems**. No contested border touches it.
- **The pirate factions hold at most 3 systems each.**

## alpha 0.6.40.6 – 2026-11-09

**No more route classes; the Veil as clouds.** A new game is needed.
- **Every hyperspace route is open to every ship with a jump drive** – the route classes (and the drive class they
  asked for) are gone; the systems' own conditions, entry permits and the dangers of the Far Reaches are the
  barriers now. Every jump costs the same fuel.
- The jump drives are **grades Mk I–III** now (the old Cl.1–3 drives): a better drive **jumps faster** (×1 / ×0.85 /
  ×0.7) and holds an old gate's failing field together (**misjumps** ×1 / ×0.6 / ×0.3).
- Galaxy map: all routes in one colour, the route list without classes; gate tooltips without a route class.
- **The Veil on the galaxy map** is a slowly wavering band of **black clouds with violet accents** – violet light in
  their folds and along their ragged inner edge (a shader, `veil_clouds.gdshader`).

## alpha 0.6.40.5 – 2026-11-09

**Package 40c: the content of the Rim.** A new game is needed.
- **Rich deposits:** every Rim system has one more asteroid field (the Far Reaches two), its rock holds 1.5× as much
  ore (Far Reaches 1.8×) and is purer (45 % high grade instead of 20 %), every metallic and stony colossus has a deep
  deposit, and every system a giant to harvest.
- **Old battlefields** (~40 % of the Rim, a few in the core): 6–12 hulks of warships of two old enemies, burnt grey,
  rusted, holed and often broken in two, in a field of scrap. Salvaged: salvage, alloys, weapon parts, sometimes an old
  module and **Pre-Severance Tech**. They stay until salvaged – for good.
- **Pre-Severance derelicts** (more often further out): the colony and generation ships that brought people to the
  Cluster – a long spine, a broken habitat ring, faded paint – with fragments round them. Salvaged: Pre-Severance
  Tech, research data, scrap, and now and then a **Relic of Earth**.
- New good **Pre-Severance Tech** (1,600 cr) – only from the wrecks; research and high-tech worlds buy it.
- **The edge of the Veil:** the two outermost systems of every constellation of the Far Reaches (40 in all), violet on
  the galaxy map. A violet curtain of light in their sky, ghost ships flickering up on the sensors, echoes and voices
  in the log – and **Veil rifts**, jagged tears in space visible from afar: analysing one gives much more data (Veil
  readings for the Research Exchange) and often exotic matter.
- Galaxy map: the Veil glows violet round the cluster, "THE VEIL" in the overview; the system info lists rich
  deposits, battlefields, derelicts and the edge of the Veil.
- Codex: Old battlefields, Pre-Severance derelicts, The edge of the Veil, Veil rifts. Smoke tests for all of it.

## alpha 0.6.40.4 – 2026-11-09

**Galaxy map overview.** Zoomed right out (below ×1.8), the map becomes an overview: system names, security and
station marks are hidden (only your current, the selected and the hovered system keep their names), the territories
are always shown and each faction's name stands over its land (pirate holdings smaller, labels never overlap), and
"THE RIM" and "THE FAR REACHES" are written along their rings.

## alpha 0.6.40.3 – 2026-11-09

**Package 40a extended: the Far Reaches.** A new game is needed.
- Beyond the Rim lies a second ring of **20 constellations** of 5–7 systems each – about **120 more systems**, the
  cluster now has ~240. Nobody lives there: no settlements, no stations, no research posts at the strange stars, the
  lowest security in the cluster (0.0–0.15), old gates everywhere.
- The Far Reaches are reached **only through the Rim** (one or two routes per constellation), their constellations
  joined among themselves by single routes with more gaps than in the Rim – regions you have to go round.
- Territory reads "Unclaimed – the Far Reaches". The galaxy map is larger (5300 × 3600) and zooms further.

## alpha 0.6.40.2 – 2026-11-09

**Package 40b: the gates.**
- Gates now show **whose system it is**, in six drawings: the **Assembly's** white-and-blue ring with four pylons,
  the **Covenant's** crimson and gold with eight spires, the **Directorate's** silver octagon with green emitters, the
  plain yellow-striped gates of the **independents** – and in the empty Rim the **old gates**: rusted, plates missing,
  broken down to the bare frame in places, their field flickering. The **pirates** patch theirs with scrap plates and
  red lights.
- A jump through an **old or patched gate takes longer** (×1.6) and, very rarely (3 %, pirate gates 1.5 %), its field
  breaks down mid-jump: the ship is **flung out somewhere in the target system** (far out or near a field) and takes
  damage (15 % of the hull, armour first – never fatal). The log says what happened and why.
- **Two new animations:** coming out of a gate – the gate flares, the ship shoots out of it and slows to its place
  with a flash and a glittering trail, like dropping out of warp; and the **misjump** – violet lightning, a torn ring,
  the ship thrown out tumbling with sparks and smoke. NPCs make the gate flare too.
- Codex: "Hyperspace gates" tells of the styles, the old gates and misjumps. Smoke tests for the styles and the misjump.

## alpha 0.6.40.1 – 2026-11-09

**Package 40a: the new cluster.** A new game is needed (older saves are moved to the new cluster).
- About **120 systems**: a **core** of ~60 held by the Assembly, the Covenant, the Directorate and – at its edges – the
  pirates, much as before; round it **the Rim**, a ring of **11 constellations** of 4–7 systems each, close together
  and joined among themselves, to their neighbours by a single route (now and then none – regions form) and to the core
  by one or two. The Rim belongs to no one: wild, unwatched, low security.
- **Capitals are ringed by their own systems** – every neighbour of a capital belongs to its power.
- **Free settlements** in most constellations: a small outpost (mining, trade, research or ice), an independent
  system (yellow). The manufacturers' independent homes (Erzhalde, Perlmutt, Schwarzwacht) lie in constellations right
  on the core.
- **Names:** inhabited systems (stations, havens, settlements) German names – 40 new ones; empty systems catalogue
  numbers or the names of their explorers ("KVX-114", "Brandts Wacht", "Ruiz' Hoffnung").
- **Galaxy map: zoom and pan** – it opens zoomed in round the current system; the wheel zooms towards the pointer,
  dragging moves the map. Empty systems show no economy or prosperity; the Rim is "Unclaimed – the Rim".
- The empty systems of the Rim are made when first needed (not behind the loading screen).

## alpha 0.6.43.4 – 2026-11-09

**Package 43c: tourist traffic – Tourismus done.**
- **Cruise liners** of Maison Aurelle (Pearl, Opal and now and then an Empress as a "Grand Liner") come through the
  gates, fly to a sight of the system, drift past it for a while and then berth at the resort; in a well-off system
  with a famous sight but no resort they sail on through a gate afterwards.
- **Sightseeing shuttles** leave the resort for a sight (the rings, a beautiful world, a wondrous star, a landmark),
  linger and fly home.
- Their numbers follow the resorts and the prosperity of the system (Universe.system_profile: cruise, tour_shuttles).
- Debug: cruise liner + sightseers now. Codex "Resorts and sights" mentions them.

## alpha 0.6.43.3 – 2026-11-09

**Package 43b: tourist flights and round trips.**
- **Tourist flights** among the passenger contracts: holidaymakers bound for a resort, more of them in richer
  systems, more often in business and luxury class; they pay 30 % more. Each group delivered raises the resort
  system's prosperity a little.
- **Round trips** (from Average prosperity up): sightseers board here, you take them to a sight in another system
  (up to three jumps) – a beautiful world, the rings of a giant, a wondrous star, a landmark – stay close, out of warp,
  for 45 seconds while they look, and bring them back to where they boarded. The deadline covers the whole trip; the
  more famous the sight, the better the pay. The sight's system gains a little prosperity.
- The board marks them "TOURISTS" and "ROUND TRIP"; the contract shows how long they have looked.
- Codex "Tourists and round trips"; debug: round trips – sight seen.

## alpha 0.6.43.2 – 2026-11-09

- Resorts redrawn: the big ones (tier 3) are **habitat rings** – a wide ring with a landscape under a glass roof:
  meadows, forests, lakes and towns, walled on both edges, half of it in night with the towns' windows lit and lights
  twinkling over them; spokes to the hub, docks at the rim. The smaller ones are **biospheres** – a great glass dome
  over the same landscape, half in night, with a service ring and docks. Names: "… – Habitat Ring" / "… – Biosphere".
  (The ring resort, observatory and pleasure dome looks are gone.)

## alpha 0.6.43.1 – 2026-11-09

**Package 43a: resorts and sights.** A new game is needed.
- New station type **Resort** (ivory and gold) in three looks: a **ring resort** of hotel decks with a garden dome and
  glass observation pods at a ringed giant, an **observatory resort** with a great telescope, a glazed gallery and a
  viewing bubble at a wondrous star (red supergiant, neutron star, black hole, blue giant), and a **pleasure dome** –
  an octagonal casino under glass, neon on every edge and a great wheel – at a beautiful world.
- Resorts stand where a holiday is worth it: earthlike, ocean and jungle worlds, ringed giants, wondrous stars, safe
  and wealthy systems – about ten in a cluster; Landfall, Heimkehr and Perlmutt always have one.
- Tourism trade: resorts sell souvenirs, holo films and art and want luxuries, fine food, wine, perfume and gold; a
  resort gives its system a strong tourism economy.
- The sights of a system (beautiful worlds, the rings of the giants, wondrous stars, landmarks such as The Vote, the
  Pilgrim Gate and the Meridian Sphere) – for the round trips of package 43b.
- The station column of the concourse shows the system's economy and what this market makes and wants (it still
  showed the old station-type lists).
- Codex "Resorts and sights"; debug: to a resort.

## alpha 0.6.42.5 – 2026-11-09

**Package 42d: tuning – Wirtschaft 2.0 done.**
- Trade balance checked across two clusters: no market ever buys back above its price; the best routes earn about
  10,000–14,000 credits per 100 m³ load over one jump (artworks, fuel rods, medical isotopes, magnet coils – limited by
  the stock), a hold of ore about 5,000, contracts 5,000–20,000.
- Waystations keep to their own goods (water, food, fuel) and the basic needs instead of taking on the system's whole
  economy.
- Prosperity rises a little faster with trade: a level is about 100,000 credits of wanted goods (was 120,000).
- Galaxy map: how far a system's prosperity has moved from its usual level ("+8 from its usual 52").
- Codex entry "Munitions Depot".
- Fixed: a few texts had a line break written into the code instead of an escape (no visible change).

## alpha 0.6.42.4 – 2026-11-09

**Package 42c: prosperity changes and shapes the systems.**
- Prosperity moves: selling a system what it wants and buying what it makes raise it, so do finished contracts and
  pirates shot down there; a raid that knocks out a station costs 10 points. Left alone it drifts back to its base
  (most of the way in about two hours). The news report when a system rises or falls a level.
- Rich systems are busier (more shuttles and haulers) and get an extra patrol; poor ones draw more pirates.
- Contracts: rich systems offer one more and pay up to 15 % more, impoverished ones one fewer and up to 15 % less.
- Outfitters: high-tech, wealthy and rich systems carry one quality step better than the station's tier allows;
  military systems carry A quality and every size of weapon and armour up to the tier; impoverished systems lose A.
- Convoys carry what the source market makes, bound for a market that wants it; richer systems send more of them.
- The loading screen prepares every system's layout and markets (the galaxy map and the convoys need them) – no hitch
  later.
- Debug: prosperity drift 1 h. Codex "Economies and prosperity" updated.

## alpha 0.6.42.3 – 2026-11-09

- Market: the goods are grouped in **sixteen categories** – ores, ices, gases, metals, minerals, nuclear materials,
  fuels & coolants, components, food, chemicals, industrial goods, consumer goods, high-tech & medical, science,
  military goods, luxury goods – with a heading per group and a filter for each (the economy filters stay below).
- Raw materials are wanted by their own users now, not all by "industry and high-tech": tungsten and titanium by the
  military, helium-3 and cryo coolant by research, ammonia and carbon dioxide by agriculture, xenon by the military …
- Weapon parts are made by industry and used by the military.
- New service **Munitions Depot** (Obsidian Ordnance): ammunition for every weapon that has to be restocked – the
  mines of the mine launchers so far; mines are no longer sold on the market. What a depot stocks and charges follows
  the economy: military systems carry every kind and sell it cheapest, industrial ones the common kinds, high-tech
  ones the jammer mines; pirate havens sell everything, dearly. Munitions go back for half their price.
- `Warenliste.md`: all tradeable goods with category, producing and consuming economy.

## alpha 0.6.42.2 – 2026-11-09

**Package 42b: markets with real stocks.** A new game is needed.
- 56 new goods of the nine economies – grain, coffee and fine wine; drill bits, gemstones and industrial diamonds;
  machinery, robots and prefab habitats; steel, refined fuel and glass; plastics, explosives and fertiliser; computers,
  nanites, implants and AI cores; star charts and prototypes; ammunition and body armour; souvenirs, jewellery,
  perfume and artworks. Some are trade goods only. The older goods have their place in the economies too.
- Every good has a role at each station: **made here** (green – its station, or the system's main or secondary
  economy; ores only where the system's fields hold them, gases only where a giant gives them), **wanted here**
  (gold – its station, the economies that need it, luxuries in wealthy and rich systems, basic needs everywhere) or
  neutral.
- **Real stocks:** buying takes from the stock and raises the price, selling fills it and lowers the price (whole
  sales are priced along the way). Over game time the stocks drift back: made goods are made again, wanted goods
  used up, neutral goods carried off. Richer systems keep bigger stocks and pay a little more. Traded stocks are saved.
- Market screen: the economy and prosperity of the system, what is made and wanted here, a stock column, filters for
  local trade, the hold, raw materials, components, luxury goods, all and each of the nine economies. The galaxy map
  lists what each station's market sells and buys.
- Codex entry "Markets and stocks"; debug: markets +1 h, +20 luxury goods.

## alpha 0.6.42.1 – 2026-11-09

**Package 42a: Wirtschaft 2.0 – the economic model.** A new game is needed.
- Every system has a **main economy** and, if strong enough, a **secondary** one: Agriculture, Mining, Industry,
  Refining, Chemistry, High-Tech, Research, Military or Tourism. They come from the system's factors – its stations
  above all (they are fixed and shape the economy), then its planets, moons, asteroid fields and belts. Ocean and
  jungle worlds feed, metal worlds and fields are mined, gas giants power industry, red and toxic giants supply the
  chemists, earthlike worlds draw tourists and high-tech firms. The hand-made systems lean towards their own.
- **Prosperity** in five levels (Impoverished, Poor, Average, Wealthy, Rich): it starts from a system's people,
  stations and security, is saved with the game and will change in play (package 42c).
- New planet type **Metal World**: a dense iron world laced with copper and silver ore veins that glint in the sun –
  the strongest mining factor. In the collection too.
- Galaxy map: the economy filter now highlights the nine economies (main or secondary); a coloured mark above each
  system shows its main economy, five pips its prosperity; the system info names the economy, its strongest reasons
  and the prosperity. The header shows the economy of the current system.
- Codex entry "Economies and prosperity"; debug section "Economy (package 42)": the factors in the log, prosperity
  ±20, to a metal world, to a system of each economy.

## alpha 0.6.41.6 – 2026-11-09

**Performance on the system map.** Fully zoomed out: 8–12 ms per frame (spikes to 28 ms) → about 4 ms (spikes to 8 ms).
- Dashed rings (no-fire zones, harvest bands) are one draw call each instead of one per dash (90 per station), and
  are left out where they would be a speck.
- NPC ships smaller than a pixel on screen are hidden and not redrawn (the map marks them); effects and stations that
  would be a few pixels are not redrawn either.
- The belt dashes on the map are only rebuilt when the zoom changes.

## alpha 0.6.41.5 – 2026-11-09

**Performance.** The game logic runs on one CPU core (GDScript), so a busy system could drop to 20–50 FPS while the
PC looked idle. Measured in the start system: 19 ms per frame (spikes to 38 ms) → 2.5 ms (spikes to 5 ms).
- Effects (warp glitter trails, explosions, beams, smoke) are only redrawn while on screen; a glitter trail has about
  half the sparks.
- Stations, structures, gates and NPC ships are only redrawn while on screen.
- What is under the mouse is looked up when the mouse moves, otherwise ten times a second (it walked all ~1,700
  objects every frame); hidden rocks are skipped at once.
- NPC ships check their power plan four times a second instead of every frame.

## alpha 0.6.41.4 – 2026-11-08

- Inventory: the gas tanks and shielded racks get their own bars under the cargo hold (used / room); gas in the
  ordinary racks is shown with the room it takes there (twice its volume); radioactive goods outside shielded racks
  get a warning line. Gases are marked "(gas)", radioactive goods ☢.
- The ship info (HUD and the Info tab) shows the gas tanks and shielded racks next to the cargo.

## alpha 0.6.41.3 – 2026-11-08

- Fixed: the ship menu's Modules tab crashed with a gas collector or deep core drill fitted (the tool kinds had no name).

## alpha 0.6.41.2 – 2026-11-08

- Fixed: switching on the gas collector (the Kujira's scoop above all) crashed the game – it has no target.
- No more funnel: ships with a drone hatch open it and the gas streams in through it; ships without one take the gas
  in on their underside (the stream vanishes under the hull). The gas comes in from ahead, where the ship is flying.
- Kujira: the funnel at the bow is gone – a slightly raised bridge with cockpit glass sits on the nose now, and a
  drone hatch on the spine between the last tank and the bridge (two drones, crew posts).

## alpha 0.6.41.1 – 2026-11-08

**Package 41: the mining expansion.** A new game is needed.
- 12 new ores with their refined materials: copper, tungsten, gold, uraninite, spodumene (lithium), graphite, quartz,
  monazite (thorium), nitrogen ice, dry ice – and osmium and palladium, found only as deep deposits in colossi.
- Purity: every asteroid is low, medium or high grade (the prospector reads it); purer rock gives more ore.
- **Gas harvesting:** every giant has a harvest band (dashed rings on the map). Fly through it with a gas collector on
  and keep moving – the scoop swings out and draws a stream of gas in. Deeper means more gas; below the inner ring heat
  and pressure wear armour and hull past the shields. Storms double both. Gas giants give hydrogen and helium (rarely
  helium-3), ice giants nitrogen and neon (xenon), red giants hydrogen and sulfur dioxide (phosphine), toxic giants
  chlorine and ammonia (fluorine).
- New modules: Gas Collector (1–4), Deep Core Drill (2–4, colossi only), Gas Tanks, Shielded Cargo Rack.
- Gases take twice the room in ordinary racks; gas tanks hold them at their own volume.
- **Radioactive goods** (uraninite, monazite, enriched uranium, thorium, fuel rods, tritium, medical isotopes) outside
  shielded racks raise a red RADIATION banner with an alarm. Shielded racks hold far less per size.
- **Components** at any station with fabricators: circuit boards, battery cells, armour plating, carbon fiber, ion
  propellant, magnet coils, fusion cells, fuel rods, tritium, medical isotopes, precision optics, cryo systems.
- **KHI Kujira** (L gas freighter): big round tanks, 1,600 m³ of gas, a built-in scoop, heat resistant hull.
- Codex entries, debug section "Mining expansion (package 41)", smoke tests.

## alpha 0.6.39.11 – 2026-11-08

- Yards: the docking bays of the Atelier Aurelle and the Hadrian Foundry are flush with the hull now (arms and
  docking blocks as wide as the bays); the berths' girders no longer jump a pixel half-way (Kanayama Works).

## alpha 0.6.39.10 – 2026-11-08

**Package 39d: the manufacturers' systems.** A new game is needed.
- Earthworks: **Altwerft** in the Assembly's space – the Earthworks Second Yard (12696 HE), the standard yard design.
- New class of systems: **independent** (yellow on the galaxy map), no power holds them:
  - **Erzhalde** – Kanayama Works: a yellow building site with scaffolding, tower cranes and a smoking refinery block.
  - **Perlmutt** – Atelier Aurelle: slender and rounded, ivory and gold, a glass dome with a biosphere at its heart.
  - **Schwarzwacht** – Hadrian Foundry: black and angular with red lights; weapon platforms are being built round it,
    drones at work.
- Every maker's yard sells all of its ships, and the berths hold them under construction (scaffolding, sparks, drones).
- Codex entry on independent systems; debug: jump to each maker's system.

## alpha 0.6.39.9 – 2026-11-08

- Axiom Yards reworked: the spine ends at its sensor hub instead of running off the left edge; in the berths lie the
  manufacturer's own ships – two Thresholds and two Parallaxes – under scaffolding, a section still open.
- Work drones hop round the unfinished jump gates, welding.

## alpha 0.6.39.8 – 2026-11-08

- Durchbruch: big haulers carry Dyson plates along the shell near the Meridian Sphere (out loaded, back empty).
- The solar mirrors over Curie are curved reflectors now, turned to the planet as you see it in the sky – their
  facets gather the light into a beam that lands on the surface.
- Curie has a research station: the Curie Terraforming Institute. A new game is needed.

## alpha 0.6.39.7 – 2026-11-08

- Fix: the debug menu crashed the game ("Invalid access … 'desert'") – Vesper, Heimkehr's desert moon, is a moon of a
  planet type, and a few places looked moons up among the moon types only (debug menu, moon fields, debug jump to a
  moon). The smoke test now opens every debug tab in all three capitals.

## alpha 0.6.39.6 – 2026-11-08

**Package 39c: Durchbruch, the capital of the Directorate.** A new game is needed.
- A blue-white A star – and round it a **Dyson sphere under construction**: frame rings of the shell, closed with
  silver collector plates where they are built, bare scaffolding (welders at work) where not. Its hub, the **Meridian
  Sphere**, is the only station in the Cluster built round a star.
- Physicists: Noether, **Curie** (half terraformed – green with seas on one side, desert on the other, three solar
  mirrors beaming light onto the new land), Planck with Meitner and Bohr, Kepler.
- **Axiom Yards** at Meitner: sleek berths, ships testing their cloaks, and six **small jump gates** being built round
  the yard (now and then one is test-fired). The Threshold is sold only there.
- **Research Exchange** (Meridian Sphere): research data from analysed anomalies and exotic matter for credits and
  standing; exotic matter for sale to Allied pilots.
- Contracts: measurement probes, exotic matter for the Sphere, test flights from the Axiom Yards; codex entries; debug.

## alpha 0.6.39.5 – 2026-11-08

- Pilgrim Gate: rays from the tips of its spires gather in a burning focus ahead of the gate; from there the mighty
  beam runs home right across the system map.
- Cathedral of Return in crimson and gold instead of pale stone.
- New planet type **Red Gas Giant** (Compline is one) – it now turns up elsewhere too and has its tile in the
  collection. A new game is needed.
- Work drones hop over the Lux Aeterna from one welding spot to the next.

## alpha 0.6.39.4 – 2026-11-08

**Package 39b: Heimkehr, the capital of the Covenant.** A new game is needed.
- Heimkehr under a red supergiant: the lava world Lauds, the red gas giant Compline (no rings) with the desert moon
  Vesper (pilgrim cities) and Nones, the ice world Matins.
- The Cathedral of Return over Vesper – pale stone, stained glass, a rose window ringed in gold, spires; modern docking
  arms and solar sails beneath the old forms.
- The Pilgrim Gate: a ceremonial ring of ivory and gold that points home; its light never goes out and pilgrims pass
  through it in an endless line.
- The Forge of Return at Lauds: furnace towers, a farm of red focus crystals, a warship in its berth – the only yard
  that sells the Cathedral. Beside it the Lux Aeterna: the Covenant's capital ship, crimson and gold, a great focus
  crystal at the bow, huge weapon towers, a habitat ring at her heart.
- The Curia (Cathedral of Return): the Hierarch's edicts (each with a blessing and a burden), tithes (standing, a
  petition for the next edict), indulgences (wipe your record with the Covenant), relics of Earth (found in anomalies –
  standing and a blessing: cheaper prices at Covenant stations).
- Contracts: pilgrim convoys and crystal transports to Heimkehr, relic recoveries; codex entries; debug functions.

## alpha 0.6.39.3 – 2026-11-08

- The background stars twinkle much less – a gentle, slow shimmer instead of blinking.

## alpha 0.6.39.2 – 2026-11-08

- Agora's city lights have structure: bright metropolises, a glittering band along the coasts and highways between
  them – the open land and the sea stay dark.
- Much busier drone traffic between The Vote and its relay stations (two lanes each way).
- The Res Publica redesigned after Luz's reference: a long bow split by the trench of her spinal railgun, broad
  shoulders, swept wings at the stern with the engine core between them, drone hatches all over the hull (drones
  launch and land), a wing still under scaffolding; her stern lies against the yard's gantries.

## alpha 0.6.39.1 – 2026-11-08

**Package 39a: Landfall, the capital of the Assembly** – the first hand-made special system. A new game is needed.
- The Assembly's capital is now Landfall: G star, Pnyx, Agora (brightest city lights), Ekklesia and the deep-blue ice
  giant Boulé with Ostrakon and Kleros.
- Capitals are closed: an entry permit from Friendly standing on (taken only at Arch-enemy) opens the gates.
- The Vote: trade hub with four relay stations, drone traffic and a blue beam that sends ballot drones to the gates.
- The Senate: bills every 30–60 min with an upside and a price for an hour; votes, party donations, bribes.
- Concord Yards with the Res Publica in her berth; the Concordia is sold only there.
- Ballot couriers and drone field trials; codex entries Landfall and The Senate; debug functions.

## alpha 0.6.38.2 – 2026-11-08

- Collection: moon types are a category of their own (Moon types), apart from the planet types.
- Collection tiles grow with the screen – picture, text and tile size scale up on large screens, and the tiles
  stretch so each row fills the width.

## alpha 0.6.38.1 – 2026-11-08

**Package 38: new planet types.** A new game is needed.
- New: ice giants, dwarf planets out in the Kuiper belt, ocean worlds and jungle worlds. Now and then a waystation
  orbits a dwarf planet.
- Every planet type reworked, twice as fine: seas and coasts, a cloud layer of its own, polar caps, a twilight edge,
  glowing lava flows, banded giants with vortices and great storms, craters, rings in many shapes – and every planet
  its own shade of its type.
- City lights on the night side of habitable worlds in inhabited systems.
- Collection → Planet types: a tile per planet and moon type with picture, size, mass, temperature and description.
- Debug: jump to a planet of each type.

## alpha 0.6.37.6 – 2026-11-08

- The plasma arc of a coronal mass ejection no longer stops at a straight edge – it fades out before the star's
  picture ends.
- **Eruptions by star class:** red dwarfs and red supergiants erupt far more often (a red dwarf every 3–7 minutes),
  hot blue stars rarely (every 14–30).
- Flares on the star's disc smaller, rarer and in the star's hot colour instead of white.

## alpha 0.6.37.5 – 2026-11-08

- **Coronal mass ejection:** inside the shockwave (combat and recon view) plasma streaks race across the screen away
  from the star and the light turns warm.
- Debug: the coronal mass ejection starts at the countdown (banner and alarm, 10 s to the eruption).

## alpha 0.6.37.4 – 2026-11-08

**Coronal mass ejection warning:** 10 s before the eruption a red, bold, pulsing banner top centre – "! ENERGY SPIKE
DETECTED ON THE STAR !" with a countdown – and a calm, alien alarm that fades in and out (sound: "extraterrestrial
alert sound" by fnx_sound, Pixabay). The audio system now plays MP3 as well.

## alpha 0.6.37.3 – 2026-11-08

**Zooming between the recon view and the map:** the planets, moons and the star glide from their place in the sky to
their place on the map (and back), the zoom passes the change at an even pace (about 0.6 s), and a holo grid flashes
up while a scan line sweeps the screen – like a cockpit display switching to the tactical view.

## alpha 0.6.37.2 – 2026-11-08

- **Neutron stars** blaze much brighter – a bright point even on the system map.
- **Warp** from 12,000 km (was 40,000): planet to moon no longer means minutes of sublight flight.
- **Star classes in the Collection** (instead of the codex): a tile per class with a small animated picture, size in
  solar radii, mass in solar masses, surface temperature and a description; classes not yet visited show as "???".
- **Coronal mass ejections** hit harder: a ship in warp is torn out of it (emergency shutdown), cloaks fail for 20 s,
  drones are knocked out for a few seconds (white lightning), mines go off.

## alpha 0.6.37.1 – 2026-11-08

**Package 37: new star types.** A new game is needed.
- Twelve star types: the main sequence O, B, A, F, G, K, M, pink brown dwarfs, red supergiants (ten times a G star –
  the planets move out), white dwarfs, neutron stars and black holes (only in systems without stations, now and then
  with a research station).
- All animated in a finer pixel style: boiling surfaces, sunspots, prominences rising and falling on the limb, flares;
  a neutron star with huge glowing field lines and sweeping jets; a black hole with its turning accretion disc, the far
  side bent over the hole, and a gravitational lens bending the stars behind it.
- Coronal mass ejections: warning in the log, an eruption on the star, then a shockwave races through the system –
  sensors jammed, shields weakened (collapsed close to the star).
- The solar collector draws by the star's brightness; a black hole pulls ships in close up and crushes what crosses
  its horizon.
- Codex entries; debug: any star type in the current system, an ejection at once.

## alpha 0.6.36.7 – 2026-11-08

**Depth:** the parallax of planets, moons and stars now depends on how close they are – a near planet glides by as a
layer of its own (slower than the ships, clearly faster than the stars), a far one hardly moves; right above a body it
slides smoothly under the ship.

## alpha 0.6.36.6 – 2026-11-08

**More impressive planets, moons and stars:** about as big as before from afar, but growing ever more steeply towards
the surface – right above a planet it fills the screen (about 1,050 instead of 650 px radius at 1080p). The star is
half again as big and has a wide, soft corona.

## alpha 0.6.36.5 – 2026-11-08

**Station orbits:** like moons, stations have their own orbit round their planet or moon and stand somewhere else on it
each time you jump in (the rocks round a station go with it); the orbits show in the Orbit view. Waystations stay on
their gate route. A new game is recommended.

## alpha 0.6.36.4 – 2026-11-08

**Emergency shutdown** on the warp key (X): in warp it only does the shutdown – once asks, again within 5 s drops out.
Space did not get through (it also presses focused buttons) and centres the camera again.

## alpha 0.6.36.3 – 2026-11-08

- **Warp** half again as fast.
- **Emergency shutdown:** Space in warp asks in the log; Space again within 5 s throws the ship out of warp – flash,
  glittering trail, and it tumbles three times round itself before it answers the helm (the drive needs 6 s).
- **Planets, moons and stars** come much closer (right above a planet about 650 instead of 450 px radius at 1080p) and
  grow and shrink smoothly – no hard limits, a fixed pixel grid instead of one that jumped with every change of size.

## alpha 0.6.36.2 – 2026-11-08

**Orbit view:** a new zoom level between Recon and System (F3; System is now F4) – a flat map 260,000 km round the ship,
enough for a planet with all its moons, their orbits and names. Not during a warp (the wheel skips it). Saved zoom keys
are reset once to the new defaults.

## alpha 0.6.36.1 – 2026-11-08

**Package 36: moons.** A new game is needed.
- Gas giants have 2–3 moons, rocky worlds mostly one; four kinds: rocky (craters), ice, volcanic (glowing volcanoes) and
  captured asteroids (lumpy). 3,000–7,800 km across the radius – far bigger than colossi. Named after their planet
  ("Sonnenwende V-a").
- Every time you jump into a system, the planets and moons stand somewhere else on their orbits; stations, ring rocks
  and moon fields move with them. Saved with the game.
- Some stations orbit a moon; every fourth moon has a small asteroid field; pirates hide behind moons.
- Moons are warp targets and show in the overview and on the system map (orbits and names when zoomed in).
- Debug: moons of the system, jump to a moon (of each kind), roll the orbits.

## alpha 0.6.35.17 – 2026-11-08

**Warp to stations:** stations and pirate havens can be warped to from 8,000 km (other targets still 40,000 km). Standing just outside a no-fire zone used to mean minutes of sublight flight; now a ship always arrives 2,500 km from the station.

## alpha 0.6.35.16 – 2026-11-08

**Fixed:** the recon view slowed to about 10 FPS in asteroid fields with colossi. Slices of the radar shadows could be twisted, and every failed triangulation logged an error, several times a frame (about 95 ms a frame, now about 20 ms). Contacts out of radar range are skipped before the sight-line check.

## alpha 0.6.35.15 – 2026-11-08

- **Warp:** the lines streaming behind a ship in warp are gone (the friction glow replaces them).
- **FPS display** in the top bar, left of the Ship / Pilot / Map buttons: frames per second and the slowest frame, green / yellow / red; can be switched off in the settings.

## alpha 0.6.35.14 – 2026-11-08

**Warp:** the tunnel and the warp trail reach only from the start to the end of the warp (on the system map they ran to infinity). Fixed: the system map stuttered badly during a warp – thousands of tunnel rings were drawn every frame (about 170 ms a frame, now about 17 ms).

## alpha 0.6.35.13 – 2026-11-08

**Warp:** no more slowing down at the end – after accelerating, the ship flies at full speed right to the destination and drops straight to sublight; the exit flash appears at the point of arrival.

## alpha 0.6.35.12 – 2026-11-08

**Warp:** a much brighter flash going in; the flash coming out comes a moment before arrival; the glittering trail is shorter (about 3.5 s). Instead of the arc in front of the ship, every ship in warp glows like a ship entering an atmosphere, only bluer – a hot sheath round the bow, flickering tongues of flame and sparks streaming back.

## alpha 0.6.35.11 – 2026-11-08

**Warp trail:** instead of smoke, a long glittering trail along the course (7,500 km, longer than the combat view), brighter towards the ship; it flares up all at once, then fades from the far end towards the ship.

## alpha 0.6.35.10 – 2026-11-08

**Warp:** a bright flash of light going into and coming out of warp; every ship leaves a small bluish trail of smoke when it drops out, fading after a few seconds.

## alpha 0.6.35.9 – 2026-11-08

**Warp tunnel:** a fixed size (1,300 km radius) – big at close range with room for the whole formation, a narrow tunnel on the recon view; always centred on the ship leading the formation.

## alpha 0.6.35.8 – 2026-11-08

**Warp:** the radar is hidden during a warp (it showed in recon by mistake in 0.6.35.7).

## alpha 0.6.35.7 – 2026-11-08

**Warp:** the camera stays at close range (zoom out by hand whenever you like – the radar now shows in recon during
a warp too); a new warp animation: a pale blue tunnel forms round the ship, rings and streaks rush past.

## alpha 0.6.35.6 – 2026-11-08

**Ice colossus:** the spiked crystal is now a rounded ice ball with soft bulges.

## alpha 0.6.35.5 – 2026-11-08

- Radar shadows end at the radar range.
- Two new colossus shapes for each kind of rock: metal slab and spindle, stone rubble pile and kidney, ice teardrop
  and spiked crystal – with matching radar shadows.
- Colossi can be mined: a huge deposit of two ores; mined out they stay and show as empty.
- Small asteroids mined out break apart, the pieces drift and fade; they grow back after 30–60 minutes.

## alpha 0.6.35.4 – 2026-11-08

**Asteroid fields:** more compact (12,000–22,000 km) and made of many small structures – dense knots, patches and streams – with open space between them and some very dense spots. Every field now has 3–5 colossi (one more in lawless space).

## alpha 0.6.35.3 – 2026-11-08

**System map centred on your ship again** (as before); the camera-limit fix from 0.6.35.2 stays.

## alpha 0.6.35.2 – 2026-11-08

**System map centred again:** the map is centred on the star (Godot's default camera limits had pushed the map of the bigger systems aside); the camera glides between map and close view.

## alpha 0.6.35.1 – 2026-11-08

**Part 6 begins – package 35: system scale.** A new game is needed.
- Systems are three times as big (6 million km); warps are faster, crossing a system takes 20–30 s.
- Asteroid belts and Kuiper belts as scenery: a band on the system map, rocks drifting in the background close up.
- Asteroid fields lie in the belts, are bigger and denser and come in five styles (clustered, band, dense core,
  boulder field, gravel field).
- More traffic (about half again as much, up to 90 ships per system).
- A short loading screen at the start; asteroid pictures and the colossus shader are made ahead of time (no more
  hitch when entering a field with colossi), the next system during the hyperspace jump.

## alpha 0.5.34.4 – 2026-11-08

**Part 5 review fixes** (reviews/teil5_review.md): wingmen and the platform ship keep to no-fire zones (self-defence
allowed) and are repaired when docked, their damage survives jumps; the SHIP LOST window takes every key; leaner saves
(only current bar offers and crew quarters with someone in them); the wingmen panel hides in hyperspace; debug
"Lose the active ship" works in god mode; dead code removed.

## alpha 0.5.34.3 – 2026-11-08

**Collection:** the categories as a list of buttons on the left, the chosen one on the right.

## alpha 0.5.34.2 – 2026-11-08

**Wanted posters:** the ship's icon (in the captain's paint) beside the ship's name.

## alpha 0.5.34.1 – 2026-11-08

**Package 34 – codex, collection, wanted posters** (the last package of part 5).
- Notorious pirates are characters: a face and Piloting & Gunnery that grow with their stars and work on their ship.
- The Bond Office shows Wild West wanted posters: WANTED, the mugshot, the stars, DEAD OR ALIVE, the reward, the ship
  and the escort.
- Pilot window → Pilot → Collection: crew perks you have had (the rest "???") and the posters of the notorious
  pirates you destroyed.
- Codex: new category Pilot & Crew (8 entries), unlocked at first contact.

## alpha 0.5.33.1 – 2026-11-07

**Package 33 – wingmen** (mercenaries for ground combat follow in part 7).
- Pilots for hire at The Bar: real characters with Piloting and Gunnery, two traits and their own ship with a
  standard fit; contracts of 30, 60 or 120 minutes, paid up front, plus a share of the income (F 2 % … A 20 %).
- They fly in formation, warp and jump with you (and follow whom you follow), dock with you; orders aggressive,
  defensive, passive and "attack my target" in the WINGMEN panel (keys N and Y; the others can be bound).
- At most two (the second with Leadership 3); Leadership makes them better and cheaper. Skill tree: Wing Command.
- Citadel: a Hadrian S ship on the launch platform, flown by a Co-Pilot with the new perk Wingman; launch and recall
  in space; destroyed, it can be recalled at a hangar for 10 %.

## alpha 0.5.31.5 – 2026-11-07

**The rebuild summary as tiles:** the lost ship, the respawn station, the crew (in the pod with its signal time / lost), cargo and losses; on the right the costs (hull, modules and drones), the total, the remaining balance, REBUILD and the starter ship – which asks once more.

## alpha 0.5.31.4 – 2026-11-07

**Package 31a – losing the ship.**
- Every crew member rolls to survive (better quality, better odds; Lucky, Medic); survivors drift in an escape pod
  at the wreck – visible in space, on the radar and in the overview – until the signal fades (5–22 minutes by
  quality). Fly within 2,500 km to take them aboard.
- The pilot comes back at the last station docked at in a Dragonfly; the SHIP LOST window offers to rebuild the
  lost ship for 10 % of its value (hull, modules, drones).
- New crew perks: Cargo Insurance (the hold comes back with a rebuilt ship), Insurance Agent (rebuild 5 % cheaper).

## alpha 0.5.31.3 – 2026-11-07

**Station concourse:** the station service tiles grow with the window (the icon too); when space runs short only the services scroll, not the whole column.

## alpha 0.5.31.2 – 2026-11-07

**Station concourse:** the station services are squarer tiles, two in a row (The Bar and the Image Studio among them).

## alpha 0.5.31.1 – 2026-11-07

**Package 31 – the crew and The Bar** (packages 31 and 32 together).
- Ships from M up have crew posts (2–10), some required: without them the ship cannot undock; a bought ship comes
  with rookies (quality F) on the required posts.
- Random crew: name, portrait, profession (7), quality F–A, one rolled bonus, very rarely a perk (e.g. Second
  Profession). They learn from the right work and step up with a rolled improvement. The crew of the active ship
  takes a small share of sales, bounties and contract rewards.
- Ship menu → Modules → CREW; The Bar on the concourse to hire; crew quarters at every station; skill tree: hull
  tiles bring their professions, new tile Science Officers; debug functions.

## alpha 0.5.30.5 – 2026-11-07

**Pilot window:** the Pilot tab comes first and U always opens it. It has three sub-tabs: Info (portrait, name,
level, attributes and all statistics – finances, flight & combat, work, contracts), Standings and Codex (both moved
from the ship menu). The ship menu keeps Info (news, active ship, contracts, fleet), Modules, Ship, Inventory,
Transactions, Industry and Market. The HUD hint opens the skill tree or the perks.
Smoke test: `-- --smoketest --only=pilot,codex` runs single test groups.

## alpha 0.5.30.4 – 2026-11-07

**HUD:** the Ship, Pilot and Map buttons moved to the top right, where the old buttons were.

## alpha 0.5.30.3 – 2026-11-07

**HUD top bar:** three icon buttons top right – Ship [I], Pilot [U], Map [M]; the Pilot button glows green when
skill tree tiles or perk points wait. The zoom, station and help buttons are gone (F1–F3, L and H still work).

## alpha 0.5.30.2 – 2026-11-07

**The skill tree as a real tree** – a new game is needed.
- Drawn as a tree: the Pilot Licence is the trunk, Shields above it, then branches by activity (defence, combat,
  mining, industry, flight, exploration, security, trade, drones); mastery are the roots. Drag it, walk it with
  W/A/S/D, the detail of a tile on the right.
- Everything can be bought; using needs the tile: a locked ship stays docked, a locked module stays offline, a
  locked core module cannot be fitted (fitted ones keep working). Station manufacturing has its own tile.
- New achievement: damage taken (defence branch).

## alpha 0.5.30.1 – 2026-11-07

**Package 30 – perks and the skill tree.**
- 40 skill tree tiles in eight branches open by achievements and are confirmed; they gate buying ships and modules
  and manufacturing (blueprints) – owned ships and modules stay usable.
- 24 perks in six groups, one point per pilot level; their effects work (crew perks with packages 31 and 33).
- Pilot window: Skills, Perks, Skill tree, Pilot; HUD hint for tiles to open and perk points; debug: unlock all.

## alpha 0.5.29.2 – 2026-11-07

- Skills rise by themselves (no more confirming); a new pilot level fed by all experience, every level a perk point.
- Skill bonuses only on the ships the pilot owns. Roadmap: the new progress design and a proposal for perks and the
  skill tree tiles (package 30).

## alpha 0.5.29.1 – 2026-11-07

**Package 29 – skills and the Pilot window.**
- Twelve skills from the attributes, levels 0–10 (+1 % each), experience by doing; an advance is confirmed.
- Their bonuses work on the pilot's own ships (speed, damage, power, scanners, warp, mining, prices, rewards …).
- Pilot window [U]: skills, skill tree preview (package 30), the pilot; the HUD shows a ready advance.
- Debug menu → Character: skill levels, experience, the bonuses at work.

## alpha 0.5.28.3 – 2026-11-07

**Package 28 – the pilot and character creation.**
- The pilot is part of the save: name, call sign, looks, five attributes.
- Pixel construction kit: one look makes the 48 × 48 portrait and the 16 × 16 top-down figure (15 options, 94 choices).
- Character creation at the start of a new game; the Image Studio (Visage Clinics) changes the looks at stations.
- The concourse shows the portrait and the attributes; debug menu → Character.

## alpha 0.5.28.2 – 2026-11-07

- Menus by keyboard: W/A/S/D (and the arrow keys) move the highlight, Enter/Space press, Q/E switch tabs, Escape
  goes back; while a menu is open the ship does not fly. A key group "Menus" of its own in the key bindings.

## alpha 0.5.28.1 – 2026-11-07

**Package 28a – the audio framework (part 5 begins).**
- Audio autoload with channels (music, atmosphere, effects, interface), volume sliders per channel in the settings.
- 36 synthesised placeholder sounds (priority A of docs/audio/sound_list.md) wired to game events: engine, warp,
  jumps, docking, weapons, hits, explosions, modules, drones, interface, purchases, contracts, messages, alarms, space.
- Debug menu → Audio: play every sound, live channel levels, event log.

## alpha 0.4.25.47 – 2026-11-07

**The rest of the part 4 code review.**
- Leaving NPC carriers take their drones along quietly; a hit ends the cloak, which also costs energy in warp
  and for NPCs; the focus lance breaks off when its target warps or cloaks; the trader drone holds the runway.
- Smaller fixes: wormhole location text, factory jobs of lost ships, drones in the ship value, empty storage
  entries, real reasons in the outfitter, debug teleport never to a waystation with an L ship, "wait" state.
- Performance: power plan only on changes, drone lists once per frame, cached hull data.
- Keyboard flight through the command bus; clean-ups; 8 new checks.

## alpha 0.4.25.46 – 2026-11-07

**Fixes from the part 4 code review (the top 5, report in reviews/teil4_review.md).**
- Drones removed before take-off give their place in the deck / hatch queue back (trader drones no longer wait for ever).
- A new order during an approach or landing breaks it off cleanly (pad freed, hatch shut, ship full size).
- The bundled focus lance draws the power of all its crystals.
- Point defence, auto mode, anti-drone pulse and mine settings are kept with the ship (jumps, saves, docking).
- Ships waiting inside a waystation cannot be targeted; wormhole jumps stow the drones first and refuse in warp.

## alpha 0.4.25.45 – 2026-11-07

- Ship info: the current speed is shown as a number with its unit (km/s) instead of a bar.

## alpha 0.4.25.44 – 2026-11-07

**Package 27 (part 2) – the outfitter rework.**
- Categories → the ship's slots → module families → size · quality tiles → description and value changes;
  buy & fit straight into the slot; a footer with the ship's key values and power.
- A short description for every module family (also in all module tooltips); current speed in the ship info.

## alpha 0.4.25.43 – 2026-11-07

**Package 27 (part 1) – new station concourse.**
- Three columns instead of the tile grid: commander (placeholder) and news; the docked ship with its state and
  the ship services (refuel / repair in one click); the station with faction, economy, balance and its services.
- Waystations offer only market, fuel, repair and hangar (as decided for part 4).

## alpha 0.4.25.42 – 2026-11-07

**Package 26 – station type 0: waystations with landing pads.**
- New small station type in most systems with 2–4 round landing pads instead of hangar bays (S and M ships only).
- Landing and lifting off through an animated hatch; one ship per pad at a time, the others wait.

## alpha 0.4.25.41 – 2026-11-07

- Kanayama-maru market: traders park nearby and send a cargo drone that lands on the runway over the stern,
  picks up the wares, takes off past the bow and flies back; one drone on the runway at a time.

## alpha 0.4.25.40 – 2026-11-07

- Cloak: using a weapon, tool or module ends it (a refused one does not); target locks are allowed while cloaked
  and kept when cloaking.
- New drone module Drone Cloak Emitter (only for ships with a cloaking device, sold by Directorate outfitters):
  the drones become Axiom cloak drones with their own look and cloak together with their ship.

## alpha 0.4.25.39 – 2026-11-07

- Threshold: the black hole goes out under the cloak and ignites again once the ship is fully visible.

## alpha 0.4.25.38 – 2026-11-07

- Threshold: the black hole's ignition flash now really flares up – halo, white-hot centre, rays, the hull lights up.
- Cloak: no more rectangle over the ship – a cyan scan line runs over the hull from stern to bow and the ship fades
  behind it; it shows again bow first.

## alpha 0.4.25.37 – 2026-11-07

- Threshold: the black hole ignites 2.5 s after undocking – a flash of light, the hole grows, then the accretion
  disc forms; it goes out with a flash when docking. It keeps the same orientation whichever way the ship turns.

## alpha 0.4.25.36 – 2026-11-07

- Threshold: a raised bridge at the stern – three stepped decks casting shadows, the cabin on top looking forward
  through a cyan window band; the drone hatch moves to the forward hull.

## alpha 0.4.25.35 – 2026-11-07

- Threshold: the black hole now looks three-dimensional – the accretion disc is tilted towards the camera, its near
  band crosses in front of the hole and its far half is lensed into a bright arc over the top; one side glows hotter.

## alpha 0.4.25.34 – 2026-11-07

**Package 25g – Axiom Astronautics: research and jump ships.**
- Parallax and Threshold: futuristic graphite hulls with cyan light lines; the Threshold's round core holds an
  artificial black hole with a turning accretion disc.
- Sensors +25 %, signature −25 %, power use −15 %, built-in cloaking device.
- Parallax marks systems with undiscovered anomalies on the galaxy map.
- Threshold: wormhole jumps without a gate for exotic matter (new resource from rare anomalies).
- Axiom research ships in Directorate systems. Debug: +10 exotic matter.

## alpha 0.4.25.33 – 2026-11-07

- The Cathedral bundles its crystals too: one lance, one tile; in auto mode the lance takes turns
  between up to six targets.
- Lance balance: each lance carries the damage of its whole 2 s cycle – bundling really gives +30 %
  damage per second.

## alpha 0.4.25.32 – 2026-11-07

- Focus lance: the crystal beams meet between ship and target, charge for a moment, then a thick beam
  burns into the target for about a second.
- Templar and Cathedral: golden spikes slide out and back in now and then.
- Anti-drone pulse: a bar in its module tile shows the next pulse; knocked-out drones crackle with red
  lightning.
- Debug: a hostile pirate drone carrier (debug only).

## alpha 0.4.25.31 – 2026-11-07

**Package 25f – Forge of Return, the Covenant's flying temples.**
- Acolyte, Templar, Cathedral: crimson battlements and crystal batteries around a radiant nave; the
  Cathedral with a rose window, bell towers and a golden halo.
- Focus-crystal lasers (Covenant outfitters and ships only); beam bundling into a focus lance (+30 %).
- Reactor +80 % (Cathedral +120 %), weak hulls, no drone hangars.
- Cathedral: anti-drone pulse (drones drift for 15 s, friend or foe) and auto mode for its lasers.
- Covenant patrols fly Forge ships. Debug: nearby NPC carriers launch their drones.

## alpha 0.4.25.30 – 2026-11-07

- Roadmap: parts 8 (story start in Beyond, packages 55–65) and 9 (feeling and balancing, packages 66–74)
  planned; new package 28a (audio framework) at the start of part 5; loading basics in package 35;
  new principle: a small code review at the end of every part.

## alpha 0.4.25.29 – 2026-11-07

- Concordia: three engine flames – the spine and both flight wings (they move with the wings).

## alpha 0.4.25.28 – 2026-11-07

- Concord stripes pulse much more visibly; the combat light is bigger.
- Drone launch light: a construction-site amber warning light – flashing, with a chase, and beacons at
  the corners of open doors.
- Fix: the Concordia's open doors were hidden under its flight wings – now drones visibly launch from
  and return into open doors.
- Hydraulic struts with joints connect the hull and the deployed flight wings.

## alpha 0.4.25.27 – 2026-11-07

- Concord light effects: the blue stripes pulse; in a fight a bright spot runs along them from bow to
  stern; the Concordia's stripes light up yellow while its drone doors are open.
- Concordia: the flight wings move out and back in space and fold in to dock (the doors move along).
- Drones use the hangar doors in turn, also when launched one by one.

## alpha 0.4.25.26 – 2026-11-07

**Package 25e – Concord Fleetworks, the first faction ships.**
- Demos, Quirinus, Concordia: Assembly drone carriers with visible hangar doors (2 / 4 / 6).
- Drones doubled in every way, control range up to the recon range; own guns half damage; shields +60 %
  with three times the downtime. Concordia: eleven drones in Assembly blue.
- Drones launch from several hangar doors at once and land in the nearest.
- NPC carriers launch their drones in a fight and recall them afterwards.
- Faction ships only at the faction's shipyards and only with standing (Neutral / Friendly / Allied).
- Assembly patrols fly Concord carriers in their own systems (now and then a Goliath).
- Debug: fill the drone hangar. Fix: a hull's shield bonus no longer shortens the shield downtime.

## alpha 0.4.25.25 – 2026-11-07

- Mogura and Iwakudaki: drone hatch moved 3 pixels towards the stern (cleaner fit).

## alpha 0.4.25.24 – 2026-11-07

- Drone hatches: the lower half lies in shadow like the hull, so the crease along the centre line runs
  across the hatch too (also on the sliding panel while it opens).

## alpha 0.4.25.23 – 2026-11-07

- The shut drone hatch is now part of the ship's picture, so it also shows in the hangar, the shipyard
  and the ship menu.

## alpha 0.4.25.22 – 2026-11-07

- Every ship that carries drones has a visible sliding drone hatch (Kanayama-maru: its runway): drones
  rise out of it and land in it; drawn in the maker's colours, sized by ship class.

## alpha 0.4.25.21 – 2026-11-06

- Engine flames sit at the actual drives: the Goliath shows two flames at its arm drives instead of
  one in the middle (ships with a centred drive look as before).

## alpha 0.4.25.20 – 2026-11-06

- Goliath: the arms are hinged at the stern (straight drive sections) and open in space into a round
  arc that carries the pincers far out; they fold in to dock and undock (eight stages).

## alpha 0.4.25.19 – 2026-11-06

- Goliath redesigned as a scorpion: wide-sweeping segmented arms ending in pincers around long cannons,
  a long spiked bow, two slanted red eye-slits as the bridge that glow up and fade, a drone hatch on the spine.
- Citadel gets the armoured-dome bridge; all four bridge designs are kept as variants.
- Ship art scripts are now kept in `tools/art/`.

## alpha 0.4.25.18 – 2026-11-06

- Hadrian design pass: rounded side parts; the Goliath's arms start far aft and arch around the hull,
  with one drive on each arm instead of a main engine.
- Citadel: a big launch platform with a sliding hatch (the S ship rises and lifts off – animation for
  now, the ship comes with part 5) and a small drone hatch – drones rise out of it and land in it.
- Debug menu → Ship: "Citadel: launch from the platform".

## alpha 0.4.25.17 – 2026-11-06

**Package 25d – Hadrian Dynamics.**
- Talon, Maul, Goliath and Citadel: brutalist warships in dark steel with red lights.
- Reflective hull (10/15/20 % of armour damage back to the attacker), +20 % explosive resistance on M/L.
- Weak outside combat: few tool slots, no ore hold, −50 % mining/salvage/analysis, high signature.
- Talon fires rockets and torpedoes faster; Goliath and Citadel with built-in point defence.
- Goliath and Citadel only at military stations and the biggest yards.
- Pirates fly worn, rusty Hadrian copies; Directorate patrols fly Hadrian ships.
- Debug menu: spawn any ship next to you.

## alpha 0.4.25.16 – 2026-11-05

- Empress: the ripples on the pool move at half speed (the glint on the glass dome is unchanged).

## alpha 0.4.25.15 – 2026-11-05

- Studio intro: the d, the title and the brackets stay centred when the window is resized or maximised.

## alpha 0.4.25.14 – 2026-11-05

- Roadmap: plans for parts 5 (Character Update), 6 (New Worlds Discovery Update) and the new part 7
  (The Sky Is Not Enough) taken over from the draft; story moves to part 8, balancing to part 9;
  phases 1 and 2 swapped (story & endgame first, co-op last); new working principles (debug functions
  per package, single player first but co-op-ready, alpha until the end of phase 2).

## alpha 0.4.25.13 – 2026-11-05

- Empress redesigned: narrower window sides and a long park deck under a glass dome between the gold
  stripes – lawn, trees, flowers and a pool with sun loungers; animated pool water and a glint on the dome.

## alpha 0.4.25.12 – 2026-11-05

**Package 25c – Maison Aurelle and passenger transport.**
- Passenger cabins: bulk, business and luxury suites (luxury only in Aurelle ships), with new icons.
- Bulletin board tab "Passengers": transport contracts, paid per passenger and jump, with deadlines;
  failure (late, or ship lost) costs a little standing.
- Four Maison Aurelle ships: Pearl, Boulevard, Opal, Empress – ivory and gold, rows of windows.
- Built-in afterburner (Pearl, Boulevard, Opal); Empress with fast warp, strong shields, half-size cargo
  racks, +25 % luxury pay and white drones with their own shield.
- Aurelle yards only at trade hubs of rich, safe Assembly/Covenant systems; Boulevard liners as NPC traffic.

## alpha 0.4.25.11 – 2026-11-05

- Ship menu: the on-board market has its own tab "Market"; "Industry" and "Market" only show on ships that have a factory / a market.

## alpha 0.4.25.10 – 2026-11-05

- Fix: the warp alignment ring on the ship shows the real time until the warp starts (alignment time plus
  the turn still needed) – it used the jump drive spool time and was full too early on slow KHI ships.
- Kanayama-maru: drones roll down the whole runway one after the other and only break away past the bow.
- Roadmap_Entwurf.md (draft worked on in Claude Chat) is kept out of the repository (.gitignore); the
  screenshot folder is ignored by Godot's importer.

## alpha 0.4.25.9 – 2026-11-05

- Kanayama-maru: the bridge is now the rounded, sloping glass front of the first design, at the front of the rear block.

## alpha 0.4.25.8 – 2026-11-05

- Kanayama-maru redesigned as a carrier: tall rear block with the bridge flush at its front, a flat flight
  deck in front of it (lights, centre line, drone lifts). Drones launch forwards off the deck and land on it.

## alpha 0.4.25.7 – 2026-11-05

**Package 25b – Kanayama-maru, the heavy industry ship.**
- Drone carrier for nine yellow mining drones (+25 % mining, +5 m³), station-grade refinery, prospector.
- Manufacturing takes time everywhere (stations too); jobs are queued and saved.
- On-board factory: modules and drones from the cargo hold.
- On-board market: traders come over and buy at fair prices; big offers attract pirates.
- New ship menu tab "Industry"; icons for factory and market.

## alpha 0.4.25.6 – 2026-11-05

- Intro: the laser shot is now a short, soft zap and quieter (less tiring).

## alpha 0.4.25.5 – 2026-11-05

- New studio intro "dlirius games": the animated d on black with a laser shot per colour bar, the title in
  silver with two brackets; a click slams them together around the d with a hammer-on-iron sound, any key
  skips. The game now starts with scenes/intro.tscn.

## alpha 0.4.25.4 – 2026-11-05

- Fix: the power priority of built-in modules (refinery, prospector) can be set in power management.
- Balancing: the KHI refineries draw twice the power (8 / 16 / 32 MW while on).

## alpha 0.4.25.3 – 2026-11-05

- Fix: the KHI smoke plumes blew inwards across the hull – they now blow outwards from the flank pipes.

## alpha 0.4.25.2 – 2026-11-05

- KHI refinery smoke now sprays in thin plumes sideways out of the exhaust pipes on the flanks instead of out of the stern (looked like a burning engine).

## alpha 0.4.25.1 – 2026-11-05

**Package 25a – Kanayama Heavy Industries mining ships.**
- Manufacturer framework: every hull has a maker; shipyards stock hulls by the maker's rules; mining
  colonies get a small yard (Mogura, Anaguma, Drillhead); the shipyard shows the maker.
- Mogura (S), Anaguma (M), Iwakudaki (L) with built-in ore hold, refinery (switchable, power while on,
  black smoke) and prospector; +10 % mining, slow to turn and to warp. Half the NPC miners fly them.
- Built-in modules are framed in gold and listed in the ship menu and power management.

## alpha 0.4.24.2 – 2026-11-05

**Package 24 – ship manufacturers (planning finished).**
- Seven manufacturers in data/manufacturers.gd, each with its own crest (three new crest shapes, warning
  stripes) and a codex entry with motto, history and planned models.
- The recon radar always shows 10,000 km, independent of the window size; drone control ranges never
  exceed it.

## alpha 0.4.24.1 – 2026-11-05

Package 24 (planning of the manufacturers) is running – this update carries two small changes:
- Hivewright Drone Works now goes by the tag HWD.
- Drones keep out of the radar shadow of colossi: they ignore targets behind one, fly back when they end
  up in a shadow, and steer around colossi.

## alpha 0.4.23.4 – 2026-11-05

- K launches one drone per press (up to the maximum); new action "Launch all drones" without a default key (Settings → Controls).

## alpha 0.4.23.3 – 2026-11-05

- Idle drones fly a symmetric formation: mirrored pairs left and right, an odd one exactly behind on the centre line, same heading as the ship.

## alpha 0.4.23.2 – 2026-11-05

- Ship menu → Modules: new category for the drone hangar equipment (weapon, mining laser, drone module).
- Icons for the drone hangar and the drone modules (also on the Drone Bay tile).

## alpha 0.4.23.1 – 2026-11-05

**Package 23 – drones.** 498 smoke-test checks pass.
- New core slot: Drone Hangar (size 1–9, quality = room); drones out at once by hull (S 1 … L 9).
- Hangar equipment for all drones: weapon (size 1), mining laser (size 1), bonus slot for 8 new drone
  module families.
- Drones with combat / mining / repair roles and behaviours, sealed fuel (about 5 min), 9,000 km
  control range; they really fire and mine; lost when empty or destroyed.
- Drone window at the top left edge, keys K (launch) and P (recall); into the hangar for warps and
  jumps and out again afterwards.
- Drone Bay (Hivewright Drone Works) at every station.
- Test fix: the manual-weapons test no longer fails when its pirate carries a radar jammer.

## alpha 0.4.22.4 – 2026-11-05

- Fix: a newly locked target becomes the active one (modules on the old target turn yellow).
- Fix: modules no longer switch off when their target leaves the sensor range – they wait (orange), the
  target is locked again automatically when it is back (within 60 s) and they fire again.

## alpha 0.4.22.3 – 2026-11-05

- Module tiles: green = active on the current target, yellow = active on another target (out of range is now orange).
- Balancing: all weapon ranges +10 %, sensor ranges +15 %.

## alpha 0.4.22.2 – 2026-11-05

- Tab: ships first, then asteroids, wrecks and anomalies; with nothing selected it starts with the ships again.

## alpha 0.4.22.1 – 2026-11-05

**Package 22 – multi-focus.** 462 smoke-test checks pass.
- Every weapon and tool keeps the target it was switched on against; pressing a running module's key
  moves it to the active target. Lock slots 3–6 by sensor size; T1/T2 labels on tiles, locks, brackets.
- Bigger NPC ships split their fire over several targets.
- Targeting keys: Tab cycles everything in sensor range, V hostile ships, C friendly ships.

## alpha 0.4.21.2 – 2026-11-05

- Power bar: one block per priority group (passive and active no longer split).
- Modules that need no power are in group 0 (no priority buttons, no extra text).

## alpha 0.4.21.1 – 2026-11-05

**Package 21 – power management.** 446 smoke-test checks pass.
- The reactor output is a hard limit; passive modules always draw, weapons and active modules only
  while in use.
- Priority groups 1–4 per module: on an overload group 4 shuts down first, then 3, then 2.
- Ship menu → Modules → POWER MANAGEMENT: output bar per group and the module list with priorities.
- HUD power line (passive + active, groups off); chat messages on shutdown and restart.

## alpha 0.4.20.1 – 2026-11-05

**Package 20 – new module types.** 436 smoke-test checks pass. (From here on the last number counts
the updates within the current package.)
- Shield variants (balanced / capacitive / fast-cycle) and shield downtime for every ship: a shot-down
  shield stays offline (by size, type, quality) and restarts at 50 %.
- Point Defense Turret: shoots down hostile missiles, torpedoes and mines.
- Shield Transfer Beam: charges a friendly ship's shield from your capacitor, shortens its downtime.
- Cargo Scanner (manifests, smugglers' unregistered cargo) and Solar Collector (refuels near the star).
- Mine Launcher with four mine types sold as goods: proximity, timed, jammer, EMP.
- Radar Jammer – also used by pirates against you (radar static, short contact list, shorter locks).

## alpha 0.4.19.19 – 2026-11-05

- Debug menu (Pilot → Contracts): "Escort convoy" with adjustable freighters (1–6) and jumps (1–8) –
  an escort contract from the docked (or nearest) station to a random station exactly that many
  jumps away, accepted at once; the convoy rolls out and waits for you.

## alpha 0.4.19.18 – 2026-11-05

- Formation fix: the pilot's ship no longer lags behind in warp. Followers use the lead's position of
  the current frame (the pilot's ship was updated before the lead), and the lead takes the whole
  formation into warp in the same instant.

## alpha 0.4.19.17 – 2026-11-05

- Debug menu: "Reroll board here" also rerolls the station's faction contracts.

## alpha 0.4.19.16 – 2026-11-05

Formation flight and keyboard controls. 403 smoke-test checks pass.
- Followers fly a fixed V formation behind the lead and keep their slot for the whole warp.
- The lead of your group announces each warp and gate jump in the chat.
- WASD flies the ship (release: stop), the arrow keys pan the camera. Saved camera bindings from older
  versions are reset once.
- Tab selects the nearest hostile ship (again: the next one), B the nearest station within 5,000 km.

## alpha 0.4.19.15 – 2026-11-05

Convoy and group follow-ups, command hotkeys. 397 smoke-test checks pass.
- Group warp: the ship being followed warps at the speed of the slowest ship following it.
- After a pirate attack convoy ships no longer scatter; the convoy holds until no pirate is within its
  recon range and the pilot follows (≤ 8,000 km) or is right next to it (≤ 2,000 km); 2 min timeout.
- Your group (convoy, patrol, followed ship, followers) shows as green tiles at the top left.
- New rebindable hotkeys: R lock/unlock (nearest hostile if nothing selected), Q approach, X warp,
  J jump, G dock, F follow. Buttons show their key in the tooltip.

## alpha 0.4.19.14 – 2026-11-05

Patrol contracts work like convoy escorts now. 386 smoke-test checks pass.
- The contract gets its own patrol group: it starts at the issuing station (rolling out of its bays) or
  at a named gate/field, waits for the pilot (Follow or 3 s within 1,000 km), then flies its rounds.
- Marked green with a PATROL LEAD on combat view, radar and system map; Follow works (also in warp).
- Only flying with that group counts; it is released afterwards; if it is destroyed, the contract fails.
- Test fix: the notorious roaming test starts next to a safer system (was random).

## alpha 0.4.19.13 – 2026-11-04

**Package 19 – module size & quality system** (first package of Teil 4). 379 smoke-test checks pass.
**Old saves cannot be loaded any more** (save version 2) – please start a new game.
- Modules are family + size + quality ("Pulse Laser 2 · C"): 53 families, about 1,700 modules generated
  from size curves and quality factors (D lightest, F heaviest, B as heavy as A).
- Every hull slot has its own maximum size; smaller modules fit bigger slots; hyperdrive size sets the
  jump class.
- Outfitters stock sizes and qualities by station tier, manufacturing rolls the quality, military-grade
  gear is the biggest modules.
- Skiff and Longhaul are sold at shipyards, the Carrion Crow in Pirate Havens.
- Modules tab shows slot maxima and module size/quality; outfitter grouped by family.

## alpha 0.3.18.12 – 2026-11-04

Planning only: slot layouts of all nine current hulls agreed (per-slot sizes, core slots), hyperdrive
size ↔ jump class, Earthworks membership; the NPC-only hulls become buyable (Carrion Crow in Pirate
Havens, Skiff, Longhaul); patrols will fly their own faction's ships once the state manufacturers exist.

## alpha 0.3.18.11 – 2026-11-04

Planning only: the module system design for package 19 is agreed and recorded in the roadmap –
module = family + size + quality, size curves, smaller modules fit bigger slots, quality factors with
mass rules (D lightest, F heaviest, B as heavy as A), per-slot sizes for every ship.

## alpha 0.3.18.10 – 2026-11-04

Planning only (no gameplay change): all open questions of Teil 4 decided and recorded in the roadmap –
module system rebuilt from scratch (weapons size 1–4, slots defined per ship), quality F–A buyable and
S in the endgame, multi-focus as several active targets, drones limited by hangar + bandwidth, mines as
goods, radar jammer used by and against the player, type-0 station services, faction ships from
Neutral (top models Allied) at their own yards, specialised manufacturers starting with "Earthworks"
(today's hulls), about 24 ships, design discussed per manufacturer.

## alpha 0.3.18.9 – 2026-11-04

**Package 18 – Codex.** Teil 3 (NPCs and Factions) is complete. 365 smoke-test checks pass.
- In-game encyclopedia with 45 entries in six categories (Basics, History, Factions, Corporations,
  The Cluster, Technology); faction and corporation entries generated from their data.
- Ship menu tab "Codex"; "Codex" in the main menu shows everything discovered in any game.
- Basics known from the start, the rest unlocks on discovery (first dock, factions met, services used,
  colossi, havens, notorious pirates, raids, ion weapons, warp, gates, mining); "New Codex entry" notice.
- Roadmap: GitHub repository noted in the versioning rules.

## alpha 0.3.18.8 – 2026-11-04

First versioned state (git introduced). Phase 0.5, Teil 3 (NPCs and Factions): packages 10–17 done,
package 18 (Codex) is next. 354 automated smoke-test checks pass.

Content since moving to Claude Code:
- **Package 12 – Reputation per faction:** standing −100…+100 in five tiers; docking, prices, patrols,
  contracts, military gear; pirate standing opens the Pirate Havens; Standing tab in the ship menu.
- **Patrol beats:** patrols fly slow rounds at each waypoint (round stations, through fields).
- **Package 13 – Bounties & law:** bounties issued by the powers, bonds paid at any station of the
  issuer; criminal record per power (Suspect / Wanted / Most Wanted), fines, decay.
- **Package 14 – Pirate archetypes:** Raider, Brawler, Sniper, Ambusher, Leech (new ion weapons), Coward.
- **Package 15 – Notorious pirates:** five named captains with 1–5 stars, growing escorts and bounty,
  wanted posters; station raids by 5-star captains (announcement, hull bar, turrets, ion torpedo,
  offline stations with relief deliveries, red stars, defence reward).
- **Package 16 – World reactions & news:** news ticker (each item once, radio only near you), archive at
  stations, bounty campaigns, distress calls, fleeing traffic, escalation, wrecks for all ships.
- **Package 17 – NPC missions:** faction contracts (escort, patrol, intercept, hunt) and trader escorts at
  trade hubs; convoys of 2–4 freighters with pay per freighter; gathering outside the station, green
  markers, CONVOY LEAD, Follow (also in warp and through gates), warp interdiction and gate ambushes,
  warp announcements in the ticker.
- **Roadmap:** new Teil 4 "Module and Internal Ship Parts Rework" (packages 19–27).
- **Fixes & polish:** clear warning when a jump is not possible (e.g. fuel); debug raid buttons.
