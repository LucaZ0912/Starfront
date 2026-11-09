# Balancing – Kernmodule

Stand alpha 0.6.40.10, erzeugt aus den Spieldaten (`data/modules.gd`, `GameData.modules`). Zwischenteil 6½, Paket 75 (Bestandsaufnahme) – Teil 1: die Kernmodule (jedes Schiff hat jeden Kernslot genau einmal: Panzerung, Triebwerk, Energieverteiler, Reaktor, Tank, Sprungantrieb, Sensoren; dazu der Drohnenhangar).

## So entstehen die Werte

Jedes Modul ist **Familie + Größe + Qualität** (z. B. `pl_standard:4:B`). Eine Familie hat ein **Ankermodul** mit festen Werten bei einer **Referenzgröße**; alle anderen Größen und Qualitäten werden daraus berechnet.

### Größe

Wert = Ankerwert × (Größe / Referenzgröße) ^ Exponent. Exponent über 1 = wächst schneller als die Größe, unter 1 = langsamer, 0 = bleibt gleich.

| Wert | Exponent | Was das heißt (Größe 2 → 8, also ×4) |
| --- | --- | --- |
| Panzerung, Schub, Kondensator, Aufladung, Reaktorleistung, Treibstoff | 1,3 | ×6,1 |
| Treibstoff je Sprung | 1,0 | ×4 |
| Scanstärke | 0,6 | ×2,3 |
| Sensor-Reichweite | 0,35 | ×1,6 |
| Auflösung (Sensoren) | 0,2 | ×1,3 |
| Effizienz (Energieverteiler) | nur der Anteil über 1, mit √(Größe/Ref.) | Basic-Verteiler bleibt bei 1,00 |
| Masse | 1,2 | ×5,3 |
| Strombedarf | 1,1 | ×4,6 |
| Preis | 1,6 | ×9,2 |
| **gleich bei jeder Größe:** Resistenzen der Panzerung, Wendigkeit des Triebwerks, Aufladezeit des Sprungantriebs | 0 | ×1 |
| Sprungantrieb-Stufe | Größe 1–2 → Mk I, 3–4 → Mk II, 5–6 → Mk III | Sprungzeit ×1 / ×0,85 / ×0,7, Fehlsprünge an alten Toren ×1 / ×0,6 / ×0,3 |
| Drohnenplätze | Größe × 3 × Qualitätsfaktor | – |

### Qualität

Die Qualität multipliziert vier Dinge: **Leistung** (alle Werte aus der Größen-Tabelle oben mit Exponent > 0, außer Energie), **Masse**, **Strombedarf** und **Preis**.

| Qualität | Leistung | Masse | Strombedarf | Preis | Drohnenplätze |
| --- | --- | --- | --- | --- | --- |
| F | ×0,80 | ×1,25 | ×0,94 | ×0,55 | ×0,60 |
| E | ×0,88 | ×1,10 | ×0,96 | ×0,70 | ×0,75 |
| D | ×0,95 | ×0,90 | ×0,98 | ×0,85 | ×0,90 |
| C | ×1,00 | ×1,00 | ×1,00 | ×1,00 | ×1,00 |
| B | ×1,08 | ×1,08 | ×1,04 | ×1,40 | ×1,25 |
| A | ×1,16 | ×1,08 | ×1,08 | ×2,00 | ×1,50 |

**Nicht** von der Qualität verändert: Resistenzen, Wendigkeit, Aufladezeit des Sprungantriebs, Sprungantrieb-Stufe. D ist die leichteste Qualität, F die schwerste; B ist so schwer wie A.

### Auffälligkeiten (für die Abstimmung)

