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

# Paketname der App im Vordergrund (leer, wenn nicht ermittelbar).
foreground_pkg() {
  adb shell dumpsys window 2>/dev/null | tr -d '\r' \
    | sed -n 's/.*mCurrentFocus=Window{[^ ]* [^ ]* \([A-Za-z0-9_.]*\)\/.*/\1/p' | head -n 1
}

# Harte Sperre: Eingaben nur, wenn die App im Vordergrund in allowed-apps.txt steht.
app_guard() {
  local pkg; pkg=$(foreground_pkg)
  if [ -z "$pkg" ]; then
    echo "STOPP: Vordergrund-App nicht erkennbar" >&2; log "Sperre: Vordergrund unbekannt"; exit 3
  fi
  if ! grep -qxF "$pkg" "$HANDY_DIR/allowed-apps.txt" 2>/dev/null; then
    echo "STOPP: App nicht freigegeben: $pkg" >&2; log "Sperre: $pkg nicht freigegeben"; exit 3
  fi
}
