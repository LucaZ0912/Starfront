# Code-Review Teil 6 – New Worlds Discovery Update, Part A + Zwischenteil 6½ (Pakete 35–43, 40a–e, 75)

Stand: alpha 0.6.75.3 (Commit `03f257b`), Review nur lesend – geändert wird erst nach Freigabe durch Luz.

**Umfang:** alles seit Teil 5 (`v0.5.34.4..HEAD`, 128 Dateien, rund 15.100 Zeilen neu): Systemmaßstab und Gürtel (35),
Monde und Umlaufbahnen (36), Sterntypen und CME (37), Planetentypen (38), Spezialsysteme mit Senat, Kurie und
Research Exchange (39a–d), der neue Cluster mit Rand, Fernen Weiten, Toren, Fehlsprüngen, Wracks, Veil, Gefahren und
Festungen (40a–e), Bergbau-Erweiterung (41), Wirtschaft 2.0 (42a–d), Tourismus (43a–c) und der Zwischenteil 6½
(Geschwindigkeitskurve, Plasma Drive, Schub – Paket 75).
**Geprüfte Bereiche:** `universe.gd` (Cluster-Erzeugung, Layout, Umlaufbahnen, Speichern), `game_state.gd` (Sprung,
Ankunft, Fehlsprung, Touren, Wohlstand, Speichern), `system_view.gd` (Ankunft, Gefahren, Garnison, CME, Radar, Wracks,
Bergung), `ship.gd` (Locks, Ziele, Schub, Gas, Tiefenbohrer), `mine.gd`, `traffic.gd` (Touristen, Wahldiebe),
`economy.gd`, `market.gd`, `munitions.gd`, `tourism.gd`, `senate.gd`, `curia.gd`, `industry.gd`, `missions.gd`,
`commands.gd`, `ship_fitting.gd`, `celestial.gd`, `galaxy_map.gd`, `hud.gd`, `main.gd`, `warmup.gd`, `convoy_sim.gd`.
**Smoke-Test:** letzter voller Lauf 0.6.75.3: 805 Prüfungen, 0 Fehler (in dieser Sitzung nicht neu gelaufen).

**Gesamteindruck:** Ein sehr großer Teil, und der Kern hält: Die Cluster-Erzeugung ist durchgehend deterministisch
(eigene RNGs je Schritt, Hash-Entscheidungen für nachträgliche Eigenschaften), die Randfälle (leere Gruppen, keine
Kandidaten) sind abgefangen, Wirtschaft und Markt hängen sauber an Caches, und die in 0.6.75.3 begonnene Prüfung auf
freigegebene Node-Referenzen ist an allen Stellen durchgezogen, die ich gefunden habe (Locks, Relock, Fokus-Ziele,
Auto-Feuer, Garnison, Gefahren, Radar, Marktkäufer, Aggressoren, Killer). Kein Absturz gefunden. Die Funde liegen
wieder an den Nähten – diesmal vor allem beim Speichern (die neuen, dichten Felder vervielfachen den Spielstand) und bei
Dingen, die nach dem Würfeln der Umlaufbahnen nicht mitwandern.

---

## Wichtig

### W1 – Der Spielstand enthält jeden Asteroiden jedes je erzeugten Systems: 3,6 MB nach 17 Minuten, Autosave nach jedem Sprung
`universe.gd` `to_dict()` / `from_dict()`, `warmup.gd` `queue_layouts()`, `main.gd` `_on_arrived_system()`
(`SaveGame.autosave.call_deferred()`), `save_game.gd` `save_game()` (`var_to_str`)

