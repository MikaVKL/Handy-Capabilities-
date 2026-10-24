#!/usr/bin/env python3
"""Ganze Spiele (bis kein Zug mehr möglich ist) mit dem Solver, verschiedene Kettenlängen."""
import random, statistics, sys, time
sys.path.insert(0, "scripts"); sys.path.insert(0, "tools")
import sim2048 as M

k, n = int(sys.argv[1]), int(sys.argv[2])
rng = random.Random(7); t = time.time(); res = []
for i in range(n):
    board, score, moves = M.new_board(rng), 0, 0
    while moves < 3000:
        seq = M.S.plan(board, k)
        if not seq:
            break
        for d in seq:
            nb, g, moved = M.S.move(board, d)
            moves += 1
            if moved:
                board, score = M.spawn(nb, rng), score + g
    res.append((score, max(board), moves))
    print(f"k={k} Spiel {i+1}: Punkte {score}, größter Stein {max(board)}, Züge {moves}", flush=True)
print(f"k={k}: Ø Punkte {statistics.mean(r[0] for r in res):.0f}, größter Stein je Spiel {[r[1] for r in res]}, {time.time()-t:.0f}s")
