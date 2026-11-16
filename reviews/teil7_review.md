# Code-Review Teil 7 – The Sky Is Not Enough (Pakete 49–54e)

Stand: alpha 0.7.54.17 (Commit `9df5731`), Review nur lesend – geändert wird erst nach Freigabe durch Luz.

**Umfang:** alles seit Teil 6 (`v0.6.75.4..v0.7.54.17`, unter `scripts/` 89 Dateien, rund 50.200 Zeilen neu): Stationsdecks
zu Fuß (49), Landen, Planetenkarte, Städte und Siedlungen (50), Ausrüstung, Anzug und Klinik (51), Kampf zu Fuß mit
Team, Drohnen, Granaten, Schleichen (52), Orte zum Erkunden mit Werkzeugen, Aufträgen zu Fuß, Dark Ones, Museum und
Wildnis (53a–f), Wolkenstädte mit Skyrail (54), Sehenswürdigkeiten und Ausflüge (54a), Kneipenspiele (54b), Hauptstädte
und besondere Stationsräume (54c), dynamisches Wetter (54e).
**Geprüfte Bereiche:** `ground_view.gd` (Levelwechsel `go_level`, `_process`, Eingabe, `use`, POI-Cache, Aufzüge,
Skyrail, Senat/Kurie/Exchange zu Fuß, Kurator, Wetter-Anbindung), `ground_combat.gd` (Schritt, Feuer, Treffer, Explosion,
Wiederaufstehen, Team, Taktik- und Schleichansicht), `weather.gd`, `weather_fx.gd`, `planet_map.gd`, `game_state.gd`
(neue Felder, Speichern/Laden, `new_game`, POIs, Museum, Sturz-Rückkauf, Aufträge zu Fuß), `pilot_gear.gd`
(Speichern, Slots, Sturz), `curia.gd`, `missions.gd` (Aufträge zu Fuß, Ausflüge, Shuttle), `commands.gd` (Minispiele,
Sehenswürdigkeiten, Souvenirs, Kurie/Senat), `main.gd` (Landen, Abheben, Sturz, Laden), `system_view.gd`
(Ab- und Aufstieg), `universe.gd` (Städte, Landeplätze), `debug_menu.gd` (Boden-Status).
**Nur gestreift** (Schleifen, Zufall, Auffälligkeiten – nicht Zeile für Zeile): die Generatoren `dungeon_gen`, `wild_gen`,
`sight_gen`, `deck_gen`, `cloud_gen`, `capital_gen`, `palace_gen`, `museum_gen`, `settle_gen`, `station_rooms`; die vier
Kneipenspiele (nur Einsatz, Abbruch, Ende); `walker.gd`. **Nicht geprüft:** die reinen Zeichen-Dateien (`chibi_art`,
`obj_art`, `build_art`, `creature_art`, `wild_art`, `cloud_sea`, `city_skyline` …), `flight_scene.gd`, `city_hatch.gd`,
`gear_panel.gd`, `pilot_window.gd` und der Smoke-Test selbst.
**Smoke-Test:** letzter voller Lauf 0.7.54.17: 875 Prüfungen, 0 Fehler (in dieser Sitzung nicht neu gelaufen). Die Befunde
unten sind aus dem Code abgeleitet, nicht im laufenden Spiel nachgestellt.

**Gesamteindruck:** Für 50.000 neue Zeilen ist der Teil erstaunlich sauber. Die Generatoren sind deterministisch (eigene
RNGs aus Hash-Seeds, nur zwei kosmetische Ausnahmen), das Wetter ist rein aus Spielzeit und Region berechnet und braucht
keinen Spielstand, der Kampf prüft an allen Stellen, die ich gelesen habe, auf „schon tot“ und auf freigegebene Nodes,
Minispiele rechnen Einsatz und Abbruch korrekt ab, und die neuen Felder werden vollständig gespeichert und geladen. Keinen
harten Absturz gefunden. Die Funde liegen an zwei Nähten: **Zustand, der nur in der `GroundView` lebt** (der Ort mit
seinen geöffneten Kisten und Gefallenen; Zünder und Zeitschalter, die per Index auf die alte Karte zeigen) und **Zustand,
der beim neuen Spiel nicht geleert wird**.

