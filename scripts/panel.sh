#!/data/data/com.termux/files/usr/bin/bash
# Nutzung: panel.sh on|off
# on  = Dauer-Benachrichtigung mit STOPP-Knopf (von jeder App aus erreichbar)
# off = Benachrichtigung entfernen
case "$1" in
  on)
    termux-notification --id handy-panel --ongoing --alert-once --priority high \
      --title "Handy-Steuerung aktiv" --content "STOPP-Knopf unten" \
      --button1 "STOPP" --button1-action "$HOME/.shortcuts/Handy-Stop.sh"
    ;;
  off) termux-notification-remove handy-panel ;;
  *) echo "Nutzung: $0 on|off" >&2; exit 2 ;;
esac