`to_dict()` schreibt für **jedes Layout in `Universe.layouts`** den Bestand **jedes** Asteroiden (`ast[id] = amount`),
unabhängig davon, ob je einer abgebaut wurde. Zwei Dinge aus Teil 6 treiben das hoch: Paket 35 macht die Felder dicht
(`_make_field`: 360–1.500 Brocken je Feld, dazu Mondfelder und Kolossränder → grob 1.000–6.000 Asteroiden je System),
und das Vorladen (`warmup.queue_layouts()`, 42c) erzeugt hinter dem Ladebildschirm die Layouts **aller bewohnten
Systeme** – die liegen damit alle in `layouts` und werden alle gespeichert, besucht oder nicht.
Nachgemessen am aktuellen `autosave.sav`: Spielzeit 1.047 s (17 min), **63 Layouts, 170.522 Feld- und 9.025
Streu-/Kolossrand-Einträge, 3,6 MB** – als Text (`var_to_str`), bei jedem Autosave (nach jedem Sprung) neu geschrieben
und beim Laden Eintrag für Eintrag über `L["asteroids"]` zurückgespielt (`from_dict` sucht je Asteroid im Dictionary –
das ist noch linear, aber 180.000-mal). Mit einer längeren Karriere (alle ~240 Systeme besucht, Felder mehrfach
geschürft) wird daraus eine zweistellige Megabyte-Datei; der Hänger beim Autosave nach dem Sprung wächst mit.
**Vorschlag:** Nur speichern, was vom Erzeugten abweicht: Asteroiden mit `amount != amount0` (bzw. `gone`), Kolosse mit
`amount != amount0` oder geändertem `deep_amount`, Anomalien mit `scan > 0`; Layouts ohne Abweichung ganz weglassen.
`from_dict` bleibt kompatibel (fehlende Einträge = unverändert). Ein Smoke-Check, der nach einem Sprung ohne Bergbau
prüft, dass das `world`-Dictionary klein bleibt, würde einen Rückfall fangen.

### W2 – Feste Wracks (Schlachtfeld, Derelikt) verschwinden samt Restbeute, wenn der Laderaum voll ist – auch die Erdreliquie
`system_view.gd` `complete_salvage()`, `universe.gd` `_derelict()` (Reihenfolge der Beute), `to_dict()` (`salvaged`)

Für Wracks mit `hulk`, `relic` oder `sr_`-Id setzt `complete_salvage()` **immer** `node.data["salvaged"] = true` und
gibt den Node frei – auch wenn `add_cargo` nur einen Teil (oder nichts) aufnehmen konnte. Die Restbeute wird zwar noch
in `node.data["loot"]` zurückgeschrieben, aber das Wrack ist weg und kommt wegen `salvaged` nie wieder (so wird es auch
gespeichert). Bei einem Derelikt ist das Haupt-Wrack mit `old_tech 3–6, research_data 4–8, salvage 15–25` beladen,
die **Erdreliquie steht als letzter Eintrag im Beute-Dictionary** – genau sie fällt bei einem fast vollen Laderaum als
Erstes weg. Das trifft den Reliquien-Auftrag der Kurie und die Segnung (Paket 39b): „nothing (cargo hold full)“ im Log,
die Reliquie ist für diese Partie verloren. Bei gewöhnlichen Wracks war das schon vorher so, dort kommt aber ständig
Nachschub; die festen Fundstellen sind einmalig.
**Vorschlag:** Ein festes Wrack erst dann als `salvaged` markieren und freigeben, wenn `loot` leer ist (alle Werte ≤ 0);
sonst stehen lassen und `salvage` auf 0 zurücksetzen, damit man es nach dem Umladen noch einmal bergen kann. Zusätzlich
die Reliquie als ersten Eintrag ins Beute-Dictionary legen (`_derelict`) oder in `complete_salvage` Gegenstände mit
Auftragsbezug zuerst aufnehmen.

---

## Mittel

### M1 – Strahlungszone über einem Mondfeld steht am falschen Ort (das Feld wandert mit dem Mond, die Zone nicht)
`universe.gd` `_hazards()` (Zeilen `pos = f["pos"]`, `field = f["id"]`), `_moon_fields()`, `_place_orbits()` (Liste
`["fields", "asteroids", "debris", "structures"]`), `roll_orbits()`

