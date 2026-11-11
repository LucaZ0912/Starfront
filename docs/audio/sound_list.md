# Sternenfront – Soundliste für Paket 28a (Audio-Grundgerüst)

Stand 7. Nov 2026, Entwurf zum Abstimmen. Die **ID** ist der Dateiname und der Schlüssel im Code
(`sfx/<id>.ogg`).

**Priorität:**
- **A** = gleich in 28a als Platzhalter
- **B** = bald, gern mit 28a
- **C** = später, mit dem Paket der jeweiligen Funktion oder in Teil 9

**Grundton des Spiels:** Pixel-Art und Neon-Stationen, aber keine Comic-Bleeps. Synthetisch und leicht analog,
mit „Weltraum-Industrie“-Charakter: Servos, Druckluft, tiefe Synth-Bässe. Waffen sind knackig, aber kurz, weil
im Gefecht viele gleichzeitig feuern.

**Technik-Vorschlag:**
- OGG Vorbis, 44,1 kHz.
- Effekte mono (das Spiel verteilt sie im Stereobild nach Position), Atmosphäre und Musik stereo.
- Loops nahtlos schneidbar.
- Lautheit grob einheitlich (Effekte etwa −14 LUFS, Atmosphäre leiser).

Kanäle: **SFX** (Effekte), **UI**, **AMB** (Atmosphäre), **MUS** (Musik) – passend zu den geplanten
Lautstärkereglern.

---

## 1. Flug & Navigation (SFX)

| ID | Ereignis | Klangvorschlag | Länge | Prio |
| --- | --- | --- | --- | --- |
| `engine_loop` | Eigenes Triebwerk (Loop, Tonhöhe und Lautstärke folgen der Geschwindigkeit) | Tiefes, weiches Rauschen mit leichtem Brummen darunter; bei Vollgas heller und luftiger | Loop 3–4 s | A |
| `boost` | Schub (Shift): kurzer Boost, 0.6.75.2 | Hartes Zünd-Fauchen mit tiefem Druckstoß, das schnell abklingt | 1,1 s | A |
| `afterburner_on` | Nachbrenner an | Kurzes Zünd-„Wumm“, dann ein fauchender Schub, der in den Loop übergeht | 0,6 s | B |
| `afterburner_loop` | Nachbrenner läuft | Heiseres, druckvolles Fauchen | Loop 2 s | B |
| `warp_spool` | Warp lädt auf (Ausrichten) | Ansteigender Synth-Ton mit pulsierendem Flattern, wie ein aufgeladener Kondensator | 2–3 s | A |
| `warp_enter` | Eintritt in den Warp | Tiefer „Whoomp“-Sog, Ton kippt nach oben weg | 1 s | A |
| `warp_loop` | Im Warp | Gedämpftes, schwebendes Dröhnen mit leichtem Flanger | Loop 4 s | B |
| `warp_exit` | Austritt aus dem Warp | Umgekehrter Sog: rauschendes Abbremsen, kurzer tiefer Nachhall | 1 s | A |
| `gate_activate` | Sprungtor aktiviert sich | Elektrisches Summen, das sich in Stufen aufbaut, Funkenknistern | 2 s | A |
| `jump_hyperspace` | Hyperraumsprung | Großer Riss: tiefer Bass-Schlag, dann ein verzerrtes, sich entfernendes Heulen | 2–3 s | A |
| `hyperspace_loop` | Transit-Bildschirm | Weites, tiefes Rauschen mit langsamem Pulsieren | Loop 6 s | B |
| `wormhole_open` | Threshold öffnet Wurmloch | Tiefes Saugen, das sich zu einem verzerrten Schwarze-Loch-Brummen dreht | 2 s | B |
| `wormhole_collapse` | Fehlgeschlagener Wurmloch-Sprung | Knirschender Abbruch, Ton bricht unsauber ab | 1 s | C |

## 2. Andocken & Stationen (SFX)

| ID | Ereignis | Klangvorschlag | Länge | Prio |
| --- | --- | --- | --- | --- |
| `dock_clamp` | Andocken abgeschlossen (in der Bucht) | Schweres mechanisches „Klonk“ mit Druckluftzischen | 1,2 s | A |
| `undock_release` | Abdocken | Klammern lösen sich: Klacken, Zischen, leichtes Anrollen | 1,2 s | A |
| `bay_enter` | Schiff fährt in die Hangarbucht | Hall wird enger, dumpfes Raumgeräusch | 1,5 s | C |
| `pad_hatch_open` | Lukentüren einer Plattform öffnen | Servo-Surren mit hydraulischem Gleiten, am Ende ein Anschlag | 1 s | B |
| `pad_hatch_close` | Lukentüren schließen | Wie oben, umgekehrt, satterer Anschlag | 1 s | B |
| `pad_touchdown` | Aufsetzen auf der Plattform | Dämpferzischen und tiefes Aufsetzen | 0,6 s | C |
| `station_hail` | Andockerlaubnis / Begrüßung | Zwei-Ton-Gong mit leichtem Funk-Rauschen | 0,8 s | B |

