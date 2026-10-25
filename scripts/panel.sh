#!/data/data/com.termux/files/usr/bin/bash
# Nutzung: panel.sh on|idle|off
# on   = Dauer-Benachrichtigung mit STOPP-Knopf (ein Lauf ist aktiv)
# idle = Dauer-Benachrichtigung mit START-Knopf (bereit: in der Ziel-App tippen, Auftrag eingeben)
# off  = Benachrichtigung entfernen
case "$1" in
  on)
    termux-notification --id handy-panel --ongoing --alert-once --priority high \
      --title "Handy-Steuerung aktiv" --content "STOPP-Knopf unten" \
      --button1 "STOPP" --button1-action "$HOME/.shortcuts/tasks/Handy-Stop.sh"
    ;;
  idle)
    termux-notification --id handy-panel --ongoing --alert-once --priority low \
      --title "KI-Makro bereit" --content "In der Ziel-App: START tippen" \
      --button1 "START" --button1-action "$HOME/.shortcuts/tasks/Handy-Start.sh"
    ;;
  off) termux-notification-remove handy-panel ;;
  *) echo "Nutzung: $0 on|idle|off" >&2; exit 2 ;;
esac
