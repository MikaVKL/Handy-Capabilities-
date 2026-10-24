#!/data/data/com.termux/files/usr/bin/bash
# Nutzung: bench.sh LABEL PUNKTE [NOTIZ]   – hängt den letzten Lauf an bench.csv an
#          bench.sh --show                  – Tabelle anzeigen
HANDY_DIR="${HANDY_DIR:-$HOME/handy}"; CSV="$HANDY_DIR/state/bench.csv"
mkdir -p "$HANDY_DIR/state"
if [ "$1" = "--show" ]; then
  [ -f "$CSV" ] && column -t -s';' "$CSV" 2>/dev/null || cat "$CSV"; exit 0
fi
[ -n "$1" ] && [ -n "$2" ] || { echo "Nutzung: $0 LABEL PUNKTE [NOTIZ]" >&2; exit 2; }
row=$(STATS_CSV=1 "$(dirname "$0")/stats.sh") || exit 1
[ -f "$CSV" ] || echo "zeit;label;punkte;dauer_s;screenshots;aktionen;aufrufe;s_pro_aufruf;notiz" > "$CSV"
echo "$(date '+%F %T');$1;$2;$row;$3" >> "$CSV"
echo "Gespeichert: $1  Punkte=$2  $row"
