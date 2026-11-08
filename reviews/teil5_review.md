# Code-Review Teil 5 – Pilot, Crew, Wingmen (Pakete 28a–34)

Stand: alpha 0.5.34.3 (Commit `58a1c20`), Review nur lesend – geändert wird erst nach Freigabe durch Luz.

**Umfang:** alles seit Teil 4 (`v0.4.25.47..HEAD`, 50 Skriptdateien, rund 7.200 Zeilen neu). Schwerpunkt auf den Nähten,
an denen in Teil 4 die meisten Fehler lagen: Zustand bei Andocken / Ablegen / Sprung / Tod, Speichern und Laden,
Gegner- und Zonenlogik, Eingaben bei offenen Fenstern.
**Geprüfte Bereiche:** `game_state.gd` (Skills, Skilltree, Crew, Verlust, Wingmen, Sammlung), `commands.gd`,
`ship_fitting.gd` (Skill-/Crew-/Wingman-Effekte, Nutzungssperre), `ship.gd` (Wingman-Verhalten), `system_view.gd`
(Kapseln, Wingmen, Plattform), `notorious.gd`, die neuen Fenster (`pilot_window`, `loss_window`, `bar_panel`,
`crew_card`, `bond_panel`, `hangar_panel`, `hud` Wingmen-Panel), `main.gd`, Daten (`crew.gd`, `wingmen.gd`, `skilltree.gd`).
**Smoke-Test:** letzter voller Lauf mit Screenshots (0.5.34.1) grün, 719 Prüfungen; 0.5.34.2/.3 nur betroffene Gruppen.

**Gesamteindruck:** Die neuen Systeme hängen sauber am Command-Bus und speichern sich vollständig mit. Kein Absturz,
keine Spielstand-Gefahr gefunden. Die Funde liegen wieder an den Nähten – diesmal vor allem bei den Wingmen-Schiffen,
die als „Spieler-Schiffe" fliegen, aber nicht wie das eigene Schiff behandelt werden.

---

## Wichtig

### W1 – Wingmen und Plattform-Schiff greifen in No-Fire-Zonen an – die Station schießt auf sie
`ship.gd` `_protected()` (gibt für `faction == "player"` immer `false` zurück), `_wing_targeting()`,
`system_view.gd` `_check_zone_fire()`

Wingmen haben die Fraktion „player". `_protected()` ist dadurch für sie immer aus: Ein aggressiver (oder hitzköpfiger)
Wingman jagt einen Piraten bis unter die Station, eröffnet in der Zone das Feuer, wird Aggressor – und die
Stationsbatterien zerlegen ihn. Der Spieler verliert den Wingman, ohne selbst etwas falsch gemacht zu haben.
**Vorschlag:** Für Wingmen (und das Plattform-Schiff) die Zonen-Regel wie bei NPCs anwenden: kein Ziel in einer Zone,
außer es ist selbst Aggressor oder greift den Spieler / den Wingman an (Notwehr).

### W2 – Wingmen und Plattform-Schiff reparieren sich nie
`system_view.gd` `_sync_wingmen()` / `_sync_platform()`, `game_state.gd` `wing_*`

Der Schaden wird beim Andocken gespeichert und beim Ablegen wiederhergestellt – repariert wird aber nirgends. Nach ein
paar Kämpfen fliegt der Wingman für den Rest des Vertrags halb kaputt. Umgekehrt ist **nach einem Sprung** alles wieder
heil, weil die Nodes beim Systemwechsel ohne Speichern verschwinden (inkonsistent).
**Vorschlag:** Beim Andocken repariert und tankt die Station sie kostenlos (wie ihre eigene Werft); beim Systemwechsel
den Zustand vorher sichern, damit Schaden nicht durch Springen verschwindet.

### W3 – Bei offenem „SHIP LOST"-Fenster gehen Tasten durch
`main.gd` `_unhandled_input()`

Das Verlust-Fenster ist nur optisch modal. Escape öffnet das Pausenmenü dahinter, U/I/M öffnen Pilot-Fenster,
Schiffsmenü oder Karte *unter* dem Verlust-Fenster (Layer 25 < 30), Schnellladen geht auch. Man sieht davon nichts,
klickt aber womöglich ins Leere.
**Vorschlag:** Solange das Fenster offen ist, alle Spieltasten außer der Menü-Navigation abfangen.

---

## Klein

- **K1 – Bar-Angebote wachsen im Spielstand.** `GameState.bar` behält für jede je besuchte Station die Bewerber samt
  vollständiger Wingman-Schiffe. Über eine lange Karriere wird der Spielstand dadurch merklich größer.
  *Vorschlag:* abgelaufene Einträge (älter als 20 Minuten) beim Speichern weglassen – sie werden ohnehin neu gewürfelt.
- **K2 – WINGMEN-Panel bleibt im Hyperraum stehen.** `hud.gd` `_update_drones()` kehrt ohne Spieler-Node früh zurück,
  das Wingmen-Panel wird dann nicht mehr aktualisiert und zeigt alte Werte. *Vorschlag:* im Hyperraum ausblenden.
- **K3 – Crew-Anteil beim Bordmarkt.** Verkauft das Bordmarkt-Schiff (Kanayama-maru) Waren, während ein anderes Schiff
  aktiv ist, zahlt die Crew des *aktiven* Schiffs den Anteil statt der des Marktschiffs. Selten, aber falsch.
- **K4 – Toter Code.** `GameState._insurance_ship()` wird seit 31a nicht mehr gerufen. *Vorschlag:* entfernen.
- **K5 – „Lose the active ship" im Gott-Modus.** Der Debug-Befehl tut dann stillschweigend nichts.
  *Vorschlag:* Meldung „God mode is on" oder Gott-Modus für den Befehl kurz aussetzen.
- **K6 – Leere Crew-Quartiere.** `quarters_of()` legt für jede abgefragte Station einen leeren Eintrag an, der
  mitgespeichert wird. Harmlos, aber unnötig – beim Speichern leere Einträge weglassen.

---

## Geprüft und in Ordnung

Skilltree-Nutzungssperre (Rumpf, Kernmodule, offline-Module, Fertigung) · Crew-Boni, Abgabe, Lernen und Aufstieg ·
Speichern/Laden aller neuen Felder (Crew, Quartiere, Bar, Kapseln, Verlust-Angebot, Wingmen, Plattform, Sammlung) ·
Wiederanzeige eines offenen Verlust-Angebots nach dem Laden · Respawn an der letzten Station (auch Havens und fremde
Systeme) · Kapseln: Ablauf, Aufnehmen, Übergabe ins Quartier · Wingmen folgen dem Gefolgten, Warp im Verbund,
Vertragsende, Tod · Plattform: nur Hadrian-S, Pilot-Posten nur mit Perk Wingman, Rückruf für 10 % · Sammlung und
Steckbriefe (auch für ältere Kapitäne ohne Gesicht).

## Vorschlag Reihenfolge

W1, W2, W3 zusammen in einem Fix-Update (0.5.34.4), die kleinen Punkte K1–K6 gleich mit – danach ein voller Smoke-Test.
