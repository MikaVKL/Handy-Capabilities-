#!/usr/bin/env python3
"""Fehlersuche: spielt gegen die Attrappe im selben Prozess und meldet den ersten Schritt, an dem das Lesen danebenliegt."""
import json, os, random, sys, tempfile
os.environ.setdefault("FAKE_STATE", tempfile.mkdtemp() + "/state.json")
os.environ["HANDY_DIR"] = tempfile.mkdtemp()
sys.path.insert(0, "scripts"); sys.path.insert(0, "tools")
import fake_adb as F, play2048 as P, solve2048 as S

def run(seed, moves=150, theme="dark"):
    random.seed(seed)
    F.DARK = theme == "dark"
    b = [0] * 16
    for v in (2, 2):
        b[random.choice([i for i in range(16) if b[i] == 0])] = v
    st = {"board": b, "score": 0, "over": False}
    F.save(st)
    fr = (F.render(st), F.W, F.H, 12)
    rect = P.find_board(fr)
    ref = P.gap_median(fr, rect)
    json.dump({"board": list(rect), "gap_ref": list(ref)}, open(P.CALIB, "w")) if os.path.isdir(os.path.dirname(P.CALIB)) else (os.makedirs(os.path.dirname(P.CALIB)), json.dump({"board": list(rect), "gap_ref": list(ref)}, open(P.CALIB, "w")))
    P.save_samples([(v, P.norm_color(fr, rect, i // 4, i % 4, ref)) for i, v in enumerate(b)])
    _, pal, ref = P.load()
    board = tuple(b)
    for n in range(1, moves + 1):
        seq = S.plan(board, 1)
        if not seq:
            return f"Spiel vorbei nach {n-1} Zügen"
        d = seq[0]
        pred = S.move(board, d)[0]
        nb, g, moved = S.move(tuple(st["board"]), d)
        nb = F.spawn(nb); st["board"] = list(nb); st["score"] += g
        F.save(st)
        fr = (F.render(st), F.W, F.H, 12)
        cols = [P.norm_color(fr, rect, i // 4, i % 4, ref) for i in range(16)]
        ok, new, learned = P.check(cols, pred, pal, True)
        if not ok or new != tuple(st["board"]):
            bad = [i for i in range(16) if (new or pred)[i] != st["board"][i]]
            info = [(i, st["board"][i], cols[i], P.classify(cols[i], pal)) for i in bad[:3]] if bad else []
            return f"Zug {n} ({d}): ok={ok}, gleich={new == tuple(st['board'])}; abweichend: {info}"
        new_samples = [(v, c) for v, c in learned if not any(w == v and P.dist(c, rgb) < 3 for w, rgb in pal)]
        if new_samples:
            P.save_samples(new_samples); pal = P.load()[1]
        board = new
    return f"{moves} Züge fehlerfrei, Punkte {st['score']}, Proben je Wert: { {v: sum(1 for w, _ in pal if w == v) for v in sorted({w for w, _ in pal})} }"

if __name__ == "__main__":
    theme = sys.argv[1] if len(sys.argv) > 1 else "dark"
    for seed in range(1, int(sys.argv[2]) + 1 if len(sys.argv) > 2 else 5):
        print(f"Seed {seed}: {run(seed, theme=theme)}")
