#!/usr/bin/env python3
"""Nachgebautes Handy für Tests: rendert ein 2048-Brett als Rohbild und verarbeitet Wischen. Nur für Tests."""
import json, os, random, struct, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "scripts"))
import solve2048 as S, play2048 as P

STATE = os.environ.get("FAKE_STATE", "/tmp/claude-0/fp/state.json")
W, H = 1080, 2340
BOARD = (50, 600, 1030, 1580)
HEADER16 = os.environ.get("FAKE_HDR16") == "1"

def load():
    return json.load(open(STATE))

def save(st):
    json.dump(st, open(STATE, "w"))

def fill(data, x1, y1, x2, y2, rgb):
    row = bytes((rgb[0], rgb[1], rgb[2], 255)) * (x2 - x1)
    for y in range(y1, y2):
        o = (y * W + x1) * 4
        data[o:o + len(row)] = row

def render(st):
    data = bytearray(bytes((250, 248, 239, 255)) * (W * H))
    fill(data, 700, 200, 1000, 300, P.BOARD_BG)           # Punktefeld, gleiche Farbe wie das Brett, aber kleiner
    x1, y1, x2, y2 = BOARD
    fill(data, x1, y1, x2, y2, P.BOARD_BG)
    cw = (x2 - x1) / 4
    gap = 28
    for i, v in enumerate(st["board"]):
        r, c = divmod(i, 4)
        tx1, ty1 = int(x1 + c * cw + gap / 2), int(y1 + r * cw + gap / 2)
        tx2, ty2 = int(x1 + (c + 1) * cw - gap / 2), int(y1 + (r + 1) * cw - gap / 2)
        fill(data, tx1, ty1, tx2, ty2, P.PALETTE.get(v, (60, 58, 50)))
        if v:   # "Ziffer" in der Mitte, damit die Abtastung abseits der Mitte getestet wird
            mx, my = (tx1 + tx2) // 2, (ty1 + ty2) // 2
            fill(data, mx - 40, my - 30, mx + 40, my + 30, (119, 110, 101))
    if st.get("over"):    # halbtransparentes Weiß über dem Brett wie bei "Game over"
        for y in range(y1, y2, 1):
            o = (y * W + x1) * 4
            seg = bytearray(data[o:o + (x2 - x1) * 4])
            for k in range(0, len(seg), 4):
                seg[k] = (seg[k] + 255) // 2; seg[k+1] = (seg[k+1] + 255) // 2; seg[k+2] = (seg[k+2] + 255) // 2
            data[o:o + len(seg)] = seg
    hdr = struct.pack("<III", W, H, 1) + (struct.pack("<I", 0) if HEADER16 else b"")
    return hdr + bytes(data)

def spawn(b):
    e = [i for i, v in enumerate(b) if v == 0]
    if not e:
        return b
    i = random.choice(e)
    return b[:i] + (2 if random.random() < 0.9 else 4,) + b[i + 1:]

def main(a):
    if os.environ.get("FAKE_FAIL") == "1":
        print("error: no devices/emulators found", file=sys.stderr); return 1
    st = load()
    if a[:2] == ["exec-out", "screencap"]:
        sys.stdout.buffer.write(render(st)); return 0
    if a[:2] == ["shell", "dumpsys"]:
        print(f"  mCurrentFocus=Window{{1 u0 {st.get('fg', 'com.gabrielecirulli.app2048')}/x.Y}}"); return 0
    if a[:3] == ["shell", "input", "swipe"]:
        x1, y1, x2, y2 = (int(v) for v in a[3:7])
        dx, dy = x2 - x1, y2 - y1
        d = ("right" if dx > 0 else "left") if abs(dx) > abs(dy) else ("down" if dy > 0 else "up")
        nb, g, moved = S.move(tuple(st["board"]), d)
        if moved:
            nb = spawn(nb); st["score"] += g
            if not any(S.move(nb, dd)[2] for dd in S.DIRS):
                st["over"] = True
            st["board"] = list(nb); save(st)
        return 0
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