1. **Treibstoff je Sprung steigt mit der Qualität** (A verbraucht 16 % mehr als C) – er läuft wie ein Leistungswert mit; vermutlich ungewollt.
2. **Resistenzen** der Panzerung sind bei jeder Größe und Qualität gleich (Standard 10 % kinetisch, Reflective 35 % optisch, Ablative 35 % explosiv).
3. **Wendigkeit** des Triebwerks ist bei jeder Größe und Qualität gleich – und im Schiff hängt sie nur am Triebwerk, am Rumpf (`turn_mult`) und an der Stromversorgung, **nicht an Masse oder Schub**. Ein A-Triebwerk macht das Schiff schneller (Schub), aber nicht wendiger. Geschwindigkeit = Schub ÷ Masse; Beschleunigung und Warp-Tempo folgen der Geschwindigkeit.
4. **Sensor-Reichweite und Auflösung** wachsen mit der Größe kaum (Größe 8 hat nur 1,6× die Reichweite von Größe 2).
5. Der **Basic-Energieverteiler** hat bei jeder Größe und Qualität Effizienz 1,00 – Qualität verbessert dort nur Kondensator und Aufladung.
6. **Preis** wächst mit Exponent 1,6, die meisten Leistungswerte mit 1,3 – große Module sind pro Leistung teurer.
7. Ankermodule mit Strombedarf 0 (Standard-Panzerung, Ablative, Reaktoren, Tanks, Verteiler) bleiben bei 0, egal wie groß.


## Panzerung (hull)

### Standard Plating (`pl_standard`) – Größen 1–10, Referenzgröße 2

**Nach Größe** (Qualität C):

| Größe | Panzerung | Resistenz | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- |
| 1 | 122 | kin 10 % | 87 | 0.00 | 490 |
| 2 | 300 | kin 10 % | 200 | 0.00 | 1500 |
| 3 | 508 | kin 10 % | 325 | 0.00 | 2870 |
| 4 | 739 | kin 10 % | 459 | 0.00 | 4550 |
| 5 | 987 | kin 10 % | 601 | 0.00 | 6500 |
| 6 | 1251 | kin 10 % | 747 | 0.00 | 8700 |
| 7 | 1529 | kin 10 % | 899 | 0.00 | 11130 |
| 8 | 1819 | kin 10 % | 1056 | 0.00 | 13780 |
| 9 | 2120 | kin 10 % | 1216 | 0.00 | 16640 |
| 10 | 2431 | kin 10 % | 1380 | 0.00 | 19700 |

**Nach Qualität** (Größe 2):

| Qualität | Panzerung | Resistenz | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- |
| F | 240 | kin 10 % | 250 | 0.00 | 830 |
| E | 264 | kin 10 % | 220 | 0.00 | 1050 |
| D | 285 | kin 10 % | 180 | 0.00 | 1280 |
| C | 300 | kin 10 % | 200 | 0.00 | 1500 |
| B | 324 | kin 10 % | 216 | 0.00 | 2100 |
| A | 348 | kin 10 % | 216 | 0.00 | 3000 |

### Reflective Plating (`pl_reflective`) – Größen 1–10, Referenzgröße 2

**Nach Größe** (Qualität C):

| Größe | Panzerung | Resistenz | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- |
| 1 | 106 | opt 35 % | 78 | 0.90 | 1480 |
| 2 | 260 | opt 35 % | 180 | 2.00 | 4500 |
| 3 | 440 | opt 35 % | 293 | 3.10 | 8610 |
| 4 | 640 | opt 35 % | 414 | 4.30 | 13640 |
| 5 | 856 | opt 35 % | 541 | 5.50 | 19490 |
| 6 | 1085 | opt 35 % | 673 | 6.70 | 26100 |
| 7 | 1325 | opt 35 % | 809 | 7.90 | 33400 |
| 8 | 1576 | opt 35 % | 950 | 9.20 | 41350 |
| 9 | 1837 | opt 35 % | 1094 | 11 | 49930 |
| 10 | 2107 | opt 35 % | 1242 | 12 | 59100 |

**Nach Qualität** (Größe 2):

| Qualität | Panzerung | Resistenz | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- |
| F | 208 | opt 35 % | 225 | 1.90 | 2480 |
| E | 229 | opt 35 % | 198 | 1.90 | 3150 |
| D | 247 | opt 35 % | 162 | 2.00 | 3830 |
| C | 260 | opt 35 % | 180 | 2.00 | 4500 |
| B | 281 | opt 35 % | 194 | 2.10 | 6300 |
| A | 302 | opt 35 % | 194 | 2.20 | 9000 |

### Ablative Plating (`pl_ablative`) – Größen 1–10, Referenzgröße 2

**Nach Größe** (Qualität C):

