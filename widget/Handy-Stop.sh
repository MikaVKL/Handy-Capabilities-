#!/data/data/com.termux/files/usr/bin/bash
# Termux:Widget-Knopf "Stopp": sofort abbrechen.
STATE="$HOME/handy/state"; mkdir -p "$STATE"
touch "$STATE/STOP"
[ -f "$STATE/pid" ] && kill "$(cat "$STATE/pid")" 2>/dev/null
termux-toast "Gestoppt"
