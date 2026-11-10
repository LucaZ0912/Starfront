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

Das Spiel ist ein umfangreicher Einzelspieler-Prototyp in Godot 4.3. Phase 0 und Phase 0.5 Teil 1 bis 3 sind abgeschlossen; Teil 4 (Module and Internal Ship Parts Rework) läuft – Pakete 19 bis 24 fertig, Pakete 25a (KHI-Bergbauschiffe), 25b (Kanayama-maru), 25c (Maison Aurelle), 25d (Hadrian Dynamics), 25e (Concord Fleetworks), 25f (Forge of Return) und 25g (Axiom Astronautics) fertig – damit sind alle Manufakturen gebaut; Paket 26 (Stationstyp 0: Raststationen mit Landeplattformen) fertig; Paket 27 (Stationsübersicht, Ausrüster, Kurzbeschreibungen, Geschwindigkeit) fertig – damit sind alle Pakete von Teil 4 umgesetzt. Code-Review von Teil 4 gemacht (Bericht `reviews/teil4_review.md`), alle Befunde sind abgearbeitet (0.4.25.46 und 0.4.25.47) – Teil 4 abgeschlossen. **Teil 5 läuft:** Paket 28a (Audio-Grundgerüst), die Menüsteuerung per Tastatur und Paket 28 (Pilot & Charaktererstellung) und Paket 29 (Fähigkeiten + Pilot-Fenster) fertig, Fortschritts-Mechanik am 7. Nov neu entschieden (Fähigkeiten automatisch, Pilotenlevel, Perks, Skilltree über Leistungen); Paket 30 (Perks, Skilltree über Leistungen, Baupläne) fertig und der Skilltree in 0.5.30.2 als gezeichneter Baum nach Tätigkeiten neu gebaut (alles kaufbar, nutzbar erst mit Kachel), Paket 31 (Crew-System & The Bar, mit 32 zusammengelegt) fertig, Paket 31a (Game Over: Rettungskapseln, Rückkauf, Respawn) fertig, Paket 33 (Wingmen und Citadel-Plattform) fertig, Paket 34 (Codex-Einträge, Sammlung, berüchtigte Piraten als Charaktere mit Wild-West-Steckbrief) fertig – damit sind alle Pakete von Teil 5 umgesetzt. Code-Review von Teil 5 gemacht (Bericht `reviews/teil5_review.md`), alle Befunde in 0.5.34.4 behoben – **Teil 5 abgeschlossen**. **Teil 6 läuft:** Paket 35 (Systeme ×3, Asteroiden- und Kuipergürtel, neue Asteroidenfelder, mehr Verkehr, Ladebildschirm und Vorladen) fertig, Paket 36 (Monde, Umlaufbahnen beim Einspringen neu) fertig, Paket 37 (zwölf Sterntypen, animiert, koronale Massenausbrüche, Schwarzes Loch mit Sog und Linse) fertig, Paket 38 (neue Planetentypen, alle überarbeitet, Stadtlichter) fertig, Paket 39 (Spezialsysteme) läuft: Paket 39 (Spezialsysteme: Landfall, Heimkehr, Durchbruch und die Systeme der privaten Manufakturen) fertig. Paket 41 (Bergbau-Erweiterung: Gase, neue Erze, Reinheit, radioaktive Waren, Bauteile, Kujira) fertig. Paket 42 (Wirtschaft 2.0: Haupt- und Nebenwirtschaft, Wohlstand, Hochmetallwelten, Markt mit Lagerbeständen und 56 neuen Waren, Kategorien, Munitionsdepot, Wirkungen des Wohlstands) fertig. Paket 43 (Tourismus: Resorts als Habitatringe und Biosphären, Sehenswürdigkeiten, Touristen- und Rundflüge, Kreuzfahrtschiffe) fertig. **Paket 40 (neuer Cluster) fertig:** 40a (120 Systeme, Kern und Rand aus Konstellationen, Heimatsysteme nur von eigenen Systemen umgeben, freie Siedlungen, Namen, Galaxiekarte mit Zoom; in 0.6.40.3 erweitert um die Fernen Weiten – ein zweiter Ring aus 20 unbewohnten Konstellationen, ~240 Systeme; 0.6.40.4: Übersicht der Galaxiekarte beim Herauszoomen mit Gebiets- und Regionsnamen) fertig. 40b (Tore in sechs Bauarten, alte Tore langsamer mit seltenen Fehlsprüngen, Animationen für Ankunft und Fehlsprung) fertig. 40c (reiche Rohstoffe, alte Schlachtfelder, Wracks aus der Zeit vor dem Bruch, Veil-Rand mit Rissen und Geisterechos) fertig; 0.6.40.6: Routenklassen abgeschafft (jeder Sprungantrieb kommt überall hin, Antriebe Mk I–III springen schneller und stabilisieren alte Tore), der Veil auf der Galaxiekarte als wabernde schwarze Wolken mit lila Akzenten; 0.6.40.7: Gebiete nach der Lore (Assembly und Covenant teilen sich den Kern mit umstrittener Grenze, das Directorate eine Enklave von höchstens 4 Systemen ohne umstrittene Grenzen, Piraten je höchstens 3 Systeme). 40d (Strahlungszonen, Ionenstürme, alte Minenfelder, Piratenfestungen mit Kopfgeld) fertig; 0.6.40.9: spezialisierte Baupläne im Skilltree für Strahlungsisolierung und Abschirmhülle (50–90 % je nach Qualität). 40e (Codex, Debug, Abstimmung, Leistung) fertig – damit ist Paket 40 abgeschlossen und **Part A von Teil 6 fertig**. Part B (Into the Darkness) ist hinter Teil 7 verschoben; der **Zwischenteil 6½** ist mit Paket 75 erledigt (Kernmodule aufgelistet, Geschwindigkeit und Plasma Drive, Schub auf Shift; 76–78 gehen ins große Balancing von Teil 9). Code-Review von Teil 6 gemacht (Bericht `reviews/teil6_review.md`), alle Befunde in 0.6.75.4 behoben – **Teil 6 Part A abgeschlossen**. **Teil 7 läuft:** Paket 49 (Bodenansicht, begehbare Stationsdecks mit Läden und Bar, je Stationstyp eigenes Aussehen) fertig; 0.7.49.2: schräge, gemütliche Ansicht und Aufbau nach Luz' Skizze (Aufzugsraum, Gang mit Läden unten, große Bar mit Fensterfront und anheuerbarer Crew oben); 0.7.49.3: Panorama-Fensterfront mit runden Ecken, die Station geht rundherum weiter; 0.7.49.4: das All nur durch das Glas; 0.7.49.5: Neon und Cyberpunk-Grundton; 0.7.49.6: Crew-Gespräche, Sitzen, Jukebox, Aufzugstüren; 0.7.49.7: Stationsthemen, Wegfindung, Gesprächsbildschirm; 0.7.49.8: Hangar-Ebene, Aufzüge mit Ebenenwahl, Waystation-Diner; 0.7.49.9: Hangar weit unten, Hangar- und Werft-Laden am Gang; 0.7.49.10: Leben im Hangar (Lader, Drohnen, Tankwagen); 0.7.49.11: neue Figuren (C3, Neon-Randlicht); 0.7.49.12: Sitzmöbel an die Figuren angepasst; 0.7.49.13: Bar benutzbar, Stationsfenster zu Fuß gesperrt, Hangar je Schiff; 0.7.49.14: Blick aufs Schiff von der Hangar-Bank, Stern und Planet immer im Fenster. **Paket 50 geteilt – 50a (Landung) fertig:** 0.7.50.1 Sinkstationen über allen festen Planeten und Monden, Abstieg mit Hitzeschimmer, Planetenkarte mit Städten und Orten, Landung auf einem Landefeld, Rückstieg in den Orbit; 0.7.50.2 Knopf „Descend“; 0.7.50.3 Übergänge, Anflug in Draufsicht, Aufsetzen und Abheben; 0.7.50.4 Stadt als Lichter, Landedrohne für kleine Orte. **50b (Landeplätze & Städte) fertig:** 0.7.50.5 Landeklappe, Stadt als Station am Boden mit Hangar, Einkaufsstraße und Turm-Bar; 0.7.50.6 vier Baustile (Assembly, Covenant, Directorate, Independent), Tag und Nacht, Straßenschlucht; 0.7.50.7 Grundrisse je Welt, Welten drehen sich, Bar und Hangar im Stil; 0.7.50.8 Tageszeit live mit Sonnenuntergang aus der Bar; 0.7.50.9 Wachen in den Städten (ohne Waffenfeuer); 0.7.50.10 Siedlungen mit vier Landeplätzen, Läden, Sondergebäude nach Wirtschaft und Begrenzung je Welt; 0.7.50.11 Siedlungen detaillierter (acht Bauformen, Natur in Vielfalt); 0.7.50.12 Wirtschaftsbereiche (Tagebau, Felder, Werke, Tanklager …); 0.7.50.13 alles im Maßstab, Tagebau vom Rand; 0.7.50.14 Sci-Fi-Fahrzeuge und -Anlagen; 0.7.50.15 Abheben mit Wahl (Orbit/Planetenkarte), Landedrohne als Landungsschiff mit Rampe, vom Schiff gefangen, Landeplätze im Detail; 0.7.50.16 Abstiegsflamme und Eintrittshitze neu, Drohne und Schiff in echten Größen; 0.7.50.17 kleine Orte im Anflug als Lichter mit Wirtschaft, keine Flamme beim Abstieg. Handel der Sondergebäude zurückgestellt als Paket 54d, Wohlstand im Stil als Idee für später. **Paket 51 (Persönliche Ausrüstung & Umwelt) fertig:** 0.7.51.1 Anzüge als „Rumpf“ des Piloten, Waffen, Gürtel, Features, Taschen, Schiffsspind, Gear-Seite; 0.7.51.2 Gear-Laden, der Pilot im Anzug; 0.7.51.3 Umwelt, Energie, Sauerstoff, Gürtel, Ladepunkte; 0.7.51.4 Klinik und Aufwachen – **Paket 51 fertig**; 0.7.51.5 Debug-Funktionen der Pakete 49–51 nachgereicht (F12 → Ground). Netzwerk fehlt noch. Teile 5–9 sind geplant (aus dem Roadmap-Entwurf übernommen, zuletzt am 7. Nov 2026: Teile 8 und 9, Audio-Grundgerüst 28a, Lade-Grundlagen in Paket 35, Code-Review am Ende jedes Teils), Phase 1 und 2 getauscht (erst Story & Endgame, dann Koop). Version alpha 0.7.51.5. Stand 10. November 2026.

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

- **Leitlinien:** `Leitlinien.md` im Projektordner hält alle verbindlichen Grundsätze (Arbeitsweise, Aussehen, Maßstab, Muster für neue Systeme) – **zu Beginn jedes Pakets lesen**, jedes Ergebnis vor dem Zeigen dagegen prüfen (seit 11. Nov 2026).

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
- **Code-Review am Ende jedes Teils (Grundsatz):** Am Ende jedes Teils gibt es ein kleines Code-Review (Aufräumen, tote Stellen, offensichtliche Fehler). Funde zuerst als Liste, Änderungen nach Freigabe durch Luz. Das große, vollständige Review folgt in Teil 9 (Paket 66).
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
| 6 | New Worlds Discovery Update – Part A Galaxy Rework (Pakete 35–43) | ✅ Part A erledigt (9. Nov 2026); Part B (Into the Darkness, Pakete 44–48) **verschoben hinter Teil 7** |
| 6½ | Zwischenteil: Module und Schiffe abstimmen – Paket 75 | ✅ erledigt (9. Nov 2026); 76–78 gehen in Teil 9 auf |
| 7 | The Sky Is Not Enough (Landen, Planeten, Boden) – Pakete 49–54 | grober Plan |
| 7½ | Into the Darkness (Teil 6 Part B: Veil-Erkundung, Aliens, Endgame-Beute) – Pakete 44–48 | grober Plan – Umsetzung noch offen |
| 8 | Intro and First Part of the Story – Pakete 55–65 | grober Plan (vorher Teil 7) |
| 9 | Feeling and Balancing – Pakete 66–74 | grober Plan (vorher Teil 8) – Paket 8 (großes Balancing) geht in den Paketen 72–74 auf |

Landen und Bodengameplay waren als Part B von Teil 6 geplant und sind jetzt ein eigener Teil 7 (fast ein eigenes Spiel im Spiel); die späteren Teile rücken um eins nach.

**Reihenfolge (Entscheidung Luz, 9. Nov 2026):** Nach Part A von Teil 6 kommt erst ein kleiner **Zwischenteil 6½** (Module und Schiffe abstimmen), dann **Teil 7**. **Part B von Teil 6 (Into the Darkness)** wird **hinter Teil 7** geschoben – wie die Veil-Erkundung umgesetzt wird, ist noch offen. Die Versionen bleiben im Schema: Zwischenteil 6½ zählt als Teil 6 (alpha 0.6.75.x …).

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
  - **Strahlbündelung (alle FOR-Schiffe, ab 0.4.25.33 auch die Cathedral – Entscheidung Luz):** Sind **alle Waffenplätze** mit Fokuskristall-Lasern belegt, bündeln sich ihre roten Strahlen vor dem Schiff und feuern gemeinsam auf das Ziel – **+30 % Schaden**.
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
- [x] Concordia: drei Triebwerksflammen – am Rumpf und an beiden Flugdecks (wandern beim Ausfahren mit); Düsen mit nur einer Reihe Abstand zählen als ein Triebwerk (0.4.25.29).

**Umgesetzt 25f (7. Nov 2026, alpha 0.4.25.31)** – Forge of Return, die fliegenden Tempel des Covenant, 11 neue automatische Prüfungen:

- [x] **Acolyte** (S, Milizschiff, 36.000 cr, ab Neutral), **Templar** (M, Patrouillenschiff, 175.000 cr, ab Friendly), **Cathedral** (L, Flaggschiff, 850.000 cr, ab Allied) – nur an Covenant-Werften, keine Drohnenhangars.
- [x] **Design – die Dualität der Macht:** außen dunkelrote, gezackte Wehrgänge mit goldenen Spitzen und glühenden roten Kristallgeschützen (Bedrohung für den Feind), innen ein strahlendes Kirchenschiff aus Elfenbein und Gold mit Buntglasfenstern, getragen von goldenen Strebebögen (Vorbild für die eigene Fraktion). Am stärksten bei der Cathedral: Wehrgänge mit Zinnen, Kristallbatterien, große Rosette am Bug, zwei Glockentürme mit goldenen Spitzen, goldener Heiligenschein über dem Allerheiligsten am Heck. Feste Farben Rot und Gold, egal wem das Schiff gehört.
- [x] **Kraftwerk:** +80 % Reaktorleistung (Cathedral +120 %); dafür weniger Struktur und kleinere Panzerungsplätze (Cathedral mit normalen Hüllenwerten).
- [x] **Fokuskristall-Laser** (neue Waffe, Größe 1–4): rote Strahlen, hoher Schaden, große Reichweite, sehr hoher Strombedarf; nur an Covenant-Ausrüstern (Qualität nach Stationsstufe), nur in Covenant-Schiffe einbaubar; eigenes Icon (roter Kristall).
- [x] **Strahlbündelung (Acolyte, Templar):** sind alle Waffenplätze mit Fokuskristallen belegt, werden sie zu einer **Fokus-Lanze**: dünne rote Strahlen laufen vor dem Bug zusammen, von dort feuert ein dicker Strahl – +30 % Schaden, eine Kachel in der Modulleiste.
- [x] **Cathedral – Anti-Drohnen-Puls** (eingebaut, aktivierbar): eingeschaltet alle 30 s eine rote Schockwelle (420 Energie), die **alle** Drohnen im Umkreis von 5.000 km lahmlegt – auch die von Verbündeten; sie treiben 15 s flackernd und reglos, verbrauchen weiter Treibstoff. NPC-Cathedrals setzen ihn gegen feindliche Drohnen ein.
- [x] **Cathedral – Automodus** (eingebaut): die Fokuslaser, die nicht von Hand eingeschaltet sind, feuern selbstständig auf bis zu 6 Ziele – nur feindliche oder die beim Einschalten aufgeschalteten; nie auf Unbeteiligte.
- [x] **Patrouillen:** in Covenant-Systemen Acolyte, Templar und Cathedral (gelegentlich eine Goliath in Covenant-Farben), in umkämpften Systemen Earthworks-Schiffe.
- [x] Überarbeitung (0.4.25.32): **Fokus-Lanze** neu – alle Kristallstrahlen bündeln sich an einem Punkt zwischen Schiff und Ziel, laden ihn kurz auf (0,55 s) und geben dann etwa 1 s lang einen dicken Strahl auf das Ziel ab (Schaden über diese Sekunde verteilt, Abklingzeit mindestens 2,4 s); weiter nur ein Waffenmodul in der Leiste. **Goldene Zacken** an Templar und Cathedral schieben sich ab und zu langsam nach außen und wieder ein (jede zu ihrer Zeit). **Puls-Kachel** mit Balken bis zum nächsten Puls; gelähmte Drohnen sprühen rote Blitze. **Debug-Gegner:** ein Piraten-Quirinus mit Drohnen („DEBUG drone carrier“ in der Piratenliste) – echte Piraten fliegen ihn nie.
- [x] Überarbeitung (0.4.25.33): die **Cathedral bündelt jetzt auch** – mit Kristallen in allen acht Plätzen eine einzige Lanze und eine Kachel; im Automodus feuert die Lanze selbstständig und wechselt dabei der Reihe nach zwischen bis zu 6 Zielen. Lanzen-Ausgleich: eine Lanze trägt den Schaden ihres ganzen Zyklus (2 s), sodass die Bündelung wirklich +30 % Schaden pro Sekunde bringt.
- [x] **Debug-Funktion:** Debug-Menü → Ship: „NPC carriers launch drones“ (Träger in der Nähe starten ihre Drohnen – zum Testen des Pulses); dazu wie gehabt „Spawn any ship“.

**Umgesetzt 25g (7. Nov 2026, alpha 0.4.25.34)** – Axiom Astronautics, die Forschungs- und Sprungschiffe des Directorate, 15 neue automatische Prüfungen:

- [x] **Parallax** (S, Forschungsschiff, 42.000 cr, ab Neutral) und **Threshold** (L, Sprungschiff-Prototyp, 980.000 cr, ab Allied) – nur an Directorate-Werften.
- [x] **Design:** äußerst futuristisch – dunkler Graphit und Schiefer, weiße Vorderkanten, feine cyanfarbene Lichtlinien. Parallax als schmales Delta mit Sensorring. **Threshold** (Entwurf Luz): ein langer Rumpf durch einen runden Kern mit einem **künstlichen schwarzen Loch** – weißer Rand, Gehäuse, cyanfarbener Licht-Saum, eine orange Akkretionsscheibe mit heißem Innenrand; die Scheibe dreht sich (helle Spiralstreifen wandern um das schwarze Loch). Vorn eine Sensornadel.
- [x] **Markenzeichen:** Sensoren +25 % Reichweite und Scan-Stärke, Signatur −25 %, Stromverbrauch −15 %.
- [x] **Tarnvorrichtung** (eingebaut, eigenes Icon): unsichtbar und nicht anvisierbar – Gegner verlieren das Ziel, auf Radar und Kontaktliste verschwindet das Schiff; getarnt nur fliegen und warpen (keine Locks, Waffen, Werkzeuge, andere Module); verbraucht Energie (Parallax 5/s, Threshold 18/s) und fällt bei leerem Kondensator aus; im Hangar aus. Der eigene Pilot sieht sein Schiff halb durchsichtig mit cyanfarbenem Schimmer.
- [x] **Parallax:** markiert auf der Galaxiekarte alle Systeme im Umkreis von 4 Sprüngen mit unentdeckten Anomalien samt Anzahl (cyanfarbener Ring, „n?“).
- [x] **Threshold – Wurmloch-Sprung:** auf der Galaxiekarte Ziel wählen → „Wormhole jump“: ohne Sprungtor, Entfernung = Zahl der normalen Sprünge, **1 Exotic Matter pro Sprung**, höchstens 8 Sprünge, kein Weg durch den Veil (Systeme mit `veil`-Kennung), 120 s Abklingzeit des Kerns; Ankunft neben einer Station – oder bei einem Fehlschlag (12 %) irgendwo im Zielsystem, gern in einem Asteroidenfeld.
- [x] **Exotic Matter:** neue Ressource ohne Laderaum (im Spielstand), aus seltenen Anomalien „Exotic Matter Signature“ (etwa jede siebte, etwas schwerer zu analysieren): 2–4 Einheiten je Analyse.
- [x] **NPCs:** In Directorate-Systemen fliegen zwei Axiom-Forschungsschiffe (Parallax) durchs System; unter Beschuss tarnen sie sich und tauchen nach 25 s wieder auf. Die Patrouillen des Directorate bleiben Earthworks und Hadrian.
- [x] Drohnenklappen für Parallax und Threshold.
- [x] **Nachtrag 0.4.25.35:** Das schwarze Loch der Threshold plastischer (Wunsch Luz) – die Akkretionsscheibe liegt schräg zur Kamera: das vordere Band läuft vor dem Loch entlang, die hintere Hälfte verschwindet dahinter und wird als heller Bogen über das Loch gelinst; dünner Photonenring, die auf uns zu drehende Seite leuchtet heller, die abgewandte glimmt dunkelrot. Die Threshold ist dafür als volles (nicht gespiegeltes) Bild gezeichnet.
- [x] **Nachtrag 0.4.25.36:** Erhöhte Brücke am Heck der Threshold (Wunsch Luz) – drei abgestufte Decks, die ihren Schatten nach rechts unten werfen, oben die Brückenkabine mit cyanfarbenem Fensterband nach vorn und Sensorkuppel; die Drohnenklappe sitzt jetzt auf dem vorderen Rumpf.
- [x] **Nachtrag 0.4.25.37:** Das schwarze Loch wird gezündet (Wunsch Luz): im Hangar und beim Ab- und Andocken ist der Kern leer; 2,5 s nach dem Abdocken ein Lichtblitz, dann wächst das schwarze Loch, danach bildet sich die Akkretionsscheibe (gut 3 s); beim Andocken ein Lichtblitz und es verschwindet. Das schwarze Loch ist eine eigene Ebene und behält immer dieselbe Ausrichtung, egal wohin das Schiff dreht (der gelinste Bogen liegt immer oben). Ein im All angetroffenes Schiff brennt schon.
- [x] **Nachtrag 0.4.25.38** (Wunsch Luz): Der Zündblitz flammt richtig auf – greller Kern, großer Lichthof, vier Strahlen, und der ganze Rumpf leuchtet mit. **Tarnung als Animation:** statt des übergelegten Rechtecks läuft eine cyanfarbene Scan-Linie über die Schiffsform von hinten nach vorn, dahinter verblasst das Schiff (Triebwerke zuerst); beim Enttarnen taucht es vom Bug her wieder auf. Gilt für Parallax und Threshold (S schneller als L).
- [x] **Nachtrag 0.4.25.39** (Wunsch Luz): Unter der Tarnung ist das schwarze Loch aus – es verlischt mit dem Blitz, sobald die Tarnung einsetzt, und zündet neu (Blitz, wachsendes Loch, Scheibe), kurz nachdem das Schiff wieder ganz sichtbar ist.
- [x] **Nachtrag 0.4.25.40** (Wunsch Luz): **Waffen und Tools beenden die Tarnung** – sobald eine Waffe, ein Werkzeug oder ein anderes Modul wirklich angeht, ist das Schiff wieder sichtbar (wird es abgelehnt, z. B. weil die Zielerfassung noch läuft, bleibt die Tarnung an). Zielerfassung ist getarnt jetzt erlaubt (Hinterhalt vorbereiten), bestehende Locks bleiben beim Tarnen erhalten. **Tarn-Drohnen:** neues Drohnenmodul „Drone Cloak Emitter“ (Bonus-Slot des Hangars, nur in Schiffen mit Tarnvorrichtung, nur an Directorate-Ausrüstern, C/D, B ab Stufe 2, A ab Stufe 3/Militär): Die Drohnen werden zu Axiom-„Cloak Drones“ (eigenes Aussehen: Graphit, cyanfarbene Lichtlinie) und tarnen sich mit dem Schiff – getarnt schießen und schürfen sie nicht, sondern halten sich beim Träger; sie tauchen mit dem Schiff wieder auf.
- [x] **Debug-Funktion:** Debug-Menü → Ship: „+10 exotic matter (Threshold)“ (setzt auch die Abklingzeit zurück).

**Nachtrag 0.4.25.41 (Kanayama-maru, Wunsch Luz):** Händler am Bordmarkt parken in etwa 1.600 km Abstand und schicken eine **Frachtdrohne**: Sie fliegt über das Heck an, landet auf dem Runway, rollt aus, lädt die Ware (der Handel passiert an Deck), startet über den Runway am Bug und fliegt zurück – erst dann zieht der Händler ab. Immer nur eine Drohne auf dem Runway (auch nicht, während eigene Drohnen starten), weitere warten in der Anflugschleife. Ohne Flugdeck handeln Händler wie bisher direkt.

### Stationstyp 0 (Paket 26)

- [x] **Neuer Stationstyp 0:** lässt nur S- und M-Schiffe landen und kann als **zusätzliche Station in allen Systemen** vorkommen.

**Umgesetzt 26 (7. Nov 2026, alpha 0.4.25.42)** – „Waystation“ (Raststation) mit Landeplattformen statt Hangarbuchten (Vorschlag Luz), 5 neue automatische Prüfungen:

- [x] **Aussehen:** kleiner Kern mit Ring und Kuppel, auf Streben runde **Landeplattformen** (2 / 3 / 4 nach Stufe) – Warnstreifen-Rand, gelber Landekreis, Lichter, in der Mitte eine **Luke**; ab Stufe 2 ein Solarsegel. Bernsteinfarbener Akzent.
- [x] **Landen:** Anflug über die Plattform, Ausrichten zur Station, Aufsetzen, die Lukentüren gleiten auf und das Schiff sinkt hindurch (wird kleiner und dunkler). **Starten:** Luke auf, das Schiff steigt auf, Luke zu, dann hebt es nach außen ab.
- [x] **Immer nur ein Schiff pro Plattform** beim Landen oder Starten – wer keine freie Plattform bekommt, wartet außerhalb (bzw. beim Start im Inneren). Statuslampe je Plattform: grün frei, gelb blinkend belegt.
- [x] **Nur S- und M-Schiffe** (`max_size` 2): L-Schiffe des Piloten werden abgewiesen; zu großer NPC-Verkehr endet seine Fahrt dort ohne Plattform.
- [x] **Verbreitung:** in rund drei Vierteln aller Systeme eine Raststation (zusätzlich zum Stationsplan), draußen auf dem Weg zu einem Sprungtor; Stufe 1 (55 %), 2 (33 %), 3 (12 %). Im Testfeld eine je Stufe.
- [x] **Angebot** (laut Entscheidung zu Teil 4): feste kleine Auswahl – **Markt, Treibstoff, Reparatur, Hangar**; keine Werft, kein Ausrüster, keine weiteren Dienste (seit 0.4.25.43; in 0.4.25.42 versehentlich mehr). Der Markt erzeugt Wasser und Nahrung und braucht Elektronik, Medizin, Deuterium.

### Ausrüster & Übersicht (Paket 27)