| Größe | Panzerung | Resistenz | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- |
| 1 | 114 | exp 35 % | 100 | 0.00 | 1480 |
| 2 | 280 | exp 35 % | 230 | 0.00 | 4500 |
| 3 | 474 | exp 35 % | 374 | 0.00 | 8610 |
| 4 | 689 | exp 35 % | 528 | 0.00 | 13640 |
| 5 | 921 | exp 35 % | 691 | 0.00 | 19490 |
| 6 | 1168 | exp 35 % | 860 | 0.00 | 26100 |
| 7 | 1427 | exp 35 % | 1034 | 0.00 | 33400 |
| 8 | 1698 | exp 35 % | 1214 | 0.00 | 41350 |
| 9 | 1978 | exp 35 % | 1398 | 0.00 | 49930 |
| 10 | 2269 | exp 35 % | 1587 | 0.00 | 59100 |

**Nach Qualität** (Größe 2):

| Qualität | Panzerung | Resistenz | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- |
| F | 224 | exp 35 % | 288 | 0.00 | 2480 |
| E | 246 | exp 35 % | 253 | 0.00 | 3150 |
| D | 266 | exp 35 % | 207 | 0.00 | 3830 |
| C | 280 | exp 35 % | 230 | 0.00 | 4500 |
| B | 302 | exp 35 % | 248 | 0.00 | 6300 |
| A | 325 | exp 35 % | 248 | 0.00 | 9000 |

## Triebwerk (engine)

### Chemical Thruster (`eng_chemical`) – Größen 1–8, Referenzgröße 2

**Nach Größe** (Qualität C):

| Größe | Schub (kN) | Wendigkeit (rad/s) | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- |
| 1 | 171 | 3.50 | 52 | 1.40 | 400 |
| 2 | 420 | 3.50 | 120 | 3.00 | 1200 |
| 3 | 711 | 3.50 | 195 | 4.70 | 2300 |
| 4 | 1034 | 3.50 | 276 | 6.40 | 3640 |
| 5 | 1382 | 3.50 | 360 | 8.20 | 5200 |
| 6 | 1752 | 3.50 | 448 | 10 | 6960 |
| 7 | 2141 | 3.50 | 540 | 12 | 8910 |
| 8 | 2546 | 3.50 | 633 | 14 | 11030 |

**Nach Qualität** (Größe 2):

| Qualität | Schub (kN) | Wendigkeit (rad/s) | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- |
| F | 336 | 3.50 | 150 | 2.80 | 660 |
| E | 370 | 3.50 | 132 | 2.90 | 840 |
| D | 399 | 3.50 | 108 | 2.90 | 1020 |
| C | 420 | 3.50 | 120 | 3.00 | 1200 |
| B | 454 | 3.50 | 130 | 3.10 | 1680 |
| A | 487 | 3.50 | 130 | 3.20 | 2400 |

### Ion Drive (`eng_ion`) – Größen 1–10, Referenzgröße 2

**Nach Größe** (Qualität C):

| Größe | Schub (kN) | Wendigkeit (rad/s) | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- |
| 1 | 227 | 4.00 | 39 | 3.70 | 1650 |
| 2 | 560 | 4.00 | 90 | 8.00 | 5000 |
| 3 | 949 | 4.00 | 146 | 13 | 9570 |
| 4 | 1379 | 4.00 | 207 | 17 | 15160 |
| 5 | 1843 | 4.00 | 270 | 22 | 21660 |
| 6 | 2336 | 4.00 | 336 | 27 | 29000 |
| 7 | 2854 | 4.00 | 405 | 32 | 37110 |
| 8 | 3395 | 4.00 | 475 | 37 | 45950 |
| 9 | 3957 | 4.00 | 547 | 42 | 55480 |
| 10 | 4538 | 4.00 | 621 | 47 | 65660 |

**Nach Qualität** (Größe 2):

| Qualität | Schub (kN) | Wendigkeit (rad/s) | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- |
| F | 448 | 4.00 | 113 | 7.50 | 2750 |
| E | 493 | 4.00 | 99 | 7.70 | 3500 |
| D | 532 | 4.00 | 81 | 7.80 | 4250 |
| C | 560 | 4.00 | 90 | 8.00 | 5000 |
| B | 605 | 4.00 | 97 | 8.30 | 7000 |
| A | 650 | 4.00 | 97 | 8.60 | 10000 |

