# Wie viel muss einer App beigebracht werden?

Ziel: ein Programm, das beliebige (unkritische) Apps bedient. 2048 dient zum Üben. Für jede neue App messen wir,
welche Stufe sich lohnt, statt alles zu bauen.

## Stufen
| Stufe | Was beigebracht wird | Aufwand je App | übertragbar? |
|---|---|---|---|
| 0 | nichts: Screenshot, Tippen, Wischen | keiner | ja |
| 1 | Steckbrief `apps/NAME.md` (Layout, Eigenheiten, Werbung, Paketname) | gering; Claude kann ihn nach einer Erkundung selbst schreiben | pro App |
| 2 | Ketten mit Wirkungsprüfung (`batch.sh`, `swipe-check`, `tap-check`) | gering | generisch |
| 3 | Textbaum statt Bild (`ui.sh`, `ui.sh tap TEXT`) | keiner, falls die App einen Baum liefert | generisch, nicht bei Spielen |
| 4 | Werkzeug für die Fachlogik (bei 2048: `solve2048.py`) | hoch | pro App oder App-Art |
| 5 | lokales Lesen ohne Modell (Pixelfarben, OCR) | hoch | teils generisch |

## Messschema je App (immer gleiche Aufgabe, Haiku, `/effort low`, `/clear` vor jedem Lauf)
1. **Wahrnehmung:** `ui.sh` aufrufen. Liefert es Elemente (Text, Positionen), ist Stufe 3 möglich; meldet es `LEER`, sind Screenshots nötig.
2. **Stufe 0:** Aufgabe ohne Steckbrief. Notieren: Dauer, Aufrufe, Erfolg.
3. **Stufe 1:** Claude schreibt nach der Erkundung einen Steckbrief; Aufgabe wiederholen.
4. **Stufe 2/3:** mit Ketten bzw. Textbaum wiederholen.
5. **Stufe 4/5** nur, wenn die Zeit pro Aufgabe für den Zweck noch zu hoch ist.
Jeder Lauf: `bench.sh LABEL ERGEBNIS "Notiz"`, Auswertung mit `bench.sh --show`.
Kennzahlen: Dauer, Aufrufe, Sekunden pro Aufruf, Qualität (bei 2048 Punkte; bei anderen Apps: Aufgabe erfüllt ja/nein), Aufwand zum Anlernen (Minuten).

## Wahrnehmung (ui.sh) bei bisher getesteten Apps
| App | Textbaum | Folge |
|---|---|---|
| Taschenrechner | vollständig (Tasten, Ergebnisvorschau) | Stufe 3 möglich, keine Bilder nötig |
| Clock | vollständig (Alarme, Schalter, Reiter) | Stufe 3 möglich |
| 2048 | nur ein WebView, Inhalt nicht sichtbar | Screenshots nötig |
| Termux | nur die Zusatztasten, Terminaltext fehlt | Screenshots nötig |
Regel: Zuerst `ui.sh`. Liefert es Elemente, den Textbaum nutzen; meldet es `LEER` oder nur einen WebView, auf Screenshots zurückfallen.

## Bisherige Erkenntnisse (2048)
- Haiku mit `/effort low` war pro Aufruf etwa 30 % schneller als Sonnet mit medium.
- Nach jedem Zug ein Screenshot: etwa 10 s pro Zug. 4er-Ketten blind: etwa 6 s pro Zug, aber festgefahrene Züge ohne Prüfung.
- Simulation (ganze Spiele): 1 Zug blind ≈ 14.900 Punkte, 2 ≈ 11.500, 3 ≈ 5.500, 4 ≈ 2.800. Blinde Ketten kosten viel Qualität.
- Werbung (Ladekreis, Vollbild) kostet Zeit; im Steckbrief regeln.
- **Lokaler Spieler (Stufe 5) auf dem A57, ein Lauf:** 40 Züge in 112 s (2,8 s pro Zug), keine Modellaufrufe, Punktestand und Brett
  stimmten mit dem Bildschirm überein, alle vier Richtungen kamen vor, eine Werbung wurde per Zurück-Taste umgangen.
  Zum Vergleich pro Zug: Sonnet etwa 16 s, Haiku etwa 11 s (jeweils mit Screenshot nach jedem Zug).
- Zeitaufteilung des lokalen Spielers wird seit der Zeitmessung (`Zeit pro Zug: …`) ausgegeben; Schätzung davor:
  Bild holen etwa 1 s, App-Sperre (`dumpsys`) etwa 0,5 s, `input swipe`-Start etwa 0,4 s, Warten 0,35 s, Rechnen etwa 0,3 s.
