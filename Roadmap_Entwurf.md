# Sternenfront – Roadmap-Entwurf

Arbeitsdatei für die Planung kommender Teile. Wird von Luz und Claude (Chat) gepflegt –
**Claude Code ändert diese Datei nicht.** Fertige Abschnitte übernimmt Claude Code auf Zuruf
in die `Roadmap.md` („Übernimm Abschnitt X aus Roadmap_Entwurf.md in die Roadmap.md“).

Stand der Haupt-Roadmap beim Anlegen: alpha 0.4.25.6 – Teil 4 in den letzten Zügen
(Pakete 19–24 und 25a fertig), Teil 5 ist der nächste.

---

## Phase 0.5 Teil 5 – Character Update (Entwurf)

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
| 30 | Skilltree | erste Fortschrittsmechanik: Module, Größen, Qualitäten und Schiffsklassen werden durch Tun freigeschaltet (nicht zeitbasiert wie EVE) | 29, Teil 4 |
| 31 | Crew-System | Rollen, Mindest- und Höchstcrew für Schiffe ab M, Wirkung der Crew-Werte, Lohn, Erfahrung | 29 |
| 32 | Anheuern | neuer Stations-Service zum Anheuern (mit Monopolfirma), Crew-Verwaltung im Schiffsmenü, Crew aus Aufträgen | 31 |
| 33 | Söldner & Wingmen | anheuerbare Piloten mit eigenem Schiff fliegen im Verbund; einfache Befehle; Free Captains als Söldner | 31, 32 |
| 34 | Codex, Tutorial-Hinweise, Feinschliff | Codex-Einträge, Hinweise beim ersten Kontakt, Smoke-Tests, Balancing der Boni | alle |

---

### Teil A – Der Pilot

#### Charaktererstellung (Paket 28)

- Vorerst nur beim **Spielstart**: Name, Sprite, Attribute.
- **Sprite-Baukasten** in Pixel-Art: Körperform, Kopf/Frisur, Hautton, Kleidung/Anzug, Farben. Das **Porträt wird aus denselben Teilen erzeugt** (Brustbild), damit beides immer zusammenpasst.
- Der Sprite ist die **Vorbereitung auf Teil 6** (dort wird der Pilot vermutlich selbst sichtbar unterwegs sein) – in Teil 5 erscheint er nur in Menüs, Porträts, Funk- und Nachrichtenmeldungen.
- Die Crew und Söldner bekommen Porträts aus **demselben Baukasten** (zufällig erzeugt).

#### Attribute

Fünf Grundwerte, beim Start verteilt (Vorschlag: alle starten bei 3, dazu 8 freie Punkte, maximal 8 pro Attribut beim Start).

| Attribut (im Spiel) | Deutsch | Wofür grob |
| --- | --- | --- |
| Strength | Kraft | Belastbarkeit, Nahkampf/Athletik (v. a. Teil 6), Bergbau-Handwerk |
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
| Athletics | Strength + Dexterity | in Teil 5: weniger Ausfall bei Treffern/Andruck; Hauptnutzen ab Teil 6 | (ab Teil 6: zu Fuß) |
| Firearms | Dexterity + Reflexes | Hauptnutzen ab Teil 6 (Handwaffen) | (ab Teil 6) |

**Achtung (Claude):** Athletics und Firearms haben in Teil 5 kaum Nutzen. Wer beim Start in Kraft investiert, verschenkt Punkte. Siehe Entscheidungen.

#### Skilltree (Paket 30) – die erste Fortschrittsmechanik

- Wie in EVE muss man **lernen, wie Module funktionieren und wie Schiffe zu fliegen sind** – aber **nicht über Echtzeit**, sondern über das, was man tut.
- **Trennung zu den Fähigkeiten:** Fähigkeiten = *wie gut* (Prozent-Boni). Skilltree = *was man darf und kann* (Freischaltungen).
- **Was freigeschaltet wird (Vorschlag):**
  - **Schiffsklassen:** S von Anfang an; M und L über Knoten (z. B. „Frigate Operations“, „Cruiser Command“), Spezialschiffe (Bergbau, Industrie, Fracht) über eigene Zweige.
  - **Modulfamilien und -größen:** Grundmodule klein und in F–D von Anfang an; größere Größen und Qualitäten B–A über Knoten der jeweiligen Familie.
  - **Spezial-Ausrüstung:** Drohnen, Minenwerfer, E-War, Interdictor über eigene Knoten.
- **Woher die Punkte kommen (Vorschlag):** Jede Fähigkeit sammelt Erfahrung; Erfahrung füllt **Lernpunkte im passenden Zweig** (Kampf, Industrie, Handel, Wissenschaft, Steuerung). Wer viel kämpft, kommt im Kampfzweig schnell voran.
- **Zweige:** Flight (Steuerung/Schiffsklassen), Combat, Industry (Bergbau, Raffinerie, Fertigung), Science (Scanner, Anomalien), Commerce (Handel, Ruf), Command (Crew, Söldner).

---

### Teil B – Crews und Söldner

#### Crew-System (Paket 31)

- **Schiffe ab M** haben eine **Mindest- und Höchstcrew**. S-Schiffe fliegt der Pilot allein.
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
- **Kosten:** fester Lohn pro **Spielstunde** (Spielzeit, nicht Echtzeit) je nach Stufe und Erfahrung, plus ein **sehr kleiner Gewinnanteil** (Vorschlag: auf Verkäufe, Kopfgelder und Auftragsbelohnungen).