- [x] **Erweitert (Wunsch Luz, 7. Nov 2026): neue Stationsübersicht** (Concourse) in drei Spalten statt des 3×4-Kachelrasters, angelehnt an ein Fan-Referenzbild:
  - **links oben – Commander** (Platzhalter): Pixel-Silhouette als Porträt, CMDR-Name, Rang (noch „—“), Schiffe, laufende Aufträge, Flugzeit; Porträt und Karriere-Statistik folgen später.
  - **links unten – News:** die neuesten 6 Meldungen als Karten (NEWS / RAID / RADIO farbig), darunter die Kachel zum Nachrichtenarchiv.
  - **Mitte – Schiffsanalyse:** Schiffsbild, Name, Rumpf, Klasse, Größe; Balken für Hülle, Panzerung, Tank, Fracht, Drohnen; darunter die **Schiffsdienste**: Tanken und Reparieren direkt per Klick (mit Preis, „full“ / „No damage“), Drone Bay, Ausrüster, Hangar.
  - **rechts – Station:** Wappen, Name, Typ, Stufe, System, Sicherheit, Fraktion mit eigenem Ansehen, Wirtschaft (erzeugt / braucht), **Kontostand**; darunter die **Stationsdienste** als längliche Kacheln mit Icons (Markt, Werft, Raffinerie, Fertigung, Bond Office, Bulletin Board) – nicht verfügbare gedimmt mit Grund. Hilfslieferungen nach einem Überfall erscheinen hier.
- [x] **Überarbeitung des Ausrüsters** (nach Referenzbild von Luz, alpha 0.4.25.44):
  - **links** Kategorie-Kacheln: Waffen, Werkzeuge, Kern, Optionales, Drohnenhangar, Lager.
  - **daneben** die Plätze des angedockten Schiffs in dieser Kategorie (Platz, Maximalgröße, eingebautes Modul in Qualitätsfarbe).
  - **rechts** für den gewählten Platz die vorrätigen **Modulfamilien als Kacheln** (Icon, Anzahl, wie viele passen, Schadensart; Tooltip mit Kurzbeschreibung), dann **Größe · Qualität als Kacheln** mit Preis („too big“ / gesperrt gedimmt). Bei **Kern-Plätzen** entfällt die Familienwahl – direkt Größe · Qualität, je Familie eine Reihe. Module aus dem eigenen Lager erscheinen oben.
  - **Auswahl:** Name, **Kurzbeschreibung**, Werte und **wie sich das Schiff ändert** (grün besser, rot schlechter; Warnung bei Stromüberlast); **„Buy & fit“** baut direkt ein (das alte Modul geht ins Lager), „Buy to storage“, „Fit from storage“, „Remove → storage“.
  - **Fußzeile:** wichtigste Schiffswerte (Geschwindigkeit, Wendigkeit, Masse, Kondensator, Schild, Panzerung, Hülle, DPS, Fracht, Treibstoff, Sensoren, Signatur) und **Stromverteilung** als Balken – mit der Änderung der aktuellen Auswahl.
  - Neuer Befehl `module_buy_fit`.
- [x] **Kurzbeschreibung** zu jeder der 75 Modulfamilien (data/module_desc.gd) – im Ausrüster und in jeder Modul-Zusammenfassung (auch in den Tooltips der Modulübersicht im Schiffsmenü).
- [x] **Derzeitige Geschwindigkeit** in der Schiffsinfo am linken Rand – als Zahl mit Einheit („Speed 123 km/s“, im Warp „WARP“; seit 0.4.25.45 ohne Balken, Wunsch Luz).

### Code-Review Teil 4

Read-only-Review in eigener Session (7. Nov 2026), Bericht in `reviews/teil4_review.md`: keine kritischen, 7 wichtige und 14 kleinere Befunde, 6 Performance-Punkte, Koop-Hinweise, Aufräumliste, 9 Smoke-Test-Lücken.

**Behoben in alpha 0.4.25.46 (die Top 5), 6 neue automatische Prüfungen:**

- [x] **W2** Start-Warteschlangen von Flugdeck und Drohnenluke liefen nicht zurück – Drohnen, die vor dem Abheben eingeholt oder zerstört werden, geben ihren Platz frei; Andocken setzt beide auf 0 (sonst warteten spätere Starts und Händlerdrohnen ewig). Die manuellen Zähler-Resets im Smoke-Test sind entfernt.
- [x] **W1** Ein neuer Befehl während Anflug oder Landung bricht sauber ab: Plattform frei, Luke zu, Schiff wieder in voller Größe und Farbe.
- [x] **W3** Die gebündelte Fokuslanze zieht den Strom aller Kristalle und feuert nur, wenn alle Strom haben.
- [x] **W5** Punktverteidigung, Automodus, Antidrohnenpuls und die Minenwerfer-Einstellungen liegen im Fitting (gespeichert) und überstehen Sprünge, Laden und Andocken.
- [x] **W4** Wer in der Raststation auf eine freie Plattform wartet (oder noch nicht aufgestiegen ist), ist weder anvisierbar noch verwundbar.
- [x] **W6** Wurmloch-Sprung: nicht aus dem Warp oder beim Andocken; die Drohnen werden vorher eingeholt und starten nach der Ankunft wieder.

**Behoben in alpha 0.4.25.47 (der Rest), 8 neue automatische Prüfungen:**

- [x] **W7** Ein NPC-Träger, der springt, andockt oder abzieht, nimmt seine Drohnen still mit – keine Explosionen mehr am Tor; nur bei Zerstörung des Trägers gehen sie hoch.
- [x] **K1** Ortsanzeige auch im Wurmloch-Transit („Wormhole → Ziel“). **K2** Ein Treffer (Mine, Explosion) beendet die Tarnung; die Tarnung kostet auch im Warp Energie; getarnte NPCs benutzen keine Werkzeuge. **K3** Hinweis im Fabrik-Reiter: läuft nur auf dem aktiven Schiff im All. **K4** Fabrikaufträge eines zerstörten Schiffs verschwinden mit ihm. **K5** Drohnen zählen zum Schiffswert. **K6** Die Händlerdrohne belegt die Startbahn, solange sie landet, lädt und startet – eigene Drohnen warten. **K7** Die Fokuslanze bricht ab, wenn das Ziel warpt, sich tarnt oder weit aus der Reichweite gerät. **K8** Ein Blick ins leere Lager legt keinen Eintrag mehr an. **K9** Der Ausrüster nennt den echten Grund („too big“ oder „not for this ship“). **K10** Der Debug-Teleport parkt L-Schiffe nie an einer Raststation. **K11** Plattformen werden alle 0,5 s von verschwundenen Schiffen befreit. **K12** Kurzbeschreibungen an die Daten angepasst (Raketen lenkbar, Taktik-Sensoren, Ionentorpedo, Zielcomputer). **K13** Fabrik/Raffinerie, die auf Platz warten, zeigen den eigenen Zustand „wait“ statt „außer Reichweite“. **K14** NPC-Tarnung kostet Energie.
- [x] **Performance:** Strom-Plan nur noch bei Änderungen (P1), Drohnenlisten einmal pro Frame (P2), Drohnenklappen, Art-Breite und Texturgröße je Rumpf zwischengespeichert (P3–P5).
- [x] **Koop:** Tastaturflug (WASD) läuft über den Befehlsbus (`key_steer`); die Simulationsfunktionen, die direkt in den Spielstand schreiben, sind als „nur auf dem Host“ markiert.
- [x] **Aufräumen:** `ShipFitting.describe()` entfernt, Abdunkel-Formel als `_hangar_shade`, verrutschter Kommentar korrigiert, `module_summary_lines()` statt Zerlegen von Text.
- [x] **Test-Lücken** T1, T2, T4–T9 geschlossen.
- Bewusst nicht gemacht: P6 (Stationen zeichnen jeden Frame neu – schon vor Teil 4 so), Umbau von `builtin_modules()` in eine Tabelle (wenig Nutzen, Risiko), zentrales Drohnen-Einholen (Warp und Sprung sind zwei verschiedene Ereignisse), Test T3 (Wurmloch mit ausgeflogenen Drohnen – bräuchte einen Threshold als Spielerschiff im laufenden System).

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
| 28a ✓ | Audio-Grundgerüst | Spielereignisse (Andocken, Warp, Sprung, Treffer, Explosion, Modul an/aus, UI) lösen Sounds aus – zunächst mit Platzhaltern; Lautstärke-Regler für Gesamt, Musik, Atmosphäre und Effekte. Ab da bringt **jedes Paket seine Sounds gleich mit**; Musik, Atmosphäre und Feinschliff folgen in Teil 9 (Paket 69) | – |
| 28 ✓ | Pilot & Charaktererstellung | Pilot als eigene Ebene im Spielstand; Sprite-Baukasten (Pixel-Art), Porträt aus dem Sprite; Name/Rufzeichen; Attribute verteilen; neuer Ablauf „Neues Spiel“ | – |
| 29 ✓ | Fähigkeiten | Fähigkeiten aus Attributen abgeleitet, steigen durch Tun; kleine Prozent-Boni im Spiel; Charakter-Reiter im Schiffsmenü | 28 |
| 30 ✓ | Skilltree & Baupläne | erste Fortschrittsmechanik: Module, Größen, Qualitäten und Schiffsklassen werden durch Tun freigeschaltet (nicht zeitbasiert wie EVE); dazu **Baupläne** für die Herstellung | 29, Teil 4 |
| 31 ✓ | Crew-System & The Bar | (mit 32 zusammengelegt, 7. Nov 2026) Crew-Slots je Schiff mit Pflicht-Rollen, zufällige Crewmitglieder (Name, Porträt, Profession, Qualität F–A, gewürfelter Bonus, seltene Perks), prozentuale Abgabe, Aufstieg durch Tätigkeit, Crew-Reiter im Schiffsmenü, neuer Service **The Bar** zum Anheuern, Skilltree-Anbindung | 29, 30 |
| 31a ✓ | Game Over überarbeiten | gewichtete Überlebenswürfe der Crew, Rettungskapsel mit Zeitlimit, Fenster „Schiff zurückkaufen“ (~10 % des Werts mit Modulen) oder Anfängerschiff, Respawn an der letzten Station | 31 |
| 32 | _(in 31 aufgegangen)_ | Crew aus Aufträgen folgt mit Teil 7 (Ausbau der Bar) | – |
| 33 ✓ | Wingmen (Söldner: Teil 7) | anheuerbare Piloten mit eigenem Schiff fliegen im Verbund; einfache Befehle; Free Captains als Söldner | 31, 32 |
| 34 ✓ | Codex, Sammlung, Steckbriefe, Feinschliff | Codex-Einträge, Hinweise beim ersten Kontakt, Smoke-Tests, Balancing der Boni | alle |

**Umgesetzt 28a (7. Nov 2026, alpha 0.5.28.1)** – Audio-Grundgerüst, 5 neue automatische Prüfungen:

- [x] **Audio-Autoload** (`scripts/autoload/audio.gd`): Sounds per ID (`assets/sfx/<id>.wav`, später auch `.ogg`); Einzel-Sounds (`play`), Sounds im All mit Entfernungs-Abschwächung zur Kamera (`play_at`, hörbar bis 9.000 km), Loops per Schlüssel (`loop`). 24 Stimmen; derselbe Sound höchstens 4× gleichzeitig und nicht schneller als alle 45 ms; bei Engpass wird die älteste Stimme übernommen. Leichte Tonhöhen-Variation, damit Wiederholungen nicht gleich klingen.
- [x] **Kanäle:** Master → Music, Ambience, SFX (UI läuft über SFX). **Einstellungen:** je ein Regler für Gesamt, Musik, Atmosphäre und Effekte (gespeichert).
- [x] **36 Platzhalter-Sounds der Priorität A**, synthetisch erzeugt (`tools/audio/make_placeholders.py`) nach den Klangvorschlägen; eine echte Datei mit gleichem Namen ersetzt sie ohne Code-Änderung.
- [x] **Angeschlossene Ereignisse:** Triebwerk (Loop nach Geschwindigkeit), Warp (Aufladen, Eintritt, Austritt, Herausreißen), Sprung (Tor lädt, Hyperraum), Andocken/Abdocken, Waffen nach Art (optisch, Strahl, kinetisch, explosiv) für alle Schiffe in Hörweite, Treffer je Schicht (Schild, Panzerung, Struktur), Schild bricht zusammen, Explosion klein/groß, Ziel erfasst, Modul an/aus/verweigert, Bergbaulaser (Loop), Survey-Scan, Drohnenstart, Klicks auf allen Knöpfen und Kacheln, Fenster auf/zu (Station, Schiffsmenü), abgelehnte Befehle, Kaufen/Verkaufen, Auftrag erfüllt, Meldungen (gut / Warnung, höchstens eine pro Sekunde), Alarm bei kritischer Struktur, Weltraum-Atmosphäre.
- [x] **Debug-Funktion** (Debug-Menü → Audio): jeden Sound einzeln abspielen, Pegel je Kanal live, Ereignis-Mitschrift (welches Ereignis welchen Sound ausgelöst hat), alle Loops stoppen.

**Menüsteuerung per Tastatur (7. Nov 2026, alpha 0.5.28.2, Wunsch Luz):**

- [x] In allen Menüs (Hauptmenü, Pause, Einstellungen, Tastenbelegung, Spielstände, Station mit allen Diensten, Schiffsmenü, Codex, Debug): **W/A/S/D** (und die Pfeiltasten) bewegen die Markierung zum nächsten Knopf in dieser Richtung (gelber Rahmen, scrollt mit), **Enter/Leertaste** drücken ihn, auf Schiebereglern ändern A/D den Wert, **Q/E** wechseln die Reiter (Schiffsmenü, Debug-Menü, Ausrüster-Kategorien, Markt-Filter), **Escape** geht wie bisher zurück.
- [x] Solange ein Menü offen ist, gehören die Tasten dem Menü – das Schiff fliegt nicht; in Textfeldern bleiben W/A/S/D Buchstaben.
- [x] Eigene Tastengruppe „Menus“ in der Tastenbelegung (umbelegbar); Menü- und Spieltasten dürfen sich überschneiden, beim Umbelegen wird nur innerhalb desselben Bereichs getauscht.

**Sounds (Liste mit Klangvorschlägen: `docs/audio/sound_list.md`, 7. Nov 2026):** 28a bringt das Grundgerüst mit den **36 Sounds der Priorität A** als synthetische Platzhalter. Der Rest kommt danach:
- **Priorität B (39), nach 28a nach und nach:** `afterburner_on`, `afterburner_loop`, `warp_loop`, `hyperspace_loop`, `wormhole_open`, `pad_hatch_open`, `pad_hatch_close`, `station_hail`, `w_lance`, `w_railgun`, `w_massdriver`, `w_torpedo`, `w_ion`, `w_focus_charge`, `w_focus_burn`, `shield_up`, `lock_progress`, `missile_warning`, `power_overload`, `ore_collected`, `scan_complete`, `cloak_on`, `cloak_off`, `blackhole_ignite`, `drone_recall`, `drone_dock`, `drone_lost`, `ui_hover`, `ui_tab`, `fit_module`, `mission_accept`, `mission_failed`, `codex_entry`, `map_open`, `alarm_fuel`, `alarm_pirates`, `interdict`, `amb_station`, `mus_menu`.
- **Priorität C (28), mit dem passenden Paket bzw. in Teil 9 (Paket 69):** `wormhole_collapse`, `bay_enter`, `pad_touchdown`, `w_cruise`, `w_pointdef`, `mine_drop`, `explosion_mine`, `emp_hit`, `harvester_loop`, `repair_beam_loop`, `shield_boost`, `jammer_loop`, `blackhole_loop`, `refinery_loop`, `factory_loop`, `drone_pulse`, `hatch_open`, `runway_roll`, `standing_up`, `standing_down`, `cargo_full`, `amb_field`, `amb_star`, `amb_veil` (mit Paket 44), `radio_chatter`, `mus_explore`, `mus_combat`, `mus_station`.
- Häufige Sounds (Waffen, Treffer, Klicks) später in 2–3 Varianten; das Grundgerüst wählt zufällig und verändert die Tonhöhe leicht.

**Debug-Funktionen je Paket** (Debug-Menü, neuer Reiter „Character“):

| Paket | Debug-Funktionen |
| --- | --- |
| 28a | Jeden Sound einzeln abspielen; Lautstärke je Kanal live anzeigen; Ereignis-Mitschrift (welches Ereignis welchen Sound ausgelöst hat) |
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

**Umgesetzt 28 (7. Nov 2026, alpha 0.5.28.3)** – nach den Entscheidungen von Luz (Porträt 48×48, Grundausstattung + Gesichtsdetails + Sci-Fi-Extras, Aussehen-Dienst an Stationen, „Neues Spiel“ nur mit Name, Aussehen und Attributen), 6 neue automatische Prüfungen:

- [x] **Pilot als eigene Ebene im Spielstand:** Name, Rufzeichen (optional), Aussehen, Attribute; alte Spielstände bekommen ein Standard-Aussehen und verteilte Standardwerte.
- [x] **Pixel-Baukasten** (`scripts/core/pilot_art.gd`): ein „Look“ erzeugt das **Porträt (Brustbild 48×48)** und den **Draufsicht-Sprite (16×16, für Teil 7)** aus denselben Teilen. 15 Optionen mit 94 Wahlmöglichkeiten – **Grundausstattung:** Körperform (3), Hautton (8), Frisur (9: Glatze, Buzz Cut, Kurz, Seitenscheitel, Lang, Pferdeschwanz, Irokese, Locken, Dutt), Haarfarbe (10, auch Neonpink und Cyan), Augenfarbe (6), Kleidung (4: Fliegeranzug, Jacke, Panzeranzug, Mantel) mit Haupt- und Akzentfarbe (je 14). **Gesichtsdetails:** Augenbrauen, Bart (5), Narbe (4), Sommersprossen. **Sci-Fi-Extras:** Implantat (Cyber-Auge, Kieferplatte, Schläfen-Schaltkreise), Tattoo (Wangenlinien, Stirnzeichen, Halslinien), Kopfteil (Headset, Visier, Brille). Zufalls-Look (Extras seltener) – später auch für Crew und Söldner.
- [x] **Charaktererstellung beim neuen Spiel:** links Porträt groß und Draufsicht, Mitte der Baukasten (jede Option mit ‹ ›, „Random look“), rechts Name, Rufzeichen und die fünf Attribute (alle ab 3, 8 freie Punkte, höchstens 8; Start erst, wenn alle Punkte verteilt sind) und der Galaxie-Seed. Mit Maus und Tastatur bedienbar.
- [x] **Image Studio** (neuer Stationsdienst, Monopol **Visage Clinics** [VSG], neues Icon): Aussehen ändern für 2.500 cr (nach Ansehen), Attribute bleiben fest. Nicht an Raststationen (feste Dienste).
- [x] **Concourse:** echtes Porträt, „CMDR Name »Rufzeichen«“ und die fünf Attribute statt des Platzhalters.
- [x] **Debug-Funktion** (Debug-Menü → Character): Charaktererstellung jederzeit öffnen, Zufalls-Pilot, Attribute frei setzen (1–20, auch über die Startgrenzen hinaus).

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

**Umgesetzt 29 (7. Nov 2026, alpha 0.5.29.1)** – nach den Entscheidungen von Luz (Aufstieg durch Tun + Bestätigen, eigenes Fenster), 4 neue automatische Prüfungen:

- [x] **Zwölf Fähigkeiten** (`data/skills.gd`) wie in der Tabelle, Stufe 0–10, **+1 % je Stufe** auf ihre Wirkung. Die Attribute bestimmen die **Startstufe** (0 bei Mittelwert 3, 1 ab 5,5, 2 bei 8) und das **Lerntempo** (×0,9 bei 3 bis ×1,4 bei 8). Erfahrung für die nächste Stufe: 100 × (Stufe+1)^1,5.
- [x] **Aufstieg durch Tun** *(seit 0.5.29.2 automatisch, ohne Bestätigen – Entscheidung Luz; davor:)* Jede Fähigkeit sammelt Erfahrung aus ihrer Tätigkeit – Piloting (Warps, Andocken), Gunnery (Treffer auf Feinde), Engineering (Fertigung), Science (Analysen, Surveys), Navigation (Sprünge, Wurmlöcher), Mining (Abbau, Raffinieren), Trading (Handel am Markt), Negotiation (Aufträge), Electronics (Radarstörer). Ist genug da, meldet das Log den Aufstieg und im HUD erscheint „▲ n skills ready to advance [U]“; bestätigt wird im Pilot-Fenster, überschüssige Erfahrung bleibt erhalten. Leadership wächst erst mit den Crews (Paket 31), Athletics und Firearms ab Teil 7.
- [x] **Nachtrag 0.5.29.2** (neue Entscheidung Luz): Fähigkeiten **steigen automatisch** auf (Meldung im Log und Klang), der Bestätigen-Knopf entfällt. Neu ist das **Pilotenlevel** (bis 50): alle Fähigkeits-Erfahrung zählt mit, Erfahrung für das nächste Level 250 × Level^1,4; **jedes Level bringt einen Perkpunkt** (die Perks kommen mit Paket 30). Das Pilot-Fenster zeigt Level, Erfahrung und Perkpunkte, der Concourse „Pilot level n“. Die Boni wirken nur auf Schiffe, die der Pilot besitzt.
- [x] **Wirkung** (nur auf den eigenen Schiffen): Piloting – Geschwindigkeit, Beschleunigung, schnelleres Ausrichten; Gunnery – Waffenschaden, schnellere Zielerfassung; Engineering – Reaktorleistung, kürzere Schild-Ausfallzeit; Science – Reichweite von Scannern und Survey; Navigation – Warp-Tempo, weniger Sprung-Treibstoff; Mining – Abbaurate; Trading – Kauf- und Verkaufspreise (je die Hälfte); Negotiation – Auftragsbelohnung; Electronics – Reichweite des Radarstörers.
- [x] **Pilot-Fenster** (eigene Taste **U**, auch über der Station, mit Tastatur bedienbar): Reiter **Skills** (Karten mit Stufen-Balken, Erfahrung, Lerntempo, Wirkung jetzt, „Grows by“, Knopf „Advance“), **Skill tree** (die sechs Zweige als Vorschau – Inhalt mit Paket 30), **Pilot** (Porträt groß, Attribute, Werdegang).
- [x] **Debug-Funktion** (Debug-Menü → Character): jede Fähigkeit auf eine Stufe setzen oder Erfahrung geben; die wirkenden Boni des aktiven Schiffs ohne → mit Fähigkeiten.

#### Skilltree (Paket 30) – die erste Fortschrittsmechanik

- **Entschieden (7. Nov 2026, Luz):** Fortschritt hat drei Ebenen:
  1. **Fähigkeiten** steigen **automatisch** durch Tun und geben Prozent-Boni (umgesetzt 0.5.29.2).
  2. Das **Pilotenlevel** schöpft aus aller Erfahrung; **jedes Level bringt einen Perkpunkt** (umgesetzt 0.5.29.2). **Perks** sind besondere Fähigkeiten, aufgeteilt in Aktivitätsgruppen; der Punkt wird frei ausgegeben, manche Perks verlangen eine Mindeststufe der passenden Fähigkeit.
  3. Der **Skilltree** ist ein **Baum aus Kacheln**, die sich von Kachel zu Kachel weiterführen. Eine Kachel wird frei, wenn ihre Vorgänger frei sind und ihre **Leistungen** erfüllt sind (z. B. „5.000 Erz abgebaut und 2.000 an Stationen raffiniert“). Dann leuchtet sie und wird **im Pilot-Fenster bestätigt** – keine Punkte.
- **Startumfang** (bis das Story-Intro in Teil 8 kommt): frei sind die **Earthworks-Schiffe der Größe S** und **Module bis Qualität C** (in den kleinen Größen); über den Baum kommen **M- und L-Schiffe, Manufaktur-Schiffe, größere Module, Qualitäten B und A, Spezialausrüstung** (Drohnen, Minen, E-War, Interdictor) und **Baupläne**. Vorschlag: Schiffe und Module, die man schon besitzt, bleiben nutzbar.

**Umgesetzt 30 (7. Nov 2026, alpha 0.5.30.1)** – Vorschlag unten von Luz angenommen („Passt“), 4 neue automatische Prüfungen:

- [x] **Skilltree** (`data/skilltree.gd`): 40 Kacheln in 8 Zweigen (Flight, Industry, Blueprints, Combat, Commerce, Science, Equipment, Mastery) wie in der Tabelle unten. Eine Kachel wird frei, wenn ihre Vorgänger offen und ihre **Leistungen** erfüllt sind; dann leuchtet sie grün und wird im Pilot-Fenster mit „Open“ bestätigt. „Drone Operations“ braucht nur eine seiner zwei Leistungen.
- [x] **Leistungen werden gezählt:** Warps, Sprünge, besuchte Systeme, Erz abgebaut, an Stationen raffiniert, Module gefertigt, Märkte gehandelt, Umsatz, Piraten zerstört, Kopfgeld-Aufträge, Aufträge für Covenant / Assembly, Passagiere, Anomalien, Exotic Matter, gescannte Schiffe, eingelöste Kopfgelder, Pilotenlevel.
- [x] **Sperren beim Kaufen und Bauen** (was man besitzt, bleibt nutzbar): Schiffe in der Werft; Module am Ausrüster (Spezialausrüstung, Qualität B/A, Waffen Größe 3/4, Optionales/Werkzeuge/Drohnenmodule ab Größe 3 – **Kernmodule richten sich nach dem Schiff**, Abweichung vom Vorschlag, damit man z. B. den Reaktor eines freigeschalteten M-Schiffs ersetzen kann); **Baupläne** für die Fertigung an Stationen und in der Bordfabrik (Größe 1–2 frei, 3–5 und 6+ über den Baum). Der Ausrüster zeigt gesperrte Varianten mit „skill tree“, die Werft den Grund.
- [x] **24 Perks** in sechs Gruppen wie in der Tabelle; ein Perkpunkt je Pilotenlevel, manche brauchen eine Fähigkeitsstufe; Crew Morale und Wing Commander sind erst ab Paket 31 / 33 wählbar. Alle übrigen wirken bereits (Reichweite, Strukturschaden, Ziele, Kopfgeld, Nachbrenner, Ausrichten unter Beschuss, Sprung-Treibstoff und -Aufladen, seltene Bonus-Erze, mehr Ausbeute, Raffinerie, Fertigung, Analyse, Survey, Scans, getarnte Schiffe auf 2.000 km, Erz-/Barrenpreise, **Market Insider** zeigt am Markt „↗ Preis“ und wo es in den Nachbarsystemen am besten verkauft, Ansehen, Strafen, Drohnen, Geleitschutz).
- [x] **Pilot-Fenster** mit vier Reitern: Skills, **Perks** (Gruppen mit „Take“), **Skill tree** (in 0.5.30.1 Zweige als Kachel-Ketten, seit 0.5.30.2 der gezeichnete Baum), Pilot. **HUD:** „▲ n tiles to open • m perk points [U]“.
- [x] **Debug-Funktion** (Debug-Menü → Character): „Unlock everything“-Schalter (alle Kacheln und Baupläne), einzelne Kachel öffnen, Baum zurücksetzen, Perkpunkte geben. Im Testsystem ist alles offen.

**Perks (angenommen 7. Nov 2026)** – je Gruppe vier, in Klammern die nötige Fähigkeitsstufe:

