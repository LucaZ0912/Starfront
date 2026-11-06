# Sternenfront – Roadmap

Nov 3, 2026 · @Luz

## Vision

Sternenfront ist ein Einzelspieler-Spiel mit zuschaltbarem Koop – wie Valheim oder Deep Rock Galactic im Weltraum, kein MMO.

- **Solo zuerst:** Jede Funktion ist allein voll spielbar. Intern ist das Solospiel ein lokaler Server mit einem Spieler.
- **Koop zuschalten:** Im Pausenmenü "Open to friends" – das eigene Spiel wird zum Host, Freunde treten der Welt bei und fliegen mit eigenem Schiff mit. Online und im LAN.
- **Die Welt gehört dem Host:** Gast-Piloten werden im Spielstand des Hosts mitgespeichert. Kein eigener Server, keine Konten.
- **Schwierigkeit skaliert:** mehr und stärkere Piraten pro Spieler, Bosse mit mehr Leben und Phasen, Beute für jeden Spieler einzeln.
- **PvP optional:** nur zwischen Spielern derselben Session, nur wenn der Host es erlaubt (z. B. in unsicheren Systemen oder als Duell).
- **Geteilter Bildschirm:** spätere, optionale Stufe mit Gamepad für den zweiten Spieler.
- **Endgame:** Trägerschiffe mit Fightern, Drohnen, Langstrecken- und Nuklearraketen, Raketenabwehr, Bossgegner.
- Sprache des Spiels: Englisch, Sternsystem-Namen bleiben deutsch.

## Aktueller Stand

Das Spiel ist ein umfangreicher Einzelspieler-Prototyp in Godot 4.3. Phase 0 und Phase 0.5 Teil 1 bis 3 sind abgeschlossen; Teil 4 (Module and Internal Ship Parts Rework) läuft – Pakete 19 bis 24 fertig, Pakete 25a (KHI-Bergbauschiffe), 25b (Kanayama-maru), 25c (Maison Aurelle), 25d (Hadrian Dynamics) und 25e (Concord Fleetworks) fertig, als Nächstes 25f (Forge of Return). Netzwerk fehlt noch. Teile 5–7 sind geplant (aus dem Roadmap-Entwurf übernommen), Phase 1 und 2 getauscht (erst Story & Endgame, dann Koop). Version alpha 0.4.25.28. Stand 5. November 2026.

| Bereich | Stand |
| --- | --- |
| Welt | Sternencluster mit 48 Systemen in realistischer Größe, Live-Warp, Hyperraum-Sprünge über Tore. Drei Mächte und zwei Piratenfraktionen kontrollieren Gebiete (Sicherheit nach Territorium, umkämpfte Grenzsysteme, Wappen und Holo-Banner). Drei Asteroidenklassen mit 18 Erzen, Asteroiden in vielen Größen und Formen, Colossi mit Radarschatten, lose Gesteinsbrocken. Debug-Testsystem mit allen Inhalten. |
| Ansicht | Feste Zoomstufen Combat, Recon (Radar), System |
| Schiffe | Ein aktives Schiff pro Pilot, Hangar wie EVE, Module in Kern-, Waffen-, Werkzeug- und Optional-Slots (Slotzahl aller Rümpfe erhöht). Scanner (Survey, Prospector, Warrant), Ice Harvester, Strip Miner, Ore Hold, Mining-Upgrades, aktive Ausrüstung. Warp Interdictor. |
| Kampf | Aktive Steuerung wie in EVE: Ziele aufschalten, Module über Kachelleiste oder Tasten 1–9, Schadenszahlen, Deckung hinter Colossi, Nicht-Feuer-Zonen mit Stationsverteidigung. Waffen wirken auf jedes Schiff – Angriffe auf nicht feindliche Schiffe kosten Ruf. |
| Ruf | Ruf pro Fraktion (−100 bis +100, fünf Stufen) aus Bonds, Aufträgen, Angriffen und Abschüssen; wirkt auf Andockerlaubnis, Preise, Patrouillen (angreifen, scannen, ignorieren), Aufträge, Militär-Module und Piraten (lassen Freunde in Ruhe, Pirate Havens andockbar). Reiter „Standing“ im Schiffsmenü. |
| Stationen | Modulare Pixel-Art-Stationen in 8 Typen und 3 Stufen (jede Kombination kommt im Cluster vor), Andocken in Hangarbuchten, Pirate Havens (mit Piraten-Ruf andockbar: Schwarzmarkt, Ausrüster). Concourse mit 10 Services, jeder im Monopol einer Firma. |
| NPCs & Verkehr | Bevölkerung je System aus den Planeten; Shuttles, Bergbauschiffe, Patrouillen in Fraktionsfarben, wartende Frachter, Feld-Patrouillen, Torwachen; Handelskonvois mit echten Routen über den ganzen Cluster; zeitversetztes Erscheinen außerhalb der Sicht; Contacts-Liste; Warp Interdictor mit Timing-Minispiel. |
| Wirtschaft | Märkte nach Stationstyp, Raffinerie nach Asteroidenklasse, Fertigung, Aufträge am Schwarzen Brett, Kopfgelder als Bonds. Sternenkarte zeigt die Wirtschaften aller Systeme. |
| Menüs | Startmenü (mit Testsystem im Debug-Modus), Pausenmenü, Schiffsmenü (Info, Modules, Ship, Inventory, Transactions, Standing), Debug-Menü (F12, inkl. Ruf-Regler), frei belegbare Steuerung. |
| Spielstände | Benannte Spielstände, Autosave, F5/F9. Alte Spielstände werden automatisch in den neuen Cluster umgezogen. |
| Recht | Kopfgelder setzen die drei Mächte aus (Covenant zahlt mehr, Assembly weniger); Bonds werden an jeder Station des Ausstellers eingelöst. Strafregister pro Macht: Suspect, Wanted, Most Wanted – Patrouillen jagen, keine Aufträge, kein Andocken; Punkte verfallen oder Strafe zahlen. |
| Piraten | Sechs Archetypen mit eigener KI und Ausrüstung (Raider, Brawler, Sniper, Ambusher, Leech mit neuen Ionenwaffen, Coward); Warrant Scanner zeigt den Typ. |
| Berüchtigte | Fünf benannte Piratenkapitäne (1–5 Sterne) mit eigener Lackierung, Eigenschaft und wachsender Eskorte ziehen durch den Cluster (nie in die Heimatsysteme); Kopfgeld steigt mit der Zeit, 5-Stern-Kapitäne überfallen Stationen; Steckbriefe am Bond Office, ☠ auf der Galaxiekarte, besondere Beute, Nachfolger. |
| Welt & News | Notrufe, fliehender Verkehr, Eskalation (Patrouille → Verstärkung → Einsatzgruppe), Wracks für alle Schiffe; Nachrichten-Ticker im Schiffs-Panel, Archiv in jeder Station, Kopfgeld-Kampagnen. |
| Fraktionsaufträge | Am Schwarzen Brett jeder Regierungsstation: Konvoi-Eskorte, Patrouille begleiten, Schmuggler abfangen (ab Neutral), Jagd auf Berüchtigte (ab Friendly); +4 Ruf. |
| Module | Neues Modulsystem: Familie + Größe (1–10, Waffen 1–4) + Qualität (F–A); jeder Schiffsplatz mit eigener Maximalgröße; ca. 1.900 Module aus 61 Familien. Skiff, Longhaul und Carrion Crow kaufbar. Paket 20: Schild-Varianten mit Downtime nach dem Zusammenbruch, Punktverteidigung, Schildtransfer, Frachtscanner, Sonnen-Sammler, Minenwerfer mit vier Minenarten (Ware), Radarstörer (auch bei Piraten). |
| Studio-Intro | Beim Start: das animierte „d“ von dlirius games auf Schwarz (aus `dlirius/games.gif`), ein leises „Zapp“ je Farbbalken (ab 0.4.25.6, vorher ein lauterer Laser), danach „dlirius games“ in Silber mit zwei Klammern darüber; ein Mausklick lässt die Klammern mit einem Hammerschlag um das d zusammenfahren, eine Taste überspringt das Intro (alpha 0.4.25.5). Bleibt zentriert, wenn das Fenster vergrößert wird (0.4.25.15). |
| Codex | Nachschlagewerk mit 45 Einträgen in sechs Kategorien; Grundlagen offen, der Rest wird beim Entdecken freigeschaltet („New Codex entry“ im HUD); im Schiffsmenü und im Hauptmenü. |
| Fehlt | Teile 4–9, Story und Endgame-Inhalte (Phase 1), Netzwerk (Phase 2) |

Die Spiellogik für Bewegung und Kampf steckt noch in den Schiff-Objekten der Darstellung; die Trennung erfolgt mit dem Netzwerk-Umbau in Phase 2.

## Arbeitsweise & Übergabe (Claude Code)

Ab jetzt wird direkt im Projektordner mit Claude Code gearbeitet. Hinweise für jede neue Sitzung:

- **Projekt:** `C:\Users\Luca\OneDrive\Dokumente\My Games\Sternfeld5.0` – Godot 4.3, GDScript, UI komplett im Code gebaut. Spieltexte englisch, Systemnamen deutsch, Antworten an Luz auf Deutsch.
- **Roadmap:** liegt als `Roadmap.md` im Projektordner und wird dort gepflegt.
- **Godot:** `C:\Users\Luca\Desktop\Godot_v4.3-stable_mono_win64\Godot_v4.3-stable_mono_win64_console.exe` (nicht im PATH).
- **Test:** Smoke-Test mit `godot --headless --path . -- --smoketest` (gut 360 Prüfungen, Ziel: „DONE – failures: 0“). Neue Pakete bekommen eigene Prüfungen in `scripts/debug/smoke_test.gd`. Ohne `--headless` und mit `-- --smoketest --shots` speichert der Test Screenshots neuer Oberflächen nach `Claude outputs/`.
- **Neue Skripte:** in Autoloads und SystemView per `preload("res://…")` einbinden statt über `class_name` – sonst schwarzer Bildschirm, solange der Editor die Klassen nicht neu eingelesen hat.
- **Godot-Editor:** Vor dem Starten geänderte Dateien neu laden („Discard local changes and reload“), sonst schreibt der Editor alte Fassungen zurück.
- **Saves:** Galaxie wird aus dem Seed erzeugt, gespeichert werden nur Änderungen (`Universe.GALAXY_VERSION` = 3; ältere Saves werden umgezogen). Konvois werden nicht gespeichert.
- **Kompatibilität alter Spielstände (Grundsatz für Phase 0.5):** Wir sind in einer frühen Alpha – alte Spielstände müssen **nicht** ladbar bleiben, ein Neuanfang ist in Ordnung. Neue Mechaniken und Umbauten werden **nie** dadurch eingeschränkt, dass alte Spielstände nicht mehr passen. Ein Spielstand-Umzug wird nur gebaut, wenn er nebenbei und ohne Kompromisse geht; sonst erhöhen wir die Version und alte Stände werden mit einem klaren Hinweis abgelehnt.
- **Dokument:** Fertige Pakete hier abhaken, „Aktueller Stand“ nachziehen; die README im Projekt beschreibt alle Systeme.
- **Debug-Funktionen (Grundsatz):** Jedes Paket bringt passende Debug-Funktionen mit (Debug-Menü F12, nur bei aktivem Debug-Modus), damit Luz jede neue Mechanik ohne langes Spielen gezielt testen kann: Zustände direkt setzen, Fortschritt überspringen, Inhalte spawnen, Werte einsehen. **Ein Paket gilt erst als fertig, wenn seine Debug-Funktionen da sind.**
- **Erst ein fertiges Einzelspielerspiel, Koop zum Schluss (Grundsatz):** Ziel ist zuerst ein vollständiges, gut funktionierendes Einzelspielerspiel; Koop ist die Kirsche auf der Torte und kommt am Ende (Phase 2). Trotzdem wird alles von Anfang an koop-tauglich gebaut, damit es später ohne Neubau mehrspielerfähig wird:
  - Spielzustand (Positionen, Werte, Inventar, Fortschritt) liegt in Daten, nicht nur in Darstellungs-Objekten.
  - Alles, was den Zustand verändert, läuft über die Befehlsschicht (`Commands.execute`) – so kann später ein Host Befehle von Gästen annehmen.
  - Alles gehört klar einem Besitzer: Spieler (Pilot, Crew, Söldner, Schiffe, Bonds, Ruf) oder Welt (Systeme, NPCs, Märkte).
  - Zufall und Simulation so, dass ein Host sie allein entscheidet und an Gäste weitergibt.
  - Die Benutzeroberfläche zeigt nur an und schickt Befehle – sie ändert selbst keinen Spielzustand.
