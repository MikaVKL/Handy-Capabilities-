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
  # Neuer Lauf: Zähler zurücksetzen, wenn der letzte Schritt länger als RUN_IDLE_SECS her ist
  if [ -f "$STATE/steps" ]; then
    local age=$(( $(date +%s) - $(stat -c %Y "$STATE/steps" 2>/dev/null || date +%s) ))
    [ "$age" -gt "${RUN_IDLE_SECS:-120}" ] && rm -f "$STATE/steps"
  fi
  local n; n=$(cat "$STATE/steps" 2>/dev/null || echo 0); n=$((n + 1))
  if [ "$n" -gt "$MAX_STEPS" ]; then
    echo "STOPP: Schrittlimit ($MAX_STEPS) erreicht" >&2; log "Schrittlimit"; exit 1
  fi
  echo "$n" > "$STATE/steps"
  log "schritt $n${HANDY_IN_BATCH:+ [b]}: $*"
  # Bildschirm wecken (tut nichts, wenn er schon an ist), damit keine schwarzen Screenshots entstehen
  adb shell input keyevent KEYCODE_WAKEUP >/dev/null 2>&1 || true
}

# Paketname der App im Vordergrund (leer, wenn nicht ermittelbar).
foreground_pkg() {
  adb shell dumpsys window 2>/dev/null | tr -d '\r' \
    | sed -n 's/.*mCurrentFocus=Window{[^ ]* [^ ]* \([A-Za-z0-9_.]*\)\/.*/\1/p' | head -n 1
}

# Harte Sperre: Eingaben nur, wenn die App im Vordergrund in allowed-apps.txt steht.
# Beim App-Wechsel hinkt die Fokusanzeige kurz hinterher; deshalb bis zu 3 Versuche im Abstand von 0,7 s.
app_guard() {
  local pkg="" i
  for i in 1 2 3; do
    pkg=$(foreground_pkg)
    if [ -n "$pkg" ] && grep -qxF "$pkg" "$HANDY_DIR/allowed-apps.txt" 2>/dev/null; then
      return 0
    fi
    [ "$i" -lt 3 ] && sleep 0.7
  done
  if [ -z "$pkg" ]; then
    echo "STOPP: Vordergrund-App nicht erkennbar" >&2; log "Sperre: Vordergrund unbekannt"; exit 3
  fi
  echo "STOPP: App nicht freigegeben: $pkg" >&2; log "Sperre: $pkg nicht freigegeben"; exit 3
}