| Gruppe | Perks |
| --- | --- |
| Combat | **Sharpshooter** (Gunnery 3): Waffenreichweite +10 % · **Hull Breaker** (Gunnery 5): +15 % Schaden gegen Struktur · **Quick Lock** (Gunnery 2): ein Ziel mehr gleichzeitig · **Bounty Hunter**: Kopfgelder +15 % |
| Flight | **Afterburner Discipline** (Piloting 3): Nachbrenner −25 % Energie · **Emergency Warp** (Piloting 5): Ausrichten unter Beschuss −30 % · **Fuel Saver** (Navigation 3): Sprung-Treibstoff −15 % · **Gate Runner** (Navigation 5): Sprung-Aufladen −25 % |
| Industry | **Prospector's Eye** (Mining 3): höhere Chance auf seltene Bonus-Materialien in Asteroiden · **Deep Core** (Mining 5): Asteroiden geben 20 % mehr her · **Efficient Refining** (Mining 4): Raffinerie-Ausbeute +10 % · **Master Builder** (Engineering 4): Fertigung 25 % schneller, öfter bessere Qualität |
| Science | **Anomaly Hunter** (Science 3): Anomalien 25 % schneller analysiert · **Long Survey** (Science 5): Survey-Reichweite +30 % · **Signal Reader** (Electronics 3): Warrant- und Frachtscans doppelt so schnell · **Ghost Hunter** (Electronics 5): getarnte Schiffe auf 2.000 km sichtbar |
| Commerce | **Haggler** (Trading 3): Erze und Barren +5 % beim Verkauf · **Market Insider** (Trading 5): Galaxiekarte zeigt Preise der Nachbarsysteme · **Diplomat** (Negotiation 3): Ansehen aus Aufträgen +25 % · **Fine Print** (Negotiation 5): Strafen beim Scheitern halbiert |
| Command | **Drone Wrangler** (Electronics 3): eine Drohne mehr gleichzeitig · **Convoy Shepherd**: Geleitschutz-Belohnung +20 % · **Crew Morale** (Leadership 4, ab Paket 31): Löhne −15 % · **Wing Commander** (Leadership 3, ab Paket 33): Söldner +10 % |

**Umgebaut 0.5.30.2 (7. Nov 2026, nach der Zeichnung von Luz)** – ein **neues Spiel ist nötig**, 1 neue automatische Prüfung (alle angepasst):

- [x] **Der Baum ist gezeichnet:** unten der **Stamm „Pilot Licence“** (später gibt ihn das Story-Intro aus Teil 8), darüber **Shields**, von dort fächern die **Äste nach Tätigkeiten** auf – mit geschwungenen goldenen Linien (offen = gold, bereit = grün, erreichbar = matt, gesperrt = dunkel; der Ast wird nach oben dünner). Die **Meisterschaft** (Qualität, Modulgrößen über das Pilotenlevel) liegt als **Wurzeln** links und rechts in der Erde. Der Baum ist größer als das Fenster: **mit der Maus ziehen**, mit **W/A/S/D** von Kachel zu Kachel, Enter oder Klick öffnet eine bereite Kachel; rechts das **Detailfeld** (was die Kachel nutzbar macht, woraus sie wächst, Leistungen mit Balken, „Open“).
- [x] **Gliederung nach Tätigkeit statt nach Hersteller**, manche Modultypen mit eigener Kachel (z. B. bessere bzw. andere Schilde).
- [x] **Alles ist kaufbar, nutzbar erst mit der Kachel:** ein Schiff ohne Kachel **legt nicht ab**; ein Modul ohne Kachel bleibt **offline** (Ausrüster: „offline: skill tree“, Werft: Hinweis); **Kernmodule** ohne Kachel lassen sich nicht einbauen, schon eingebaute laufen weiter (die Standard-Ausstattungen der Schiffe). **Station Manufacturing** schaltet die Fertigung an Stationen frei, Baupläne bleiben (Größe 1–2 / 3–5 / 6+).

**Nachtrag 0.5.30.3 (7. Nov 2026, Wunsch Luz):**

- [x] **HUD-Leiste umgebaut:** oben rechts drei Knöpfe mit Pixel-Icons – **Ship** [I], **Pilot** [U] (leuchtet grün, wenn Kacheln oder Perkpunkte warten) und **Map** [M]. In 0.5.30.4 nach oben rechts verschoben (dorthin, wo die alten Knöpfe waren). Die Knöpfe für Zoom, Station und Hilfe sind weg, die Tasten (F1–F3, L, H) bleiben.

**Nachtrag 0.5.30.5 (7. Nov 2026, Wunsch Luz):**

- [x] **Pilot-Fenster neu geordnet:** der Reiter **Pilot** steht vorne und **U öffnet immer ihn**. Darin drei Unterreiter: **Info** (Porträt, Name/Umbenennen, Level, Attribute und alle Statistiken: Finanzen, Flug & Kampf, Arbeit, Aufträge), **Standings** und **Codex** (beide aus dem Schiffsmenü hierher verlegt). Das Schiffsmenü behält Info (Nachrichten, aktives Schiff, Aufträge, Flotte), Modules, Ship, Inventory, Transactions, Industry, Market. Der HUD-Hinweis öffnet Skilltree bzw. Perks.
- [x] **Schnelle Teil-Tests:** `-- --smoketest --only=pilot,codex,…` führt nur die genannten Testgruppen aus (Absprache: bei kleinen Änderungen nur die betroffenen Tests, beim nächsten großen Paket wieder der volle Lauf).

**Skilltree-Kacheln (0.5.30.2)** – → = wächst aus der vorigen Kachel; Manufaktur-Schiffe brauchen weiterhin auch das Ansehen der Fraktion:

| Ast | Kacheln, Leistungen und was sie nutzbar machen |
| --- | --- |
| Stamm | **Pilot Licence** (frei): Dragonfly, Skiff, Grundmodule (Standardpanzerung, chemische und Ionen-Triebwerke, Verteiler, Spaltreaktor, Tank, Sprungantrieb, Grundsensoren, Pulslaser, Bergbaulaser, Scanner, Analyzer, Salvager, Frachtregal, Zusatztank) → **Shields**: 1 Warp – Schildgenerator |
| Defence | **Advanced Shields** (Kondensator- und Schnellschilde): 5.000 Schaden eingesteckt → **Shield Support** (Schild-Booster, Schild-Transfer): 20.000 · **Armour** (Panzerplatten, Reflex- und Ablativpanzerung, Reparatur): 5.000 |
| Combat | **Light Weapons** (Autokanone, Raketen, Strahlwaffe): 3 Piraten → **Fighters** (Hornet, Talon, Acolyte, Demos): 5 → **Gunships** (Warden, Maul, Templar, Quirinus): 25 Piraten, 3 Kopfgeld-Aufträge → **Capital Ships** (Bastion, Goliath, Citadel, Cathedral, Concordia): 100 / 10. Daneben **Heavy Weapons** (Größe 3, Railgun, Massenbeschleuniger, Lanze, Torpedo): 25 → **Capital Weapons** (Größe 4, Marschflugkörper): 75 · **Point Defence & Mines**: 20 · **Focus Crystals**: 10 Aufträge für den Covenant |
| Mining | **Mining Operations** (Erzlager, Prospektor, Bergbau-Verstärker): 300 Erz → **Mining Ships** (Drillhead, KHI Mogura): 1.000 → **Ice Harvesting**: 2.000 · **Mining Frigates** (KHI Anaguma, Strip Miner): 5.000 abgebaut, 2.000 raffiniert → **Mining Barges** (KHI Iwakudaki): 30.000 / 10.000 → **Heavy Industry** (Kanayama-maru, wächst auch aus Blueprints II): 10 Märkte, 20 Module gefertigt |
| Industry | **Station Manufacturing** (Fertigung an Stationen, Baupläne Größe 1–2): 1.000 an Stationen raffiniert → **Blueprints II** (bis Größe 5): 20 Module gefertigt → **Blueprints III** (alle Größen): 100 |
| Flight | **Navigation** (Nachbrenner, Radar): 25 Warps, 10 Sprünge → **Advanced Propulsion** (Plasmatriebwerk, Fusionsreaktor, Präzisionsverteiler, Kondensator, Solarsegel): 100 / 40 |
| Exploration | **Survey** (Survey-Werkzeug, Verstärker, Gravimetrie): 3 Anomalien → **Research Ships** (Axiom Parallax): 10 → **Wormhole Research** (Axiom Threshold): 40 Anomalien, 3 Exotic Matter, 100 Sprünge |
| Security | **Scanning** (Warrant- und Frachtscanner, taktische Sensoren, Zielcomputer): 5 Piraten → **Electronic Warfare** (Störsender): 30 gescannte Schiffe → **Interdiction**: 10 eingelöste Kopfgelder |
| Trade | **Freight** (Mule): 3 Märkte, 50.000 cr Umsatz → **Bulk Freight** (Frachter): 5 / 250.000 · **Passengers** (Massen- und Business-Kabinen): 3 Aufträge → **Liners** (Pearl, Boulevard, Opal): 50 Passagiere → **Megaliner** (Empress, Luxuskabinen): 400 Passagiere, 1 Mio cr |
| Drones | **Drone Operations** (Hangar, erste Drohnenmodule): 2.000 Erz *oder* 25 Piraten → **Advanced Drones** (Schild, Schaden, Waffenreichweite, Tarnung): 10.000 *oder* 75 |
| Wurzeln (Mastery) | **Quality B**: Pilotenlevel 8 → **Quality A**: 18 · **Larger Modules** (bis Größe 4): 5 → **Heavy Modules** (bis 7): 12 → **Capital Modules**: 20 |

- Wie in EVE muss man **lernen, wie Module funktionieren und wie Schiffe zu fliegen sind** – aber **nicht über Echtzeit**, sondern über das, was man tut.
- **Trennung zu den Fähigkeiten:** Fähigkeiten = *wie gut* (Prozent-Boni). Skilltree = *was man darf und kann* (Freischaltungen).
- **Beim Spielstart ist sehr wenig frei:** nur das Startschiff und wenige Grundmodule. Die Grundlagen lernt man später im **Story-Intro (Teil 8)**, das auch schon erste Knoten freischaltet.
- **Was freigeschaltet wird (Vorschlag):**
  - **Schiffsklassen:** das Startschiff von Anfang an; weitere S-, M- und L-Schiffe über Knoten (z. B. „Frigate Operations“, „Cruiser Command“), Spezialschiffe (Bergbau, Industrie, Fracht) über eigene Zweige.
  - **Modulfamilien und -größen:** wenige Grundmodule von Anfang an; weitere Familien, größere Größen und höhere Qualitäten über Knoten der jeweiligen Familie.
  - **Spezial-Ausrüstung:** Drohnen, Minenwerfer, E-War, Interdictor über eigene Knoten.
  - **Baupläne:** Was man in der Fertigung herstellen kann (Module, Waren, Gegenstände), lernt man als Bauplan – wahrscheinlich im Skilltree, im Zweig Industry. Ohne Bauplan keine Herstellung des Gegenstands.
- ~~Woher die Punkte kommen (früherer Vorschlag): Lernpunkte je Zweig~~ – ersetzt durch die Entscheidung oben (Kacheln über Leistungen, Perks über das Pilotenlevel).
- **Zweige:** Flight (Steuerung/Schiffsklassen), Combat, Industry (Bergbau, Raffinerie, Fertigung), Science (Scanner, Anomalien), Commerce (Handel, Ruf), Command (Crew, Söldner).

---

### Teil B – Crews und Söldner

#### Crew-System (Paket 31)

**Vorgaben Luz (7. Nov 2026)** – gehen den älteren Notizen darunter vor; offene Fragen in der Antwort an Luz:

- **Crew-Slots** ab **M** (später evtl. besondere S-Schiffe), sichtbar als **neuer Reiter bei den Schiffsmodulen**. Jedes Schiff legt fest: **Höchstzahl**, **Mindestzahl** (darunter funktioniert es nicht) und **welche Arten** von Slots (Kampfschiff ≠ Bergbauschiff).
- **Crewmitglieder sind zufälliger als Module:** Name (aus einer **sehr großen Liste von Vor- und Nachnamen**, kombiniert), **zufälliges Porträt**, eine **Profession** (= Slot-Art), manche zusätzlich eine **Nebenprofession** (auch auf einem zweiten Posten einsetzbar), eine **Qualitätsstufe D bis A** (später S und S+).
- **Boni** gehören zur Profession (z. B. Co-Pilot: Geschwindigkeit, bestimmte Waffengruppen, Reichweite, Schaden …). **Welche** Boni und **wie hoch** wird je Mitglied **ausgewürfelt** – im Rahmen seiner Qualitätsstufe.
- Die Qualitätsstufe legt auch die **kleine prozentuale Abgabe** fest, die besetzte Crew kostet.
- **Aufstieg:** im Einsatz sammeln sie **sehr langsam Erfahrung** und steigen eine Qualitätsstufe auf – Bonus und Abgabe steigen.

**Antworten Luz (7. Nov 2026):**

1. **Nur die prozentuale Abgabe** – deutlich unter 1 % je Mitglied (große Schiffe haben bis zu 10).
2. Die **sieben Rollen** passen erst mal (Co-Pilot, Gunner, Engineer, Science Officer, Mining Foreman, Quartermaster, Drone Operator), erweiterbar.
3. **Mindestbesatzung = Slot-Arten, die zwingend besetzt sein müssen** (z. B. Bergbauschiff: Mining Foreman).
4. Der **Grundwert wird gewürfelt**, im Rahmen der Qualitätsstufe – das soll zum **Sammeln** anregen.
5. **Nebenprofession** ist ein **superseltener Perk**: das Mitglied kann auch auf einen anderen Slot und hat dort einen anderen Bonus. Dazu weitere **superseltene Perks** – fest, auch ein F-Mitglied kann einen haben, er verbessert sich beim Aufstieg nicht.
6. Erfahrung durch **passende Tätigkeiten**.
7. **Nur aktiv genutzte Crews** kosten.
8. Pakete 31 und 32 **zusammen**: neuer Service **„The Bar“** – vorerst nur der Laden für Crewmitglieder (wird in Teil 7 stark ausgebaut); Anheuern kostet **vorab** etwas. **Neu gekaufte Schiffe** haben die Mindestcrew in **Klasse F** (ohne Perk).
9. **Neues Paket 31a – Game Over überarbeiten:** gewichtete Würfel je Crewmitglied (höhere Qualität = höhere Überlebenschance und längere Zeit, bis die **Rettungskapsel** verschwindet). Nach dem Tod ein **Fenster: Schiff zurückkaufen** für ca. **10 % des Gesamtwerts mit allen Modulen** (ohne Crew). Wer ablehnt oder es sich nicht leisten kann, bekommt das **Anfängerschiff**. **Respawn** an der **letzten Station, an der man angedockt war**.
10. **Skilltree:** schaltet eine Kachel ein Schiff frei, das eine Crew-Art zwingend braucht, wird diese Crew-Art mit freigeschaltet; Crew-Arten, die auf keinem Schiff Pflicht sind, bekommen **eigene Kacheln**.

**Vorschlag Claude (zur Freigabe):**

- **Qualitätsstufen:** **F** (Rookie, nur Standardcrew neuer Schiffe und Bar-Ausschuss, nie mit Perk), D, C, B, A (später S, S+).
- **Abgabe** (Anteil an Verkäufen, Kopfgeldern und Auftragsbelohnungen, nur Crew des aktiven Schiffs): F 0,02 % · D 0,05 % · C 0,1 % · B 0,15 % · A 0,25 % – zehn A-Mitglieder = 2,5 %. Im Log und im Crew-Reiter sichtbar.
- **Bonus:** jedes Mitglied hat **einen** gewürfelten Bonus aus der Liste seiner Profession, Höhe gewürfelt im Rahmen: F 1–2 % · D 2–4 % · C 4–6 % · B 6–9 % · A 9–12 %. Beim Aufstieg wird **die Verbesserung gewürfelt**, nicht der Wert neu (Änderung Luz, 7. Nov 2026): der Bonus steigt um → D +1–2 · → C +1,5–3 · → B +2–3,5 · → A +2,5–4 Prozentpunkte und **darf über dem Höchstwert der neuen Stufe liegen** – ein gut gewürfeltes F-Mitglied kann so als A besser sein als ein frisch angeheuertes A. Die Boni gelten nur auf dem Schiff, auf dem das Mitglied sitzt.

| Rolle | mögliche Boni (einer wird gewürfelt) | Erfahrung durch |
| --- | --- | --- |
| Co-Pilot | Geschwindigkeit · Wendigkeit · Ausrichten zum Warp · Warp-Tempo · Nachbrenner-Energie | Warps, Flugstrecke |
| Gunner | Schaden optisch / kinetisch / explosiv · Waffenreichweite · Feuerrate | Schaden an Gegnern |
| Engineer | Energie-Ausbeute · Kondensator-Aufladung · Schild-Regeneration · Schild-Downtime · Panzerung | Zeit im Kampf, Reparaturen |
| Science Officer | Scan-Reichweite · Analyse-Tempo · Survey-Reichweite · Warrant-/Frachtscan-Tempo | Analysen, Scans |
| Mining Foreman | Abbaurate · Erzlager · Raffinerie-Ausbeute · Drohnen-Bergbau | Erz abgebaut |
| Quartermaster | Frachtraum · Verkaufspreise · Treibstoffverbrauch · Abgabe der übrigen Crew | Umsatz am Markt |
| Drone Operator | Drohnen-Schaden · -Reichweite · -Tempo · -Haltbarkeit | Drohnen im Einsatz |

- **Aufstieg:** sehr langsam – grob F→D nach ca. 2 Std. passender Tätigkeit, D→C 5 Std., C→B 12 Std., B→A 30 Std.
- **Perks** (fest, unabhängig von der Qualität; Chance ca. 4 % pro Mitglied, die Nebenprofession ca. 1 %): **Second Profession** (zweiter Slot mit eigenem gewürfelten Bonus) · **Lucky** (überlebt fast immer) · **Quick Learner** (doppelte Erfahrung) · **Loyal** (keine Abgabe) · **Old Hand** (Bonus +50 %) · **Medic** (bessere Überlebenschance der übrigen Crew) · **Haggler** (die ganze Crew kostet die Hälfte) · **Night Owl** (+Bonus ausschließlich in Systemen mit niedriger Sicherheit).
- **Slots je Schiff** (Pflicht fett), S-Schiffe vorerst ohne Crew:

| Schiffe | Slots |
| --- | --- |
| Mule, Longhaul | **Co-Pilot**, Quartermaster (Longhaul: + Engineer, Quartermaster) – 2 / 4 |
| Drillhead, Anaguma | **Mining Foreman**, Co-Pilot, Engineer – 3 |
| Warden, Templar, Maul, Goliath | **Gunner**, Co-Pilot, Engineer (Goliath + Gunner) – 3 / 4 |
| Quirinus | **Drone Operator**, Gunner, Engineer – 3 |
| Boulevard, Opal | **Co-Pilot**, Quartermaster, Engineer – 3 |
| Bastion | **Gunner**, **Engineer**, Co-Pilot, Gunner, Science Officer, Quartermaster – 6 |
| Iwakudaki | **Mining Foreman**, **Engineer**, Mining Foreman, Co-Pilot, Quartermaster, Drone Operator – 6 |
| Kanayama-maru | **Mining Foreman**, **Engineer**, **Quartermaster**, + 7 weitere gemischt – 10 |
| Threshold | **Science Officer**, **Engineer**, Co-Pilot, Science Officer, Gunner, Quartermaster – 6 |
| Cathedral | **Gunner**, **Engineer**, + 6 weitere – 8 |
| Concordia, Citadel | **Drone Operator**, **Gunner**, **Engineer**, + 7 weitere – 10 |
| Empress | **Co-Pilot**, **Quartermaster**, **Engineer**, + 7 weitere – 10 |

- **Skilltree** nach Regel 10: Co-Pilot (Freight), Mining Foreman (Mining Ships), Gunner + Engineer (Gunships), Drone Operator (Gunships über den Quirinus), Quartermaster (Bulk Freight bzw. Heavy Industry). **Science Officer** ist erst beim Threshold Pflicht → eigene Kachel **„Science Officers“** im Ast Exploration (nach Research Ships). Pflicht-Rollen stehen im Detailfeld der Kachel.
- **The Bar** (Concourse-Service an Stationen mit Werft und an Militär-, Forschungs- und Bergbaustationen): 4–8 Bewerber mit Porträt, Profession, Qualität, Bonus, ggf. Perk; das Angebot wechselt alle ~20 Minuten Spielzeit, der Stationstyp bestimmt die häufigsten Professionen. **Anheuer-Preis vorab:** D ≈ 5.000 · C ≈ 20.000 · B ≈ 75.000 · A ≈ 250.000 cr (gewürfelt ±30 %, Perk teurer). Angeheuerte gehen auf ein Schiff im Hangar oder ins **Crew-Quartier** der Station (wie das Modullager). Entlassen ohne Erstattung.
- **Crew-Reiter** im Schiffsmenü bei den Modulen: Slots mit Rolle und Pflicht-Markierung, Mitglied mit Porträt, Qualität, Bonus, Perk, Erfahrung; tauschen mit dem Crew-Quartier beim Andocken. **Ohne Pflichtcrew kein Abdocken.**
- **Debug:** Crew würfeln (Rolle, Qualität, Perk), Erfahrung geben, Pflichtcrew-Prüfung abschalten, Bar neu würfeln.

**Umgesetzt 31 (7. Nov 2026, alpha 0.5.31.1)** – Vorschlag oben von Luz angenommen („Passt, bauen“, mit gewürfelter Verbesserung beim Aufstieg), 6 neue automatische Prüfungen:

- [x] **Crew-Daten** (`data/crew.gd`): 7 Rollen mit je 4–5 möglichen Boni, Qualitäten F–A mit Rahmen, Aufstiegs-Verbesserung, Abgabe, Erfahrungsbedarf, Anheuer-Preisen; **Slots für alle 19 Schiffe ab M** wie in der Tabelle; **je über 200 Vor- und Nachnamen**; Porträt zufällig aus dem Porträt-Baukasten des Piloten.
- [x] **Crewmitglieder** (`scripts/core/crew.gd`): Name, Porträt, Profession, Qualität, ein gewürfelter Bonus im Rahmen, sehr selten ein **Perk** (ca. 4 %; Second Profession ca. 1 % mit eigenem Bonus auf dem zweiten Posten). Statt „Haggler“ heißt der Perk **Thrifty** (der Pilot-Perk Haggler gibt es schon). Lucky und Medic wirken mit Paket 31a.
- [x] **Wirkung** auf das Schiff, auf dem sie sitzen (Geschwindigkeit, Wendigkeit, Ausrichten, Warp, Schaden je Schadensart, Reichweite, Feuerrate, Energie, Kondensator, Schilde, Panzerung, Scanner, Survey, Sensoren, Abbau, Erzlager, Raffinerie, Drohnen, Fracht, Verkaufspreise, Treibstoff, Crew-Abgabe).
- [x] **Abgabe** der Crew des aktiven Schiffs von Verkäufen (Markt, Bordmarkt), Kopfgeldern und Auftragsbelohnungen – im Log „Crew share“, im Crew-Reiter und in der Statistik.
- [x] **Erfahrung durch passende Tätigkeit** (Warps/Sprünge, Abschüsse, eingesteckter Schaden, Analysen/Scans, Erz, Handel, Drohnen im Einsatz); Aufstieg mit gewürfelter Verbesserung (darf über den Rahmen gehen), Meldung im Log.
- [x] **Pflichtcrew:** ohne besetzte Pflicht-Posten **kein Abdocken**; neu gekaufte Schiffe kommen mit **F-Crew ohne Perk** auf den Pflicht-Posten.
- [x] **Crew-Reiter** im Schiffsmenü (Modules → **CREW n / m**): Posten mit Porträt-Karten, Pflicht-Markierung, Erfahrungsbalken; Posten wählen, ins **Crew-Quartier** der Station schicken, aus dem Quartier einsetzen oder entlassen.
- [x] **The Bar** (Driftwood Taverns, neuer Concourse-Service in der Stationsspalte; seit 0.5.31.2 zeigt die Stationsspalte ihre Services als **rechteckige Kacheln, zwei pro Reihe** – Wunsch Luz; seit 0.5.31.3 wachsen sie samt Icon mit der Fenstergröße, und bei wenig Platz scrollt nur der Service-Bereich): 4–8 Bewerber, Wechsel alle 20 Minuten Spielzeit, Stationstyp bestimmt die häufigsten Professionen; anheuern ins Quartier oder direkt auf einen freien Posten.
- [x] **Skilltree:** Schiffs-Kacheln bringen die Pflicht-Rollen ihrer Schiffe mit (im Detailfeld „crew: …“); neue Kachel **Science Officers** (Exploration, nach Research Ships, 15 Anomalien).
**Umgesetzt 31a (7. Nov 2026, alpha 0.5.31.4)** – 3 neue automatische Prüfungen:

- [x] **Überlebenswurf je Crewmitglied**, gewichtet nach Qualität (F 40 % · D 50 % · C 60 % · B 70 % · A 85 %; Lucky 97 %; ein Medic an Bord gibt den anderen +15 %).
- [x] **Rettungskapsel** am Ort des Wracks: im All sichtbar (weiße Kapsel, rotes Blinklicht, Notruf-Ring), im Radar und **in der Übersicht anwarpbar**; Tooltip mit Namen und Restzeit je Mitglied. Signal hält je nach Qualität **F 5 · D 8 · C 12 · B 16 · A 22 Minuten** Spielzeit, danach ist das Mitglied verloren. Ein eigenes Schiff **näher als 2.500 km nimmt die Kapsel auf**: Überlebende gehen auf freie passende Posten, der Rest fährt mit bis zur nächsten Station (Crew-Quartier).
- [x] **Respawn an der letzten Station**, an der man angedockt war (sonst Heimatstation), zunächst im **Anfängerschiff** (Dragonfly).
- [x] **Fenster „SHIP LOST“:** wer es in die Kapsel geschafft hat und wer nicht, und das Angebot von **Aegis Mutual**, das Schiff **für 10 % seines Werts** (Rumpf, Module, Drohnen – ohne Crew) neu aufzubauen; dann ersetzt es die Dragonfly, mit Rookies auf den Pflicht-Posten. Ablehnen oder zu wenig Geld: die Dragonfly bleibt. Eine offene Entscheidung wird nach dem Laden erneut gefragt. **Seit 0.5.31.5 als Kacheln (Skizze Luz):** Schiff mit Rebuild-Preis, Respawn-Ort mit Stationsbild, Crew (in der Kapsel mit Restzeit / verloren), Fracht & Verluste; rechts die Kosten (Rumpf, Module & Drohnen, Insurance Agent), Total, Restguthaben, REBUILD und TAKE THE STARTER SHIP – mit Sicherheitsabfrage.
- [x] **Neue Perks (Ideen Luz), genauso selten wie die anderen:** **Cargo Insurance** – beim Rückkauf kommt die ganze Fracht mit; **Insurance Agent** – Rückkauf 5 % günstiger. Lucky und Medic wirken jetzt.
- [x] Schiffe, die nicht aktiv sind, verlieren ihre Crew mit dem Schiff.
- [x] **Debug** (Debug-Menü → Ship → Crew): „Lose the active ship“, „Pod signals fade in 10 s“.

