#!/data/data/com.termux/files/usr/bin/bash
# Nutzung: swipe.sh X1 Y1 X2 Y2 [DAUER_MS]
. "$(dirname "$0")/lib.sh"; step_guard swipe "$@"
adb shell input swipe "$1" "$2" "$3" "$4" "${5:-300}"
