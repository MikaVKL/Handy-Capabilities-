#!/data/data/com.termux/files/usr/bin/bash
# Wertet den letzten Lauf aus dem Protokoll aus (ab dem letzten "schritt 1").
# Nutzung: stats.sh [LOGDATEI]
LOGF="${1:-${HANDY_DIR:-$HOME/handy}/state/log.txt}"
[ -f "$LOGF" ] || { echo "Kein Protokoll: $LOGF" >&2; exit 1; }
start=$(grep -n 'schritt 1[ :]' "$LOGF" | tail -n 1 | cut -d: -f1)
[ -n "$start" ] || { echo "Kein Lauf gefunden" >&2; exit 1; }
# Der Aufruf "batch" steht direkt vor dem ersten Schritt der Kette
[ "$start" -gt 1 ] && sed -n "$((start - 1))p" "$LOGF" | grep -q 'aufruf batch' && start=$((start - 1))
run=$(tail -n +"$start" "$LOGF")
first=$(printf '%s\n' "$run" | head -n 1 | cut -c1-19)
last=$(printf '%s\n' "$run" | tail -n 1 | cut -c1-19)
dur=$(( $(date -d "$last" +%s) - $(date -d "$first" +%s) ))
shots=$(printf '%s\n' "$run" | grep -c ' screenshot$')
actions=$(printf '%s\n' "$run" | grep -E 'schritt [0-9]+( \[b\])?: ' | grep -vc ' screenshot$')
batches=$(printf '%s\n' "$run" | grep -c 'aufruf batch')
single=$(printf '%s\n' "$run" | grep -cE 'schritt [0-9]+: ')
calls=$((single + batches))
echo "Dauer (erster bis letzter Schritt): ${dur}s"
echo "Screenshots: $shots   Aktionen (ohne Screenshot): $actions"
echo "Skript-Aufrufe (Modellrunden, grob): $calls   davon Ketten: $batches"
[ "$actions" -gt 0 ] && echo "Screenshots pro Aktion: $(awk "BEGIN{printf \"%.2f\", $shots/$actions}")"
[ "$calls" -gt 0 ] && echo "Sekunden pro Aufruf: $(awk "BEGIN{printf \"%.1f\", $dur/$calls}")"