- **Alpha bis zum Ende von Phase 2:** Mechaniken werden gebaut, wenn sie ins Projekt passen – auch wenn die Story sie erst später einsetzt (z. B. Veil-Erkundung vor dem Story-Intro). Ob etwas vor der Story „verraten“ wird, spielt in der Alpha keine Rolle.
- **Roadmap-Entwurf:** `Roadmap_Entwurf.md` pflegen Luz und Claude (Chat) für kommende Teile; Claude Code ändert sie nicht (steht in `.gitignore`) und übernimmt Abschnitte nur auf Zuruf in diese Roadmap.
- **Versionierung (Git):** Version **alpha Phase.Teil.Paket.laufende Nummer** – z. B. `0.3.18.8` = Phase 0(.5), Teil 3, Paket 18, achtes Update darin. Steht in `project.godot` (`config/version`), im Hauptmenü unten links und in `CHANGELOG.md`. **Jedes Update** bekommt: neue Nummer (laufende Nummer +1; **die laufende Nummer gilt pro Paket**: beginnt ein neues Paket, steigt die Paketnummer und die laufende Nummer startet wieder bei 1 – z. B. Paket 20 beginnt mit `0.4.20.1`; Änderungen und Fehlerbehebungen, auch an älteren Mechaniken, zählen die laufende Nummer des aktuellen Pakets hoch, bis das nächste Paket beginnt), Changelog-Eintrag, einen Commit „alpha <Version> – <Kurzbeschreibung>“ und einen Tag `v<Version>` und wird nach GitHub hochgeladen (`git push --follow-tags`, Repository [LucaZ0912/Starfront](https://github.com/LucaZ0912/Starfront), privat). `.godot/` wird nicht versioniert.

## Roadmap

&#91;embedded content: Roadmap · 8 Phasen mit Abnahmekriterium\]

**Neue Reihenfolge der Phasen (entschieden, 5. Nov 2026):** Weil zuerst ein vollständiges Einzelspielerspiel entstehen soll und Koop zum Schluss kommt, **tauschen Phase 1 und Phase 2**:

| Phase | Inhalt |
| --- | --- |
| 0 | Fundament (✅ erledigt) |
| 0.5 | Content & Design (Teile 1–9, siehe unten) |
| **1** | **Story-Ausbau und vollständiger Endgame-Aufbau** (bisher Phase 2) |
| **2** | **Netzwerk-Architektur / Koop** (bisher Phase 1) |

Bis zum Netzwerk-Umbau wird jede Mechanik nach dem Grundsatz „koop-tauglich bauen“ entworfen (siehe Arbeitsweise), damit Phase 2 möglichst wenig umbauen muss. Ab Phase 2 ist das Solospiel ein lokaler Host ohne Gäste – deshalb bleibt das Spiel in jeder Phase allein spielbar, und Koop ist nur ein Schalter im Pausenmenü.

## Phase 0 im Detail

Phase 0 bringt Startmenü, Speichern/Laden und eine Befehlsschicht – alles sofort im Einzelspieler nützlich und die Grundlage für den Server.

**Stand 3. Nov 2026: umgesetzt und getestet** – 75 automatische Prüfungen bestanden (inkl. Debug-Menü), inklusive Speichern → Neustart → Laden. Offen bleibt nur die vollständige Trennung von Simulation und Darstellung; sie wandert in Phase 2 (Netzwerk).

### Startmenü

- [x] Titelbildschirm mit animiertem Sternenhintergrund und Logo
- [x] New Game: Pilotname eingeben, Galaxie-Seed
- [x] Continue: lädt den letzten Spielstand
- [x] Load Game: Liste der Spielstände mit Pilot, Credits, Schiff, Ort, Spielzeit
- [x] Settings: Lautstärke (Platzhalter), Vollbild, Autosave an/aus
- [x] Quit
- [x] Pausenmenü im Spiel (Esc): Resume, Save, Load, Settings, Main Menu

### Speichern und Laden

- [x] Spielstand im Godot-Textformat (versioniert) in `user://saves/`, ein Slot pro Datei
- [x] Galaxie wird nicht gespeichert, sondern aus dem Seed neu erzeugt; gespeichert werden nur Änderungen
- [x] Inhalt: Pilot, Credits, Statistik, Flotte mit Modulen, Ladung, Positionen, Lager pro Station, Aufträge, Asteroiden-Vorkommen, Anomalie-Fortschritt
- [x] Versionsnummer im Spielstand, damit spätere Updates alte Stände umwandeln können
- [x] Autosave beim Andocken und bei Sprung-Ankunft, plus Schnellspeichern (F5 / F9)
- [x] Jede Klasse bekommt `to_dict()` und `from_dict()` – genau dieses Format nutzt später auch der Server

### Befehlsschicht

- [x] Jede Spieleraktion ist ein Befehl – 24 Stück, u. a. `move`, `goto`, `attack`, `course`, `undock`, `market_buy`, `fit_module`, `refine`, `build`, `mission_accept`
- [x] Der Befehlsbus `Commands` prüft und führt Befehle aus; Befehle enthalten nur IDs, Zahlen und Texte, UI und Klicks schicken nur noch Befehle
- [ ] Spiellogik und Darstellung trennen – teilweise: die Simulation steckt noch in den Schiff-Nodes → Teil von Phase 2 (Netzwerk)
- [x] Im Einzelspieler läuft der Bus lokal; in Phase 2 geht derselbe Befehl übers Netz

### Debug-Menü (F12)

- [x] Pilot: Credits (+10k bis +10M), Auftragsziele erfüllen, Schwarzes Brett neu würfeln, Spieltempo ×0,5 bis ×10
- [x] Schiff: God Mode, alles auffüllen, Frachtraum leeren, jeder Rumpf (auch Carrion Crow) mit oder ohne Standard-Fit, sofort einsteigen
- [x] Items: jedes Modul (oder eins von jedem) ins Stationslager, jede Ware in den Frachtraum
- [x] Welt: Teleport in jedes System (dockt an der ersten Station), Anomalien aufdecken, Piraten spawnen und vernichten
- [x] Nur in Debug-Builds aktiv; alle Cheats sind `debug_*`-Befehle, die ein Server später einfach ablehnt

### Fertig, wenn

- Spiel startet im Menü, ein neues Spiel lässt sich anlegen, speichern, beenden und identisch wieder laden.
- Der Smoke-Test läuft komplett über Befehle und prüft einen Speichern-Laden-Durchlauf.

## Phase 0.5 – Content & Design

Phase 0.5 macht den Kampf aktiver wie in EVE Online und legt die Endgame-Mechaniken fest, bevor Phase 1 Story und Endgame ausbaut und Phase 2 die Netzwerk-Architektur baut. Datenlastiger Content (Schiffe, Module, Waren, Aufträge) kommt jetzt; Mechaniken mit vielen bewegten Objekten werden nur entworfen und in Phase 1 gebaut.

**Die Teile von Phase 0.5:**

| Teil | Thema | Stand |
| --- | --- | --- |
| 1 | More More | ✅ erledigt |
| 2 | World Design Update | ✅ erledigt |
| 3 | NPCs and Factions | ✅ erledigt (Pakete 10–18) |
| 4 | Module and Internal Ship Parts Rework | in Arbeit (Pakete 19–24 fertig) |
| 5 | Character Update – Pakete 28–34 | Entwurf |
| 6 | New Worlds Discovery Update (Galaxy Rework + Into the Darkness) – Pakete 35–48 | grober Plan |
| 7 | The Sky Is Not Enough (Landen, Planeten, Boden) – Pakete 49–54 | grober Plan |
| 8 | Intro and First Part of the Story | geplant (vorher Teil 7) |
| 9 | Feeling and Balancing | geplant (vorher Teil 8) – enthält Paket 8 (großes Balancing) |

Landen und Bodengameplay waren als Part B von Teil 6 geplant und sind jetzt ein eigener Teil 7 (fast ein eigenes Spiel im Spiel); die späteren Teile rücken um eins nach.

### Aktive Steuerung (jetzt)

- [x] Objekt anklicken (Gegner, Asteroid, Wrack, Station …) → Kontextmenü oben rechts
- [x] Aktionen im Kontextmenü: Approach, Orbit, Keep at range, Lock target, Warp to, Dock, Jump – je nach Objekt
- [x] Anvisieren dauert je nach Sensoren; mehrere Ziele möglich, aktives Ziel wählbar
- [x] Modulleiste unten links: aktivierbare Module als rechteckige Kacheln, passive Module werden nicht angezeigt
- [x] Aktivieren per Klick auf die Kachel oder Taste 1–9, nur mit anvisiertem Ziel in Reichweite
- [x] Kacheln zeigen Zyklus, Reichweite, Energiebedarf und Zustand (aktiv, außer Reichweite, kein Ziel)
- [x] Haltungen und Auto-Battle werden ersetzt; NPCs kämpfen weiter automatisch
- [x] Alles läuft als Befehle über den Befehlsbus (lock, unlock, target, orbit, approach, keep\_range, activate …) – umgesetzt, 83 automatische Prüfungen bestanden

### Feinschliff & Ideen

- [x] Systemansicht: große Objekte (Stationen, Tore, Asteroidenfelder, Planeten) haben bei der Auswahl Vorrang vor Schiffen, mit großzügigem Klickbereich
- [x] Schadenszahlen im Kampf: blau für Schildschaden, rot für Hüllenschaden (Panzerung + Struktur)
- [x] Ausführliches Log: Zielerfassung, Aktivierung, Gründe für Fehlschläge und Abschalten
- [ ] Idee: Detail-Langstreckenscanner – aktivierbares Modul, auf einen Ort (Feld, Anomalie, Planet) angewendet; zeigt danach eine Liste der Objekte dort (Asteroiden mit Erzart und Menge, NPCs mit Schiffsklasse)

### Endgame-Entwürfe (Bau in Phase 1)

| Mechanik | Idee | Was die Architektur können muss |
| --- | --- | --- |
| Trägerschiffe | Riesige L/XL-Rümpfe mit Hangar; starten Staffeln kleiner Fighter, die Ziele angreifen und zurückkehren | Viele eigenständige Objekte pro Spieler, Befehle an Staffeln |
| Drohnen – ⏩ vorgezogen in Teil 4 (Paket 23) | Drohnenbucht-Modul + Bandbreite; Typen für Kampf, Bergbau, Reparatur, Bergung | Wie Fighter, kleiner und zahlreicher |
| Langstreckenraketen | Treffen Ziele im Radarbereich außerhalb der Sichtweite; brauchen Zielerfassung | Raketen als Ereignis "abgefeuert von A auf B", Flugbahn rechnet jeder Rechner selbst |
| Nuklearraketen | Langsam, großer Explosionsradius, begrenzte Munition; in sicheren Systemen verboten | Flächenschaden, Munition als Ware |
| Raketenabwehr | Point-Defense-Modul schießt Raketen und Fighter in Reichweite ab; dazu Störsender/Flares | Raketen sind abschießbare Objekte |
| Bossgegner | Phasen nach Lebenspunkten, angekündigte Spezialangriffe, Verstärkung, skaliert mit der Spielerzahl | Boss-Skripte auf dem Host, Skalierung pro Session |

## Phase 0.5 Teil 2 – Welt, Rohstoffe & Module (Plan)

Teil 2 macht die Systeme lebendiger: drei Asteroidenklassen mit eigenen Rohstoffen, Asteroiden in vielen Größen und Formen, Riesenbrocken mit Radarschatten, größere Stationen und neue Module. Fast alles davon ist Daten und Grafik und übersteht den Netzwerkumbau unverändert.

| # | Arbeitspaket | Inhalt | Abhängig von |
| --- | --- | --- | --- |
| 1 | Rohstoffe & Raffinerie – ✅ erledigt | ca. 15 neue Erze/Eise, Raffinerieprodukte, neue Rezepte, Marktpreise | – |
| 2 | Feldtypen & Verteilung – ✅ erledigt | Metallic / Stony / Icy, Lage im System, Sicherheitsstufe | 1 |
| 3 | Asteroiden-Grafik – ✅ erledigt | Größenklassen, prozedurale Formen, Aussehen je Typ | 2 |
| 4 | Freie Asteroiden – ✅ erledigt | Brocken um Planeten, Ringe, bei Toren und POIs | 3 |
| 5 | Riesenasteroiden – ✅ erledigt | Vordergrund-Ebene, Hindernis für Schiffe, Radarschatten | 3 |
| 6 | Stationen – ✅ erledigt | modularer Aufbau, größer je Stufe, neue Typen | – |
| 7 | Module – ✅ erledigt | Langstrecken-Detailscanner, Eis-Sammler u. a. | 1, 2 |
| 8 | Balancing & Test – ⏭ verschoben ans Ende von Phase 0.5 | Großes Balancing mit Auswertungswerkzeug (Einkommen pro Stunde je Tätigkeit, Kampfwerte, Fortschrittskurve, Energiehaushalt) nach Teil 3. Spielstand-Umzug und automatische Tests laufen schon mit. | alle, Teil 3 |
| 9 | Kopfgeld-Bonds – ✅ erledigt | Bonds statt Sofortauszahlung, Bond Office als Stations-Kachel, Warrant Scanner | 7 |
| + | Zusätze – ✅ erledigt | Testsystem im Debug-Hauptmenü; Cluster auf 48 Systeme erweitert, jeder Stationstyp in jeder Stufe; Wirtschaften auf der Sternenkarte; mehr Slots für alle Schiffe; Mining-Laser-Animation mit Abbauzahlen; Schiffsmenü-Reiter Transactions (Aufträge, Bonds) | – |

Teil 2 ist inhaltlich abgeschlossen. Weitere Reihenfolge: Teil 3 (NPCs) → Teil 4 (Module & Schiffsinnenleben) → Teile 5–8 → Teil 9 mit Paket 8 (großes Balancing) als Abschluss von Phase 0.5 → Phase 1 (Story & Endgame) → Phase 2 (Netzwerk). Jedes Paket endet mit einem lauffähigen Stand, Screenshots und erweiterten automatischen Tests.

### Asteroidenfelder & Rohstoffe

Jedes Feld hat einen von drei Typen, angelehnt an echte Asteroidenklassen: **Metallic** (M-Typ), **Stony** (S-Typ, "steinig"; im Spiel "Silicate") und **Icy** (Eis). Ein Feld enthält mehrere Rohstoffe seines Typs; seltene Rohstoffe kommen nur in unsicheren Systemen vor.

| Feldtyp | Häufig | Mittel | Selten (Sicherheit < 0.5) | Raffiniert zu |
| --- | --- | --- | --- | --- |
| Metallic | Iron Ore, Nickel Ore | Titanium Ore, Cobalt Ore | Platinum Ore, Iridium Ore | Ingots (Iron, Nickel, Titanium, Cobalt, Platinum, Iridium) |
| Stony (Silicate) | Silicate Rock, Bauxite | Olivine, Rare Earth Ore | Xeno Crystal, Neodymium Ore | Silicon, Aluminium, Magnesium, Rare Earths, Xeno Lattice, Neodymium |
| Icy | Water Ice, Ammonia Ice | Methane Ice, Deuterium Ice | Helium-3 Ice, Cryo Crystal | Water, Ammonia, Methane, Deuterium, Helium-3, Cryo Coolant |

- **Lage im System:** Metallic-Felder eher sternnah, Icy-Felder hinter der "Frostgrenze" weit draußen, Stony dazwischen. So lohnt sich die Wahl des Ziels.
- **Verwendung:** Metalle und Silikate für Module und Rümpfe; Eise für Treibstoff (Deuterium, Helium-3 → Pyre Fuel Syndicate), Lebenserhaltung (Wasser) und Kühlung (Cryo Coolant für große Waffen und Reaktoren).
- **Wirtschaft:** Bergbaukolonien verarbeiten Metallic und Stony am besten; neu ein Ice-Processing-Bonus für Stationen nahe Icy-Feldern. Rezepte der Fertigung werden um die neuen Materialien erweitert.
- **Bestehendes:** Iron Ore, Titanium Ore und Xeno Crystal bleiben erhalten und wandern in die neuen Feldtypen – alte Spielstände bleiben ladbar (Spielstand-Version 2).

### Asteroiden: Größen, Formen, Aussehen

Asteroiden werden prozedural aus einem Seed erzeugt: Größenklasse, Grundform und Oberfläche, sodass kein Brocken wie der andere aussieht.

| Größe | Durchmesser | Vorrat | Besonderheit |
| --- | --- | --- | --- |
| Small | 20–50 km | 30–120 | Schnell abgebaut, oft in Schwärmen |
| Medium | 50–120 km | 120–400 | Standard im Feld |
| Large | 120–300 km | 400–1.500 | Mehrere Rohstoffe möglich |
| Colossal | 1.000–5.000 km | – (nur Randbrocken) | Vordergrund, Hindernis, Radarschatten |

- **Formen:** rundlich, länglich ("Kartoffel"), Kontakt-Doppelasteroid, kantige Bruchstücke, Splitter (Eis), mit Kratern und Rissen – aus Rauschen und Seed, als Pixelart im bestehenden Stil.
- **Aussehen je Typ:**
  - Metallic: dunkelgrau bis rostbraun, Metalladern, kleine Glanzpunkte.
  - Stony: beige, ocker und rotbraun, rau, große Krater.
  - Icy: weiß-blau, halbtransparente Kanten, Frost-Glitzern, leichter Dunst-Schweif.
- **Riesenasteroiden (Colossal):**
  - Liegen über den Schiffen (Vordergrund) und verdecken sie teilweise.
  - Sind Hindernisse: Schiffe fliegen außen herum statt hindurch.
  - Werfen einen **Radarschatten**: In der Recon-Ansicht ist der Kegel hinter dem Brocken dunkel, Kontakte darin sind nicht sichtbar. Offen: blockieren sie auch Zielerfassung und Waffen?
  - An ihrem Rand lassen sich kleinere Brocken abbauen.
- **Freie Asteroiden außerhalb der Felder:**
  - Ringe und lose Brocken um Planeten (passend zum Planetentyp, z. B. Eis um Gasriesen).
  - Einzelne Brocken und kleine Schwärme bei Toren, Stationen und Anomalien.
  - Großteils Kulisse, einige abbaubar; so wirken auch POIs ohne Feld belebt.
- **Technik:** Viele Asteroiden werden nur in der Nähe der Kamera als Objekte erzeugt (Kulissen-Brocken als einfache Sprites), damit das Spiel flüssig bleibt.

### Stationen

Stationen werden aus Bauteilen zusammengesetzt; Typ und Stufe bestimmen, welche Teile und wie viele – so hat jeder Typ eine eigene Silhouette und große Stationen wirken mächtig.

- **Größe nach Stufe:** Stufe 1 ca. 960 km (knapp 4× so groß wie vorher), Stufe 3 ca. 1.600 km, Shipyard ca. 1.760 km; jede Andockbucht fasst ein L-Schiff. Das Schiff fliegt beim Andocken sichtbar in eine Bucht. Nicht-Feuer-Zone 15.000 / 22.000 / 30.000 km je Stufe: Wer darin zuerst schießt, wird 30 s lang zum Aggressor und von den Stationsbatterien beschossen.
- **Bauteile:** Kern/Hub, Ringe, Andockarme, Solarflügel, Wohnmodule, Lagertanks, Raffinerie-Türme, Werft-Gerüste, Geschütztürme, Antennen, Leuchtreklame der Monopol-Firmen.

| Typ | Erkennungsmerkmale | Status |
| --- | --- | --- |
| Trade Hub | Großer Ring, viele Andockarme, Leuchtreklame | besteht, neue Grafik |
| Industrial Complex | Fabrikblöcke, Schornsteine, Werft-Gerüst | besteht, neue Grafik |
| Mining Colony | Raffinerie-Türme, Erzsilos, Greifarme | besteht, neue Grafik |
| Agricultural Station | Gewächshaus-Kuppeln, große Solarflügel | besteht, neue Grafik |
| Research Station | Antennenschirme, Labormodule, Sensoren | besteht, neue Grafik |
| Military Outpost | Panzerung, Geschütztürme, Hangartore | besteht, neue Grafik |
| Ice Refinery | Tanks, Kühltürme, Dampfwolken; nahe Icy-Feldern | neu |
| Shipyard Complex | Riesige Baudocks, Schiffsrumpf im Bau | neu (große Werft, Träger in Phase 1) |
| Pirate Haven | Zusammengeflickte Wracks, rote Lichter; nur Sicherheit < 0.3, feindlich | neu, Docking erst mit Ruf (später) |

### Neue Module

Der Langstrecken-Detailscanner ist gesetzt; die übrigen Zeilen sind Vorschläge, die zu den neuen Rohstoffen und zur Modulleiste passen.

| Modul | Slot | Wirkung | Status |
| --- | --- | --- | --- |
| Long-Range Survey Scanner | Werkzeug, aktiv | Auf einen Ort (Feld, Anomalie, Planet, Tor) im Auswahlfenster richten; nach 5–10 s Scanzeit eine Liste: Asteroiden nach Rohstoff und Menge, NPC-Schiffe mit Klasse und Fraktion, Wracks. Ergebnis mit Zeitstempel, veraltet nach einigen Minuten. | gesetzt |
| Prospector Scanner | Werkzeug, aktiv | Auf einen anvisierten Asteroiden: zeigt, welche Rohstoffe er enthält und ungefähr wie viel (± 20 %, besseres Modul genauer). Ohne Scan steht im Auswahlfenster nur "Zusammensetzung unbekannt". | gesetzt |
| Warrant Scanner | Werkzeug, aktiv | Auf ein anvisiertes NPC-Schiff: zeigt, ob ein Kopfgeld ausgesetzt ist, wie hoch und in welchem System der Bond eingelöst werden kann. Ohne Scan ist das Kopfgeld unbekannt. | gesetzt |
| Ice Harvester | Werkzeug, aktiv | Baut Icy-Asteroiden effizient ab; normale Bergbaulaser schaffen Eis nur mit starkem Malus | gesetzt |
| Strip Miner (L) | Werkzeug, aktiv | Sehr hohe Abbaurate, nur auf großen Rümpfen | gesetzt |
| Ore Hold | Optional | Zusätzlicher Frachtraum nur für Erz und Eis | gesetzt |
| Mining Upgrade | Optional | +Abbaurate für einen Feldtyp | gesetzt |
| Afterburner → aktiv | Optional, aktiv | Wird aktivierbar: Tempo-Boost gegen Energie statt passivem Bonus | gesetzt |
| Shield Booster / Armor Repairer | Optional, aktiv | Eigenes Schild bzw. Panzerung im Kampf aktiv reparieren | gesetzt |

Der Scanner braucht eine neue Zielart: Er wirkt auf das Objekt im Auswahlfenster (oben rechts) statt auf ein anvisiertes Ziel. Das Ergebnis erscheint als eigenes Fenster und im Auswahlfenster des Ortes.

### Kopfgelder als Bonds

Kopfgelder werden nicht mehr sofort ausgezahlt, sondern als **Bond** ausgestellt – ein Schuldschein, der nur an einer Station im ausstellenden System eingelöst werden kann. So lohnt sich der Rückweg, und unsichere Systeme mit Station werden wertvoll.

- **Wer stellt aus:** Die Sicherheitsbehörde des Systems über eine neue Monopol-Firma, Vorschlag **Sable Writ Exchange \[SWX\]** – "Every head has a price."
- **Wer hat Kopfgeld:** Nicht jeder NPC. Höhe nach Schiffsklasse und Unsicherheit des Systems; Bosse und berüchtigte Piraten deutlich mehr. Der Warrant Scanner zeigt es vorher an.
- **Ablauf:** Abschuss → Bond landet im Pilotenkonto ("Bond Wallet", sichtbar im Schiffsmenü-Reiter Transactions → Bonds) mit System, Ziel, Betrag und Datum → an einer Station dieses Systems über die neue Kachel **Bond Office** einlösen.
- **Bond Office (neue Stations-Kachel):** Liste aller Bonds, einlösbare hervorgehoben, "Alle einlösen", Hinweis auf das System für die übrigen. Firmen-Banner wie bei den anderen Diensten.
- **Systeme ohne Station:** Bonds dort werden im nächstgelegenen System mit Station eingelöst (so umgesetzt).
- **Zusammenspiel:** BlackLedger-Kopfgeldaufträge bleiben eigenständig (Belohnung beim Auftraggeber); Bonds kommen zusätzlich.
- **Koop (später):** Bonds pro Spieler, aufgeteilt nach Schadensanteil.

### Entscheidungen zu Teil 2

| Frage | Optionen | Entscheidung |
| --- | --- | --- |
| Radarschatten der Riesenasteroiden | Nur Radar-Anzeige · auch Zielerfassung · auch Waffen/Projektile | Radar + Zielerfassung; Projektile prallen ab – Deckung wird taktisch |
| Hindernis-Verhalten | Weiche Ausweichsteuerung · harte Kollision | Weiches Ausweichen, kein Kollisionsschaden |
| Eis abbauen | Normaler Bergbaulaser · eigener Ice Harvester | Eigener Ice Harvester (Normaler Bergbau Laser geht auch aber mit massiven Malus effekten) |
| Anzahl neuer Rohstoffe | Klein (\~8) · voll (\~15) | Voll, Balancing über Preise |
| Reichweite des Detailscanners | Ganzes System · begrenzt (z. B. 1 Mio. km) | Begrenzt, Upgrade für mehr Reichweite |
| Pirate Haven | Jetzt nur als Kulisse · mit Ruf-System | Jetzt als feindliche Kulisse, andocken später |
| Weitere Module aus der Vorschlagsliste | alle · Auswahl | Alle – alle Module der Liste sind gesetzt |
| Bonds bei Schiffsverlust | Bleiben erhalten · gehen mit dem Schiff verloren | Bleiben erhalten (digital beim Piloten) |
| Ablauf der Bonds | Nie · nach Spielzeit (z. B. 2 h) | Nie |

## Phase 0.5 Teil 3 – NPCs (Plan)

Teil 3 macht die Systeme lebendig: Regierungen, die Systeme kontrollieren, Verkehr, der sich nach Bevölkerung und Wirtschaft richtet, ein Ruf pro Fraktion und Piraten mit Charakter. Die Dienstleistungs-Konzerne behalten ihre Service-Monopole; die Fraktionen sind davon getrennte Regierungen. Paket 8 (großes Balancing) bleibt am Ende von Phase 0.5, weil Teil 3 Kopfgelder, Verkehr und Kampfstärken noch einmal verschiebt.

| # | Arbeitspaket | Inhalt | Abhängig von |
| --- | --- | --- | --- |
| 10 | Fraktionen & Territorium – ✅ erledigt | 3 Supermächte + 2 Piratenfraktionen, Systemkontrolle, Farben & Wappen, Holo-Banner, Territorium auf der Karte | – |
| 11 | Bevölkerung & Verkehr – ✅ erledigt (inkl. abschaltbarer Kartenebenen) | Systemprofil aus Planeten, Stationen, Wirtschaft; Shuttles, Handelskonvois, Bergbauschiffe, Patrouillen | 10 |
| 12 | Ruf pro Fraktion – ✅ erledigt | Skala −100 bis +100, fünf Stufen, Quellen und Auswirkungen, Mitzieh-Effekt; Pirate Havens andockbar | 10 |
| 13 | Kopfgelder & Recht – ✅ erledigt | Kopfgelder von Fraktionen, Bonds mit Aussteller, Fahndungsstufe pro Fraktion | 12 |
| 14 | Piraten-Archetypen – ✅ erledigt | 6 KI-Typen mit eigenem Verhalten und Loadout | 10 (parallel zu 11) |
| 15 | Berüchtigte Piraten – ✅ erledigt | benannte Piraten mit Eskorte, Steckbrief, wandern durch den Cluster | 13, 14 |
| 16 | Weltreaktionen & Nachrichten-Ticker – ✅ erledigt | Eskalation der Patrouillen, Flucht, Notrufe, Wracks, Funk- und Nachrichten-Ticker | 11, 12 |
| 17 | NPC-Missionen – ✅ erledigt | Konvoi-Eskorte, Patrouille begleiten, Jagd auf Berüchtigte, Schmuggler abfangen | 15, 16 |
| 18 | Codex (Glossar) – ✅ erledigt | Nachschlagewerk im Spiel: Geschichte, Fraktionen, Konzerne, Orte, Technik, Spielgrundlagen; Einträge werden beim Entdecken freigeschaltet | 10 (wächst mit jedem Paket) |
| 8 | Großes Balancing | Analyse-Werkzeug, Preise, Kopfgelder, Kampfstärken (Abschluss von Phase 0.5) | alle |

### Welt & Hintergrund (Entwurf)

Die Fraktionen brauchen eine gemeinsame Geschichte. Der Entwurf bleibt bewusst grob; ausformuliert landet er im Codex (Paket 18). Namen im Spiel sind englisch.

**Zeit:** 12900 HE (Human Era, Holozän-Kalender ab dem Beginn der menschlichen Zivilisation – entspricht 2900 n. Chr.).

**Vorgeschichte**

- **um 12340 HE – Der Sprung:** Durchbruch beim Hyperraumantrieb. Die Menschheit bricht zu den Sternen auf.
- **12400–12700 HE – Die Expansion:** Charter-Konzerne bauen Sprungtore, Kolonieschiffe besiedeln ferne Sternhaufen – darunter einen dichten Haufen weit draußen am Rand des erschlossenen Raums. Mit der Erde verbindet ihn nur eine einzige Fernroute, das **Long Gate**.
- **12713 HE – The Severance (der Bruch):** Der Cluster wird schlagartig abgeschnitten. Fernsprünge enden seitdem im **Veil**, einem Gürtel aus instabilem Hyperraum um den Cluster; die lokalen Tore funktionieren weiter. Seitdem kein Lebenszeichen von der Erde. **Die Ursache ist unbekannt** – um dieses Rätsel dreht sich die spätere Story. Die Trümmer des Long Gate liegen in einem Randsystem.
- **12713–12760 HE – The Dark Decades:** Versorgungslücken, Zerfall der Kolonialverwaltung, die ersten Piraten. Aus dem Chaos entstehen die drei Mächte.
- **Heute:** knapp 200 Jahre nach dem Bruch. Niemand Lebendes hat die Erde gesehen – sie ist Mythos, Ziel oder bloße Erinnerung. Der Sternhaufen heißt allgemein nur **„the Cluster“**.

**Die drei Mächte**

- **Cluster Assembly** („the Assembly“) – reine Demokratie: Jede Bürgerin und jeder Bürger stimmt über jedes Gesetz direkt ab („the Vote“, über das Datennetz der Tore). Ziel: den Cluster als neue Heimat aufbauen – Motto „The Cluster is home.“ Hervorgegangen aus Kolonisten und Stationsarbeitern. Stärken: Handel, Bevölkerung, Infrastruktur; Schwäche: langsame Entscheidungen, kleines Militär mit Milizen. Farben Blau/Weiß, Wappen: Sternenkreis um eine offene Hand.
- **Covenant of Return** („the Covenant“) – theokratische Autokratie unter dem **Hierarch**. Glaubt, die Erde sei heilig und der Bruch eine Prüfung; wer bleiben will („the Settled“), gilt als Feind. Hervorgegangen aus der Besatzung der Kolonialflotte, deren Kaplan-Admiral die Rückkehr zum heiligen Auftrag erklärte. Stärken: Militär, Disziplin. Farben Karmesin/Gold, Wappen: Sonne über einem Weg.
- **Meridian Directorate** („the Directorate“) – Technokratie: regiert von einem Rat aus Fachleuten, Ämter nach Prüfungen. Zwei Ziele: das Leben im Cluster verbessern (Medizin, Terraforming, Raffinerie) und mit **Project Bridge** einen Weg durch das Veil finden. Hervorgegangen aus einer Forschungsexpedition, die beim Bruch im Cluster war. Handelt mit allen; der Covenant braucht ihre Forschung, misstraut ihr aber. Farben Grün/Silber, Wappen: Zirkel mit Lichtbogen.
- **Beziehungen:** Covenant und Assembly sind verfeindet. Das Directorate ist neutral zu beiden, leicht freundlich zur Assembly – und wird vom Covenant geduldet, solange Project Bridge Fortschritte macht.

**Piratenfraktionen – Beispiele (zwei auswählen)**

- **Hollow Crown:** Schmugglerkartell, Schwarzmarkt für verbotene Directorate-Technik und Covenant-Reliquien. Violett/Schwarz.
- **The Severed:** Nihilistischer Kult – „die Erde hat uns verlassen“; plündern Wracks und flicken Schiffe aus Schrott zusammen. Rost/Weiß.
- **Free Captains:** Bund von Freibeutern mit eigenem Kodex; Söldner für jeden, der zahlt. Schwarz/Türkis. (keine Eigene Stationen tauchen aber als Piraten auf)&#32;

**Konzerne:** Die Service-Monopole sind alte Charter-Häuser aus der Zeit vor dem Bruch. Sie sind politisch neutral und haben Verträge mit allen drei Mächten – deshalb bieten sie überall dieselben Dienste an.

### Fraktionen & Territorium (Paket 10)

- **Fünf Fraktionen** in einer neuen Datei `data/factions.gd`: Name, Kurzname, zwei Farben, Wappen, Haltung zu den anderen Fraktionen (verbündet, neutral, feindlich).
- **Supermächte (Vorschlag):** Cluster Assembly – Demokratie, Blau/Weiß. Covenant of Return – Theokratie, Karmesin/Gold. Meridian Directorate – Technokratie, Grün/Silber. Hintergrund siehe „Welt & Hintergrund“.
- **Piratenfraktionen (Vorschlag):** zwei aus Ashen Fang, Hollow Crown, The Severed und Free Captains (siehe „Welt & Hintergrund“).
- **Systemkontrolle** deterministisch im Cluster-Plan (wie `stations_plan`): jede Supermacht hat ein Kerngebiet um einen Ankerpunkt; wo Gebiete aufeinandertreffen, liegen umstrittene Grenzsysteme; Piratenfraktionen kontrollieren unsichere Randsysteme rund um die Pirate Havens.
- **Sicherheit** ergibt sich künftig aus der kontrollierenden Fraktion und der Entfernung zu deren Kerngebiet.
- **Wappen:** prozedurale Pixel-Art (Schild, Symbol, Farben) – einmal erzeugt, überall verwendet: Karte, Banner, Bonds, Ruf-Anzeige.
- **Holo-Banner:** Fraktionsstationen zeigen neben der Station ein flackerndes Holo-Wappen (über dasselbe System wie die Neon-Lichter von StationArt).
- **Lackierung:** Patrouillen und Fraktionsschiffe in den Farben ihrer Fraktion.
- **Galaxiekarte:** neue Ebene „Territorium“ mit Fraktionsfarben, Grenzen und Wappen; Infofeld zeigt die kontrollierende Fraktion.
- **Spielstände:** alte Spielstände bekommen die Fraktionen per Migration.

### Bevölkerung & Verkehr (Paket 11)

- **Systemprofil:** Bevölkerung aus den Planeten – erdähnlich stark (×3), Wüste und Eis mittel, Lava, Gift und Gas kaum, Gestein fast nichts. Dazu Anzahl und Stufe der Stationen und ihre Wirtschaft.
- **Ergebnis des Profils:** Verkehrsbudget, Patrouillenstärke und Piratendruck pro System.
- **Shuttles:** pendeln zwischen Planeten und Stationen – der Grundverkehr, wächst mit der Bevölkerung.
- **Handelskonvois:** mehr bei Handelsstationen; springen zwischen Systemen und fliegen Routen nach Angebot und Nachfrage.
- **Bergbauschiffe:** bei Bergbau-Stationen; bauen an Feldern ab und konkurrieren mit dem Spieler um das Erz.
- **Patrouillen:** von der kontrollierenden Fraktion gestellt; bei Militärstationen größer und besser ausgerüstet; feste Routen zwischen Stationen und Toren.
- **Neue Rümpfe:** Shuttle und Frachter für den zivilen Verkehr.
- **Performance:** NPC-Limit pro System; Systeme ohne Spieler werden nur grob simuliert (Konvois sind unterwegs, aber nicht als einzelne Schiffe).
- **Patrouillen-Runden (4. Nov 2026):** Patrouillen bleiben am Wegpunkt nicht mehr stehen, sondern fliegen 1,5–3 min mit halbem Tempo eine Runde – um Stationen und Tore auf einem Ring deutlich außerhalb (Schritte von höchstens 60°, also nie quer darüber), durch Asteroidenfelder im Zickzack – und warpen dann weiter.
- **Nachgebessert nach dem ersten Test:** Verkehr und Patrouillen fliegen mit 60 % Tempo und brauchen 2,5× so lange zum Ausrichten für den Warp (mind. 6 s); Patrouillen bleiben 1–2 min an jedem Wegpunkt; NPC-Warpspuren auf der Systemkarte stark verkleinert.
- **Ortsgebundene NPCs (Loiterer):** wartende Frachter/Skiffs bei Stationen, Zweier-Patrouillen in den Asteroidenfeldern, Torwachen an bis zu zwei Toren – kreisen 10–25 min langsam um ihren Ort.
- **Mehr Verkehr:** bis zu 16 Shuttles; 2 freie Bergbauschiffe in jedem System mit Feldern, bis zu 10 in Bergbausystemen; Startsystem ca. 27 Schiffe (Limit 60).
- **Zeitversetztes Erscheinen:** beim Betreten etwa die Hälfte des Verkehrs, der Rest kommt einzeln alle 2,5–6 s; nie im Umkreis von 60.000 km um den Spieler – stattdessen durch ferne Tore, aus Stationen außer Sicht oder aufsteigend vom Planeten.
- **Reiter „Contacts“** neben der Übersicht: alle Schiffe im System mit Rolle, Fraktionsfarbe und Entfernung, ⇢ = im Warp.
- **Warp Interdictor (S/M):** Schiff im Warp auswählen, Modul aktivieren → Ziel friert ein, man springt sofort hinterher (1,5× Warpdauer) und wird \~2 s vor dem Ziel festgehalten, bis das Timing-Minispiel entschieden ist (Taste E oder Klick; 2–3 Treffer je nach Rumpf, max. 2 Fehler, 14 s). Erfolg: Ziel fällt aus dem Warp, Antrieb 45 s gestört. Noch ohne rechtliche Folgen (später Paket 13).
- **Kartenebenen** „Territory \[T\]“ und „Convoys“ auf der Clusterkarte abschaltbar, Einstellung wird gespeichert.

### Ruf pro Fraktion (Paket 12)

- **Skala** −100 bis +100 in fünf Stufen: Erzfeind, Feindselig, Neutral, Freundlich, Verbündet.
- **Quellen:** Kopfgelder einlösen, Missionen, Angriffe auf Fraktionsschiffe, Zollverstöße.
- **Mitzieh-Effekt:** Wer einer Fraktion hilft, verliert etwas Ruf bei deren Feinden. (Nur bei Missionen, die sich expelzit gegen eine andere Faktion richten)
- **Auswirkungen:** Andockerlaubnis, Preisauf- oder -abschlag, Verhalten der Patrouillen (ignorieren, scannen, angreifen), freigeschaltete Missionen und Module.
- **Piraten-Ruf:** entscheidet, ob man in den Pirate Havens der jeweiligen Piratenfraktion andocken darf.
- **Anzeige:** Ruf-Übersicht mit Wappen im Schiffsmenü.

**Umgesetzt (4. Nov 2026)** – Code in `scripts/core/reputation.gd` (`GameState.rep`), 28 neue automatische Prüfungen, alle 247 bestanden:

- [x] Fünf Stufen: Arch-enemy (< −60), Hostile (ab −60), Neutral (ab −20), Friendly (ab +20), Allied (ab +60). Start: Mächte 0, Piraten −10. Gespeichert mit dem Piloten; alte Spielstände bekommen die Startwerte.
- [x] Quellen: Bond einlösen +0,5 bis +4 beim Aussteller (Macht, die das System hält oder beansprucht – Bonds merken sich jetzt ihren Aussteller), Auftrag erledigt +2,5 bei der Fraktion der Auftragsstation, erster Schuss auf ein nicht feindliches Schiff −4, Zivilist abgeschossen −10, Patrouille −12, Pirat −1,5 je Größenklasse bei seiner Piratenfraktion.
- [x] Mitzieh-Effekt nur bei Aufträgen gegen eine Fraktion: Kopfgeldaufträge kosten −1,5 bei der Piratenfraktion, die das Zielsystem hält.
- [x] Andocken: Erzfeinde werden abgewiesen (Freihäfen nie). Pirate Havens: ab Friendly mit ihrer Piratenfraktion andockbar und die Geschütze schweigen – Schwarzmarkt, Ausrüster, Raffinerie, Treibstoff, Reparatur, Hangar (kein Bond Office, kein Schwarzes Brett, keine Werft).
- [x] Preise an Stationen der Fraktion (Markt, Ausrüster, Werft, Treibstoff, Reparatur): Hostile +10 % / Verkauf −10 %, Friendly −5 % / +3 %, Allied −10 % / +6 %.
- [x] Patrouillen greifen Hostile und schlechter an, scannen Neutrale (höchstens alle 2 min pro Fraktion eine Meldung) und ignorieren Freunde. Wer auf ein Schiff einer Fraktion schießt, wird 90 s lang von deren Schiffen bekämpft.
- [x] Aufträge: bei Hostile keine Aufträge an den Stationen der Fraktion; Friendly +10 %, Allied +20 % Belohnung. L-Module an Militärposten erst ab Friendly.
- [x] Piraten einer Fraktion lassen Friendly-Piloten in Ruhe.
- [x] Waffen wirken jetzt auf jedes Schiff (nicht nur Feinde); vor dem Feuern auf ein nicht feindliches Schiff warnt das Log.
- [x] Reiter „Standing“ im Schiffsmenü (Wappen, Stufe, Wert, aktuelle Auswirkungen), Ruf im Stationskopf und im Auswahlfenster, Ruf-Regler im Debug-Menü (`debug_rep`).
- [ ] Zollverstöße als Quelle – es gibt noch keinen Zoll (Idee „Schmuggel & Zoll“); `rep.change()` ist dafür vorbereitet.
- [ ] Fraktions-Missionen und -Module im engeren Sinn kommen mit Paket 17 bzw. den Fraktionsrümpfen; Fahndungsstufe mit Paket 13.

### Kopfgelder & Recht (Paket 13)

- **Kopfgelder** werden von der Fraktion ausgesetzt, die das System kontrolliert (Piraten-Kopfgelder von den Supermächten).
- **Bonds** tragen die ausstellende Fraktion und ihr Wappen; Sable Writ Exchange bleibt die Clearingstelle.
- **Fahndungsstufe pro Fraktion:** Schießen in Nicht-Feuer-Zonen oder Angriffe auf Zivilisten setzen den Spieler bei der kontrollierenden Fraktion auf die Liste. Leichte Vorstufe des späteren Verbrechenssystems.

**Umgesetzt (4. Nov 2026)** – Code in `scripts/core/law.gd` (`GameState.law`), 16 neue automatische Prüfungen, alle 263 bestanden:

- [x] Aussteller eines Kopfgelds ist immer eine Macht: die Systembesitzerin, in umstrittenen Systemen die erste beanspruchende Macht, im Piratenraum die nächstgelegene Macht. Großzügigkeit je Macht: Covenant ×1,25, Directorate ×1,0, Assembly ×0,9. Der Warrant Scanner zeigt den Aussteller.
- [x] Bonds tragen Aussteller und Wappen; Einlösung bei Sable Writ Exchange an **jeder** Station des Ausstellers (nicht in Pirate Havens). Bond Office und Bond-Liste zeigen Wappen und die nächste Einlösestelle mit Kurs-Knopf. Alte Bonds ohne Aussteller behalten die alte Regel.
- [x] Strafregister pro Macht. Zuständig ist die Systembesitzerin, in umstrittenen Systemen die Macht des Opfers; Piratenraum ist rechtsfrei. Punkte: Feuer in einer Nicht-Feuer-Zone 1, erster Schuss auf Zivilist 1 / Patrouille 2 (nur wenn sie keine Gefahr war), Abschuss 2 / 3, Interdiction eines rechtmäßigen Schiffs 1.
- [x] Stufen: Suspect (1–2) – Patrouillen greifen an, auch in Nicht-Feuer-Zonen; Wanted (3–5) – keine Aufträge; Most Wanted (6+) – kein Andocken. Ein Punkt verfällt alle 5 min ohne neue Tat; Strafe 2.000 cr pro Punkt am Bond Office der Fraktion (`fine_pay`).
- [x] Anzeige im Standing-Reiter und am Bond Office; Debug-Menü setzt Register (`debug_wanted`); gespeichert mit dem Piloten.
- [ ] Kopfgeld auf den Spieler und Kopfgeldjäger – später (Berüchtigte / Weltreaktionen).

### Piraten-Archetypen (Paket 14)

Normale Piraten bleiben Einzelgänger wie bisher, bekommen aber eine KI-Rolle mit eigenem Verhalten und Loadout:

- **Raider:** schnell, Laser, greift an und zieht sich zurück.
- **Brawler:** schwer gepanzert, Autokanonen, sucht den Nahkampf.
- **Sniper:** hält Abstand, Railgun oder Raketen.
- **Ambusher:** lauert in Asteroidenfeldern oder im Radarschatten eines Colossus.
- **Leech:** Ionenwaffen, saugt Schilde und Energie ab.
- **Coward:** flieht bei Schaden und ruft Hilfe.
- Der Warrant Scanner zeigt den Archetyp nach dem Scan. Lackierung nach Piratenfraktion.

**Umgesetzt (4. Nov 2026)** – Daten in `data/pirate_archetypes.gd`, 12 neue automatische Prüfungen, alle 275 bestanden:

- [x] Je Archetyp drei Loadouts (leicht überall, mittel unter Sicherheit 0,6, schwer unter 0,3); Häufigkeit gewichtet (Raider am häufigsten, Leech am seltensten).
- [x] Raider: schnell, Pulslaser + Nachbrenner; ca. 7 s Angriff, 4,5 s Abdrehen, dann wieder rein.
- [x] Brawler: Panzerung + Autokanonen, geht auf Nahkampfdistanz.
- [x] Sniper: Raketen bzw. Railgun auf maximaler Reichweite, weicht zurück, wenn man näher kommt.
- [x] Ambusher: wartet hinter einem Colossus (Radarschatten) oder in den Felsen, greift erst Ziele innerhalb von 45 % seiner Sensorreichweite an; erste 5 s +60 % Schaden.
- [x] Leech: neue Ionenwaffen (Ion Disruptor S, Ion Siphon M) – +60 % gegen Schilde, saugen Energie ab (die Hälfte geht an den Schützen). Piratenausrüstung: nicht bei den Konzernen, nur aus Wracks oder in Pirate Havens.
- [x] Coward: flieht unter 55 % Panzerung + Struktur, ruft alle freien Piraten im Umkreis von 45.000 km gegen den Angreifer und warpt weg.
- [x] Alle Piraten wehren sich jetzt gegen jeden, der auf sie schießt. Warrant Scanner und Auswahlfenster zeigen den Archetyp; Debug-Spawn listet alle Loadouts.

### Berüchtigte Piraten (Paket 15)

- Name und Spitzname, eigene Lackierung, eine besondere Eigenschaft (z. B. „Shield Breaker“, „Never Alone“).
- 2 bis 4 Begleitschiffe in Formation.
- Steckbrief am Kopfgeldbrett mit hohem Kopfgeld; wandern zwischen Systemen, Galaxiekarte zeigt „zuletzt gesehen in …“.
- Besondere Beute; nach dem Tod übernimmt nach einer Weile ein Nachfolger. Vorstufe zu den Bossen.

**Umgesetzt (4. Nov 2026, nachgebessert)** – Code in `scripts/core/notorious.gd` (`GameState.notorious`) und `scripts/core/station_status.gd` (`GameState.stations`), 28 neue automatische Prüfungen, alle 303 bestanden:

- [x] Fünf Kapitäne gleichzeitig, verteilt auf Hollow Crown, The Severed und Free Captains; Name, Spitzname, eigene Lackierung (6 Farbschemata), Archetyp mit schwerem Loadout, Begleiter in Formation.
- [x] Sechs Eigenschaften: Shield Breaker, Never Alone (+2 Begleiter), Iron Hide, Ghost, Overcharged, Regenerator.
- [x] **Gefährlichkeit 1–5 Sterne:** 2 / 2 / 3 / 4 / 5 Begleiter (ab 2 Sternen schwerere Begleitschiffe), der Kapitän nimmt 85 % bis 50 % Schaden. Start: zwei 1-Stern-, zwei 2-Stern- und ein 3-Stern-Kapitän. Alle 30 min Überleben +1 Stern; neue Begleiter warpen dazu. Nachfolger starten mit 1–2 Sternen.
- [x] **Kopfgeld unabhängig von den Sternen:** Grundwert 40.000–80.000 cr, +500 cr alle 4 min Lebenszeit. Steckbrief zeigt „Wanted since“.
- [x] **Wandern:** überall außer in den Heimatsystemen (die drei Hauptstädte und das Startsystem des Spielers). Unsichere Systeme (≤ 0,65) 6–12 min, sicherere nur kurz (2–4 min), dann lungern sie in den Asteroidenfeldern. Nie, solange der Spieler im selben System ist.
- [x] **Überfälle:** 5-Stern-Kapitäne überfallen bei Ankunft in einem System mit Station (keine Militärstation) in der Hälfte der Fälle eine Station:
  - **Ankündigung 5 min vorher** („SWX ALERT“ im Log), dann 3–5 min Überfall.
  - **Live**, wenn der Spieler im System ist: Station bekommt eine **Lebensleiste** (15.000 je Stufe), Geschütze je 1.200 HP und sind **abschießbar**; Piraten beschießen erst die Geschütze, dann die Hülle. Neuer **Ionentorpedo** (nur 5-Stern-Kapitäne, nicht ausrüstbar, keine Beute) schaltet alle 10 s ein Geschütz für 25 s aus. Markierungen: rotes ✕ = zerstört, violetter Ring = lahmgelegt; HUD-Zeile mit Hülle, Geschützen, Restzeit.
  - **Station fällt:** Kopfgeld +100.000 cr, ein Stern wird **rot**. Station 1 Stunde **offline** (Andocken geht, kein Service) – oder bis die **Hilfsgüter** geliefert sind (Legierungen, Elektronik + eine typabhängige Ware, Menge nach Stufe). Lieferung in beliebigen Teilmengen direkt im Concourse, **doppelter Grundpreis** je Einheit, bei Abschluss 5.000 cr je Stufe Bonus und Ruf bei der Fraktion.
  - **Kapitän kurz vorm Verlieren** (< 30 % Panzerung + Struktur): Abbruch, die Piraten fliehen und springen weg, der Kapitän versteckt sich 15 min („whereabouts unknown“).
  - **Verteidigen lohnt sich:** wer einen Angreifer trifft und die Station hält (Flucht, Zeitablauf oder Tod des Kapitäns), bekommt 20.000 cr und Ruf.
  - Ohne Spieler im System entscheidet der Zufall (höhere Stufe hält eher).
- [x] Steckbriefe am Bond Office (Porträt, Sterne, Fraktion, Archetyp, Eigenschaft, Kopfgeld, Begleiter, „Wanted since“, „zuletzt gesehen in …“ mit Kurs-Knopf, laufender Überfall); Galaxiekarte zeigt ☠ und Details im Systeminfo.
- [x] Abschuss: Bond über das volle Kopfgeld, Wrack mit drei ihrer Module, seltenen Barren und vielen Teilen. Nach 20–40 min übernimmt ein Nachfolger die Crew.
- [x] Sichtungen, Überfälle, Aufstiege und Abschüsse werden als Meldungen gesammelt (`notorious.news`) – Grundlage für den Nachrichten-Ticker in Paket 16.

### Weltreaktionen & Nachrichten-Ticker (Paket 16)

- **Eskalation:** Patrouille → Verstärkung → Einsatzgruppe, abhängig von Fraktion und Sicherheit des Systems.
- **Zivilisten:** Händler fliehen vor Kämpfen, Shuttles weichen aus, angegriffene Schiffe senden Notrufe.
- **Wracks:** zerstörte Schiffe hinterlassen Wracks mit Beute zum Bergen.
- **Funk-Ticker:** kurze Meldungen aus dem System, z. B. „Convoy under attack near Aldersee Gate“.
- **Nachrichten-Ticker:** Ereignisse der Welt als Meldungen, z. B. „Concord raises bounties in Eschental“ oder Sichtungen berüchtigter Piraten.

**Umgesetzt (4. Nov 2026)** – Code in `scripts/core/news.gd` (`GameState.news`) und `scripts/world/traffic.gd`, 14 neue automatische Prüfungen, alle 317 bestanden:

- [x] Nachrichtenarten: **Überfall-Alarme** (bleiben zusätzlich im Chat/Log), **Cluster-Nachrichten** (Kopfgeld-Kampagnen, Konvois, Piratenaktivität, alles zu den Berüchtigten, Stationen wieder online) und **Funk** aus dem aktuellen System.
- [x] **Ticker** unten im Schiffs-Panel – jede neue Meldung läuft genau einmal durch, ohne Neues ist er ausgeblendet; Funk nur, wenn er höchstens 26.000 km von dir entfernt passiert (≈ Durchmesser eines Asteroidenfelds), sonst nur im Archiv; Kurzliste im Info-Reiter des Schiffsmenüs; **News Archive** als neue Stations-Kachel (Lumen Newsnet [LNN]) mit Filtern und laufenden Kampagnen – entspricht der Entscheidung „kurz im Ship Info, ausführlich in Stationen“.
- [x] **Kopfgeld-Kampagnen:** alle 2,5–5 min ein Welt-Ereignis; oft erhöht eine Macht in einem System die Kopfgelder 30 min lang um 50 % – wirkt wirklich auf neue Piraten dort.
- [x] **Notrufe** angegriffener Zivilisten und Patrouillen („Mayday!“, „Convoy under attack near …“), **Zivilisten fliehen** im Umkreis von 25.000 km vom Angreifer weg.
- [x] **Eskalation** im Gebiet der Mächte: nächste Patrouille antwortet → **Verstärkung** (2 Schiffe) → **Einsatzgruppe** (3 schwere Schiffe); Covenant ×1,5, Directorate ×1,0, Assembly ×0,8, sichere Systeme schneller; Verstärkungen ziehen nach 5 min wieder ab. Im Piratenraum kommt niemand.
- [x] **Wracks für alle:** Zivilisten hinterlassen Ladung, Patrouillen Waffenteile und manchmal ein Modul.
- [x] Debug-Menü: Überfall mit 5-min-Ankündigung oder sofort (`debug_raid`).

### NPC-Missionen (Paket 17)

- Konvoi-Eskorte, Patrouille begleiten, Jagd auf berüchtigte Piraten, Schmuggler abfangen.
- Missionen kommen von Fraktionen und hängen vom Ruf ab.

**Umgesetzt (4. Nov 2026)** – Code in `scripts/core/missions.gd` (Fraktionsaufträge), `scripts/world/traffic.gd` und `scripts/core/convoy_sim.gd`, 14 neue automatische Prüfungen, alle 334 bestanden:

- [x] Drei **Fraktionsaufträge** je Regierungsstation, unter BlackLedgers Angeboten am Schwarzen Brett, mit Wappen und benötigter Ruf-Stufe; +4 Ruf bei Abschluss (statt +2,5), −2 bei Misserfolg; Mitzieh-Effekt gegen die Piratenfraktion.
- [x] **Konvoi-Eskorte** (ab Neutral): ein echter Konvoi (2–4 Frachter + Begleitschiff) startet an der Station zu einem Ziel 1–2 Sprünge entfernt. Mindestens 60 % der Reise im selben System dabei sein (nicht angedockt); Hinterhalte durch Piraten (in unsicheren Systemen häufiger). Abgabe an der Zielstation. **Bezahlung anteilig:** jeder verlorene Frachter kostet seinen Anteil; alle verloren = gescheitert.
- [x] **Sammeln & Markierung:** der Konvoi sammelt sich vor der Station und startet erst, wenn man 3 s innerhalb von 1.000 km war („Convoy departing“ im Ticker unten links); die Wartezeit zählt nicht gegen einen. Eigener Konvoi grün markiert: Ring in der Kampfansicht, grüne Rauten mit „YOUR CONVOY“ im Radar und auf der Systemkarte.
- [x] **Folgen:** Knopf „Follow“ für grün markierte Schiffe (jedes Konvoischiff = dessen Führungsschiff; Führungsschiff mit doppeltem Ring und „CONVOY LEAD“) – Folgen genügt auch zum Losfliegen des Konvois; man bleibt beim Schiff, geht sofort mit in den Warp (ohne Ausrichten) und springt ihm durch Tore hinterher; die Konvoi-Schiffe selbst nutzen dasselbe Verhalten und bleiben zusammen.
- [x] **Verbund-Warp:** wer einem Schiff folgt (auch über eine Kette), warpt mit ihm – das Führungsschiff richtet seine Warpzeit nach dem langsamsten Warpantrieb aller Folgenden (alpha 0.4.19.15).
- [x] **Nach einem Angriff:** Konvoischiffe fliehen nicht mehr; der Konvoi hält die Position, solange ein Pirat in der Recon-(Sensor-)Reichweite seiner Schiffe ist, und fliegt weiter, sobald alles frei ist **und** der Spieler dabei ist (Follow innerhalb 8.000 km oder direkt daneben, 2.000 km); ohne Spieler nach 2 Minuten Ruhe (alpha 0.4.19.15).
- [x] **Verbund-Kacheln:** Konvoi, Patrouille, das verfolgte Schiff und wer dem Spieler folgt erscheinen oben links als kleine grüne Kacheln (Name, LEAD, Entfernung, Schild/Panzer/Struktur; Klick wählt aus, Rechtsklick folgt) (alpha 0.4.19.15).
- [x] **Feste Formation:** Folgende fliegen in fester V-Formation hinter dem Führungsschiff (Spieler auf dem ersten Platz) und halten ihren Platz während des gesamten Warps; das Führungsschiff kündigt jeden Warp und Sprung im Chat an (alpha 0.4.19.16).
- [x] **Tastatursteuerung:** WASD fliegt das Schiff (Loslassen = Stopp), Pfeiltasten bewegen die Kamera (alte gespeicherte Kamera-Belegungen werden einmalig zurückgesetzt); Tab wählt den nächsten Feind (nochmal: den nächsten), B die nächste Station innerhalb 5.000 km (alpha 0.4.19.16).
- [x] **Befehls-Hotkeys** (umbelegbar, Einstellungen → Steuerung): R Lock (nochmal: Unlock; ohne Auswahl: nächster Feind), Q Approach, X Warp, J Jump, G Dock, F Follow (alpha 0.4.19.15).
- [x] **Warp-Ansage:** leitet der Konvoi den nächsten Warp ein, meldet er das im Ticker („Convoy aligning for warp to … – stay close!“).
- [x] **Abfangen durch Piraten:** der eskortierte Konvoi kann mitten im Warp herausgezogen werden – Konvoi und alle Folgenden fallen direkt beim Führungsschiff aus dem Warp, Antriebe 15 s gestört, 3–4 Piraten greifen an – oder Piraten lauern am Ankunftstor (beides in unsicheren Systemen häufiger).
- [x] **Eskorte auch ohne Fraktion:** Handelsstationen (Trade Hubs) bieten am BlackLedger-Brett Eskorten für unabhängige Händler-Konvois mit 2–4 Frachtern ohne eigenes Begleitschiff an (ca. 30 % ihrer Angebote).
- [x] **Patrouille begleiten** (ab Neutral): eigene Auftrags-Patrouille – startet an der Station (rollt aus den Hangarbuchten) oder an einem genannten Ort (Tor, Feld), grün markiert mit „PATROL LEAD“, wartet auf den Spieler (Follow oder 3 s innerhalb von 1.000 km), dann „Patrol departing“ und ihre Runden; „Follow“ wie beim Konvoi (auch im Warp). 3 Minuten innerhalb von 10.000 km mitfliegen; wird die Gruppe zerstört, scheitert der Auftrag.
- [x] **Schmuggler abfangen** (ab Neutral): ein nicht registrierter Hollow-Crown-Frachter taucht im Zielsystem (bis 2 Sprünge) auf und flieht zum entferntesten Tor; vor dem Sprung oder binnen 20 min vernichten. Erledigt ihn jemand anderes, zählt es nur, wenn man ihn getroffen hatte.
- [x] **Jagd auf Berüchtigte** (ab Friendly): benannter Kapitän; 20.000 cr + halbes Kopfgeld + 10.000 je Stern, zusätzlich zum SWX-Bond. Scheitert, wenn jemand anderes ihn erwischt.

### Codex / Glossar (Paket 18)

- **Nachschlagewerk im Spiel** als eigener Reiter „Codex“ im Schiffsmenü, zusätzlich erreichbar über das Hauptmenü.
- **Kategorien:** History (Der Sprung, Expansion, The Severance, Dark Decades), Factions (die drei Mächte, Piratenfraktionen, Wappen und Beziehungen), Corporations (Charter-Häuser und ihre Services), The Cluster (Orte, Long Gate, Veil), Technology (Hyperraum, Sprungtore, Colossi, Scanner), Basics (Bonds, Ruf, Nicht-Feuer-Zonen, Fahndung).
- **Freischaltung:** Grundlagen von Anfang an; weitere Einträge beim Entdecken – erste Begegnung mit einer Fraktion, erster Colossus, erster Pirate Haven, erster berüchtigter Pirat. Hinweis „New Codex entry“ im HUD.
- **Darstellung:** englische Texte, Wappen und kleine Pixel-Art-Bilder; Querverweise zwischen Einträgen.
- **Technik:** Einträge als Daten in `data/codex.gd`; jedes spätere Paket ergänzt seine Einträge gleich mit.

**Umgesetzt (4. Nov 2026, alpha 0.3.18.9)** – Daten in `data/codex.gd`, Zustand in `scripts/core/codex.gd` (`GameState.codex`), Ansicht `scripts/ui/codex_view.gd`, 10 neue automatische Prüfungen, alle 365 bestanden:

- [x] 45 Einträge in sechs Kategorien (Basics, History, Factions, Corporations, The Cluster, Technology); Fraktions- und Konzerneinträge werden aus deren Daten erzeugt.
- [x] Reiter „Codex“ im Schiffsmenü; „Codex“ im Hauptmenü zeigt alles, was in irgendeinem Spiel entdeckt wurde (`user://codex.cfg`).
- [x] Freischaltung: Grundlagen von Anfang an; Geschichte beim ersten Andocken (Stationsarchive), Fraktionen bei der ersten Begegnung, Konzerne beim Nutzen ihres Dienstes, außerdem Colossi, Pirate Havens, Berüchtigte, Überfälle, Ionenwaffen, Warp, Tore, Bergbau.
- [x] Hinweis „📖 New Codex entry“ oben im HUD und im Log; ungelesene Einträge gelb, unentdeckte als „???“; Wappen-, Schiffs- oder Icon-Bild und „See also“-Querverweise.

### Ideen für später (zurückgestellt)

- **Schmuggel & Zoll:** Patrouillen scannen die Fracht, manche Waren sind je nach Fraktion verboten.
- **Grenzkonflikte:** In umstrittenen Systemen kämpfen Fraktionspatrouillen gegeneinander; wer hilft, gewinnt Ruf.
- **Fraktionsrümpfe:** bei hohem Ruf Fraktionsvarianten mit eigener Lackierung und leicht anderen Werten.
- **Dynamischer Piratendruck:** Wenn niemand jagt, wächst die Piratenpräsenz in einem System mit der Zeit.
- **Dynamisches Territorium:** Fraktionen erobern Systeme – frühestens nach Phase 1.

### Entscheidungen zu Teil 3

| Frage | Optionen | Vorschlag | Entscheidung |
| --- | --- | --- | --- |
| Namen, Themen und Farben der Fraktionen | Vorschlag übernehmen · eigene Namen | Cluster Assembly, Covenant of Return, Meridian Directorate (Farben siehe Welt & Hintergrund) | gesetzt |
| Beziehungen der Supermächte | alle neutral · eine Rivalität · alle verfeindet | Covenant und Assembly verfeindet, Directorate neutral zu beiden (leicht freundlich zur Assembly) | gesetzt |
| Territorium | fest aus dem Seed · dynamisch | In 0.5 fest, dynamisch später | gesetzt (dynamische Gebiete in eigener Phase für die BAckground Simulation) |
| Systeme pro Fraktion | gleich verteilt · ungleich | je Supermacht ca. 12–14, Piraten ca. 4–5, Rest umstritten | gesetzt&#32; |
| Konvois zwischen Systemen | echte Routen · nur lokal erzeugt | Echte Routen, außerhalb des Spielersystems grob simuliert | gesetzt (Änderung vielleicht in einem größerem Wirtschaftsupdate) |
| NPC-Limit pro System | 20 · 30–40 · 60 | ca. 30–40 aktive Schiffe | Bis jetzt ist die Belastung sehr gering daher würde ich es mal mit 60 versuchen.&#32; |
| Angriff auf Zivilisten | nur Ruf-Verlust · Ruf + Fahndung | Ruf-Verlust + Fahndungsstufe bei der kontrollierenden Fraktion | gesetzt |
| Startruf | alle neutral · Startfraktion wählbar | Neutral bei allen, leicht negativ bei den Piraten | gesetzt |
| Einlösung der Bonds | überall · nur im Gebiet des Ausstellers | Bei Sable Writ Exchange im Gebiet der ausstellenden Fraktion | gesetzt |
| Holo-Banner | alle Fraktionsstationen · nur große Stationen | Alle Fraktionsstationen, Größe nach Stufe | gesetzt |
| Kann der Spieler Pirat werden? | nein · über Piraten-Ruf | Über Piraten-Ruf: Haven-Zugang, Piratenmissionen (Ausbau später) | gesetzt |
| Nachrichten-Ticker | im HUD · nur an Stationen · beides | Kurzer Ticker im HUD, Archiv im Schiffsmenü | Kurzer Ticker im Ship Info Menü. Ausführlich in Staionen Einsehbar |
| Piratenfraktionen | Ashen Fang · Hollow Crown · The Severed · Free Captains | Ashen Fang + Hollow Crown (eine gewalttätig, eine wirtschaftlich); The Severed als spätere Erweiterung | Hollow Crown · The Severed · Free Captains (Free Captains ohne eigene Stationen und gebiet nur Piraten und später Anheuerbar als Begleitschiffe o.ä.) |
| Ursache des Bruchs | im Codex erklärt · Rätsel | Rätsel – wird später über Story und Endgame (Long Gate) aufgelöst | Unbekannt – die Story dreht sich um dieses Rätsel |
| Name des Sternhaufens | nur „the Cluster“ · Eigenname | Allgemein „the Cluster“, alter Katalogname nur im Codex | Gesetzt |
| Startgebiet des Spielers | Assembly · frei wählbar · neutrales Grenzgebiet | Grenzsystem der Assembly | In 0.5 Grenzsystem der Assembly, Später gibt es ein Intro system |
| Codex-Freischaltung | alles offen · durch Entdecken | Grundlagen offen, Rest durch Entdecken | gesetzt |
|  |  |  |  |

## Phase 0.5 Teil 4 – Module and Internal Ship Parts Rework (Plan)

Teil 4 baut das Ausrüstungssystem um: feinere Modulgrößen, Qualitätsstufen, Rümpfe mit eigenen Stärken statt fester S/M/L-Plätze, neue Modultypen, Drohnen und deutlich mehr Schiffe. Es folgt direkt auf Teil 3. Alte Spielstände müssen dafür nicht kompatibel bleiben (siehe Arbeitsweise) – der Umbau wird frei geplant, nötigenfalls wird neu angefangen.

| # | Arbeitspaket | Inhalt | Abhängig von |
| --- | --- | --- | --- |
| 19 | Größen- & Qualitätssystem – ✅ erledigt | Modulgrößen 1–10, Qualität F–A, Rumpfplätze mit Maximalgröße je Schiff | – |
| 20 | Neue Modultypen & Waffen – ✅ erledigt | Schild-Varianten + Schild-Downtime, Punktverteidigung, Schildtransfer, Frachtscanner, Sonnen-Sammler, Minenwerfer (4 Minen), Radarstörer | 19 |
| 21 | Energie-Management – ✅ erledigt | im Schiff festlegen, welche Module bei Strommangel zuerst abgeschaltet werden | 19 |
| 22 | Multi-Fokus – ✅ erledigt | größere Schiffe kämpfen gleichzeitig gegen mehrere kleine Ziele | 19 |
| 23 | Drohnen (vorgezogen aus dem Endgame) – ✅ erledigt | Drohnenhangar als Extraplatz der Basisklasse, Bergbau- und Kampfdrohnen | 19, 22 |
| 24 | Schiffsmanufakturen – ✅ erledigt | alle Manufakturen und ihre Schiffe besprechen; am Ende: Codex-Einträge und ein Wappen/Icon je Manufaktur | 19 |
| 25 | Neue Schiffe | in kleinen Schritten gebaut: 25a KHI-Bergbauschiffe (+ Grundgerüst), 25b Heavy Industry Ship mit Fertigungszeit und Bordmarkt, 25c ff. die weiteren Manufakturen; auch für NPCs und Piraten, fraktionsexklusive Schiffe | 19, 23, 24 |
| 26 | Stationstyp 0 | kleine Außenposten nur für S- und M-Schiffe, zusätzlich in allen Systemen | 25 |
| 27 | Ausrüster & Modulübersicht | Ausrüster neu gestaltet, Kurzbeschreibungen in der Modulübersicht, aktuelle Geschwindigkeit in der Schiffsinfo | 19, 20 |

### Module: Größe und Qualität (Paket 19)

- **Größenklassen 1 bis 10** statt S/M/L – Waffen nur **1 bis 4**. Das Modulsystem wird neu entworfen, alte Module werden nicht umgerechnet.
- **Qualitätsklassen F, E, D, C, B, A** – später im Endgame zusätzlich **S** und **S+**.
- **Schiffsmodulplätze ohne feste Größe S/M/L:** jeder Platz hat eine **Maximalgröße**, die je Schiff verschieden ist. Ein S-Schiff kann z. B. Engines 5 haben, ein anderes S-Schiff Engines 6, weil es eher darauf ausgelegt ist – so bekommt jeder Rumpf ein eigenes Profil.
- **Schiffsgröße S, M, L bleibt** als grobe Größenklasse, aber ohne direkten Einfluss aufs Gameplay – außer dass L-Schiffe nicht in Stationen vom Typ 0 landen können.

**Entwurf – abgestimmt am 4. Nov 2026:**

- **Modul = Familie + Größe + Qualität**, angezeigt z. B. „Pulse Laser 2 · C“. Die Familie legt die Art fest (Schadensart, Reichweite, Wirkung) und einen Größenbereich; Größe und Qualität skalieren die Werte über Kurven statt über feste Einzelmodule.
- **Größenbereiche:** Waffen 1–4 · Werkzeuge 1–4 (Strip Miner nur 3–4) · Hüllenpanzerung, Triebwerk, Reaktor, Verteiler, Tank 1–10 · Hyperantrieb 1–6 (Sprungklasse steigt mit der Größe) · Sensoren 1–8 · Optional 1–8 (Fracht bis 10).
- **Familien (aus den heutigen Modulen):** Waffen – Pulse Laser, Beam Laser, Photon Lance, Autocannon, Railgun, Mass Driver, Rockets, Torpedoes, Cruise Missiles, Ion (Piraten); Werkzeuge – Mining Laser, Ice Harvester, Strip Miner, Salvager, Repair Beam, Scanner, Analyzer, Survey, Prospector, Warrant, Interdictor; Kern – Panzerung Standard/Reflective/Ablative, Triebwerk Chemical/Ion/Plasma, Reaktor Fission/Fusion, Distributor, Tank, Hyperdrive, Sensoren Radar/Gravimetric/Tactical; Optional – Shield, Armor Plates, Cargo, Ore Hold, Afterburner, Shield Booster, Armor Repairer, Mining Upgrades, Survey Amplifier, Targeting, Fuel, Capacitor.
- **Größenkurven (Startwerte):** Leistung ∝ Größe^1,3 · Masse ∝ Größe^1,2 · Strom ∝ Größe^1,1 · Preis ∝ Größe^1,6.
- **Kleinere Module passen in größere Plätze**, größere nie in kleinere.
- **Qualität:**

| Qualität | F | E | D | C | B | A | S (Endgame) | S+ (Endgame) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Leistung | ×0,80 | ×0,88 | ×0,95 | ×1,00 | ×1,08 | ×1,16 | ×1,28 | ×1,40 |
| Masse | ×1,25 (schwerste) | ×1,10 | ×0,90 (leichteste) | ×1,00 | ×1,08 | ×1,08 (wie B) | offen | offen |
| Strom | ×0,94 | ×0,96 | ×0,98 | ×1,00 | ×1,04 | ×1,08 | ×1,12 | ×1,15 |
| Preis | ×0,55 | ×0,70 | ×0,85 | ×1,00 | ×1,40 | ×2,00 | – | – |

- **Bezug:** F–A kaufbar – Ausrüster führen F–C überall, B ab Stationsstufe 2, A ab Stufe 3 oder an Militärposten; Beute und Fertigung liefern zufällige Qualitäten; S/S+ nur im Endgame.
- **Masse** wirkt auf Unterlicht- und Warpgeschwindigkeit (heute schon über Schub ÷ Masse; Ausbau beim Schiffsumbau).
- **Schiffsplätze:** jedes Schiff hat eine Liste einzelner Plätze mit Typ und Maximalgröße – auch die Kernplätze (z. B. Triebwerk 4 bei der Dragonfly, 5 bei der Hornet). Die Plätze der Earthworks-Rümpfe werden Schiff für Schiff gemeinsam festgelegt.
- **Plätze der heutigen Rümpfe (abgestimmt, Feinschliff im Balancing):** W = Waffe, T = Werkzeug, O = Optional, Zahl = Maximalgröße; Kern = Panzerung / Triebwerk / Reaktor / Verteiler / Tank / Hyperantrieb / Sensoren.

| Schiff | Rolle | Waffen | Werkzeuge | Optional | Kern | Profil |
| --- | --- | --- | --- | --- | --- | --- |
| Dragonfly (S) | Scout | W1 W1 | T2 T2 T1 | O2 O2 O1 | 2/4/3/3/3/2/4 | schwache Waffen, starke Sensoren, viel Werkzeug |
| Hornet (S) | Jäger | W2 W2 W1 | T1 | O2 O2 O1 | 3/5/4/4/2/2/3 | bester S-Kämpfer, starkes Triebwerk, kleiner Tank |
| Mule (M) | Frachter | W2 W1 | T2 T1 | O6 O5 O5 O4 O3 O3 | 5/5/4/4/6/4/3 | große Optional-Plätze für Fracht |
| Drillhead (M) | Bergbau | W2 W1 | T3 T3 T2 T2 | O4 O4 O3 O3 | 4/4/5/4/4/3/5 | viele große Werkzeuge, gute Sensoren |
| Warden (M) | Kampffregatte | W3 W3 W2 W2 | T2 T1 | O5 O4 O4 O3 O2 | 6/6/6/6/4/4/5 | ausgewogener Kämpfer |
| Bastion (L) | Schwerer Kreuzer | W4 W4 W3 W3 W2 W2 | T3 T3 T2 T2 | O8 O7 O6 O6 O5 O4 | 9/8/9/9/7/6/7 | einziger Platz für 4er-Waffen |
| Carrion Crow (S) | Piraten-Raider | W2 W1 | T1 | O2 O1 | 3/4/3/3/2/2/2 | billig zusammengeflickt |
| Skiff (S) | Shuttle | – | – | O2 | 1/3/2/2/2/1/1 | schnell, wendig, unbewaffnet |
| Longhaul (L) | Massenfrachter | W2 | – | O9 O8 O8 O7 | 7/8/6/5/9/5/3 | riesige Fracht, träge |

- **Hyperantrieb ↔ Sprungklasse:** Größe 1–2 = Klasse 1, 3–4 = Klasse 2, 5–6 = Klasse 3.
- **Manufaktur:** Dragonfly, Hornet, Mule, Drillhead, Warden, Bastion, Skiff und Longhaul gehören zu **Earthworks** (alte Erd-Designs); der **Carrion Crow** wird Teil der Piraten-Werften („Flickwerk“).
- **Bisher nur von NPCs geflogene Schiffe (entschieden):**
  - **Carrion Crow:** bleibt das Standardschiff der Piraten; **kaufbar in Pirate Havens** mit Piraten-Ruf (Friendly).
  - **Skiff:** **kaufbar** – günstig, schnell, wendig, unbewaffnet, kleiner Laderaum; später Grundlage für Passagier-Aufträge.
  - **Longhaul:** **kaufbar**, teuer und träge – spätes Handelsschiff mit riesigem Laderaum, kaum Waffen, braucht selbst Begleitschutz.
  - **Patrouillen:** sobald die staatlichen Manufakturen da sind (Paket 24/25), fliegen sie die **Schiffe ihrer eigenen Fraktion**; bis dahin Earthworks-Rümpfe in Fraktionslackierung.
**Umgesetzt (4. Nov 2026, alpha 0.4.19.13)** – `data/modules.gd` (Familien, Kurven, Qualität), `slot_sizes` in `data/hulls.gd`, 14 neue automatische Prüfungen, alle 379 bestanden:

- [x] 53 Familien, alle Größen und Qualitäten erzeugt (ca. 1.700 Module, Anzeige „Pulse Laser 2 · C“); Werte über Größenkurven aus den alten Modulen als Ankerpunkten.
- [x] Qualität F–A mit Leistungs-, Strom-, Preis- und Massefaktoren (D leichteste, F schwerste, B = A an Masse).
- [x] Plätze aller neun Rümpfe einzeln nach der Tabelle; kleinere Module passen in größere Plätze; Hyperantrieb-Größe bestimmt die Sprungklasse.
- [x] Ausrüster nach Stationsstufe (Größen-Obergrenzen, B ab Stufe 2, A ab Stufe 3/Militär), Fertigung mit gewürfelter Qualität, Beute in allen Qualitäten, Militär-Ausrüstung (größte Module) ab Friendly.
- [x] Standardfits, NPC- und Piraten-Loadouts sowie das Startlager auf das neue System umgestellt.
- [x] Skiff und Longhaul an Werften kaufbar, Carrion Crow in Pirate Havens.
- [x] Modul-Reiter zeigt Maximalgröße je Platz und Größe/Qualität je Modul; Ausrüster gruppiert nach Familie mit Größe·Qualität-Knöpfen (Feinschliff in Paket 27).
- [x] Spielstand-Version 2: ältere Spielstände werden mit Hinweis abgelehnt und nicht mehr bei „Continue“ angeboten.

- **Umfang Paket 19:** neues Datenmodell, Plätze der Earthworks- und NPC-Rümpfe, Ausrüster/Fertigung/Beute/NPC-Loadouts/Startschiff umgestellt, neue Spielstand-Version (alte Stände mit Hinweis abgelehnt). Neue Modultypen erst in Paket 20.

### Neue Modultypen und Waffen (Paket 20)

- **Verschiedene Schilde:** manche mit mehr Kapazität, andere mit höherer Ladegeschwindigkeit.
- **Minenwerfer:** hinterlässt verschiedene Arten von Minen:
  - **Annäherungsminen** – explodieren, wenn ein Schiff nahe kommt.
  - **Radarstörer-Minen** – stören das Radar in ihrem Umkreis.
  - **Zeitauslöser** – explodieren nach einer eingestellten Zeit.
  - **EMP-Minen** – legen Schilde, Energie und Module kurzzeitig lahm.
- **Radarstörer (Modul):** schaltet die Radaransicht aus, sodass nicht mehr angezeigt wird, wo sich Feinde befinden. Wirkt auf Gegner im Umkreis – und Gegner setzen ihn auch gegen den Spieler ein.
- **Zusätzlich (5. Nov 2026 festgelegt):** Punktverteidigung, Schildtransferstrahl (überträgt Energie aus dem eigenen Energiespeicher – nicht aus dem eigenen Schild – und verbraucht nur Energie, solange er aktiv überträgt), Frachtscanner, Sonnen-Sammler. Fern-Reparatur kommt als Reparatur-Drohnen in Paket 23.
- **Schild-Downtime:** wird ein Schild komplett abgeschossen, bleibt er eine Zeit lang aus – abhängig von maximaler Schildmenge, Schildart und Qualität – und startet danach mit 50 %. Gilt für alle Schiffe (auch NPCs und Gegner); der Schildtransferstrahl verkürzt die Downtime.

**Umgesetzt (5. Nov 2026, alpha 0.4.20.1)** – 8 neue Familien in `data/modules.gd`, Minen in `scripts/world/mine.gd`, 31 neue automatische Prüfungen, alle 436 bestanden:

- [x] Schild-Varianten: Shield Generator (ausgewogen), Capacitive Shield (mehr Kapazität, langsame Ladung), Fast-Cycle Shield (weniger Kapazität, schnelle Ladung).
- [x] Schild-Downtime für alle Schiffe: Artfaktor (1,0 / 1,35 / 0,6) ÷ Qualität × (4 + √max. Schild / 3) s, 3–60 s; danach 50 %; Schild-Booster helfen nicht, Schildtransfer lässt sie 3× so schnell ablaufen. Anzeige „SHIELD DOWN“ im Schiffspanel, auf Ziel- und Verbund-Kacheln und in der Auswahl; Downtime in der Schiffsinfo.
- [x] Punktverteidigung (Waffenplatz, 1–3): eingeschaltet schießt sie feindliche Raketen, Torpedos (auch Ionen-Torpedos) und Minen in Reichweite selbst ab; zählt nicht als Kanone; Patrouillen haben sie teils dabei.
- [x] Schildtransferstrahl (Werkzeug, 1–3): auf ein anvisiertes befreundetes Schiff, Energie aus dem eigenen Speicher, nur während er überträgt; NPC-Patrouillen nutzen ihn untereinander.
- [x] Frachtscanner (Werkzeug, 1–2): liest die Ladung eines anvisierten Schiffs; Schmuggler zeigen „unregistrierte Ladung“; ein Teil der Piratenladung bleibt im Wrack.
- [x] Sonnen-Sammler (optional, 1–4, passiv): tankt im All nach – voll bis 4 Sternradien, danach mit dem Quadrat der Entfernung schwächer.
- [x] Minenwerfer (Waffenplatz, 1–3): legt Minen aus dem Frachtraum hinter das Schiff; Rechtsklick auf die Kachel wählt Art und Zeitzünder (5–60 s); 3/6/9 Minen gleichzeitig, verschwinden nach 5 min, treffen nur Feinde. Minen als Ware bei Militär, Werften und Piratenbasen: Annäherung, Zeitauslöser, Radarstörer (6.000 km, 45 s), EMP (Schild bricht zusammen, Energie und Module 8 s tot).
- [x] Radarstörer (optional, 1–4, aktiv): Feinde im Umkreis verlieren das Radarbild und erfassen/feuern nur noch auf halbe Sensorreichweite; etwa jeder fünfte Pirat setzt ihn gegen den Spieler ein (Rauschen und „RADAR JAMMED“ im Radar, Kontaktliste nur bis 3.000 km, Locks halb so weit).
- [x] Ausrüster führen die neuen Module automatisch; Beschreibungen und Icons für alle neuen Module.

### Energie-Management (Paket 21)

- Im Schiff einstellen, **welche Module abgeschaltet werden, wenn zu viel Strom verbraucht wird** (Prioritätenliste).
- **Festgelegt (5. Nov 2026):** Der Energieoutput ist eine harte Grenze. Module kommen in Prioritätsgruppen 1–4 (4 = niedrigste); bei Überlast wird Gruppe 4 abgeschaltet, danach 3 usw. Waffen und aktive Module verbrauchen nur Energie, wenn sie benutzt werden – passive Module, Kernmodule und Scanner immer; angezeigt werden passiver und aktiver Verbrauch. Im Schiffsmenü unter Ausrüstung ein Reiter Energiemanagement: Balken mit dem maximalen Output und dem Anteil jeder Gruppe, darunter alle Module mit Icon, Name, Qualität, aktiv/passiv und einstellbarer Priorität.

**Umgesetzt (5. Nov 2026, alpha 0.4.21.1)** – Strommodell in `ShipFitting` (`power_plan`, `priorities`), Laufzeit in `Ship._update_power`, 10 neue automatische Prüfungen, alle 446 bestanden:

- [x] Harte Grenze: nutzbarer Output = Reaktor × Verteiler-Effizienz, wird nie überschritten.
- [x] Passiv (Kern, passive optionale Module, Scanner) zieht immer; aktiv (Waffen, Punktverteidigung, Minenwerfer, Werkzeuge, aktive optionale Module) nur in Benutzung. NPCs: Waffen im Kampf, Strahlen immer, Störsender beim Stören.
- [x] Prioritätsgruppen 1–4 (Vorgabe: Kern 1, Waffen/Schilde 2, Werkzeuge/aktive 3, Rest 4); bei Überlast schaltet Gruppe 4 ab, dann 3, dann 2; Gruppe 1 bleibt an (nur wenn sie allein zu viel ist, wird gedrosselt). Abgeschaltete passive Module wirken nicht, abgeschaltete aktive bleiben an, aber ohne Wirkung (rote Kachel), bis wieder Strom da ist; Meldungen im Chat.
- [x] Schiffsmenü → Modules → POWER MANAGEMENT: Balken je Gruppe (passiv kräftig, aktiv hell, weiße Linie = Output), Vorschau „ohne aktive Module“ / „alles an“, Modulliste mit Icon, Name, Größe · Qualität, aktiv/passiv, MW und Prioritätsknöpfen 1–4. HUD-Zeile „Power x / y MW (passive + active)“ mit abgeschalteten Gruppen.
- [x] Module ohne Stromverbrauch stehen in Gruppe 0 (keine Knöpfe); der Balken zeigt je Gruppe einen zusammenhängenden Block (alpha 0.4.21.2).
- [x] Prioritäten werden mit dem Schiff gespeichert; alle Standard- und NPC-Ausrüstungen laufen auch mit allem eingeschaltet unter der Grenze.

### Multi-Fokus (Paket 22)

- **Multi-Fokus-Möglichkeit**, damit größere Schiffe gleichzeitig gegen mehrere kleine Schiffe kämpfen können.
- **Zieltasten (5. Nov 2026 festgelegt):** Tab schaltet durch alle Ziele in Sensorreichweite, eine eigene Taste durch feindliche, eine durch verbündete Ziele.

**Umgesetzt (5. Nov 2026, alpha 0.4.22.1)** – 15 neue automatische Prüfungen, alle 462 bestanden:

- [x] Jede Waffe und jedes Werkzeug behält das Ziel, das beim Einschalten aktiv war; mehrere aktive Ziele gleichzeitig. Taste eines laufenden Moduls mit anderem Ziel → wechselt auf das aktive Ziel, nochmal → aus. Verlorener Lock schaltet nur die Module darauf ab.
- [x] Fehlerbehebung (0.4.22.4): ein neu erfasstes Ziel wird sofort das aktive (laufende Module auf dem alten werden gelb); verlässt ein Ziel die Sensorreichweite oder verschwindet im Radarschatten, bleiben die Module darauf an (orange) und das Ziel wird automatisch neu erfasst, sobald es zurück ist (bis 60 s) – vorher schalteten sie ab und feuerten nicht wieder.
- [x] Lock-Plätze nach Sensorgröße: 3 (Größe 1–2), 4 (3–4), 5 (5–6), 6 (7–8).
- [x] Modulkacheln eingefärbt: grün = aktiv auf dem aktuellen Ziel, gelb = aktiv auf einem anderen Ziel, orange = außer Reichweite (0.4.22.3). Balancing: alle Waffenreichweiten +10 %, Sensorreichweiten +15 % (0.4.22.3).
- [x] Anzeige: Modulkacheln zeigen ihr Ziel (T1, T2 …), Lock-Karten und Zielklammern im All Lock-Nummer und Zahl der Module darauf.
- [x] NPCs: größere Schiffe (Rumpf M+, ab drei Waffen) verteilen ihre Waffen auf mehrere Feinde in der Nähe ihres Ziels.
- [x] Zieltasten: Tab = alle Ziele in Sensorreichweite – erst die Schiffe, dann Asteroiden, Wracks, Anomalien; ohne Auswahl beginnt es wieder bei den Schiffen (0.4.22.2) – V = feindliche, C = verbündete Schiffe (in Sensorreichweite, sonst bis 50.000 km), jeweils nächstes zuerst; gespeicherte alte Belegungen dieser Tasten werden einmalig auf die neuen Vorgaben gesetzt.

### Drohnen (Paket 23, vorgezogen aus dem Endgame)

**Festgelegt (5. Nov 2026):** Drohnenhangar als neues Kernmodul (Größe 1–9, Qualität = mehr Lagerplatz); wie viele Drohnen gleichzeitig fliegen, legt das Schiff fest (S 1 … L 9). Drei Ausstattungsplätze für alle Drohnen: Waffe (Größe 1), Bergbaulaser (Größe 1), Bonusplatz für Drohnenmodule. Eine Drohnensorte, Rolle (Kampf/Bergbau/Reparatur) jederzeit per Kachel umschaltbar, je Rolle Verhalten (Kampf: verteidigen, Ziel angreifen, Fire at will, ruhen; Bergbau: auto, Ziel, ruhen; Reparatur: auto, Ziel, nur Verbündete, nur selbst, ruhen) und „Zurückrufen“. Drohnen: schwach, 5 Lagerplatz, feste Treibstoffmenge (ca. 5 min, Leerlauf 0,8×, im Hangar kein Verbrauch, nicht auftankbar), 9.000 km Steuerreichweite. Beim Warp-Laden/Sprung in den Hangar, danach sofort wieder raus. Neue Firma verkauft Drohnen als eigenen Service in allen Stationen. Schlichtes Design mit Antriebsspur, Waffen feuern wirklich, Bergbaulaser wie beim Schiff.

**Umgesetzt (5. Nov 2026, alpha 0.4.23.1)** – `scripts/world/drone.gd`, Drohnenfenster im HUD, Drone Bay (`drone_panel.gd`), 31 neue automatische Prüfungen, alle 498 bestanden:

- [x] Kernplatz „Drone Hangar“ (Größe 1–9 je Rumpf, Lagerplatz = Größe × 3 × Qualitätsfaktor 0,6–1,5); Drohnen gleichzeitig: Dragonfly/Hornet/Crow/Skiff 1, Mule 3, Drillhead/Warden 4, Longhaul 5, Bastion 9.
- [x] Ausstattungsplätze Waffe (Größe 1), Bergbaulaser/Eisernter (Größe 1), Bonus (Drohnenmodule: Relay, Cargo Pod, Armor, Shield Emitter, Weapon Booster, Targeting Array, Fuel Cell, Thrusters – Größe 1–3, Qualität F–A); keine Schiffswaffe, kein Schiffsstrom. Standardausrüstungen mit Pulse Laser und Bergbaulaser, Startschiff mit zwei Drohnen.
- [x] Drohne: 60 Hülle, 5 m³, 520 km/s, 5 min Treibstoff (Leerlauf 0,8×, Arbeit 1×, Kampf 1,2×), 9.000 km Steuerreichweite; außerhalb: zurück, Ziel fallen lassen; leer oder zerstört = verloren (kein Wrack). Feuert ihre echte Waffe, Bergbau mit demselben Strahl wie das Schiff, Antriebsleuchten.
- [x] Alle Rollen und Verhalten wie festgelegt; Reparatur mit eingebautem Strahl; „Fire at will“ greift auch Zivilisten an (Straftat), Verbündete bleiben verschont.
- [x] Drohnenfenster oben links am Rand: eingeklappt ohne gestartete Drohnen, sonst Rollen-Kacheln, Verhaltensknöpfe, Treibstoff/Hülle je Drohne, Starten/Zurückrufen. Tasten K (starten) und P (zurückrufen).
- [x] Warp-Ausrichten/Sprungantrieb: Drohnen fliegen in den Hangar und kommen danach sofort wieder heraus; zu weit entfernte bleiben zurück. Andocken nimmt sie auf.
- [x] Drone Bay der Hivewright Drone Works in jeder Station: kaufen, gebrauchte verkaufen, Hüllen reparieren (Treibstoff nicht nachfüllbar). Hangars und Drohnenmodule beim Ausrüster.
- [x] Schiffsmenü → Modules: eigene Kategorie „Drone hangar – equipment for all drones“ mit den drei Ausstattungsplätzen; Icons für Drohnenhangar und Drohnenmodule (0.4.23.2).
- [x] Ruhende Drohnen fliegen symmetrisch: gespiegelte Paare links und rechts, Reihe für Reihe weiter hinten, eine ungerade Drohne exakt auf der Mittelachse dahinter; in Position mit demselben Kurs wie das Schiff (0.4.23.3).
- [x] K startet je Druck eine Drohne (bis zum Maximum); „Alle Drohnen starten“ als eigene Aktion ohne Standardtaste, in den Einstellungen belegbar (0.4.23.4).
- [x] Test-Stabilität: der Kampftest wartet nur noch auf den eigenen Piraten und nimmt ihm den Radarstörer.

- **Drohnenhangar** wird dem Schiff zugewiesen – als **Extramodul in der Basisklasse**; Größe und ob überhaupt vorhanden hängen vom Schiff ab.
- **Bergbaudrohnen** und **Kampfdrohnen**.

### Schiffsmanufakturen (Paket 24)

- **Earthworks:** die bisherigen Schiffe (Dragonfly, Hornet, Mule, Drillhead, Warden, Bastion …) – noch auf der Erde entwickelt, gemeinsame Designsprache.
- **Spezialisierung:** jede Manufaktur hat einen Schwerpunkt (Bergbau, Kampf …), aber nicht strikt – z. B. hat die Bergbaufirma auch ein Schiff, das gut als Frachter taugt.
- **Verschiedene Firmen stellen verschiedene Schiffe her** – jede Manufaktur mit eigener Designsprache und eigenem Schwerpunkt.
- **Fraktionsschiffe kommen über die Manufakturen ins Spiel:** jede große Fraktion (Assembly, Covenant, Directorate) hat eine eigene, staatlich geführte Schiffsmanufaktur mit mehreren Schiffen.
- Zu klären, bevor gebaut wird (siehe offene Fragen):
  - **Wie viele Schiffe** es geben soll und **von wie vielen Manufakturen**.
  - **Wie sie unterschiedlich aussehen:** Ideen – eigene Silhouetten-Bausteine je Manufaktur im Pixel-Art-Generator (Rumpfform, Flügel, Triebwerke, Cockpit), eigene Farbpaletten und Muster, Markenzeichen (z. B. Leuchtstreifen, Panzerrippen, Antennen), Firmenlogo auf dem Rumpf.
  - **Wie sie sich unterschiedlich anfühlen:** Ideen – feste Stärken je Manufaktur (z. B. mehr Platz für Triebwerke, große Schildgeneratoren, viele Waffenplätze, Drohnenhangar), Fahrverhalten (Beschleunigung, Wendigkeit, Trägheit), Energiehaushalt, Signatur; dazu eigene Triebwerksspuren und Sounds.

#### Steckbriefe der Manufakturen (für Pakete 24/25 und den Codex)

Vorgehen (5. Nov 2026 vereinbart): **Paket 24 = Planung.** Alle Manufakturen und ihre Schiffe werden nacheinander besprochen (Idee → Steckbrief hier → Freigabe). Zum Abschluss von Paket 24 werden die Manufakturen in den Codex eingebaut und jede bekommt ein Wappen/Icon. **Paket 25 = Bau in kleinen Schritten:** 25a KHI-Bergbauschiffe samt Grundgerüst (Rumpf gehört zu einer Manufaktur, Werften nach Manufaktur-Regeln, Pixel-Art-Bausteine und Palette je Manufaktur), 25b Heavy Industry Ship mit Fertigungszeit und Bordmarkt, 25c ff. die weiteren Manufakturen. Versionen laufen als 0.4.25.N weiter, der Teilschritt steht im Changelog.

**Earthworks** (bestehende Schiffe)
- **Geschichte:** gegründet 12450 HE auf der Erde – die erste große nicht staatliche Sternschiffmanufaktur. Ihre Schiffe ermöglichten die Erkundung der Galaxie und später die Besiedlung des Clusters. Bis kurz vor der Severance die einzige Sternschiffmanufaktur, mit nur einem Shipyard Complex im Orbit von Luna (Sol). 12696 HE entstand eine zweite Werft im Cluster; 12701 HE erlaubte die Erdregierung weitere Sternschiffmanufakturen (zwölf Jahre vor der Severance 12713 HE).
- **Design:** schlicht und praktisch – „das Basic-Erddesign“. Technisch weiterentwickelt, im Großen aber seit den 12450er Jahren unverändert: zeitloses Design, großartige Ingenieurskunst.
- **Schwerpunkt:** etwas für jeden – grundlegend Allrounder, dazu speziellere Schiffe wie Mule und Longhaul.
- **Schiffe:** alle bisherigen Schiffe im Spiel außer den speziellen Piratenschiffen – Dragonfly, Hornet, Mule, Drillhead, Warden, Bastion, Skiff, Longhaul (die Carrion Crow ist Piratenbau). Das bisherige, einheitliche Design ist genau die Earthworks-Designsprache.
- **Heute:** unabhängige Megacorp. Earthworks-Schiffe gibt es an den allermeisten Werften.
- **Codex (später):** eigener Eintrag „Earthworks“ mit der Geschichte oben, Querverweise auf „The Expansion“ und „The Severance“; freigeschaltet beim ersten Besuch einer Werft.
- **Später:** Führungspersonen kommen mit Teil 5 (Character Update), der feste Standort der Cluster-Werft von 12696 mit Teil 6 (feste Sternensysteme – auch für Fraktionshauptsitze und weitere Orte).

**Kanayama Heavy Industries (KHI)** – Bergbau- und Industriemanufaktur
- **Name & Motto:** benannt nach Kanayama-hiko, im Shinto der Gott der Bergwerke und der Metallverarbeitung. Motto: *„We dig deeper.“*
- **Geschichte:** gegründet 12701 HE im Cluster (im Jahr der Freigabe weiterer Manufakturen), als der Bergbau-Boom die Nachfrage nach schwerer Maschinerie hochtrieb – die Stationen kamen mit dem Raffinieren nicht mehr hinterher, neue Lösungen mussten her.
- **Schwerpunkt:** Bergbau- und Industrieschiffe.
- **Design:** erinnert an schwere Maschinen – bullig, praktisch statt schön. Farben hauptsächlich Gelb und die anderen Farben von Baustellenfahrzeugen (Warnstreifen Schwarz-Gelb, Orange, Grau). Läuft die Bordraffinerie, stößt das Schiff schwarze Rauchwolken aus.
- **Markenzeichen aller KHI-Schiffe:**
  - **Bordraffinerie** (fest im Rumpf): verarbeitet nebenbei langsam Erz aus dem Erzlager zu Raffinat im Frachtraum; zieht Strom, solange sie läuft, und lässt sich abschalten (z. B. um Erz roh zu verkaufen). Tempo: S ≈ 1/10, M ≈ 1/6, L ≈ 1/4 einer Stationsraffinerie, Heavy Industry Ship ≈ wie eine Station.
  - **Eingebautes Erzlager** und **+10 % Abbau-Effizienz**.
  - **Träge:** −25 % Drehgeschwindigkeit, +40 % Ausrichtzeit für den Warp (Heavy Industry Ship noch etwas mehr).
  - **Harte Hülle, große Schilde, wenig Bewaffnung.**
- **Verkauf:** KHI-Werften an Industriekomplexen und Shipyard Complexes. Mining Colonies bekommen eine kleine Werft: nur KHI S und M, dazu als günstigere Variante der Earthworks Drillhead.

**Bauplan KHI (Vorschlag 5. Nov 2026, zur Freigabe)**

| Schiff (Arbeitsname) | Größe | Waffen | Werkzeuge | Optional | Drohnen (Hangar max.) | Eingebaut |
|---|---|---|---|---|---|---|
| **Mogura** („Maulwurf“) – S-Bergbauschiff | S | [1] | [2, 1, 1] | [2, 2, 1, 1] | 1 (Hangar 1) | Raffinerie 1/10, Erzlager 60 m³, Prospektor-Scanner |
| **Anaguma** („Dachs“) – M-Bergbauschiff | M | [2, 1] | [3, 3, 2] (Strip Miner, Eisernter) | [5, 4, 3, 3] | 2 (Hangar 3) | Raffinerie 1/6, Erzlager 300 m³, Prospektor |
| **Iwakudaki** („Felsbrecher“) – L-Bergbauschiff | L | [2, 2] | [4, 4, 3, 3] | [7, 6, 5, 4] | 4 (Hangar 5) | Raffinerie 1/4, Erzlager 900 m³, Prospektor |
| **Kanayama-maru** – Heavy Industry Ship | L | [2, 2] | [3, 3] | [8, 7, 6, 5] | 9 (Hangar 9) | Raffinerie ≈ Station, Erzlager 1.200 m³, Fertigungsanlage, Markt |

- **Heavy Industry Ship:** seine Drohnen bekommen +25 % Abbau-Effizienz und +5 m³ Lagerplatz und tragen einen gelben Anstrich. **Fertigung an Bord** wie der Manufacturing-Dienst der Stationen, dazu Drohnen als neues Rezept; zieht Strom, solange sie läuft. **Neu für alle Fertigungen (auch Stationen): jeder Bauplan braucht Zeit.** **Markt:** man stellt Waren und Preise ein; solange das Schiff stillsteht, fliegen zivile NPC-Händler aus dem System es an und kaufen; große Angebote locken mit höherer Wahrscheinlichkeit Piraten an.
- **Grundgerüst (Paket 24, mit KHI gebaut):** jeder Rumpf gehört einer Manufaktur (bisherige = Earthworks, Carrion Crow = Piratenbau); Manufaktur-Daten (Name, Kürzel, Farbe, Palette, Motto, Geschichte); Werften führen Schiffe nach Manufaktur-Regeln; Pixel-Art-Bausteine und Palette je Manufaktur; Werft-Anzeige mit Manufaktur; Codex-Einträge je Manufaktur.

**Maison Aurelle (AUR)** – Luxus- und Passagiermanufaktur
- **Name & Motto:** „aurum“ = Gold. Gründerin und Betreiberin: **Ivoire Maison** (Figur für Teil 5). Motto: *„Arrive in style.“*
- **Geschichte:** die jüngste Manufaktur im Cluster, gegründet 12895 HE – möglich geworden durch den Wirtschaftsboom der Cluster Assembly der letzten Jahre. Eng mit der Assembly verbunden, aber eine unabhängige Megacorp. Profitiert stark vom Export an reiche Oligarchen im Covenant, wo ihre Schiffe als Statussymbol gelten – dort wird gern verschwiegen, dass die Gründerin und Betreiberin der Assembly angehört.
- **Schwerpunkt:** Luxusliner und Personentransport, später auch Rennschiffe (eigene Mechanik, späteres Update).
- **Design:** äußerst schick und geleckt, besonders die teuren Liner – Vorbild Luxus-Kreuzfahrtschiffe: lange, glatte, helle Rümpfe (Weiß/Elfenbein mit Gold- oder Champagner-Akzenten), Fensterreihen, elegante Linien. Die Schiffe sollen sich luxuriös anfühlen und sind besonders teuer.
- **Neue Mechanik – Personentransport:**
  - Neue Module (optional): **Passagierkabinen** in den Klassen **Bulk**, **Business** und **Luxus**. Kapazität hängt von der Modulgröße ab und wird durch die Qualität erhöht. Bulk und Business passen in alle Schiffe, **Luxus nur in Schiffe dieser Manufaktur**.
  - Neuer Reiter **Transportaufträge** am Missionsbrett: **Bulk** (viele Leute von Station zu Station) sowie **Business** und **Luxus**, die die passende Klasse verlangen.
  - Bulk-Aufträge nimmt man an, bis die Gesamtkapazität aller Bulk-Kabinen voll ist. Business- und Luxus-Aufträge verlangen jeweils eine eigene Kabine dieser Klasse, in die die ganze Gruppe passt (bestätigt).
  - **Bezahlung** pro Passagier und Sprung: Bulk ≈ 60 cr, Business ≈ 220 cr, Luxus ≈ 700 cr (Boulevard −20 % auf Luxus, Empress +25 %). Jeder Auftrag hat eine **Frist**; wird das Schiff mit Passagieren zerstört oder die Frist verpasst, scheitert der Auftrag mit etwas Rufverlust bei der Fraktion der Startstation.
  - Wird in Teil 5 (VIP-Transporte) und Teil 6 (Tourismus) noch mehrfach erweitert.
  - Später: Touristen-Aktionen, im Character Update VIP-Transporte in den höheren Klassen.
- **Schiffe (Vorschlag mit Arbeitsnamen):**

| Schiff | Größe | Waffen | Werkzeuge | Optional | Drohnen | Fluggefühl & Besonderheiten |
|---|---|---|---|---|---|---|
| **Boulevard** – Linienschiff | M | [2, 2, 1] (mittel) | [1] | [5, 4, 4, 3] | 1 (Hangar 2) | viel Triebwerksleistung, kurze Warp-Ausrichtzeit; eingebauter Nachbrenner (ohne Platz); Luxuskabinen möglich, aber −20 % Bezahlung. Fliegt in wohlhabenden Systemen auch als NPC-Shuttle zwischen Stationen |
| **Pearl** – kleiner Luxusliner | S | [1, 1] | – | [3, 2] | – | äußerst schnell; Luxuskabinen, eingebauter Nachbrenner |
| **Opal** – mittlerer Luxusliner | M | [2, 1] | [1] | [5, 5, 4, 4, 3] | – | äußerst schnell für seine Größe; Luxuskabinen, Nachbrenner |
| **Empress** – Megaliner (Kreuzfahrtschiff) | L | [3, 3, 2] (mittel) | [1] | [9, 9, 8, 8, 7, 6] | 4 (Hangar 5) | wenig wendig, aber kurze Warp-Ausrichtzeit und hohe Warpgeschwindigkeit; hohe Schildkapazität; Luxuskabinen mit Bonus (+25 %) auf Luxus-Aufträge; Frachterweiterungen nur mit 50 % Kapazität. Drohnen im weißen Aurelle-Stil mit eigenem Schild, den das Schild-Bonusmodul verstärkt |

- **Preise:** etwa das 2,5-Fache eines Earthworks-Schiffs gleicher Größe.
- **Verkauf:** Werften der Handelsstationen in reichen, sicheren Systemen – im Gebiet der Assembly und des Covenant; im Directorate keine.
- **Eingebauter Nachbrenner:** wirkt wie das Nachbrenner-Modul, belegt aber keinen Platz; eigene Kachel in der Modulleiste, verbraucht Energie, solange er an ist.

**Hadrian Dynamics (HDY)** – Kampfschiff-Manufaktur
- **Name & Motto:** *„Deterrence is a product.“* Hervorgegangen aus der Waffenschmiede **Hadrian Ordnance** und dem Rumpfbauer **Castellan Hullworks**. Gründer: **Erik Martin**; heute führt sein Sohn **Erik Martin Jr.** die Firma – er gilt als der reichste Mann des Clusters (Figuren für Teil 5).
- **Geschichte:** die umstrittenste Manufaktur im Cluster. Nach der Severance (12713 HE) versank der Cluster im Chaos, lange bürgerkriegsähnliche Zustände folgten – Waffenmanufakturen wie Hadrian Ordnance wurden steinreich. Erik Martin läutete zugleich das Ende der Dark Decades ein: Er entdeckte die Möglichkeit wieder, Nuklearwaffen zu bauen, und erzwang um **12748 HE** durch nukleare Abschreckung den ersten Waffenstillstand zwischen den gerade entstandenen, miteinander im Krieg liegenden Fraktionen Assembly und Covenant. Um **12790 HE** fusionierte Hadrian Ordnance mit Castellan Hullworks zu Hadrian Dynamics, Erik Martin wurde ihr Chef, und die Firma begann, eigene Schiffe zu entwickeln.
- **Schwerpunkt:** Kampfschiffe – stark im Kampf, schwach in allem anderen.
- **Design:** brutalistisch und gefährlich: massive, kantige Panzerblöcke, dunkle Metalle, wenige Lichter, Waffen gut sichtbar. Eigene Interpretation – kein Nachbau fremder Schiffe.
- **Markenzeichen aller HDY-Schiffe:**
  - **Reflektierende Schiffshülle:** ein Teil des Schadens, der auf die Panzerung trifft, geht an den Angreifer zurück – S 10 %, M 15 %, L 20 % (Schilde reflektieren nicht). M und L dazu +20 % Explosivresistenz.
  - **Schwach außerhalb des Kampfs:** kaum Werkzeugplätze (S 0, M/L 1), kleiner Frachtraum, kein Erzlager, −50 % auf Abbau, Bergung und Analyse, hohe Signatur (leicht zu erfassen und zu scannen).
- **Schiffe (Namen freigegeben):**
  - **Talon** – Dropship (S): schnell, gut bewaffnet, starke Schilde, kein Drohnenhangar; erhöhte Feuerrate für Torpedos und Raketen.
  - **Maul** – Kanonenboot (M): schnell, gut bewaffnet, kleiner Drohnenhangar (2); als einziges M-Schiff später Langstrecken- und Nuklearraketen.
  - **Goliath** – Destroyer (M): schnell, Bewaffnung eines L-Kampfschiffs, Drohnenhangar 5; eingebaute Punktverteidigung; später Langstrecken- und Nuklearraketen. Design: zwei mächtige Waffenarme.
  - **Citadel** – kleiner Flottenträger (L): durchschnittliche Bewaffnung, großer Drohnenhangar (9); eingebaute Punktverteidigung; später Langstrecken- und Nuklearraketen. **Für Teil 5 vormerken:** Hangar auf der Oberseite für ein S-Schiff, das später wie Drohnen gestartet werden kann.
- **Verkauf:** überall; die größeren Schiffe (Goliath, Citadel) nur an Militärstationen und in Hightech-Wirtschaften (bis Teil 6: Shipyard Complexes und Stationen der Stufe 3; „Hightech-Wirtschaft“ wird mit der Wirtschafts-Überarbeitung in Teil 6 neu festgelegt). **Piraten** fliegen heruntergekommene Varianten der HDY-Schiffe – aber nie die Goliath.
- **Später:** Langstreckenraketen (Recon-Reichweite) und Nuklearraketen sind eigentlich für künftige XL- und XXL-Schiffsklassen geplant (viel später) – dass HDY-Schiffe sie tragen können, ist ihre Besonderheit. Nuklearwaffen: schweres Verbrechen in allen Fraktionsgebieten, nur über den Schwarzmarkt, großer Flächenschaden.

#### Staatliche Manufakturen (Fraktionsschiffe: normale Modelle ab Neutral, Spitzenmodelle ab Allied, nur an Werften der Fraktion)

**Concord Fleetworks (CFW)** – staatliche Manufaktur der Cluster Assembly
- **Name:** „concord“ = Eintracht – der Kompromiss nach den feindseligen Debatten. Schiffsnamen nach griechischen und römischen Gestalten, die für das Volk stehen.
- **Geschichte:** Als sich der Krieg legte, mussten nach Jahrzehnten des Bürgerkriegs viele alte Earthworks-Schiffe der Assembly ausgemustert oder modernisiert werden. Die Regierung wollte Earthworks zuerst verstaatlichen; nach langen, feindseligen Debatten bot sie stattdessen eine Kooperation bei der Entwicklung neuer Schiffe an. Zusammen mit **Hivewright Drone Works** entstand **12755 HE** Concord Fleetworks – ein Gemeinschaftsunternehmen von Assembly, Earthworks und Hivewright.
- **Grundsätze:** Die Assembly will das Leben ihrer Bürger schützen – darum **gute Schilde und Drohnen**. CFW-Schiffe sind im Endeffekt Drohnenträger: die Drohnen kämpfen, die Pilotin bleibt hinter starken Schilden.
- **Design:** nah an Earthworks, aber moderner, mit deutlich sichtbaren Drohnenhangars (Hangartore, Startbuchten). Flaggschiff als langer Träger mit vielen Hangaröffnungen – eigene Gestaltung, kein Nachbau fremder Schiffe.
- **Markenzeichen aller CFW-Schiffe:**
  - **Drohnen:** Hülle, Schaden, Abbau, Reparatur, Lagerplatz und Treibstoff verdoppelt; Steuerreichweite verdoppelt, aber höchstens bis zur **Recon-Reichweite** (siehe unten).
  - **Waffen des Schiffs selbst:** halber Schaden (Reichweite und Feuerrate unverändert).
  - **Schilde:** +60 % Kapazität, aber dreifache Downtime nach einem Zusammenbruch.
- **Schiffe (Namen nach Gestalten des Volkes – freigegeben):**
  - **Demos** (griech. „das Volk“) – Milizschiff (S): kleiner Drohnenträger, leichte Bewaffnung, mittlerer Hangar (3 Drohnen), gute Schilde, wenig Panzerung, sonst durchschnittlich. Ab **Neutral**.
  - **Quirinus** (röm. Gott der Bürgerschaft) – Patrouillenschiff (M): Weiterentwicklung des Milizschiffs, 7 Drohnen, gute Schilde, sonst durchschnittlich. Ab **Friendly**.
  - **Concordia** (röm. Göttin der Eintracht) – Flaggschiff (L, Spitzenmodell): großer Drohnenträger mit einem großen Waffenplatz, guten Sensoren, besonders großem Hangar – **11 Drohnen, als einziges Schiff** – und starken Schilden; seine Drohnen in besonderer Assembly-Blau-Färbung. Ab **Allied**.
- **Patrouillen:** In Fraktionssystemen bestehen die Patrouillen ausschließlich aus Schiffen der Fraktionsmanufaktur – mit Ausnahme einzelner Goliath in Fraktionsfarben. In umkämpften Systemen fliegen Earthworks-Schiffe. (Gilt für alle drei Fraktionen.)
- **Später:** Ränge bei den Fraktionen aufsteigen – dann könnten Schiffe auch an Ränge gebunden werden.

**Forge of Return (FOR)** – staatliche Manufaktur des Covenant of Return
- **Name & Motto:** angelehnt an den Covenant of Return – die Schiffe sollen den Weg heim zur Erde erzwingen. Motto: *„Faith is forged in fire.“*
- **Geschichte:** in den Dark Decades vom Covenant komplett von Grund auf selbst entwickelt – durch Versuch und Irrtum und um den Preis vieler toter Piloten, Besatzungen und Ingenieure. Der blutige Weg ist weithin bekannt, aber im Covenant wagt niemand, darüber zu sprechen – und: es hat funktioniert. Covenant-Schiffe müssen sich hinter traditionellen Schiffen nicht verstecken und übertreffen sie in einigen Punkten. Die **Cathedral** entstand erst später als Antwort auf die Drohnenträger der Assembly.
- **Haltung:** die exakte Antithese zu Concord Fleetworks. Covenant-Piloten lehnen Drohnen ab – Drohnen sind eine Erfindung des Clusters. (Nur die Haltung der eigenen Piloten: im Covenant-Gebiet gibt es weiter Drone Bays, Drohnen zu starten ist keine Straftat.)
- **Design:** prunkvoll und brutal; Rot und Gold wie das Wappen des Covenant.
- **Markenzeichen aller FOR-Schiffe:**
  - **Kraftwerk stark verstärkt:** +80 % Reaktorleistung (Cathedral +120 %); dafür −30 % Strukturpunkte und kleinere Panzerungsplätze (die Cathedral hat normale Hüllenwerte). **Keine Drohnenhangars.**
  - **Synthetische rote Fokuskristall-Laser:** eigene optische Strahlwaffe (Größe 1–4) mit hohem Schaden, großer Reichweite und sehr hohem Strombedarf; nur an Covenant-Ausrüstern erhältlich und **nur in Covenant-Schiffe einbaubar**.
  - **Strahlbündelung (S und M):** Sind **alle Waffenplätze** mit Fokuskristall-Lasern belegt, bündeln sich ihre roten Strahlen vor dem Schiff und feuern gemeinsam auf das Ziel – **+30 % Schaden**.
- **Schiffe (Namen freigegeben):**
  - **Acolyte** – Milizschiff (S): kleines Kampfschiff, wenig Hülle, sehr starkes Kraftwerk, Fokuskristall-Laser, kein Hangar. Ab **Neutral**.
  - **Templar** – Patrouillenschiff (M): Weiterentwicklung mit mehr Waffenplätzen und mehr Energie, sonst dieselben Schwächen. Ab **Friendly**.
  - **Cathedral** – Flaggschiff (L): eher mobile Waffenplattform als Schiff – sehr viele Waffenplätze, riesiges Kraftwerk, stärkere Hülle als die anderen FOR-Schiffe, keine Drohnen. Ab **Allied**.
    - **Anti-Drohnen-Puls** (eingebaut, aktivierbar): alle 30 s ein Puls im Umkreis von 5.000 km, der **alle** Drohnen lahmlegt – auch die von Verbündeten; sie treiben 15 s reglos, verbrauchen aber weiter Treibstoff. Sehr hoher Energiebedarf.
    - **Automodus:** feuert die Fokuskristall-Laser selbstständig auf bis zu 6 Ziele im Umkreis – nur auf feindliche Ziele oder auf die beim Einschalten gesperrten Ziele.

**Axiom Astronautics (AXA)** – staatliche Manufaktur des Meridian Directorate
- **Name & Motto:** „Axiom“ = Grundsatz, von dem alles abgeleitet wird. Motto: *„Every frontier is a hypothesis.“*
- **Aufbau:** wie das Directorate selbst geführt von einem Expertenrat aus Komitees für jeden Belang.
- **Geschichte:** besteht seit der Gründung des Directorate und entwickelt sich ständig weiter.
- **Rolle:** Anders als bei den anderen Fraktionen fliegen Patrouillen und Flaggschiffe des Directorate **Earthworks- und Hadrian-Dynamics-Schiffe (auch Goliath und Citadel)**. Die AXA-Schiffe sind trotzdem häufig in Directorate-Systemen unterwegs – als Forschungs- und Erkundungsschiffe.
- **Design:** äußerst futuristisch (genauer beim Entwurf).
- **Markenzeichen aller AXA-Schiffe:**
  - **Sensoren:** +25 % Reichweite und Scan-Stärke; **geringere Signatur**; effizienterer Energieverbrauch.
  - **Tarnvorrichtung** (eingebaut): macht das Schiff unsichtbar – Gegner sehen es nicht mehr. Getarnt kann es nur noch fliegen und warpen (keine Waffen, Werkzeuge, Locks usw.).
- **Schiffe:**
  - **Parallax** – Forschungsschiff (S): durchschnittlich in allen Belangen. Markiert auf der Galaxiekarte alle Systeme im Umkreis von **4 Sprüngen** mit unentdeckten Anomalien samt Anzahl (wird mit dem Discovery Update in Teil 6 erweitert). Ab **Neutral**.
  - **Threshold** – Sprungschiff (L, Prototyp): durchschnittlich für ein L-Schiff in Bewaffnung, Schutz, Geschwindigkeit und Lagerraum. Springt **ohne Sprungtor** durch ein kleines Wurmloch: Kurs auf der Galaxiekarte setzen, Entfernung = Zahl der normalen Sprünge, Verbrauch **1 Einheit Exotic Matter pro Sprung Entfernung**. Ab **Allied**. Nur an Directorate-Werften.
    - **Exotic Matter:** neue Ressource ohne Lagerplatzbedarf, gewonnen beim Analysieren bestimmter (seltener) Anomalien. Kein zusätzlicher Treibstoff nötig.
    - **Grenzen:** kein Weg durch den Veil (bleibt Project Bridge vorbehalten), höchstens 8 Sprünge Entfernung, Abklingzeit nach jedem Sprung, und der Sprung kann schiefgehen – dann endet er an einem zufälligen Ort im Zielsystem (z. B. mitten in einem Asteroidenfeld).

**Recon-Reichweite und Drohnen:** Die Recon-Reichweite ist fest **10.000 km** (das Radar zeigt sie unabhängig von der Fenstergröße) – das ist die Höchstgrenze für jede Drohnen-Steuerreichweite (Relay-Modul, CFW-Verdopplung). Drohnen meiden den Radarschatten von Kolossen. (Umgesetzt in alpha 0.4.24.1/0.4.24.2.)

**Für alle Manufakturen:** eingebaute Module (Nachbrenner, Bordraffinerie, Prospektor-Scanner, Fertigung, Markt …) bekommen in der Modulleiste und im Schiffsmenü eine **farbige Umrandung**, damit man sie als fest eingebaut erkennt.

**Abschluss Paket 24 (5. Nov 2026, alpha 0.4.24.2)** – `data/manufacturers.gd`, Wappen in `scripts/core/crest_art.gd`, 6 neue automatische Prüfungen:

- [x] Alle sieben Manufakturen als Daten: Name, Kürzel, Art (privat/staatlich), Fraktion, Gründungsjahr, Motto, Farbe, Wappen, Geschichte, geplante Modelle.
- [x] Ein Wappen je Manufaktur im Stil der Fraktionswappen, mit drei neuen Schildformen (Platte, Oval, Achteck) und Warnstreifen-Muster: Earthworks (Erdkugel mit Umlaufbahn und Luna, Stahlblau), KHI (Berg und Spitzhacke über Warnstreifen, Gelb-Schwarz), Maison Aurelle (A unter Vierzackstern, Elfenbein-Gold), Hadrian Dynamics (Wehrmauer mit Tor, dunkles Metall mit rotem Rand), Concord Fleetworks (verschlungene Ringe mit Drohnen, Assembly-Blau), Forge of Return (Amboss mit Flamme, Rot-Gold), Axiom Astronautics (Delta mit Singularität und Orbit, kühles Cyan).
- [x] Codex: ein Eintrag je Manufaktur (Kategorie Corporations) mit Motto, Art, Gründungsjahr, Geschichte und bekannten Modellen; Earthworks ab Spielbeginn, die privaten beim ersten Werftbesuch, die staatlichen zusammen mit ihrer Fraktion.
- [x] Recon-Reichweite fest 10.000 km (Radar unabhängig von der Fenstergröße), Obergrenze der Drohnen-Steuerreichweite.
- [x] Annahme: Axiom Astronautics gegründet 12740 HE (mit dem Directorate in den Dark Decades) – bei Bedarf anpassen.

### Neue Schiffe (Paket 25)

- **Mehr und neue Schiffe** aus den Manufakturen, mit unterschiedlichen Profilen (Maximalgrößen je Platz, Drohnenhangar).
- **Neue Schiffe auch bei NPCs und Piraten.**
- **Fraktionsexklusive Schiffe** aus den staatlichen Manufakturen – passt zum Ruf-System (Paket 12) und zur Idee „Fraktionsrümpfe“.

**Umgesetzt 25a (5. Nov 2026, alpha 0.4.25.1)** – KHI-Bergbauschiffe und Grundgerüst, 17 neue automatische Prüfungen:

- [x] Jeder Rumpf gehört einer Manufaktur (`maker`): die bisherigen Earthworks, die Carrion Crow Piratenbau. Werften führen Schiffe nach den Regeln der Manufaktur (`yards`, `small_yards` in `data/manufacturers.gd`): Earthworks an allen Werften, KHI an Industriekomplexen und Shipyard Complexes; Mining Colonies haben jetzt eine kleine Werft mit Mogura, Anaguma und dem Earthworks Drillhead.
- [x] Mogura (S), Anaguma (M), Iwakudaki (L) mit Plätzen laut Bauplan, Standardausrüstung, bulliger Pixel-Art in KHI-Gelb mit Warnstreifen, Schornsteinen, Führerhaus und Bohrkopf (bleibt gelb, egal wem das Schiff gehört).
- [x] Der Ladekreis beim Warp-Ausrichten zeigt die echte Zeit (Ausrichtzeit und nötige Drehung) – vorher lief er nach der Sprungantrieb-Ladezeit und war bei den trägen KHI-Schiffen zu früh voll (0.4.25.10).
- [x] Markenzeichen: eingebautes Erzlager (60/300/900 m³), +10 % Abbau, −25 % Drehgeschwindigkeit, +40 % Ausrichtzeit für den Warp; eingebaute Raffinerie (0,15/0,4/1,0 Erz pro s, 70/80/90 % Ausbeute, 8/16/32 MW nur wenn an (ab 0.4.25.4 verdoppelt), abschaltbar, Zustand bleibt über Warps erhalten) – schwarzer Rauch, solange sie arbeitet (auch NPC-KHI-Schiffe beim Abbauen); eingebauter Prospektor-Scanner.
- [x] Rauch tritt in dünnen Fahnen seitlich aus den Rohrstutzen an den Flanken aus (statt hinten raus, wo er wie ein brennender Antrieb wirkte) (0.4.25.2); Richtung korrigiert – nach außen, weg vom Rumpf (0.4.25.3).
- [x] Eingebaute Module: goldener Rahmen in der Modulleiste, eigene Kategorie „Built into the hull“ im Schiffsmenü, in der Energieverwaltung mit einstellbarer Priorität (Fehler behoben in 0.4.25.4); können nicht ausgebaut werden. Neues Raffinerie-Icon.
- [x] Werft zeigt Manufaktur mit Wappen und Motto, das Schiffsmenü den Hersteller. Die Hälfte der NPC-Bergleute fliegt KHI-Schiffe.

**Umgesetzt 25b (5. Nov 2026, alpha 0.4.25.7)** – Kanayama-maru, 15 neue automatische Prüfungen:

- [x] Kanayama-maru (L, 950.000 cr, an KHI-Werften der Stufe 3): Drohnenträger für 9 Drohnen, Erzlager 1.200 m³, Raffinerie wie eine Station (3 Erz/s, 100 % Ausbeute, 60 MW), Prospektor, sehr träge (−40 % Drehen, +70 % Ausrichtzeit). Pixel-Art (ab 0.4.25.8 als Träger): hinten ein hoher gelber Block mit Triebwerken, drei Schornsteinen und der Brücke als abgeschrägte, abgerundete Glasfront an seiner Vorderkante (wie die Kanzel des ersten Entwurfs, 0.4.25.9), davor ein flaches Flugdeck (dunkel, Warnstreifen-Kante, grüne Positionslichter, gelbe Mittellinie, drei Drohnenaufzüge), vorn der Bohrkopf. Die Drohnen rollen nacheinander die ganze Startbahn entlang, drehen erst hinter dem Bug ab und landen auf dem Deck wieder (0.4.25.10).
- [x] Ihre Drohnen: +25 % Abbau, +5 m³ Laderaum, KHI-Gelb.
- [x] **Fertigung braucht Zeit** – überall: 15 s × Größe^1,2 je Modul (Drohne 40 s). Stationen: Auftrag läuft weiter, das Modul landet danach im Stationslager; Warteschlange im Manufacturing-Panel; Aufträge werden gespeichert.
- [x] **Fabrik an Bord** (eingebaut, 30 MW, abschaltbar): baut wie ein Industriekomplex (bis Größe 7) und Drohnen aus den Materialien im Laderaum; arbeitet nur eingeschaltet und im All; Module landen im Laderaum, Drohnen im Hangar (wartet bei Platzmangel); schwarzer Rauch beim Arbeiten.
- [x] **Bordmarkt** (eingebaut, 6 MW, abschaltbar): Waren und Preise im neuen Schiffsmenü-Reiter „Industry“; solange er offen ist und das Schiff stillsteht, fliegen alle 25–50 s Händler herüber und kaufen, wenn der Preis fair ist (bis etwa 0,9–1,5 × Grundpreis); Angebote über 60.000 cr locken mit wachsender Wahrscheinlichkeit 2–4 Piraten an.
- [x] Neue Icons für Fabrik und Markt.
- [x] Eigene Schiffsmenü-Reiter „Industry“ (Fabrik) und „Market“ (Bordmarkt) – nur bei Schiffen, die sie haben (0.4.25.11).

**Umgesetzt 25c (5. Nov 2026, alpha 0.4.25.12)** – Maison Aurelle und Personentransport, 22 neue automatische Prüfungen:

- [x] **Passagierkabinen** (optionale Module, Größe 1–10): Bulk (8 Plätze bei Größe 1, 65 bei Größe 5), Business (3 / 24), Luxus-Suite (1 / 10); mehr Plätze mit Größe und Qualität. Bulk und Business passen überall, Luxus-Suiten nur in Aurelle-Schiffe. Neue Icons (Sitzreihen, Business-Sessel, Bett mit Krone). Belegte Kabinen lassen sich nicht ausbauen.
- [x] **Reiter „Passengers“ am Missionsbrett** (neben „Contracts“): eigene Transportaufträge (5 je Station), eigenes Limit (8 Gruppen gleichzeitig, zählen nicht zu den 5 normalen Aufträgen). Bulk-Gruppen füllen die Bulk-Plätze aller Kabinen zusammen; jede Business-/Luxus-Gruppe bekommt eine eigene freie Kabine ihrer Klasse, in die alle passen (die kleinste passende). Anzeige der eigenen Kabinen und ihrer Belegung.
- [x] Bezahlung pro Passagier und Sprung (Ziel bis 4 Sprünge, im selben System zählt wie 1 Sprung): Bulk 60, Business 220, Luxus 700 cr; Boulevard −20 %, Empress +25 % auf Luxus; Ruf-Bonus wie bei anderen Aufträgen. Luxusreisende häufiger in reichen Systemen.
- [x] Frist: 3 min + 2,5 min je Sprung ab Annahme. Verpasste Frist oder Schiff mit Passagieren zerstört → Auftrag gescheitert, −1,5 Ruf bei der Fraktion der Startstation. Abgeben („Disembark“) nur am Ziel und mit dem Schiff, auf dem sie sind.
- [x] **Pearl** (S, 45.000 cr): Luxusyacht, +35 % Tempo, kurze Ausrichtzeit, kein Hangar. **Boulevard** (M, 120.000 cr): Linienschiff, +25 % Tempo, sehr kurze Ausrichtzeit (−30 %), Luxus −20 %, Hangar 2 / 1 Drohne. **Opal** (M, 170.000 cr): Luxusliner mit Glas-Lounge, +45 % Tempo, kein Hangar. **Empress** (L, 650.000 cr): Megaliner, träge (−30 % Drehen), Ausrichtzeit −40 %, Warp +35 %, Schild +60 %, Frachtmodule nur 50 %, Luxus +25 %, 4 Drohnen (Hangar 5). Pearl/Boulevard/Opal mit Schild +20–25 %.
- [x] **Eingebauter Nachbrenner** (Pearl, Boulevard, Opal): wie das Modul, ohne Platz; goldene Kachel in der Modulleiste, verbraucht Energie und Strom nur, solange er an ist.
- [x] Empress-Drohnen: weiß-gold, mit eigenem Schild (60, +5/s); das Schild-Bonusmodul der Drohnen wirkt bei ihr 50 % stärker.
- [x] Pixel-Art: lange, glatte Elfenbein-Rümpfe mit Perlweiß-Kante, Goldlinien, Fensterreihen und Glasbrücke; Opal mit geschwungener Goldlinie und Glas-Lounge, Empress mit gestuften Decks und Glaskuppel. Bleibt elfenbein, egal wem das Schiff gehört.
- [x] Verkauf nur an Werften der Handelsstationen in reichen, sicheren Systemen (Sicherheit ≥ 0,65) der Assembly und des Covenant – im Directorate keine.
- [x] In diesen Systemen fliegen Boulevards als NPC-Linienschiffe zwischen den Stationen (gut ein Drittel der Shuttles).
- [x] Empress neu gezeichnet (0.4.25.13): schmalere Fensterseiten, dazwischen zwischen den beiden Goldstreifen ein langes Parkdeck unter einer Glaskuppel mit Streben – Rasen, Bäume, Blumen, Promenade und ein Pool mit Sonnenliegen. Animiert: Wellen auf dem Pool (ab 0.4.25.16 halb so schnell), ein Lichtreflex läuft über die Kuppel. Als erste Art in voller Höhe gezeichnet (nicht gespiegelt).

**Umgesetzt 25d (6. Nov 2026, alpha 0.4.25.17)** – Hadrian Dynamics, 14 neue automatische Prüfungen:

- [x] **Talon** (S, Dropship, 34.000 cr): vier Waffenplätze, kein Werkzeugplatz, kein Hangar, +15 % Tempo, Schild +40 %, Raketen und Torpedos feuern 30 % schneller. **Maul** (M, Kanonenboot, 115.000 cr): fünf Waffenplätze, 1 Werkzeugplatz, Hangar 2 (1 Drohne), +15 % Tempo. **Goliath** (M, Zerstörer, 280.000 cr): sechs Waffenplätze bis Größe 4 wie ein L-Kampfschiff auf zwei Waffenarmen, Hangar 5 (4 Drohnen), eingebaute Punktverteidigung. **Citadel** (L, kleiner Flottenträger, 560.000 cr): fünf Waffenplätze, Hangar 9 (9 Drohnen), eingebaute Punktverteidigung; für Teil 5 als Träger eines S-Schiffs vorgemerkt.
- [x] **Reflektierende Hülle:** S 10 %, M 15 %, L 20 % des Schadens, der die Panzerung trifft, gehen an den Angreifer zurück (Schilde reflektieren nicht; zurückgeworfener Schaden prallt nicht erneut ab und zählt nicht als Angriff); rotes Aufblitzen beim Angreifer. M und L dazu +20 % Explosivresistenz.
- [x] **Schwach außerhalb des Kampfs:** Werkzeugplätze S 0, M/L 1, kleiner Frachtraum, kein Erzlager, −50 % auf Abbau, Eisernte, Bergung und Analyse, hohe Signatur. Langstrecken- und Nuklearraketen sind für Maul, Goliath und Citadel vorgemerkt (`heavy_missiles`).
- [x] Pixel-Art: brutalistische, kantige Panzerblöcke in dunklem Stahl mit Plattenfugen, wenigen roten Lichtern und gut sichtbaren Geschützen; Talon als Panzerkeil mit Raketenkapsel, Maul mit Panzerschürze und langem Zwillingsgeschütz auf dem Rücken, Goliath mit zwei wuchtigen Waffenarmen an breiten Schultergelenken, Citadel als Festung mit Zinnen, Hangarbuchten mit roten Leitlichtern und Punktverteidigungstürmen.
- [x] Verkauf überall; Goliath und Citadel nur an Militärstationen, Shipyard Complexes und Stationen der Stufe 3.
- [x] **Piraten** fliegen heruntergekommene Kopien (rostiger Stahl, orange Lichter, Ausrüstung der Qualität E/F) – Talon, Maul und Citadel, nie die Goliath (20 % der Piraten).
- [x] **Directorate-Patrouillen** fliegen zur Hälfte Talon, Maul und Goliath statt Earthworks-Schiffen.
- [x] **Debug-Funktion** (Debug-Menü → World): „Spawn any ship next to you“ – jede Ausrüstung als Gegner oder neutral (z. B. um die reflektierende Hülle zu testen).
- [x] Design-Überarbeitung (0.4.25.18): Seitenteile abgerundet (Raketenkapsel der Talon, Panzerschürze der Maul). Goliath: die Waffenarme setzen ganz hinten an und bilden einen Bogen um den Rumpf; statt eines großen Haupttriebwerks sitzen zwei kleinere hinten an den Armen.
- [x] **Citadel mit Startplattform:** große Plattform mittschiffs (Stahlrahmen, rote Eckleuchten) mit Schiebeklappe – für das S-Schiff aus Teil 5. Animation: die Klappe fährt weg, das kleine Schiff taucht darunter auf, hebt ab, die Klappe schließt wieder (vorerst nur als Animation; Debug-Menü → Ship: „Citadel: launch from the platform“). Dahinter eine kleine **Drohnenklappe** mit derselben Animation: die Drohnen steigen nacheinander daraus auf und landen wieder darin.
- [x] Citadel-Brücke: vier Vorschläge (Keep mit Zinnen und Schießscharten, Kommandoturm mit rotem Visier, Panzerkuppel mit Schlitzring, Bug-Brücke mit rotem Fensterwinkel) – gewählt: die **Panzerkuppel** (0.4.25.19). Alle vier bleiben als Varianten erhalten (`VARIANTS` in `data/pixel_art.gd`, Zeichenskripte in `tools/art/`).
- [x] **Goliath als Skorpion** (0.4.25.19) – das Flaggschiff, das Angst einflößen soll: Heck wie zuvor (zwei Triebwerke an den Armen), die gegliederten Arme holen weit aus und schließen vorn wie Scheren – zwei gebogene Zangenbacken mit glühenden Spitzen um je eine lange Kanone, Punktverteidigungstürme auf den Armen; der Rumpf läuft vorn in einen langen Stachel aus; die Brücke sind zwei lange, schräge rote Augenschlitze unter dunklen Brauen, die langsam aufglühen und verblassen; die Platte auf dem Rücken ist jetzt die Drohnenklappe (Drohnen steigen daraus auf).
- [x] **Goliath-Arme beweglich** (0.4.25.20): fester Kontaktpunkt am Heck – die Triebwerkspartie bleibt gerade, an ihrem Ende sitzt ein Gelenk. Im All öffnen sich die Arme zu einem runden, kreisförmigen Bogen, der die Scheren weit vom Rumpf wegschiebt; beim An- und Abdocken falten sie sich in acht Stufen wieder eng an den Rumpf (passt so in die Hangarbuchten). In Menüs zeigt das Bild die geschlossene Form.
- [x] Triebwerksflammen sitzen dort, wo die Triebwerke wirklich sind (aus der Pixel-Art abgeleitet): die Goliath hat zwei Flammen an den Arm-Triebwerken statt einer in der Mitte; Schiffe mit mittigem Antrieb bleiben wie bisher (0.4.25.21).
- [x] **Drohnenklappe für jedes Drohnenschiff** (0.4.25.22): alle Schiffe mit Drohnen (außer der Kanayama-maru mit ihrer Startbahn) haben eine sichtbare Schiebeklappe auf der Mittellinie – Größe nach Schiffsklasse, in den Farben des Herstellers (Rumpffarbe, KHI-Gelb, Aurelle-Elfenbein mit Gold, Hadrian-Stahl), bei der Empress am Heck vor dem Park. Die Drohnen steigen daraus auf und landen wieder darin. Die Stellen sucht `tools/art/drone_hatches.py` auf glatter Hülle (ohne Cockpit, Waffen, Abzeichen). Ab 0.4.25.23 ist die geschlossene Klappe Teil des Schiffsbilds und damit auch in Hangar, Werft und Schiffsmenü zu sehen; ab 0.4.25.24 liegt ihre untere Hälfte wie der Rumpf im Schatten (der Knick in der Mitte läuft über die Klappe).

**Umgesetzt 25e (7. Nov 2026, alpha 0.4.25.26)** – Concord Fleetworks, die ersten Fraktionsschiffe, 11 neue automatische Prüfungen:

- [x] **Demos** (S, Milizträger, 32.000 cr, ab Neutral): 3 Drohnen, zwei Hangartore in Seitenkapseln, leichte Waffen, wenig Panzerung. **Quirinus** (M, Patrouillenträger, 150.000 cr, ab Friendly): 7 Drohnen, vier Hangartore. **Concordia** (L, Flottenträger, 720.000 cr, ab Allied): als einziges Schiff **11 Drohnen** in Assembly-Blau, sechs Hangartore an breiten Flugdecks, ein großer Waffenplatz, sehr gute Sensoren, Sensorfeld, sehr starke Schilde.
- [x] **Drohnen-Markenzeichen:** Hülle, Schaden, Abbau, Reparatur, Laderaum und Treibstoff der Drohnen verdoppelt; Steuerreichweite verdoppelt, höchstens bis zur Recon-Reichweite. **Eigene Waffen:** halber Schaden. **Schilde:** +60 % (Concordia +90 %), dafür dreifache Ausfallzeit nach einem Zusammenbruch (Schildbonus eines Rumpfs verkürzt die Ausfallzeit nicht mehr).
- [x] **Mehrere Hangartore:** Schiffe können mehrere Drohnentore haben (`drones`, `drones_2` …); die Drohnen steigen gleichzeitig aus allen Toren auf, jedes Tor öffnet und schließt sich einzeln, zurückkehrende Drohnen landen im nächstgelegenen. Tore in den Farben des Besitzers.
- [x] **NPC-Träger kämpfen mit Drohnen:** Concord-Schiffe von NPCs starten im Kampf alle Drohnen (Modus Verteidigen, greifen auch das Ziel des Trägers an) und holen sie 18 s nach dem Kampf zurück. Drohnen von NPC-Trägern gehören zur Fraktion ihres Trägers (Farbe, Feindschaft, Verbündete).
- [x] **Fraktionswerften:** Concord-Schiffe gibt es nur an Werften von Assembly-Stationen (Größe bis zur Stationsstufe); Kauf nur mit dem nötigen Ruf – die Werft zeigt die Bedingung, die Kaufknöpfe sind sonst gesperrt.
- [x] **Patrouillen:** In Assembly-Systemen fliegen die Patrouillen Demos, Quirinus und Concordia (gelegentlich eine Goliath in Assembly-Farben); in umkämpften Systemen Earthworks-Schiffe. Directorate wie bisher halb Hadrian (nur in eigenen Systemen).
- [x] **Debug-Funktionen:** Debug-Menü → Ship: „Fill drone hangar“; „Spawn any ship next to you“ kann jetzt auch Assembly-Patrouillen (patrol_cfw_*) als Gegner oder neutral setzen.
- [x] Nebenbei: der zufällig scheiternde Test „asteroid lock“ wählt nur noch nicht abgebaute Asteroiden.
- [x] **Lichteffekte** (0.4.25.27): die blauen Streifen der Concord-Schiffe pulsieren leicht; im Kampf (feuern, getroffen werden, feindliches Ziel) läuft auf jedem Streifen ein heller Lichtpunkt vom Bug zum Heck; bei der Concordia leuchten die Streifen gelb, solange die Hangartore zum Drohnenstart offen sind.
- [x] **Concordia-Flugdecks beweglich** (0.4.25.27): im All fahren die Flugdecks ein Stück nach außen und nach hinten, beim An- und Abdocken wieder ein; die Hangartore wandern mit.
- [x] Die Drohnen nutzen die Hangartore der Reihe nach – auch wenn man sie einzeln startet (0.4.25.27).
- [x] Überarbeitung (0.4.25.28): Pulsieren deutlich stärker (leuchtender Saum, langsames Atmen), Kampf-Lichtpunkt größer; das Gelb beim Drohnenstart ist jetzt ein Baustellen-Warnlicht – bernsteinfarben blinkend mit Lauflicht, dazu blitzende Warnleuchten an den Ecken der offenen Tore; die Tore der Concordia sind beim Starten und Zurückrufen sichtbar offen (sie lagen unter den Flugdecks) – die Drohnen fliegen hinein; sichtbare Hydraulikstreben mit Gelenken zwischen Rumpf und ausgefahrenen Flugdecks.

### Stationstyp 0 (Paket 26)

- **Neuer Stationstyp 0:** lässt nur S- und M-Schiffe landen und kann als **zusätzliche Station in allen Systemen** vorkommen.

### Ausrüster & Übersicht (Paket 27)

- **Überarbeitung des Ausrüsters:** besseres Design für mehr Übersicht.
- **Kurzbeschreibung** zu jedem Modul in der Modulübersicht.
- **Derzeitige Geschwindigkeit** am linken Rand in der Schiffsinfo anzeigen.

### Entscheidungen zu Teil 4

Alle Fragen am 4. Nov 2026 geklärt. Folgen für die Pakete:
- **Paket 19** baut das Modulsystem neu (keine Umrechnung der alten Module), Waffen in Größe 1–4, Modulplätze je Schiff einzeln festgelegt – vorher gehen wir die Schiffe einzeln durch.
- **Paket 22 (Multi-Fokus)** = mehrere aktive Ziele, jede Waffe behält ihr Ziel vom Einschalten.
- **Paket 24 (Manufakturen)** beginnt mit „Earthworks“ (die heutigen Rümpfe); jede weitere Manufaktur wird vor dem Bau im Design besprochen.


| Frage | Optionen | Vorschlag | Entscheidung |
| --- | --- | --- | --- |
| Umrechnung der heutigen Größen | S/M/L → feste Werte (z. B. 2 / 5 / 8) · je Modultyp eigene Tabelle | Feste Werte als Start, je Modultyp nachjustieren (gilt für die Daten, nicht für alte Spielstände) | **Keine Umrechnung** – das Modulsystem wird grundlegend neu entworfen. Größenbereich je Modultyp; **Waffen nur Größe 1–4** |
| Wirkung der Qualität | nur Werte · Werte + Masse/Strom · Werte + Preis | Werte, Strom und Preis steigen mit der Qualität | Werte, Strom und Preis steigen mit der Qualität |
| Woher kommt Qualität | nur Fertigung · auch Beute · auch Markt | F–C im Handel, B–A aus Fertigung und Beute, S erst im Endgame | **F bis A** sind zu kaufen; **S** (und S+) gibt es nur im Endgame |
| Maximalgröße pro Platz | pro Slottyp (alle Engines gleich) · pro einzelnem Platz | pro Slottyp und Schiff, einzelne Ausnahmen möglich | **Pro einzelnem Platz**, nicht uniform – z. B. Dragonfly zwei 1er-Waffenplätze, andere Schiffe einen 4er und zwei 3er usw. Wir gehen **Schiff für Schiff** durch, was Sinn ergibt |
| Multi-Fokus-Mechanik | mehrere aktive Ziele · Waffengruppen je Ziel · automatische Zielverteilung | Waffengruppen, die je ein eigenes Ziel haben; Anzahl hängt von Schiff/Sensoren ab | **Mehrere aktive Ziele**: jede Waffe feuert auf das Ziel, das beim Einschalten aktiv war |
| Drohnen-Begrenzung | Anzahl im Hangar · Bandbreite · beides | Hangar fasst Drohnen, Bandbreite begrenzt, wie viele gleichzeitig fliegen | Hangar fasst Drohnen (Vorrat), Bandbreite begrenzt, wie viele gleichzeitig fliegen |
| Fraktionsschiffe kaufen | ab Friendly · ab Allied · Missionen | ab Friendly mit der Fraktion, Spitzenmodelle ab Allied | Normale Modelle **ab Neutral**, Spitzenmodelle ab Allied |
| Minen | Anzahl begrenzt (Munition als Ware) · unbegrenzt mit Abklingzeit | Minen als Ware, begrenzte Zahl gleichzeitig ausgelegter Minen je Werfer; Minen verschwinden nach einiger Zeit | Minen als Ware, begrenzte Zahl gleichzeitig ausgelegter Minen je Werfer; Minen verschwinden nach einiger Zeit |
| Radarstörer – auf wen wirkt er | auf Gegner im Umkreis · auf ein anvisiertes Ziel · auf das eigene Schiff (Tarnung) | wirkt auf Gegner im Umkreis: ihr Radar (Recon-Ansicht) fällt aus bzw. zeigt keine Kontakte; NPCs verlieren die Zielerfassung auf Entfernung | Auf **Gegner im Umkreis** – und **Gegner setzen ihn auch gegen den Spieler ein** |
| Dienste in Stationen Typ 0 | wenige feste · zufällig | Markt, Treibstoff, Reparatur, Hangar – keine Werft | Feste kleine Auswahl: Markt, Treibstoff, Reparatur, Hangar – keine Werft |
| Anzahl Manufakturen | 3 staatliche + 2–3 private · 3 + 5 oder mehr | 3 staatliche (je Macht) + 3 private (neutral, überall), dazu die Piraten-Werften als Flickwerk ohne Verkauf | **Spezialisierte Manufakturen** (z. B. Bergbau, Kampf …), nicht strikt – die Bergbaufirma hat auch ein Schiff, das gut als Frachter taugt. Die **bisherigen Schiffe** bilden die Manufaktur **„Earthworks“** (noch auf der Erde entwickelt, einheitliches Design). Jede Manufaktur hat eine einheitliche Designsprache; Anzahl ergibt sich beim Entwurf |
| Anzahl Schiffe | ca. 20 · 30–40 · mehr | Start mit ca. 24 (je Manufaktur 3–5 über S/M/L verteilt), später erweitern | Ca. 24 zum Start, später erweitern |
| Wo werden Fraktionsschiffe verkauft | nur Werften der Fraktion · auch neutral | nur an Werften der Fraktion, abhängig vom Ruf | Nur an Werften der jeweiligen Fraktion |
| Unterscheidung im Aussehen | nur Farben · eigene Bausteine je Manufaktur · handgezeichnete Vorlagen | eigene Baustein-Sets je Manufaktur im Pixel-Art-Generator + Palette + Markenzeichen | **Pro Manufaktur gemeinsam besprechen**, wie das Design wirken soll (Formen, Farben, Markenzeichen); umgesetzt als eigene Baustein-Sets im Pixel-Art-Generator |
| Unterscheidung im Spielgefühl | nur Werte · Werte + Fahrverhalten · + eigene Besonderheit je Manufaktur | Werte + Fahrverhalten + eine Markenbesonderheit je Manufaktur | Werte + Fahrverhalten + eine Markenbesonderheit je Manufaktur |

## Phase 0.5 Teil 5 – Character Update

Mit Teil 5 bekommt das Spiel eine neue Ebene: **den Piloten**. Bisher ist der Spieler nur sein
Schiff – ab jetzt gibt es eine Person mit Aussehen, Werten und Fähigkeiten, die mit der Zeit
besser wird. Dazu kommt die **erste echte Fortschrittsmechanik** (Skilltree) und ein neuer
Umgang mit größeren Schiffen: **Crews und Söldner**.

Teil 5 hat zwei Hälften:

1. **Der Pilot** – Charaktererstellung, Attribute, Fähigkeiten, Skilltree
2. **Crews und Söldner** – Besatzung für Schiffe ab M, anheuerbare Wingmen

Spieltexte englisch (Attribut- und Fähigkeitsnamen im Spiel daher englisch, hier mit deutscher Erklärung).

### Arbeitspakete (Vorschlag)

Nummerierung schließt an Teil 4 an (dort bis Paket 27).

| # | Arbeitspaket | Inhalt | Abhängig von |
| --- | --- | --- | --- |
| 28 | Pilot & Charaktererstellung | Pilot als eigene Ebene im Spielstand; Sprite-Baukasten (Pixel-Art), Porträt aus dem Sprite; Name/Rufzeichen; Attribute verteilen; neuer Ablauf „Neues Spiel“ | – |
| 29 | Fähigkeiten | Fähigkeiten aus Attributen abgeleitet, steigen durch Tun; kleine Prozent-Boni im Spiel; Charakter-Reiter im Schiffsmenü | 28 |
| 30 | Skilltree & Baupläne | erste Fortschrittsmechanik: Module, Größen, Qualitäten und Schiffsklassen werden durch Tun freigeschaltet (nicht zeitbasiert wie EVE); dazu **Baupläne** für die Herstellung | 29, Teil 4 |
| 31 | Crew-System | Rollen, Mindest- und Höchstcrew für Schiffe ab M, Wirkung der Crew-Werte, Lohn, Erfahrung | 29 |
| 32 | Anheuern | neuer Stations-Service zum Anheuern (mit Monopolfirma), Crew-Verwaltung im Schiffsmenü, Crew aus Aufträgen | 31 |
| 33 | Söldner & Wingmen | anheuerbare Piloten mit eigenem Schiff fliegen im Verbund; einfache Befehle; Free Captains als Söldner | 31, 32 |
| 34 | Codex, Tutorial-Hinweise, Feinschliff | Codex-Einträge, Hinweise beim ersten Kontakt, Smoke-Tests, Balancing der Boni | alle |

**Debug-Funktionen je Paket** (Debug-Menü, neuer Reiter „Character“):

| Paket | Debug-Funktionen |
| --- | --- |
| 28 | Charaktererstellung jederzeit neu öffnen; Zufalls-Pilot erzeugen; Attribute frei setzen (auch über die Startgrenzen hinaus) |
| 29 | Jede Fähigkeit auf eine Stufe setzen bzw. Erfahrung hinzufügen; Anzeige der aktuell wirkenden Boni (vorher/nachher) |
| 30 | **„Alles freischalten“**-Schalter; einzelne Knoten/Zweige freischalten oder zurücksetzen; Lernpunkte geben; alle Baupläne geben |
| 31 | Crew sofort an Bord setzen (Rolle, Stufe, Werte wählbar); Mindestcrew-Prüfung abschaltbar; Löhne sofort abrechnen; Schiffsverlust samt Rettungskapsel auslösen, Kapsel-Timer verkürzen |
| 32 | Anheuer-Angebot an der aktuellen Station neu würfeln; Crew-Auftrag direkt erzeugen |
| 33 | Söldner sofort anheuern und neben sich spawnen; Leadership-Grenze ignorieren; Befehle testen |

---

### Teil A – Der Pilot

#### Charaktererstellung (Paket 28)

- Vorerst nur beim **Spielstart**: Name, Sprite, Attribute.
- Danach: **Aussehen** an Stationen gegen Geld änderbar, **Werte nicht**.
- **Sprite-Baukasten** in Pixel-Art: Körperform, Kopf/Frisur, Hautton, Kleidung/Anzug, Farben. Das **Porträt wird aus denselben Teilen erzeugt** (Brustbild), damit beides immer zusammenpasst.
- Der Sprite ist die **Vorbereitung auf Teil 7** (dort ist der Pilot am Boden selbst unterwegs) – in Teil 5 erscheint er nur in Menüs, Porträts, Funk- und Nachrichtenmeldungen.
- Die Crew und Söldner bekommen Porträts aus **demselben Baukasten** (zufällig erzeugt).

#### Attribute

Fünf Grundwerte, alle schon in Teil 5 beim Start verteilt: **alle starten bei 3, dazu 8 freie Punkte, maximal 8 pro Attribut.** Die Attribute **wachsen danach nicht** – ganz vielleicht später über Story-Ereignisse oder Endgame-Mechaniken.

| Attribut (im Spiel) | Deutsch | Wofür grob |
| --- | --- | --- |
| Strength | Kraft | Belastbarkeit, Nahkampf/Athletik (v. a. Teil 7), Bergbau-Handwerk |
| Dexterity | Geschick | Feinmotorik: Steuerung, Reparatur, Waffen von Hand |
| Intelligence | Intelligenz | Technik, Wissenschaft, Navigation, Elektronik |
| Charisma | Charisma | Handel, Verhandeln, Führung von Crew und Söldnern |
| Reflexes | Reaktionszeit | Ausweichen, Zielen unter Druck, Timing (z. B. Interdictor-Minispiel) |

#### Fähigkeiten (Paket 29)

Jede Fähigkeit hat einen **Grundwert aus zwei Attributen** und steigt durch **Tun** (Erfahrung pro Fähigkeit). Wirkung: wenige Prozent, spürbar aber nicht entscheidend (Richtwert: bis etwa +10 % auf höchster Stufe).

| Fähigkeit (im Spiel) | Attribute | Wirkung im Spiel (Vorschlag) | Steigt durch |
| --- | --- | --- | --- |
| Piloting | Reflexes + Dexterity | Höchstgeschwindigkeit, Beschleunigung, kürzeres Ausrichten für den Warp | Fliegen, Warpen, Andocken |
| Gunnery | Reflexes + Intelligence | Trefferwirkung/Reichweite der Schiffswaffen, schnelleres Aufschalten | Treffer im Kampf |
| Engineering | Intelligence + Dexterity | mehr Energie, schnellere Reparatur, weniger Schild-Downtime | Reparieren, Energie-Management, Fertigung |
| Science | Intelligence | Scanner-Reichweite und -Tempo, Anomalie-Analyse, Prospektor-Genauigkeit | Scannen, Analysieren, Survey |
| Navigation | Intelligence + Reflexes | Warp-Tempo, weniger Sprungtreibstoff | Sprünge, lange Warps |
| Mining | Strength + Intelligence | Abbaurate, Raffinerie-Ausbeute | Abbauen, Raffinieren |
| Trading | Charisma + Intelligence | bessere Kauf-/Verkaufspreise | Handeln |
| Leadership | Charisma | Crew-Wirkung, geringere Löhne, mehr Wingmen | Mit Crew/Söldnern fliegen |
| Negotiation | Charisma + Reflexes | mehr Ruf aus Aufträgen, höhere Belohnungen, kleinere Strafen | Aufträge abschließen |
| Electronics | Intelligence + Reflexes | Radarstörer, Interdictor (breiteres Zeitfenster), Warrant/Frachtscanner | E-War-Module benutzen |
| Athletics | Strength + Dexterity | in Teil 5: weniger Ausfall bei Treffern/Andruck; Hauptnutzen ab Teil 7 | (ab Teil 7: zu Fuß) |
| Firearms | Dexterity + Reflexes | Hauptnutzen ab Teil 7 (Handwaffen) | (ab Teil 7) |

Athletics und Firearms haben in Teil 5 kaum Nutzen – bewusst so entschieden, sie zahlen sich ab Teil 7 aus.

#### Skilltree (Paket 30) – die erste Fortschrittsmechanik

- **Status:** Die genaue Mechanik (wie Fähigkeiten und Skilltree zusammenhängen, woher die Punkte kommen) ist **noch offen** und wird vor Paket 30 gesondert besprochen. Die Punkte unten sind nur Material dafür.
- Wie in EVE muss man **lernen, wie Module funktionieren und wie Schiffe zu fliegen sind** – aber **nicht über Echtzeit**, sondern über das, was man tut.
- **Trennung zu den Fähigkeiten:** Fähigkeiten = *wie gut* (Prozent-Boni). Skilltree = *was man darf und kann* (Freischaltungen).
- **Beim Spielstart ist sehr wenig frei:** nur das Startschiff und wenige Grundmodule. Die Grundlagen lernt man später im **Story-Intro (Teil 8)**, das auch schon erste Knoten freischaltet.
- **Was freigeschaltet wird (Vorschlag):**
  - **Schiffsklassen:** das Startschiff von Anfang an; weitere S-, M- und L-Schiffe über Knoten (z. B. „Frigate Operations“, „Cruiser Command“), Spezialschiffe (Bergbau, Industrie, Fracht) über eigene Zweige.
  - **Modulfamilien und -größen:** wenige Grundmodule von Anfang an; weitere Familien, größere Größen und höhere Qualitäten über Knoten der jeweiligen Familie.
  - **Spezial-Ausrüstung:** Drohnen, Minenwerfer, E-War, Interdictor über eigene Knoten.
  - **Baupläne:** Was man in der Fertigung herstellen kann (Module, Waren, Gegenstände), lernt man als Bauplan – wahrscheinlich im Skilltree, im Zweig Industry. Ohne Bauplan keine Herstellung des Gegenstands.
- **Woher die Punkte kommen (Vorschlag):** Jede Fähigkeit sammelt Erfahrung; Erfahrung füllt **Lernpunkte im passenden Zweig** (Kampf, Industrie, Handel, Wissenschaft, Steuerung). Wer viel kämpft, kommt im Kampfzweig schnell voran.
- **Zweige:** Flight (Steuerung/Schiffsklassen), Combat, Industry (Bergbau, Raffinerie, Fertigung), Science (Scanner, Anomalien), Commerce (Handel, Ruf), Command (Crew, Söldner).

---

### Teil B – Crews und Söldner

#### Crew-System (Paket 31)

- **Schiffe ab M** haben eine **Mindest- und Höchstcrew**. S-Schiffe fliegt der Pilot allein.
- **Unter der Mindestcrew fliegt das Schiff nicht** (kein Abdocken, kein Aktivieren im Hangar).
- **Schiffsverlust:** Für jedes Crewmitglied wird einzeln ausgewürfelt, ob es überlebt. Die Überlebenden sitzen in einer **Rettungskapsel** im Weltraum, die eine Zeit lang auf Rettung wartet (Zeitlimit) – holt man sie rechtzeitig ab, ist die Crew zurück, sonst ist sie verloren.
- Ein Schiff braucht **verschiedene Rollen** – welche, hängt vom Schiff ab:

| Rolle (im Spiel) | Wirkt auf | Wichtigster Wert |
| --- | --- | --- |
| Co-Pilot | Fahrverhalten, Ausrichten, Warp | Piloting |
| Gunner | Waffen, Multi-Fokus (zusätzliche Ziele bei großen Schiffen) | Gunnery |
| Engineer | Energie, Reparatur, Schild-Downtime | Engineering |
| Science Officer | Scanner, Analyse, Survey | Science |
| Mining Foreman | Abbaurate, Drohnen-Bergbau | Mining |
| Quartermaster | Frachtraum, Preise, Löhne der übrigen Crew | Trading |
| Drone Operator | Drohnen-Bandbreite und -Wirkung | Electronics |

- **Crew-Werte** wie beim Piloten, aber auf ihre Rolle spezialisiert; sie **verbessern sich langsam** durch Einsatz. So wird das Schiff mit der Zeit besser.
- **Kosten:** fester Lohn pro **Spielstunde** (Spielzeit, nicht Echtzeit) je nach Stufe und Erfahrung, plus ein **sehr kleiner Gewinnanteil** (0,5–2 % auf Verkäufe, Kopfgelder und Auftragsbelohnungen).

#### Anheuern (Paket 32)

- Vorerst **an Stationen**: neuer Service im Concourse (Monopolfirma, z. B. eine Agentur für Raumfahrtpersonal); Angebot hängt vom Stationstyp ab (Militärstation: Gunner, Forschungsstation: Science Officer, Bergbaukolonie: Mining Foreman …).
- Außerdem **über Aufträge**: gerettete Piloten, Überläufer, Belohnungen.
- **Crew-Verwaltung** im Schiffsmenü: Besatzung je Schiff, Werte, Lohn, umsetzen zwischen Schiffen im Hangar.

#### Söldner & Wingmen (Paket 33)

- **Anheuerbare Piloten und Söldner** fliegen **im Verbund** mit dem Spieler (eigenes Schiff, Befehle wie „folgen“, „angreifen“, „bergen/abbauen“).
- Sie können bei manchen Schiffen die **mitgetragenen Schiffe** fliegen. Bis dahin gibt es **ein Schiff, das ein kleines Schiff tragen kann** – es wird in wenigen Schritten integriert; die großen Trägerschiffe bleiben Endgame.
- **Anzahl:** 1 Wingman zu Beginn, mit der Fähigkeit Leadership bis zu 3.
- Die **Free Captains** aus Teil 3 sind die naheliegende Quelle: „später anheuerbar als Begleitschiffe“ war schon notiert.

---

### Anmerkungen von Claude (noch offen)

- **Skilltree-Mechanik** ist bewusst aufgeschoben – vor Paket 30 eigene Runde.
- **Strenger Einstieg:** „sehr wenig frei“ und „ohne Mindestcrew kein Abflug“ machen den Start hart, und das Story-Intro kommt erst mit Teil 8. Zum **Testen** lösen das die Debug-Funktionen („Alles freischalten“, Crew sofort an Bord, Mindestcrew-Prüfung abschaltbar). Für normales Spielen zwischen Teil 5 und 8 bleibt die Frage, ob es zusätzlich ein paar vorab freigeschaltete Startknoten gibt.
- **Anheuern muss verlässlich sein:** Wenn M-Schiffe ohne Crew nicht fliegen, sollte an jeder Station mit Werft wenigstens einfache Crew zu bekommen sein.
- **Rettungskapseln** brauchen ein Ziel im Weltraum (Kapsel als Objekt mit Notrufsignal) und eine Antwort darauf, wie man sie birgt (z. B. heranfliegen und aufnehmen wie beim Bergen) – das gehört ins Crew-Paket 31.

### Entscheidungen zu Teil 5

| Frage | Optionen | Vorschlag | Entscheidung |
| --- | --- | --- | --- |
| Attribute und Teil 7 | alle fünf jetzt · Kraft erst mit Teil 7 · jetzt verteilen, später Umverteilung | Alle fünf jetzt, Kraft wirkt schon in Teil 5; mit Teil 7 kostenlose Umverteilung | **Alle fünf jetzt**, ohne Sonderregel |
| Startpunkte | wenige · mittel · viele | Alle bei 3, 8 freie Punkte, max. 8 | **Alle bei 3, 8 freie Punkte, max. 8** |
| Wachsen die Attribute selbst? | nein · über Skilltree-Meilensteine · durch Tun | Nur über einzelne Skilltree-Knoten (+1) | **Nein** – vielleicht später über Story-Ereignisse oder Endgame-Mechaniken |
| Fähigkeit vs. Skilltree | getrennte Erfahrung · Skilltree-Punkte aus Fähigkeits-Erfahrung · Aufgaben | Skilltree-Punkte aus Fähigkeits-Erfahrung | **Aufgeschoben** – vor Paket 30 gesondert besprechen |
| Was ist beim Start frei? | sehr wenig · alles Kleine | Alle S-Schiffe, Module bis Größe 3, Qualität F–D | **Sehr wenig**: Startschiff und wenige Module; Grundlagen und erste Freischaltungen im Story-Intro (Teil 8) |
| Unter der Mindestcrew | fliegt nicht · fliegt mit Abzügen · namenlose Grundbesatzung | Abzüge + günstige Grundbesatzung | **Schiff fliegt nicht** |
| Crew bei Schiffsverlust | stirbt · rettet sich · Zufall | Rettet sich meist, kleine Verlustchance | **Überleben je Mitglied ausgewürfelt**; Überlebende in einer Rettungskapsel mit Zeitlimit zur Rettung |
| Lohn | fest · fest + Anteil · nur Anteil | Fest pro Spielstunde + 0,5–2 % | **Fest pro Spielstunde + kleiner Gewinnanteil** |
| Söldner und Trägerschiffe | Wingmen jetzt, Träger später · kleine Träger vorziehen · alles vorziehen | Wingmen jetzt, Träger später | **Ein Schiff, das ein kleines Schiff tragen kann**, kommt vorher und wird in wenigen Schritten integriert |
| Wingmen-Anzahl | fest · abhängig von Leadership · nur durch Geld | 1, mit Leadership bis 3 | **1 zu Beginn, mit Leadership bis 3** |
| Charakter ändern | nie · Aussehen ja, Werte nein · beides gegen Geld | Aussehen ja, Werte nein | **Aussehen ja (an Stationen), Werte nein** |
| Koop (Phase 2, Netzwerk) | dem Spieler · Crew gehört dem Schiff · später | Dem Spieler | **Dem Spieler** – reisen mit dem Gast-Piloten |

## Phase 0.5 Teil 6 – New Worlds Discovery Update (grober Plan)

Teil 6 hat **zwei Parts** mit eigenen Paketen. Nummerierung schließt an Teil 5 an (dort bis Paket 34). Details je Part besprechen wir, wenn wir dran sind.

| Part | Thema | Kern |
| --- | --- | --- |
| A | Galaxy Rework | größere, abwechslungsreichere Systeme, neue Sterne und Planeten, Monde, Spezialsysteme, Cluster auf ca. 100 Systeme, neue Wirtschaft |
| B | Into the Darkness | Vorstöße ins Veil, Gegnerwellen, zwei Alienspezies, Beginn der Endgame-Mechaniken |

Die Veil-Mechanik entsteht bewusst schon hier, damit die Story (Teil 8) sie später nutzen kann, ohne sie neu zu bauen.

### Part A – Galaxy Rework

| # | Arbeitspaket | Inhalt |
| --- | --- | --- |
| 35 | System-Maßstab & Aufbau | deutlich größere Systeme; in den meisten Systemen ein dekorativer Asteroidengürtel und ein dekorativer Kuipergürtel (überwiegend Hintergrund); darin die bekannten Asteroidenfelder, dichter als heute |
| 36 | Monde | Planeten bekommen Monde, Gasriesen 2–3 |
| 37 | Neue Sterntypen | animierte Neutronensterne, Schwarze Löcher mit Akkretionsscheibe, Rote Überriesen (Beteigeuze-artig) |
| 38 | Neue Planetentypen | Eisriesen, Eisplaneten, Zwergplaneten |
| 39 | Spezialsysteme | die drei Fraktions-Heimatsysteme fest gestaltet; Systeme der Manufakturen |
| 40 | Cluster ca. 100 Systeme | weiterhin ca. 50 bewohnte Systeme im Kern, darum ein Gürtel unbewohnter Systeme: eine Mischung aus reichen Rohstoffen, Anomalien und Wracks, Piratenverstecken und Gefahren; dazu teilweise **unabhängige Systemregierungen mit Außenposten** |
| 41 | Bergbau-Erweiterung | starke Erweiterung des Bergbaus: viele neue abbaubare Elemente und daraus herstellbare Waren |
| 42 | Wirtschaft 2.0 | Systeme bekommen eine Wirtschaft und ein Wohlstandslevel; daraus Materialausstoß, Bedürfnisse, Angebot und Nachfrage. Handelskonvois haben **zum System passende Waren** an Bord – die Wirtschaft bestimmt die Konvois, nicht umgekehrt (echte Warenströme erst in einem späteren „Wirtschaft 3.0“) |
| 43 | Tourismus | Tourismus-Stationen als neuer Stationstyp und eine Tourismus-Wirtschaft |

### Part B – Into the Darkness

| # | Arbeitspaket | Inhalt |
| --- | --- | --- |
| 44 | Veil-Erkundung | Vorstöße ins Veil im Stil eines **Dungeon-Crawlers**: Abfolge von Veil-Systemen, die man sich erkämpft |
| 45 | Veil-Einsätze | Systeme im Veil erkunden, Gegnerwellen bekämpfen; am Ende ein **Bossgegner** und ein **Wurmloch zurück in den Cluster** |
| 46 | Der Schwarm | erste Alienspezies |
| 47 | Die Vergenz | zweite Alienspezies (KI) |
| 48 | Endgame-Beute | Beginn der Endgame-Mechaniken: S+-Ausrüstung und S+-Crewmitglieder sammeln |

Jedes Paket mit eigenen Debug-Funktionen (z. B. zu jedem Systemtyp springen, Stern-/Planetentyp erzwingen, Veil-System öffnen, Alienwelle spawnen, S+-Beute geben).

### Entscheidungen zu Teil 6

| Frage | Optionen | Vorschlag | Entscheidung |
| --- | --- | --- | --- |
| Unbewohnte Systeme | leer · Rohstoffe/Anomalien · Piraten und Gefahren | Rohstoffe, Anomalien, Piratenverstecke – Lohn für Erkundung | **Mischung aus allen drei**, dazu teilweise unabhängige Systemregierungen mit Außenposten |
| Wirtschaft 2.0 und Konvois | Konvois weiter nur Kulisse · Konvois liefern echt | Konvois verändern Angebot und Nachfrage tatsächlich | **Konvois haben zum System passende Waren**; die Wirtschaft beeinflusst die Konvois, nicht umgekehrt. Echte Warenströme ggf. in einem späteren **Wirtschaft 3.0** |
| Veil-Einsätze | offene Erkundung · abgeschlossene Einsätze mit Rückkehr · beides | Einsätze: hinein, Ziel erfüllen, Rückweg | **Dungeon-Crawler**: Abfolge von Veil-Systemen, am Ende evtl. Bossgegner und Wurmloch zurück in den Cluster |

## Phase 0.5 Teil 7 – The Sky Is Not Enough (grober Plan)

Landen auf Planeten und Gameplay am Boden – aus Teil 6 herausgelöst, weil es fast ein eigenes Spiel innerhalb des Spiels ist (eigene Ansicht, Steuerung, Kollision, KI).

| # | Arbeitspaket | Inhalt |
| --- | --- | --- |
| 49 | Landung | Landeanimation beim Absinken; bei Planeten mit Atmosphäre eine glühende Scheibe um das Schiff (Eintritt) |
| 50 | Planetenkarten | Karten der Planeten mit Städten und Points of Interest; prozedural aus dem Seed, Schlüsselorte von Hand gebaut; landbar sind alle festen Planeten |
| 51 | Bodengameplay & Bodenmissionen | was man am Boden tut, Missionen am Boden |
| 52 | Kampf zu Fuß | Kampf mit dem Piloten ohne Schiff (nutzt Athletics/Firearms aus Teil 5) |
| 53 | Wolkenstädte | Gasriesen bekommen Wolkenstädte |
| 54 | Personentransport & Sehenswürdigkeiten | Personentransport-Aufträge ausgebaut: Touristen zu Touristengebieten und Sehenswürdigkeiten (auf Planeten, in Wolkenstädten, an besonderen Orten im All) – baut auf der Tourismus-Wirtschaft aus Paket 43 auf |

Jedes Paket mit eigenen Debug-Funktionen (z. B. sofort landen, zu einem POI springen, Bodenmission starten, Gegner am Boden spawnen).

### Entscheidungen zu Teil 7

| Frage | Optionen | Vorschlag | Entscheidung |
| --- | --- | --- | --- |
| Bodenansicht | Draufsicht wie im Weltraum · Seitenansicht · eigene Szenen | Draufsicht in Pixel-Art | **Draufsicht wie im All** |
| Planetenkarten | prozedural · handgebaut · gemischt | prozedural, wichtige Orte handgebaut | **Prozedural, Schlüsselorte** (Hauptstädte, Fraktions-Heimatwelten, Story-Orte) **von Hand** |
| Landbare Welten | feste Planeten + Wolkenstädte · nur ausgewählte · alle inkl. Monde | feste Planeten und Monde, Gasriesen über Wolkenstädte | **Alle festen Planeten** (und Monde); bei Gasriesen nur die **Wolkenstädte** |

## Phase 0.5 Teil 8 – Intro and First Part of the Story

(Vorher Teil 7.) Beschreibung folgt. Details besprechen wir, wenn wir dran sind. Das Story-Intro bringt auch die Grundlagen des Skilltrees und erste Freischaltungen (siehe Teil 5) und nutzt die Veil-Mechanik aus Teil 6.

## Phase 0.5 Teil 9 – Feeling and Balancing

(Vorher Teil 8.) Beschreibung folgt. Hierher wandert Paket 8 (großes Balancing mit Analyse-Werkzeug) als Abschluss von Phase 0.5.

## Offene Entscheidungen

Geklärt: Einzelspieler mit zuschaltbarem Koop, der Host besitzt die Welt, Schwierigkeit skaliert, PvP optional, aktive Module statt Auto-Battler.

| Frage | Optionen | Vorschlag |
| --- | --- | --- |
| Spieler pro Session | 2–4 · bis 8 | Ausgelegt auf 4, technisch bis 8 |
| Plattform | Nur Desktop · auch Browser | Desktop (ENet), kein Browser |
| Gast-Piloten | Nur in der Host-Welt · in eigene Welt mitnehmbar | Erst nur in der Host-Welt, Mitnahme später |
| PvP-Regeln | Unsichere Systeme · Duelle · vom Host frei schaltbar | Host-Schalter + Duell auf Einladung |
| Verlust bei Abschuss | Schiff weg + Versicherung · nur Ladung weg | Wie heute: Schiff weg, Aegis-Versicherung, Ladung als Wrack |
| Munition | Unbegrenzt · Raketen als Ware | Normale Waffen unbegrenzt, Raketen und Nuklearraketen als Ware |
| Geteilter Bildschirm | Gar nicht · später mit Gamepad | Später, eigene optionale Phase |
