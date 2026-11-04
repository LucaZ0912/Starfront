# Sternenfront – Changelog

Versions follow **alpha Phase.Teil.Paket.laufende Nummer** (see Roadmap.md → Arbeitsweise & Übergabe).
Every update gets its own entry, a commit and a git tag `v<version>`.

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
