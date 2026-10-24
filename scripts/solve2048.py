#!/usr/bin/env python3
"""2048-Zugwahl per Expectimax. Claude liest nur das Brett, dieses Skript entscheidet.

Nutzung:
  solve2048.py "2 0 0 0/0 4 0 0/0 0 0 0/0 0 0 2" [N] [--act CX CY D]
Brett: 4 Zeilen mit je 4 Zahlen (0 = leer), Zeilen durch / getrennt, oben beginnend.
Ausgabe: die nächsten N Züge (Standard 3) als Wörter (left right up down), eine Zeile.
Mit --act werden stattdessen fertige batch.sh-Aktionen ausgegeben (Wisch ab Mittelpunkt CX CY, Strecke D px).
Die Folgezüge werden ohne neuen Zufallsstein geplant; deshalb kurze Ketten und danach neu lesen.
"""
import sys
from functools import lru_cache

DIRS = ("left", "right", "up", "down")

def slide_row(row):
    tiles = [v for v in row if v]
    out, gained, i = [], 0, 0
    while i < len(tiles):
        if i + 1 < len(tiles) and tiles[i] == tiles[i + 1]:
            out.append(tiles[i] * 2); gained += tiles[i] * 2; i += 2
        else:
            out.append(tiles[i]); i += 1
    return tuple(out + [0] * (4 - len(out))), gained

@lru_cache(maxsize=None)
def slide_left(row):
    return slide_row(row)

def move(board, d):
    rows = [board[i * 4:(i + 1) * 4] for i in range(4)]
    if d in ("up", "down"):
        rows = [tuple(rows[r][c] for r in range(4)) for c in range(4)]
    if d in ("right", "down"):
        rows = [r[::-1] for r in rows]
    new, gained = [], 0
    for r in rows:
        nr, g = slide_left(r); new.append(nr); gained += g
    if d in ("right", "down"):
        new = [r[::-1] for r in new]
    if d in ("up", "down"):
        new = [tuple(new[r][c] for r in range(4)) for c in range(4)]
    flat = tuple(v for r in new for v in r)
    return flat, gained, flat != board

# Schlangen-Gewichte: der größte Stein soll unten links liegen, die Folge fällt schlangenförmig ab
SNAKE = (0, 1, 2, 3, 7, 6, 5, 4, 8, 9, 10, 11, 15, 14, 13, 12)  # Rang je Feld, 15 = unten links (beste Ecke)
WEIGHTS = tuple(4.0 ** (r / 3.0) for r in SNAKE)

def evaluate(board):
    score = sum(v * w for v, w in zip(board, WEIGHTS))
    empty = board.count(0)
    return score * (1 + 0.1 * empty)

def expect(board, depth):
    empties = [i for i, v in enumerate(board) if v == 0]
    if not empties:
        return evaluate(board)
    if len(empties) > 4:
        empties = empties[:: max(1, len(empties) // 4)][:4]
    total = 0.0
    for i in empties:
        for val, p in ((2, 0.9), (4, 0.1)):
            b = board[:i] + (val,) + board[i + 1:]
            total += p * best_value(b, depth - 1)
    return total / len(empties)

def best_value(board, depth):
    if depth <= 0:
        return evaluate(board)
    best = -1.0
    for d in DIRS:
        nb, _, moved = move(board, d)
        if moved:
            best = max(best, expect(nb, depth))
    return best if best >= 0 else evaluate(board) * 0.01

def best_move(board, depth=2):
    best, best_d = -1.0, None
    for d in DIRS:
        nb, _, moved = move(board, d)
        if not moved:
            continue
        v = expect(nb, depth)
        if v > best:
            best, best_d = v, d
    return best_d

def plan(board, n, depth=2):
    seq = []
    for _ in range(n):
        d = best_move(board, depth)
        if d is None:
            break
        seq.append(d)
        board, _, _ = move(board, d)  # ohne neuen Stein
    return seq

def parse(text):
    rows = [r.split() for r in text.strip().split("/")]
    if len(rows) != 4 or any(len(r) != 4 for r in rows):
        raise ValueError("Brett braucht 4 Zeilen mit je 4 Zahlen")
    vals = [int(x) for r in rows for x in r]
    for v in vals:
        if v and (v & (v - 1)):
            raise ValueError(f"{v} ist keine Zweierpotenz")
    return tuple(vals)

def act(d, cx, cy, dist):
    x1, y1, x2, y2 = {
        "left": (cx + dist, cy, cx - dist, cy), "right": (cx - dist, cy, cx + dist, cy),
        "up": (cx, cy + dist, cx, cy - dist), "down": (cx, cy - dist, cx, cy + dist)}[d]
    return f'"swipe-check {x1} {y1} {x2} {y2} 150"'

def main(argv):
    if len(argv) < 2:
        print(__doc__); return 2
    try:
        board = parse(argv[1])
    except ValueError as e:
        print(f"Fehler: {e}", file=sys.stderr); return 2
    rest = argv[2:]
    n = 3
    if rest and rest[0].isdigit():
        n = int(rest[0]); rest = rest[1:]
    seq = plan(board, n)
    if not seq:
        print("KEIN ZUG MÖGLICH (Spiel vorbei?)"); return 3
    if rest and rest[0] == "--act" and len(rest) >= 4:
        cx, cy, dist = map(int, rest[1:4])
        print(" ".join(act(d, cx, cy, dist) for d in seq))
    else:
        print(" ".join(seq))
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
