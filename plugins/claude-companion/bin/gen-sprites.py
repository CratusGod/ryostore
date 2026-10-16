#!/usr/bin/env python3
"""Draw the Claude Companion sprite sheets.

Dev-time tool, not run by the plugin. The companion is an original ten-ray
spark with a small face; every frame is rasterised from the same geometry
(rays modulated by a travelling wave, a breathing core, a few overlays), so
all nine animations stay consistent. Writes:

  assets/sprites.png            plain sheet (cells of W x H, COLS per row)
  assets/season-<id>.png        the same frames wearing a seasonal accessory
  assets/particles.png          small sprites used by the season effects
  content/SpriteDefs.qml        animation metadata read by content/PixelSprite.qml
  content/SeasonDefs.qml        particle metadata read by content/SeasonFx.qml
  <dir>/contact-*.png           4x contact sheets for review (--preview DIR)

The design is deliberately its own: a warm-orange spark in the spirit of the
Claude mark, not a copy of it.

Needs python-pillow.  Usage: bin/gen-sprites.py [--preview DIR]
"""
import math
import os
import sys
from PIL import Image, ImageDraw

W, H = 48, 48          # one frame cell
COLS = 10
CX, CY = 24, 27        # spark centre
N_RAYS = 12
# per-ray length from the centre, irregular on purpose (hand-drawn feel)
RAY_LEN = [17.5, 14.0, 16.5, 13.0, 17.5, 14.5, 16.5, 13.0, 17.5, 14.0, 16.0, 13.5]
CORE_R = 8.6

PAL = {
    "O": (0x3a, 0x1d, 0x12),   # outline
    "B": (0xd9, 0x77, 0x57),   # body
    "b": (0xb2, 0x58, 0x3c),   # body shade
    "l": (0xf0, 0x9a, 0x7a),   # body light
    "E": (0x2a, 0x14, 0x0c),   # eye
    "G": (0xff, 0xf1, 0xe6),   # glint / cheek highlight
    "K": (0xf2, 0x9b, 0xa2),   # blush
    "Y": (0xf6, 0xd3, 0x6b),   # sparkle yellow
    "y": (0xe8, 0xa9, 0x3a),   # sparkle deep
    "R": (0xd9, 0x4a, 0x3f),   # alert red
    "D": (0x6f, 0xb4, 0xe8),   # sweat drop
    "Z": (0xcf, 0xd8, 0xe6),   # zzz / bubble
    "z": (0x8f, 0x9b, 0xb0),   # bubble shade
    "W": (0xf7, 0xf2, 0xea),   # white
    "w": (0xd8, 0xd2, 0xca),   # white shade
    "r": (0xd2, 0x2f, 0x2f),   # santa red
    "q": (0xa3, 0x1f, 0x24),   # santa red shade
    "P": (0x5b, 0x3a, 0x8c),   # witch purple
    "p": (0x3f, 0x27, 0x66),   # witch purple shade
    "N": (0xe8, 0x7a, 0x1e),   # halloween orange
    "k": (0x1a, 0x1a, 0x22),   # sunglasses black
    "s": (0x7a, 0xd0, 0xe6),   # sunglasses sheen
    "F": (0xf2, 0x7f, 0xb0),   # flower pink
    "f": (0xc9, 0x55, 0x86),   # flower pink shade
    "g": (0x6a, 0xb0, 0x5a),   # leaf green
    "h": (0x45, 0x86, 0x3d),   # leaf green shade
    "M": (0xd9, 0xa2, 0x38),   # mustard
    "m": (0xa8, 0x75, 0x1c),   # mustard shade
    "T": (0x8a, 0x4a, 0x2a),   # brown
    "u": (0xc0, 0x4b, 0x26),   # autumn red
}


def col(key):
    return PAL[key] + (255,)


# ── geometry ──────────────────────────────────────────────────────────────────

def angdiff(a, b):
    d = (a - b + math.pi) % (2 * math.pi) - math.pi
    return d