### Plasma Drive (`eng_plasma`) – Größen 3–10, Referenzgröße 5

**Nach Größe** (Qualität C):

| Größe | Schub (kN) | Wendigkeit (rad/s) | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- |
| 3 | 721 | 2.60 | 173 | 9.10 | 7950 |
| 4 | 1047 | 2.60 | 245 | 13 | 12600 |
| 5 | 1400 | 2.60 | 320 | 16 | 18000 |
| 6 | 1774 | 2.60 | 398 | 20 | 24100 |
| 7 | 2168 | 2.60 | 479 | 23 | 30840 |
| 8 | 2579 | 2.60 | 562 | 27 | 38180 |
| 9 | 3006 | 2.60 | 648 | 31 | 46100 |
| 10 | 3447 | 2.60 | 735 | 34 | 54570 |

**Nach Qualität** (Größe 5):

| Qualität | Schub (kN) | Wendigkeit (rad/s) | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- |
| F | 1120 | 2.60 | 400 | 15 | 9900 |
| E | 1232 | 2.60 | 352 | 15 | 12600 |
| D | 1330 | 2.60 | 288 | 16 | 15300 |
| C | 1400 | 2.60 | 320 | 16 | 18000 |
| B | 1512 | 2.60 | 346 | 17 | 25200 |
| A | 1624 | 2.60 | 346 | 17 | 36000 |

## Energieverteiler (distributor)

### Power Distributor (`dist_basic`) – Größen 1–8, Referenzgröße 2

**Nach Größe** (Qualität C):

| Größe | Kondensator | Aufladung /s | Effizienz | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 41 | 3.66 | 1.00 | 22 | 0.00 | 330 |
| 2 | 100 | 9.00 | 1.00 | 50 | 0.00 | 1000 |
| 3 | 169 | 15 | 1.00 | 81 | 0.00 | 1910 |
| 4 | 246 | 22 | 1.00 | 115 | 0.00 | 3030 |
| 5 | 329 | 30 | 1.00 | 150 | 0.00 | 4330 |
| 6 | 417 | 38 | 1.00 | 187 | 0.00 | 5800 |
| 7 | 510 | 46 | 1.00 | 225 | 0.00 | 7420 |
| 8 | 606 | 55 | 1.00 | 264 | 0.00 | 9190 |

**Nach Qualität** (Größe 2):

| Qualität | Kondensator | Aufladung /s | Effizienz | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- | --- |
| F | 80 | 7.20 | 1.00 | 63 | 0.00 | 550 |
| E | 88 | 7.92 | 1.00 | 55 | 0.00 | 700 |
| D | 95 | 8.55 | 1.00 | 45 | 0.00 | 850 |
| C | 100 | 9.00 | 1.00 | 50 | 0.00 | 1000 |
| B | 108 | 9.72 | 1.00 | 54 | 0.00 | 1400 |
| A | 116 | 10 | 1.00 | 54 | 0.00 | 2000 |

### Precision Power Distributor (`dist_precision`) – Größen 1–10, Referenzgröße 2

**Nach Größe** (Qualität C):

| Größe | Kondensator | Aufladung /s | Effizienz | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 61 | 5.69 | 1.06 | 20 | 0.00 | 1980 |
| 2 | 150 | 14 | 1.08 | 45 | 0.00 | 6000 |
| 3 | 254 | 24 | 1.10 | 73 | 0.00 | 11480 |
| 4 | 369 | 34 | 1.11 | 103 | 0.00 | 18190 |
| 5 | 494 | 46 | 1.13 | 135 | 0.00 | 25990 |
| 6 | 626 | 58 | 1.14 | 168 | 0.00 | 34800 |
| 7 | 765 | 71 | 1.15 | 202 | 0.00 | 44530 |
| 8 | 909 | 85 | 1.16 | 238 | 0.00 | 55140 |
| 9 | 1060 | 99 | 1.17 | 274 | 0.00 | 66570 |
| 10 | 1215 | 113 | 1.18 | 310 | 0.00 | 78800 |

**Nach Qualität** (Größe 2):