---

## Wichtig

### W1 – Der Zustand eines Orts lebt nur in der GroundView: Kisten und Gegner sind nach jedem Wiederbetreten wieder da (Beute beliebig oft)
`ground_view.gd` `_poi_map()` (`_poi_cache`), `_loot()`, `_wild_find()`; `main.gd` `land_at()`, `take_off("map")`,
`close_deck()`; `game_state.gd` `poi_use()` / `poi_used`

Was an einem Ort geöffnet, geplündert oder getötet wurde, steht nur in den Karten des `_poi_cache` der aktuellen
`GroundView`. Dauerhaft gemerkt wird allein „Ziel erledigt“ (`poi_used`). Der Cache geht an drei Stellen verloren:

1. **Abheben und wieder landen.** `take_off("map")` gibt die View frei, `land_at()` baut eine neue – alle Ebenen werden
   aus demselben Seed neu erzeugt, jede Kiste ist wieder zu, jeder Gegner steht wieder. Das geht über „Zur Planetenkarte“
   ohne jeden Flug in ein paar Sekunden.
2. **In der Stadt von der Gasse aufs Dach (oder umgekehrt).** `_poi_map()` hält nur **einen** Ort: Ist die Site-Id eine
   andere, wird `_poi_cache = {"site": sid}` neu angelegt. Kanal plündern → Aufzug zur Roof Plaza (Konzernturm) → zurück
   in die Gasse: die Kanalisation ist neu, ohne die Stadt zu verlassen.
3. **Speichern und Laden** auf dem Boden (nach dem Laden steht man auf der Planetenkarte, der Ort ist frisch).

Da `_loot()` seinen RNG aus dem Seed der Kiste nimmt, gibt jede Runde exakt dieselbe Beute: je Kiste 60–900 cr nach
Thema (Tresor und Versteck ×3), Forschungsdaten, Verbrauchsgüter und – mit festem Ergebnis – dieselben Museumsfunde, die
der Kurator als Dubletten ankauft. Solange man das Ziel nicht anrührt, bleibt der Ort auf der Karte. Bei Jagdaufträgen
kommt hinzu, dass `_poi_target_done()` dort bewusst kein `poi_use` setzt: der Fund am Ende der Wildnis (`wild_find`) ist
nach jeder Landung wieder zu holen. Umgekehrt geht auch echter Fortschritt verloren: aufgeschweißte Türen, gelegte
Reaktor-Schalter, die Minikarte.
**Vorschlag:** Den Zustand je Ort in `GameState` halten und speichern, z. B. `poi_state[site_id] = {"open": [...],
"dead": [...]}` mit Schlüsseln `"<ebene>:<index>"` – nach dem Erzeugen einer Karte anwenden (Zustand der Kisten/Türen
setzen, `dead`-Meta füllen), beim Erledigen des Ziels und beim nächsten Systembesuch (`poi_visits` zählt hoch) löschen.
Kleinste Lösung nur gegen die Beute: eine gespeicherte Liste `poi_looted` mit `"<site>:<ebene>:<index>"`, in `_loot()` und
`_wild_find()` geprüft. Dazu `_poi_cache` nach Site-Id schlüsseln (`_poi_cache[sid] = {...}`), damit Gasse und Dach
nebeneinander bestehen.

### W2 – Zünder, Stolperdrähte und Zeitschalter überleben den Levelwechsel und zeigen dann auf die falsche Karte
`ground_view.gd` `go_level()` (leert `_fuses`, `_wires_t`, `_haz_t`, `_socket` nicht), `_fuses_step()`, `_wires_step()`,
`_socket_step()`, `explore_use()` (Zellen 3 s, Kurbeltür 4 s), `_explore_effect()` (Tresorbohrer `VAULT_DRILL` 20 s),
`blast_near()`, `shot_lands()`

`_fuses` und `_wires_t` sind Wörterbücher „Index in `map.explore` → Restzeit“. `go_level()` setzt ein Dutzend anderer
Felder zurück, diese nicht. Läuft ein Zähler, während man die Ebene wechselt (Leiter, Tür, Aufzug – ein Tastendruck),
gilt der Index danach für die `explore`-Liste der **neuen** Karte:

