# Sternenfront – Leitlinien

Verbindliche Grundsätze für jede Arbeit am Spiel. **Zu Beginn jedes Pakets lesen**, jedes Ergebnis (Screenshot,
Oberfläche, Mechanik) **vor dem Zeigen dagegen prüfen**. Wird ein Grundsatz neu festgelegt oder geändert, kommt er
hierher – mit Datum. Die Roadmap sagt, *was* gebaut wird; diese Datei sagt, *wie*.

Stand: Entwurf vom 11. Nov 2026 (Claude), zur Korrektur durch Luz.

---

## 1. Arbeitsweise

1. **Erst Konzept, dann Bau.** Neue Oberflächen, Orte und Systeme werden zuerst beschrieben und als **Mockup oder
   Probe-Render** gezeigt. Gebaut wird erst nach Luz' Okay.
2. **Nach jedem sichtbaren Update anhalten.** Nicht mehrere Updates hintereinander stapeln; Luz schaut drauf, dann
   geht es weiter.
3. **Ein Grundsatz gilt für alles, worauf er passt.** Wird etwas an einem Asset korrigiert (z. B. „zu 21.
   Jahrhundert“), werden **alle** Assets derselben Art und Welt mitgeprüft, nicht nur das eine.
4. **Bestehende Muster nutzen.** Neue Systeme folgen dem, was das Spiel schon hat (siehe 4.), statt der schnellsten
   Lösung.
5. **Jedes Paket bringt Debug-Funktionen mit** (Debug-Menü F12): Zustände setzen, Inhalte spawnen, Werte einsehen.
   **Ein Paket ist erst fertig, wenn seine Debug-Funktionen da sind.**
6. **Tests:** jedes Paket bekommt eigene Prüfungen im Smoke-Test; bei großen Schritten läuft der volle Test, und
   **committet wird erst nach grünem Test**.
7. **Pro Update:** Changelog, Roadmap (Haken, „Aktueller Stand“, Versionszeile), README, `config/version`; Commit
   „alpha <Version>: …“, Tag `v<Version>`, Push.
8. **Screenshots** schickt Claude Luz direkt (Luz liest oft am Handy) – genug, um ein Update beurteilen zu können.
9. **Lange Sitzungen vermeiden.** Pro Paket (oder bei langen Paketen pro Abschnitt) eine frische Sitzung, damit nichts
   aus dem Blick gerät; diese Datei und die Roadmap tragen das Wissen weiter.
10. `Roadmap_Entwurf.md` gehört Luz – nie ändern oder committen.

## 2. Spiel und Sprache

- Einzelspieler zuerst, alles **koop-tauglich** gebaut (Zustand in Daten, Änderungen über `Commands.execute`, die
  Oberfläche zeigt nur an).
- **Spieltexte englisch**, Sternsystem-Namen deutsch; Antworten an Luz auf Deutsch.
- Alte Spielstände müssen nicht ladbar bleiben (Alpha); nie eine Mechanik deswegen einschränken.

## 3. Aussehen

### 3.1 Grundton
- **Sci-Fi überall.** Nichts sieht nach 21. Jahrhundert aus: keine Gummireifen, **keine Vorstadthäuser mit
  Satteldach und Holzverkleidung**, keine Dinge, die so heute in einer Kleinstadt stehen. Technik schwebt, leuchtet,
  ist modular, gepanzert, abgedichtet.
- **Cyberpunk/Neon als Grundton** auf Decks und in Städten: Neonschilder, Lichtleisten, Hologramm-Werbung,
  Lichtkegel; Rimlight an den Figuren.
- **Pixel-Art in Draufsicht** (am Boden leicht schräg), schwarze Umrisse.

### 3.2 Maßstab
- **Ein Maßstab für alles am Boden:** ~15 Art-Pixel je Meter, eine Figur ~27 Art-Pixel (1,8 m), ein Geschoss ~2,6 m,
  Türen ~2 m hoch, Fahrzeuge und Gebäude in echter Größe. Was zu groß fürs Bild ist, wird **angeschnitten oder aus
  der Ferne** gezeigt (z. B. der Tagebau vom Rand).
- **Größenverhältnisse auch im All und im Anflug:** große Schiffe sind riesig (Länge aus den Rumpfdaten), die
  Landedrohne (~10 m) daneben winzig.

### 3.3 Stile der Mächte (Städte, Siedlungen, Decks)
- **Independent:** Cyberpunk – Neon, enge Fassaden, Kabel, Werbung.
- **Assembly:** helle Steine und Glas, Kuppeln, Terrassen, Dachgärten.
- **Covenant:** dunkler rotbrauner Stein, Spitztürme, goldene Fenster unter Spitzbögen, rote Banner.
- **Directorate:** weiße Türme im Raster, Sechseck-Kronen, Solardächer, grüne Lichtbänder.
- Siedlungen im Stil ihrer Macht, aber schlichter und rauer; Boden, Begrenzung und Umwelt nach Welttyp.

### 3.4 Welt
- Orte sind an die **Geografie** gebunden (Städte und Siedlungen auf Land, Piers und Plattformen auf dem Meer).
- **Tag und Nacht** laufen live; Orte merken sich ihre Tageszeit.
- In gebauten Stadtbereichen **Wachen, aber kein Waffenfeuer**.

## 4. Muster, die neue Systeme nutzen

- **Ausrüstung wie beim Schiff:** Rumpf/Anzug bestimmt die Slots; Module/Teile mit **Qualität F–A**; Darstellung als
  **Slot-Kacheln** mit Bild wie im Schiffsmenü – keine Button-Listen.
- **Schadensarten:** optisch (stark gegen Schilde), kinetisch (stark gegen Rüstung), explosiv (stark gegen Struktur
  bzw. den Körper); Schichten Schild → Rüstung → Struktur/Gesundheit.
- **Orte als eigene Instanzen:** Wichtige Einrichtungen (Bar, Klinik, Hangar …) sind **eigene Ebenen über den
  Aufzug** mit eigenem Aufbau und Personal, nicht bloß ein Raum in der Ladenreihe.
- **Läden** sind begehbar; ihre Fenster öffnen das Dienst-Fenster wie an der Station.
- **Sortimente folgen der Wirtschaft** (Qualität nach Stufe, Wohlstand, Hightech; Militärgüter in Militärsystemen).

## 5. Offene Punkte aus diesem Durchgang

- [x] ~~Debug-Funktionen für die Pakete 49–51 fehlen noch (Landen, Städte, Siedlungen, Ausrüstung, Umwelt, Klinik).~~ Erledigt in 0.7.51.5 (F12 → Ground).
- Gebäude am Boden auf Sci-Fi umbauen (alle Bauformen, im Maßstab).
- Klinik als eigene Ebene über den Aufzug (Rezeption, Zimmer, Aufwachzimmer, Personal).
- Gear-Seite nach dem Muster des Schiffsmenüs (Kacheln, Anzug-Mockup) – erst Mockup.
