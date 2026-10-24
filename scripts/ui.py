#!/usr/bin/env python3
"""Liest einen uiautomator-Dump (XML) von stdin.
  ui.py list                -> kompakte Liste der Elemente mit Text/Beschreibung oder Klickbarkeit
  ui.py find TEXT [N]       -> Mitte "X Y" des N-ten Elements, dessen Text/Beschreibung TEXT enthält
"""
import re, sys
import xml.etree.ElementTree as ET

def load():
    data = sys.stdin.read()
    a, b = data.find("<?xml"), data.rfind("</hierarchy>")
    if a < 0 or b < 0:
        a = data.find("<hierarchy")
    if a < 0 or b < 0:
        return []
    root = ET.fromstring(data[a:b + len("</hierarchy>")])
    out = []
    for n in root.iter("node"):
        m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", n.get("bounds", ""))
        if not m:
            continue
        x1, y1, x2, y2 = map(int, m.groups())
        text, desc = n.get("text", ""), n.get("content-desc", "")
        click = n.get("clickable") == "true"
        if not (text or desc or click):
            continue
        out.append({"text": text, "desc": desc, "click": click, "cls": n.get("class", "").rsplit(".", 1)[-1],
                    "id": n.get("resource-id", "").rsplit("/", 1)[-1], "pkg": n.get("package", ""),
                    "cx": (x1 + x2) // 2, "cy": (y1 + y2) // 2, "w": x2 - x1, "h": y2 - y1})
    return out

def main(argv):
    els = load()
    cmd = argv[1] if len(argv) > 1 else "list"
    if cmd == "list":
        if not els:
            print("LEER: kein Textbaum (Spiel/Zeichenfläche oder gesperrte App) – Screenshot benutzen")
            return 3
        for i, e in enumerate(els[:80], 1):
            label = e["text"] or e["desc"] or e["id"] or e["cls"]
            flags = ("klickbar " if e["click"] else "") + e["cls"]
            print(f'[{i}] "{label}" ({flags}) @ {e["cx"]},{e["cy"]}')
        return 0
    if cmd == "find" and len(argv) > 2:
        needle, n = argv[2].lower(), int(argv[3]) if len(argv) > 3 and argv[3].isdigit() else 1
        exact = [e for e in els if needle in (e["text"].lower(), e["desc"].lower())]
        hits = exact or [e for e in els if needle in e["text"].lower() or needle in e["desc"].lower()]
        if len(hits) < n:
            print(f'NICHT GEFUNDEN: "{argv[2]}" ({len(hits)} Treffer)', file=sys.stderr)
            return 4
        print(f'{hits[n-1]["cx"]} {hits[n-1]["cy"]}')
        return 0
    print(__doc__, file=sys.stderr); return 2

if __name__ == "__main__":
    sys.exit(main(sys.argv))
