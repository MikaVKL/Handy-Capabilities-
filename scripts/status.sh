#!/data/data/com.termux/files/usr/bin/bash
# Meldet den Zustand an das Bedienfeld (App KI-Makro): status.sh running|done|error|stopped|idle ["Text"]
am broadcast -a dev.handy.macro.STATUS -p dev.handy.macro --es state "${1:-idle}" --es text "${2:-}" >/dev/null 2>&1 || true
