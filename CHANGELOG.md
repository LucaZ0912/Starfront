# Sternenfront – Changelog

Versions follow **alpha Phase.Teil.Paket.laufende Nummer** (see Roadmap.md → Arbeitsweise & Übergabe).
Every update gets its own entry, a commit and a git tag `v<version>`.

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