`_hazards()` legt eine Strahlungszone zu 60 % „über ein Feld“ und wählt dabei aus **allen** `L["fields"]` – also auch
aus den Mondfeldern (`_moon_fields` hängt sie mit `"moon"`/`"anchor"` ebenfalls in `L["fields"]`). Zu diesem Zeitpunkt
steht ein Mond noch auf der Startposition seines Planeten (`_make_moons`: `"pos": p["pos"]`); erst `_place_orbits()` –
das **nach** `_hazards()` läuft – setzt Planet, Mond und alles mit `anchor` auf die Umlaufbahn. Gefahren stehen nicht in
der Liste der mitbewegten Schlüssel. Ergebnis: Das Mondfeld (und seine Asteroiden, die `purity_grade = high` und ×1,3
bekommen haben) liegt beim Mond, die Strahlungszone irgendwo auf der alten Planetenbahn im Leeren – und bei jedem
Einspringen (`roll_orbits`) wandert das Feld erneut, die Zone bleibt. Der HUD-Text „Ore inside is purer“ stimmt dann
für ein Feld, das gar nicht in der Zone liegt. Im Rand (25–35 % Strahlungs-Chance, 25 % der Monde mit Feld) kommt das
regelmäßig vor.
**Vorschlag:** In `_hazards()` nur Felder ohne `"moon"` zulassen – oder der Gefahr `anchor = f["anchor"]` mitgeben und
`"hazards"` in `_place_orbits()` in die Liste der mitbewegten Schlüssel aufnehmen (dann auch den Celestial-Node beim
Neuaufbau an `hz["pos"]` setzen, was `_spawn_hazards` ohnehin tut).

### M2 – Ein koronaler Massenausbruch sprengt das ganze alte Minenfeld
`system_view.gd` `_update_cme()` (Schleife über `get_nodes_in_group("mines")` → `m.explode.call_deferred()`),
`mine.gd` `setup_old()` (`add_to_group("mines")`, `life = 1e12`)

Die Schockwelle lässt jede Mine detonieren, die sie überrollt – das war für gelegte Minen gedacht (0.6.37.2). Die
alten Minen von Paket 40d stehen in derselben Gruppe und haben keine Ausnahme: Beim ersten CME ist das Minenfeld weg
(bis zum nächsten Systemaufbau, denn `_spawn_hazards` legt es aus dem Layout neu). Mit einem M-Stern (CME alle 3–7
Minuten, `cme_rate`) überlebt ein Minenfeld im Rand selten länger als die erste Viertelstunde – „ein Hindernis, das
nicht ausgeht“ (Kommentar in `setup_old`) ist es dann nicht. Vielleicht so gewollt (die Explosionskette ist ein
Schauspiel); falls nicht:
**Vorschlag:** In `_update_cme()` Minen mit `faction == "derelict"` überspringen (oder nur die auslösen, die ohnehin
im Umkreis eines Schiffs liegen).

### M3 – Ein Fehlsprung heilt ein schwer beschädigtes Schiff auf 25 % Struktur
`game_state.gd` `_misjump()`: `f.structure = maxf(f.structure - (dmg - a), float(s["structure_max"]) * 0.25)`

Das „nie tödlich“ ist als Untergrenze gebaut – aber `maxf` hebt ein Schiff, das mit 5 % Struktur durch ein altes Tor
springt, auf 25 % **an**. Wer angeschlagen im Rand hängt, springt mit dem Debug-Fehlsprung oder einfach oft genug durch
alte Tore und wird dabei repariert.
**Vorschlag:** `f.structure = maxf(f.structure - (dmg - a), minf(f.structure, float(s["structure_max"]) * 0.25))` –
der Schaden wird gekappt, aber nie negativ.

### M4 – Planeten und Monde kennen beim Würfeln der Bahn weder Wrackfelder noch Gefahren
`universe.gd` `_place_orbits()` (`keep_off`: Tore, Felder ohne Mond, Havens, Stationen ohne Anker), `_wreck_sites()`,
`_hazards()`, `_free_spot()`

