#!/data/data/com.termux/files/usr/bin/bash
# Nutzung: tap.sh X Y
. "$(dirname "$0")/lib.sh"; step_guard tap "$@"; app_guard
adb shell input tap "$1" "$2"