- [x] **Debug** (Debug-Menü → Ship → Crew): Pflichtcrew ignorieren, Mitglied würfeln (Rolle, Qualität, Perk) ins Schiff oder Quartier, alle Posten füllen, +250 Erfahrung, neue Gesichter an der Bar.

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

**Vorgaben Luz (7. Nov 2026)** – gehen den älteren Notizen darunter vor:

- Paket 33 sind **erst mal nur Wingmen**. Söldner kommen als gleiche Mechanik für den **Bodenkampf in Teil 7**.
- Wingmen werden **in der Bar** angeheuert, mit **zeitlich festgelegtem Vertrag**: Anheuersumme plus **Anteil** (deutlich höher als bei Crew, je nach Level).
- Wingmen sind **richtige Charaktere** wie der Pilot: Fähigkeiten und ein **Schiff mit echtem Loadout** (beim Anheuern einsehbar). Sie fliegen **im Verbund**, bis der Vertrag abläuft.
- **Befehle** ähnlich wie bei Drohnen, aber rudimentär: **Aggressiv, Defensiv, Passiv**. Das Verhalten hängt auch von den **Eigenschaften** des Wingman ab.
- **Citadel:** ihr mitgetragenes Schiff **stattet man selbst aus**; geflogen wird es von einem **besonderen Crewmitglied**, das nur auf der Citadel dient – ein **Co-Pilot mit dem neuen Perk „Wingman“**. Wer die Citadel kauft, bekommt dafür einen **F-Charakter** dazu.

**Antworten Luz (7. Nov 2026):** Verträge 30 / 60 / 120 Minuten wie vorgeschlagen; Anteil bis **20 % bei A**; **höchstens 2** Wingmen, Leadership verbessert ihre Wirkung und senkt die Kosten; Eigenschaften wie vorgeschlagen; das Schiff gehört dem Wingman – **stirbt er, explodiert es und der Vertrag endet**; beim Warpen fliegt er **im Verbund** (folgen), folgt der Spieler einem anderen Schiff, folgt der Wingman diesem; **feste Tasten für „greift mein Ziel an“ und „passiv“**, aggressiv/defensiv einstellbar ohne Vorbelegung; auf die Citadel passen **alle Schiffe ihres Herstellers** (Hadrian Dynamics, Größe S); bei Zerstörung Kapsel, später an der Station **für 10 % zurückrufen**; Skilltree-Kachel im **Kampf-Ast**, die eine Kampf-Kachel voraussetzt.

**Umgesetzt 33 (7. Nov 2026, alpha 0.5.33.1)** – 6 neue automatische Prüfungen:

- [x] **Wingmen** (`data/wingmen.gd`): Name, Porträt, Level F–A, **Piloting und Gunnery** (+1 % Tempo / Schaden je Stufe), **zwei Eigenschaften** (Daredevil, Cautious, Disciplined, Hothead, Sharpshooter, Loyal, Greedy – Daredevil/Cautious und Disciplined/Hothead schließen sich aus) und ein **eigenes Schiff mit Standard-Ausstattung** (F/D: Hornet, Talon, Acolyte · C: Warden, Maul, Templar · B: Maul, Templar, Goliath · A: Goliath, Bastion).
- [x] **The Bar → PILOTS FOR HIRE:** 1–3 Piloten, Karte mit Fähigkeiten, Eigenschaften, Schiff und Loadout, Anteil; Vertrag **30 / 60 / 120 Minuten** (Preis für 30 Min: F 3.000 · D 8.000 · C 20.000 · B 50.000 · A 120.000 cr; 60 Min ×1,8, 120 Min ×3,2). **Anteil** F 2 · D 4 · C 7 · B 12 · A 20 %. Laufende Verträge verlängern oder beenden.
- [x] **Höchstens 2 Wingmen**, der zweite ab **Leadership 3**; Leadership (+1 % je Stufe) macht sie besser und billiger; Leadership lernt man durch Anheuern und ihre Abschüsse.
- [x] **Im Verbund:** sie fliegen in Formation, warpen mit, springen mit; **folgst du einem Schiff, folgen sie ihm**; beim Andocken docken sie mit, beim Ablegen kommen sie mit raus. Sie kämpfen nur in der Nähe des Schiffs, mit dem sie fliegen (Daredevil weiter).
- [x] **Befehle:** Aggressiv · Defensiv · Passiv (alle oder einzeln) und **„Attack my target“** – im neuen **WINGMEN-Panel** oben links (mit Hülle, Schild, Tätigkeit, Restzeit). Tasten: **N** = greift mein Ziel an, **Y** = passiv, aggressiv/defensiv frei belegbar.
- [x] **Tod:** das Schiff explodiert, der Vertrag endet. Abschüsse der Wingmen zählen für dich (Kopfgeld), der Anteil geht ab.
- [x] **Skilltree:** neue Kachel **Wing Command** (Combat, nach Fighters: 10 Piraten, 2 Kopfgeld-Aufträge).
- [x] **Citadel-Plattform:** im Hangar ein **Hadrian-S-Schiff** (heute die Talon) auf die Plattform stellen oder wieder herunternehmen (um es auszustatten). Neuer Crew-Posten **Platform Pilot** – nur ein Co-Pilot mit dem seltenen Perk **Wingman**; die gekaufte Citadel bringt einen F-Platform-Pilot mit; der Posten kommt mit der Kachel Capital Ships. Im All **Launch / Recall** im WINGMEN-Panel, das Plattform-Schiff folgt und kämpft wie ein Wingman (gleiche Befehle). Zerstört: der Pilot würfelt um die Rettungskapsel, das Schiff kann **im Hangar für 10 % zurückgerufen** werden.
- [x] **Debug** (Debug-Menü → Ship): Wingman sofort dazu (Level wählbar, 30 Min, gratis), alle Verträge beenden. Smoke-Test: Teil-Läufe `--only=wingmen,platform`.

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

#### Paket 34 – Codex, Sammlung, Steckbriefe (umgesetzt 8. Nov 2026, alpha 0.5.34.1)

**Wünsche Luz (8. Nov 2026):** eine **Sammlung** – gesammelte Crew-Perks als Kacheln (fehlende ergraut mit dickem „???“) und eine Liste der getöteten berüchtigten Piraten (Name, Schiff, Mugshot); die **berüchtigten Piraten als richtige Charaktere** (wie Wingmen, mit Boni auf ihre Sachen); der **Steckbrief im Bond Office im Wild-West-Stil**: Mugshot in der Mitte, Sterne, „Dead or alive“, Belohnung, Schiff und Eskorte.

- [x] **Berüchtigte Piraten sind Charaktere:** jeder hat ein Gesicht (Porträt-Baukasten) und **Piloting & Gunnery**, die mit den Sternen wachsen (Grundwert 1–3 + 2 je Stern, höchstens 12) und als +1 % Tempo / Schaden je Stufe auf ihr Schiff wirken.
- [x] **Wanted-Steckbrief** im Bond Office: Papier-Optik, groß „WANTED“, der **Mugshot** im Rahmen, die Sterne (rote = überrannte Stationen), Name und Spitzname, **„DEAD OR ALIVE“**, „REWARD“ mit der Summe, darunter Schiff (seit 0.5.34.2 mit dem Schiffs-Icon in der Lackierung des Kapitäns), Eskorte, Eigenschaft, Fraktion, Fähigkeit, zuletzt gesehen und „Set course“. Tote Kapitäne: ausgeblichen, „– DESTROYED –“.
- [x] **Sammlung** (Pilot-Fenster → Pilot → **Collection**; seit 0.5.34.3 links die Kategorien als Knopf-Liste, rechts die gewählte): **Crew-Perks** als Kacheln – ein Perk zählt, sobald ein Crewmitglied mit ihm dir dient (an Bord, auf der Plattform, im Crew-Quartier); fehlende ergraut mit „???“. Darunter die **erlegten berüchtigten Piraten** als Steckbrief mit Mugshot, Sternen, Schiff, Belohnung, wo und wann.
- [x] **Codex:** neue Kategorie **Pilot & Crew** mit 8 Einträgen (Fähigkeiten & Pilotenlevel, Perks, Skilltree, Crew, Wingmen, Citadel-Plattform, Schiffsverlust, Sammlung); die neuen schalten sich beim **ersten Kontakt** frei (erstes Schiff mit Crew, erster Wingman, erste Plattform, erster Verlust, erstes Sammelstück) und erscheinen als „New Codex entry“.
- [x] Entwickler-Notizen aus Perk-Texten entfernt. **Balancing der Boni** bleibt beim Skilltree-/Balancing-Durchgang in Teil 9 (72a).

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
| B | Into the Darkness | Vorstöße ins Veil, Gegnerwellen, zwei Alienspezies, Beginn der Endgame-Mechaniken – **verschoben hinter Teil 7** (9. Nov 2026) |

Die Veil-Mechanik entsteht bewusst schon hier, damit die Story (Teil 8) sie später nutzen kann, ohne sie neu zu bauen.

### Part A – Galaxy Rework

| # | Arbeitspaket | Inhalt |
| --- | --- | --- |
| 35 ✓ | System-Maßstab & Aufbau | deutlich größere Systeme; in den meisten Systemen ein dekorativer Asteroidengürtel und ein dekorativer Kuipergürtel (überwiegend Hintergrund); darin die bekannten Asteroidenfelder, dichter als heute. Dazu die **Grundlagen fürs Laden**: Vorladen von Assets und Loading Gates (Sprung und Hyperraum als Übergänge, die die Ladezeit verdecken); Ladebildschirme mit Lore-Bildern und Feinschliff in Teil 9 (Paket 67) |
| 36 ✓ | Monde | Planeten bekommen Monde, Gasriesen 2–3 |
| 37 ✓ | Neue Sterntypen | animierte Neutronensterne, Schwarze Löcher mit Akkretionsscheibe, Rote Überriesen (Beteigeuze-artig) |
| 38 ✓ | Neue Planetentypen | Eisriesen, Eisplaneten, Zwergplaneten |
| 39 ✓ | Spezialsysteme | die drei Fraktions-Heimatsysteme fest gestaltet; Systeme der Manufakturen |
| 40 | Cluster ca. 100 Systeme | weiterhin ca. 50 bewohnte Systeme im Kern, darum ein Gürtel unbewohnter Systeme: eine Mischung aus reichen Rohstoffen, Anomalien und Wracks, Piratenverstecken und Gefahren; dazu teilweise **unabhängige Systemregierungen mit Außenposten** |
| 41 ✓ | Bergbau-Erweiterung | starke Erweiterung des Bergbaus: viele neue abbaubare Elemente und daraus herstellbare Waren |
| 42 ✓ | Wirtschaft 2.0 | Systeme bekommen eine Wirtschaft und ein Wohlstandslevel; daraus Materialausstoß, Bedürfnisse, Angebot und Nachfrage. Handelskonvois haben **zum System passende Waren** an Bord – die Wirtschaft bestimmt die Konvois, nicht umgekehrt (echte Warenströme erst in einem späteren „Wirtschaft 3.0“) |
| 43 ✓ | Tourismus | Tourismus-Stationen als neuer Stationstyp und eine Tourismus-Wirtschaft |

### Part B – Into the Darkness (verschoben hinter Teil 7)

**Entscheidung Luz (9. Nov 2026):** Wie Part B umgesetzt werden soll, ist noch offen – er kommt **nach Teil 7** (als „Teil 7½“). Vorarbeit liegt schon im Cluster: die Veil-Randsysteme mit Rissen und Geisterechos (40c), die Fernen Weiten als Vorposten.

| # | Arbeitspaket | Inhalt |
| --- | --- | --- |
| 44 | Veil-Erkundung | Vorstöße ins Veil im Stil eines **Dungeon-Crawlers**: Abfolge von Veil-Systemen, die man sich erkämpft |
| 45 | Veil-Einsätze | Systeme im Veil erkunden, Gegnerwellen bekämpfen; am Ende ein **Bossgegner** und ein **Wurmloch zurück in den Cluster** |
| 46 | Der Schwarm | erste Alienspezies |
| 47 | Die Vergenz | zweite Alienspezies (KI) |
| 48 | Endgame-Beute | Beginn der Endgame-Mechaniken: S+-Ausrüstung und S+-Crewmitglieder sammeln |

**Reihenfolge (Entscheidung Luz, 8. Nov 2026):** Die Pakete **41 bis 43 werden vorgezogen** (Bergbau-Erweiterung, Wirtschaft 2.0, Tourismus); der **Cluster wird erst danach neu gemacht** (Paket 40), damit er gleich mit der neuen Wirtschaft entsteht.

Jedes Paket mit eigenen Debug-Funktionen (z. B. zu jedem Systemtyp springen, Stern-/Planetentyp erzwingen, Veil-System öffnen, Alienwelle spawnen, S+-Beute geben).

#### Paket 35 – System-Maßstab & Aufbau (umgesetzt 8. Nov 2026, alpha 0.6.35.1)

**Antworten Luz (8. Nov 2026):** Maßstab **×3**; Gürtel wie vorgeschlagen, dazu die **Asteroidenfelder überarbeiten – deutlich größer, dichter, mehr Variation**; ein kurzer **Ladebildschirm** beim Start aus dem Hauptmenü, und der **Ruckler beim Einfliegen in Felder mit Colossi** soll weg; neues Spiel nötig ist in Ordnung; **mehr Verkehr**.

- [x] **Systeme ×3:** Radius 6 Mio. km (Tore bei 5,7 Mio.), Planetenbahnen, Anomalien, Havens, Wegstationen und Spawnpunkte mitskaliert (`Universe.SCALE`); Warp-Grundtempo 150.000 → 240.000 km/s – ein Warp quer durchs System dauert etwa 20–30 s.
- [x] **Asteroidengürtel** (80 % der Systeme, zwischen den Gesteinsplaneten und dem ersten Gasriesen) und **Kuipergürtel** (70 %, außen bei ~84 % des Radius): auf der Systemkarte als Band aus feinen Körnern, aus der Nähe ziehen **dunklere Brocken mit Parallaxe im Hintergrund** vorbei (nicht abbaubar).
- [x] **Asteroidenfelder neu:** Metall- und Gesteinsfelder liegen **im Asteroidengürtel**, Eisfelder **im Kuipergürtel** (ohne Gürtel wie bisher in Bahnzonen). Radius 20.000–40.000 km statt 10.000–16.000, im Schnitt dichter (≈ 0,22 Brocken je 1.000 km², eng geklumpt) und in **fünf Stilen**: Clustered, Band (entlang der Bahn gestreckt), Dense Core (dichter Kern mit mehr großen Brocken), Boulder Field (wenige große) und Gravel Field (viele kleine). Der Stil steht im Feldnamen.
- [x] **0.6.35.4 (Wunsch Luz):** Felder **kompakter und strukturierter** – Radius 12.000–22.000 km, darin viele kleine Strukturen (dichte Knoten, Haufen, Ketten) mit freien Flächen dazwischen; etwa 0,9 Brocken je 1.000 km², an manchen Stellen sehr dicht. **Mehr Colossi:** jedes Feld hat jetzt 3–5 (in gesetzlosen Systemen einen mehr), über das Feld verteilt.
- [x] **0.6.35.5 (Wunsch Luz):** **Radarschatten** enden jetzt am Rand der Radarreichweite. **Zwei neue Colossus-Formen je Gesteinsart** (mit passendem Radarschatten): Metall – Platte und Spindel, Gestein – Geröllhaufen und Niere, Eis – Tropfen (gefrorener Komet) und Kristall mit Stacheln (seit 0.6.35.6 eine runde Eiskugel mit sanften Beulen – die Sternform war zu viel). **Colossi sind abbaubar** (sperrbar, Prospektor und Bergbaulaser, Abstand zur Oberfläche zählt): riesiger Vorrat aus zwei Erzen des Feldes; leer bleiben sie stehen und zeigen im Scanner „empty“. **Kleine Asteroiden zerbrechen**, wenn sie leer sind – die Stücke treiben auseinander und verblassen – und wachsen nach **30–60 Minuten** nach (gewichteter Zufall, kleinere eher). Leere Colossi und zerbrochene Asteroiden werden mitgespeichert.
- [x] **0.6.35.7 – Warp (Wunsch Luz):** Die Kamera bleibt beim Warp auf **Kampfnähe** (kein automatisches Herauszoomen mehr); herauszoomen kann man jederzeit selbst. **Während des Warps ist das Radar ausgeblendet** (0.6.35.8 – in 0.6.35.7 versehentlich eingeblendet). Neue **Warp-Animation:** um das Schiff bildet sich ein **blauer, leicht durchsichtiger Tunnel** – Wände entlang des Kurses, Ringe und Streifen, die nach hinten vorbeiziehen, ein Bugleuchten; er baut sich am Anfang auf und verblasst vor der Ankunft. Seit 0.6.35.9 hat er eine **feste Größe** (Radius 1.300 km – nah groß genug für die ganze Formation, in Recon ein schmaler Tunnel) und ist immer auf das Schiff zentriert, das die Formation anführt. Seit 0.6.35.10 gibt es beim **Eintritt und Austritt einen hellen Lichtblitz**, und jedes Schiff hinterlässt beim Austritt eine Spur (0.6.35.10 noch Rauch) – seit 0.6.35.11 eine **lange glitzernde Spur** entlang des Kurses (7.500 km, länger als die Kampfansicht), zum Schiff hin heller und größer: erst glitzert alles auf, dann verblasst sie vom fernen Ende zum Schiff hin (seit 0.6.35.12 etwa 3,5 s). 0.6.35.12: der **Eintrittsblitz ist viel heller** (weißer Kern, blauer Schein, Lichtstreif), der **Austrittsblitz kommt kurz vor der Ankunft**; statt des Bogens vor dem Schiff glüht jedes Schiff im Warp wie beim **Eintritt in eine Atmosphäre, nur bläulicher** – Hitzeschale um den Bug, flackernde Flammenzungen an den Flanken, Funken nach hinten. 0.6.35.13: Der Warp bremst am Ende **nicht mehr ab** – nach dem Beschleunigen fliegt das Schiff mit voller Geschwindigkeit bis zum Ziel und fällt dort schlagartig auf Unterlicht; der Austrittsblitz erscheint am Ankunftspunkt. Reibung, Blitze und Glitzerspur wachsen mit der Schiffsgröße und gelten für jedes Schiff, auch im Verbund. 0.6.35.14: Tunnel und Warpschweif reichen nur noch **vom Start bis zum Ziel** (auf der Systemkarte liefen sie ins Unendliche); das **Stottern der Systemkarte im Warp** ist behoben – dort wurden tausende Tunnelringe pro Bild gezeichnet (≈ 170 ms je Bild, jetzt ≈ 17 ms). 0.6.35.15: Die Linien hinter dem Schiff im Warp sind weg (die Reibung ersetzt sie); neue **FPS-Anzeige** oben rechts neben den Buttons (Bilder pro Sekunde und langsamstes Bild, grün/gelb/rot), in den Einstellungen abschaltbar. 0.6.35.16: **Recon-Ansicht in Feldern mit Colossi flüssig** – die Radarschatten bestanden aus Vierecken, die sich manchmal verdrehten; jedes gescheiterte Zerlegen in Dreiecke schrieb eine Fehlermeldung (mehrere pro Bild, ≈ 95 ms je Bild ≈ 10 FPS). Jetzt direkt als Dreiecke gezeichnet (≈ 20 ms); Kontakte außerhalb der Radarreichweite werden vor der Sichtlinien-Prüfung aussortiert. 0.6.35.17: **Warp zu Stationen und Piratenhäfen schon ab 8.000 km** (sonst 40.000 km) – wer knapp außerhalb der No-Fire-Zone stand, flog bisher minutenlang im Unterlicht heran; jetzt landet man immer 2.500 km vor der Station.
- [x] **Mehr Verkehr:** Shuttles, Bergbauschiffe, wartende Frachter, Feld- und Torwachen, Piraten etwa anderthalbfach; Obergrenze 60 → 90 Schiffe je System.
- [x] **Laden:** kurzer **Ladebildschirm** beim Start aus dem Hauptmenü; dahinter werden alle Asteroidenbilder des Systems vorab erzeugt und der **Colossus-Shader vorkompiliert** – der Ruckler beim Einfliegen in Felder mit Colossi ist weg. Beim **Hypersprung** wird das Zielsystem während des Tunnels vorbereitet. Unsichtbare Asteroiden kosten keine Rechenzeit mehr.
- [x] **0.6.35.2/.3:** Die Systemkarte ist wieder **auf das eigene Schiff zentriert** – Godots Standard-Kameragrenze von ±10 Mio. km hatte die Karte der größeren Systeme zur Seite geschoben (die kurzzeitige Zentrierung auf den Stern in 0.6.35.2 ist wieder raus).
- [x] **Debug** (Debug-Menü → World): Ladezeit des letzten Systems und Vorlade-Statistik, „Into the asteroid belt“ / „Into the Kuiper belt“.

#### Paket 36 – Monde (umgesetzt 8. Nov 2026, alpha 0.6.36.1)

**Antworten Luz (8. Nov 2026):** Monde sollen sich bewegen – **Planeten und Monde bekommen beim Einspringen einen zufälligen Ort auf ihrer Umlaufbahn** (die Illusion, dass sie sich bewegen); Monde sind **sehr viel größer als Colossi**, darum **kein Radarschatten**; Namen „Planet-a/-b“, **später auch benannte Monde** in den handgebauten Systemen (Paket 39); sonst alle Vorschläge angenommen (Anzahl, Typen, Warp-Ziele, Stationen an Monden, kleine Mondfelder, Piraten hinter Monden, neues Spiel nötig).

- [x] **Monde:** Gasriesen 2–3, Gesteins-, Wüsten- und Eisplaneten meist einer (0–2), Lava- und Ödplaneten selten einer. Vier Typen: **Felsmond** (Krater), **Eismond**, **Vulkanmond** (glühende Vulkane, Io-artig) und **eingefangener Asteroid** (unförmiger Umriss). Radius 3.000–7.800 km (höchstens zwei Drittel des Planeten) – weit größer als jeder Colossus. Namen: „Sonnenwende V-a“, „-b“, „-c“.
- [x] **Umlaufbahnen:** Beim Ankommen per Sprung oder Wurmloch stehen Planeten und Monde an einem neuen Ort ihrer Bahn; alles, was an ihnen hängt, wandert mit: Stationen, Ringgestein, Gestein um Stationen, Mondfelder. Planeten halten Abstand zu Toren, Gürtelfeldern, Piratenhäfen und Wegstationen. Der Ort wird gespeichert (nach dem Laden steht alles, wo es war). Wartet ein eigenes Schiff draußen im System, wird nicht neu gewürfelt.
- [x] **Stationen an Monden:** etwa ein Drittel der Stationen eines Planeten mit Monden kreist um einen Mond („Sonnenwende IV-b – Trade Hub“).
- [x] **Mondfelder:** jeder vierte Mond hat ein kleines Asteroidenfeld (Radius 4.000–7.000 km, Gestein passend zum Mond), das mit ihm wandert.
- [x] **Warp-Ziele und Karte:** Monde sind Warp-Ziele (◐ in der Übersicht), Hintergrundkörper aus der Nähe und auf der Systemkarte; Mondbahnen und -namen erscheinen, sobald man nah genug heranzoomt.
- [x] **Piraten** lauern auf der sternabgewandten Seite von Monden ohne Station (außerhalb jeder No-Fire-Zone) und in Mondfeldern.
- [x] **Debug** (Debug-Menü → World): Monde des Systems, „To the next moon“ und je Mondtyp, „Roll the orbits (as on arrival)“. Im Testsystem hat der Gasriese je einen Mond jeder Art.
- [x] **0.6.36.2 – Orbit-Ansicht (Wunsch Luz):** auf der Systemkarte lagen die Monde zu nah an ihrem Planeten, um sie zu sehen. Neue Zoomstufe **Orbit** zwischen Recon und System (**F3**; System jetzt **F4**): flache Karte, 260.000 km vom Schiff bis zum Bildrand – ein ganzes Mondsystem mit Bahnen und Namen. **Nicht im Warp** (das Mausrad überspringt sie, die Taste meldet es; wer beim Warpbeginn in Orbit ist, wechselt auf System). Gespeicherte Zoom-Tasten werden einmalig auf die neuen Standards gesetzt.
- [x] **0.6.36.3 – Warp und Himmelskörper (Wunsch Luz):** Warp **50 % schneller** (Grundtempo 360.000 km/s). **Notabschaltung:** die **Warp-Taste (X)** im Warp fragt im Log nach (seit 0.6.36.4; die Leertaste kam nicht an – sie bedient auch fokussierte Buttons), ein zweites Drücken innerhalb von 5 s wirft das Schiff aus dem Warp – mit Schwung in Flugrichtung, Blitz und Glitzerspur, und es **trudelt drei Umdrehungen** um sich selbst, bevor es wieder gehorcht; der Antrieb braucht 6 s. Planeten, Monde und Sterne kommen **näher** (direkt darüber ≈ 650 statt 450 px Radius bei 1080p) und wachsen und schrumpfen **weich** – keine harten Grenzen mehr bei Größe, Überflug und Lage, und ein festes Pixelraster statt einer Auflösung, die bei jeder Größenänderung springt.
- [x] **0.6.36.5 – Stationsbahnen (Wunsch Luz, Vorbereitung Teil 7):** Stationen haben wie Monde eine **eigene Umlaufbahn** um ihren Planeten oder Mond (fester Bahnradius) und stehen bei jedem Einspringen an einem neuen Ort darauf; zwei Stationen eines Körpers halten Abstand. Das Gestein um eine Station wandert mit ihr. Die Bahnen erscheinen in der Orbit-Ansicht. Wegstationen bleiben an ihrem Platz an der Torroute.
- [x] **0.6.36.6 – Eindrucksvollere Himmelskörper (Wunsch Luz):** aus der Ferne etwa so groß wie bisher, zur Oberfläche hin wachsen sie immer steiler – direkt über einem Planeten ≈ 1.050 statt 650 px Radius (1080p), er füllt den Bildschirm. Der **Stern** ist 1,5× größer als ein Planet gleicher Größe und hat einen **weiten, weichen Lichthof** (Korona, gut 5 Sternradien).
- [x] **0.6.36.7 – Tiefe:** die Parallaxe der Himmelskörper hängt jetzt von der Nähe ab – ein naher Planet gleitet als eigene Ebene vorbei (≈ 15–30 px je 1.000 km Flug, Schiffe ≈ 600, Sterne 0,3–2), ein ferner bewegt sich kaum mehr als die Sterne; direkt über dem Körper rutscht er gleichmäßig unter das Schiff (vorher klebten nahe Planeten im Sternenfeld und sprangen über dem Planeten zum Rand).

#### Paket 37 – Neue Sterntypen (umgesetzt 8. Nov 2026, alpha 0.6.37.1)

**Antworten Luz (8. Nov 2026):** weiter **Pixel-Look** (es geht um die Features der Objekte, nicht um Fotorealismus); Häufigkeiten wie vorgeschlagen; Rote Überriesen riesig, Planeten rücken nach außen; **koronale Massenausbrüche als Ereignis**; Spielwirkung ja – Solarkollektor nach Helligkeit, Frostgrenze, Sog am Schwarzen Loch, **keine** Schäden durch Neutronenstern-Jets; an Neutronensternen und Schwarzen Löchern höchstens **Forschungsstationen** (an die ~100 Systeme aus Paket 40 denken); Raumverzerrung am Schwarzen Loch; neues Spiel in Ordnung. Referenzbilder: Neutronenstern mit Feldlinien und Jets, wabernder Roter Riese, Schwarzes Loch mit gekrümmter Akkretionsscheibe.