- **Index zu groß:** `_fuses_step()` greift schon in der ersten Schleife auf `map.explore[int(k0)]` zu – Skriptfehler,
  die Funktion bricht ab, **bevor** die Zeit heruntergezählt wird. Das wiederholt sich in jedem Frame, solange die View
  lebt: Fehler-Spam, und kein Zünder, keine Kurbeltür, kein Zellenschloss, kein Tresorbohrer funktioniert an diesem Ort
  mehr. `_wires_step()` genauso: Zeit abgelaufen → Zugriff → Abbruch vor dem `erase` → ab da jeden Frame, und die
  Schleife über die Stolperdrähte dahinter läuft nie mehr.
- **Index passt:** Es trifft irgendein Ding der neuen Ebene. Ist es zufällig vom passenden Typ, geht dort eine Tür auf
  oder eine Sprengkiste hoch; beim Stolperdraht explodiert es in jedem Fall an der Position dieses Dings und der Alarm
  geht los (`raise_alarm()`), obwohl dort nichts war.
- **Die alte Karte bleibt hängen:** Im Cache steht das Ding weiter auf `"lit"`, `"falling"`, `"cranking"`, `"picking"`,
  `"drilling"` oder `"fired"` – beim Zurückkommen heißt es für immer „Still cranking…“, „The drill is biting – hold out“,
  die Sprengkiste zündet nie, der Gefangene kommt nie frei (Rettungsauftrag nicht mehr lösbar).

Die Schritte laufen außerdem nur, wenn `combat != null` ist. Ein Zähler „schläft“ also durch friedliche Ebenen (Gasse,
Straße) und wird erst im nächsten Ort mit Kampf wach – dort mit einem Index aus einem ganz anderen Ort. Realistische
Auslöser: der Klick eines Stolperdrahts (0,6 s) oder eine angeschossene Sprengkiste direkt an der Leiter; die Kurbeltür
(4 s) oder der Tresorbohrer (20 s), wenn man in der Wartezeit kurz die Ebene wechselt. `_socket` (Laden an der Steckdose)
hat denselben Fehler in harmlos: der Index wird gegen die neue Liste geprüft und sonst beendet.
**Vorschlag:** Die Zähler an die Karte hängen statt an die View (`map.set_meta("fuses", …)` / `"wires"`), in den Schritten
von dort lesen – dann laufen sie nach der Rückkehr einfach weiter und nichts bleibt hängen. Alternativ in `go_level()`
vor dem Wechsel alle offenen Zähler sofort auflösen oder ihren Zustand zurücksetzen (`"lit"`→`"shut"` usw.) und die
Wörterbücher leeren; `_haz_t`, `_socket`, `_sink` mit leeren. In beiden Schritten zusätzlich den Index prüfen
(`k < map.explore.size()`), damit ein verirrter Eintrag nie mehr jeden Frame wirft.

---

## Mittel

### M1 – Neues Spiel leert den Bodenzustand nicht: der neue Pilot erbt Museum, Fotos, Siegesserien und erledigte Orte
`game_state.gd` `new_game()`; betroffen `poi_visits`, `poi_used`, `museum_finds`, `museum_donated`, `sight_photos`,
`sight_visits`, `minigame_streak`, `minigame_wins`, `minigame_best`, `maint_sites`; dazu `Weather.debug_kind`

`new_game()` setzt `gear`, `fall_offer`, Senat, Kurie usw. zurück – die zehn neuen Felder aus Teil 7 fehlen. `from_dict()`
überschreibt sie beim Laden korrekt; wer aber in derselben Sitzung nach einer Partie ein neues Spiel beginnt, startet mit
dem Museum des alten Piloten samt dessen Boni (halbe Fehlsprung-Chance, +50 % Ruf für Reliquien, schnelleres Scannen,
halber Schaden der Symbolwelle), kann bereits gemachte Fotos nicht mehr verkaufen, sitzt mit der alten Siegesserie (und
deren Einsatzgrenzen) am Tisch, und der Archivist Suit wird nie mehr vergeben, weil `"_suit"` schon in `museum_donated`
steht. `maint_sites` wird zudem weder gespeichert noch in `from_dict()` geleert – ein per Debug oder Auftrag dunkel
geschalteter Wartungstunnel wandert in den nächsten geladenen Spielstand mit. Das ist dieselbe Klasse wie Review 6 K1.
**Vorschlag:** In `new_game()` alle zehn Felder leeren und `Weather.debug_kind = ""` setzen (dort, wo `SaveGame` schon
`Commands.suit_god = false` setzt, ebenfalls); `maint_sites.clear()` auch am Anfang von `from_dict()`. Ein Smoke-Check
„nach `new_game()` sind diese Felder leer“ fängt das für künftige Felder.

