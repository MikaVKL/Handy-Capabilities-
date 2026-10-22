#!/data/data/com.termux/files/usr/bin/bash
# Gemeinsame Funktionen: Schrittlimit, Stopp-Datei, Protokoll.
HANDY_DIR="${HANDY_DIR:-$HOME/handy}"
MAX_STEPS="${MAX_STEPS:-25}"
STATE="$HANDY_DIR/state"
mkdir -p "$STATE"

log() { echo "$(date '+%F %T') $*" >> "$STATE/log.txt"; }

step_guard() {
  if [ -f "$STATE/STOP" ]; then
    echo "STOPP: vom Nutzer abgebrochen" >&2; log "abgebrochen (STOP)"; exit 1
  fi
  local n; n=$(cat "$STATE/steps" 2>/dev/null || echo 0); n=$((n + 1))
  if [ "$n" -gt "$MAX_STEPS" ]; then
    echo "STOPP: Schrittlimit ($MAX_STEPS) erreicht" >&2; log "Schrittlimit"; exit 1
  fi
  echo "$n" > "$STATE/steps"
  log "schritt $n: $*"
}
