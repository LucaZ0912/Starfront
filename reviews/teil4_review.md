# Code-Review Teil 4 – Modul- und Schiffsinnenleben-Rework (Pakete 19–27)

Stand: alpha 0.4.25.45 (Commit `d309355`), Review nur lesend, keine Datei außer dieser geändert.

**Geprüfte Bereiche:** `scripts/core/ship_fitting.gd`, `data/modules.gd`, `data/module_desc.gd`, `data/hulls.gd`,
`scripts/world/ship.gd`, `scripts/world/drone.gd`, `scripts/world/focus_lance.gd`, `scripts/world/market_drone.gd`,
`scripts/core/pixel_art.gd`, `scripts/core/station_art.gd`, `scripts/world/celestial.gd`, `scripts/autoload/universe.gd`
(Wegstationen, Shop), `scripts/ui/station/station_ui.gd`, `scripts/ui/station/outfitter_panel.gd`,
`scripts/autoload/commands.gd`, `scripts/autoload/game_state.gd`, `scripts/world/traffic.gd`, `scripts/world/system_view.gd`,
Testabdeckung in `scripts/debug/smoke_test.gd`.

**Smoke-Test:** headless durchgelaufen, `[SMOKE] DONE – failures: 0 []`. Die RID-/ObjectDB-Leak-Warnungen beim Beenden
(DummyTexture, ShapedTextData) sind Headless-Aufräumrauschen von Godot, kein Teil-4-Problem.

**Gesamteindruck:** Der Kern (Modulfamilien, `_compute`, Strombudget, Drohnen, Hersteller-Mechaniken) ist sauber
strukturiert und gut kommentiert; alle Spieleraktionen laufen über `Commands`. Die Fehler liegen fast alle an den Nähten:
Zustand, der beim Docken/Abdocken/Warp/Tod nicht zurückgesetzt wird, und Laufzeitzustand, der auf dem `Ship`-Node statt
im `ShipFitting` lebt. Kein Crash gefunden.

---

## Kritisch

Keine Befunde, die abstürzen oder Spielstände zerstören. Der Smoke-Test ist grün. Die beiden ersten „wichtigen" Punkte
sind aber im Spiel sichtbar und blockieren Mechaniken dauerhaft, daher stehen sie ganz oben in der Top-5-Liste.

---

## Wichtig

### W1 – Landeanflug unterbrechbar: Schiff bleibt geschrumpft und dunkel, Pad bleibt belegt
`scripts/world/ship.gd:294-314` (`set_order`), `:468-497` (`_dock_pad`), `:356-394` (`_update_docking`),
`scripts/world/celestial.gd:543-571` (`claim_pad`/`release_pad`)

**Situation:** Während der Order `docking` (Pad oder Bucht) klickt der Spieler irgendwo hin → `Commands.move` →
`set_order()` ersetzt die Order ohne Prüfung. `scale` (bis `PAD_SINK` = 0,62) und `modulate` (abgedunkelt, teils
transparent) werden nirgends zurückgesetzt – das Schiff fliegt klein und dunkel weiter bis zum nächsten Docken.
`release_pad()` und `set_pad_open(pi, false)` werden nur am Ende von `_dock_pad` gerufen; der Pad bleibt mit offener
Luke und gelber Lampe „belegt", bis irgendein anderes Schiff `claim_pad()` ruft und die Leiche aufräumt (lazy, Zeile 547).
Dasselbe gilt schon, wenn `_pad_approach` einen Pad bis 8.000 km vor der Station reserviert (`:450`) und der Spieler
dann abdreht.

**Fix:** In `set_order()` den Fall `order.type == "docking"` behandeln – entweder wie `undocking` die neue Order als
`then` puffern (Landung nicht abbrechbar) oder sauber abbrechen: `node.release_pad(self)`, `node.set_pad_open(pad, false)`,
`scale = Vector2.ONE`, `modulate = Color.WHITE`. Zusätzlich in `_pad_approach` den Pad erst reservieren, wenn der Anflug
wirklich beginnt (oder bei Orderwechsel wieder freigeben). Ein Smoke-Check dafür fehlt (siehe T1).