Schlachtfelder, Derelikte, Strahlungszonen und Minenfelder werden mit `_free_spot(used)` platziert – `used` enthält die
**Startpositionen** der Planeten, nicht die späteren. `_place_orbits()` setzt den Planeten danach auf einen neuen Winkel
seiner Bahn und weicht dabei nur Toren, Feldern, Havens und freien Stationen aus. Ein Gasriese (Radius 30.000 km plus
Monde bis ~100.000 km Reichweite) kann so auf ein Schlachtfeld (Radius 3.800 km) oder in eine Strahlungszone fallen;
und weil `roll_orbits` bei jedem Einspringen neu würfelt, passiert das nicht nur bei der Erzeugung. Wie oft das
tatsächlich eintritt, habe ich nicht gemessen (bei 3–6 Planeten je System und mehreren Fundstellen im Rand halte ich
es für gelegentlich sichtbar: ein Derelikt „im“ Planeten, ein Minenfeld unter einem Mond).
**Vorschlag:** `L.get("sites", [])` und die nicht an ein Feld gebundenen Gefahren (`hz_rad` ohne `field`, `hz_ion`,
`hz_mines`) mit ihrem Radius in `keep_off` aufnehmen (Anomalien gleich mit – das war schon vorher offen).

---

## Klein

- **K1 – `misjumps` und `pending_arrival` überleben Neustart und Laden.** `new_game()` und `from_dict()` leeren beide
  nicht (`debug_misjump` auch nicht). Wird während eines laufenden Sprungs mit gewürfeltem Fehlsprung schnell geladen,
  erbt das Schiff mit derselben `uid` im geladenen Stand den Fehlsprung (umgekehrt geht ein gewürfelter Fehlsprung
  beim Speichern im Sprung verloren – das ist harmlos). *Vorschlag:* beide in `new_game()`/`from_dict()` leeren.
- **K2 – Schub-Fehltext steht verkehrt.** `ship.gd` `boost_error()` liefert für `in_warp()` / Warp-, Dock-Orders
  „Not in warp.“ – genau das Gegenteil; `main.gd` loggt den Text bei Shift im Warp. *Vorschlag:* „Not while warping
  or docking.“
- **K3 – Garnison, die flieht, hält die Festung ewig.** `_spawn_hazards()` nimmt `ArchData.pick(0.0)` – darunter
  Feiglinge, die bei `COWARD_FLEE` per `_try_escape_warp()` an ein Feld oder eine Anomalie warpen und dort ein neues
  `home` bekommen. Sie bleiben in `_garrison`, `_garrison_lost()` findet also immer noch Lebende; die Festung bricht
  nicht, bis der Spieler sie quer durchs System jagt (die Meldung sagt ihm nicht, wo). *Unsicher*, ob die Archetyp-
  Tabelle bei Sicherheit 0 Feiglinge liefert. *Vorschlag:* Garnison ohne Feigling würfeln oder eine geflohene Garnison
  nach ~60 s als „verschollen“ aus `_garnison` streichen.
- **K4 – Ablauf des Wahlurnen-Auftrags räumt fremde `sealed_cargo` ab.** `_update_faction_jobs()` ruft bei
  abgelaufenem Ballot-Auftrag `cf.remove_cargo("sealed_cargo", amount)` auf dem **aktiven** Schiff – dieselbe Ware
  nutzen gewöhnliche Kuriere und der Kristalltransport (39b). Läuft die Urne ab, fehlen danach dem anderen Auftrag die
  Kisten und er lässt sich nicht abgeben (`can_turn_in` prüft den Bestand). Dasselbe Muster steckt schon in
  `abandon_mission`/`fail_mission`; neu ist nur der automatische Ablauf. *Vorschlag:* je Auftrag eine eigene Ware-Id
  (`sealed_cargo:<mission id>` oder Marker im Auftrag) oder beim Ablauf nur entfernen, was über den Bedarf der übrigen
  Kurieraufträge hinausgeht.
