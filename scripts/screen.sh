#!/data/data/com.termux/files/usr/bin/bash
# Screenshot machen; gibt den Dateipfad aus (danach mit Read ansehen).
. "$(dirname "$0")/lib.sh"; step_guard screenshot
sleep 0.4
out="$STATE/screen.png"
adb exec-out screencap -p > "$out" && echo "$out"