- [x] **Zwölf Sterntypen** (Anteil): M 30 %, K 20 %, G 15 %, F 8 %, A 5 %, B 3 %, O 2 %, **Brauner Zwerg** (pink, „failed star“) 6 %, **Roter Überriese** 4 %, **Weißer Zwerg** 3 %, **Neutronenstern** 2 %, **Schwarzes Loch** 2 % (je mindestens eines). Heimatsystem: ein G-Stern. Neutronensterne und Schwarze Löcher nur in Systemen ohne Stationen – jedes zweite bekommt eine Forschungsstation. Die Anteile sind auf ~100 Systeme ausgelegt (Paket 40).
- [x] **Größen und Planeten:** O 150.000 km … M 38.000 km, Roter Überriese 600.000 km (zehnmal ein G-Stern; die Planetenbahnen rücken nach außen), Weißer Zwerg 18.000, Neutronenstern 6.000 (Feldlinien bis 90.000), Schwarzes Loch 12.000 (Scheibe bis 72.000). Um Neutronensterne und Schwarze Löcher kreisen nur wenige tote Welten. Warp-Ankunft je Typ (am Schwarzen Loch 10 Horizontradien).
- [x] **Animiert im Pixel-Look, feiner** (≈ 450 Pixelreihen über einen Stern): brodelnde Oberfläche (Granulation; beim Überriesen riesige auf- und absteigende Konvektionszellen und ein wogender Rand; beim Braunen Zwerg Sturmbänder), Randverdunkelung, Sonnenflecken, **Protuberanzen**, die am Rand aufsteigen und zurückfallen, **Flares**, die auf der Scheibe aufblitzen, Korona und weicher Lichthof. **Neutronenstern:** winziger greller Kern, riesige magnetische Feldlinien mit fließendem Plasma, zwei Jets, die wie ein Leuchtturm kreisen. **Schwarzes Loch:** Ereignishorizont, Photonenring, rotierende Akkretionsscheibe (eine Seite heller), die über das Loch gekrümmte Rückseite der Scheibe und ein Bogen darunter; eine **Gravitationslinse** verbiegt den Sternenhintergrund.
- [x] **Koronale Massenausbrüche (Ereignis):** alle 7–15 Minuten bei Sternen, die ausbrechen (nicht Braune/Weiße Zwerge, Neutronensterne, Schwarze Löcher): Warnung im Log 25 s vorher, ein Plasmabogen löst sich vom Stern, dann rast eine **Schockwelle** (90.000 km/s) als oranger Ring durchs System. Wo sie vorbeikommt, sind die Sensoren gestört; nahe am Stern brechen die Schilde zusammen, weiter draußen werden sie geschwächt. Trifft alle Schiffe.
- [x] **Spielwirkung:** Solarkollektor nach Helligkeit (O/B stark, M schwach, Brauner Zwerg kaum, Schwarzes Loch nichts); Frostgrenze je Typ. **Sog am Schwarzen Loch:** ab 14 Horizontradien zieht es Schiffe an, innerhalb von etwa 4 kommt man nicht mehr weg, wer den Horizont überschreitet, wird zerdrückt (Warnung im Log).
- [x] **Codex:** koronale Massenausbrüche. **Debug** (World): jeden Sterntyp ins aktuelle System setzen, Massenausbruch sofort, Verteilung im Cluster.
- [x] **0.6.37.2 (Wünsche Luz):** **Neutronenstern** mit deutlich hellerem Kern – auf der Systemkarte ein heller Punkt. **Warp schon ab 12.000 km** (statt 40.000 – von Planet zu Mond musste man sonst bis zu zehn Minuten fliegen). **Sternklassen in der Sammlung** statt im Codex: Kategorie „Star classes“, eine Kachel je Typ mit animiertem Vorschaubild, mittlerer Größe in Sonnenradien, Masse in Sonnenmassen, Oberflächentemperatur und Beschreibung; noch nicht besuchte grau als „???“. **Massenausbruch verschärft:** wer im Warp von der Welle getroffen wird, fällt per Notabschaltung heraus (und trudelt); Tarnung fällt aus und geht 20 s nicht; Drohnen fallen einige Sekunden aus (weiße Blitze statt roter); getroffene Minen explodieren.
- [x] **0.6.37.3 – Übergang Recon ↔ Karte (Wunsch Luz):** statt eines harten Umschaltens (Überblendung in ≈ 0,2 s, die Körper sprangen an ihren Kartenplatz) **gleiten Planeten, Monde und Stern** von ihrem Platz am Himmel an ihren Platz auf der Karte und nehmen dabei ihre Kartengröße an (umgekehrt beim Hineinzoomen); der Zoom durchquert die Übergangszone **gleichmäßig in ≈ 0,6 s**; dazu blitzt ein **Holo-Raster** in Radargrün auf und eine **Scanlinie** läuft über den Bildschirm – wie ein Cockpit-Display, das auf die taktische Ansicht umschaltet.
- [x] **0.6.37.4 – Warnung vor Massenausbrüchen (Wunsch Luz):** 10 s vor dem Ausbruch steht oben in der Mitte rot und fett **„! ENERGY SPIKE DETECTED ON THE STAR !“** mit Countdown (pulsierend), beim Ausbruch „! CORONAL MASS EJECTION !“; dazu ein ruhiger, fremdartiger **Alarm** im Loop, der ein- und ausblendet (von Luz geliefert: „extraterrestrial alert sound“ von fnx_sound, Pixabay; das Audiosystem kann jetzt auch MP3).
- [x] **0.6.37.5:** Der Debug-Befehl für Massenausbrüche startet beim **Countdown** (Banner und Alarm sofort, 10 s bis zum Ausbruch). In **Kampf- und Recon-Ansicht** ziehen, solange man in der Welle steckt, **Plasmastreifen** vom Stern weg durchs Bild und das Licht wird warm – die eigentliche Front ist in dieser Nähe zu schnell, um sie zu sehen.
- [x] **0.6.37.6:** Der Plasmabogen am Stern wird nicht mehr am Rechteck des Sternbilds abgeschnitten, er läuft vorher aus (draußen übernimmt die Schockwelle). **Ausbruchsrate je Sternklasse:** Rote Zwerge (×2,2) und Rote Überriesen (×2,5) brechen weit öfter aus, K ×1,3, G ×1, F ×0,8, A ×0,6, B und O ×0,5 – ein Roter Zwerg etwa alle 3–7 Minuten, ein blauer Stern alle 14–30. Flares auf der Sternscheibe kleiner, seltener und in der heißen Sternfarbe statt weiß.

#### Paket 38 – Neue Planetentypen (umgesetzt 8. Nov 2026, alpha 0.6.38.1)

**Antworten Luz (8. Nov 2026):** neue Typen Eisriese, Zwergplanet, dazu Ozean- und Dschungelwelt; **alle bestehenden Typen überarbeiten** (mehr Details, mehr Variation); **Stadtlichter** auf der Nachtseite erdähnlicher Welten in bewohnten Systemen; Planetentypen in die **Sammlung** (mit Monden); Zwergplaneten und Eisriesen Kulisse und Warp-Ziele, Ozean- und Dschungelwelten so bevölkert wie erdähnliche; **manchmal liegt eine Wegstation an einem Zwergplaneten**; neues Spiel in Ordnung.

- [x] **Neue Typen:** **Eisriese** (türkis bis blau, zarte Bänder, dunkler Sturmfleck, oft Ringe, 2–3 Monde; nur weiter draußen), **Zwergplanet** (klein, kraterig, ein bis zwei je System mit Kuipergürtel, dort draußen; eigene Warp-Ziele, keine Monde), **Ozeanwelt** (Inselketten, dichte Wolken) und **Dschungelwelt** (grün, feucht, viele Wolken) in den warmen mittleren Bahnen.
- [x] **Alle Typen überarbeitet** (doppelt so feines Raster): Meere mit flachem Wasser an den Küsten, Land von Tiefland bis Gebirge, **eigene Wolkenschicht**, die schneller zieht als der Boden, **Polkappen**, ein **Dämmerungssaum** an der Tag-Nacht-Grenze, sechs Lichtstufen; **Lavawelten** mit glühenden, langsam fließenden Strömen, die auch auf der Nachtseite leuchten; **Gasriesen** mit verwirbelten Bändern, kleinen Wirbeln und einem großen Sturmfleck; **Krater** auf Fels-, Wüsten- und Zwergwelten; **Ringe** in vielen Formen (Breite, Lücken, Neigung). Jeder Planet bekommt eine **eigene Abwandlung** seiner Farben (Farbton, Sättigung, Helligkeit), dazu eigene Meeres- und Wolkenanteile.
- [x] **Stadtlichter:** erdähnliche, Ozean- und Dschungelwelten in bewohnten Systemen funkeln auf der Nachtseite – an Küsten und in Ballungsräumen, mehr in reichen und sicheren Systemen; andere feste Welten mit einer Station im Orbit zeigen ein paar Siedlungen.
- [x] **Wegstationen an Zwergplaneten:** in etwa 40 % der Systeme mit Zwergplanet kreist die Wegstation um ihn statt an der Torroute zu liegen.
- [x] **Sammlung → Planet types:** eine Kachel je Planeten- und Mondtyp (15) mit drehendem Vorschaubild, Größe in Erdradien, Masse in Erdmassen, Temperatur und Beschreibung; noch nicht gesehene grau als „???“.
- [x] **0.6.38.2:** Mondtypen als eigene Kategorie „Moon types“; die Sammlungskacheln wachsen mit dem Bildschirm (Bild, Schrift, Kachelgröße bis 2,4×) und füllen die Zeile.
- [x] **Debug** (World → Planets): Typen im System, „zum nächsten Planeten“ je Typ (auf die Nachtseite, für die Stadtlichter); das Testsystem zeigt alle Typen nebeneinander.

#### Paket 39 – Spezialsysteme (umgesetzt 8. Nov 2026: 39a alpha 0.6.39.1, 39b 0.6.39.4, 39c 0.6.39.6, 39d 0.6.39.10)

**Antworten Luz (8. Nov 2026):**
- **Rahmen:** Spezialsysteme haben festen Inhalt (Name, Stern, Planeten und Monde mit Namen, feste Stationen, ein Wahrzeichen mit eigener Grafik, Codex-Eintrag); **wo** sie auf der Galaxiekarte liegen, bestimmt weiter der Algorithmus (die Hauptstadt einer Fraktion wird immer ihr Spezialsystem) – übersteht so auch Paket 40.
- **Staatliche Manufakturen** (Concord, Forge of Return, Axiom) sitzen in den Hauptsystemen ihrer Fraktion und sind dort zu sehen.
- Piratenhochburgen und Hivewright **erst mal nicht** (vielleicht später).
- **Vorgehen:** Wir gehen die Systeme einzeln durch; Luz beschreibt, was er sich vorstellt, teils mit Referenzbildern; dann wird gebaut (Unterpakete 39a, 39b …, Versionen 0.6.39.N).
- **Spielwirkung:** Die **Hauptsysteme sind verschlossen** – Zugang erst ab **Friendly** bei der Fraktion. **Besondere Aufträge** dort (noch auszudenken). Das **L-Schiff der Fraktionsmanufaktur** (Concordia, Cathedral, Threshold) gibt es **nur im Hauptsystem** zu kaufen.
- **Namen** überlegen wir gemeinsam; das Hauptsystem des Directorate heißt **„Durchbruch“** (englisch im Spiel: *Breakthrough*?).
- **Reihenfolge:** Beginn mit der **Assembly-Hauptstadt**.
- **Zugang über einen Permit:** Ab Friendly bekommt man von der Fraktion einen Permit, den die Tore ins Hauptsystem prüfen. Er wird **erst entzogen, wenn man auf die unterste Stufe (Arch-enemy) fällt** – sonst bleibt er.
- **Capital Ships (neue Idee Luz):** Für Assembly und Covenant entwirft ihre Manufaktur je ein **Capital Ship** – XL, so groß wie eine Station, **vorerst nicht fliegbar**. Es liegt an der Manufaktur angedockt und wird dort gebaut; ein besonderer Auftrag ist, es **einmal zu begleiten**.

**Systeme:** Assembly-Hauptstadt (mit Concord Fleetworks) · Covenant-Hauptstadt (mit Forge of Return) · Directorate-Hauptstadt „Durchbruch“ (mit Axiom Astronautics) · Earthworks („Second Yard“ von 12696) · Kanayama Heavy Industries · Maison Aurelle · Hadrian Dynamics.

##### 39a – Landfall (Hauptsystem der Assembly) – umgesetzt 8. Nov 2026, alpha 0.6.39.1

- [x] **Rahmen:** `Universe.SPECIAL_CAPITALS` – die Hauptstadt der Assembly wird Landfall (Name, G-Stern, Sicherheit 1.0, feste Stationen); feste Planeten und Monde (`SPECIAL_BODIES`), feste Stationen (`SPECIAL_STATIONS`), Wahrzeichen als `structures`, die mit ihrer Station mitkreisen. Galaxie-Version 7 – neues Spiel nötig.
- [x] **Körper:** Pnyx (Fels), **Agora** (Erdwelt, hellste Stadtlichter), Ekklesia (Ozean), **Boulé** (tiefblauer Eisriese mit Ring) mit Ostrakon und Kleros.
- [x] **Permit:** ab Friendly mit Meldung erteilt, erst bei Arch-enemy entzogen; Tore und Threshold-Wurmlöcher prüfen ihn; Galaxiekarte zeigt „Capital – closed“.
- [x] **The Vote:** Tradehub (Stufe 3) mit eigener Pixel-Art (Kuppel, Habitatring, Datenring mit Emittern, vier Andockarme, vier Drohnenhangars), vier Relaisstationen mit kleinen Drohnenhangars; Drohnen pendeln dauernd; alle 2–4 Minuten schießt ein **blauer Strahl** (Tunnel mit Ringen, Lichtpaket, Blitz am Tor) eine Drohne zu einem Tor.
- [x] **The Senate:** Dienst nur in The Vote; sechs Gesetze mit Vorteil und Preis (Zollsenkung, Milizaufruf, Werftförderung, Treibstoffentlastung, Exportförderung, Flottensparpaket), 30–60 min Abstimmung, eine Stunde in Kraft im ganzen Assembly-Gebiet; eigene Stimme (±3 %), Parteispende (25.000 cr, +4 % je Spende, höchstens +16 %), Bestechung (mind. 250.000 cr oder ein Viertel des Vermögens; 45 % fliegt auf: Geld weg, −30 Ansehen; sonst sicher). Wer auf der Gewinnerseite stimmt, bekommt etwas Ansehen. Ergebnisse in den Nachrichten.
- [x] **Concord Yards** an Ostrakon (Werft Stufe 3, drei Baudocks mit Trägern im Bau, Turm mit Brücken) – **Concordia nur hier**; daneben die **Res Publica** im Bau (Ringvorderkörper mit Öffnung und Drohnenklappen, Kommandoturm, Triebwerke, Gerüste, Schweißfunken, Arbeitsdrohnen).
- [x] **Aufträge:** Stimmenkurier (Assembly-Stationen → The Vote, Frist, Diebe unterwegs) und Drohnen-Feldtest (Concord Yards, Piraten durch eigene Drohnen im Assembly-Gebiet), beide ab Friendly.
- [x] **0.6.39.2 (Wunsch Luz):** Agoras Stadtlichter **strukturiert** (Metropolen, Küstenbänder, Verkehrsadern; Land und Meer dazwischen dunkel); **viel mehr Drohnenverkehr** zwischen The Vote und den Relais (zwei Bahnen je Richtung); **Res Publica neu** nach Referenzbild: langer Bug mit dem Graben der **Spinal-Railgun** (Waffe gegen Capital Ships), breite Schultern, gepfeilte Heckflügel mit dem Antriebskern dazwischen, **überall Drohnenklappen** (Drohnen starten und landen), ein Flügel noch im Gerüst; ihr Heck liegt an den Brücken der Werft.
- [x] **0.6.39.3 (Wunsch Luz):** die Hintergrundsterne funkeln deutlich schwächer und langsamer.
- [x] **Codex:** Landfall, The Senate. **Debug** (World): nach Landfall, Permit geben/nehmen, Stimmdrohne, neues Gesetz, sofort abstimmen (Bestechung fliegt auf / klappt).

**Antworten Luz (8. Nov 2026):**
- System **Landfall**; die dicht besiedelte Erdwelt heißt **Agora** (hellste Stadtlichter im Cluster).
- **The Vote:** ein **großer Tradehub in der Mitte**, darum **kleinere Stationen mit kleinen Drohnenhangars**. Von der mittleren Station fliegen immer wieder Drohnen zu den kleineren und zurück. **Alle paar Minuten** schießt ein **blauer Strahl** – wie der Hyperraumtunnel, nur kleiner – eine Drohne zu den umliegenden Toren (die Stimmen gehen hinaus).
- **Abstimmungen:** ja – mit einem eigenen Dienst in The Vote namens **„The Senate“**.
- **Aufträge:** Stimmenkurier, Drohnen-Feldtest für Concord und Geleit – aber statt einer Concordia wird das neue **Capital Ship** von Concord Fleetworks begleitet.
- **Capital Ship „Res Publica“** von Concord Fleetworks: Supercarrier in Stationsgröße, **runder Vorderkörper (Ring) mit einer Öffnung in der Mitte, an der mehrere Drohnenklappen sitzen**, dahinter Brückenturm und Triebwerke (Referenzbild von Luz); liegt im Bau an den Concord Yards (Gerüste, Schweißfunken, Arbeitsdrohnen). Der **Begleitauftrag** (Testflug quer durchs System, Angriffe, Geleit bis zum Wiederandocken) kommt **später, wenn es ein Framework für Story-Missionen gibt** (Paket 55).
- **Concord Yards** an einem **Mond des tiefblauen Eisriesen**.
- **The Senate:** alle 30–60 min ein Gesetzesentwurf, Abstimmung mit Ja/Nein (mit Permit); Wirkung eine Zeit lang im ganzen Assembly-Gebiet. Dazu **Parteispende** (Geld, erhöht die Chance nur ein wenig) und **Bestechung** (sehr teuer, garantiert bei Erfolg das gewünschte Ergebnis, aber hohes Risiko, erwischt zu werden – dann ist das Geld weg und das Ansehen sinkt).
- **Namen griechisch:** Pnyx (innere Felswelt), Agora (Erdwelt), Ekklesia (Ozeanwelt), **Boulé (tiefblauer Eisriese)** mit den Monden Ostrakon und Kleros.
- **The Vote:** Luz lässt sich nach der Beschreibung überraschen.

##### 39b – Heimkehr (Hauptsystem des Covenant) – umgesetzt 8. Nov 2026, alpha 0.6.39.4

- [x] **Körper:** Roter Überriese; Lauds (Lavawelt), **Compline** (roter Gasriese ohne Ringe) mit **Vesper** (Wüstenmond mit Pilgerstädten, strukturierte Lichter) und Nones, Matins (Eiswelt) – alle weit genug vom Riesenstern.
- [x] **Cathedral of Return** über Vesper (Tradehub, Stufe 3): Kreuzschiff aus hellem Stein mit Strebebögen, Lanzettfenstern aus Buntglas, Apsis, Türme und Fialen, **Fensterrose** in Gold gefasst (die Sonne über dem Weg) – darunter moderne Andockarme, Solarsegel, goldenes Neon.
- [x] **Pilgertor:** zeremonieller Ring aus Elfenbein und Gold mit Sonnenstrahlen und Buntglas; wirft einen nie erlöschenden **Lichtstrahl heimwärts** (vom Stern weg), Pilgerschiffe ziehen in endloser Reihe hindurch.
- [x] **Forge of Return** an Lauds (Werft Stufe 3): Hochofentürme, Schornsteine, **Farm roter Fokuskristalle** mit dem großen Kristall in goldener Fassung, ein Kriegsschiff im Bau – **Cathedral nur hier**. Daneben die **Lux Aeterna**: länglich, Karmesin und Gold, großer Fokuskristall in goldener Gabel am Bug, **riesige Geschütztürme** vorn und achtern, **Habitatring als Kern**, Türme mit Buntglas, ein Abschnitt im Gerüst; der Kristall glüht.
- [x] **Die Kurie** (Dienst nur in der Kathedrale): **Edikte** des Hierarchen (sechs, je Segen und Bürde, 30–60 min, im ganzen Covenant-Gebiet); **Zehnt** (10.000 cr, +1,5 Ansehen, höchstens +6 je Edikt; ab 50.000 cr eine **Bittschrift** für das nächste Edikt aus zwei); **Ablass** (1,5× die Strafe, löscht jede Fahndungsstufe beim Covenant); **Reliquien der Erde** (30 % aus analysierten Anomalien; je +3 Ansehen und 20 min **Segen**: Waren an Covenant-Stationen −10 %, Verkauf +5 %, höchstens 2 h).
- [x] **Aufträge** (ab Friendly): Pilgerkonvoi zur Kathedrale, Kristalltransport zur Forge, Reliquienbergung (Anomalie analysieren, Reliquie abliefern).
- [x] **Codex:** Heimkehr, The Curia. **Debug** (World): nach Heimkehr, Permit, neues Edikt, Reliquien.
- [x] **0.6.39.7 (Fehler):** Das Debug-Menü stürzte ab – Vesper ist ein Mond eines Planetentyps (Wüstenwelt), einige Stellen suchten Monde nur unter den Mondtypen. Behoben (auch bei den Mondfeldern); der Smoke-Test öffnet jetzt jeden Debug-Reiter in allen drei Hauptsystemen.
- [x] **0.6.39.5 (Wünsche Luz):** Pilgertor – von den Turmspitzen bündeln sich Lichtstrahlen in einem **Fokuspunkt**, von dort läuft der mächtige Strahl **über die ganze Systemkarte**; Kathedrale in **Rot und Gold**; der **Rote Gasriese** ist eine eigene Planetenklasse (kommt auch anderswo vor – Vormerkung für Paket 40 – und steht in der Sammlung); **Arbeitsdrohnen** an der Lux Aeterna.


**Antworten Luz (8. Nov 2026):**
- Der **Systemname bleibt deutsch** → **Heimkehr**; Planeten und Monde nach den kanonischen Stunden (Vesper, Lauds, Matins, Compline, Nones).
- Stern: **Roter Überriese**. Die Hauptwelt **Vesper** ist eine **Wüstenwelt als Mond eines roten Gasriesen ohne Ringe** (Compline).
- **Cathedral of Return:** die Heimatstation über Vesper – **alt-kirchlich und doch modernes Sci-Fi**. Beim **Pilgertor** freie Hand.
- **Mechanik:** Edikte des Hierarchen, Zehnt, Ablass und Reliquien – alles. Der **Segen** für abgegebene Reliquien sind **günstigere Preise an Covenant-Stationen**.
- **Capital Ship des Covenant:** länglich, **Gold- und Rottöne**, **riesige Waffenaufbauten**, ein **Habitatring als Kern** des Schiffes – **prunkvoll**.
- Aufträge: Pilgergeleit, Reliquienbergung, Kristalltransporte – passt.

##### 39c – Durchbruch (Hauptsystem des Directorate) – umgesetzt 8. Nov 2026, alpha 0.6.39.6

**Weitere Antworten Luz:** blau-weißer **A-Stern**, **Physiker** als Namen, statt Beiträgen erst mal **nur die Forschungsbörse** (eine Bau-Mechanik für die Sphäre vielleicht später).

- [x] **Dyson-Sphäre im Bau** um den Stern (Radius 175.000 km): fünf Rahmenringe der Schale (von oben als Ellipsen), gebaute Bögen mit silbernen Kollektorplatten (Pixel-Textur: Platten, Nähte, grünes Kollektorband, Fenster; das Band glimmt), an den Enden nacktes Gerüst mit Schweißfunken; aus der Ferne ein Gitter aus Linien. Nabe **Meridian Sphere** (Forschungsstation Stufe 3) direkt auf der Schale – die einzige Station um einen Stern.
- [x] **Körper:** Noether, **Curie** (halb terraformt: grün mit Meeren / noch Wüste, zerfranste Front mit ersten grünen Flecken; drei **Solarspiegel** werfen Licht auf das neue Land), Planck mit Meitner und Bohr, Kepler (Eisriese mit Ring).
- [x] **Axiom Yards** an Meitner: schlanke Werft, Schiffe testen ihre Tarnung (blenden aus und ein), **sechs kleine Sprungtore im Bau** rundherum (verschieden weit, ab und zu ein Testlauf) – **Threshold nur hier**. Kein Capital Ship.
- [x] **Forschungsbörse:** Datensätze aus analysierten Anomalien (5.000 cr, +0,5 Ansehen je Satz) und Exotic Matter (12.000 cr, +1) verkaufen; Exotic Matter kaufen nur für Allied (30.000 cr).
- [x] **0.6.39.9 (Wünsche Luz):** Axiom Yards überarbeitet – der Rumpf endet an der Sensornabe (vorher links abgeschnitten); in den Docks liegen **echte Axiom-Schiffe** (zwei Threshold, zwei Parallax) unter Gerüsten; **Arbeitsdrohnen** an den Toren im Bau.
- [x] **0.6.39.8 (Wünsche Luz):** große **Transporter** bringen Platten entlang der Schale (nahe der Nabe, hin beladen, zurück leer); die **Solarspiegel** sind gewölbte Reflektoren, die sich zu Curie drehen, wie man sie am Himmel sieht – das Licht bündelt sich zum Strahl auf die Oberfläche; Curie hat eine **Forschungsstation** (Curie Terraforming Institute).
- [x] **Aufträge** (ab Friendly): Messsonde (2 min im Zielsystem bleiben), Exotic Matter für die Sphäre, Testflug-Geleit für einen Axiom-Prototyp. **Codex:** Durchbruch, Research Exchange. **Debug:** nach Durchbruch, Permit, Forschungsdaten.

**Antworten Luz (8. Nov 2026):**
- **Project Bridge kommt nicht hierher**, sondern später in ein eigenes Story-System bzw. in Part B (Veil-Erkundung).
- **Hauptstation: eine Dyson-Sphäre im Bau** – die einzige Station direkt um einen Stern.
- Die **Axiom-Werft** bekommt **kein Capital Ship**, dafür **viele kleine Sprungtore im Bau** (die Werft stellt sie her). Die Threshold nur hier.
- Halb terraformte Hauptwelt mit Orbitalspiegeln, Forschungsbörse, Auftragsideen (Threshold-Testflug, Exotic Matter bergen, Messsonden): ja. **Kein Quiz.**

##### 39d – Systeme der privaten Manufakturen – umgesetzt 8. Nov 2026, alpha 0.6.39.10

**Antworten Luz (8. Nov 2026):** nicht lange aufhalten; **Earthworks immer in einem Assembly-System**, die anderen bekommen eine **neue Systemklasse „Independent“ (gelb auf der Galaxiekarte)**. Jedes System hat eine Werft im Stil der Manufaktur, in deren Buchten ihre Schiffe gebaut werden: Earthworks Standard-Werft; **KHI** wie eine Baustelle, gelb mit Gerüsten; **Aurelle** hochwertig, runder und schlanker, mit **Kuppel und Biosphäre**; **Hadrian Dynamics** dunkel-schwarz mit roten Lichtern, **Waffenplattformen**, die rundherum von Drohnen gebaut werden.

