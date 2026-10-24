#!/data/data/com.termux/files/usr/bin/bash
# Textbaum der Oberfläche statt Bild. Schneller und billiger als Screenshots, wo die App einen Baum liefert.
# Nutzung: ui.sh                 – kompakte Liste (Text, Typ, Mitte X,Y)
#          ui.sh tap TEXT [N]    – tippt das N-te Element mit diesem Text (exakte Treffer zuerst, sonst Teiltreffer)
DIR="$(dirname "$0")"; . "$DIR/lib.sh"
dump() { adb exec-out uiautomator dump /dev/tty 2>/dev/null; }
case "$1" in
  tap)
    shift
    [ "$#" -ge 1 ] || { echo "Nutzung: $0 tap TEXT [N]" >&2; exit 2; }
    n=1
    if [ "$#" -ge 2 ]; then
      last="${!#}"
      case "$last" in ''|*[!0-9]*) ;; *) n="$last"; set -- "${@:1:$(($#-1))}" ;; esac
    fi
    xy=$(dump | python3 "$DIR/ui.py" find "$*" "$n") || exit $?
    exec "$DIR/tap.sh" $xy ;;
  ""|list)
    step_guard ui
    dump | python3 "$DIR/ui.py" list ;;
  *) echo "Nutzung: $0 [list | tap TEXT [N]]" >&2; exit 2 ;;
esac
