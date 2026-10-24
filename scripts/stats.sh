#!/data/data/com.termux/files/usr/bin/bash
# Wertet den letzten Lauf aus dem Protokoll aus (ab dem letzten "schritt 1").
# Nutzung: stats.sh [LOGDATEI]
LOGF="${1:-${HANDY_DIR:-$HOME/handy}/state/log.txt}"
[ -f "$LOGF" ] || { echo "Kein Protokoll: $LOGF" >&2; exit 1; }
start=$(grep -n 'schritt 1[ :]' "$LOGF" | tail -n 1 | cut -d: -f1)
[ -n "$start" ] || { echo "Kein Lauf gefunden" >&2; exit 1; }
# Der Aufruf "batch" steht direkt vor dem ersten Schritt der Kette
[ "$start" -gt 1 ] && sed -n "$((start - 1))p" "$LOGF" | grep -q 'aufruf batch' && start=$((start - 1))
tail -n +"$start" "$LOGF" > /tmp/handy-run.$$ 2>/dev/null || exit 1
first=$(head -n 1 /tmp/handy-run.$$ | cut -c1-19); last=$(tail -n 1 /tmp/handy-run.$$ | cut -c1-19)
dur=$(( $(date -d "$last" +%s) - $(date -d "$first" +%s) ))
shots=$(grep -c ' screenshot$' /tmp/handy-run.$$)
actions=$(grep -E 'schritt [0-9]+( \[b\])?: ' /tmp/handy-run.$$ | grep -vc ' screenshot$')
batches=$(grep -c 'aufruf batch' /tmp/handy-run.$$)
single=$(grep -E 'schritt [0-9]+: ' /tmp/handy-run.$$ | wc -l)
calls=$((single + batches))
rm -f /tmp/handy-run.$$
echo "Dauer (erster bis letzter Schritt): ${dur}s"
echo "Screenshots: $shots   Aktionen (ohne Screenshot): $actions"
echo "Skript-Aufrufe (Modellrunden, grob): $calls   davon Ketten: $batches"
[ "$actions" -gt 0 ] && echo "Screenshots pro Aktion: $(awk "BEGIN{printf \"%.2f\", $shots/$actions}")"
[ "$calls" -gt 0 ] && echo "Sekunden pro Aufruf: $(awk "BEGIN{printf \"%.1f\", $dur/$calls}")"
