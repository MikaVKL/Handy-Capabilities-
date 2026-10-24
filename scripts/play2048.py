#!/usr/bin/env python3
"""2048 komplett lokal spielen: Brett aus den Pixelfarben lesen, Solver entscheidet, swipe.sh wischt. Kein Modell nötig.

  play2048.py calibrate [--board X1 Y1 X2 Y2] [--values "2 0 0 0/0 4 0 0/0 0 0 0/0 0 0 2"]
      Findet das Brett (ohne --board automatisch über die Hintergrundfarbe), speichert es und zeigt das gelesene Brett.
      Mit --values (das Brett, wie es auf dem Bildschirm steht) werden die Farben dieser Zahlen nachgelernt.
  play2048.py read            Brett einmal lesen und ausgeben
  play2048.py play N [--settle 0.35]   N Züge spielen (nach jedem Zug wird das Brett neu gelesen und neu geplant)
Voraussetzung: Handy zeigt 2048 im Vordergrund. Wischen läuft über swipe.sh (App-Sperre, STOP-Datei, Schrittlimit gelten).
"""
import json, os, struct, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import solve2048 as S

HANDY = os.environ.get("HANDY_DIR", os.path.expanduser("~/handy"))
CALIB = os.path.join(HANDY, "state", "2048-calib.json")
SWIPE = os.environ.get("SWIPE_SCRIPT", os.path.join(os.path.dirname(os.path.abspath(__file__)), "swipe.sh"))
BOARD_BG = (187, 173, 160)
PALETTE = {0: (205, 193, 180), 2: (238, 228, 218), 4: (237, 224, 200), 8: (242, 177, 121), 16: (245, 149, 99),
           32: (246, 124, 95), 64: (246, 94, 59), 128: (237, 207, 114), 256: (237, 204, 97), 512: (237, 200, 80),
           1024: (237, 197, 63), 2048: (237, 194, 46), 4096: (60, 58, 50)}

class Unclear(Exception):
    pass

def grab():
    f = os.environ.get("FRAME_FILE")
    data = open(f, "rb").read() if f else subprocess.run(["adb", "exec-out", "screencap"], capture_output=True, check=True).stdout
    w, h = struct.unpack("<II", data[:8])
    hdr = len(data) - w * h * 4
    if hdr not in (12, 16):
        raise Unclear(f"Rohbild hat unerwartete Größe (Kopf {hdr} Byte)")
    return data, w, h, hdr

def px(fr, x, y):
    data, w, h, hdr = fr
    x, y = max(0, min(w - 1, int(x))), max(0, min(h - 1, int(y)))
    o = hdr + (y * w + x) * 4
    return data[o], data[o + 1], data[o + 2]

