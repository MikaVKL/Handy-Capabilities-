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

## Grenzen
- Nur für einfache Apps ohne sensible Daten. Screenshots gehen an Claude.
- Apps mit Screenshot-Sperre zeigen ein schwarzes Bild.
- Kontingent des Abos wird verbraucht; Screenshots sind teuer.
- Nach Neustart muss Wireless-Debugging oft neu verbunden werden.
