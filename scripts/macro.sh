#!/data/data/com.termux/files/usr/bin/bash
# KI-Makro: "Das hier ist <App im Vordergrund>, mache <Auftrag>".
# Erkennt die App, prüft die Freigabe, lädt den Steckbrief (apps/profiles.tsv) und führt den Auftrag aus:
# direkt mit dem lokalen Werkzeug (z. B. 2048) oder über Claude Code.
# Nutzung: macro.sh                     (Auftrag im Dialog eingeben; App = Vordergrund)
#          macro.sh "Auftrag"           (App = Vordergrund)
#          macro.sh --app PAKET "Auftrag"
DIR="$(cd "$(dirname "$0")" && pwd)"; . "$DIR/lib.sh"
APPS="$HANDY_DIR/apps"; OUT="$STATE/claude.out"
say() { echo "$*"; termux-toast "$*" >/dev/null 2>&1 || true; "$DIR/status.sh" error "$*"; }

# ADB prüfen; wenn nicht verbunden, einmal selbst verbinden (mDNS), sonst klar melden
if [ "$(adb get-state 2>/dev/null)" != "device" ]; then
  "$DIR/connect.sh" >/dev/null 2>&1
  if [ "$(adb get-state 2>/dev/null)" != "device" ]; then
    say "ADB nicht verbunden. Wireless debugging an? In Termux: connect.sh PORT"
    exit 1
  fi
fi

# Läuft schon ein Makro (doppeltes Antippen, doppelte Zustellung), nicht noch eins starten
old=$(cat "$STATE/pid" 2>/dev/null)
if [ -n "$old" ] && [ "$old" != "$$" ] && kill -0 "$old" 2>/dev/null && grep -q macro.sh "/proc/$old/cmdline" 2>/dev/null; then
  say "Läuft schon. Erst ■ tippen."
  exit 1
fi

pkg=""
if [ "$1" = "--app" ]; then pkg="$2"; shift 2; fi
if [ -z "$pkg" ]; then
  # Direkt nach dem Antippen von START schließt sich noch die Benachrichtigungsleiste bzw. ein Eingabefenster:
  # bis zu 3 s warten, bis dort die Ziel-App im Vordergrund steht
  for _ in 1 2 3 4 5 6; do
    pkg=$(foreground_pkg)
    case "$pkg" in ""|com.termux|com.termux.api|com.android.systemui|dev.handy.macro) sleep 0.5 ;; *) break ;; esac
  done
fi
case "$pkg" in
  ""|com.termux|com.termux.api|com.sec.android.app.launcher|com.android.systemui|dev.handy.macro)
    last=$(cat "$STATE/last-app" 2>/dev/null); [ -n "$last" ] && pkg="$last" ;;
esac
[ -n "$pkg" ] || { say "Keine App erkannt. Ziel-App öffnen und erneut starten."; exit 1; }
grep -qxF "$pkg" "$HANDY_DIR/allowed-apps.txt" 2>/dev/null || { say "App nicht freigegeben: $pkg (allow-app.sh)"; exit 3; }

task="$*"
if [ -z "$task" ]; then
  task=$(termux-dialog text -t "Das hier ist $pkg. Was soll ich tun?" 2>/dev/null | sed -n 's/.*"text": *"\(.*\)".*/\1/p')
fi
[ -n "$task" ] || exit 0

profile=""; direct=""
if [ -f "$APPS/profiles.tsv" ]; then
  line=$(grep -v '^#' "$APPS/profiles.tsv" | awk -F'\t' -v p="$pkg" '$1==p {print; exit}')
  profile=$(printf '%s' "$line" | cut -f2); direct=$(printf '%s' "$line" | cut -f3)
fi

"$DIR/start-run.sh" || { say "Nicht startklar (ADB verbunden? connect.sh)"; exit 1; }
echo $$ > "$STATE/pid"
export MAX_STEPS="${HANDY_MAX_STEPS:-150}"
log "macro: $pkg | $task"
echo "Start: $pkg"; termux-toast "Start: $pkg" >/dev/null 2>&1 || true; "$DIR/status.sh" running

cd "$HANDY_DIR" || exit 1
if [ "$direct" = "play2048" ] && [[ "$task" =~ ([0-9]+) ]] && [ "${BASH_REMATCH[1]}" -le 500 ]; then
  python3 "$DIR/play2048.py" play "${BASH_REMATCH[1]}" > "$OUT" 2>&1
else
  command -v claude >/dev/null 2>&1 || { rm -f "$STATE/pid"; "$DIR/end-run.sh" >/dev/null 2>&1; say "claude nicht gefunden (PATH in Hintergrundläufen). Siehe README."; exit 1; }
  model="${HANDY_MODEL:-haiku}"
  prompt="Du bedienst das Handy über die Skripte in $DIR (siehe CLAUDE.md). Die App im Vordergrund beim Start war $pkg."
  [ -n "$profile" ] && prompt="$prompt Lies zuerst den Steckbrief $APPS/$profile."
  prompt="$prompt Auftrag des Nutzers: $task
Bei normalen Apps zuerst ui.sh, sonst Screenshots. Keine Zwischenkommentare; am Ende ein bis zwei Sätze mit dem Ergebnis."
  claude -p "$prompt" --model "$model" --allowedTools "Bash($DIR/*)" "Read" > "$OUT" 2>&1
fi

summary=$(tail -n 3 "$OUT" 2>/dev/null | tr '\n' ' ' | cut -c1-200)
rm -f "$STATE/pid"
"$DIR/end-run.sh" >/dev/null 2>&1
termux-notification --id handy-result --title "KI-Makro fertig" --content "${summary:-fertig}" >/dev/null 2>&1 || true
"$DIR/panel.sh" idle >/dev/null 2>&1 || true
"$DIR/status.sh" done "${summary:-fertig}"
echo "$summary"
