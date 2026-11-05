# Sternenfront – Changelog

Versions follow **alpha Phase.Teil.Paket.laufende Nummer** (see Roadmap.md → Arbeitsweise & Übergabe).
Every update gets its own entry, a commit and a git tag `v<version>`.

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