def body(scale=1.0, core=1.0, dx=0, dy=0, amp=0.0, phase=0.0, rot=0.0, flush=0.0):
    """Rasterise the spark. Returns (image, (cx, cy, coreRadius))."""
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = img.load()
    cx, cy = CX + dx, CY + dy
    rc = CORE_R * core
    rays = []
    for i in range(N_RAYS):
        length = RAY_LEN[i] * scale * (1.0 + amp * math.sin(phase - i * 2 * math.pi / N_RAYS))
        rays.append((math.radians(-75 + 30 * i + rot), length))
    filled = [[False] * W for _ in range(H)]
    for y in range(H):
        for x in range(W):
            ddx, ddy = x + 0.5 - cx, y + 0.5 - cy
            r = math.hypot(ddx, ddy)
            inside = r <= rc
            if not inside:
                th = math.atan2(ddy, ddx)
                for a, length in rays:
                    if length <= rc:
                        continue
                    d = abs(angdiff(th, a))
                    if d >= math.pi / 2:
                        continue
                    lat, along = r * math.sin(d), r * math.cos(d)
                    if along > length:
                        continue
                    t = min(1.0, along / length)
                    hw = 2.6 - 1.2 * t
                    if along > length - hw:
                        lim = math.sqrt(max(0.0, hw * hw - (along - (length - hw)) ** 2))
                    else:
                        lim = hw
                    if lim > 0 and lat <= lim:
                        inside = True
                        break
            filled[y][x] = inside
            if inside:
                proj = ddx * 0.55 + ddy * 0.83
                if proj > 4.2:
                    c = "b"
                elif proj < -6.0:
                    c = "l"
                else:
                    c = "B"
                px[x, y] = col(c)
    outline(img, filled)
    if flush > 0:   # error: a red flush on the body
        for y in range(H):
            for x in range(W):
                if filled[y][x]:
                    r_, g_, b_, a_ = px[x, y]
                    px[x, y] = (min(255, int(r_ + 28 * flush)), int(g_ * (1 - 0.18 * flush)),
                                int(b_ * (1 - 0.18 * flush)), a_)
    return img, (cx, cy, rc)


def outline(img, filled):
    px = img.load()
    for y in range(H):
        for x in range(W):
            if filled[y][x]:
                continue
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if 0 <= nx < W and 0 <= ny < H and filled[ny][nx]:
                    px[x, y] = col("O")
                    break


def put(img, x, y, key):
    x, y = int(round(x)), int(round(y))
    if 0 <= x < W and 0 <= y < H:
        img.putpixel((x, y), col(key))


def stamp(img, grid, ox, oy, outlined=False):
    """Draw an ASCII sprite at (ox, oy); '.' is transparent."""
    layer = [[None] * W for _ in range(H)]
    for j, row in enumerate(grid):
        for i, ch in enumerate(row):
            if ch != ".":
                layer[oy + j][ox + i] = ch if 0 <= ox + i < W and 0 <= oy + j < H else None
    if outlined:
        for y in range(H):
            for x in range(W):
                if layer[y][x] is None:
                    for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                        if 0 <= nx < W and 0 <= ny < H and layer[ny][nx] is not None:
                            img.putpixel((x, y), col("O"))
                            break
    for y in range(H):
        for x in range(W):
            if layer[y][x] is not None:
                img.putpixel((x, y), col(layer[y][x]))


# ── face ──────────────────────────────────────────────────────────────────────
# Eyes sit on the core: left x = cx-4..cx-2, right x = cx+2..cx+4, y around cy-2.

