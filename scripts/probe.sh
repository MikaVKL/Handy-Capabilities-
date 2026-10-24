#!/data/data/com.termux/files/usr/bin/bash
# Prüft eine freigegebene App ohne Modellaufruf: öffnet sie und wertet den Textbaum aus.
# Nutzung: probe.sh PAKET        (Ergebnis auch in state/probes.csv)
DIR="$(dirname "$0")"; . "$DIR/lib.sh"
pkg="$1"; [ -n "$pkg" ] || { echo "Nutzung: $0 PAKET" >&2; exit 2; }
"$DIR/open-app.sh" "$pkg" || exit $?
sleep 3
row=$(adb exec-out uiautomator dump /dev/tty 2>/dev/null | python3 "$DIR/ui.py" summary)
IFS=';' read -r verdict elems click texts web labels <<< "$row"
CSV="$STATE/probes.csv"
[ -f "$CSV" ] || echo "zeit;paket;urteil;elemente;klickbar;mit_text;webviews;beispiele" > "$CSV"
echo "$(date '+%F %T');$pkg;$row" >> "$CSV"
case "$verdict" in
  REICH)   hint="Textbaum nutzbar: ui.sh + Ketten mit tap/tap-text, kaum Screenshots nötig." ;;
  DUENN)   hint="Textbaum teilweise nutzbar: ui.sh probieren, für Unklares Screenshots." ;;
  WEBVIEW) hint="Inhalt steckt in einem WebView: Screenshots nötig." ;;
  *)       hint="Kein Textbaum: Screenshots nötig." ;;
esac
echo "$pkg: $verdict ($elems Elemente, $click klickbar, $texts mit Text, $web WebView)"
echo "Beispiele: $labels"
echo "$hint"
