#!/usr/bin/env python3
"""2048 komplett lokal spielen: Brett aus den Pixelfarben lesen, Solver entscheidet, swipe.sh wischt. Kein Modell nötig.

  play2048.py calibrate [--board X1 Y1 X2 Y2] [--values "2 0 0 0/0 4 0 0/0 0 0 0/0 0 0 2"]
      Findet das Brett (ohne --board automatisch über die Hintergrundfarbe), speichert es und zeigt das gelesene Brett.
      Mit --values (das Brett, wie es auf dem Bildschirm steht) werden die Farben dieser Zahlen nachgelernt;
      dabei wird das schon gefundene Brett wiederverwendet. Die automatische Suche braucht freie Felder in allen Zeilen
      und Spalten, also am besten direkt nach einem neuen Spiel.
  play2048.py read            Brett einmal lesen und ausgeben
  play2048.py probe           Diagnose: große einfarbige Flächen mit Farbe und Position
  play2048.py cells [--board X1 Y1 X2 Y2]   Diagnose: Farbe jedes Feldes und nächster Palettenwert
  play2048.py play N [--settle 0.35]   N Züge spielen (nach jedem Zug wird das Brett neu gelesen und neu geplant)
Voraussetzung: Handy zeigt 2048 im Vordergrund. Wischen läuft über swipe.sh (App-Sperre, STOP-Datei, Schrittlimit gelten).
"""
import json, os, struct, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import solve2048 as S

HANDY = os.environ.get("HANDY_DIR", os.path.expanduser("~/handy"))
CALIB = os.path.join(HANDY, "state", "2048-calib.json")
SWIPE = os.environ.get("SWIPE_SCRIPT", os.path.join(os.path.dirname(os.path.abspath(__file__)), "swipe.sh"))
KEY = os.path.join(os.path.dirname(SWIPE), "key.sh")
BOARD_BG = (187, 173, 160)
PALETTE = {0: (205, 193, 180), 2: (238, 228, 218), 4: (237, 224, 200), 8: (242, 177, 121), 16: (245, 149, 99),
           32: (246, 124, 95), 64: (246, 94, 59), 128: (237, 207, 114), 256: (237, 204, 97), 512: (237, 200, 80),
           1024: (237, 197, 63), 2048: (237, 194, 46), 4096: (60, 58, 50)}

class Unclear(Exception):
    pass

def grab():
    f = os.environ.get("FRAME_FILE")
    if f:
        data = open(f, "rb").read()
    else:
        try:
            r = subprocess.run(["adb", "exec-out", "screencap"], capture_output=True)
        except FileNotFoundError:
            raise Unclear("adb nicht gefunden (pkg install android-tools)")
        if r.returncode != 0 or len(r.stdout) < 16:
            msg = (r.stderr.decode(errors="replace").strip() or "kein Bild erhalten")[:120]
            raise Unclear(f"ADB liefert kein Bild ({msg}). Verbindung prüfen: adb devices; ggf. Wireless debugging einschalten und adb connect IP:PORT")
        data = r.stdout
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