def eyes(img, cx, cy, kind="open", dx=0, dy=0):
    ex = [cx - 5 + dx, cx + 3 + dx]
    y0 = cy - 4 + dy
    for x in ex:
        if kind == "open":
            for yy in range(5):
                put(img, x, y0 + yy, "E"); put(img, x + 1, y0 + yy, "E")
            put(img, x, y0, "G")
        elif kind == "narrow":          # focused
            for yy in range(1, 5):
                put(img, x, y0 + yy, "E"); put(img, x + 1, y0 + yy, "E")
        elif kind == "wide":
            for yy in range(6):
                put(img, x - 1, y0 - 1 + yy, "E"); put(img, x, y0 - 1 + yy, "E"); put(img, x + 1, y0 - 1 + yy, "E")
            put(img, x - 1, y0 - 1, "G"); put(img, x, y0 - 1, "G")
        elif kind == "blink":
            put(img, x, y0 + 2, "E"); put(img, x + 1, y0 + 2, "E"); put(img, x + 2, y0 + 2, "E")
        elif kind == "closed":          # a gentle downward arc
            put(img, x, y0 + 1, "E"); put(img, x + 1, y0 + 2, "E"); put(img, x + 2, y0 + 1, "E")
        elif kind == "half":
            put(img, x, y0 + 1, "E"); put(img, x + 1, y0 + 1, "E")
            put(img, x, y0 + 2, "E"); put(img, x + 1, y0 + 2, "E")
        elif kind == "happy":           # ^ ^
            put(img, x, y0 + 2, "E"); put(img, x + 1, y0 + 1, "E"); put(img, x + 2, y0 + 2, "E")
        elif kind == "x":
            for k in range(3):
                put(img, x + k, y0 + k, "E"); put(img, x + 2 - k, y0 + k, "E")


def mouth(img, cx, cy, kind):
    if kind == "smile":
        for p in ((-2, 3), (-1, 4), (0, 4), (1, 3)):
            put(img, cx + p[0], cy + p[1], "E")
    elif kind == "frown":
        for p in ((-2, 4), (-1, 3), (0, 3), (1, 4)):
            put(img, cx + p[0], cy + p[1], "E")
    elif kind == "o":
        put(img, cx - 1, cy + 3, "E"); put(img, cx, cy + 3, "E")
        put(img, cx - 1, cy + 4, "E"); put(img, cx, cy + 4, "E")
    elif kind == "flat":
        put(img, cx - 1, cy + 4, "E"); put(img, cx, cy + 4, "E")


def blush(img, cx, cy):
    put(img, cx - 5, cy + 2, "K"); put(img, cx - 4, cy + 2, "K")
    put(img, cx + 3, cy + 2, "K"); put(img, cx + 4, cy + 2, "K")


# ── overlays ──────────────────────────────────────────────────────────────────

GLYPH = {
    "!": ["R", "R", "R", ".", "R"],
    "?": ["ZZ", "..Z", ".Z", ".", ".Z"],
}


def glyph(img, ch, x, y, key):
    rows = {"!": [(1, 1, 1, 0, 1)], }
    if ch == "!":
        for yy in range(3):
            put(img, x, y + yy, key); put(img, x + 1, y + yy, key)
        put(img, x, y + 4, key); put(img, x + 1, y + 4, key)
    elif ch == "?":
        for p in ((0, 0), (1, 0), (2, 1), (2, 2), (1, 3), (1, 5)):
            put(img, x + p[0], y + p[1], key)
        put(img, x + 1, y + 4, key) if False else None


def zzz(img, n, cx, cy):
    # three Zs rising up-right; n steps the group
    seq = [(cx + 8, cy - 12, 3), (cx + 12, cy - 17, 4), (cx + 15, cy - 23, 5)]
    shown = 1 + (n % 4) if n % 4 < 3 else 3
    for k in range(shown):
        x, y, s = seq[k]
        for i in range(s):
            put(img, x + i, y, "Z"); put(img, x + s - 1 - i, y + i, "Z"); put(img, x + i, y + s - 1, "Z")


def thought(img, n, cx, cy):
    # three dots growing toward a thought cloud, top right
    pts = [(cx + 12, cy - 8), (cx + 15, cy - 12), (cx + 18, cy - 17)]
    for k, (x, y) in enumerate(pts):
        if k <= n % 4:
            size = 1 if k == 0 else 2
            for i in range(size):
                for j in range(size):
                    put(img, x + i, y + j, "Z")
    if n % 4 == 3:
        for p in ((16, -22), (17, -22), (18, -22), (19, -22), (15, -21), (20, -21), (16, -20), (17, -20), (18, -20), (19, -20)):
            put(img, cx + p[0], cy + p[1], "Z")