- [x] **Platzierung** (Algorithmus): Altwerft (Earthworks) – sicheres Assembly-System (nicht Hauptstadt, nicht Start); **Erzhalde** (KHI), **Perlmutt** (Aurelle), **Schwarzwacht** (Hadrian) – unabhängig (zuerst unbeanspruchte, dann umkämpfte, dann Randsysteme einer Macht; weg von Piraten und voneinander), Sicherheit 0,75. Namen deutsch; Planeten zufällig.
- [x] **Independent:** Systemklasse ohne Macht, gelb auf der Galaxiekarte (Legende, Systeminfo „Independent system“) – Vormerkung für Paket 40.
- [x] **Werften:** Earthworks Second Yard (Standard), Kanayama Works (Baustelle: gelbe Plattform, Gerüste, zwei Turmkräne, rauchender Raffinerieblock), Atelier Aurelle (rund, Elfenbein und Gold, Glaskuppel mit Biosphäre), Hadrian Foundry (schwarzer Keil, rote Lichter, Stacheln) – jede verkauft **alle Schiffe** ihrer Manufaktur; in den Buchten liegen sie **im Bau** (Dockbett, Gerüste, Funken, Arbeitsdrohnen). Um die Hadrian Foundry fünf **Waffenplattformen im Bau** mit Drohnen.
- [x] **Codex:** Independent systems. **Debug:** zu jedem Manufaktur-System.
- [x] **0.6.39.11 (Luz):** Andockbuchten bei Aurelle und Hadrian bündig mit dem Rest; Gerüstschienen der Docks springen nicht mehr um einen Pixel (KHI).

#### Paket 40 – Neuer Cluster (umgesetzt 9. Nov 2026, alpha 0.6.40.1 – 0.6.40.10)

**Antworten Luz (9. Nov 2026):**
- **Größe:** etwa **120 Systeme** – ein bewohnter Kern (~60) und ein Gürtel unbewohnter Systeme (~60). Die Galaxiekarte bekommt **Zoom und Verschieben**.
- **Gürtel:** ein **Ring um den Kern**, dahinter beginnt der Veil. Die Gürtelsysteme sollen sich **in Gruppen zusammentun** (Konstellationen und Regionen, ähnlich der Karte von EVE Online) statt gleichmäßig verteilt zu sein.
- **Inhalt des Gürtels:** **reiche Rohstoffe** (große Felder, seltene Erze, Colossi mit Tiefenerz, Gasriesen), **Anomalien und Wracks** (alte Schlachtfelder, Überreste aus der Zeit vor dem Bruch), **Piraten und Gefahren**, **Veil-Randsysteme** (seltsame Phänomene, Vorbereitung für Teil B).
- **Neue Gefahren:** **Strahlungszonen**, **Ionenstürme**, **alte Minenfelder**, **Piratenfestungen** (größer als die bisherigen Häfen, mit Verteidigung und eigenem Kopfgeld).
- **Unabhängige Systeme:** **kleine freie Siedlungen** – gelbe unabhängige Systeme im Gürtel mit einem Außenposten (Bergbau-, Handels- oder Forschungsposten), eigene Regeln, keine Patrouillen der Mächte.
- **Namen:** **bewohnte Systeme** (auch die freien Siedlungen) bekommen **deutsche, bildhafte Namen** wie bisher; **unbewohnte** Systeme **Katalognummern und Entdeckernamen** (z. B. „KVX-114“, „Brandts Wacht“).
- **Gebiete:** die drei Mächte behalten ihre Gebiete im Kern **ungefähr wie bisher**, Piratenfraktionen an den Rändern; **die Heimatsysteme der Fraktionen sind ausschließlich von Systemen der eigenen Fraktion umgeben**.
- **Tore – neues, detaillierteres Design:** in bewohnten Systemen **vier Bauarten** – **Assembly**, **Covenant**, **Directorate** und **Independent**; in unbewohnten Systemen **ältere, teils heruntergekommene Tore** (unbewohnte Systeme haben keine gepflegte Tor-Infrastruktur); in Piratensystemen die **alten Tore, behelfsmäßig geflickt** (Schrott, rote Lichter).
- **Alte Tore spielen sich anders:** der Sprung **dauert länger** und kann **sehr selten** danebengehen – Ankunft irgendwo im Zielsystem, etwas Schaden am Schiff –, und zwar so, dass man den Zusammenhang versteht (Meldung, sichtbarer Grund).
- **Zwei neue Animationen:** das **Ankommen im System** nach einem Torsprung (ähnlich dem Austritt aus dem Warp) und der **misslungene Sprung**, bei dem das Schiff woanders herausgeschleudert wird.

**Vorschlag Aufteilung:**
- [x] **40a** – Neuer Cluster: 120 Systeme, Kern mit den Gebieten wie bisher (Heimatsysteme nur von eigenen Systemen umgeben), Gürtel als Ring aus Konstellationen und Regionen (wenige Verbindungen zwischen den Gruppen, wie bei EVE), Namen (deutsch für bewohnte, Katalog/Entdecker für unbewohnte), Galaxiekarte mit Zoom und Verschieben, Laden – **umgesetzt 9. Nov 2026, alpha 0.6.40.1**; erweitert 9. Nov 2026, alpha 0.6.40.3: **die Fernen Weiten** – ein zweiter, äußerer Ring aus 20 Konstellationen (~120 unbewohnte Systeme, nur über den Rand erreichbar), zusammen ~240 Systeme
- [x] **40b** – Tore: vier Bauarten für bewohnte Systeme, alte Tore im Gürtel, geflickte Piratentore; längerer, selten misslingender Sprung durch alte Tore; Animationen für Ankunft und misslungenen Sprung – **umgesetzt 9. Nov 2026, alpha 0.6.40.2**
- [x] **40c** – Inhalt des Gürtels: reiche Rohstoffe, Anomalien und Wracks (alte Schlachtfelder, Überreste vor dem Bruch), freie Siedlungen mit Außenposten, Veil-Randsysteme mit seltsamen Phänomenen – **umgesetzt 9. Nov 2026, alpha 0.6.40.5**: reichere Felder und Kolosse, Gasriese in jedem Randsystem; alte Schlachtfelder mit Wracks von Kriegsschiffen, Wracks der Kolonieschiffe aus der Zeit vor dem Bruch, neue Ware Pre-Severance Tech; 40 Veil-Randsysteme mit violettem Himmel, Geisterechos und Veil-Rissen (die freien Siedlungen kamen schon mit 40a)
- [x] **0.6.40.6 (Wünsche Luz, 9. Nov 2026):** **Routenklassen abgeschafft** – überholt, da viele Systeme eigene Bedingungen haben, die Fernen Weiten durch ihre Schwierigkeit eine natürliche Barriere sind und es nicht zum Torsystem passt; die Antriebe sind jetzt Stufen Mk I–III (schnellerer Sprung, seltener Fehlsprung an alten Toren). Der Veil auf der Galaxiekarte als **waberndes Band schwarzer Wolken mit lila Akzenten**.
- [x] **0.6.40.7 (Wünsche Luz, 9. Nov 2026, Lore):** **Assembly und Covenant** haben **umstrittene Grenzsysteme** aneinander (nur dort gibt es umstrittene Systeme); das **Directorate** hat keine umstrittenen Grenzen und **höchstens 4 Systeme** (Hauptstadt mit höchstens drei Routen und ihr Ring); die **Piratenfraktionen** je **höchstens 3 Systeme**; den Rest teilen sich Assembly und Covenant.
- [x] **40d** – Gefahren: Strahlungszonen, Ionenstürme, alte Minenfelder, Piratenfestungen – **umgesetzt 9. Nov 2026, alpha 0.6.40.8**: Strahlung (Schilde leeren sich, dann brennt der Rumpf; Erz darunter reiner), Ionenstürme (ziehen durchs System, Radar gestört, Blitze), alte Minenfelder (gegen jeden scharf), sechs Piratenfestungen im Rand mit Bastionen, schweren Geschützen, Garnison und Kopfgeld 150.000 cr (Garnison vernichten = Festung gebrochen, nach 30 min wieder aufgebaut)
- [x] **0.6.40.9 (Idee Luz, 9. Nov 2026):** **spezialisierte Baupläne** im Skilltree (Industrie: *Radiation Insulation*, *Shielded Hull Lining*) – mit ihnen baut man ein **Isolationsschild-Upgrade** gegen Strahlung und ein **Abschirmhüllen-Upgrade** gegen Ionenstürme; optionale Module, nie im Handel, je nach Qualität **50 % (F) bis 90 % (A)** weniger Wirkung der Gefahr.
- [x] **40e** – Codex, Debug, Tests, Abstimmung und Performance – **umgesetzt 9. Nov 2026, alpha 0.6.40.10**: Codex zum neuen Cluster (Der Rand und die Fernen Weiten), Debug-Abschnitt zu allen Orten von Paket 40 (Festung brechen, erzwungener Fehlsprung), Abstimmung (Ferne Weiten ein Feld mehr statt zwei, Veil-Risse etwas magerer, keine Raststationen in den Fernen Weiten), Leistung (Radar sammelt Objekte viermal pro Sekunde, winzige Asteroiden nicht gezeichnet, Dunst als Textur, alte Minen gedrosselt – weit herausgezoomt im Rand 65 → 157 fps) – **Paket 40 abgeschlossen**

#### Paket 41 – Bergbau-Erweiterung (umgesetzt 8. Nov 2026, alpha 0.6.41.1)

**Antworten Luz (8. Nov 2026):**
- **Neue Quellen:** Gasernte an Gasriesen (neue Rohstoffklasse Gas) und Tiefenerze nur in Colossi – ja.
- **Gasernte:** ein **Ernteband** in der oberen Atmosphäre (auf der Karte als gestrichelter Ring); mit dem **Gas-Sammler** fährt ein Trichter aus, ein Gasstrom wird eingesaugt; **je tiefer, desto mehr Gas – aber Hitze und Druck schaden der Hülle**; ab und zu Stürme (mehr Ausbeute, mehr Schaden); man muss in Fahrt bleiben.
- **Gase je Riesenklasse:** Gasriese – Wasserstoff, Helium (selten Helium-3); Eisriese – Stickstoff, Neon (selten Xenon); Roter Gasriese – Wasserstoff, Schwefeldioxid (selten Phosphin); Toxischer Riese – Chlor, Ammoniak (selten Fluor).
- **Lagerung:** Gase passen in normale Frachtregale, **brauchen dort aber doppelt Platz**; das optionale Modul **Gastanks** lagert sie effizienter.
- **Neue Elemente** (etwa 12) und **zwei Stufen Warenketten** (Erz → Rohstoff → Bauteil) wie vorgeschlagen, dazu **Reinheitsgrade** und die Werkzeuge **Gas-Sammler** und **Tiefenbohrer**.
- **Radioaktive Materialien:** Uraninit → angereichertes Uran (Brennstäbe, später Atomsprengköpfe), Monazit → Thorium, Lithium → Tritium, medizinische Isotope (später auch Ausrüstung auf Charakterebene). **Strahlung als Gefahr:** radioaktive Fracht in **nicht abgeschirmten** Frachtregalen löst oben eine **Warnung mit Warnsignal** aus (wie beim CME-Banner); **abgeschirmte Frachtregale** (Modul) lagern sie sicher, fassen aber **deutlich weniger** bei gleicher Größe.
- **KHI-Gasfrachter „Kujira“** (L): große runde Gastanks, eingebauter Gas-Sammler, verstärkte Hülle (taucht tiefer), riesiges Gaslager, langsam.

**Umgesetzt (alpha 0.6.41.1):**
- [x] 12 neue Erze (Kupfer, Wolfram, Gold, Uraninit, Spodumen, Graphit, Quarz, Monazit, Stickstoff- und Trockeneis; Osmium und Palladium nur als Tiefenerz in Colossi) mit Raffinerie-Stufe
- [x] Reinheitsgrade (niedrig/mittel/hoch) je Asteroid – reinere Brocken geben mehr Erz
- [x] 11 Gase, je Riesenklasse drei; Ernteband (gestrichelte Ringe), Tiefe = mehr Gas, unterhalb des inneren Rings Hitze und Druck an Panzerung und Hülle (an den Schilden vorbei), Stürme (doppelt Gas und Hitze), nur in Fahrt
- [x] Gas-Sammler (Größe 1–4, Trichter und Gasstrom), Tiefenbohrer (Größe 2–4, nur Colossi)
- [x] Lagerung: Gase in Frachtregalen doppelt so groß, Gastanks (optional) fassen sie 1:1; radioaktive Waren in abgeschirmten Regalen (12 m³ statt 40 je Größe), sonst rotes RADIATION-Banner mit Alarm
- [x] 12 Bauteile aus Rohstoffen an jeder Station mit Fabrikatoren (Platine, Batteriezellen, Panzerplatten, Kohlefaser, Ionentreibstoff, Magnetspulen, Fusionszellen, Brennstäbe, Tritium, medizinische Isotope, Präzisionsoptik, Kryosysteme)
- [x] KHI Kujira (L, 640.000 cr): 1.600 m³ Gastanks, eingebauter Gas-Schöpfer (×1,5), 60 % Hitzeschutz
- [x] 0.6.41.2: Absturz beim Einschalten des Sammlers behoben; kein Trichter mehr – Gas strömt durch die geöffnete Drohnenklappe (ohne Klappe: an der Unterseite); Kujira mit leicht erhöhter Brücke am Bug und Drohnenklappe
- [x] Codex-Einträge (Gasernte, Bauteile und Reinheit, radioaktive Waren), Debug-Abschnitt, Smoke-Tests

#### Paket 42 – Wirtschaft 2.0 (umgesetzt 9. Nov 2026: 42a alpha 0.6.42.1, 42b 0.6.42.2/.3, 42c 0.6.42.4, 42d 0.6.42.5)

**Reihenfolge:** Wirtschaft 2.0 vor dem Tourismus (Paket 43) – der Tourismus wird als Wirtschaftszweig gleich mitgedacht und in 43 nur noch angedockt.

**Antworten Luz (9. Nov 2026):**
- **Ebene:** Jedes System hat eine **Haupt- und eine Nebenwirtschaft**. Sie ergeben sich aus **Faktoren** im System – welche Planeten (und Monde), Gürtel und Felder es gibt und welche Stationen dazu passen. Die Stationen sind fest und **prägen die Wirtschaft**, nicht umgekehrt.
- **Planeten als Faktor:** Erdähnliche Welten boosten **Tourismus und Hightech**, Wasserwelten **Agrar**, die neue **Hochmetallwelt** (Planetentyp mit hohen Metallvorkommen an der Oberfläche) **Bergbau**. Gasriesen boosten **Bergbau plus eine zweite** Wirtschaft: Gasriese → Industrie (Energie, Helium-3), Eisriese → Agrar (Wasser, Stickstoff), Roter Riese → Chemie, Toxischer Riese → Chemie/Raffinerie. Die übrigen Typen ordnen wir beim Umsetzen sinngemäß zu.
- **Wirtschaftsarten:** Agrar, Bergbau, Industrie, Raffinerie, Chemie, Hightech, Forschung, Militär, Tourismus.
- **Wohlstand:** 5 Stufen (Verarmt · Arm · Durchschnittlich · Wohlhabend · Reich), **ändert sich langsam**: steigt mit erfüllten Bedürfnissen und Handel, sinkt durch Piraten, Überfälle und Engpässe.
- **Markt:** **echte Lagerbestände** – Verkäufe drücken den Preis, Käufe heben ihn, Produktion und Verbrauch füllen bzw. leeren die Lager mit der Zeit.
- **Dienste:** fest je Station, aber **wie viel sie anbieten** hängt von Wohlstand und Wirtschaft ab – z. B. höhere Qualitätsstufen beim Ausrüster in Hightech- und reichen Systemen, stärkere Waffen in Militärsystemen.
- **Weitere Wirkungen des Wohlstands:** Verkehr und Konvois (mit zum System passenden Waren), Sicherheit und Piraten (arme Systeme ziehen Piraten an, reiche haben mehr Patrouillen), Aufträge und später Touristenströme.
- **Waren:** **etwa 50 neue Waren** zu den Wirtschaftsarten; **nicht alle herstellbar** oder für etwas anderes nötig – manche sind reine Handelswaren. Gold (aus Paket 41) wird in wohlhabenden und Tourismus-Systemen gefragt.

**Vorschlag Aufteilung:**
- [x] **42a** – Wirtschaftsmodell: Faktoren → Haupt-/Nebenwirtschaft je System, Wohlstand (5 Stufen), neuer Planetentyp Hochmetallwelt, Anzeige auf Galaxiekarte und Systeminfo, Debug – **umgesetzt 9. Nov 2026, alpha 0.6.42.1**
- [x] **42b** – Markt: echte Lagerbestände, Preise aus Bestand, Produktion/Verbrauch je Wirtschaft, ~50 neue Waren, Markt-UI mit Kategorien und Beständen – **umgesetzt 9. Nov 2026, alpha 0.6.42.2** (56 neue Waren); 0.6.42.3: 16 Warenkategorien im Markt, feinere Verbraucher, Waffenteile Industrie → Militär, neuer Dienst Munitionsdepot (Minen nicht mehr am Markt, Angebot nach Wirtschaft)
- [x] **42c** – Wirkungen: Dienste nach Wohlstand/Wirtschaft (Ausrüster-Qualitäten, Waffen, Werften), Verkehr und Konvois mit passenden Waren, Sicherheit/Piraten, Aufträge; Wohlstand verändert sich durch Handel, Engpässe und Piraterie – **umgesetzt 9. Nov 2026, alpha 0.6.42.4** (Werften bleiben vorerst fest)
- [x] **42d** – Codex, Smoke-Tests, Abstimmung (Preise, Tempo der Veränderung) – **umgesetzt 9. Nov 2026, alpha 0.6.42.5**

#### Paket 43 – Tourismus (umgesetzt 9. Nov 2026: 43a alpha 0.6.43.1/.2, 43b 0.6.43.3, 43c 0.6.43.4)

**Antworten Luz (9. Nov 2026):**
- **Station:** **ein neuer Stationstyp „Resort“** mit Hotelring, Aussichtsdecks und Lichtern, in **Varianten je nach Ort** – Ring-Resort am Gasriesen, Sternwarte an besonderen Sternen, Vergnügungsstation an Handelsknoten.
- **Orte:** an **schönen Welten** (erdähnlich, Ozean, Dschungel), an **Naturwundern im All** (Gasriesen mit Ringen, rote Überriesen, Schwarze Löcher, Neutronensterne, Doppelsterne), in den **Spezialsystemen** (Landfall, Heimkehr mit den Pilgern, Perlmutt …) und bevorzugt in **wohlhabenden und reichen Systemen**.
- **Gameplay:**
  - **Touristenflüge:** Passagieraufträge – Touristen aus reichen Systemen zu den Resorts bringen (baut auf den Kabinen aus Paket 25c auf).
  - **Rundflüge – von anderen Systemen aus:** Touristen in einem System an Bord nehmen, zu einer Sehenswürdigkeit **in einem anderen System** fliegen, dort nah genug eine Weile verweilen und sie wieder zurückbringen.
  - **Tourismus-Handel:** Resorts kaufen Luxusgüter, Essen und Wein teuer und verkaufen Souvenirs, Holofilme, Kunst.
  - **NPC-Kreuzfahrtschiffe:** Aurelle-Liner und Touristenshuttles als Verkehr zwischen Resorts und Sehenswürdigkeiten.
- **Dienste:** **keine besonderen** – das Resort hat Markt, Bar und die üblichen Dienste.

**Vorschlag Aufteilung:**
- [x] **43a** – Resort-Stationstyp mit Varianten (Grafik), Platzierung im Cluster (schöne Welten, Naturwunder, Spezialsysteme, reiche Systeme), Tourismus-Wirtschaft und -Markt, Sehenswürdigkeiten als Liste je System – **umgesetzt 9. Nov 2026, alpha 0.6.43.1** (etwa 10 Resorts je Cluster; 0.6.43.2 neu gezeichnet: große als Habitatring mit Landschaft unter Glasdach und Nachtseite mit Stadtlichtern, kleinere als Biosphäre)
- [x] **43b** – Touristenflüge und Rundflüge (Aufträge, Verweilen an der Sehenswürdigkeit, Rückflug), Tourismus hebt den Wohlstand – **umgesetzt 9. Nov 2026, alpha 0.6.43.3**
- [x] **43c** – NPC-Kreuzfahrtschiffe und Touristenshuttles, Codex, Debug, Tests, Abstimmung – **umgesetzt 9. Nov 2026, alpha 0.6.43.4**

### Entscheidungen zu Teil 6

| Frage | Optionen | Vorschlag | Entscheidung |
| --- | --- | --- | --- |
| Unbewohnte Systeme | leer · Rohstoffe/Anomalien · Piraten und Gefahren | Rohstoffe, Anomalien, Piratenverstecke – Lohn für Erkundung | **Mischung aus allen drei**, dazu teilweise unabhängige Systemregierungen mit Außenposten |
| Wirtschaft 2.0 und Konvois | Konvois weiter nur Kulisse · Konvois liefern echt | Konvois verändern Angebot und Nachfrage tatsächlich | **Konvois haben zum System passende Waren**; die Wirtschaft beeinflusst die Konvois, nicht umgekehrt. Echte Warenströme ggf. in einem späteren **Wirtschaft 3.0** |
| Veil-Einsätze | offene Erkundung · abgeschlossene Einsätze mit Rückkehr · beides | Einsätze: hinein, Ziel erfüllen, Rückweg | **Dungeon-Crawler**: Abfolge von Veil-Systemen, am Ende evtl. Bossgegner und Wurmloch zurück in den Cluster |

## Phase 0.5 Zwischenteil 6½ – Module und Schiffe abstimmen (Entwurf, 9. Nov 2026)

Ein kleiner Zwischenteil vor Teil 7 (Wunsch Luz, 9. Nov 2026): Nach Teil 4 (Module, Manufakturen), Teil 5 (Crew, Skilltree) und Teil 6 (Bergbau, Wirtschaft, Rand und Gefahren) passen Schiffe und Module nicht mehr überall zueinander – vor dem Boden-Teil einmal geradeziehen. Das große Balancing über alle Systeme bleibt in Teil 9 (Pakete 72–74); hier geht es nur um **Schiffe, Module und Kampf**. Paketnummern schließen hinter Teil 9 an; Versionen alpha 0.6.75.x usw.

| # | Arbeitspaket | Inhalt (Vorschlag) |
| --- | --- | --- |
| 75 ✓ | Bestandsaufnahme | ein **Balancing-Werkzeug** für Schiffe und Module (vorgezogener Teil von Paket 72): alle Rümpfe und Module mit ihren Kennzahlen als Tabelle (Debug-Menü und `Balancing.md`) – Schaden pro Sekunde, Reichweite, Energie, effektive Trefferpunkte, Tempo, Fracht, Slots, Preis je Leistung, je Größe und Qualität; Ausreißer werden markiert |
| 76 | Schiffe | Rollen schärfen (Scout, Kampf, Bergbau, Fracht, Liner, Forschung, Träger), Preis und Leistung je Größenklasse angleichen, Eigenheiten der Manufakturen prüfen, NPC-Varianten |
| 77 | Module | Waffen je Schadensart und Größe (Schaden, Reichweite, Energie), Schilde, Panzerung und Resistenzen, Größen- und Qualitätskurven, Energiebedarf, Preise; die neueren Module (Gas, Tiefenbohrer, Schutzmodule) einordnen |
| 78 | Kampf und Gegner | **automatische Testkämpfe** (Schiff gegen Schiff, Zeit bis zur Zerstörung), Piraten-Archetypen, berüchtigte Piraten, Festungen und Kopfgelder nachziehen |

Dazu am Ende das **Code-Review von Teil 6 Part A** (wie nach jedem Teil).

**Abschluss (Entscheidung Luz, 9. Nov 2026):** Mehr Balancing braucht es jetzt nicht – aufgefallen war vor allem die Geschwindigkeit. Der Zwischenteil endet mit Paket 75 (0.6.75.1–0.6.75.3); die Pakete 76–78 gehen ins große Balancing von Teil 9 (Pakete 72–74). Als Nächstes das **Code-Review von Teil 6** (eigene Sitzung, Bericht `reviews/teil6_review.md`), dann **Teil 7**.

**Paket 75 – Stand 9. Nov 2026:**
- [x] **Kernmodule aufgelistet** (`Balancing_Kernmodule.md`): Werte je Größe und je Qualität, Rechenregeln, Auffälligkeiten.
- [x] **0.6.75.1 – Geschwindigkeit (Luz: „alle Schiffe zu langsam, im Mittelfeld etwa 300 km/s; große Schiffe beim besten Ausbau langsamer“):** Plasma Drive hatte weniger Schub als der Ion Drive gleicher Größe – jetzt rund 35 % mehr; Geschwindigkeit folgt der Wurzel aus Schub je Masse (300 km/s bei 0,2883 kN/t). Standardausrüstungen im Schnitt ~300 km/s (S 271, M 331, L 297), bestes Triebwerk S ~560, M ~430, L ~325.
- [x] **0.6.75.2 – Schub (Idee Luz):** jedes Schiff hat einen kurzen Boost auf **Shift** (umbelegbar, sonst Leertaste): 2,5 s ×1,8 Tempo und dreifache Beschleunigung, kostet ein Fünftel des Energiespeichers, 15 s Abklingzeit; lange gelb-orange Triebwerksflamme, Zündblitz, kurzes Kamerawackeln, Zünd-Sound, Anzeige im HUD. **NPCs nutzen ihn selten** (Piraten und Patrouillen beim Fliehen oder Verfolgen, 35 s Abklingzeit) – man kann noch aufholen oder fliehen.
- [x] **0.6.75.3 – Absturz behoben (Bericht Luz):** beim Tod des letzten Ziels („Left operand of 'is' is a previously freed instance“) – eine Zielaufschaltung zeigte noch auf das gerade zerstörte Schiff; Drohnenschüsse leiser und ausgedünnt.
- [ ] Offen aus der Liste: Treibstoff je Sprung steigt mit der Qualität; Resistenzen und Wendigkeit unabhängig von Größe/Qualität; Sensor-Reichweite wächst kaum; Basic-Verteiler immer Effizienz 1,0; Plasma Drive günstiger als der Ion Drive gleicher Größe.

**Offene Fragen an Luz:** wo es sich konkret falsch anfühlt (welche Schiffe oder Module zu stark, zu schwach, zu teuer, nutzlos); ob nach Zahlen (Werkzeug) oder nach Spielgefühl abgestimmt wird – oder beides; Zielzeiten (wie lange bis zum ersten M- und L-Schiff); ob 75–78 so passen.

## Phase 0.5 Teil 7 – The Sky Is Not Enough (grober Plan)

Landen auf Planeten und Gameplay am Boden – aus Teil 6 herausgelöst, weil es fast ein eigenes Spiel innerhalb des Spiels ist (eigene Ansicht, Steuerung, Kollision, KI).

**Pakete (Vorschlag 9. Nov 2026, nach den Antworten unten – ersetzt den groben Plan):**

