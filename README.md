# Handy-Capabilities

Privates Experiment: Claude Code läuft in Termux auf dem Handy und bedient den
Bildschirm per ADB über das Gerät selbst. Start/Stopp über zwei Widget-Knöpfe.
Kein API-Key nötig, die Anmeldung läuft über das normale Claude-Abo.

**Status: ungetestet.** Besonders Claude Code in Termux und dauerhaftes
Wireless-Debugging müssen auf dem Gerät ausprobiert werden.

## Einrichtung (einmalig)
1. Aus F-Droid installieren: **Termux**, **Termux:Widget**, **Termux:API**.
2. In Termux: `pkg update && pkg install git nodejs android-tools termux-api`
3. Claude Code installieren und mit dem Abo anmelden:
   `npm install -g @anthropic-ai/claude-code`, dann `claude` starten und einloggen.
4. Handy: Einstellungen → Entwickleroptionen → **Kabelloses Debugging** an (WLAN nötig).
   "Gerät mit Kopplungscode koppeln" wählen, dann in Termux:
   `adb pair localhost:KOPPLUNGSPORT` und `adb connect localhost:DEBUGPORT`
5. Dieses Repo klonen und `./install.sh` ausführen.
6. Auf dem Startbildschirm ein **Termux:Widget** anlegen: Knöpfe *Handy-Start* und *Handy-Stop*.
7. Erlaubte Apps in `~/handy/allowed-apps.txt` eintragen (Paketnamen, z. B. `com.android.calculator2`).

## Benutzung
- *Handy-Start* tippen, Auftrag eingeben, in die Ziel-App wechseln.
- *Handy-Stop* bricht sofort ab. Außerdem endet jeder Lauf nach 25 Schritten (`MAX_STEPS`).
- Protokoll: `~/handy/state/log.txt`, Ausgabe: `~/handy/state/claude.out`.

## App-Sperre
`tap.sh`, `swipe.sh`, `text.sh` und `key.sh` (außer `home`/`back`) prüfen vor jeder Eingabe,
welche App im Vordergrund ist, und brechen ab, wenn sie nicht in `~/handy/allowed-apps.txt` steht.
Für Gesten auf dem Homescreen den Launcher eintragen (Paketname per
`adb shell dumpsys window | grep mCurrentFocus` bei geöffnetem Homescreen ablesen).
Termux selbst gehört nicht auf die Liste.

## Verbindung (ADB)
Der Port von Wireless debugging ändert sich bei jedem Einschalten. `~/handy/scripts/connect.sh` sucht Adresse und Port
per mDNS; klappt das nicht, `connect.sh PORT` (IP von der letzten Verbindung) oder einmalig `connect.sh PORT IP`.

## Lauf vorbereiten und aufräumen
`~/handy/scripts/start-run.sh` prüft die ADB-Verbindung, löscht STOP-Datei und Schrittzähler, hebt den
Bildschirm-Timeout an und schaltet die STOPP-Benachrichtigung ein. `~/handy/scripts/end-run.sh` stellt alles zurück.
Nach einem Abbruch mit dem STOPP-Knopf bleibt die STOP-Datei liegen, bis `start-run.sh` (oder *Handy-Start*) sie löscht.

## Stopp-Benachrichtigung
`~/handy/scripts/panel.sh on` zeigt eine Dauer-Benachrichtigung mit **STOPP**-Knopf (Termux:API nötig).
*Handy-Start* schaltet sie automatisch ein, *Handy-Stop* und das Ende des Laufs aus. Bei `claude` im Terminal
vorher `panel.sh on`, nachher `panel.sh off`. Die Benachrichtigungsleiste gilt für die App-Sperre als fremde App,
Claudes Eingaben werden währenddessen ohnehin abgelehnt.

## Bildschirm
Vor jeder Aktion weckt `lib.sh` den Bildschirm (`KEYCODE_WAKEUP`), damit keine schwarzen
Screenshots entstehen. *Handy-Start* setzt außerdem den Timeout auf 10 Minuten
(`scripts/screen-timeout.sh on`) und stellt ihn nach dem Lauf oder bei *Handy-Stop* zurück.
Bei interaktiver Nutzung (`claude` im Terminal) einmal `~/handy/scripts/screen-timeout.sh on`
und danach `... off` ausführen.
Hat das Gerät eine PIN, kann es sich nach Bildschirm-Aus sperren; dann stoppt die App-Sperre alle Eingaben.

## Grenzen
- Nur für einfache Apps ohne sensible Daten. Screenshots gehen an Claude.
- Apps mit Screenshot-Sperre zeigen ein schwarzes Bild.
- Kontingent des Abos wird verbraucht; Screenshots sind teuer.
- Nach Neustart muss Wireless-Debugging oft neu verbunden werden.