def sparks(img, n, cx, cy, tips):
    # tiny sparks flying off the tips while it works
    for k, (tx, ty) in enumerate(tips):
        if (n + k) % 2 == 0:
            put(img, tx, ty, "Y")
            if (n + k) % 4 == 0:
                put(img, tx + (1 if tx > cx else -1), ty + (1 if ty > cy else -1), "y")


def sparkle(img, x, y, size=1, key="Y"):
    put(img, x, y, key)
    if size >= 1:
        for d in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            put(img, x + d[0], y + d[1], key)
    if size >= 2:
        for d in ((2, 0), (-2, 0), (0, 2), (0, -2)):
            put(img, x + d[0], y + d[1], "y")


def sweat(img, n, cx, cy):
    x, y = cx + 8, cy - 7 + (n % 3)
    put(img, x, y, "D"); put(img, x - 1, y + 1, "D"); put(img, x, y + 1, "D"); put(img, x + 1, y + 1, "D")
    put(img, x, y + 2, "D"); put(img, x - 1, y + 2, "D"); put(img, x + 1, y + 2, "D")


def ray_tips(cx, cy, scale, amp, phase, rot):
    out = []
    for i in range(N_RAYS):
        length = RAY_LEN[i] * scale * (1.0 + amp * math.sin(phase - i * 2 * math.pi / N_RAYS))
        a = math.radians(-75 + 30 * i + rot)
        out.append((cx + math.cos(a) * (length + 2), cy + math.sin(a) * (length + 2)))
    return out


# ── poses ─────────────────────────────────────────────────────────────────────
# Each pose function draws frame n of an animation and returns (image, anchor)
# where anchor = (cx, cy, coreRadius) so accessories can follow the body.

def f_idle(kind):
    pose = {
        "a": dict(scale=1.00, amp=0.03, phase=0.0),
        "b": dict(scale=1.03, amp=0.04, phase=1.0, dy=0),
        "c": dict(scale=1.06, amp=0.05, phase=2.0, dy=-1),
        "blink": dict(scale=1.00, amp=0.03, phase=0.0),
        "look": dict(scale=1.02, amp=0.04, phase=1.5),
    }[kind]
    img, anc = body(**pose)
    cx, cy, _ = anc
    eyes(img, cx, cy, {"blink": "blink"}.get(kind, "open"), dx=1 if kind == "look" else 0)
    return img, anc


def f_sleep(n):
    s = [0.52, 0.55, 0.58, 0.55][n % 4]
    img, anc = body(scale=s, core=0.97, dy=3, amp=0.02, phase=n)
    cx, cy, _ = anc
    eyes(img, cx, cy, "closed")
    zzz(img, n, cx, cy)
    return img, anc


def f_awake(n):
    P = [
        dict(scale=0.60, dy=3), dict(scale=0.78, dy=2), dict(scale=0.95, dy=1),
        dict(scale=1.14, dy=-2), dict(scale=1.00, dy=0), dict(scale=1.00, dy=0),
    ][n]
    img, anc = body(amp=0.03, phase=n, **P)
    cx, cy, _ = anc
    eyes(img, cx, cy, ["closed", "blink", "half", "wide", "open", "open"][n])
    if n == 3:
        for p in ((-14, -14), (14, -15), (-12, 6)):
            sparkle(img, cx + p[0], cy + p[1], 0)
    return img, anc


def f_think(n):
    ph = n / 6 * 2 * math.pi
    img, anc = body(scale=1.0, amp=0.20, phase=ph)
    cx, cy, _ = anc
    eyes(img, cx, cy, "open", dx=1, dy=-1)
    mouth(img, cx, cy, "flat")
    thought(img, n, cx, cy)
    return img, anc


def f_work(n):
    ph = n / 8 * 4 * math.pi
    rot = [0, 2, 0, -2, 0, 2, 0, -2][n]
    img, anc = body(scale=1.04, amp=0.24, phase=ph, rot=rot, dy=-1 if n % 2 else 0)
    cx, cy, _ = anc
    eyes(img, cx, cy, "narrow")
    sparks(img, n, cx, cy, ray_tips(cx, cy, 1.04, 0.24, ph, rot)[::3])
    return img, anc