| # | Arbeitspaket | Inhalt |
| --- | --- | --- |
| 49 ✓ | Bodengrundlage & begehbare Stationen | die **Bodenansicht** als eigene Szene: Pixel-Kacheln, Kollision, Kamera, der Pilot läuft mit **WASD** (Sprite aus Teil 5), Aussteigen und Einsteigen; als erster begehbarer Ort ein **Stationsdeck**: in jeder Station kann man aussteigen und einen kleinen Bereich begehen, dessen Aussehen vom Stationstyp abhängt – mit **Läden und Bar** (öffnen die bekannten Fenster); das Stationsfenster bleibt wie bisher |
| 50a ✓ | Landung | **Sinkstationen** über allen festen Planeten und Monden (Warpziel); **Abstieg** – beschleunigen, kleiner werden, bei Atmosphäre Hitzeschimmer; **Planetenkarte** mit den Orten; **Landefeld** mit dem eigenen Schiff; **Aufstieg** in den Orbit |
| 50b ✓ | Landeplätze & Städte | jeder feste Planet und Mond hat einige Landeplätze; **Städte** wie Stationen (Landefeld, Straßen, Gebäude mit Diensten, Bar, Leute, Wachen nach Systemsicherheit), Stil nach Planet, Fraktion und Wohlstand, prozedural aus dem Seed, Hauptstädte von Hand; die übrigen Orte (Außenposten, Minen, Ruinen, Absturzstellen, Camps) begehbar |
| 51 ✓ | Persönliche Ausrüstung & Umwelt | Anzüge, Handwaffen, Werkzeuge, aktive Teile (Granate, Schildgenerator, Medkit, Stimulans) – **Prinzip wie beim Schiff** (Slots, Größe, Qualität F–A); eigenes kleines Inventar; Ausrüster am Boden; **Umwelt nach Planetentyp** (Hitze, Kälte, giftige Luft, Vakuum) – ohne passenden Anzug sinkt die Lebensleiste |
| 52 | Kampf zu Fuß (Hybrid) | laufen mit WASD, **Gegner aufschalten, die Waffe feuert selbst** (Trefferquote aus Firearms), Position, **Deckung**, Abstand und **Ausweichen** (Athletics); aktive Ausrüstung auf 1–4; menschliche Gegner (Banditen, Piraten, Wachen); **Tod am Boden:** Aufwachen in der Klinik der nächsten Stadt bzw. Station, ein Teil der Ausrüstung ist weg |
| 52a | Bodenteam | **Crewmitglieder als Bodenteam** (später auch Söldner) steuern: folgen, Position halten, angreifen, Fähigkeit einsetzen; eigene Ausrüstung je Mitglied; verletzt statt tot (Klinik) |
| 53 | POIs & Bodenaufträge | Einsatzorte mit Ziel: Wrack bergen, Rettung, Kopfgeld zu Fuß, Anomalie scannen, Ruinen, Absturzstellen, Höhlen, **Rohstoffe von Hand**; Aufträge vom Auftragsbrett in Städten und Stationen; **auch POIs/Dungeons in den Städten, dort sind Waffen erlaubt** (Luz, 10. Nov 2026) |
| 53a | Lebewesen | **nicht-menschliche Gegner** und Tiere auf Dschungel-, Ozean- und Eiswelten (friedlich oder gefährlich) – eigenes Paket (Wunsch Luz) |
| 54 | Wolkenstädte | Städte auf Plattformen in den Wolken der Gasriesen |
| 54a | Personentransport & Sehenswürdigkeiten am Boden | Touristen zu Sehenswürdigkeiten auf Planeten und in Wolkenstädten – baut auf Paket 43 auf |
| 54c | Handgebaute Orte | **Hauptstädte, Fraktions-Heimatwelten und Story-Orte von Hand** gebaut, dazu **handgebaute Stations-Innenräume** für besondere Stationen – eigenes Paket am Ende von Teil 7 (Luz, 10. Nov 2026) |
| 54b | Minispiele | was im Spiel steht, soll man auch benutzen können: **Billard** am Billardtisch der Spelunken, dazu Ideen wie Darts, Arcade-Automaten, Kartenspiel in der Bar – vorgemerkt (Wunsch Luz, 9. Nov 2026), eigenes Paket |
| 54d | Handel der Sondergebäude | das besondere Gebäude jeder Siedlung bekommt **seinen eigenen Handel** nach der Wirtschaft des Ortes: Erz ab Mine günstiger (Förderturm, Erzhalden), Nahrung beim Agrar-Hof, Bauteile aus der Werkstatt, Raffinerie- und Chemiewaren, Daten und Proben im Labor, Rekrutierung in der Kaserne, Zimmer und Aussicht im Hotel – aus 50b zurückgestellt (Luz, 10. Nov 2026; Paket 55 ist schon das Story-Grundgerüst) |

Am Ende wie immer Codex, Debug, Tests, Abstimmung und das **Code-Review von Teil 7**.

#### Paket 49 – Bodengrundlage & begehbare Stationen (umgesetzt 9. Nov 2026, alpha 0.7.49.1)

- [x] **Bodenansicht** (`scripts/ground/`): `GroundMap` (Kacheln 16 px, ×3 gezeichnet, Kollision, Zonen, Bild), `Walker` (Pilot und Leute, Sprite aus Teil 5, laufen mit Wippen), `GroundView` (eigene Ebene über der Systemansicht, Kamera folgt, Schilder, Hinweis-Zeile).
- [x] **Stationsdeck** (`DeckGen`): Schleuse mit dem eigenen Schiff vor dem Fenster, Promenade mit Kiosken und Deko, Läden und Bar als Räume mit Türen und Leuchtschildern, Schiffsdienste als Terminals im Dock Office; nur was die Station anbietet; nach einem Überfall „closed“.
- [x] **Aussehen je Stationstyp** (Handel, Militär, Forschung, Industrie, Bergbau, Agrar, Eis, Werft, Resort, Piratenhafen).
- [x] **Steuerung:** WASD/Pfeile, Shift rennt, E benutzt; Tastengruppe „On foot“ (eigener Kontext). Tür → Dienst-Fenster über dem Deck, Schließen → zurück aufs Deck, Schleuse → zurück zum Schiff.
- [x] **Leute:** Barkeeper, Ladenbesitzer, Gäste, Passanten. **Codex:** On foot. **Tests.**
- [x] **0.7.49.2 – Überarbeitung nach Luz' Rückmeldung** („Steuerung gut, Stil gefällt nicht“ + Skizze): schräge Draufsicht (Wände mit Vorderseite, stehende Möbel als eigene Sprites, nach Tiefe sortiert), kleine Figuren aus dem Porträt-Aussehen (`ChibiArt`), Möbel (`ObjArt`); Aufbau: Aufzugsraum links (zurück zum Schiff), Gang mit Läden unten, große Bar oben hinter einem Geländer mit Fensterfront (Sternsystem, Stern und Planet der Station draußen), Crew aus dem Bar-Angebot steht in der Bar und wird mit E angesprochen.
- [x] **0.7.49.3 – zweite Runde Rückmeldung:** Fensterfront höher (5 Reihen) mit richtig gerundeten Ecken (Panorama), der Aufzugsraum liegt tief in der Station statt am All, rundherum geht die Stationsstruktur weiter (nur über der Fensterfront ist All).
- [x] **0.7.49.4:** das All nur noch durch das Glas, alles oberhalb des Fensterrahmens schwarz; Fensterfront 7 Reihen hoch.
- [x] **0.7.49.5 – Cyberpunk als Grundton:** Ladenschilder als Neonschilder an der Wand über den Türen, BAR-Schild in Neon (flackert), Neonleisten an den Wandkanten mit Licht auf dem Boden, leuchtende Leitlinie, Lichtkegel (Lampen, Jukebox, Theke, Tische, Fenster), Hologramm-Werbung im Gang; Farben weiter je Stationstyp.
- [x] **0.7.49.6:** Gespräch mit einem Crewmitglied in der Bar (Begrüßung je Qualität, Fragen nach Beruf, Können, Preis, Akte; Anheuern ins Quartier oder aufs Schiff, danach geht es zum Aufzug); Sitzen auf Stühlen, Barhockern, Sofa, Bank; Jukebox mit drei im Spiel erzeugten Lounge-Stücken; Aufzüge mit animierten Türen (Aussteigen beim Betreten, Einsteigen zum Schiff); Terminals im Dock Office nicht mehr in der Tür.
- [x] **0.7.49.7:** Stationsthemen (Bar-Stil je Typ: Lounge, Messe, Café, Kantine, Spelunke, Picknick/Garten, Strandbar mit Pool; eigene Böden, Fensterecken, Deko am Fenster und im Gang); Sitzen richtig auf dem Sitz (Sitzpose), Stühle an den Tischen; Wegfindung (A*) für die Leute, die jetzt auch in die Läden gehen; Gesprächsbildschirm nach Luz' Mockup (großes Porträt links, Text unten, Antworten rechts; Info / Auf Wiedersehen) – Grundlage für Gespräche in Teil 8.
- [x] **0.7.49.8:** Hangar als eigene Ebene (erhöhter Gang mit Glasfront, darunter das eigene Schiff im geschlossenen Hangar; Ganglänge nach Schiffsgröße; links Treppe zum Schiff – Startpunkt, Rückweg ins Schiff und Stationsfenster; rechts Aufzüge); Aufzüge mit Auswahl Hangar / Kommerzielle Ebene; Waystations mit eigenem Deck (runde Glaskuppel vorne, Diner darunter).
- [x] **0.7.49.9:** Hangar ohne Leute und Dinge in Menschengröße, dafür weit unten (kleine Platten, winzige Kisten, Dunst); Hangar-Dienst und Werft als Läden unten am Hangar-Gang statt auf der kommerziellen Ebene.
- [x] **0.7.49.10:** Leben im Hangar (annähernd maßstabsgetreu): Lader fahren Kisten zwischen den Stapeln und dem Schiff, Reparaturdrohnen schweißen am Rumpf (Funken), ein Tankwagen am Heck mit pulsierendem Schlauch.
- [x] **0.7.49.11:** neue Figuren nach Luz' Wahl „C3“ (aus Vorschlägen A–D und fünf C-Variationen): groß und schlank (18×40, ~6 Köpfe), feiner gezeichnet (2 Bildschirmpixel je Pixel), schwarze Umrisse, Neon-Randlicht (links cyan, rechts pink); vorne, hinten, seitlich, Laufen, Sitzen.
- [x] **0.7.49.12:** alle Sitzmöbel an die neuen Figuren angepasst (Sitzhöhe = Hüfte, Lehnen bis zu den Schultern: Stühle, Barhocker, Bänke, Sofa, Kisten, Liegen); Bänke mit Rücken-Sitzern bekommen die Lehne vor der Figur.
- [x] **0.7.49.13:** die Bar benutzbar (an den Barhocker setzen → Gespräch mit dem Barkeeper: Drink bestellen mit Trink-Animation und Alkohol für einen späteren Debuff, Bar-Gespräche, „Wen kann man hier anheuern?“ → Crew-Fenster); zu Fuß kein Weg zurück ins Stationsfenster; jedes Schiff seine eigene Hangar-Nummer, nach dem Schiffswechsel Hinweis und Aufzug direkt dorthin; Bank im Hangar am Glas Richtung Schiff; Minispiele als eigenes Paket 54b vorgemerkt.
- [x] **0.7.49.14:** auf der Hangar-Bank gleitet die Kamera zum Schiff; Stern und Planet stehen immer im sichtbaren Teil der Fensterfront der Bar.

#### Paket 50 – Landung, Landeplätze & Städte (am 10. Nov 2026 auf Luz' Vorschlag geteilt: 50a Landung ✓, 50b Landeplätze & Städte)

**Wunsch Luz (10. Nov 2026):** über allen landbaren Planeten in ihrer Mitte (wo der Planet am größten erscheint) eine **Sinkstation/Sonde**, zu der man warpen kann; dort **sinken**: das Schiff beschleunigt und wird langsam kleiner, bei Atmosphäre mit **Hitzeschimmer**; danach ein Bild mit einer **Miniaturkarte des Planeten**, auf der Städte und Orte eingetragen sind – dort landen.

- [x] **0.7.50.1:** Sinkstationen (Sonde mit drei blinkenden Armen und pulsierenden Ringen) über jedem festen Planeten und Mond – Warpziel, in der Übersicht (▼); Abstieg (Beschleunigen, dann Kleinerwerden; Hitzekugel mit Bugwelle und Plasmaschweif bei Atmosphäre); Planetenkarte (großer Planet, Orte darauf und in der Liste: Städte, Außenposten, Minen, Ruinen, Absturzstellen, Forschungscamps); Landung auf einem Landefeld (Boden des Planeten, Betonplatte mit dem eigenen Schiff und Rampe, Lichter, Kiesweg zum Ort); über die Rampe zurück in den Orbit (Aufstieg aus dem Planeten); gelandet = angedockt (sicher); Codex; Test.
- [x] **0.7.50.2:** Knopf „Descend“ im Auswahlfeld der Sinkstation (auch Andock-Taste) – vorher gab es dort keine Möglichkeit zum Sinkflug.
- [x] **0.7.50.3 (Luz: „harter Schnitt“):** Kamera zoomt beim Absinken mit, Weißblende → Schwarz → Planetenkarte blendet auf (Planet dreht sich herein, Orte leuchten nacheinander auf); **Anflug in Draufsicht** nach der Ortswahl (Boden des Planeten in seinen Farben – Meere und Kontinente, Dünen, Eis, Lava, Krater –, Schatten rückt ans Schiff, Wolken bei Atmosphäre, der Ort mit seiner Landeplattform kommt ins Bild); **Aufsetzen** (Schiff kommt von oben auf die Plattform, Staub, Ruck, Pilot über die Rampe); **Abheben** (Staub, Schiff steigt auf, Weißblende, Aufstieg mit Kamera-Rückzug).
- [x] **0.7.50.4 (Luz: „die auftauchende Stadt wirkt komisch“):** die Stadt im Anflug nur noch als **Lichter** in der Dämmerung (Lichterketten der Alleen, viele winzige warme Fenster, in der Mitte am dichtesten), das Schiff wird beim Hineinfliegen **winzig**; **Landedrohne** (jedes Schiff hat eine): kleine Orte erreicht man nicht mit dem Schiff – die Drohne wird aus der Drohnenklappe abgeschossen, das Schiff zieht nach oben weg, die Drohne landet; zurück mit der Drohne zum Schiff.
**50a – Landung: fertig** (0.7.50.1–0.7.50.4).

**50b – Landeplätze & Städte:**
**Konzept Städte (Luz, 10. Nov 2026):** die meisten Schiffe sind gigantisch – in einer Stadt landet man darum unter der Erde: eine **riesige Landeklappe** im Boden öffnet sich, das ganze Schiff sinkt darunter, die Klappe schließt sich. Darunter ein **Hangar wie auf den Stationen**; die **Aufzüge** führen zu Orten wie der **„Einkaufsstraße“** und einer **„Bar“** – die Bar liegt **weit oben in riesigen Türmen**, aus dem Fenster sieht man andere Türme, kleine **Speeder und Drohnen** fliegen vorbei. **Kleine Orte** erreicht man mit der **Landedrohne** (0.7.50.4).
- [x] **0.7.50.5:** **Landeklappe** (Draufsicht auf die nächtlichen Dächer der Stadt, Schiff kommt über die Klappe, Klappe öffnet sich, Schiff sinkt in den Lichtschacht, Klappe schließt; beim Abflug umgekehrt); **Stadt = Station am Boden** (eigener Markt, Ausrüster, Werft, Bonds, Bar mit Crew, News, Auftragsbrett – Art nach Planetentyp); **Stadt-Hangar** wie auf den Stationen; **Lifte** Hangar · Einkaufsstraße · Turm-Bar; **Einkaufsstraße** (echte Läden im Süden, Ladenfassaden mit Neon-Namen im Norden, belebt); **Turm-Bar** weit oben mit Blick auf die Stadt bei Nacht (Türme mit Fenstern und Neon, Speeder in ihren Bahnen, Drohnen, Parallaxe); Codex „Cities“; Test.
- [x] **0.7.50.6 (Luz):** **vier Baustile** – Independent (Cyberpunk wie bisher), Assembly (helle Steine und Glas, Kuppeln, Terrassen, Dachgärten), Covenant (dunkler rotbrauner Stein, Spitztürme, goldene Fenster unter Spitzbögen, rote Banner), Directorate (weiße Türme im Raster, Sechseck-Kronen, Solardächer, grüne Lichtbänder) – in Anflug, Landeklappe, Straße und Turm-Bar, auch die Ladenfassaden; **Tag und Nacht** je Stadt nach ihrer Lage auf der Planetenkarte (Ausblick, Straßenbeleuchtung, Anflug); **Straßenschlucht** (über den Läden ragen die Häuser in den Himmel, Lichterketten); **plastische Stadt** bei der Landeklappe (Türme mit Fassaden und Schatten); Anflug: die Stadt kommt mit dem Boden und liegt nur auf Land.
- [x] **0.7.50.7 (Luz):** **Grundrisse im Anflug je Welt** (Hafenstadt mit Piers und schwimmenden Plattformen auf Ozeanwelten, Lichtungen im Dschungel, ummauerte Stadt mit Oase in der Wüste, Kuppeln auf Eis- und Giftwelten, Kraterstadt auf Felswelten und Monden, Raster auf Metallwelten) und **Straßennetz je Macht** (krumme Alleen, Ringstraßen mit Parks, Speichen zum Kathedralenplatz, strenges Raster); **die Welten drehen sich** (Tag 20–40 Spielminuten, dieselbe Stadt bei Tag und Nacht; Planetenkarte zeigt den Sonnenstand und „Tag/Nacht dort – Sonnenauf-/untergang in N min“); **Bar und Hangar im Stil der Stadt** (Farben, Bar-Einrichtung, Flaggen im Hangar).
- [x] **0.7.50.8 (Luz):** die Tageszeit läuft **live** weiter, während man in der Stadt ist; **Abenddämmerung und Sonnenuntergang** aus dem Barfenster (Himmel in der Farbe des Sterns, Sonne sinkt hinter die Türme im Westen bzw. geht im Osten auf, Fenster gehen nach und nach an, Licht durchs Glas wird Abendlicht); die Straße wird abends warm und dann dunkel.
- [x] **0.7.50.9:** **Wachen** in den Städten (Posten an Liften und Treppen, Streifen in Hangar, Straße und Turm-Bar, Zahl nach Systemsicherheit, Uniform je Macht, Gewehr geschultert, ansprechbar); **Waffenfeuer bleibt in Städten aus** (Luz).
- [x] **0.7.50.10 (Luz: Vorschlag ja, mit Landeplätzen in der Karte):** **Siedlungen** – Außenposten, Minen, Forschungscamps als eine begehbare Karte unter freiem Himmel: **4 Landeplätze** (auf den freien landen und starten andere Landedrohnen – später für Multiplayer), Straße mit **begehbaren Läden**, Häuser, **Sondergebäude nach Wirtschaft** (Erzdepot mit Förderturm, Agrar-Genossenschaft mit Gewächshäusern, Werkstatt, Raffinerie, Chemiewerk, Tech-Labor/Forschungsstation mit Schüssel, Rekrutierung, Hotel), Wachen auf Streife, Tag/Nacht; **plausible Begrenzung je Welt** (dichter Dschungel, Plattformen auf dem Meer, Dünen, Eis, Kraterfelsen, erkaltete Lava); Codex „Settlements“. Ruinen und Absturzstellen bleiben Landefelder (POIs in Paket 53).
- [x] **0.7.50.11 (Luz: „zu chibi, zu kastig“):** Siedlungen detaillierter und abwechslungsreicher – **acht Bauformen** (Fertighalle mit Wellblech, Containerstapel, Tonnendachhalle, Habitat-Kuppel, Satteldachhaus, Lehmbau, Steinhaus, weißes Modul) je Macht und Welt, jedes Gebäude eigen (Dachaufbauten, Fenster mit Rahmen, Leitungen, Schilder), zwei Häuserreihen, Marktstände, Masten, Rover; Bäume verschiedener Arten und Größen mit Lianen, Unterholz, Felsgruppen, Schneewehen und Eiskristalle; Markisen über den Läden.
- [x] **0.7.50.12 (Luz):** **wirtschaftsbasierte Umgebung** hinter einem Zaun am Ende der Straße, belebt: **Tagebau** mit Terrassen, Bagger, Muldenkippern und Förderband (Bergbau); **Felder** mit Erntemaschine und Sprühdrohnen – bzw. **Hydrokultur** auf Welten ohne Anbau (Landwirtschaft); Werk mit rauchenden Schornsteinen und **Portalkran** über dem Containerlager (Industrie); **Tanklager** mit Fackel (Raffinerie/Chemie); **Antennenfeld** und **Startrampe** mit gelegentlichem Raketenstart (Forschung/Hightech); **Übungsgelände** mit Panzerfahrzeugen (Militär); **Gärten** mit Aussichtsturm (Tourismus); auf Ozeanwelten **Fischfarmen** mit Boot oder eine **Bohrinsel**.
- [x] **0.7.50.13 (Luz: „Größenverhältnisse daneben“):** ein **Maßstab** für alles in den Siedlungen (die Figur als Maß, ~15 Pixel je Meter): Häuser mit echten Geschosshöhen, Türen, Fenstern; Laternen, Bäume, Container, Tanks, Schüsseln, Schornsteine dazu passend; **Fahrzeuge neu in echter Größe** (Muldenkipper mit mannshohen Reifen, Bagger, Mähdrescher, Tanklaster, Radpanzer, Arbeitsboot); **Tagebau vom Rand aus** gesehen – Erdwall, Wände und Sohlen in den Dunst, riesige Maschinen in der Tiefe.
- [x] **0.7.50.14 (Luz: „zu 21. Jahrhundert“):** **Sci-Fi** – Fahrzeuge ohne Gummireifen (Erzfrachter auf gepanzerten Raupenmodulen mit Leuchtfugen, Bergbau-Plattform auf Antigrav-Pads mit Schneidkralle, Erntegleiter, Schwebe-Tanker, Schwebepanzer, Tragflächenboot; Schwebendes wippt und leuchtet den Boden an), Anlagen mit Leuchtringen, Lichtbändern, Emittern, Energiekern; Gebäude mit Lichtleisten und Zugangs-Panels.
- [x] **0.7.50.15 (Luz, nach dem ersten Spielen):** **Abheben mit Wahl** – zurück in den Orbit oder auf die Planetenkarte (anderer Ort auf derselben Welt); **Landedrohne neu** als Landungsschiff für vier Leute und ein Fahrzeug (Kabine mit Bullaugen, Fahrzeugbucht, Cockpitkuppel, vier Hubfans, Heckdüsen, Positionslichter) mit **animierter Rampe** zum Aus- und Einsteigen (auch bei den fremden Drohnen); **Rückflug: das Schiff fängt die Drohne** (Aufstieg, das Schiff kommt von oben, Traktorstrahl, Andocken, Abflug); **Landeplätze detailliert** (Platten, Brandspuren, Aufsetzring mit H, Warnrand, Nummer, Randlichter, Abläufe, Tankklappe, Tanksäule, Lader) mit **Lichtern und Statusanzeige** (CLEAR, INBOUND, DEPARTING, OCCUPIED); Landefeld zwei Pads nördlich, zwei südlich der Straße; Hinweiszeile passend zum Ort.
- [x] **0.7.50.16 (Luz: „Flamme viel zu groß“, „Shuttle riesig neben der Threshold“):** Abstiegsflamme in Schiffsgröße und neu gezeichnet (Kern, Schichten, Stoßdiamanten); **Eintrittshitze neu** – Bugstoßwelle in drei Schichten um die Nase, Plasmaschweif mit Turbulenzen, Schlieren, abplatzende Funken, Leuchten (additiv); **Drohne und Schiff in echten Größen** (Drohne ~10 m neben der Schiffslänge – bei großen Schiffen winzig unter dem Rumpf); 2D-MSAA-Einstellung entfernt (Warnung beim Start).
- [x] **0.7.50.17 (Luz):** **kleine Orte im Anflug** klein und als Lichter wie die Städte – Häuser an einer Straße, Laternen, die vier Pads mit Blinklichtern, daneben die Wirtschaft (Tagebau mit Terrassen und fahrenden Lichtern, Felder oder Gewächshäuser, Hallen mit Schloten, Tanklager mit Fackel, Schüsseln, Übungsplatz, Gärten, Fischfarmen auf dem Wasser), alles an die Geografie gebunden; Ruinen und Absturzstellen klein; Nacht dunkelt das Land im Anflug ab; **keine Triebwerksflamme beim Abstieg**.
- Wohlstand im Stil – **noch kein Plan** (Luz, 10. Nov 2026): aus 50b herausgenommen, offene Idee für später.
- Handel der Sondergebäude (Erz ab Mine günstiger usw.) → zurückgestellt als **Paket 54d** (Luz, 10. Nov 2026).

**50b – Landeplätze & Städte: fertig** (0.7.50.5–0.7.50.17).

**Entscheidungen Luz (10. Nov 2026):** Wachen ja, aber **kein Waffenfeuer** in den gebauten Stadtbereichen. Wenn POIs und das Dungeon-System kommen (Paket 53), bekommen auch die Städte eigene POIs/Dungeons, **in denen Waffen erlaubt sind**. **Handgebaute Städte und Stations-Innenräume** werden ein **eigenes Paket am Ende von Teil 7** (54c).

**Vorschlag Siedlungen (kleine Orte), offen:** Landung wie bisher per Landedrohne auf dem Landefeld, von dort zu Fuß in den Ort – eine eigene begehbare Karte unter freiem Himmel (Tag/Nacht live wie in den Städten). Eine Hauptstraße bzw. ein Platz mit **3–6 Gebäuden** und **begehbaren Läden** (Gemischtwaren/Markt, Werkstatt/Ausrüster, kleine Kantine mit Bar, je nach Größe Arzt oder Auftragsbrett); **Wachen auf Streife** (Ortsmiliz oder Werkschutz der Firma), Zahl nach Systemsicherheit, in gesetzlosen Systemen stattdessen Söldner. **Ein besonderes Gebäude je Wirtschaft** von System und Planet mit eigenem Handel: Bergbau → Förderturm, Erzhalden, Loren (Erz ab Mine günstiger); Landwirtschaft → Gewächshäuser und Silos (Nahrung); Industrie → Fabrikhalle (Bauteile); Forschung → Labor/Observatorium (Daten, Proben); Eis → Wasserwerk; Tourismus → Hotel/Aussichtspunkt; Militär → Kaserne mit Rekrutierung; Piraten → Schwarzmarkt. Ortsarten nach Landeplatz: Außenposten (Kuppeln, Funkmast), Mine, Forschungscamp; **Ruinen und Absturzstellen bleiben POIs für Paket 53**. Stil nach Macht wie die Städte, aber schlichter und rauer; Boden und Umwelt nach Planetentyp (Sand, Schnee, Fels; Kuppeln und Schleusen ohne Atmosphäre); Leben: Bewohner, Lastroboter, kleine Fahrzeuge.
- [x] Orte begehbar – Außenposten, Minen und Forschungscamps als Siedlungen (0.7.50.10–0.7.50.17); Ruinen und Absturzstellen kommen als POIs mit Paket 53.

#### Paket 51 – Persönliche Ausrüstung & Umwelt