### W2 – `deck_queue` / `hatch_queue` laufen nie wieder auf 0: Starts verzögern sich, Marktdrohnen landen nie mehr
`scripts/world/drone.gd:56-78` (Start), `:438-483` (nur hier wird dekrementiert), `scripts/world/system_view.gd:1436-1446`
(`stow_all_drones`), `scripts/world/drone.gd:506-515` (`_lost`), `scripts/world/market_drone.gd:44-46`

**Situation:** Jede startende Drohne erhöht `carrier.deck_queue` (Flugdeck) bzw. `hatch_queue` (Luke); dekrementiert
wird nur, wenn sie das Deck verlassen hat bzw. aus der Luke gestiegen ist. Wird eine Drohne vorher per
`stow_all_drones()` (Warp, Sprung, Docken) oder `_lost()` (Treibstoff, Abschuss, Puls – `stunned` greift zwar erst
danach, aber ein Puls während des Rollens ist möglich) entfernt, bleibt der Zähler erhöht – für immer, denn das
`ShipFitting` kennt ihn nicht und `_dock` setzt ihn nicht zurück. Folgen auf der Kanayama-maru: jede weitere Startwelle
wartet `RUNWAY_GAP × deck_queue` länger, und `MarketDrone._runway_free()` verlangt `deck_queue == 0` → Händlerdrohnen
kreisen ewig am Anflugpunkt, der Bordmarkt ist tot. Der Smoke-Test setzt die Zähler von Hand auf 0
(`smoke_test.gd:3404, 3825, 4406`) – das kaschiert das Problem.

**Fix:** In `Drone` ein `_exit_tree()` (oder in `stow_drone`/`stow_all_drones`/`_lost`): `if runway: carrier.deck_queue -= 1`,
`if hatch_launch: carrier.hatch_queue -= 1`. Zusätzlich defensiv in `Ship._dock()` und wenn `view.drones_of(self)` leer
ist, beide Zähler auf 0 setzen. Danach die manuellen Resets im Smoke-Test entfernen, damit er den Fehler fände.

### W3 – Fokuslanze zieht nur den Strom eines einzigen Kristalls
`scripts/world/ship.gd:3041-3050` (`power_in_use`), `scripts/core/ship_fitting.gd:610-625` (`power_plan`),
`:389-421` (`_bundle_focus`), `:250`/`:400` (`powered`)

**Situation:** `_bundle_focus` ersetzt alle Waffen durch eine Lanze mit `slot = ws[0]["slot"]` (= `weapon_0`).
`power_in_use()` setzt beim Feuern nur `u["weapon_0"]` (über `module_on` bzw. `module_timers`); `power_plan()`
iteriert aber über alle `weapon_i` und zählt nur die als „in Benutzung", die in `in_use` stehen. Ergebnis: Eine
Cathedral mit acht Kristallen bezahlt beim Feuern den Strom von einem – das harte Strombudget aus Paket 21 greift bei
Covenant-Schiffen praktisch nicht. Auch der Automodus (`_update_auto_fire`, `:2764-2780`) setzt nur `module_timers[weapon_0]`.
Analog nimmt die Lanze `powered` nur von Kristall 0: Liegt `weapon_3` in einer abgeschalteten Gruppe, feuert die Lanze
trotzdem mit voller Kraft.

**Fix:** In `power_in_use()` nach dem Füllen prüfen: `if fit.stats()["focus_bundle"] > 0 and u.has(weapon_0): für alle
weapon_i u[i] = true`. In `_bundle_focus` `lance["powered"] = alle Kristalle powered` (oder die Lanze auf die Kristalle
begrenzen, die Strom haben, und Schaden entsprechend skalieren). Smoke-Check: `power_plan(power_in_use())["requested"]`
einer feuernden Cathedral muss ≈ Summe der acht Kristall-Leistungen sein (T2).

### W4 – Abdocken über Pads: Schiff ist unsichtbar, aber angreifbar und „nirgends"
`scripts/world/ship.gd:316-330` (`undock`), `:501-516` (`_undock_pad`, Warten mit `pi < 0`), `:230-232` (`is_targetable`)

