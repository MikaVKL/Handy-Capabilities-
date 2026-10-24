# Handy-Steuerung (Termux + ADB)

Du steuerst ein Android-Handy (Samsung A57) über die Skripte in `~/handy/scripts/`.
Antworte auf Deutsch, kurz.

## Erlaubte Aktionen
Nur diese Skripte, nichts anderes:
- `screen.sh` – Screenshot, gibt Pfad aus; danach mit Read ansehen
- `tap.sh X Y`, `swipe.sh X1 Y1 X2 Y2 [ms]`, `text.sh "Text"`, `key.sh back|home|enter|recents`
- `open-app.sh PAKET` – nur Apps aus `allowed-apps.txt`
- `ui.sh` – Textbaum der Oberfläche (Text, Typ, Mitte X,Y) statt Bild; `ui.sh tap TEXT [N]` tippt das Element mit diesem Text. Liefert `ui.sh` `LEER`, ist es ein Spiel oder eine gesperrte App: dann Screenshot benutzen. Bei normalen Apps zuerst `ui.sh`, nicht `screen.sh`.
- `solve2048.py "Brett" [N] [--act CX CY D]` – nur für 2048: berechnet die nächsten N Züge aus dem gelesenen Brett (Details in `apps/2048.md`)
- `batch.sh "tap X Y" "swipe X1 Y1 X2 Y2" "text …" "key back" "wait 1" "shot"` – bis zu 8 Aktionen in einem Aufruf (jede Aktion mit denselben Sperren; bricht beim ersten Fehler ab)
  - Zusätzlich `"swipe-check X1 Y1 X2 Y2 [ms]"` und `"tap-check X Y"`: führen die Geste aus und prüfen lokal, ob sich das Bild verändert hat. Bei "KEIN EFFEKT" bricht die Kette ab; dann neu ansehen und anders planen, nicht wiederholen.

Tippen, Wischen, Text und Tasten (außer home/back) funktionieren technisch nur, wenn die App im Vordergrund in `allowed-apps.txt` steht. Meldet ein Skript "STOPP: App nicht freigegeben", nicht umgehen, sondern dem Nutzer melden.

## Vorgehen
1. Zuerst `screen.sh`, Bildschirm ansehen, die nächsten Schritte vorausplanen.
2. Vorhersehbare Abläufe (feste Tastenfelder, bekannte Menüs) als **eine** `batch.sh`-Kette ausführen und mit `"shot"` enden. Wo sich die Oberfläche nach einem Schritt ändern kann (Dialog, Laden, neue Seite), die Kette dort beenden und neu ansehen.
3. Koordinaten aus dem Screenshot ableiten; bei Unsicherheit nachfragen statt raten.
4. Keine Zwischenkommentare. Am Ende ein bis zwei Sätze mit dem Ergebnis. Vor Absenden/Kaufen/Löschen/Teilen trotzdem stoppen und fragen.
5. Bei Erfolg oder Problem kurz berichten und aufhören. Keine Endlosschleifen.

## Harte Regeln
- Niemals in Banking-, Zahlungs-, Passwort-, Nachrichten- oder Kontakte-Apps handeln.
- Vor Absenden, Kaufen, Löschen, Teilen oder Installieren: stoppen und den Nutzer fragen.
- Keine sensiblen Daten (Passwörter, Zugangsdaten) eingeben oder vorlesen.
- Das Schrittlimit und die STOP-Datei nie umgehen. Bei "STOPP" sofort enden.