- **K5 – `Market.sync()` schreibt eine Tabelle, die niemand mehr liest.** `docked_station()` synchronisiert einmal je
  Station, `_c_market_buy/_sell` nach jedem Handel – `station["market"]` wird aber in keinem Skript mehr gelesen
  (nur `has("market")` als Markierung). Je Handel rechnet `sync` für alle ~150 Waren Kauf- und Verkaufspreis. Harmlos,
  aber tote Arbeit. *Vorschlag:* `sync` und `_mk_synced` entfernen (oder dokumentieren, wofür die Tabelle noch da ist).
- **K6 – Ankunfts-Timer gehört dem SceneTree, nicht der View.** `play_arrival()` nutzt `get_tree().create_timer(0.75)`
  mit `_arrival_now.bind(a)`. Wird die View in diesen 0,75 s neu gebaut (Schnellladen, Debug-Teleport direkt nach der
  Ankunft), ruft der Timer eine Methode auf einer freigegebenen Instanz – in Godot 4 eine Fehlermeldung, kein Absturz.
  *Unsicher*, ob es praktisch vorkommt. *Vorschlag:* Timer als Kind der View (`Timer`-Node) oder in `_arrival_now`
  `is_inside_tree()` prüfen.

---

## Geprüft und in Ordnung

**Nähte:** `begin_jump` → `_arrive` → `pending_arrival` → `main._on_arrived_system` → `play_arrival` (Reihenfolge
Laden der View, dann Ankunfts-Animation, dann Autosave) · Fehlsprung-Spots aus dem **aktuellen** Layout (Umlaufbahnen
werden vorher gewürfelt) · `_may_roll_orbits` (kein Würfeln, solange ein eigenes Schiff im System schwebt) · Andocken
leert Locks, Drohnen, Zähler · Tod (`on_ship_destroyed`) mit freigegebenem Killer, Garnison, Wingmen, Plattform ·
Laden stellt Wohlstand, Marktbestände, Festungen, Senat, Kurie, Permits, Forschungsdaten wieder her; ältere Stände
ohne diese Felder bekommen Standardwerte; `GALAXY_VERSION` 10 schickt alte Cluster durch `migrate_to_current_cluster`.
**Cluster-Erzeugung:** eigene RNGs je Schritt (`_plan_settlements`, `_name_systems`, `_plan_fortresses`,
`_wreck_sites`, `_veil_rifts`, `_hazards`, `_add_fortress`, `_add_resort`), Hash-Entscheidungen für Reinheit, Tiefenerz,
exotische Anomalien · `_assign_territory`: Directorate-Enklave (Ersatzkandidat, wenn die Hauptstadt zu viele Routen
hat), Hauptstadt-Ring, Grenzausgleich mit `guard`, Reste zu Nachbarn, umstrittene Systeme nur zwischen Assembly und
Covenant · `_plan_fortresses`/`_plan_settlements` bei leeren Gruppen (`continue`) · `_build_routes` mit Spannbäumen je
Teil, `_closest_pair`-Rückgaben geprüft · `_mark_veil` · `_place_makers` meidet Heimat, Hauptstädte, Piraten · Namen ohne
Dubletten · Laufzeit: Vorladen aller bewohnten Layouts hinter dem Ladebildschirm, danach alles aus Caches.
**Wirtschaft:** `Economy.of`/`base_prosperity` je Seed gecacht, `drift` räumt zurückgekehrte Systeme aus `prosperity` ·
`Market.info` je Station/Stufe/Seed gecacht, Bestände nur für gehandelte Waren (`market_stock`), Kauf begrenzt auf
Bestand, Laderaum und Credits, Preise aus dem Mittel der Menge – kein Hin-und-her-Gewinn durch den Spread ·
Munitionsdepot nach Wirtschaft · Senat (Bestechung, Gesetze mit Ablauf) und Kurie (Edikte, Zehnt, Ablass, Reliquien)
speichern vollständig · Konvois nehmen Waren aus den Marktrollen.
**Neue Systeme:** Gasernte (Band, Tiefe, Sturm, Hitze gegen `heat_resist`, Abschalten bei vollem Tank) · Tiefenbohrer
nur an Kolossen mit `deep_amount` · Reinheit, Strahlungsfracht (`rad_split`, Banner und Alarm) · Gefahren-Tick alle
0,5 s mit `rad_ward`/`ion_ward`, alte Minen prüfen Schiffe nur 5× pro Sekunde · Festung: Kopfgeld-Bond nur, wenn der
Spieler beteiligt war, `fortress_broken` gespeichert, Geschütze schweigen · Touren (`_update_tours`) nur im Zielsystem,
außerhalb des Warps, nicht angedockt; Touristenverkehr räumt tote Schiffe auf · Wahldiebe einmal je System · Schub
(Spieler und NPC, Energie, Abkühlung, HUD) · Geschwindigkeitskurve (Wurzel aus Schub/Masse, warp_speed).
**Freigegebene Objekte:** `locked_node`, `_update_locks`, `_update_relock`, `_focus` (`_valid`), `auto_targets`,
`wing_focus`, `last_attacker`, `_garrison`, `hazard_nodes`, `_radar_cands`, `market_buyers`, `_aggro`, `raid_live["st"]`,
Killer/Angreifer in `take_damage`, `on_ship_destroyed`, `on_ship_attacked` – überall `is_instance_valid` vor dem Zugriff.
**Leistung:** Radar sammelt Kandidaten alle 0,25 s, Asteroiden-Culling alle 0,2 s mit Pixelgrenze, Dunst als gecachte
Textur, Gefahren und Fundstellen zeichnen nur auf dem Bildschirm, Galaxiekarte (Zoom/Pan, Übersicht, Veil-Shader) liest
nur Caches; keine neue Schleife pro Frame über alle Systeme oder Asteroiden gefunden.