**Situation:** `undock()` setzt `fit.docked_at = ""` sofort, stellt das Schiff auf die Stationsmitte und `modulate.a = 0`.
Solange kein Pad frei ist (Verkehr landet/startet), wartet es so – `is_docked()` ist false, `is_targetable()` true:
Raider (`raiding`), Hafen-Geschütze und Splash-Schaden treffen ein unsichtbares Schiff; `take_damage` prüft nur
`is_docked()`. Das Stations-UI schließt sich, der Spieler sieht nichts und kann nur warten; `drones_must_return()`
sieht das Schiff als „im Raum". Für Buchten (`_update_undocking`) ist die Phase kurz, für Pads bei vollem Verkehr nicht.

**Fix:** `is_targetable()` (und `take_damage`) zusätzlich `false`, solange `order.type == "undocking"` mit
`modulate.a < 0.5` bzw. `order.pad < 0`. Oder `fit.docked_at` erst leeren, wenn die Luke aufgeht, und bis dahin eine
Aktivität „Wartet auf freien Pad" im Stations-UI anzeigen.

### W5 – Laufzeitzustand auf dem `Ship`-Node geht bei jedem Sprung und beim Laden verloren
`scripts/world/ship.gd:77` (`mine_choice`), `:95` (`module_on`), `:111-112`, `scripts/autoload/commands.gd:340-354`,
`scripts/world/system_view.gd:199-223` (`sync_player` baut den Node neu)

**Situation:** Minenwerfer-Einstellung (Typ, Zünder – Paket 20), eingeschaltete Punktverteidigung, Automodus,
Antidrohnenpuls, Afterburner usw. leben in `Ship.mine_choice` / `Ship.module_on`. Bei jedem Hyperraumsprung, Wurmloch,
Schiffswechsel und beim Laden entsteht ein neuer `Ship`-Node → PD ist aus, Minenwerfer auf „erste Mine im Laderaum",
Zünder 10 s. Refinery/Factory/Market wurden bewusst ins `ShipFitting` verlegt (`refinery_on` …) – die anderen nicht.
`SAVE_FIELDS` ist ansonsten vollständig (priorities, wormhole_ready, drones, drone_role/modes, market_offers alle drin).

**Fix:** `mine_choice` und eine Liste „dauerhaft eingeschalteter" Slots (PD, auto_fire, drone_pulse) ins `ShipFitting`
und in `SAVE_FIELDS` aufnehmen; `Ship.setup()` liest sie ein (wie `_update_modules` es für refinery/factory/market
schon tut, `:2175-2176`). Alte Saves dürfen brechen (Phase 0.5).

### W6 – Wurmloch-Sprung: Drohnen werden nicht eingeholt und starten danach nicht wieder
`scripts/autoload/commands.gd:1082-1086`, `scripts/autoload/game_state.gd:822-838` (`begin_wormhole`),
`scripts/main.gd:122-132` (`_on_jumped_out` → `remove_player`), `scripts/world/drone.gd:98-99`,
Vergleich: `scripts/world/ship.gd:1272-1274` (Torsprung ruft `stow_all_drones(self, true)`)

**Situation:** Beim Torsprung werden die Drohnen vor `begin_jump` eingeholt und über `drone_relaunch` nach der Ankunft
wieder gestartet. `begin_wormhole` wird direkt aus dem Command gerufen, ohne den `Ship`-Node anzufassen: `remove_player()`
gibt den Träger frei, die Drohnen melden „its carrier is gone" (ohne Log, da der Träger ungültig ist). Weil
`sync_player()` alle `rec["out"]` zurücksetzt, „überleben" sie stillschweigend im Hangar – aber ohne `drone_relaunch`,
ohne die Reichweiten-Regel (zu weit entfernte Drohnen gehen beim Torsprung verloren, hier nicht) und ohne Entladen der
Erzfracht (`unload()`). Außerdem prüft `wormhole_error` weder `in_warp()` noch eine laufende Landung.

