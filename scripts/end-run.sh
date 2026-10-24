#!/data/data/com.termux/files/usr/bin/bash
# Für den Nutzer: räumt nach einem Lauf auf (Timeout zurück, Benachrichtigung weg).
DIR="$(dirname "$0")"
"$DIR/screen-timeout.sh" off
"$DIR/panel.sh" off
echo "Aufgeräumt."