def f_listen(n):
    img, anc = body(scale=[1.02, 1.04, 1.02, 1.0][n], amp=0.10, phase=[0.0, 1.2, 2.4, 3.6][n])
    cx, cy, _ = anc
    eyes(img, cx, cy, ["wide", "wide", "blink", "wide"][n], dy=0)
    if n in (0, 1, 3):
        glyph(img, "?", cx + 12, cy - 21, "Z")
    return img, anc


def f_success(n):
    P = [
        dict(scale=0.85, dy=2), dict(scale=1.15, dy=-3), dict(scale=1.30, dy=-4), dict(scale=1.18, dy=-2),
        dict(scale=1.08, dy=-1), dict(scale=1.02, dy=0), dict(scale=1.0, dy=0), dict(scale=1.0, dy=0),
    ][n]
    img, anc = body(amp=0.05, phase=n, **P)
    cx, cy, _ = anc
    eyes(img, cx, cy, "happy")
    mouth(img, cx, cy, "smile")
    blush(img, cx, cy)
    if n >= 1:
        rad = 3 + n * 2.2
        for k in range(8):
            a = math.radians(22 + k * 45 + n * 6)
            sparkle(img, cx + math.cos(a) * (rad + 12), cy + math.sin(a) * (rad + 10), 0, "Y" if k % 2 else "G")
    if n == 7:
        sparkle(img, cx + 14, cy - 15, 1)
    return img, anc


def f_error(n):
    sx = [0, -2, 2, -2, 2, 0][n]
    sc = [1.0, 0.95, 0.9, 0.85, 0.8, 0.78][n]
    img, anc = body(scale=sc, dx=sx, dy=[0, 0, 1, 1, 2, 2][n], amp=0.03, phase=n, flush=1.0)
    cx, cy, _ = anc
    eyes(img, cx, cy, "x")
    mouth(img, cx, cy, "frown")
    if n >= 2:
        sweat(img, n, cx, cy)
    return img, anc


def f_alert(n):
    j = [(0, 0), (1, 0), (-1, 0), (0, -1), (1, 0), (-1, 0)][n]
    img, anc = body(scale=1.0 + 0.06 * (n % 2), dx=j[0], dy=j[1], amp=0.10, phase=n * 1.4)
    cx, cy, _ = anc
    eyes(img, cx, cy, "wide")
    mouth(img, cx, cy, "o")
    glyph(img, "!", cx + 11, cy - 22, "R" if n % 2 == 0 else "Y")
    if n % 2 == 0:
        for tip in ray_tips(cx, cy, 1.0, 0.1, n * 1.4, 0)[1::3]:
            put(img, tip[0], tip[1], "R")
    return img, anc


# name -> (loop, [(frame_fn, arg, ms), ...])
def seqs():
    return {
        "idle": (True, [(f_idle, "a", 900), (f_idle, "b", 700), (f_idle, "c", 900), (f_idle, "b", 700),
                        (f_idle, "a", 1400), (f_idle, "blink", 130), (f_idle, "a", 1800),
                        (f_idle, "look", 700), (f_idle, "a", 1200)]),
        "sleeping": (True, [(f_sleep, k, 900) for k in range(4)]),
        "awake": (False, [(f_awake, k, ms) for k, ms in enumerate((260, 200, 160, 360, 300, 500))]),
        "thinking": (True, [(f_think, k, 500) for k in range(6)]),
        "working": (True, [(f_work, k, 110) for k in range(8)]),
        "listening": (True, [(f_listen, 0, 900), (f_listen, 1, 700), (f_listen, 2, 140), (f_listen, 3, 900)]),
        "success": (False, [(f_success, k, ms) for k, ms in enumerate((140, 90, 90, 160, 120, 100, 160, 700))]),
        "error": (False, [(f_error, k, ms) for k, ms in enumerate((260, 90, 90, 90, 90, 900))]),
        "alert": (True, [(f_alert, k, 110) for k in range(6)]),
    }


# ── seasonal accessories ─────────────────────────────────────────────────────
# Drawn after the body so they follow its bob/scale. `top` is the y of the core's
# top edge; accessories rest on it and overlap the ray bases.

