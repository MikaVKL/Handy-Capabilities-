#!/data/data/com.termux/files/usr/bin/bash
# Nutzung: screen-timeout.sh on|off
# on  = Bildschirm-Timeout auf 10 Minuten (alter Wert wird gemerkt)
# off = alten Wert wiederherstellen
HANDY_DIR="${HANDY_DIR:-$HOME/handy}"
STATE="$HANDY_DIR/state"; mkdir -p "$STATE"
SAVED="$STATE/orig_timeout"
case "$1" in
  on)
    if [ ! -f "$SAVED" ]; then
      cur=$(adb shell settings get system screen_off_timeout 2>/dev/null | tr -d '\r')
      case "$cur" in ''|*[!0-9]*) echo "Timeout nicht lesbar" >&2; exit 1;; esac
      echo "$cur" > "$SAVED"
    fi
    adb shell settings put system screen_off_timeout 600000
    ;;
  off)
    [ -f "$SAVED" ] || exit 0
    adb shell settings put system screen_off_timeout "$(cat "$SAVED")" && rm -f "$SAVED"
    ;;
  *) echo "Nutzung: $0 on|off" >&2; exit 2;;
esac
