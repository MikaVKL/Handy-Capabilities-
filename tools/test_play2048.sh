#!/bin/bash
# Test des lokalen 2048-Spielers gegen ein nachgebautes Handy (tools/fake_adb.py). Lauf: bash tools/test_play2048.sh
R="$(cd "$(dirname "$0")/.." && pwd)"; W=$(mktemp -d); mkdir -p "$W/bin" "$W/handy/state" "$W/scripts"
printf '#!/bin/bash\nexec python3 %s/tools/fake_adb.py "$@"\n' "$R" > "$W/bin/adb"; chmod +x "$W/bin/adb"
cp "$R"/scripts/*.sh "$R"/scripts/*.py "$W/scripts/"; sed -i '1s|.*|#!/bin/bash|' "$W"/scripts/*.sh
export PATH="$W/bin:$PATH" HANDY_DIR="$W/handy" FAKE_STATE="$W/state.json"; P="python3 $W/scripts/play2048.py"
echo com.gabrielecirulli.app2048 > "$HANDY_DIR/allowed-apps.txt"; fail=0
check() { if eval "$2"; then echo "OK   $1"; else echo "FAIL $1"; fail=1; fi; }
init() { python3 - "$1" <<'PY'
import json, random, sys
random.seed(int(sys.argv[1])); b=[0]*16
for v in (2,2): b[random.choice([i for i in range(16) if b[i]==0])]=v
import os; json.dump({"board":b,"score":0,"over":False}, open(os.environ["FAKE_STATE"],"w"))
PY
}
truth() { python3 -c "import json,os;b=json.load(open(os.environ['FAKE_STATE']))['board'];print('/'.join(' '.join(map(str,b[i*4:i*4+4])) for i in range(4)))"; }
init 3; $P calibrate >/dev/null
check "Lesen = wahres Brett"            '[ "$($P read)" = "$(truth)" ]'
check "16-Byte-Kopf des Rohbilds"       '[ "$(FAKE_HDR16=1 $P read)" = "$(truth)" ]'
out=$($P play 40 --settle 0); sc=$(python3 -c "import json,os;print(json.load(open(os.environ['FAKE_STATE']))['score'])")
check "40 Züge, Punktestand stimmt"     'echo "$out" | grep -q "Züge: 40, geschätzter Punktestand: $sc,"'
check "Protokoll zählt die Züge"        '[ "$(grep -c swipe "$HANDY_DIR/state/log.txt")" -eq 40 ]'
python3 - <<'PY'
import json, os
json.dump({"board":[2,4,2,4,4,2,4,2,2,4,2,4,4,2,4,2],"score":0,"over":False}, open(os.environ["FAKE_STATE"],"w"))
PY
rm -f "$HANDY_DIR/state/steps"
check "Spielende wird erkannt"          '$P play 5 --settle 0 | grep -q "SPIEL VORBEI"'
python3 - <<'PY'
import json, os
json.dump({"board":[2,4,2,4,4,2,4,2,2,4,2,4,4,2,4,8],"score":0,"over":True}, open(os.environ["FAKE_STATE"],"w"))
PY
check "Game-over-Schleier gibt UNKLAR"  '$P read 2>&1 | grep -q UNKLAR'
init 5; python3 - <<'PY'
import json, os
s=json.load(open(os.environ["FAKE_STATE"])); s["fg"]="com.android.chrome"; json.dump(s,open(os.environ["FAKE_STATE"],"w"))
PY
rm -f "$HANDY_DIR/state/steps"
check "Falsche App: swipe.sh sperrt"    '$P play 3 --settle 0 2>&1 | grep -q "nicht freigegeben"'
python3 - <<'PY'
import struct; w,h=1080,2340
open("/tmp/claude-0/white.raw","wb").write(struct.pack("<III",w,h,1)+bytes((250,248,239,255))*(w*h))
PY
check "Kein 2048 sichtbar (mit Kalibrierung)" 'FRAME_FILE=/tmp/claude-0/white.raw $P read 2>&1 | grep -q "UNKLAR"'
rm -f "$HANDY_DIR/state/2048-calib.json"
check "Kein 2048 sichtbar (ohne Kalibrierung)" 'FRAME_FILE=/tmp/claude-0/white.raw $P read 2>&1 | grep -q "nicht gefunden"'
check "probe listet Flächen"          '$P probe | grep -q "rahmen=" && $P probe | head -n 3 | grep -q "(187, 173, 160)"'
check "ADB nicht verbunden: lesbare Meldung" 'out=$(FAKE_FAIL=1 $P read 2>&1); echo "$out" | grep -q "ADB liefert kein Bild" && ! echo "$out" | grep -q Traceback'
init 8; rm -f "$HANDY_DIR/state/steps"
check "Abbruch: Zugzähler zählt nur echte Züge" 'out=$(FAKE_OVER_AFTER=3 $P play 30 --settle 0 2>&1); echo "$out" | grep -q "STOPP" && echo "$out" | grep -q "Züge: 3,"'
check "Abbruch: nennt abweichende Felder"      'echo "$out" | grep -q "erwartet"'
# --- Dunkles Design mit Lichtschein (ähnlich der echten App) ---
export FAKE_THEME=dark; rm -f "$HANDY_DIR/state/2048-calib.json" "$HANDY_DIR/state/steps"
python3 - <<'PY'
import json, os
json.dump({"board":[0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,2],"score":0,"over":False}, open(os.environ["FAKE_STATE"],"w"))
PY
check "dunkel: Brett automatisch gefunden" '$P calibrate | grep -q "^Brett: (5"'
python3 - <<'PY'
import json, os
json.dump({"board":[16,2,64,2,2,128,32,8,0,0,2,4,2,0,0,2],"score":0,"over":False}, open(os.environ["FAKE_STATE"],"w"))
PY
$P calibrate --values "$(truth)" >/dev/null
check "dunkel: Lesen nach Nachlernen"  '[ "$($P read)" = "$(truth)" ]'
init 4; rm -f "$HANDY_DIR/state/steps"
out=$($P play 50 --settle 0); sc=$(python3 -c "import json,os;print(json.load(open(os.environ['FAKE_STATE']))['score'])")
check "dunkel: 50 Züge, Punktestand stimmt" 'echo "$out" | grep -q "Züge: 50, geschätzter Punktestand: $sc,"'
init 7
check "--values auch ohne Anführungszeichen" 'rm -f "$HANDY_DIR/state/2048-calib.json"; $P calibrate >/dev/null; $P calibrate --values 0 0 0 0/0 0 0 0/0 0 0 0/2 2 0 0 | grep -q "Brett:"'
check "--values: verständlicher Eingabefehler" '$P calibrate --values "1 2 3" 2>&1 | grep -q "Eingabefehler"'
# Nur das Startbrett ist bekannt, alle weiteren Farben lernt das Skript beim Spielen selbst
init 6; rm -f "$HANDY_DIR/state/2048-calib.json" "$HANDY_DIR/state/steps"
$P calibrate >/dev/null; $P calibrate --values "$(truth)" >/dev/null
out=$($P play 100 --settle 0 2>&1); sc=$(python3 -c "import json,os;print(json.load(open(os.environ['FAKE_STATE']))['score'])")
check "dunkel: lernt neue Farben selbst (100 Züge)" 'echo "$out" | grep -q "Züge: 100, geschätzter Punktestand: $sc," && echo "$out" | grep -q "Neu gelernt"'
unset FAKE_THEME
rm -rf "$W"; [ $fail -eq 0 ] && echo "Alle Tests bestanden" || { echo "Tests fehlgeschlagen"; exit 1; }