SANTA_A = [
    "..........WWWW",
    ".........WWWWWW",
    ".......rrrWWWWW",
    "......rrrrrWWW.",
    ".....rrrrrr....",
    "....rqrrrrr....",
    "...rrrrqrrrr...",
    "..rrrrrrrrrrr..",
    ".WWWWWWWWWWWWW.",
    ".WwWWWWwWWWWwW.",
]
SANTA_B = [
    "...............",
    "..........WWWW.",
    ".........WWWWWW",
    ".......rrrWWWWW",
    "......rrrrrWWW.",
    ".....rrrrrr....",
    "....rqrrrrr....",
    "...rrrrqrrrr...",
    "..rrrrrrrrrrr..",
    ".WWWWWWWWWWWWW.",
]
WITCH = [
    "........PP.....",
    ".......PPP.....",
    "......PPPp.....",
    ".....PPPPp.....",
    ".....PPPPpp....",
    "....PPPPPPp....",
    "....NNyNNNN....",
    "...PPPPPPPPp...",
    "..PPPPPPPPPPp..",
    "pPPPPPPPPPPPPPp",
]
BEANIE = [
    "......TT.......",
    ".....TuuT......",
    "......TT.......",
    "....MMMMMMM....",
    "...MMMmMMMMM...",
    "..MMMMmMMMMMM..",
    "..mmmmmmmmmmm..",
    "..MMMMMMMMMMM..",
    ".mmmmmmmmmmmmm.",
    ".MmMmMmMmMmMmM.",
]
GLASSES = [
    ".kkkkk.kkkkk.",
    "kkskkkkkkskkk",
    "kkkkkk.kkkkkk",
    ".kkkk...kkkk.",
]


def accessory(img, season, anc, n, state):
    cx, cy, rc = anc
    top = int(round(cy - rc))
    if season == "christmas":
        g = SANTA_A if n % 2 == 0 else SANTA_B
        stamp(img, g, cx - 8, top - len(g) + 3, outlined=True)
    elif season == "halloween":
        stamp(img, WITCH, cx - 8, top - len(WITCH) + 3, outlined=True)
        # glowing eyes while it works / is alert
    elif season == "autumn":
        stamp(img, BEANIE, cx - 7, top - len(BEANIE) + 3, outlined=True)
    elif season == "summer":
        stamp(img, GLASSES, cx - 6, cy - 4, outlined=True)
        if n % 6 == 2:
            put(img, cx - 5, cy - 4, "W")
    elif season == "spring":
        # flower crown along the top of the core: leaves first, flowers on top
        for k in range(7):
            ang = math.radians(-165 + k * 25)
            x, y = cx + math.cos(ang) * (rc + 0.5), cy + math.sin(ang) * (rc + 0.5)
            put(img, x, y, "h"); put(img, x + 1, y, "g"); put(img, x, y + 1, "g")
        for k, ang in enumerate((-150, -115, -90, -65, -30)):
            a = math.radians(ang)
            x, y = int(round(cx + math.cos(a) * (rc + 0.5))), int(round(cy + math.sin(a) * (rc + 0.5)))
            petal, edge = ("F", "f") if k % 2 == 0 else ("W", "w")
            for d in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                put(img, x + d[0], y + d[1], petal)
            for d in ((2, 0), (-2, 0), (0, 2), (0, -2)):
                put(img, x + d[0], y + d[1], edge)
            put(img, x, y, "Y")


SEASONS = ["christmas", "halloween", "summer", "spring", "autumn"]


# ── particles (animated in QML by content/SeasonFx.qml) ──────────────────────

PARTICLES = {
    # id: list of frames, each an ASCII grid
    "snow": [[".W.", "WWW", ".W."], ["W.W", ".W.", "W.W"]],
    "bat": [
        ["N.....N", "NN...NN", ".NNONN.", "..NNN.."],
        ["...N...", ".NNONN.", "NN.N.NN", "N..N..N"],
    ],
    "petal": [["FF.", ".FF"], ["F..", "FFF"], [".F.", "FF."]],
    "leaf": [["u..", "uuu", ".uu"], [".uu", "uuu", "u.."], ["TT.", "TTT", ".T."]],
    "glint": [["...", ".Y.", "..."], [".Y.", "YWY", ".Y."], ["..Y..", "..Y..", "YYWYY", "..Y..", "..Y.."]],
    "sun": [
        ["..y..", ".yYy.", "yYYYy", ".yYy.", "..y.."],
        [".y.y.", "..Y..", "yYYYy", "..Y..", ".y.y."],
    ],
    "butterfly": [["F...F", "FF.FF", ".FKF.", ".F.F."], [".....", "F.K.F", ".FKF.", "F...F"]],
}

