# Taschenrechner (Samsung)

Paketname: `com.sec.android.app.popupcalculator` (in `allowed-apps.txt`).
Textbaum: vollständig (Tasten, Eingabefeld, Ergebnisvorschau). Screenshots sind nicht nötig.

## Rezept (Stufe 3, Textbaum + Kette)
1. `open-app.sh com.sec.android.app.popupcalculator`
2. `ui.sh` einmal aufrufen. Die Tasten stehen mit Text und Mitte (X,Y) in der Liste, ebenso `Calculator input field …`
   und `Result preview` (hier steht das Ergebnis als Text).
3. Alle Tasten in **einem** `batch.sh` tippen, entweder mit `tap-text` (`"tap-text 7" "tap-text +" "tap-text 8" "tap-text ="`)
   oder mit den Koordinaten aus Schritt 2 (`"tap 172 1388" …`). Koordinaten sind schneller, `tap-text` robuster.
4. `ui.sh` erneut aufrufen und das Ergebnis aus `Result preview` bzw. dem Eingabefeld lesen. Kein Screenshot nötig.
5. Mit `tap-text C` löschen.
Tasten heißen: `0`–`9`, `+`, `-` (Minus-Zeichen), `×`, `÷`, `=`, `.`, `%`, `( )`, `C`, `Backspace`.
Hinweis: `ui.sh tap` bevorzugt exakte Treffer, deshalb trifft `7` nicht `17`.
