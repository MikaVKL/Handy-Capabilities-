# Scope-Karte: wie weit trägt das Programm?

Ziel: bei Bedarf eine beliebige (unkritische) App ausprobieren und sehen, wie viel sich abnehmen lässt.

## Einstieg in eine neue App (4 Schritte)
1. **Freigeben:** `allow-app.sh NAME` (sucht den Paketnamen, warnt bei Geld/Konten/Kommunikation/System).
2. **Einschätzen ohne Modell:** `probe.sh PAKET` öffnet die App und meldet REICH, DÜNN, WEBVIEW oder LEER.
3. **Erkunden mit Claude (nur lesen):** Auftrag: "Lies docs/scope.md. Erkunde die App PAKET, ändere nichts, und lege `~/handy/apps/NAME.md`
   an: Paketname, was `ui.sh` liefert, die wichtigsten Elemente mit Position, Eigenheiten (Werbung, Dialoge), empfohlene Stufe."
4. **Aufgabe stellen** und Zeit/Aufrufe mit `bench.sh` festhalten.

## Reines Wiederholen ohne Modell
`repeat.sh DURCHLÄUFE PAUSE "tap X Y" "wait 1" …` führt eine Kette bis zu 500 Mal aus (App-Sperre, STOP-Datei und STOPP-Knopf gelten).
Für Wiederholungen ist das schneller und kostet kein Kontingent; Claude lohnt sich nur für Entscheidungen.
Nur in Apps nutzen, in denen automatisierte Eingaben erlaubt sind (Regeln der App und des Anbieters prüfen).

## Ampel (Orientierung für die Freigabe, die Entscheidung liegt bei dir)
- **Grün:** keine persönlichen Daten, alles rückgängig zu machen (Rechner, Uhr, Spiele ohne Konto, Tipps).
- **Gelb:** persönliche, aber harmlose Daten (Kalender, Notizen). Nur mit Rückfrage vor Änderungen und Löschen.
- **Rot:** Geld, Konten, Nachrichten, Passwörter, Systemeinstellungen, Installationen. Nicht freigeben.
Spiele: auf Werbung und In-App-Käufe achten; Echtzeitspiele sind wegen der Antwortzeit ungeeignet.

## Karte der getesteten Apps
| App | Textbaum | Beste Stufe bisher | Ergebnis / Notiz |
|---|---|---|---|
| Taschenrechner | vollständig | 3 (Textbaum + Kette) | Rezept: `apps/calculator.md` |
| Clock | vollständig | 3 | noch nicht mit Aufgabe getestet |
| 2048 | nur WebView | 4 (Solver, 2 Züge pro Kette) | Simulation: 2 Züge ≈ 11.500 Punkte; Lauf S2 offen |
| Termux | nur Zusatztasten | – | nicht freigeben |

`probe.sh` schreibt jede Einschätzung automatisch in `~/handy/state/probes.csv`; `bench.sh` die Läufe in `bench.csv`.