# season -> list of particle behaviours. kind: fall | fly | twinkle | bob
# coordinates are in sprite pixels of the 48 x 48 cell.
FX = {
    "christmas": [
        dict(p="snow", kind="fall", x=4, sway=2, dur=5200, delay=0),
        dict(p="snow", kind="fall", x=13, sway=3, dur=6800, delay=1400),
        dict(p="snow", kind="fall", x=22, sway=2, dur=5600, delay=3000),
        dict(p="snow", kind="fall", x=31, sway=3, dur=7200, delay=700),
        dict(p="snow", kind="fall", x=40, sway=2, dur=6000, delay=2200),
        dict(p="snow", kind="fall", x=45, sway=2, dur=6400, delay=4200),
    ],
    "halloween": [
        dict(p="bat", kind="fly", y=6, x0=-8, x1=52, dur=7000, delay=0, bob=3),
        dict(p="bat", kind="fly", y=14, x0=52, x1=-8, dur=9000, delay=3500, bob=2),
    ],
    "summer": [
        dict(p="sun", kind="bob", x=39, y=2, dur=1600),
        dict(p="glint", kind="twinkle", x=9, y=14, dur=1800, delay=0),
        dict(p="glint", kind="twinkle", x=38, y=30, dur=2200, delay=700),
        dict(p="glint", kind="twinkle", x=6, y=33, dur=2000, delay=1300),
    ],
    "spring": [
        dict(p="petal", kind="fall", x=6, sway=3, dur=6400, delay=0),
        dict(p="petal", kind="fall", x=17, sway=4, dur=7600, delay=2500),
        dict(p="petal", kind="fall", x=30, sway=3, dur=6800, delay=1200),
        dict(p="petal", kind="fall", x=41, sway=4, dur=8000, delay=3700),
        dict(p="butterfly", kind="fly", y=12, x0=-6, x1=52, dur=11000, delay=1500, bob=5),
    ],
    "autumn": [
        dict(p="leaf", kind="fall", x=5, sway=4, dur=6000, delay=0),
        dict(p="leaf", kind="fall", x=16, sway=3, dur=7400, delay=1800),
        dict(p="leaf", kind="fall", x=28, sway=4, dur=6600, delay=3200),
        dict(p="leaf", kind="fall", x=40, sway=3, dur=7800, delay=900),
    ],
}


def build_particles():
    gw = max(len(r) for frames in PARTICLES.values() for g in frames for r in g)
    gh = max(len(g) for frames in PARTICLES.values() for g in frames)
    cw, ch = gw + 1, gh + 1
    names = list(PARTICLES)
    maxf = max(len(v) for v in PARTICLES.values())
    img = Image.new("RGBA", (cw * maxf, ch * len(names)), (0, 0, 0, 0))
    meta = {}
    for row, name in enumerate(names):
        frames = PARTICLES[name]
        wmax = max(len(r) for g in frames for r in g)
        hmax = max(len(g) for g in frames)
        meta[name] = dict(w=wmax, h=hmax, frames=len(frames), row=row)
        for k, g in enumerate(frames):
            for j, r in enumerate(g):
                for i, c in enumerate(r):
                    if c != ".":
                        img.putpixel((k * cw + i, row * ch + j), col(c))
    return img, meta, cw, ch


# ── build ─────────────────────────────────────────────────────────────────────

