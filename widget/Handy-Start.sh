#!/data/data/com.termux/files/usr/bin/bash
# Start des KI-Makros ("Das hier ist …, mache …"). Läuft am besten im Hintergrund (~/.shortcuts/tasks/ oder über die Benachrichtigung),
# damit die Ziel-App im Vordergrund bleibt und erkannt wird.
exec "$HOME/handy/scripts/macro.sh" "$@"
