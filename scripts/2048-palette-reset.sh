#!/data/data/com.termux/files/usr/bin/bash
# Löscht die gelernten Farben großer Kacheln (ab 256). Sie werden im nächsten Lauf aus der Vorhersage neu gelernt.
# Nötig, wenn eine Farbe falsch gespeichert wurde (z. B. 32 als 1024 erkannt).
python3 - "$HOME/handy/state/2048-calib.json" <<'PY'
import json, sys
p = sys.argv[1]
c = json.load(open(p))
pal = c.get("palette", {})
gone = [k for k in list(pal) if int(k) >= 256]
for k in gone:
    pal.pop(k)
json.dump(c, open(p, "w"))
print("Gelöscht:", ", ".join(gone) or "nichts")
PY
rm -f "$HOME/handy/state/2048-last.json"