### M2 – Der Archivist Suit geht verloren, wenn die Taschen voll sind
`game_state.gd` `museum_donate()` (`gear.add_item(MuseumData.SUIT_REWARD, 1)`), `pilot_gear.gd` `add_item()` / `_add_to()`

`add_item()` gibt zurück, wie viel **nicht** hineingepasst hat. `museum_donate()` wirft den Rückgabewert weg, hängt aber
vorher `"_suit"` an `museum_donated` und meldet „it is in your pockets“. Wer das 48. Stück mit vollen Taschen abgibt – nach
einer langen Sammeltour nicht unwahrscheinlich –, bekommt die einmalige Belohnung für das ganze Museum nie. Der Kurator
sagt trotzdem „Here – the Archivist Suit; it is yours“.
**Vorschlag:** `"_suit"` nur setzen, wenn `add_item()` 0 zurückgibt; sonst den Anzug in den Spind des aktiven Schiffs legen
oder beim Kurator „liegen lassen“ (Option „Rewards“ gibt ihn aus, sobald Platz ist) und das im Text sagen.

### M3 – Schlüsselkarte des Konzernturms ist weg, sobald man die Roof Plaza einmal verlässt (freies Erkunden)
`ground_view.gd` `go_level()` (Tausch `_site` ↔ `_city_site`), `explore_use()` (`"keycard"`: `_site["card"] = true`),
`use()` (`"dungeon_down"` mit `need_card`), `game_state.gd` `corp_poi()`

Die Karte wird als Flag im `_site`-Wörterbuch gemerkt. Für einen Auftrag ist `_site` das Wörterbuch der Mission und
bleibt; ohne Auftrag liefert `GameState.corp_poi()` bei **jedem** Wechsel Straße → Dach ein frisches Wörterbuch. Die
Karten des Turms bleiben dagegen im Cache (gleiche Site-Id) – dort steht die Karte auf `"taken"`. Wer die Karte nimmt,
kurz zur Straße oder in die Klinik fährt und zurückkommt, steht vor dem Aufzug („wants a key card“), die Karte ist nicht
mehr zu finden, es bleibt nur die Feuertreppe mit Alarm. Dasselbe Muster trifft jedes weitere Flag, das an `_site`
hängt, sobald es für Orte ohne Auftrag gebraucht wird.
**Vorschlag:** Solche Flags an den Ort im Cache hängen (`_poi_cache["card"]`) oder beim Bauen aus der Karte ableiten
(„eine `keycard` der Site steht auf `taken`“). Mit W1 zusammen lösbar: das Flag gehört in den gespeicherten Ortszustand.

### M4 – Schleichen rechnet die Sichtkegel aller ahnungslosen Gegner in jedem Frame neu
`ground_combat.gd` `_draw_tactics()` → `_draw_sneak()` → `view_poly()`; angestoßen durch `tac_node.queue_redraw()` am
Ende von `step()`