**Fix:** In `_c_wormhole_jump` vor `begin_wormhole`: `if world.player: world.stow_all_drones(world.player, true)` und
Order/Warp prüfen (`in_warp()`, `docking`), sonst Fehlertext. Smoke-Check T3.

### W7 – NPC-Träger verschwinden mit ausgeflogenen Drohnen → Explosionen am Tor / an der Station
`scripts/world/traffic.gd:158-167` (`_despawn`), `:292-325` (`on_jump`), `:272-288` (`on_docked`),
`:677-680` (Verstärkungen fliegen ab), `scripts/world/drone.gd:98-99`, `:506-515`

**Situation:** Concord-Patrouillen (`npc_drones`) starten ihre Drohnen im Gefecht. Wird der Träger danach
despawnt (Verstärkung mit `leave_at`, Konvoi springt, Patrouille dockt), ruft niemand `recall`/`stow`; die Drohnen
finden ihren Träger ungültig vor und sprengen sich einzeln mit Explosions-FX in die Luft – mitten am Tor oder in der
Station. `npc_count()` zählt Drohnen nicht, also auch keine Kapazitätsfolgen, aber es sieht nach Bug aus.

**Fix:** In `Traffic._despawn()` und `SystemView.npc_jump()` zuerst `for d in view.drones_of(s): d.queue_free()`
(lautlos). Alternativ in `Drone._lost()` keinen Explosions-FX, wenn der Träger nicht `dying`, sondern bereits freigegeben ist.

---

## Kleiner

### K1 – `location_text()` kennt nur `transit_kind == "jump"`
`scripts/core/ship_fitting.gd:663-670` – im Wurmloch-Transit zeigt die Flotte/Hangarliste das Herkunftssystem statt
„Wormhole → Ziel". Fix: `if transit_kind != "": return "%s → %s"`.

### K2 – Tarnung: Schaden enttarnt nicht, im Warp kostet sie nichts, NPC-Werkzeuge laufen getarnt weiter
`scripts/world/ship.gd:1555-1610` (`take_damage` prüft `cloaked()` nicht), `:626-635` (im Warp kein `_update_modules`
→ `_run_active` zieht keine Energie), `:1660-1686` (`_update_tools` ohne `cloaked()`-Check, `_update_weapons` hat ihn).
Minen (`threatens`) und Splash treffen getarnte Schiffe weiter, ohne sie zu enttarnen. Entscheidung: entweder
`decloak("damage")` in `take_damage` oder dokumentieren. Für den Warp: Energieabzug der Tarnung auch im Warp-Zweig.

### K3 – Fabrik/Raffinerie laufen nur auf dem aktiven Schiff im Raum
`scripts/world/ship.gd:597-611` (gedockt: `return` vor `_update_tools`), `:1664-1666` (`_update_modules` nur `manual`).
Gedockt in der Station oder auf einem geparkten Zweitschiff läuft nichts – vermutlich gewollt (Kommentar in
`game_state.gd:920`), sollte aber im Schiffsmenü stehen; sonst wirkt die Warteschlange „eingefroren".

### K4 – Fabrikaufträge eines zerstörten Schiffs bleiben in `GameState.jobs`
`scripts/autoload/game_state.gd:446-466` (`on_player_ship_lost`), `:941-943`. Werden gespeichert und nie abgearbeitet.
Fix: `jobs = jobs.filter(func(j): return j["kind"] != "ship" or int(j["uid"]) != f.uid)`.

### K5 – `ship_value()` zählt Drohnen nicht
`scripts/autoload/game_state.gd:416-421` – Hangarpanel/Nettovermögen unterschätzen Träger um bis zu 27 × 2.400 cr.

### K6 – Marktdrohne und eigene Drohnen teilen sich die Startbahn ohne Sperre
`scripts/world/market_drone.gd:44-46`, `:63-71`; `scripts/world/drone.gd:56-64`. Die Marktdrohne wartet auf
`deck_queue == 0`, erhöht ihn aber selbst nicht – startet der Spieler Drohnen, während sie landet, rollen beide
übereinander. Fix: Marktdrohne in `state in ["final","loading","takeoff"]` `host.deck_queue` belegen (nach W2).