| Qualität | Kondensator | Aufladung /s | Effizienz | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- | --- |
| F | 120 | 11 | 1.06 | 56 | 0.00 | 3300 |
| E | 132 | 12 | 1.07 | 50 | 0.00 | 4200 |
| D | 143 | 13 | 1.08 | 41 | 0.00 | 5100 |
| C | 150 | 14 | 1.08 | 45 | 0.00 | 6000 |
| B | 162 | 15 | 1.09 | 49 | 0.00 | 8400 |
| A | 174 | 16 | 1.09 | 49 | 0.00 | 12000 |

## Reaktor (reactor)

### Fission Reactor (`rea_fission`) – Größen 1–8, Referenzgröße 2

**Nach Größe** (Qualität C):

| Größe | Leistung (MW) | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- |
| 1 | 17 | 109 | 0.00 | 660 |
| 2 | 42 | 250 | 0.00 | 2000 |
| 3 | 71 | 407 | 0.00 | 3830 |
| 4 | 103 | 574 | 0.00 | 6060 |
| 5 | 138 | 751 | 0.00 | 8660 |
| 6 | 175 | 934 | 0.00 | 11600 |
| 7 | 214 | 1124 | 0.00 | 14840 |
| 8 | 255 | 1320 | 0.00 | 18380 |

**Nach Qualität** (Größe 2):

| Qualität | Leistung (MW) | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- |
| F | 34 | 313 | 0.00 | 1100 |
| E | 37 | 275 | 0.00 | 1400 |
| D | 40 | 225 | 0.00 | 1700 |
| C | 42 | 250 | 0.00 | 2000 |
| B | 45 | 270 | 0.00 | 2800 |
| A | 49 | 270 | 0.00 | 4000 |

### Fusion Reactor (`rea_fusion`) – Größen 1–10, Referenzgröße 2

**Nach Größe** (Qualität C):

| Größe | Leistung (MW) | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- |
| 1 | 24 | 87 | 0.00 | 2970 |
| 2 | 60 | 200 | 0.00 | 9000 |
| 3 | 102 | 325 | 0.00 | 17220 |
| 4 | 148 | 459 | 0.00 | 27280 |
| 5 | 197 | 601 | 0.00 | 38990 |
| 6 | 250 | 747 | 0.00 | 52200 |
| 7 | 306 | 899 | 0.00 | 66800 |
| 8 | 364 | 1056 | 0.00 | 82710 |
| 9 | 424 | 1216 | 0.00 | 99860 |
| 10 | 486 | 1380 | 0.00 | 118190 |

**Nach Qualität** (Größe 2):

| Qualität | Leistung (MW) | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- |
| F | 48 | 250 | 0.00 | 4950 |
| E | 53 | 220 | 0.00 | 6300 |
| D | 57 | 180 | 0.00 | 7650 |
| C | 60 | 200 | 0.00 | 9000 |
| B | 65 | 216 | 0.00 | 12600 |
| A | 70 | 216 | 0.00 | 18000 |

## Treibstofftank (tank)

### Fuel Tank (`tank`) – Größen 1–10, Referenzgröße 2

**Nach Größe** (Qualität C):

| Größe | Treibstoff | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- |
| 1 | 41 | 26 | 0.00 | 260 |
| 2 | 100 | 60 | 0.00 | 800 |
| 3 | 169 | 98 | 0.00 | 1530 |
| 4 | 246 | 138 | 0.00 | 2430 |
| 5 | 329 | 180 | 0.00 | 3470 |
| 6 | 417 | 224 | 0.00 | 4640 |
| 7 | 510 | 270 | 0.00 | 5940 |
| 8 | 606 | 317 | 0.00 | 7350 |
| 9 | 707 | 365 | 0.00 | 8880 |
| 10 | 810 | 414 | 0.00 | 10510 |

**Nach Qualität** (Größe 2):

| Qualität | Treibstoff | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- |
| F | 80 | 75 | 0.00 | 440 |
| E | 88 | 66 | 0.00 | 560 |
| D | 95 | 54 | 0.00 | 680 |
| C | 100 | 60 | 0.00 | 800 |
| B | 108 | 65 | 0.00 | 1120 |
| A | 116 | 65 | 0.00 | 1600 |

## Sprungantrieb (hyperdrive)

### Jump Drive (`hyperdrive`) – Größen 1–6, Referenzgröße 2

**Nach Größe** (Qualität C):

