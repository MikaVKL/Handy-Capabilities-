#!/data/data/com.termux/files/usr/bin/bash
# Termux:Widget-Knopf "Start": Auftrag abfragen und Claude Code starten.
HANDY_DIR="$HOME/handy"; STATE="$HANDY_DIR/state"; mkdir -p "$STATE"
task=$(termux-dialog text -t "Was soll Claude tun?" -i "Auftrag" | sed -n 's/.*"text": *"\(.*\)".*/\1/p')
[ -z "$task" ] && exit 0
rm -f "$STATE/STOP" "$STATE/steps"
cd "$HANDY_DIR" || exit 1
"$HANDY_DIR/scripts/screen-timeout.sh" on
"$HANDY_DIR/scripts/panel.sh" on
nohup bash -c 'claude -p "$1" --allowedTools "Bash($2/scripts/*)" "Read" > "$3" 2>&1; "$2/scripts/screen-timeout.sh" off; "$2/scripts/panel.sh" off' \
  _ "$task" "$HANDY_DIR" "$STATE/claude.out" > /dev/null 2>&1 &
echo $! > "$STATE/pid"
termux-toast "Gestartet. Stopp-Knopf zum Abbrechen."
