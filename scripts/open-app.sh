#!/data/data/com.termux/files/usr/bin/bash
# Nutzung: open-app.sh PAKETNAME  (nur Apps aus ~/handy/allowed-apps.txt)
. "$(dirname "$0")/lib.sh"; step_guard open-app "$1"
if ! grep -qxF "$1" "$HANDY_DIR/allowed-apps.txt" 2>/dev/null; then
  echo "App nicht freigegeben: $1" >&2; exit 3
fi
adb shell monkey -p "$1" -c android.intent.category.LAUNCHER 1 >/dev/null