def build(root, preview=None):
    sq = seqs()
    anims = {}
    sheet_frames = []          # list of (fn, arg) in cell order
    for name, (loop, frames) in sq.items():
        lst = []
        for fn, arg, ms in frames:
            key = (fn, arg)
            if key not in sheet_frames:
                sheet_frames.append(key)
            lst.append([sheet_frames.index(key), ms])
        anims[name] = dict(loop=loop, frames=lst)
    count = len(sheet_frames)
    rows = (count + COLS - 1) // COLS
    cells = {}
    for ci, (fn, arg) in enumerate(sheet_frames):
        cells[ci] = fn(arg)

    def sheet(season):
        out = Image.new("RGBA", (W * COLS, H * rows), (0, 0, 0, 0))
        for ci in range(count):
            img, anc = cells[ci]
            img = img.copy()
            if season:
                accessory(img, season, anc, sheet_frames[ci][1] if isinstance(sheet_frames[ci][1], int) else ci, "")
            out.paste(img, ((ci % COLS) * W, (ci // COLS) * H))
        return out

    os.makedirs(os.path.join(root, "assets"), exist_ok=True)
    sheet(None).save(os.path.join(root, "assets", "sprites.png"))
    for s in SEASONS:
        sheet(s).save(os.path.join(root, "assets", "season-%s.png" % s))
    pimg, pmeta, pcw, pch = build_particles()
    pimg.save(os.path.join(root, "assets", "particles.png"))
    write_defs(root, anims, count)
    write_season_defs(root, pmeta, pcw, pch)
    if preview:
        os.makedirs(preview, exist_ok=True)
        for s in [None] + SEASONS:
            contact(sheet(s), count, os.path.join(preview, "contact-%s.png" % (s or "plain")))
        pimg.resize((pimg.width * 8, pimg.height * 8), Image.NEAREST).save(os.path.join(preview, "contact-particles.png"))
    print("frames:", count, "sheet:", W * COLS, "x", H * rows)


def contact(sheet_img, count, path, zoom=4):
    cols = 10
    rows = (count + cols - 1) // cols
    bg = Image.new("RGBA", (cols * W * zoom, rows * H * zoom), (36, 34, 40, 255))
    for ci in range(count):
        cell = sheet_img.crop(((ci % COLS) * W, (ci // COLS) * H, (ci % COLS) * W + W, (ci // COLS) * H + H))
        cell = cell.resize((W * zoom, H * zoom), Image.NEAREST)
        bg.alpha_composite(cell, ((ci % cols) * W * zoom, (ci // cols) * H * zoom))
    bg.convert("RGB").save(path)


def write_defs(root, anims, count):
    lines = [
        "// Generated by bin/gen-sprites.py. Do not edit by hand.",
        "import QtQuick",
        "",
        "QtObject {",
        "    readonly property int cellW: %d" % W,
        "    readonly property int cellH: %d" % H,
        "    readonly property int cols: %d" % COLS,
        "    readonly property int frameCount: %d" % count,
        "    // name: { loop, frames: [[cellIndex, durationMs], ...] }",
        "    readonly property var anims: ({",
    ]
    items = []
    for name, a in anims.items():
        fr = ", ".join("[%d, %d]" % (c, ms) for c, ms in a["frames"])
        items.append("        %s: { loop: %s, frames: [%s] }" % (name, "true" if a["loop"] else "false", fr))
    lines.append(",\n".join(items))
    lines += ["    })", "}", ""]
    os.makedirs(os.path.join(root, "content"), exist_ok=True)
    with open(os.path.join(root, "content", "SpriteDefs.qml"), "w") as f:
        f.write("\n".join(lines))


def write_season_defs(root, pmeta, cw, ch):
    import json
    lines = [
        "// Generated by bin/gen-sprites.py. Do not edit by hand.",
        "import QtQuick",
        "",
        "QtObject {",
        "    readonly property int cellW: %d" % cw,
        "    readonly property int cellH: %d" % ch,
        "    readonly property var sprites: (%s)" % json.dumps(pmeta),
        "    readonly property var fx: (%s)" % json.dumps(FX),
        "}",
        "",
    ]
    with open(os.path.join(root, "content", "SeasonDefs.qml"), "w") as f:
        f.write("\n".join(lines))


if __name__ == "__main__":
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    prev = None
    if "--preview" in sys.argv:
        prev = sys.argv[sys.argv.index("--preview") + 1]
    build(root, prev)
