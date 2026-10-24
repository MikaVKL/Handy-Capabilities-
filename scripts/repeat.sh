#!/data/data/com.termux/files/usr/bin/bash
# Wiederholt eine Kette von Aktionen ohne Modell (für reines Wiederholen). Für den Nutzer, nicht für Claude.
# Nutzung: repeat.sh DURCHLÄUFE PAUSE_SEKUNDEN "tap X Y" "wait 1" ...   (höchstens 500 Durchläufe, 8 Aktionen je Durchlauf)
# Die App-Sperre, die STOP-Datei und der STOPP-Knopf gelten weiter; beim ersten Fehler wird abgebrochen.
DIR="$(dirname "$0")"; . "$DIR/lib.sh"
count="$1"; pause="$2"; shift 2 2>/dev/null
case "$count$pause" in ''|*[!0-9]*) echo "Nutzung: $0 DURCHLÄUFE PAUSE_SEKUNDEN \"aktion\" ..." >&2; exit 2;; esac
[ "$#" -ge 1 ] || { echo "Mindestens eine Aktion angeben" >&2; exit 2; }
[ "$count" -ge 1 ] && [ "$count" -le 500 ] || { echo "DURCHLÄUFE: 1 bis 500" >&2; exit 2; }
export MAX_STEPS=$(( count * $# + 5 ))
log "repeat start: $count x ($*)"
for i in $(seq 1 "$count"); do
  [ -f "$STATE/STOP" ] && { echo "STOPP nach $((i-1)) Durchläufen" >&2; exit 1; }
  "$DIR/batch.sh" "$@" || { rc=$?; echo "Abbruch im Durchlauf $i (Code $rc)" >&2; exit $rc; }
  [ "$i" -lt "$count" ] && sleep "$pause"
done
echo "Fertig: $count Durchläufe"