Solange man schleicht, zeichnet `_draw_sneak()` in jedem Frame für **jeden** nicht alarmierten Gegner der Ebene ein
Sichtpolygon: 29 Strahlen, je Strahl ein Schritt alle 3 px bis zur Sichtweite, jeder Schritt ein `cover_at()`. Bei 200 px
Sichtweite sind das rund 1.900 Abfragen je Gegner und Frame, bei 15–20 Gegnern auf einer Ebene 30.000–40.000
GDScript-Aufrufe pro Frame – unabhängig davon, ob der Gegner im Bild ist oder sich bewegt hat. Die Taktikansicht des
Piloten (`cast()`) wird dagegen sauber nur alle 0,25 s oder nach Bewegung neu berechnet. Auf großen Karten (Piratenbasis,
Konzernturm) dürfte das genau in den Schleich-Passagen ruckeln. Nebenbei: steht ein Gegner mit dem Gesicht zur Wand,
fallen alle Endpunkte fast auf einen Punkt; `draw_colored_polygon()` meldet dann eine fehlgeschlagene Triangulierung
(unsicher, nicht nachgestellt).
**Vorschlag:** Das Polygon je Gegner zwischenspeichern (`f["vp"]`, neu nur wenn Position um mehr als 2 px oder Blick um
mehr als ein paar Grad abweicht, sonst höchstens alle 0,2 s), Gegner außerhalb des Bildausschnitts überspringen, und
Polygone mit zu kleiner Fläche nicht zeichnen.

---

## Klein

### K1 – Gehaltene Tasten überleben den Levelwechsel (Befehlsrad geht von selbst auf)
`ground_view.gd` `go_level()`, `_team_keys()`, `_unhandled_input()` (`_team_held`, `_tab_held`, `_drone_held`, `_revive`)
Die vier „Taste gehalten seit“-Zähler werden in `go_level()` nicht auf −1 gesetzt, und das Loslassen wird nur
verarbeitet, wenn die Ebene einen Kampf hat. Hält man V beim Hinausgehen in eine friedliche Ebene (Gasse, Minenkopf),
geht das Loslassen verloren; in der nächsten Ebene mit Kampf zählt `_team_keys()` weiter, das Befehlsrad öffnet sich von
selbst und die Zeit läuft mit 30 %, bis man V einmal drückt. Außerdem sperrt `use()` nicht, solange `_sink` läuft –
E auf der sinkenden Plattform setzt die Fahrt wieder auf Anfang.
**Vorschlag:** In `go_level()` alle vier auf −1 (bzw. `[-1.0, -1.0]`) setzen; in `use()` bei `not _sink.is_empty()` früh
zurück.

### K2 – Team am Boden: stirbt beim Gang durch eine Tür, überlebt beim Abheben
`ground_combat.gd` `leave()`, `ground_view.gd` `go_level()`, `main.gd` `close_deck()`, `take_off()`, `_fallen()`
`leave()` („wer noch am Boden liegt, stirbt dort“) wird nur aus `go_level()` gerufen. Hebt man vom Landefeld eines Orts
ab oder geht selbst zu Boden, wird die View einfach freigegeben – das niedergeschossene Mitglied ist danach gesund. Wer
dagegen nur in die Ruine tritt, verliert es.
**Vorschlag:** `leave()` auch beim Freigeben der View rufen (`_exit_tree()` der `GroundView` oder in `close_deck()`), oder
bewusst entscheiden, dass Abheben rettet, und es dann auch beim Ebenenwechsel so halten.

### K3 – Abgebrochener Reaktivierungsauftrag lässt die Wartungstunnel dunkel
`game_state.gd` `accept_mission()` (`maint_sites[...] = m["site"]`), `abandon_mission()`, `ground_goal()`, `maint_site_for()`
`maint_sites` wird beim Annehmen gesetzt und nur in `ground_goal()` wieder gelöscht. Nach „Abandon“ führt der Aufzug der
Stadt weiter in den dunklen Tunnel dieses Auftrags (ohne Ziel, ohne Lohn) – bis zum nächsten Laden, denn gespeichert
wird das Feld nicht (siehe M1).
**Vorschlag:** In `abandon_mission()` den Eintrag der Stadt löschen; das Feld entweder speichern oder ganz aus den
Missionen ableiten (das tut `maint_site_for()` als Rückfall schon) und nur noch für Debug nutzen.