**Konzept (Entscheidungen Luz, 10. Nov 2026):**
- **Der Anzug ist der „Rumpf“ des Piloten:** die **Anzugklasse** bestimmt, wie viele **Waffenslots**, **Gürtelplätze** und **Feature-Slots** es gibt und wie gut er gegen die Umwelt schützt – Militäranzüge haben bis zu 3 Waffenslots, zivile Raumanzüge nur einen. Klassen (Vorschlag, angenommen): ziviler Raumanzug (1 Waffe · 2 Gürtel · 1 Feature), Erkundungsanzug (1 · 3 · 2), Arbeitsanzug (1 · 4 · 1), leichter Militäranzug (2 · 3 · 2), schwerer Militäranzug (3 · 2 · 3); später Hersteller- und Fraktionsvarianten.
- **Qualität F–A** beim Anzug: besseres Grundschild, mehr Munitionskapazität, mehr Rüstung, bessere Lebenserhaltung.
- **Energie:** jeder Anzug hat einen Energievorrat – **Schilde, Werkzeuge und die Lebenserhaltung kosten Energie**; aufgefüllt durch **Verbrauchsgegenstände** (Energiezellen) oder an **Ladestationen**.
- **Sauerstofftank:** auf Welten **ohne atembare Atmosphäre** wird Sauerstoff verbraucht; Nachfüllen mit Sauerstoffkartuschen bzw. an Ladestationen. Umweltgefahren nach Planetentyp: Hitze, Kälte, giftige Luft, Vakuum – nur draußen (Landefelder, Siedlungen, POIs).
- **Waffen F–A, ohne Größenklassen** (vorerst): dieselben Schadensarten wie im All – **optisch** (Laser: stark gegen Schilde, schwach gegen Rüstung, kostet Anzugenergie), **kinetisch** (stark gegen Rüstung, schwach gegen Schilde, Munition aus der Kapazität des Anzugs), **explosiv** (Granaten, Werfer: stark gegen die Gesundheit, Flächenschaden); Unterschiede in Feuerrate, Reichweite, Streuung. Schutzschichten am Piloten: Schild → Rüstung → Gesundheit. Geschossen wird ab Paket 52.
- **Gürtel** (Plätze auf den Zahlentasten): Granaten (Splitter, EMP, Rauch, **Schildgranate** – baut in einem kleinen Bereich einen Schild auf, der Feuer und Granaten **von außen abwehrt und von innen durchlässt**), Werkzeuge F–A (Scanner, Schneidbrenner, Bergbaulaser), Verbrauchsteile (Medkit, Stimulans, Energiezelle, Sauerstoffkartusche).
- **Features** (die Module des Anzugs): Schildgenerator, Panzerplatten, Sprint-Booster/Sprungdüsen, Temperaturregler, Sauerstoffreserve, Munitionspack.
- **Inventar:** kleines Inventar am Piloten, dazu ein **Spind im Schiff** (getrennt vom Frachtraum).
- **Laden:** „Gear“ (Personal-Ausrüster) in Städten, Siedlungen und auf der Kommerziellen Ebene der Stationen; Anzug, Helm und Waffe an der Figur sichtbar. Start mit einem zivilen Raumanzug (F). Vorerst keine Baupläne.
- **Klinik:** ein **richtiger Raum** in den Städten und auf den Raumstationen. **Tod im Schiff:** nach dem Respawn-Bildschirm Aufwachen in der Klinik der letzten Station. **Tod zu Fuß:** in der Klinik der nächsten Stadt mit Klinik, sonst der letzten Raumstation.

**Schritte:**
- [x] **0.7.51.1:** Ausrüstungsdaten (5 Anzugklassen, 9 Waffen, 11 Gürtelteile, 8 Features, Qualität F–A), Ausrüstung am Piloten, Taschen (12 Plätze), Spind je Schiff (12/20/30), Seite **Gear** im Pilotenfenster; Start mit zivilem Anzug (F), Laserpistole, Medkits.
- [x] **0.7.51.2:** **Gear-Laden** (Fieldkit Outfitters) auf der Kommerziellen Ebene, in den Städten und Siedlungen; Sortiment nach Ort und Wirtschaft (Qualität wie beim Ausrüster, Kampfanzüge und schwere Waffen nur in Militärsystemen und größeren Stationen, Siedlungen schlicht); Kaufen in die Taschen, Verkaufen zum halben Preis; der Pilot im Anzug (Farben, Platten, Lebenserhaltungs-Pack, Waffe auf dem Rücken, Helm vorbereitet).
- [x] **0.7.51.3:** **Umwelt je Welttyp** (Luft atembar oder nicht; Hitze, Kälte, Gift, Vakuum), draußen verbraucht die Lebenserhaltung Energie, was durchkommt kostet Gesundheit, ohne Atemluft leert sich der Sauerstoff; Helm draußen (auch bei Bewohnern und Wachen); Leisten am Boden, **Gürtel auf den Zahlentasten** (Medkit, Stimulans, Energiezelle, Sauerstoff, neue Munitionskiste); **Ladepunkte** an den Pads; an Bord aufgeladen und geheilt; Zusammenbruch vorerst: der Autopilot bringt dich hoch.
- [x] **0.7.51.4:** **Klinik (Mercy Hall)** als Raum mit Betten auf der Kommerziellen Ebene der Stationen und in den Einkaufsstraßen der Städte, Behandlung gegen Geld; **Schiff verloren** → nach dem Rückkauf-Fenster Aufwachen in der Klinik der letzten Station; **zu Fuß gestorben** → Klinik der nächsten Stadt im System (Schiff in ihren Hangar), sonst letzte Station; die Taschen sind leer. Codex-Eintrag.

- [x] **0.7.51.5 – Debug-Funktionen für die Pakete 49–51** (Leitlinien 1.5, nachgereicht): Debug-Menü F12, Reiter **Ground** – Statuszeile; Deck der angedockten Station/Stadt öffnen, Ebene wählen (Hangar, Kommerzielle Ebene, Einkaufsstraße, Turm-Bar); sofort zu einem Himmelskörper absinken; direkt landen an Stadt, Außenposten, Mine, Forschungscamp oder Landefeld – wahlweise als anderer Welttyp, mit erzwungener Wirtschaft (Siedlungen), zu einer Tageszeit (fehlt die Ortsart, legt das Debug-Menü einen Ort an); Tageszeit am Ort setzen; Ausrüstung nach Familie und Qualität in die Taschen, Gürtel füllen, Anzug auffüllen, Taschen leeren; Gesundheit/Energie/Sauerstoff/Munition setzen; Anzug unverwundbar; Umwelt der Bodenkarte erzwingen; jetzt zusammenbrechen; in der Klinik aufwachen. Smoke-Test-Prüfung.

**Paket 51: fertig** (0.7.51.1–0.7.51.5).


Jedes Paket mit eigenen Debug-Funktionen (z. B. sofort landen, zu einem POI springen, Bodenmission starten, Gegner am Boden spawnen).

**Antworten Luz (9. Nov 2026):**
- **Landung:** jeder Planet hat **feste Landeplätze**, jeder eine eigene, begrenzte Karte – **Städte** (ähnlich wie Stationen im All) und **POIs**; aus dem Orbit wählt man, wo man landet.
- **Steuerung zu Fuß:** noch offen – „die große Frage, wie das Gameplay ablaufen soll“; wird **zuerst konzeptionell** besprochen (Kampf und Gameplay am Boden).
- **Am Boden:** alles aus dem Vorschlag – Städte mit Bar, Händler, Ausrüster, Auftragsbrett, NPCs; Bodenaufträge (liefern, retten, Kopfgeld zu Fuß, Anomalie scannen, Wrack bergen); Erkundung (Ruinen, Absturzstellen, Höhlen); Rohstoffe von Hand; **nicht-menschliche Gegner (Tiere, Lebewesen) als eigenes Paket**.
- **Umwelt:** der Planetentyp bestimmt den nötigen Schutz (Hitze, Kälte, giftige Luft, Vakuum), ohne passenden Anzug sinkt die Lebensleiste – ja.
- **Persönliche Ausrüstung:** Anzüge, Handwaffen, Werkzeuge, eigenes kleines Inventar; **Ausrüstungsprinzip wie beim Raumschiff** (Größe/Qualität F–A, Slots).
- **Wer ist am Boden:** zurückgestellt (Söldner als Begleiter, Wachen, Banditen), bis das Kampfsystem steht.
- **All während der Landung:** wird **weiter simuliert**.
- **Wolkenstädte:** ja, in Teil 7.
- **Als Nächstes:** Kampf und Gameplay am Boden **konzeptionell** durchdenken, bevor die Pakete festgelegt werden.

**Konzept Boden (Entscheidung Luz, 9. Nov 2026):**
- **Ablauf:** **Städte** sind begehbare Orte, die wie Stationen funktionieren (Landefeld, Straßen, Gebäude mit Bar, Markt, Ausrüster, Auftragsbrett; Wachen nach Sicherheit); **POIs** sind Einsatzorte mit einem Ziel (bergen, retten, erkunden, abbauen) mit Gefahren und Gegnern – danach zurück zum Schiff. Ein Ort dauert typisch 5–15 Minuten; das All läuft weiter.
- **Begehbare Stationen:** ab Teil 7 hat auch **jede Raumstation einen begehbaren Bereich** – man kann weiterhin alles über das Fenster machen, aber auch **aussteigen** und einen kleinen Teil der Station begehen, dessen **Design vom Stationstyp abhängt**, mit allen möglichen **Läden und der Bar**.
- **Kampf: Hybrid (D).** Laufen mit WASD; gekämpft wird mit **Aufschalten wie beim Schiff** – die Waffe feuert selbst, Firearms bestimmt die Trefferquote; die Aufgabe des Spielers sind Position, Deckung, Abstand, Ausweichen und **aktive Ausrüstung auf 1–4** (Granate, Schildgenerator, Medkit, Stimulans). Dazu als Aufgabe: das **Steuern der Crewmitglieder im Bodenteam**, wenn man eins hat.
- **Gefühl:** Kampf ist eine wichtige Sache – wahrscheinlich die wichtigste, wie im All –, aber **nicht die einzige**.
- **Schwierigkeit:** der Pilot kann am Boden sterben – er **wacht in der Klinik** auf und verliert einen Teil seiner Ausrüstung.

### Entscheidungen zu Teil 7

| Frage | Optionen | Vorschlag | Entscheidung |
| --- | --- | --- | --- |
| Bodenansicht | Draufsicht wie im Weltraum · Seitenansicht · eigene Szenen | Draufsicht in Pixel-Art | **Draufsicht wie im All** |
| Planetenkarten | prozedural · handgebaut · gemischt | prozedural, wichtige Orte handgebaut | **Prozedural, Schlüsselorte** (Hauptstädte, Fraktions-Heimatwelten, Story-Orte) **von Hand** |
| Landbare Welten | feste Planeten + Wolkenstädte · nur ausgewählte · alle inkl. Monde | feste Planeten und Monde, Gasriesen über Wolkenstädte | **Alle festen Planeten** (und Monde); bei Gasriesen nur die **Wolkenstädte** |

## Phase 0.5 Teil 8 – Intro and First Part of the Story (grober Plan)

### Die Geschichte des Einstiegs

- **Der Pilot** ist ein **Charter-Pilot aus der Zeit um 12600 HE** – also aus der Expansion, noch vor der Severance. Bei einer Erkundungsreise gerät er in eine seltsame Raumanomalie und wird **rund 300 Jahre in die Zukunft** geschleudert.
- **Ankunft:** Er wird in einem völlig zerstörten Schiff aus einem **Wurmloch** gejagt – im System **Beyond**.
- **Beyond** liegt, wie der Name sagt, **außerhalb des Clusters**: keine Sprungtorverbindung, aber noch nicht im Veil. Die Severance hat Beyond schwer getroffen: Die **große Goldflotte der Erde** war gerade auf dem Weg durch das System und wurde vollständig zerstört. Beyond ist voller **Wracks übergroßer Schiffe** – die Schiffe, die die Reise zur Erde ohne das Long Gate schaffen konnten, waren beinahe planetengroß.
- **Dan** (Arbeitsname) leitet die **einzige Station in Beyond**, im Orbit um den erdähnlichen Planeten, mit einem **Abwrack- und Bergbauunternehmen**. Er rettet den Piloten, eröffnet ihm, dass sein Schiff vollkommen zerstört ist – und dass er ihm etwas schuldet. Er bietet **Geleit ins Cluster** an, wenn der Pilot eine Weile für ihn arbeitet.
- **Charaktererstellung bei der Rettung:** Auf Dans Station wird der Pilot untersucht (medizinischer Scan / Identitätsabgleich) – dabei werden Aussehen und Werte aus Teil 5 festgelegt.
- **Das alte Schiff:** Das Schiff des Piloten ist ein **Earthworks-Modell, das heute nicht mehr gebaut wird**. Dan nimmt es ihm ab – angeblich ist es Schrott. Irgendwann später liest man in den Nachrichten, dass ein Oldtimer-Sammler ein verloren geglaubtes Earthworks-Modell für **100 Millionen Credits** gekauft hat.
- **Zwei Wege bei Dan:**
  - **Mit Tutorial:** Man arbeitet Dans Aufträge der Reihe nach ab und lernt dabei Schiffssteuerung, Missionen und Grundwissen über die Welt. Die Schuld ist hier erzählerisch – sie ist mit den Tutorial-Aufträgen abgearbeitet.
  - **Ohne Tutorial:** Man muss trotzdem für Dan arbeiten, ist dabei aber **freier** und bekommt von Dan ein paar **KHI-Schiffe** gestellt. Die Schuld ist dann ein **echter Geldbetrag**; ist sie abbezahlt, geht es ins Cluster.
- **Abschluss:** Dan stellt einen **Freund aus dem Meridian Directorate** vor, der mit seinem **Prototyp-Sprungschiff** einen Weg nach Beyond gefunden hat. Er handelt mit Dan um **seltene alte Erdrelikte**, um daraus das **Tor zurück zur Erde** zu bauen (Project Bridge). Bei ihm wählt der Spieler, ob er im Gebiet der **Assembly** oder des **Covenant** startet. Das **Directorate** steht bewusst nicht zur Wahl: Es ist später für die Story wichtig und führt selten bis nie Krieg.
- **Zurück nach Beyond:** Wer im Directorate später aufsteigt, bekommt ein **Sprungschiff**, mit dem Beyond wieder erreichbar ist.
- **Erzählweise:** Dialoge mit Porträts an Stationen, Funksprüche im Flug, wenige kurze Zwischensequenzen (Wurmloch, Ankunft im Cluster).

### Arbeitspakete (Vorschlag)

Nummerierung schließt an Teil 7 an (dort bis Paket 54).

| # | Arbeitspaket | Inhalt |
| --- | --- | --- |
| 55 | Story-Grundgerüst | wiederverwendbares System für die Story: Story-Missionen und -Schritte, Dialoge mit Porträts, Story-Flags im Spielstand, Tutorial-Hinweise; Grundlage für alle späteren Story-Teile (Phase 1) |
| 56 | Intro-Sequenz | Anomalie und Ausstoß aus dem Wurmloch im zerstörten Schiff, Rettung durch Dan; Charaktererstellung als Scan auf Dans Station |
| 57 | Spezialsystem Beyond | System außerhalb des Clusters ohne Tor; Wrackfelder der Goldflotte mit (beinahe) planetengroßen Wracks; Dans Station am erdähnlichen Planeten |
| 58 | Arbeit für Dan | zwei Wege: **Tutorial** (geführte Aufträge für Steuerung, Andocken, Bergbau, Bergen, Kampf, Aufträge; erste Skilltree-Knoten) oder **freie Arbeit** mit gestellten KHI-Schiffen und echter Geldschuld; danach geht es ins Cluster |
| 59 | Weg ins Cluster | Directorate-Kontakt mit Prototyp-Sprungschiff, Erdrelikte, Wahl des Startgebiets (Assembly oder Covenant), Überfahrt |
| 60 | Fenster „Acquaintances“ | Personen, die man kennengelernt hat (Dan, der Directorate-Kontakt …), mit Porträt, Ort und Beziehung; der bestehende Schiffs-Reiter „Contacts“ bleibt |
| 61 | Spezialsystem Fern | Casino-System: ein einziger Planet um einen orangen Riesen, mit einer besonderen Casino-Station |
| 62 | Casino-Minispiele | neue Minispiele in der Casino-Station |
| 63 | Neue Schiffe | das alte Earthworks-Schiff des Piloten (nicht mehr hergestellt; taucht später als 100-Millionen-Sammlerstück in den Nachrichten auf), besondere Casino-Schiffe, ein Rennschiff von Maison Aurelle |
| 64 | Neue Missionsarten | _(Details offen)_ |
| 65 | Neue Touristenziele | _(Details offen)_ – baut auf Tourismus (Paket 43) und Sehenswürdigkeiten (Paket 54) auf |

Wie immer: **jedes Paket mit eigenen Debug-Funktionen** – z. B. zu jedem Story-Schritt springen, Story-Flags setzen, Intro überspringen, direkt nach Beyond oder Fern teleportieren, Casino-Spiele mit festem Ausgang testen.

### Anmerkungen von Claude

- **Die Zeitreise passt sehr gut in die Lore.** 12600 liegt mitten in der Expansion, 12713 ist die Severance – der Pilot kennt die Welt noch *vor* dem Bruch und ist damit der ideale Blick von außen. Und die Anomalie, die ihn 300 Jahre versetzt, ist ein natürlicher Faden zum Rätsel der Severance.
- **Sie erklärt den Skilltree:** Ein Pilot von vor 300 Jahren kennt die heutigen Schiffe und Module nicht – deshalb muss er sie neu lernen. Das passt genau zu „beim Start ist sehr wenig frei“ aus Teil 5.
- **Der freie Weg bei Dan** ist eine gute Lösung für erneutes Spielen: kein reines Überspringen, sondern ein schnellerer, offener Einstieg mit echter Schuld.

### Entscheidungen zu Teil 8

| Frage | Optionen | Vorschlag | Entscheidung |
| --- | --- | --- | --- |
| Wann wird der Charakter erstellt? | vor dem Intro · bei der Rettung · nach dem Tutorial | Bei der Rettung durch Dan | **Bei der Rettung durch Dan** (Scan / Identitätsabgleich) |
| Wie wird erzählt? | Dialoge · Funk · Zwischensequenzen · Mischung | Mischung | **Mischung**: Dialoge mit Porträts an Stationen, Funk im Flug, wenige kurze Zwischensequenzen |
| Startgebiet auch beim Directorate? | nur Assembly/Covenant · auch Directorate | – | **Nein** – das Directorate ist später für die Story wichtig und führt selten bis nie Krieg |
| Kann man nach Beyond zurück? | nein · später über die Story · über den Directorate-Kontakt | Später über die Story | **Mit Aufstieg im Directorate**: man bekommt ein Sprungschiff, mit dem Beyond erreichbar ist |
| Name des Personen-Fensters | Schiffs-Reiter umbenennen · Personen-Fenster anders nennen | Schiffs-Reiter „Ships“, Personen „Contacts“ | **„Acquaintances“** für Personen; der Schiffs-Reiter bleibt „Contacts“ |
| Intro überspringen | nie · ab dem zweiten Spiel · immer wählbar | Beim Spielstart wählbar | **Nicht ganz überspringbar**: Wer das Tutorial ablehnt, arbeitet trotzdem für Dan, aber freier und mit gestellten KHI-Schiffen; nach Abzahlung der Schuld geht es ins Cluster |
| Was ist das alte Schiff von der Erde? | das eigene · ein Goldflotten-Schiff · beides | Das eigene Charter-Schiff | **Ein Earthworks-Modell, das nicht mehr gebaut wird** – Dan nimmt es dem Piloten als „Schrott“ ab; später liest man, dass ein Sammler ein verloren geglaubtes Earthworks-Modell für 100 Mio. Credits gekauft hat |
| Dans Schulden | reine Story · echter Betrag | Echter Betrag | **Abhängig vom Weg**: mit Tutorial erzählerisch (Aufträge abarbeiten), ohne Tutorial ein echter Geldbetrag |

## Phase 0.5 Teil 9 – Feeling and Balancing (grober Plan)

Abschluss von Phase 0.5: Das Spiel wird aufgeräumt, schneller, klingt nach etwas und wird ausbalanciert. **Paket 8 (großes Balancing mit Analyse-Werkzeug) geht in den Balancing-Paketen 72–74 auf.** Nummerierung schließt an Teil 8 an (dort bis Paket 65).

### Part A – Feeling

| # | Arbeitspaket | Inhalt |
| --- | --- | --- |
| 66 | Großes Code-Review & Aufräumen | den gesamten Code System für System durchgehen (z. B. mit Claude Fable): aufräumen, optimieren, Fehler und Lücken suchen; Funde zuerst als Liste, Änderungen nach Freigabe (kleine Reviews gab es schon am Ende jedes Teils) |
| 67 | Performance & Laden (Feinschliff) | Ladebildschirme **mit Lore-Bildern**, Feinschliff am Vorladen und an den Loading Gates (Grundlagen dafür kommen schon in Teil 6) |
| 68 | Neues Hauptmenü | Hauptmenü neu gestaltet |
| 69 | Sound Design | **BGM** (Musik je Situation – Menü, System, Kampf, Station, Hyperraum – mit Variationen je Fraktionsgebiet), **BGS** (Atmosphäre) und **SFX** (Effekte); Feinschliff und Mischung auf Basis des Audio-Grundgerüsts aus Teil 5. Quellen: selbst gemacht, freie Lizenzen (CC0 u. ä.) und KI-erzeugt – alle Lizenzen und Quellen in einer Datei im Projekt festgehalten |
| 70 | Asset-Review-Tool | neues Werkzeug als **eigene Szene**, erreichbar über das Debug-Menü: alle Assets einzeln durchgehen (über die Erzeuger mit festen Schlüsseln, z. B. Schiff + Lackierung), Animationen ansehen, **Notizen pro Asset** hinterlassen; Notizen in einer Projektdatei (z. B. `asset_notes.json`) mit Status „offen / umgesetzt“, damit Claude Code sie gezielt anwenden kann |
| 71 | Mehr Einstellungen | **Grafik** (Auflösung, VSync, FPS-Grenze, UI-Skalierung, Effektqualität), **Audio** (Gesamt, Musik, Atmosphäre, Effekte), **HUD** (Größe, sichtbare Elemente, Schadenszahlen), **Spiel** (Autosave-Intervall, Sicherheitsabfragen, Tutorial-Hinweise) |

### Part B – Balancing

| # | Arbeitspaket | Inhalt |
| --- | --- | --- |
| 72 | Balancing-Tool | Werkzeug zur Analyse: Werte von Schiffen und Modulen vergleichen, Einnahmen pro Stunde je Tätigkeit, Preise, Kampfstärken (aus Paket 8) |
| 72a | Skilltree-Revision | gemeinsamer Detail-Durchgang mit Luz über den **ganzen Fortschritt**: Aufbau des Baums (Äste, Reihenfolge, was wo hängt, fehlende oder überflüssige Kacheln), **jede Kachel** mit ihren Leistungen und Freischaltungen, die **Perks** (Werte, Voraussetzungen), die **Fähigkeiten** (+1 % je Stufe, Erfahrungskurven) und die **Pilotenlevel-Kurve** – fürs Balancing, mit den Zahlen aus dem Balancing-Tool (siehe unten) |
| 73 | Balancing | Durchgang über alle Systeme mit dem Werkzeug |
| 74 | Playtests | Luz spielt, dazu **automatische Testläufe mit Mitschrift** (Credits pro Stunde, Abschüsse, Zeit je Tätigkeit); Erkenntnisse zurück ins Balancing; externe Tester später |

**Skilltree-Revision (72a) – festgehalten 7. Nov 2026 (Wunsch Luz):** Der Baum aus 0.5.30.2 ist ein erster Wurf, die Zahlen sind Schätzungen. Für den Durchgang mitnehmen:

- **Aufbau:** Stamm (Pilot Licence) und Startumfang passend zum Story-Intro aus Teil 8 (welche Kacheln das Intro schon öffnet); Äste nach Tätigkeit prüfen; ob Meisterschaft als Wurzeln bleibt; Heavy Industry mit zwei Vorgängern als Vorbild für weitere Querverbindungen.
- **Neue Inhalte einhängen**, die bis dahin dazukommen: Crew und Söldner (Teil 5 B), Ausrüstung wie Raumanzüge, Handwaffen und Werkzeuge (Teil 7), neue Schiffe und Module aus Teil 6–8.
- **Leistungen:** Höhe je Kachel gegen die gemessene Spielzeit je Tätigkeit (Balancing-Tool, Playtest-Mitschrift aus Paket 74) – wie lange dauert es bis Fighters, Mining Frigates, Capital Ships …?
- **Nutzungssperre:** ob gesperrte Kernmodule, offline-Module und angedockte Schiffe so bleiben oder feiner werden.
- **Perks** (24, Werte und Fähigkeitsstufen), **Fähigkeiten** (Boni je Stufe, Erfahrung je Tätigkeit) und **Pilotenlevel** (Kurve, Perkpunkte, Level 50 als Ende?).
- Debug: Fortschritt eines Testpiloten über Zeit simulieren und als Liste ausgeben (wann welche Kachel aufgeht).

Wie immer: jedes Paket mit eigenen Debug-Funktionen (z. B. Lautstärke/Spur je Situation erzwingen, Ladezeiten messen und anzeigen, Balancing-Werte live ändern).

### Entscheidungen zu Teil 9

| Frage | Optionen | Vorschlag | Entscheidung |
| --- | --- | --- | --- |
| Code-Review | nur in Teil 9 · zusätzlich klein am Ende jedes Teils | Klein am Ende jedes Teils + großes Review in Teil 9 | **Klein am Ende jedes Teils**, großes Review in Teil 9; Funde zuerst als Liste, Änderungen nach Freigabe |
| Audio-Grundgerüst | alles in Teil 9 · Grundgerüst früher | Grundgerüst mit Teil 5 | **Grundgerüst mit Teil 5**; Musik, Atmosphäre und Feinschliff in Teil 9 |
| Laden | alles in Teil 9 · Grundlagen in Teil 6 | Grundlagen in Teil 6 | **Grundlagen in Teil 6** (Vorladen, Loading Gates); Ladebildschirme und Feinschliff in Teil 9 |
| Soundeffekte (SFX) | in Paket 69 · eigenes Paket · später | In Paket 69 | **In Paket 69** (BGM, BGS und SFX) |
| Herkunft von Musik und Sounds | selbst gemacht · freie Lizenzen · KI-erzeugt · gekauft/beauftragt | – | **Selbst gemacht, freie Lizenzen (CC0 u. ä.) und KI-erzeugt**; Lizenzen und Quellen werden im Projekt festgehalten |
| Musik je Situation | eine Spur · je Situation · zusätzlich je Fraktionsgebiet | Je Situation + Fraktions-Variation | **Je Situation, mit Variationen je Fraktionsgebiet** |
| Asset-Review-Tool: wo? | im Debug-Menü · eigene Szene · eigenes Programm | Eigene Szene, über das Debug-Menü | **Eigene Szene**, erreichbar über das Debug-Menü |
| Welche Einstellungen? | Grafik · Audio · HUD · Spiel | alle vier | **Grafik, Audio, HUD und Spiel** |
| Ladebildschirme | einfach · mit Tipps/Codex · mit Lore-Bildern | Mit Tipps und Codex-Auszügen | **Mit Lore-Bildern** |
| Playtests | nur Luz · Luz + automatische Testläufe · auch externe | Luz + automatische Testläufe | **Luz + automatische Testläufe** mit Mitschrift; externe Tester später |

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