## 3. Kampf – Waffen (SFX)

Waffen klingen nach Schadensart: **optisch** hell, sirrend, **kinetisch** knallend, metallisch,
**explosiv** dumpf zischend.

| ID | Ereignis | Klangvorschlag | Länge | Prio |
| --- | --- | --- | --- | --- |
| `w_pulse` | Pulse Laser | Kurzes, helles „Pew“ mit etwas Biss (kein Spielzeug) | 0,2 s | A |
| `w_beam_loop` | Beam Laser (feuert) | Sirrendes, gleichmäßiges Summen | Loop 1 s | A |
| `w_lance` | Photon Lance | Aufladen (steigendes Fiepen) und dann ein satter heller Schuss | 1,2 s | B |
| `w_autocannon` | Autocannon | Trockenes, schnelles „Tak“, gut wiederholbar | 0,15 s | A |
| `w_railgun` | Railgun | Elektrisches Laden, dann ein peitschender Knall | 0,8 s | B |
| `w_massdriver` | Mass Driver | Wuchtiger, tiefer Knall mit metallischem Nachklang | 0,5 s | B |
| `w_rocket` | Raketenwerfer | Zischendes Abfeuern, „Fssst“ | 0,5 s | A |
| `w_arm_laser` | Roter Arm-Laser (Pathfinder, zu Fuß) | Tiefes, brodelndes Zischen, darunter ein dunkles Grollen, oben ein leises Brutzeln (0.7.52.15, Luz; hält 2,5 s seit 0.7.52.17) | 2,6 s | A |
| `w_torpedo` | Torpedo | Tiefes Ausstoßen mit Zischen, langsam anlaufend | 1 s | B |
| `w_cruise` | Marschflugkörper | Schweres Abheben, länger fauchend | 1,2 s | C |
| `w_ion` | Ionenwaffen | Knisterndes Elektro-Zappen | 0,3 s | B |
| `w_focus_charge` | Fokuslanze lädt | Mehrere helle Töne laufen zu einem Akkord zusammen (wie Kristalle) | 0,6 s | B |
| `w_focus_burn` | Fokuslanze brennt | Breiter, singender Strahl, chorartig, rot-heiß | 1 s | B |
| `w_pointdef` | Punktverteidigung | Sehr schnelles, leises Rattern | Loop 0,5 s | C |
| `mine_drop` | Mine ausgelegt | Mechanisches Ausklinken, dann ein leises Piepen (scharf) | 0,5 s | C |

## 4. Kampf – Treffer & Zerstörung (SFX)

| ID | Ereignis | Klangvorschlag | Länge | Prio |
| --- | --- | --- | --- | --- |
| `hit_shield` | Treffer auf Schild | Hohles, glasiges „Wumm“ mit Flirren | 0,3 s | A |
| `hit_armor` | Treffer auf Panzerung | Metallischer Schlag, kurz | 0,3 s | A |
| `hit_hull` | Treffer auf Struktur | Dumpfes Krachen mit Knistern und Funken | 0,4 s | A |
| `shield_down` | Schild bricht zusammen | Absteigender Glas-Klirr-Ton, Energie entweicht | 0,8 s | A |
| `shield_up` | Schild wieder da | Aufsteigendes, sauberes Summen | 0,6 s | B |
| `explosion_small` | Kleines Schiff, Drohne, Rakete | Kurzer, knackiger Knall mit Trümmerrauschen | 1 s | A |
| `explosion_large` | M/L-Schiff zerstört | Tiefer, langer Donner, mehrere Nachexplosionen | 2,5 s | A |
| `explosion_mine` | Mine geht hoch | Harter, trockener Schlag | 0,8 s | C |
| `lock_progress` | Zielerfassung läuft | Leise, schneller werdende Pieps-Folge | Loop | B |
| `lock_acquired` | Ziel erfasst | Klarer Doppelpiep | 0,3 s | A |
| `missile_warning` | Rakete/Torpedo im Anflug | Schnelles, dringliches Warnpiepen | Loop 1 s | B |
| `emp_hit` | EMP trifft eigenes Schiff | Elektrisches Krachen, dann ein „Ausfall“-Abfall der Systeme | 1 s | C |