### K4 – Planetenkarte zeigt für Wolkenstädte kein Wetter
`planet_map.gd` `select()`, `_draw_weather()` (`Weather.at(body, s)`), `weather.gd` `at()` / `world_class()`
Die Karte ruft `Weather.at()` ohne `cloud = true`; für einen Gasriesen ist die Wetterklasse dann leer, es gibt weder
Symbol noch Zeile – obwohl über dem Deck gerade ein Gassturm toben kann. Mit dem Flag allein wäre es noch nicht dasselbe
Wetter wie unten: am Boden ist der Schlüssel die Id der Stadt (`station["id"]`), auf der Karte hätte man nur die Site.
**Vorschlag:** In der Karte bei `Universe.is_giant(body)` mit `cloud = true` und als Ort
`{"id": Universe.city_id(body, s)}` aufrufen; `WEATHER_COL` um `gaswind`/`gasstorm` ergänzen.

### K5 – Souvenirstand meldet die gewünschte statt der gekauften Menge
`ground_view.gd` `_open_souvenir_menu()`, `commands.gd` `_c_souvenir_buy()`
Der Befehl kürzt die Menge still auf Laderaum und Guthaben und gibt `""` zurück; der Toast sagt trotzdem „Bought 50 …“,
auch wenn nur 7 hineinpassten.
**Vorschlag:** Die tatsächlich gekaufte Menge zurückmelden (z. B. Laderaum vorher/nachher vergleichen) und im Toast nennen.

### K6 – Audienz überschreibt eine bezahlte Petition ohne Hinweis
`curia.gd` `audience("edict", id)`, `petition()`; `ground_view.gd` `_open_curia_menu()`
Wer in der Kanzlei für 50.000 cr Zehnt eine Petition gestellt hat und danach beim Hierarchen ein anderes Edikt nennt,
verliert die Petition kommentarlos (`edict["petition"] = id`). Umgekehrt sperrt die Kanzlei ihre Knöpfe, sobald eine
Petition steht.
**Vorschlag:** In der Audienz die Edikt-Knöpfe sperren (oder nachfragen), wenn schon eine Petition steht – oder im Text
sagen, dass das Wort des Hierarchen die Petition ersetzt.

### K7 – Zwei Stellen der Generatoren nutzen den globalen Zufall
`deck_gen.gd` (Zeile 167 `ads.shuffle()`, Zeile 1036 `randf_range` für einen Laufpunkt), `cloud_gen.gd` (Zeile 285
`ads.shuffle()`)
Rein kosmetisch: Die Werbetafeln einer Straße wechseln bei jedem Betreten der Ebene, alles andere an der Karte ist fest.
Fällt nur auf, weil der Rest so konsequent deterministisch ist (und weil Bildvergleiche im Smoke-Test davon abhängen
könnten).
**Vorschlag:** Mit dem RNG der Karte mischen (Fisher-Yates über `rng.randi()`).

---

## Leistung, Determinismus, Speichern – ohne Befund

- **Wetter:** `WeatherFx` zeichnet je nach Lage 300–1.250 Linien oder Flecken pro Frame in einer GDScript-Schleife
  (Sandsturm am teuersten, dazu 240 Flecken der Staubteufel). Das ist in Ordnung; sollte es auf schwächeren Rechnern
  auffallen, lässt sich `_fall()` auf ein `draw_multiline()` je Aufruf umstellen. Die Abfrage des Wetters läuft einmal
  pro Sekunde, die Schleifen-Sounds werden in `_exit_tree()` gestoppt.
- **Kampf:** `alive()` filtert die Gegnerliste bei jedem Aufruf neu und wird pro Frame gut ein Dutzend Mal gerufen
  (Schritt, Explosionen, Zeichnen). Bei den jetzigen Gegnerzahlen unkritisch; einmal pro `step()` zwischenspeichern
  wäre billig.
- **Jeden Frame neu gezeichnet:** Schilder (`_signs`), Minikarte (`_mm`, auch ohne neue Kacheln), Planetenkarte
  (`_marks`). Alles klein.
- **Determinismus:** Orte, Städte, Sehenswürdigkeiten, Kurator-Name, Wetter – alles aus `hash()`-Seeds mit eigenem RNG.
  Bewusst zufällig sind nur Kampfwürfe, Beute gefallener Kreaturen und die Tipps am Spieltisch.
- **Speichern:** Ausrüstung (`gear.to_dict` inkl. Spinde und Team), Sturz-Angebot, Museum, Fotos, Besuche, Serien,
  Siegel der Kurie und die Flags der Auftragsorte (liegen im Missions-Wörterbuch) kommen vollständig zurück. Laden auf
  dem Boden führt bewusst auf die Planetenkarte.

