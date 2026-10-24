#!/data/data/com.termux/files/usr/bin/bash
# Textbaum der Oberfläche statt Bild. Schneller und billiger als Screenshots, wo die App einen Baum liefert.
# Nutzung: ui.sh                 – kompakte Liste (Text, Typ, Mitte X,Y)
#          ui.sh tap TEXT [N]    – tippt das N-te Element, dessen Text oder Beschreibung TEXT enthält
DIR="$(dirname "$0")"; . "$DIR/lib.sh"
dump() { adb exec-out uiautomator dump /dev/tty 2>/dev/null; }
case "$1" in
  tap)
    [ -n "$2" ] || { echo "Nutzung: $0 tap TEXT [N]" >&2; exit 2; }
    xy=$(dump | python3 "$DIR/ui.py" find "$2" "$3") || exit $?
    exec "$DIR/tap.sh" $xy ;;
  ""|list)
    step_guard ui
    dump | python3 "$DIR/ui.py" list ;;
  *) echo "Nutzung: $0 [list | tap TEXT [N]]" >&2; exit 2 ;;
esac