| Größe | Stufe (Mk) | Treibstoff je Sprung | Aufladen (s) | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 1 | 9.00 | 3.00 | 35 | 2.80 | 820 |
| 2 | 1 | 18 | 3.00 | 80 | 6.00 | 2500 |
| 3 | 2 | 27 | 3.00 | 130 | 9.40 | 4780 |
| 4 | 2 | 36 | 3.00 | 184 | 13 | 7580 |
| 5 | 3 | 45 | 3.00 | 240 | 16 | 10830 |
| 6 | 3 | 54 | 3.00 | 299 | 20 | 14500 |

**Nach Qualität** (Größe 2):

| Qualität | Stufe (Mk) | Treibstoff je Sprung | Aufladen (s) | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- | --- |
| F | 1 | 14 | 3.00 | 100 | 5.60 | 1380 |
| E | 1 | 16 | 3.00 | 88 | 5.80 | 1750 |
| D | 1 | 17 | 3.00 | 72 | 5.90 | 2130 |
| C | 1 | 18 | 3.00 | 80 | 6.00 | 2500 |
| B | 1 | 19 | 3.00 | 86 | 6.20 | 3500 |
| A | 1 | 21 | 3.00 | 86 | 6.50 | 5000 |

## Sensoren (sensors)

### Basic Sensor Suite (`sen_basic`) – Größen 1–6, Referenzgröße 2

**Nach Größe** (Qualität C):

| Größe | Reichweite | Auflösung | Scanstärke | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 812 | 0.87 | 0.66 | 17 | 1.40 | 330 |
| 2 | 1035 | 1.00 | 1.00 | 40 | 3.00 | 1000 |
| 3 | 1193 | 1.08 | 1.28 | 65 | 4.70 | 1910 |
| 4 | 1319 | 1.15 | 1.52 | 92 | 6.40 | 3030 |
| 5 | 1426 | 1.20 | 1.73 | 120 | 8.20 | 4330 |
| 6 | 1520 | 1.25 | 1.93 | 149 | 10 | 5800 |

**Nach Qualität** (Größe 2):

| Qualität | Reichweite | Auflösung | Scanstärke | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- | --- |
| F | 828 | 0.80 | 0.80 | 50 | 2.80 | 550 |
| E | 911 | 0.88 | 0.88 | 44 | 2.90 | 700 |
| D | 983 | 0.95 | 0.95 | 36 | 2.90 | 850 |
| C | 1035 | 1.00 | 1.00 | 40 | 3.00 | 1000 |
| B | 1118 | 1.08 | 1.08 | 43 | 3.10 | 1400 |
| A | 1201 | 1.16 | 1.16 | 43 | 3.20 | 2000 |

### Radar Array (`sen_radar`) – Größen 1–8, Referenzgröße 2

**Nach Größe** (Qualität C):

| Größe | Reichweite | Auflösung | Scanstärke | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 1128 | 1.13 | 0.79 | 22 | 2.80 | 2310 |
| 2 | 1438 | 1.30 | 1.20 | 50 | 6.00 | 7000 |
| 3 | 1657 | 1.41 | 1.53 | 81 | 9.40 | 13390 |
| 4 | 1832 | 1.49 | 1.82 | 115 | 13 | 21220 |
| 5 | 1981 | 1.56 | 2.08 | 150 | 16 | 30330 |
| 6 | 2111 | 1.62 | 2.32 | 187 | 20 | 40600 |
| 7 | 2229 | 1.67 | 2.54 | 225 | 24 | 51950 |
| 8 | 2336 | 1.72 | 2.76 | 264 | 28 | 64330 |

**Nach Qualität** (Größe 2):

| Qualität | Reichweite | Auflösung | Scanstärke | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- | --- |
| F | 1150 | 1.04 | 0.96 | 63 | 5.60 | 3850 |
| E | 1265 | 1.14 | 1.06 | 55 | 5.80 | 4900 |
| D | 1366 | 1.23 | 1.14 | 45 | 5.90 | 5950 |
| C | 1438 | 1.30 | 1.20 | 50 | 6.00 | 7000 |
| B | 1552 | 1.40 | 1.30 | 54 | 6.20 | 9800 |
| A | 1667 | 1.51 | 1.39 | 54 | 6.50 | 14000 |

### Gravimetric Array (`sen_grav`) – Größen 2–8, Referenzgröße 5

