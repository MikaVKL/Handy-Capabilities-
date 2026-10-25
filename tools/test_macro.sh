#!/bin/bash
# Test von macro.sh (App erkennen, Freigabe, Steckbrief, direkter Spieler oder Claude) gegen ein nachgebautes Handy.
R="$(cd "$(dirname "$0")/.." && pwd)"; W=$(mktemp -d); mkdir -p "$W/bin" "$W/handy/state" "$W/handy/scripts" "$W/handy/apps"
printf '#!/bin/bash\nexec python3 %s/tools/fake_adb.py "$@"\n' "$R" > "$W/bin/adb"
for c in termux-toast termux-notification termux-notification-remove; do printf '#!/bin/bash\necho "%s $*" >> %s/termux.log\n' "$c" "$W" > "$W/bin/$c"; done
printf '#!/bin/bash\necho "{\\"code\\": 0, \\"text\\": \\"%s\\"}"\n' "${DIALOG_TEXT:-rechne 7+8}" > "$W/bin/termux-dialog"
printf '#!/bin/bash\necho "$*" | tr "\\n" " " >> %s/claude.log; echo >> %s/claude.log; echo "Ergebnis ok"\n' "$W" "$W" > "$W/bin/claude"
chmod +x "$W"/bin/*
cp "$R"/scripts/*.sh "$R"/scripts/*.py "$W/handy/scripts/"; sed -i '1s|.*|#!/bin/bash|' "$W"/handy/scripts/*.sh
cp "$R"/apps/* "$W/handy/apps/"
export PATH="$W/bin:$PATH" HANDY_DIR="$W/handy" FAKE_STATE="$W/state.json"; M="$W/handy/scripts/macro.sh"
printf '# Pakete\ncom.gabrielecirulli.app2048\ncom.sec.android.app.popupcalculator\n' > "$HANDY_DIR/allowed-apps.txt"
fail=0; check() { if eval "$2"; then echo "OK   $1"; else echo "FAIL $1"; fail=1; fi; }
setstate() { python3 - "$1" <<'PY'
import json, os, random, sys
random.seed(11); b=[0]*16
for v in (2,2): b[random.choice([i for i in range(16) if b[i]==0])]=v
json.dump({"board":b,"score":0,"over":False,"fg":sys.argv[1]}, open(os.environ["FAKE_STATE"],"w"))
PY
}
: > "$W/claude.log"
# 1) 2048 im Vordergrund, Auftrag mit Zahl -> lokaler Spieler, kein Claude
setstate com.gabrielecirulli.app2048; python3 "$HANDY_DIR/scripts/play2048.py" calibrate >/dev/null
out=$($M "spiel 12 Züge" 2>&1)
check "2048 + Zahl: lokaler Spieler"        'grep -q "Züge: 12," "$HANDY_DIR/state/claude.out"'
check "2048 + Zahl: Claude nicht gestartet" '[ ! -s "$W/claude.log" ]'
check "Meldung am Ende"                     'grep -q "KI-Makro fertig" "$W/termux.log"'
# 2) Taschenrechner -> Claude mit Steckbrief
setstate com.sec.android.app.popupcalculator
$M "rechne 7+8" >/dev/null 2>&1
check "Claude: Modell"                      'grep -q -- "--model haiku" "$W/claude.log"'
check "Claude: App im Prompt"               'grep -q "com.sec.android.app.popupcalculator" "$W/claude.log"'
check "Claude: Steckbrief im Prompt"        'grep -q "calculator.md" "$W/claude.log"'
check "Claude: Auftrag im Prompt"           'grep -q "rechne 7+8" "$W/claude.log"'
check "Claude: nur Skripte erlaubt"         'grep -q -- "--allowedTools Bash($HANDY_DIR/scripts" "$W/claude.log"'
# 3) 2048 ohne Zahl -> Claude
: > "$W/claude.log"; setstate com.gabrielecirulli.app2048
$M "spiel eine Runde" >/dev/null 2>&1
check "2048 ohne Zahl: Claude"              '[ -s "$W/claude.log" ] && grep -q "2048.md" "$W/claude.log"'
# 4) nicht freigegebene App
: > "$W/claude.log"; setstate com.android.chrome
$M "mach irgendwas" >"$W/o.txt" 2>&1; rc=$?
check "nicht freigegeben: Abbruch 3"        '[ $rc -eq 3 ] && grep -q "nicht freigegeben" "$W/o.txt" && [ ! -s "$W/claude.log" ]'
# 5) Termux im Vordergrund -> letzte freigegebene App
setstate com.gabrielecirulli.app2048; $M "spiel 3 Züge" >/dev/null 2>&1
setstate com.termux; out=$($M "spiel 3 Züge" 2>&1)
check "Termux vorn: nimmt die letzte App"   'echo "$out" | grep -q "Start: com.gabrielecirulli.app2048"'
# 5b) Benachrichtigungsleiste vorn -> wartet kurz, dann letzte App
setstate com.android.systemui; out=$($M "spiel 3 Züge" 2>&1)
check "Leiste vorn: nimmt die letzte App"   'echo "$out" | grep -q "Start: com.gabrielecirulli.app2048"'
# 6) --app erzwingt die App
: > "$W/claude.log"; setstate com.termux
$M --app com.sec.android.app.popupcalculator "rechne 1+1" >/dev/null 2>&1
check "--app PAKET"                         'grep -q "calculator.md" "$W/claude.log"'
# 7) Auftrag per Dialog
: > "$W/claude.log"; setstate com.sec.android.app.popupcalculator
$M >/dev/null 2>&1
check "Auftrag aus dem Dialog"              'grep -q "rechne 7+8" "$W/claude.log"'
# 8) ADB nicht verbunden
setstate com.sec.android.app.popupcalculator; out=$(FAKE_FAIL=1 $M "rechne 2+2" 2>&1); rc=$?
check "ADB fehlt: klare Meldung"            '[ $rc -eq 1 ] && echo "$out" | grep -q "ADB nicht verbunden"'
# 9) Benachrichtigung mit START-Knopf
: > "$W/termux.log"; "$HANDY_DIR/scripts/panel.sh" idle
check "panel idle: START-Knopf"             'grep -q "START" "$W/termux.log" && grep -q "Handy-Start.sh" "$W/termux.log"'
rm -rf "$W"; [ $fail -eq 0 ] && echo "Alle Tests bestanden" || { echo "Tests fehlgeschlagen"; exit 1; }
