#!/data/data/com.termux/files/usr/bin/bash
# Nutzung: key.sh back|home|enter|recents
. "$(dirname "$0")/lib.sh"; step_guard key "$1"
# home und back sind immer erlaubt (Rückweg); alles andere nur in freigegebenen Apps
case "$1" in home|back) ;; *) app_guard;; esac
case "$1" in
  back) c=4;; home) c=3;; enter) c=66;; recents) c=187;;
  *) echo "Unbekannte Taste" >&2; exit 2;;
esac
adb shell input keyevent "$c"