### K7 – Fokuslanze brennt weiter, wenn das Ziel warpt oder sich tarnt
`scripts/world/focus_lance.gd:41-56` – `_valid()` prüft nur `dying`; Treffpunkt und Strahl folgen dem Ziel über die
Karte. Fix: abbrechen bei `target.in_warp()`, `not target.is_targetable()` oder Distanz > 1,5 × Reichweite.

### K8 – `storage_of()` legt beim Lesen leere Lagereinträge an
`scripts/autoload/game_state.gd:500-503`; Aufrufer `scripts/ui/station/outfitter_panel.gd:192, 283, 376`. Jeder
Outfitter-Besuch erzeugt `storage[station_id] = {}` → Save wächst um leere Dicts. Fix: für Lesezugriffe
`storage.get(id, {})`.

### K9 – Outfitter: „too big" für jeden `can_fit`-Fehler
`scripts/ui/station/outfitter_panel.gd:256` („too big for this slot"), `:286` („too big"). Luxussuiten auf
Nicht-Aurelle-Schiffen, Fokuskristalle, Tarn-Emitter werden als „zu groß" beschriftet; der echte Grund steht nur im
Tooltip. Fix: `why` kürzen und anzeigen, oder Kategorie „nicht kompatibel".

### K10 – Debug-Teleport dockt L-Schiffe an Wegstationen
`scripts/autoload/commands.gd:1011-1019` nimmt `L["stations"][0]`; in Systemen ohne reguläre Station ist das die
Wegstation (`universe.gd:987-1011`). Abdocken funktioniert über den Bucht-Fallback (`ship.gd:332-339`), aber das Schiff
„parkt" dann an einer Station, die es nicht aufnehmen darf. Fix: erste Station mit `max_size >= hull.size` wählen.

### K11 – `claim_pad` räumt Leichen nur bei der nächsten Reservierung auf
`scripts/world/celestial.gd:547-551`. Gelbe Lampe und offene Luke bleiben, bis das nächste Schiff kommt; mit W1-Fix
weitgehend erledigt, zusätzlich könnte `_process` (`:302-309`) den Check alle 0,5 s machen.

### K12 – Modulbeschreibungen widersprechen den Daten
`data/module_desc.gd:33` „Unguided rockets" – `w_rocket_s` hat `homing: true` (`data/modules.gd:345`).
`:25` „Combat sensors – … more targets at once" – `max_locks` hängt nur von der Größe ab (`ship_fitting.gd:243`).
`:39` „knocks out all modules with an EMP" – der Ionentorpedo macht nur `cap_drain` (`scripts/world/projectile.gd:105-106`),
kein `apply_emp`. `:83` `o_targeting` verschweigt den `res_bonus`.

### K13 – Zustand „range" wird als „wartet" missbraucht
`scripts/world/ship.gd:2470, 2475, 2503` (Fabrik: Hangar/Laderaum voll; Raffinerie: kein Platz). Modulleiste färbt
das wie „außer Reichweite". Fix: eigener Zustand `"wait"` plus Farbe in der HUD.

### K14 – `_update_npc_cloak` schaltet `module_on` ohne Energieabzug
`scripts/world/ship.gd:2835-2845` – NPC-Parallax tarnt sich 25 s kostenlos; `_run_active` läuft nur für `manual`.
Konsistenz-/Balance-Frage, kein Fehler.

---

## Performance (pro Frame)

### P1 – `power_plan()` für jedes Schiff in jedem Physik-Frame
`scripts/world/ship.gd:613, 3071-3086`; `scripts/core/ship_fitting.gd:610-640`. Pro Slot drei `module_data()`-Lookups
(`module_data`, `priority_of` → `module_data` + `default_priority` → `module_data`), dazu `slot_keys()` und
`builtin_modules()`. Bei 40 Schiffen × ~25 Slots × 60 Hz ≈ 180.000 Dict-Zugriffe/s. Fix: in `_compute` pro Slot
`{power, group, active}` cachen und `power_plan` darüber laufen lassen, oder nur alle 0,2 s bzw. bei Änderung von
`module_on`/`module_timers` rechnen.

