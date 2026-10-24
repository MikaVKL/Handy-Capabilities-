#!/data/data/com.termux/files/usr/bin/bash
# Für den Nutzer (nicht für Claude): macht alles für einen neuen Lauf bereit.
# Prüft ADB, löscht STOP-Datei und Schrittzähler, Bildschirm-Timeout hoch, STOPP-Benachrichtigung an.
DIR="$(dirname "$0")"
HANDY_DIR="${HANDY_DIR:-$HOME/handy}"; STATE="$HANDY_DIR/state"; mkdir -p "$STATE"
if [ "$(adb get-state 2>/dev/null)" != "device" ]; then
  echo "ADB nicht verbunden. Wireless debugging einschalten, aktuellen Port ablesen und:" >&2
  echo "  adb connect IP:PORT" >&2
  exit 1
fi
rm -f "$STATE/STOP" "$STATE/steps"
"$DIR/screen-timeout.sh" on
"$DIR/panel.sh" on
echo "Bereit: ADB verbunden, STOP-Datei gelöscht, Timeout hoch, STOPP-Knopf aktiv."