def components(fr, tol=6, min_pts=150, neighbor=False):
    """Zusammenhängende einfarbige Flächen (grobes Raster). neighbor=True vergleicht mit dem Nachbarpunkt
    (verträgt sanfte Farbverläufe), sonst mit dem Startpunkt der Fläche."""
    _, w, h, _ = fr
    step = 6
    gw, gh = w // step, h // step
    grid = [[px(fr, gx * step + 3, gy * step + 3) for gx in range(gw)] for gy in range(gh)]
    seen, comps = [[False] * gw for _ in range(gh)], []
    for gy in range(gh):
        for gx in range(gw):
            if seen[gy][gx]:
                continue
            seed, stack, xs, ys, cols = grid[gy][gx], [(gx, gy)], [], [], []
            seen[gy][gx] = True
            while stack:
                cx, cy = stack.pop(); xs.append(cx); ys.append(cy); cols.append(grid[cy][cx])
                ref = grid[cy][cx] if neighbor else seed
                for nx, ny in ((cx+1, cy), (cx-1, cy), (cx, cy+1), (cx, cy-1)):
                    if 0 <= nx < gw and 0 <= ny < gh and not seen[ny][nx] and dist(grid[ny][nx], ref) < tol:
                        seen[ny][nx] = True; stack.append((nx, ny))
            if len(xs) >= min_pts:
                mid = tuple(sorted(c[i] for c in cols)[len(cols) // 2] for i in range(3))
                comps.append((len(xs), mid, (min(xs) * step, min(ys) * step, (max(xs) + 1) * step, (max(ys) + 1) * step)))
    comps.sort(key=lambda c: -c[0])
    return comps

def cluster(vals, tol=14):
    out = []
    for v in sorted(vals):
        if out and v - out[-1][-1] <= tol:
            out[-1].append(v)
        else:
            out.append([v])
    return [sum(c) / len(c) for c in out]

def find_board_by_cells(fr):
    """Leere Felder sind gleich große, gleichfarbige Quadrate in einem 4x4-Raster."""
    squares = []
    for n, col, (a, b, c, d) in components(fr, tol=9, min_pts=120, neighbor=True):
        wd, ht = c - a, d - b
        if 80 <= wd <= 420 and 0.85 <= wd / ht <= 1.18:
            squares.append((col, a, b, c, d))
    best = []
    for col, a, b, c, d in squares:
        grp = [q for q in squares if dist(q[0], col) < 14 and abs((q[3] - q[1]) - (c - a)) <= 0.1 * (c - a)]
        if len(grp) > len(best):
            best = grp
    if len(best) < 4:
        raise Unclear("Brett nicht gefunden (zu wenige leere Felder erkennbar). Neues Spiel starten und erneut versuchen.")
    size = sorted(q[3] - q[1] for q in best)[len(best) // 2]
    lefts, tops = cluster([q[1] for q in best]), cluster([q[2] for q in best])
    if len(lefts) < 2 or len(tops) < 2:
        raise Unclear("Brett nicht eindeutig (nur eine Spalte oder Zeile leer). Neues Spiel starten.")
    pitch_x = min(lefts[i + 1] - lefts[i] for i in range(len(lefts) - 1))
    pitch_y = min(tops[i + 1] - tops[i] for i in range(len(tops) - 1))
    pitch = (pitch_x + pitch_y) / 2
    ncols = round((lefts[-1] - lefts[0]) / pitch) + 1
    nrows = round((tops[-1] - tops[0]) / pitch) + 1
    if ncols != 4 or nrows != 4:
        raise Unclear(f"Brett nicht eindeutig ({ncols} Spalten, {nrows} Zeilen sichtbar). Neues Spiel starten.")
    x1 = lefts[0] - (pitch - size) / 2
    y1 = tops[0] - (pitch - size) / 2
    return (int(x1), int(y1), int(x1 + 4 * pitch), int(y1 + 4 * pitch))

def find_board(fr):
    """Erst die klassische Hintergrundfarbe, sonst über die leeren Felder (andere Designs)."""
    _, w, h, _ = fr
    for n, col, (a, b, c, d) in components(fr, tol=10, min_pts=300):
        if dist(col, BOARD_BG) < 12 and (c - a) >= 0.6 * w and 0.85 <= (c - a) / (d - b) <= 1.15:
            return (a, b, c, d)
    return find_board_by_cells(fr)

def load():
    """Gibt (Brett, Proben, Referenz-Hintergrundfarbe) zurück. Eingebaute klassische Palette nur, solange nichts gelernt wurde."""
    cal = json.load(open(CALIB)) if os.path.exists(CALIB) else {}
    learned = cal.get("palette", {})
    if not learned:
        return cal.get("board"), [(v, rgb) for v, rgb in PALETTE.items()], (BOARD_BG if not cal.get("gap_ref") else tuple(cal["gap_ref"]))
    samples = []
    for k, v in learned.items():
        for rgb in (v if v and isinstance(v[0], list) else [v]):
            samples.append((int(k), tuple(rgb)))
    return cal.get("board"), samples, (tuple(cal["gap_ref"]) if cal.get("gap_ref") else None)

def classify(col, samples):
    return min(((v, dist(col, rgb)) for v, rgb in samples), key=lambda t: t[1])

def save_samples(new):
    """new: Liste von (Wert, Farbe). Wird in die Kalibrierdatei geschrieben (ohne nahezu gleiche Doppel)."""
    cal = json.load(open(CALIB)) if os.path.exists(CALIB) else {}
    pal = cal.setdefault("palette", {})
    for v, rgb in new:
        cur = pal.get(str(v), [])
        cur = cur if cur and isinstance(cur[0], list) else ([cur] if cur else [])
        if not any(dist(tuple(c), rgb) < 3 for c in cur):
            cur.append(list(rgb))
        pal[str(v)] = cur
    os.makedirs(os.path.dirname(CALIB), exist_ok=True)
    json.dump(cal, open(CALIB, "w"))

def cell_color(fr, rect, r, c):
    x1, y1, x2, y2 = rect
    cw, ch = (x2 - x1) / 4, (y2 - y1) / 4
    return med(fr, x1 + (c + 0.5) * cw - 0.30 * cw, y1 + (r + 0.5) * ch - 0.30 * ch)

def gap_at(fr, rect, r, c):
    """Hintergrundstreifen zwischen den Feldern im Inneren des Bretts (rechts vom Feld, bei Spalte 3 links davon):
    bekommt denselben Lichtschein wie das Feld und liegt bei jeder Art der Brettsuche an derselben Stelle."""
    x1, y1, x2, y2 = rect
    k = c + 1 if c < 3 else 3
    return med(fr, x1 + k * (x2 - x1) / 4, y1 + (r + 0.5) * (y2 - y1) / 4, r=1)

def gap_median(fr, rect):
    gs = [gap_at(fr, rect, r, c) for r in range(4) for c in range(4)]
    return tuple(sorted(g[i] for g in gs)[len(gs) // 2] for i in range(3))

def norm_color(fr, rect, r, c, gap_ref):
    """Feldfarbe abzüglich des lokalen Unterschieds im Hintergrundstreifen (entfernt Lichtschein und Verläufe)."""
    col = cell_color(fr, rect, r, c)
    if gap_ref is None:
        return col
    g = gap_at(fr, rect, r, c)
    return tuple(max(0, min(255, col[k] - (g[k] - gap_ref[k]))) for k in range(3))

def read_cells(fr, rect, pal, gap_ref=None):
    """Gibt (Werte mit None für unbekannte Farben, gemessene Farben) zurück."""
    vals, cols = [], []
    for r in range(4):
        for c in range(4):
            col = norm_color(fr, rect, r, c, gap_ref)
            v, d = classify(col, pal)
            vals.append(v if d <= 14 else None)
            cols.append(col)
    return vals, cols

def infer_new_tile(vals, cols, pal):
    """Eine bisher nie gesehene Kachelfarbe ist fast sicher der nächsthöhere Wert (2 x größter bekannter Wert):
    Höhere Steine entstehen nur durch Verschmelzen der bisher größten. Nur wenn alle unbekannten Felder dieselbe Farbe haben.
    Die Probe wird ergänzt und gespeichert; die Vorhersageprüfung im Spiel fängt Irrtümer ab."""
    unknown = [i for i, v in enumerate(vals) if v is None]
    try:
        learned = json.load(open(CALIB)).get("palette")
    except (OSError, ValueError):
        learned = None
    if not learned:
        return False        # nur mit selbst gelernter Palette (die eingebaute enthält Werte, die nie gesehen wurden)
    known = [v for v in {v for v, _ in pal} if v]
    if not unknown or not known or len(unknown) > 2 or len(unknown) > 16 - 10:
        return False        # viele unbekannte Felder = Schleier, Werbung o. ä., kein neuer Stein
    if any(dist(cols[i], cols[unknown[0]]) > 8 for i in unknown):
        return False
    new = 2 * max(known)
    if new > 8192 or any(2 ** k not in known for k in range(1, new.bit_length() - 1)):
        return False        # Lücke in den bekannten Werten: nicht raten
    pal.append((new, cols[unknown[0]]))
    save_samples([(new, cols[unknown[0]])])
    print(f"Neue Kachelfarbe {cols[unknown[0]]}: als {new} angenommen", flush=True)
    return True

def read_board(fr, rect, pal, gap_ref=None):
    vals, cols = read_cells(fr, rect, pal, gap_ref)
    if None in vals and infer_new_tile(vals, cols, pal):
        vals, cols = read_cells(fr, rect, pal, gap_ref)
    bad = [(i // 4, i % 4, cols[i]) for i, v in enumerate(vals) if v is None]
    if bad:
        raise Unclear("Farben nicht erkannt (Spiel vorbei, Anzeige verdeckt oder 2048 nicht im Vordergrund?): "
                      + ", ".join(f"Z{r+1}S{c+1}={col}" for r, c, col in bad[:4]))
    return tuple(vals)

def near(col, v, samples):
    ds = [dist(col, rgb) for val, rgb in samples if val == v]
    return min(ds) if ds else None

def check(cols, expected, samples, allow_spawn):
    """Passt das Bild zum erwarteten Brett? Gibt (ok, Brett mit neuem Stein, neue Proben) zurück.
    Nur ein einziger neuer Stein (2 oder 4) in einem leeren Feld ist erlaubt, und nur wenn allow_spawn gesetzt ist."""
    spawn, learned, out = None, [], list(expected)
    for i, e in enumerate(expected):
        col = cols[i]
        d0 = near(col, 0, samples)
        is_empty = d0 is not None and d0 <= 14
        if e == 0:
            if is_empty:
                continue
            if not allow_spawn or spawn is not None:
                return False, None, []
            spawn = i
            continue
        if is_empty:
            return False, None, []
        d = near(col, e, samples)
        if d is None:
            learned.append((e, col))          # Wert noch nie gesehen: Farbe aus der Vorhersage lernen
            continue
        vb, db = classify(col, samples)
        if d > 22 or (vb != e and db + 6 < d):
            return False, None, []
    if spawn is not None:
        col = cols[spawn]
        d2, d4 = near(col, 2, samples), near(col, 4, samples)
        if d2 is not None and d4 is not None:
            val = 2 if d2 <= d4 else 4
        elif d2 is not None:
            val = 2 if d2 <= 7 else 4
        elif d4 is not None:
            val = 4 if d4 <= 7 else 2
        else:
            return False, None, []
        out[spawn] = val
        learned.append((val, col))
    return True, tuple(out), learned

def explain(cols, expected, samples):
    """Welche Felder passen nicht zur Vorhersage (für die Fehlersuche)?"""
    out = []
    for i, e in enumerate(expected):
        v, d = classify(cols[i], samples)
        de = near(cols[i], e, samples)
        if v != e or (de is not None and de > 14):
            out.append(f"Z{i // 4 + 1}S{i % 4 + 1}: erwartet {e}, gemessen {cols[i]}, nächster Wert {v} (Abstand {d:.0f})")
    return out[:6]

def fmt(b):
    return "/".join(" ".join(str(v) for v in b[i * 4:(i + 1) * 4]) for i in range(4))

def cmd_calibrate(args):
    fr = grab()
    cal = json.load(open(CALIB)) if os.path.exists(CALIB) else {}
    reuse = "--values" in args and cal.get("board") and "--board" not in args
    if "--board" in args:
        i = args.index("--board"); rect = tuple(int(x) for x in args[i + 1:i + 5])
    elif reuse:
        rect = tuple(cal["board"])      # bereits gefundenes Brett wiederverwenden (später fehlen freie Felder zum Suchen)
    else:
        rect = find_board(fr)
    cal["board"] = list(rect)
    if not reuse or not cal.get("gap_ref"):
        cal["gap_ref"] = list(gap_median(fr, rect))
    os.makedirs(os.path.dirname(CALIB), exist_ok=True)
    json.dump(cal, open(CALIB, "w"))
    if "--values" in args:
        i = args.index("--values") + 1
        toks = []
        while i < len(args) and not args[i].startswith("--"):
            toks.append(args[i]); i += 1
        known = S.parse(" ".join(toks))     # auch ohne Anführungszeichen: die Wörter werden wieder zusammengesetzt
        ref = tuple(cal["gap_ref"])
        save_samples([(v, norm_color(fr, rect, i // 4, i % 4, ref)) for i, v in enumerate(known)])
    print(f"Brett: {rect}")
    _, pal, ref = load()
    try:
        print("Gelesen:", fmt(read_board(fr, rect, pal, ref)))
    except Unclear as e:
        print("Noch unklar:", e)
    return 0

def cmd_probe(_):
    """Gibt die größten einfarbigen Flächen des Bildschirms aus."""
    fr = grab()
    _, w, h, _ = fr
    print(f"Bild {w}x{h}; große einfarbige Flächen (Farbe, Rahmen, Größe, Anzahl Rasterpunkte):")
    for n, col, (a, b, c, d) in components(fr)[:30]:
        print(f"  {col} rahmen=({a},{b},{c},{d}) größe={c-a}x{d-b} punkte={n}")
    return 0

def cmd_cells(args):
    """Farbe jedes der 16 Felder mit nächstem Palettenwert (zur Diagnose)."""
    rect, pal, ref = load()
    fr = grab()
    if "--board" in args:
        i = args.index("--board"); rect = tuple(int(x) for x in args[i + 1:i + 5])
    rect = rect or find_board(fr)
    print(f"Brett: {rect}")
    for r in range(4):
        parts = []
        for c in range(4):
            col = norm_color(fr, rect, r, c, ref)
            v, d = classify(col, pal)
            parts.append(f"{col}→{v}({d:.0f})")
        print("  " + "  ".join(parts))
    return 0

def cmd_read(_):
    rect, pal, ref = load()
    fr = grab()
    rect = rect or find_board(fr)
    print(fmt(read_board(fr, rect, pal, ref)))
    return 0

def prepare(rect, pal, ref):
    """Startet ohne Handarbeit: Brett und Hintergrundfarbe frisch bestimmen, kurz auf Einblendanimation warten
    und bei einem frischen Spiel (nur 1-2 unbekannte Steine, Rest leer) diese als 2 anlernen (nur im Speicher;
    die Vorhersageprüfung im Spiel fängt eine Fehlannahme ab)."""
    fr = grab()
    try:
        rect = find_board(fr)
    except Unclear:
        if not rect:
            raise
    ref = gap_median(fr, rect)
    for _ in range(4):
        fr = grab()
        vals, cols = read_cells(fr, rect, pal, ref)
        if None not in vals:
            return rect, pal, ref
        time.sleep(0.5)
    unknown = [i for i, v in enumerate(vals) if v is None]
    empties = sum(1 for v in vals if v == 0)
    if len(unknown) <= 2 and empties >= 16 - 2 - 0 and len(unknown) + empties == 16:
        print("Neue Farben: frisches Spiel erkannt, lerne unbekannte Steine als 2")
        pal = pal + [(2, cols[i]) for i in unknown]
        return rect, pal, ref
    return rect, pal, ref

def cmd_play(args):
    n = int(args[0]) if args and args[0].isdigit() else 20
    settle = float(args[args.index("--settle") + 1]) if "--settle" in args else 0.35
    limit = float(args[args.index("--seconds") + 1]) if "--seconds" in args else None   # Zeitlimit statt Zugzahl
    if limit:
        n = 10**9
    rect, pal, ref = load()
    rect, pal, ref = prepare(rect, pal, ref)
    x1, y1, x2, y2 = rect
    cx, cy, d = (x1 + x2) // 2, (y1 + y2) // 2, int((x2 - x1) * 0.3)
    env = dict(os.environ); env.setdefault("MAX_STEPS", str(n + 10)); env.setdefault("HANDY_NO_WAKE", "1")
    tm = {"Wischen": 0.0, "Warten": 0.0, "Bild+Prüfen": 0.0, "Rechnen": 0.0}
    score = done = stuck = 0
    halted = False
    last_cols = last_pred = None
    folge = []
    back_used = 0
    t0 = time.time()
    board = read_board(grab(), rect, pal, ref)
    while done < n and not (limit and time.time() - t0 >= limit):
        t = time.time(); seq = S.plan(board, 1); tm["Rechnen"] += time.time() - t
        if not seq:
            print("SPIEL VORBEI (kein Zug mehr möglich)"); break
        for dname in seq:
            if done >= n or (limit and time.time() - t0 >= limit):
                break
            x1s, y1s, x2s, y2s = {"left": (cx + d, cy, cx - d, cy), "right": (cx - d, cy, cx + d, cy),
                                  "up": (cx, cy + d, cx, cy - d), "down": (cx, cy - d, cx, cy + d)}[dname]
            t = time.time(); r = subprocess.run([SWIPE, str(x1s), str(y1s), str(x2s), str(y2s), "150"], env=env); tm["Wischen"] += time.time() - t
            if r.returncode != 0:
                print(f"ABBRUCH: swipe.sh endete mit Code {r.returncode}"); return r.returncode
            done += 1
            folge.append(dname[0].upper())
            _, g, _ = S.move(board, dname)
            t = time.time(); time.sleep(settle); tm["Warten"] += time.time() - t
            t = time.time()
            pred = S.move(board, dname)[0]
            new, err = None, None
            for _round in range(3):          # nach einem Fehlschlag: bis zu 2x Zurück-Taste (Werbung), dann erneut prüfen
                for attempt in range(3):
                    try:
                        fr = grab()
                        cols = [norm_color(fr, rect, i // 4, i % 4, ref) for i in range(16)]
                    except Unclear as e:
                        err = e; time.sleep(0.5); continue
                    ok, nb, learned = check(cols, pred, pal, True)
                    if ok:
                        new = nb
                        new_samples = [(v, c) for v, c in learned if not any(abs(v - w) == 0 and dist(c, rgb) < 3 for w, rgb in pal)]
                        if new_samples:
                            save_samples(new_samples); pal = load()[1]
                            print("Neu gelernt:", ", ".join(f"{v}={c}" for v, c in new_samples), flush=True)
                        stuck = 0; score += g
                        break
                    ok0, _, _ = check(cols, board, pal, False)
                    if ok0:                    # Wisch ohne Wirkung: Brett unverändert
                        new = board; stuck += 1
                        if stuck >= 3:
                            print("STOPP: Brett ändert sich nicht (festgefahren oder falsch gelesen)"); halted = True
                        break
                    last_cols, last_pred = cols, pred
                    err = Unclear("Bild passt weder zum erwarteten noch zum alten Brett (Animation, Werbung oder verdeckt?)")
                    time.sleep(0.5)
                if new is not None or back_used >= 2:
                    break
                back_used += 1
                print("Bild passt nicht (Werbung?): drücke Zurück und prüfe erneut", flush=True)
                subprocess.run([KEY, "back"], env=env, capture_output=True)
                time.sleep(1.5)
            tm["Bild+Prüfen"] += time.time() - t
            if new is None:
                print(f"STOPP: {err}")
                if last_cols is not None:
                    for line in explain(last_cols, last_pred, pal):
                        print("  ", line)
                    print("   Erwartetes Brett:", fmt(last_pred))
                halted = True; break
            board = new
            if halted:
                break
            break
        if halted:
            break
    secs = time.time() - t0
    print(f"Züge: {done}, geschätzter Punktestand: {score}, größte Kachel: {max(board)}, Dauer: {secs:.0f}s ({secs/max(done,1):.1f}s pro Zug)")
    print("Zeit pro Zug: " + ", ".join(f"{k} {v / max(done, 1):.2f}s" for k, v in tm.items()))
    print("Brett:", fmt(board))
    print("Folge:", " ".join(folge), "  (L links, R rechts, U oben, D unten)")
    return 0

def main(argv):
    if len(argv) < 2 or argv[1] not in ("calibrate", "read", "play", "probe", "cells"):
        print(__doc__); return 2
    try:
        return {"calibrate": cmd_calibrate, "read": cmd_read, "play": cmd_play, "probe": cmd_probe, "cells": cmd_cells}[argv[1]](argv[2:])
    except Unclear as e:
        print(f"UNKLAR: {e}", file=sys.stderr); return 3
    except ValueError as e:
        print(f"Eingabefehler: {e}. Beispiel: --values \"0 0 0 0/0 0 2 0/0 0 0 2/0 0 0 0\"", file=sys.stderr); return 2

if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv))
    except BrokenPipeError:
        sys.exit(0)