def med(fr, x, y, r=2):
    pts = [px(fr, x + dx * 2, y + dy * 2) for dx in range(-r, r + 1) for dy in range(-r, r + 1)]
    return tuple(sorted(p[i] for p in pts)[len(pts) // 2] for i in range(3))

def dist(a, b):
    return sum((x - y) ** 2 for x, y in zip(a, b)) ** 0.5

def find_board(fr):
    """Größte zusammenhängende Fläche in der Brett-Hintergrundfarbe (grobes Raster, Flutfüllung)."""
    _, w, h, _ = fr
    step = 6
    gw, gh = w // step, h // step
    mask = [[dist(px(fr, gx * step, gy * step), BOARD_BG) < 10 for gx in range(gw)] for gy in range(gh)]
    seen, best = set(), (0, None)
    for gy in range(gh):
        for gx in range(gw):
            if mask[gy][gx] and (gx, gy) not in seen:
                stack, cells = [(gx, gy)], []
                seen.add((gx, gy))
                while stack:
                    cx, cy = stack.pop(); cells.append((cx, cy))
                    for nx, ny in ((cx+1, cy), (cx-1, cy), (cx, cy+1), (cx, cy-1)):
                        if 0 <= nx < gw and 0 <= ny < gh and mask[ny][nx] and (nx, ny) not in seen:
                            seen.add((nx, ny)); stack.append((nx, ny))
                if len(cells) > best[0]:
                    xs, ys = [c[0] for c in cells], [c[1] for c in cells]
                    best = (len(cells), (min(xs) * step, min(ys) * step, (max(xs) + 1) * step, (max(ys) + 1) * step))
    if not best[1]:
        raise Unclear("Brett nicht gefunden (Hintergrundfarbe nicht erkannt). Zeigt das Handy 2048?")
    return best[1]

def load():
    cal = json.load(open(CALIB)) if os.path.exists(CALIB) else {}
    pal = dict(PALETTE)
    for k, v in cal.get("palette", {}).items():
        pal[int(k)] = tuple(v)
    return cal.get("board"), pal

def cell_color(fr, rect, r, c):
    x1, y1, x2, y2 = rect
    cw, ch = (x2 - x1) / 4, (y2 - y1) / 4
    return med(fr, x1 + (c + 0.5) * cw - 0.30 * cw, y1 + (r + 0.5) * ch - 0.30 * ch)

def read_board(fr, rect, pal):
    vals, bad = [], []
    for r in range(4):
        for c in range(4):
            col = cell_color(fr, rect, r, c)
            v, d = min(((val, dist(col, rgb)) for val, rgb in pal.items()), key=lambda t: t[1])
            if d > 14:
                bad.append((r, c, col)); v = None
            vals.append(v)
    if bad:
        raise Unclear("Farben nicht erkannt (Spiel vorbei, Anzeige verdeckt oder 2048 nicht im Vordergrund?): " + ", ".join(f"Z{r+1}S{c+1}={col}" for r, c, col in bad[:4]))
    return tuple(vals)

def fmt(b):
    return "/".join(" ".join(str(v) for v in b[i * 4:(i + 1) * 4]) for i in range(4))

def cmd_calibrate(args):
    fr = grab()
    if "--board" in args:
        i = args.index("--board"); rect = tuple(int(x) for x in args[i + 1:i + 5])
    else:
        rect = find_board(fr)
    cal = json.load(open(CALIB)) if os.path.exists(CALIB) else {}
    cal["board"] = list(rect)
    if "--values" in args:
        known = S.parse(args[args.index("--values") + 1])
        pal = cal.setdefault("palette", {})
        for i, v in enumerate(known):
            pal[str(v)] = list(cell_color(fr, rect, i // 4, i % 4))
    os.makedirs(os.path.dirname(CALIB), exist_ok=True)
    json.dump(cal, open(CALIB, "w"))
    print(f"Brett: {rect}")
    _, pal = load()
    try:
        print("Gelesen:", fmt(read_board(fr, rect, pal)))
    except Unclear as e:
        print("Noch unklar:", e)
    return 0

def cmd_read(_):
    rect, pal = load()
    fr = grab()
    rect = rect or find_board(fr)
    print(fmt(read_board(fr, rect, pal)))
    return 0

def cmd_play(args):
    n = int(args[0]) if args and args[0].isdigit() else 20
    settle = float(args[args.index("--settle") + 1]) if "--settle" in args else 0.35
    rect, pal = load()
    if not rect:
        rect = find_board(grab())
    x1, y1, x2, y2 = rect
    cx, cy, d = (x1 + x2) // 2, (y1 + y2) // 2, int((x2 - x1) * 0.3)
    env = dict(os.environ); env.setdefault("MAX_STEPS", str(n + 10))
    score = done = stuck = 0
    t0 = time.time()
    board = read_board(grab(), rect, pal)
    while done < n:
        seq = S.plan(board, 1)
        if not seq:
            print("SPIEL VORBEI (kein Zug mehr möglich)"); break
        for dname in seq:
            if done >= n:
                break
            x1s, y1s, x2s, y2s = {"left": (cx + d, cy, cx - d, cy), "right": (cx - d, cy, cx + d, cy),
                                  "up": (cx, cy + d, cx, cy - d), "down": (cx, cy - d, cx, cy + d)}[dname]
            r = subprocess.run([SWIPE, str(x1s), str(y1s), str(x2s), str(y2s), "150"], env=env)
            if r.returncode != 0:
                print(f"ABBRUCH: swipe.sh endete mit Code {r.returncode}"); return r.returncode
            done += 1
            _, g, _ = S.move(board, dname)
            time.sleep(settle)
            try:
                new = read_board(grab(), rect, pal)
            except Unclear as e:
                time.sleep(0.5)
                try:
                    new = read_board(grab(), rect, pal)
                except Unclear as e2:
                    print(f"STOPP: {e2}"); done = n; break
            if new == board:
                stuck += 1
                time.sleep(0.4)
                new = read_board(grab(), rect, pal)
                if new == board and stuck >= 3:
                    print("STOPP: Brett ändert sich nicht (festgefahren oder falsch gelesen)"); done = n; break
            else:
                stuck = 0; score += g
            board = new
            break
    secs = time.time() - t0
    print(f"Züge: {done}, geschätzter Punktestand: {score}, größte Kachel: {max(board)}, Dauer: {secs:.0f}s ({secs/max(done,1):.1f}s pro Zug)")
    print("Brett:", fmt(board))
    return 0

def main(argv):
    if len(argv) < 2 or argv[1] not in ("calibrate", "read", "play"):
        print(__doc__); return 2
    try:
        return {"calibrate": cmd_calibrate, "read": cmd_read, "play": cmd_play}[argv[1]](argv[2:])
    except Unclear as e:
        print(f"UNKLAR: {e}", file=sys.stderr); return 3

if __name__ == "__main__":
    sys.exit(main(sys.argv))