**Nach Größe** (Qualität C):

| Größe | Reichweite | Auflösung | Scanstärke | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- | --- |
| 2 | 1419 | 0.92 | 1.15 | 50 | 3.60 | 4620 |
| 3 | 1635 | 0.99 | 1.47 | 81 | 5.70 | 8830 |
| 4 | 1808 | 1.05 | 1.75 | 115 | 7.80 | 14000 |
| 5 | 1955 | 1.10 | 2.00 | 150 | 10 | 20000 |
| 6 | 2084 | 1.14 | 2.23 | 187 | 12 | 26770 |
| 7 | 2199 | 1.18 | 2.45 | 225 | 15 | 34260 |
| 8 | 2305 | 1.21 | 2.65 | 264 | 17 | 42430 |

**Nach Qualität** (Größe 5):

| Qualität | Reichweite | Auflösung | Scanstärke | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- | --- |
| F | 1564 | 0.88 | 1.60 | 188 | 9.40 | 11000 |
| E | 1720 | 0.97 | 1.76 | 165 | 9.60 | 14000 |
| D | 1857 | 1.04 | 1.90 | 135 | 9.80 | 17000 |
| C | 1955 | 1.10 | 2.00 | 150 | 10 | 20000 |
| B | 2111 | 1.19 | 2.16 | 162 | 10 | 28000 |
| A | 2268 | 1.28 | 2.32 | 162 | 11 | 40000 |

### Tactical Sensor System (`sen_tactical`) – Größen 2–8, Referenzgröße 5

**Nach Größe** (Qualität C):

| Größe | Reichweite | Auflösung | Scanstärke | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- | --- |
| 2 | 1251 | 1.50 | 0.58 | 47 | 4.40 | 5080 |
| 3 | 1442 | 1.63 | 0.74 | 76 | 6.80 | 9720 |
| 4 | 1595 | 1.72 | 0.87 | 107 | 9.40 | 15390 |
| 5 | 1725 | 1.80 | 1.00 | 140 | 12 | 22000 |
| 6 | 1839 | 1.87 | 1.12 | 174 | 15 | 29450 |
| 7 | 1940 | 1.93 | 1.22 | 210 | 17 | 37690 |
| 8 | 2033 | 1.98 | 1.33 | 246 | 20 | 46670 |

**Nach Qualität** (Größe 5):

| Qualität | Reichweite | Auflösung | Scanstärke | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- | --- | --- |
| F | 1380 | 1.44 | 0.80 | 175 | 11 | 12100 |
| E | 1518 | 1.58 | 0.88 | 154 | 12 | 15400 |
| D | 1639 | 1.71 | 0.95 | 126 | 12 | 18700 |
| C | 1725 | 1.80 | 1.00 | 140 | 12 | 22000 |
| B | 1863 | 1.94 | 1.08 | 151 | 13 | 30800 |
| A | 2001 | 2.09 | 1.16 | 151 | 13 | 44000 |

## Drohnenhangar (hangar)

### Drone Hangar (`hangar`) – Größen 1–9, Referenzgröße 1

**Nach Größe** (Qualität C):

| Größe | Drohnenplätze | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- |
| 1 | 3 | 60 | 0.50 | 2500 |
| 2 | 6 | 138 | 1.10 | 7580 |
| 3 | 9 | 224 | 1.70 | 14500 |
| 4 | 12 | 317 | 2.30 | 22970 |
| 5 | 15 | 414 | 2.90 | 32830 |
| 6 | 18 | 515 | 3.60 | 43950 |
| 7 | 21 | 620 | 4.30 | 56250 |
| 8 | 24 | 728 | 4.90 | 69640 |
| 9 | 27 | 838 | 5.60 | 84090 |

**Nach Qualität** (Größe 1):

| Qualität | Drohnenplätze | Masse | Strombedarf (MW) | Preis (cr) |
| --- | --- | --- | --- | --- |
| F | 2 | 75 | 0.50 | 1380 |
| E | 2 | 66 | 0.50 | 1750 |
| D | 3 | 54 | 0.50 | 2130 |
| C | 3 | 60 | 0.50 | 2500 |
| B | 4 | 65 | 0.50 | 3500 |
| A | 5 | 65 | 0.50 | 5000 |