#### Anheuern (Paket 32)

- Vorerst **an Stationen**: neuer Service im Concourse (Monopolfirma, z. B. eine Agentur für Raumfahrtpersonal); Angebot hängt vom Stationstyp ab (Militärstation: Gunner, Forschungsstation: Science Officer, Bergbaukolonie: Mining Foreman …).
- Außerdem **über Aufträge**: gerettete Piloten, Überläufer, Belohnungen.
- **Crew-Verwaltung** im Schiffsmenü: Besatzung je Schiff, Werte, Lohn, umsetzen zwischen Schiffen im Hangar.

#### Söldner & Wingmen (Paket 33)

- **Anheuerbare Piloten und Söldner** fliegen **im Verbund** mit dem Spieler (eigenes Schiff, Befehle wie „folgen“, „angreifen“, „bergen/abbauen“).
- Sie können bei manchen Schiffen die **mitgetragenen Schiffe** fliegen (siehe Entscheidungen – Trägerschiffe sind bisher Endgame/Phase 2).
- Die **Free Captains** aus Teil 3 sind die naheliegende Quelle: „später anheuerbar als Begleitschiffe“ war schon notiert.

---

### Anmerkungen von Claude (zur Diskussion)

- **Zwei Fortschrittssysteme, die beide „durch Tun“ wachsen**, können sich doppeln (Fähigkeiten leveln *und* Skilltree-Punkte). Darum der Vorschlag oben: Fähigkeiten geben Prozente, der Skilltree schaltet frei – und die Skilltree-Punkte entstehen aus der Fähigkeits-Erfahrung. Sonst muss der Spieler zwei Zähler im Kopf haben, die dasselbe messen.
- **Gesperrte Inhalte beim Start:** Heute kann man alles fliegen, was man kaufen kann. Mit dem Skilltree muss der Einstieg sorgfältig sein, damit sich der Spielstart nicht wie ein Rückschritt anfühlt. Vorschlag: alles bis Größe 3 und Qualität D sowie alle S-Schiffe sind von Anfang an frei.
- **Pflicht-Crew für M-Schiffe** ist für den Spielstart hart: Wer sich die erste Mule kauft, kann sie ohne Crew nicht fliegen. Vorschlag: Unter der Mindestcrew fliegt das Schiff trotzdem, aber mit deutlichen Abzügen – oder eine billige, namenlose **Grundbesatzung** füllt Lücken, benannte Spezialisten verbessern das Schiff.
- **Attribute, die erst in Teil 6 zählen**, sollten in Teil 5 nicht verteilt werden müssen – sonst sind Punkte verschenkt (siehe Entscheidungen).
- **Mitgetragene Schiffe** setzen Trägerschiffe voraus. Die stehen bisher als Endgame (Phase 2) in der Roadmap – das ist ein Konflikt mit der Reihenfolge.

---

### Entscheidungen zu Teil 5

| Frage | Optionen | Vorschlag | Entscheidung |
| --- | --- | --- | --- |
| Attribute und Teil 6 | alle fünf schon jetzt verteilen · Kraft/Athletik erst mit Teil 6 · jetzt verteilen, später Umverteilung erlauben | Alle fünf jetzt, **Kraft wirkt aber schon in Teil 5** (Bergbau, Andruck-Toleranz); mit Teil 6 eine kostenlose Umverteilung | |
| Startpunkte | wenige (stark spezialisiert) · viele (breit) | Alle bei 3, 8 freie Punkte, max. 8 | |
| Wachsen die Attribute selbst? | nein, nur die Fähigkeiten · ja, über Skilltree-Meilensteine | Nur über einzelne Skilltree-Knoten (+1), sonst fest | |
| Fähigkeit vs. Skilltree | getrennte Erfahrung · Skilltree-Punkte aus Fähigkeits-Erfahrung | Skilltree-Punkte aus Fähigkeits-Erfahrung | |
| Was ist beim Start frei? | sehr wenig (EVE-artig) · alles Kleine | Alle S-Schiffe, Module bis Größe 3, Qualität F–D | |
| Unter der Mindestcrew | Schiff fliegt nicht · fliegt mit Abzügen · namenlose Grundbesatzung | Fliegt mit deutlichen Abzügen; günstige Grundbesatzung an jeder Station | |
| Crew bei Schiffsverlust | stirbt · rettet sich (Rettungskapsel) · Zufall | Rettet sich meist, kleine Chance auf Verlust – erhöht mit Erfahrung des Crewmitglieds den Einsatz | |
| Lohn | fest pro Spielstunde · + Gewinnanteil | Fest pro Spielstunde + 0,5–2 % auf Verkäufe, Kopfgelder und Aufträge | |
| Söldner und Trägerschiffe | Wingmen jetzt, Träger später · Träger vorziehen | Wingmen mit eigenem Schiff jetzt; mitgetragene Schiffe, sobald es Träger gibt | |
| Wingmen-Anzahl | fest · abhängig von Leadership | 1 zu Beginn, mit Leadership bis 3 | |
| Charakter ändern | nie · gegen Geld an Stationen (Aussehen) · Umverteilung | Aussehen jederzeit an Stationen ändern, Attribute nur bei einer Umverteilung | |
| Koop (Phase 1) | — | Pilot, Crew und Söldner gehören zum Spieler und reisen mit dem Gast-Piloten | |