## Vorschlag Reihenfolge

W1 und W2 zuerst (Spielstand-Größe, verlorene Reliquien), dann M1–M4 und K1–K6 zusammen in einem Fix-Update
(0.6.75.4) – danach ein voller Smoke-Test und ein Blick auf die Größe von `autosave.sav` nach ein paar Sprüngen.

---

## Alle Befunde

| Nr. | Schwere | Datei / Funktion | Kurz |
|---|---|---|---|
| W1 | Wichtig | `universe.gd` `to_dict`, `warmup.gd` `queue_layouts` | Spielstand speichert jeden Asteroiden aller vorgeladenen Systeme – 3,6 MB nach 17 min, Autosave je Sprung |
| W2 | Wichtig | `system_view.gd` `complete_salvage` | Feste Wracks gelten als geborgen, auch wenn der Laderaum voll war – Restbeute (Erdreliquie) weg |
| M1 | Mittel | `universe.gd` `_hazards`, `_place_orbits` | Strahlungszone über Mondfeld steht nach dem Würfeln der Bahnen im Leeren |
| M2 | Mittel | `system_view.gd` `_update_cme`, `mine.gd` `setup_old` | CME sprengt das ganze alte Minenfeld |
| M3 | Mittel | `game_state.gd` `_misjump` | Fehlsprung hebt Struktur auf 25 % an statt sie zu kappen |
| M4 | Mittel | `universe.gd` `_place_orbits` | Planeten/Monde weichen Wrackfeldern und Gefahren nicht aus |
| K1 | Klein | `game_state.gd` `new_game`/`from_dict` | `misjumps`, `pending_arrival`, `debug_misjump` nicht geleert |
| K2 | Klein | `ship.gd` `boost_error` | Text „Not in warp.“ verkehrt |
| K3 | Klein | `system_view.gd` `_spawn_hazards`/`_garrison_lost` | Geflohene Garnison hält die Festung (unsicher) |
| K4 | Klein | `game_state.gd` `_update_faction_jobs` | Ablauf der Wahlurnen nimmt `sealed_cargo` anderer Aufträge mit |
| K5 | Klein | `commands.gd` `docked_station`, `market.gd` `sync` | Preistabelle `station["market"]` wird geschrieben, aber nirgends gelesen |
| K6 | Klein | `system_view.gd` `play_arrival` | Ankunfts-Timer am SceneTree kann auf freigegebene View treffen (unsicher) |
