#!/usr/bin/env python3
"""Simulation: wie gut spielt der Solver bei verschiedenen Kettenlängen (blind gespielte Züge)?"""
import random, statistics, sys, time
sys.path.insert(0, "scripts")
import solve2048 as S

def spawn(board, rng):
    empties = [i for i, v in enumerate(board) if v == 0]
    if not empties:
        return board
    i = rng.choice(empties)
    return board[:i] + (2 if rng.random() < 0.9 else 4,) + board[i + 1:]

def new_board(rng):
    return spawn(spawn(tuple([0] * 16), rng), rng)

def play(strategy, moves, rng, k=1):
    board, score, used = new_board(rng), 0, 0
    while used < moves:
        if strategy == "alt":                       # Claudes bisheriges Muster: links, unten, links, unten …
            seq = ["left", "down"] * 4
        else:
            seq = S.plan(board, k)
            if not seq:
                break
        for d in seq[:k if strategy != "alt" else 4]:
            if used >= moves:
                break
            used += 1
            nb, g, moved = S.move(board, d)
            if moved:                               # ohne Wirkung: kein Spawn, Zug verloren
                board, score = spawn(nb, rng), score + g
    return score, max(board)

def run(label, strategy, moves, n, k=1, seed=1):
    rng = random.Random(seed); t = time.time()
    res = [play(strategy, moves, rng, k) for _ in range(n)]
    sc = [r[0] for r in res]
    print(f"{label:34s} Ø {statistics.mean(sc):7.1f}  Median {statistics.median(sc):6.0f}  "
          f"größter Stein Ø {statistics.mean(r[1] for r in res):6.0f}   ({time.time()-t:4.1f}s)")

if __name__ == "__main__":
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 100
    print(f"== 20 Züge, {n} Spiele")
    run("links/unten abwechselnd (bisher)", "alt", 20, n)
    for k in (1, 2, 3, 4, 6):
        run(f"Solver, {k} Züge blind pro Kette", "solver", 20, n, k)