## Lücken im Smoke-Test

Für jeden Befund fehlt eine Prüfung, die ihn gefangen hätte:

- **W1:** Kiste öffnen → abheben zur Karte → wieder landen (und: Gasse → Dach → Gasse) → die Kiste ist noch offen, ein
  Gefallener bleibt gefallen.
- **W2:** Sprengkiste anzünden bzw. Kurbeltür starten → sofort `go_level` auf eine Ebene mit kürzerer `explore`-Liste →
  einige Frames `_process` ohne Skriptfehler; zurück auf der alten Ebene ist das Ding nicht in einem Zwischenzustand.
- **M1:** nach `new_game()` sind `museum_donated`, `poi_used`, `sight_photos`, `minigame_streak` … leer.
- **M2:** letztes Stück spenden mit vollen Taschen → der Anzug ist irgendwo (Taschen, Spind oder ausstehend).
- **M3:** Karte nehmen → `go_level("street")` → `go_level("plaza")` → `_site["card"]` gilt noch.
- **K1/K2:** `_team_held` nach `go_level` ist −1; ein Mitglied am Boden nach Abheben.

## Vorschlag Reihenfolge

W1 und W2 zuerst – am besten zusammen mit M3, weil alle drei denselben Kern haben (Ortszustand gehört an den Ort bzw. in
den Spielstand, nicht in die View). Danach M1 und M2 (je wenige Zeilen), M4 und K1–K7 in einem Fix-Update, dazu die
Smoke-Checks oben; anschließend ein voller Smoke-Lauf.

---

## Alle Befunde

| Nr. | Schwere | Datei / Funktion | Kurz |
|---|---|---|---|
| W1 | Wichtig | `ground_view.gd` `_poi_map`, `_loot`; `main.gd` `land_at` | Ortszustand nur in der View – Kisten und Gegner nach Abheben, Gasse↔Dach oder Laden wieder da, Beute beliebig oft |
| W2 | Wichtig | `ground_view.gd` `go_level`, `_fuses_step`, `_wires_step` | Zünder/Stolperdrähte/Zeitschalter überleben den Levelwechsel: Skriptfehler jeden Frame oder falsches Ding, alte Karte hängt |
| M1 | Mittel | `game_state.gd` `new_game`, `from_dict` | Museum, Fotos, Serien, erledigte Orte, `maint_sites` beim neuen Spiel nicht geleert |
| M2 | Mittel | `game_state.gd` `museum_donate` | Archivist Suit verloren bei vollen Taschen |
| M3 | Mittel | `ground_view.gd` `go_level`, `explore_use`; `game_state.gd` `corp_poi` | Schlüsselkarte des Konzernturms weg nach Verlassen der Roof Plaza |
| M4 | Mittel | `ground_combat.gd` `_draw_sneak`, `view_poly` | Sichtkegel aller Gegner jeden Frame neu – 30.000+ Abfragen pro Frame beim Schleichen |
| K1 | Klein | `ground_view.gd` `go_level`, `_team_keys`, `use` | Gehaltene Tasten überleben den Levelwechsel; E setzt die sinkende Plattform zurück |
| K2 | Klein | `ground_combat.gd` `leave`; `main.gd` `close_deck` | Team am Boden stirbt beim Ebenenwechsel, überlebt beim Abheben |
| K3 | Klein | `game_state.gd` `abandon_mission`, `maint_sites` | Abgebrochener Reaktivierungsauftrag lässt den Tunnel dunkel (bis zum Laden) |
| K4 | Klein | `planet_map.gd` `_draw_weather`, `select` | Kein Wetter für Wolkenstädte auf der Planetenkarte |
| K5 | Klein | `ground_view.gd` `_open_souvenir_menu` | Toast nennt gewünschte statt gekaufter Menge |
| K6 | Klein | `curia.gd` `audience` | Audienz überschreibt bezahlte Petition kommentarlos |
| K7 | Klein | `deck_gen.gd`, `cloud_gen.gd` | `ads.shuffle()` / `randf_range` mit globalem Zufall |