### P2 – `drones_of(carrier)` pro Drohne pro Frame
`scripts/world/drone.gd:188` (`_formation`) → `system_view.gd:1353-1358` iteriert alle Kinder des `ship_layer`.
Mit 11 Concordia-Drohnen + Verkehr quadratisch. Fix: wie `followers_of` (`system_view.gd:1482-1500`) pro Frame cachen.

### P3 – `drone_hatches()` baut und sortiert pro Aufruf ein Array
`scripts/world/ship.gd:2539-2545`; Aufrufer `drone.gd:65, 68, 143` (pro Drohne pro Frame beim Rückflug) und
`_draw_stripes` (`:2906, 2941`). Fix: pro Hull cachen (Hatches ändern sich nie).

### P4 – `deck_point()` zählt jedes Mal die Art-Breite
`scripts/world/ship.gd:2979-2988` – Schleife über alle Art-Zeilen, pro Drohne pro Frame (`_take_off`, Rückflug,
Marktdrohne). Fix: wie `smoke_stacks()` (`:2997-3018`) cachen.

### P5 – `hatch_local()` formatiert pro Aufruf einen Cache-Key
`scripts/world/ship.gd:2567-2572` → `PixelArt.ship_texture()` → `"ship_%s_%s_%d" % […]` (String-Allokation) nur für
Breite/Höhe. Fix: Texturgröße einmal in `setup()` merken.

### P6 – Stationen `queue_redraw()` in jedem Frame
`scripts/world/celestial.gd:302-309` – vorbestehend (Paket 6/10), die Pads (`_draw_pads`) kommen obendrauf. Das
Holo-Banner zeichnet den Crest zeilenweise (`:418-420`). Kein Teil-4-Fehler, aber der größte Draw-Posten in Stationsnähe.

---

## Koop-Bereitschaft (Logik, die `Commands` umgeht)

- **`SystemView.steer()`** (`system_view.gd:876-887`, WASD-Flug aus 0.4.19.16) ruft `player.set_order()` direkt. Ein
  `{"type":"move", "pos": …, "keys": true}` über `Commands.execute` wäre eine Zeile – dann ist auch der Tastaturflug
  aufzeichenbar/netzwerkfähig.
- Alles andere Spielerseitige (Concourse, Outfitter inkl. `module_buy_fit`, Drohnenfenster, Prioritäten, Minenkonfig,
  Wurmloch, Bordmarkt-Angebote, Fabrik) läuft korrekt über den Bus. 👍
- Simulationsseitig schreiben `SystemView.market_trade()` (`:1319-1344`, `GameState.add_credits`), `Ship._refine`,
  `_run_factory`, `Drone.unload()` direkt in `GameState`/`fit`. Das ist für Server-Logik in Ordnung, sollte aber in
  Phase 1 klar als „nur auf dem Host" markiert sein – der Hinweis fehlt in den Kommentaren.
- `Commands._c_undock` fällt ohne `world` auf `_fit().docked_at = ""` zurück (`commands.gd:407-411`) – im Netz muss der
  Server das Pad-Warten (W4) selbst simulieren; zusammen mit W4 lösen.

---

## Aufräumen (totes Doppeltes, Lesbarkeit)

- **`ShipFitting.describe()`** (`ship_fitting.gd:804-857`) hat keinen Aufrufer mehr (Schiffsmenü/Hangar haben eigene
  Texte, `ship_menu.gd:595, 806`); nutzt noch das alte Speed-Format ohne Einheit. Löschen.
- **`builtin_modules()`** (`ship_fitting.gd:428-490`): neun fast identische Dict-Literale. Tabelle
  `BUILTIN_DEFS := {"cloak": {"active":"cloak", "src":"cloak", "defaults": {…}}, …}` + eine Schleife.
