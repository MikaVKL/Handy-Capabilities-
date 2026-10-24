#!/data/data/com.termux/files/usr/bin/bash
# Mehrere Aktionen in einem Aufruf. Jede Aktion läuft über das jeweilige Skript,
# also mit Schrittlimit, Stopp-Datei und App-Sperre; beim ersten Fehler wird abgebrochen.
# Nutzung: batch.sh "tap X Y" "swipe X1 Y1 X2 Y2" "text Hallo" "key back" "wait 1" "shot"
# Zusatzaktionen mit Wirkungsprüfung: "swipe-check X1 Y1 X2 Y2 [ms]" und "tap-check X Y".
# Sie führen die Geste aus und vergleichen das Bild vorher/nachher (lokal, ohne Modell).
# Hat sich nichts verändert, bricht die Kette mit "KEIN EFFEKT" ab (Exit-Code 4).
DIR="$(dirname "$0")"
. "$DIR/lib.sh"
MAX_ACTIONS="${MAX_ACTIONS:-8}"
set -f
screen_hash() { adb exec-out screencap -p 2>/dev/null | md5sum | cut -d' ' -f1; }
if [ "$#" -eq 0 ] || [ "$#" -gt "$MAX_ACTIONS" ]; then
  echo "Es sind 1 bis $MAX_ACTIONS Aktionen erlaubt" >&2; exit 2
fi
log "aufruf batch: $# Aktionen"
export HANDY_IN_BATCH=1
prev=""; n=0; ok=0
for a in "$@"; do
  set -- $a
  cmd="$1"; shift
  n=$((n + 1))
  case "$cmd" in
    swipe-check|tap-check)
      [ -n "$prev" ] || prev=$(screen_hash)
      "$DIR/${cmd%-check}.sh" "$@" || exit $?
      sleep 0.5
      now=$(screen_hash)
      if [ "$now" = "$prev" ]; then
        echo "KEIN EFFEKT: Aktion $n (${cmd%-check} $*) hat das Bild nicht verändert; Kette abgebrochen nach $ok wirksamen Aktionen" >&2
        log "kein Effekt bei Aktion $n"
        exit 4
      fi
      prev="$now"; ok=$((ok + 1)) ;;
    tap|swipe|text|key) "$DIR/$cmd.sh" "$@" || exit $?; prev="" ;;
    wait)
      case "$1" in ''|*[!0-9]*) echo "wait braucht ganze Sekunden" >&2; exit 2;; esac
      [ "$1" -le 10 ] || { echo "wait höchstens 10 Sekunden" >&2; exit 2; }
      sleep "$1" ;;
    shot) "$DIR/screen.sh" || exit $? ;;
    *) echo "Unbekannte Aktion: $cmd" >&2; exit 2 ;;
  esac
  sleep 0.3
done
