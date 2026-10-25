#!/data/data/com.termux/files/usr/bin/bash
# Stopp: sofort abbrechen (STOP-Datei sperrt alle Eingaben, laufende Prozesse werden beendet).
STATE="$HOME/handy/state"; mkdir -p "$STATE"
touch "$STATE/STOP"
if [ -f "$STATE/pid" ]; then
  pid=$(cat "$STATE/pid")
  command -v pkill >/dev/null 2>&1 && pkill -P "$pid" 2>/dev/null
  kill "$pid" 2>/dev/null
fi
"$HOME/handy/scripts/screen-timeout.sh" off
"$HOME/handy/scripts/panel.sh" idle
termux-toast "Gestoppt"
"$HOME/handy/scripts/status.sh" stopped