- **Abdunkel-Formel 4×** (`ship.gd:388, 411, 489, 535`): `Color(lerpf(1,0.45,dark), …)` → `_hangar_shade(dark, alpha)`.
- **`celestial.gd:31`**: Kommentar „colossus completely inside another one's radar shadow" steht an `pad_want`, gehört zu
  `radar_hidden` (`:25`).
- **Smoke-Test setzt `deck_queue`/`hatch_queue` von Hand** (`smoke_test.gd:3404, 3825, 4406`) – nach W2 entfernen.
- `GameData.SIZE_NAMES` (nur 1–3) wird von `describe()` benutzt; mit dessen Löschung prüfen, ob es noch gebraucht wird.
- `outfitter_panel.gd:311-316` baut die Werteliste aus `module_summary()` per `split("\n")` und entfernt Zeilen wieder
  – `module_summary` sollte stattdessen eine Liste liefern (`module_summary_lines()`), dann entfällt das Raten.
- `ship.gd:1272-1274` / `system_view.gd:2174-2176`: Drohnen-Einholen beim Warp und beim Sprung an zwei Stellen; zentral
  in `on_warp_started`/`begin_jump` (hilft auch W6).

---

## Smoke-Test-Lücken (Teil 4)

Vorhanden und gut: Pakete 20–26 und 25a–g haben je einen Testblock, Save-Roundtrip (`from_dict(to_dict())`,
`smoke_test.gd:3559`), Concourse-Spalten und `module_buy_fit` (`:696, 718`), Lanze bündelt (`:4565, 4596`).

Fehlend:
- **T1** Landung per Order abbrechen → `scale == Vector2.ONE`, `modulate == WHITE`, `pad_of(ship) == -1`, `pad_want == 0`.
- **T2** Strombedarf einer feuernden Cathedral `power_plan(power_in_use())["requested"]` ≈ Σ Kristall-Power (W3).
- **T3** Wurmloch mit ausgeflogenen Drohnen → nach Ankunft `drone_relaunch > 0` bzw. Drohnen wieder draußen (W6).
- **T4** `deck_queue`/`hatch_queue` nach `stow_all_drones` während des Rollens == 0 (W2) – ohne manuellen Reset.
- **T5** Abdocken bei allen Pads belegt: `is_targetable()` false, `take_damage` wirkungslos (W4).
- **T6** NPC-Träger `_despawn` mit Drohnen draußen → keine Drohnen-Nodes, kein Explosions-FX (W7).
- **T7** Minenwerfer-Konfig und PD-Zustand nach `load_system()`/Sprung erhalten (W5 – erst nach der Entscheidung).
- **T8** `location_text()` im Wurmloch-Transit (K1).
- **T9** Jeder `ModuleDesc.DESC`-Eintrag hat eine Familie und umgekehrt; Stichproben „homing ⇒ nicht ‚Unguided'" (K12).

---

## Top 5 – zuerst beheben

1. **W2** `deck_queue`/`hatch_queue`-Leck – legt den Kanayama-Bordmarkt dauerhaft lahm und verzögert jede Startwelle;
   Fix ist klein (`Drone._exit_tree`), Smoke-Reset danach entfernen.
2. **W1** Landeanflug durch neue Order unterbrochen – sichtbar geschrumpftes Schiff, Pad bleibt belegt; `set_order`
   um einen `docking`-Zweig ergänzen.
3. **W3** Fokuslanze umgeht das Strombudget – Covenant-Schiffe ignorieren Paket 21; zwei Zeilen in `power_in_use`
   plus `powered` der Lanze.
4. **W5** `mine_choice`/`module_on` ins `ShipFitting` und in `SAVE_FIELDS` – sonst verliert der Spieler bei jedem Sprung
   PD und Minenkonfig (betrifft Pakete 20/21/25d/25f).
5. **W4 + W6** Abdocken über Pads (unsichtbar, aber angreifbar) und Wurmloch ohne Drohnen-Einholen – beides sind
   „Nähte" zwischen `ShipFitting` und `Ship`, am besten zusammen mit einem gemeinsamen „Schiff verlässt den Raum"-Pfad lösen.
