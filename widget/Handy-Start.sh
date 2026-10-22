#!/data/data/com.termux/files/usr/bin/bash
# Termux:Widget-Knopf "Start": Auftrag abfragen und Claude Code starten.
HANDY_DIR="$HOME/handy"; STATE="$HANDY_DIR/state"; mkdir -p "$STATE"
task=$(termux-dialog text -t "Was soll Claude tun?" -i "Auftrag" | sed -n 's/.*"text": *"\(.*\)".*/\1/p')
[ -z "$task" ] && exit 0
rm -f "$STATE/STOP" "$STATE/steps"
cd "$HANDY_DIR" || exit 1
nohup claude -p "$task" \
  --allowedTools "Bash($HANDY_DIR/scripts/*)" "Read" \
  > "$STATE/claude.out" 2>&1 &
echo $! > "$STATE/pid"
termux-toast "Gestartet. Stopp-Knopf zum Abbrechen."
