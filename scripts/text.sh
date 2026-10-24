#!/data/data/com.termux/files/usr/bin/bash
# Nutzung: text.sh "Text"  (nur einfache ASCII-Zeichen; Leerzeichen werden ersetzt)
. "$(dirname "$0")/lib.sh"; step_guard text "$*"; app_guard
adb shell input text "$(printf '%s' "$*" | sed 's/ /%s/g')"
