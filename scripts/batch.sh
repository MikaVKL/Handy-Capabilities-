#!/data/data/com.termux/files/usr/bin/bash
# Mehrere Aktionen in einem Aufruf. Jede Aktion läuft über das jeweilige Skript,
# also mit Schrittlimit, Stopp-Datei und App-Sperre; beim ersten Fehler wird abgebrochen.
# Nutzung: batch.sh "tap X Y" "swipe X1 Y1 X2 Y2" "text Hallo" "key back" "wait 1" "shot"
DIR="$(dirname "$0")"
. "$DIR/lib.sh"
MAX_ACTIONS="${MAX_ACTIONS:-8}"
set -f
if [ "$#" -eq 0 ] || [ "$#" -gt "$MAX_ACTIONS" ]; then
  echo "Es sind 1 bis $MAX_ACTIONS Aktionen erlaubt" >&2; exit 2
fi
log "aufruf batch: $# Aktionen"
export HANDY_IN_BATCH=1
for a in "$@"; do
  set -- $a
  cmd="$1"; shift
  case "$cmd" in
    tap|swipe|text|key) "$DIR/$cmd.sh" "$@" || exit $? ;;
    wait)
      case "$1" in ''|*[!0-9]*) echo "wait braucht ganze Sekunden" >&2; exit 2;; esac
      [ "$1" -le 10 ] || { echo "wait höchstens 10 Sekunden" >&2; exit 2; }
      sleep "$1" ;;
    shot) "$DIR/screen.sh" || exit $? ;;
    *) echo "Unbekannte Aktion: $cmd" >&2; exit 2 ;;
  esac
  sleep 0.3
done