## 5. Module & Ausrüstung (SFX)

| ID | Ereignis | Klangvorschlag | Länge | Prio |
| --- | --- | --- | --- | --- |
| `module_on` | Modul aktivieren (allgemein) | Kurzes Relais-Klicken plus aufsteigender Mini-Synth | 0,2 s | A |
| `module_off` | Modul deaktivieren | Relais-Klicken plus absteigender Ton | 0,2 s | A |
| `module_denied` | Modul lässt sich nicht einschalten | Dumpfer Zwei-Ton-„Bonk“ | 0,3 s | A |
| `power_overload` | Stromüberlast, Gruppe schaltet ab | Brummender Abfall, Relais knallen nacheinander | 1 s | B |
| `mining_loop` | Bergbaulaser | Schleifendes Sirren mit Gesteinsknistern | Loop 2 s | A |
| `harvester_loop` | Eisernter | Kälteres, splitterndes Sirren | Loop 2 s | C |
| `ore_collected` | Erz im Laderaum | Kurzes, sattes Rumpeln | 0,4 s | B |
| `scan_ping` | Scanner / Survey | Sonar-Ping mit Nachhall | 1 s | A |
| `scan_complete` | Scan / Analyse fertig | Aufsteigender Drei-Ton-Akkord | 0,6 s | B |
| `repair_beam_loop` | Reparaturstrahl | Weiches, warmes Summen mit Knistern | Loop 2 s | C |
| `shield_boost` | Schildbooster | Steigendes Aufladen | 0,8 s | C |
| `jammer_loop` | Radarstörer an | Unruhiges, statisches Rauschen | Loop 2 s | C |
| `cloak_on` | Tarnung an (Axiom) | Gläsernes Ausblenden: der Ton „zieht sich zurück“, phasig | 1 s | B |
| `cloak_off` | Tarnung aus | Umgekehrt, mit kleinem Schimmer am Ende | 0,8 s | B |
| `blackhole_ignite` | Threshold zündet das Schwarze Loch | Lichtblitz als heller Knall, dann ein tiefes, wachsendes Brummen | 2 s | B |
| `blackhole_loop` | Schwarzes Loch brennt | Sehr tiefes, rotierendes Wummern (leise) | Loop 4 s | C |
| `refinery_loop` | Bordraffinerie (KHI) | Industrielles Stampfen und Mahlen | Loop 3 s | C |
| `factory_loop` | Bordfabrik | Roboterarme, Schweißzischen | Loop 3 s | C |
| `drone_pulse` | Antidrohnenpuls (Cathedral) | Tiefer, ringförmiger „Wuuum“-Schlag mit Knistern | 1 s | C |

## 6. Drohnen (SFX)

| ID | Ereignis | Klangvorschlag | Länge | Prio |
| --- | --- | --- | --- | --- |
| `drone_launch` | Drohne startet | Kurzes Zischen, kleines Triebwerk heult hoch | 0,5 s | A |
| `drone_recall` | Drohnen zurückrufen | Funk-Doppelpiep | 0,3 s | B |
| `drone_dock` | Drohne landet im Hangar | Leichtes Einrasten | 0,3 s | B |
| `hatch_open` | Drohnenklappe auf | Kleines Servo-Surren | 0,5 s | C |
| `runway_roll` | Drohne auf der Startbahn | Kurzes Anrollen und Abheben | 0,8 s | C |
| `drone_lost` | Drohne verloren | Kurzer, abgehackter Funkabriss | 0,4 s | B |

## 7. Benutzeroberfläche (UI)

| ID | Ereignis | Klangvorschlag | Länge | Prio |
| --- | --- | --- | --- | --- |
| `ui_click` | Knopf drücken | Weiches, kurzes Synth-Klicken | 0,05 s | A |
| `ui_hover` | Über Kachel/Knopf fahren | Sehr leises Tick | 0,03 s | B |
| `ui_open` | Fenster/Menü öffnen | Kurzes Aufziehen, leicht holografisch | 0,25 s | A |
| `ui_close` | Fenster schließen | Umgekehrt | 0,2 s | A |
| `ui_tab` | Reiter wechseln | Knappes Doppelklicken | 0,1 s | B |
| `ui_error` | Fehler / nicht möglich | Tiefer Zwei-Ton | 0,3 s | A |
| `buy` | Kaufen | Münz-/Kassen-„Ching“, digital | 0,4 s | A |
| `sell` | Verkaufen | Ähnlich, etwas tiefer | 0,4 s | A |
| `fit_module` | Modul eingebaut | Schweres Einrasten mit Werkzeug-Klacken | 0,5 s | B |
| `mission_accept` | Auftrag angenommen | Bestätigender Zwei-Ton | 0,4 s | B |
| `mission_complete` | Auftrag erfüllt | Kurzer, aufsteigender Jingle (3–4 Töne) | 1 s | A |
| `mission_failed` | Auftrag gescheitert | Absteigender, gedämpfter Jingle | 1 s | B |
| `notify` | Neue Meldung im Log | Dezentes Glöckchen | 0,3 s | A |
| `warn` | Warnung im Log | Etwas schärferes Doppel-Pling | 0,4 s | A |
| `codex_entry` | Neuer Codex-Eintrag | Geheimnisvolles, kurzes Glitzern | 0,6 s | B |
| `standing_up` | Ansehen steigt | Kleiner positiver Akkord | 0,5 s | C |
| `standing_down` | Ansehen sinkt | Kleiner Moll-Akkord | 0,5 s | C |
| `map_open` | Galaxiekarte öffnen | Weites holografisches Aufblenden | 0,5 s | B |

## 8. Warnungen & Bordcomputer (SFX/UI)

| ID | Ereignis | Klangvorschlag | Länge | Prio |
| --- | --- | --- | --- | --- |
| `alarm_hull` | Struktur kritisch | Pulsierender Alarmton, tief, nicht nervig | Loop 1 s | A |
| `alarm_fuel` | Treibstoff knapp | Einzelner, ruhiger Warnton | 0,6 s | B |
| `alarm_pirates` | Piraten im System / Überfall | Kurze Sirene mit Funk-Rauschen | 1,5 s | B |
| `interdict` | Aus dem Warp gezogen | Hartes Bremsen: Kreischen, Klirren | 1 s | B |
| `cargo_full` | Laderaum voll | Dumpfer Einzelton | 0,3 s | C |

## 9. Atmosphäre (AMB)

| ID | Ereignis | Klangvorschlag | Länge | Prio |
| --- | --- | --- | --- | --- |
| `amb_space` | Weltraum allgemein | Sehr leises, tiefes Rauschen mit gelegentlichem fernen Knistern | Loop 30–60 s | A |
| `amb_station` | Im Concourse (Stationsmenü) | Hallendes Stimmengewirr, ferne Durchsagen, Lüftung | Loop 30 s | B |
| `amb_field` | In einem Asteroidenfeld | Gelegentliches Steinknirschen, tiefe Bewegung | Loop 30 s | C |
| `amb_star` | Nahe am Stern | Warmes, glühendes Brummen | Loop 30 s | C |
| `amb_veil` | Nahe am Veil (später) | Unheimliches, dissonantes Wabern | Loop 60 s | C |
| `radio_chatter` | Funkverkehr (zu den Radio-Meldungen) | Kurze, unverständliche, verzerrte Funksprüche | 1–2 s (mehrere Varianten) | C |

## 10. Musik (MUS) – nur Platzhalter, die echte Musik kommt in Teil 9 (Paket 69)

| ID | Ereignis | Klangvorschlag | Prio |
| --- | --- | --- | --- |
| `mus_menu` | Hauptmenü | Ruhiger, weiter Synthwave-Ambient | B |
| `mus_explore` | Freies Fliegen | Langsames, schwebendes Ambient-Pad | C |
| `mus_combat` | Gefecht | Treibender Puls, dunkler Synth-Bass | C |
| `mus_station` | Station | Lounge, leicht jazzig-elektronisch | C |

---

**Varianten:** Bei oft wiederholten Sounds (Waffen, Treffer, Klicks) helfen 2–3 leicht verschiedene Varianten
(`w_pulse_1`, `w_pulse_2` …). Das Grundgerüst wählt dann zufällig und verändert die Tonhöhe leicht, damit es nicht
maschinengewehrartig gleich klingt.

**Umfang:** insgesamt 103 Einträge – Priorität A sind 36 Sounds, B 39, C 28. Damit ist das Grundgerüst vollständig spielbar; alles andere kann nach und
nach mit den Paketen kommen.

| `cme_alarm` | 0.6.37.4: Warnung vor einem koronalen Massenausbruch (10 s vorher bis kurz danach) | Ruhiger, fremdartiger Alarm im Loop – von Luz geliefert (Pixabay, „extraterrestrial alert sound“ von fnx_sound, Pixabay Content License) | Loop | ✓ echt |
