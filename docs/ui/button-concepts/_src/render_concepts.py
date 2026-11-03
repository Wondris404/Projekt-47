#!/usr/bin/env python3
"""Fáza 1 — procedurálne mockupy tlačidiel (Pillow + numpy). Žiadne prevzaté assety."""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
FONT_DIR = Path(__file__).resolve().parent / "fonts"
S = 2
PANEL = (0x20, 0x23, 0x28, 255)


def P(v: float) -> int:
    return int(round(v * S))


def rgb(c) -> tuple:
    return tuple(int(x) for x in c[:3])


def rgba(c, a=255) -> tuple:
    t = rgb(c)
    return (t[0], t[1], t[2], a)


def lum(c) -> float:
    def f(u):
        u = u / 255.0
        return u / 12.92 if u <= 0.04045 else ((u + 0.055) / 1.055) ** 2.4

    r, g, b = (f(c[0]), f(c[1]), f(c[2]))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b) -> float:
    la, lb = lum(a), lum(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def mix(a, b, t) -> tuple:
    return tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3))


def lighten(c, t) -> tuple:
    return mix(c, (255, 255, 255), t)


def darken(c, t) -> tuple:
    return mix(c, (0, 0, 0), t)


def desat(c, amount) -> tuple:
    g = 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]
    return tuple(int(c[i] * (1 - amount) + g * amount) for i in range(3))


def hex_of(c) -> str:
    return "#{:02X}{:02X}{:02X}".format(*rgb(c))


def inset(box, n):
    x0, y0, x1, y1 = box
    return (x0 + n, y0 + n, x1 - n, y1 - n)


class Plate:
    def __init__(self, state: str):
        self.state = state
        self.im = Image.new("RGBA", (P(320), P(72)), PANEL)
        self.d = ImageDraw.Draw(self.im)
        self.report = {}

    def refresh(self):
        self.d = ImageDraw.Draw(self.im)

    def arr(self):
        return np.array(self.im)

    def commit(self, arr):
        self.im = Image.fromarray(arr.astype(np.uint8), "RGBA")
        self.refresh()

    def b(self, box):
        return (P(box[0]), P(box[1]), P(box[2]), P(box[3]))

    def tone(self, c, hover=0.08):
        c = rgb(c)
        if self.state == "hover":
            return lighten(c, hover)
        if self.state == "pressed":
            return darken(c, 0.13)
        if self.state == "disabled":
            g = desat(c, 0.62)
            if lum(c) > 0.35:
                return lighten(g, 0.05)
            return darken(g, 0.04)
        return c

    def vfill(self, box, c0, c1):
        x0, y0, x1, y1 = self.b(box)
        x0, y0 = max(0, x0), max(0, y0)
        x1, y1 = min(self.im.width, x1), min(self.im.height, y1)
        if x1 <= x0 or y1 <= y0:
            return
        h = y1 - y0
        t = np.linspace(0, 1, h)[:, None, None]
        col = (np.array(rgb(c0)) * (1 - t) + np.array(rgb(c1)) * t)
        arr = self.arr()
        arr[y0:y1, x0:x1, :3] = np.clip(col, 0, 255).astype(np.uint8)
        arr[y0:y1, x0:x1, 3] = 255
        self.commit(arr)

    def brush(self, box, c0, c1, amp=8, seed=1):
        x0, y0, x1, y1 = self.b(box)
        h, w = y1 - y0, x1 - x0
        t = np.linspace(0, 1, h)[:, None, None]
        base = np.array(rgb(c0)) * (1 - t) + np.array(rgb(c1)) * t
        rng = np.random.default_rng(seed)
        streak = rng.normal(0, amp, h)
        streak = np.convolve(streak, np.ones(5) / 5, mode="same")
        pix = np.clip(base + streak[:, None, None], 0, 255)
        arr = self.arr()
        arr[y0:y1, x0:x1, :3] = pix.astype(np.uint8)
        arr[y0:y1, x0:x1, 3] = 255
        self.commit(arr)

    def grain(self, box, amp=5, seed=0):
        x0, y0, x1, y1 = self.b(box)
        rng = np.random.default_rng(seed + (0 if self.state != "pressed" else 9))
        n = rng.normal(0, amp, (y1 - y0, x1 - x0, 1))
        arr = self.arr().astype(np.int16)
        arr[y0:y1, x0:x1, :3] = np.clip(arr[y0:y1, x0:x1, :3] + n, 0, 255)
        self.commit(arr)

    def fill_poly(self, pts, color):
        sp = [(P(x), P(y)) for x, y in pts]
        self.d.polygon(sp, fill=rgba(color))

    def stroke_poly(self, pts, color, width=1):
        sp = [(P(x), P(y)) for x, y in pts]
        self.d.line(sp + [sp[0]], fill=rgba(color), width=max(1, P(width)))

    def stroke_rect(self, box, color, width=1):
        self.d.rectangle(self.b(box), outline=rgba(color), width=max(1, P(width)))

    def fill_rect(self, box, color):
        self.d.rectangle(self.b(box), fill=rgba(color))

    def bevel(self, box, hi, lo, width=2):
        if self.state == "pressed":
            hi, lo = lo, hi
        x0, y0, x1, y1 = self.b(box)
        w = max(1, P(width))
        for i in range(w):
            self.d.line([(x0 + i, y0 + i), (x1 - i, y0 + i)], fill=rgba(hi))
            self.d.line([(x0 + i, y0 + i), (x0 + i, y1 - i)], fill=rgba(hi))
            self.d.line([(x0 + i, y1 - i), (x1 - i, y1 - i)], fill=rgba(lo))
            self.d.line([(x1 - i, y0 + i), (x1 - i, y1 - i)], fill=rgba(lo))

    def rivet(self, x, y, r, metal):
        cx, cy, rr = P(x), P(y), max(2, P(r))
        hi, lo = lighten(metal, 0.38), darken(metal, 0.45)
        self.d.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), fill=rgba(lo))
        self.d.ellipse((cx - rr + P(0.6), cy - rr + P(0.6), cx + rr - P(0.6), cy + rr - P(0.6)), fill=rgba(metal))
        self.d.ellipse((cx - rr + P(0.8), cy - rr + P(0.5), cx - P(0.2), cy - P(0.2)), fill=rgba(hi))
        self.d.ellipse((cx - P(0.7), cy - P(0.7), cx + P(0.7), cy + P(0.7)), fill=rgba(darken(metal, 0.55)))

    def diamond(self, x, y, r, color):
        self.fill_poly([(x, y - r), (x + r, y), (x, y + r), (x - r, y)], color)

    def font(self, name, design_px, weight):
        f = ImageFont.truetype(str(FONT_DIR / name), max(8, P(design_px)))
        try:
            f.set_variation_by_axes([float(weight)])
        except Exception:
            pass
        return f

    def label(self, text, xy, font_name, size, weight, prefer, ink, max_w):
        cx, cy = xy
        if self.state == "pressed":
            cy += 1
        size_use = size
        f = self.font(font_name, size_use, weight)
        while f.getlength(text) > P(max_w) and size_use > 12:
            size_use -= 1
            f = self.font(font_name, size_use, weight)
        rw = max(8, int(f.getlength(text) * 0.46))
        rh = max(8, P(size_use * 0.34))
        sx, sy = P(cx), P(cy)
        x0 = max(0, sx - rw)
        y0 = max(0, sy - rh)
        x1 = min(self.im.width, sx + rw)
        y1 = min(self.im.height, sy + rh)
        crop = np.asarray(self.im.crop((x0, y0, x1, y1)).convert("RGB")).reshape(-1, 3)
        if len(crop) > 900:
            crop = crop[:: max(1, len(crop) // 900)]

        def worst(fill):
            return min(contrast(fill, (int(p[0]), int(p[1]), int(p[2]))) for p in crop)

        target = (22, 16, 12) if ink == "dark" else (248, 244, 236)
        best_fill, best_w = rgb(prefer), worst(rgb(prefer))
        if best_w < 4.6:
            for t in np.linspace(0.15, 1.0, 12):
                cand = mix(rgb(prefer), target, float(t))
                w = worst(cand)
                if w > best_w:
                    best_fill, best_w = cand, w
                if w >= 4.6:
                    break
        shadow = darken(best_fill, 0.45) if ink == "light" else lighten(best_fill, 0.45)
        self.d.text((sx + S, sy + S), text, font=f, fill=rgba(shadow, 140), anchor="mm")
        self.d.text((sx, sy), text, font=f, fill=rgba(best_fill), anchor="mm")
        self.report = {
            "fill": best_fill,
            "worst": best_w,
            "size": size_use,
            "text": text,
        }
        return best_w

    def focus_rect(self, box, color=(232, 196, 120)):
        if self.state != "focus":
            return
        x0, y0, x1, y1 = box
        self.stroke_rect((x0 - 3, y0 - 3, x1 + 3, y1 + 3), color, 1.6)

    def focus_poly(self, pts, color=(232, 196, 120)):
        if self.state != "focus":
            return
        self.stroke_poly(pts, color, 1.6)

    def down(self) -> Image.Image:
        return self.im.resize((320, 72), Image.Resampling.LANCZOS)


def chamfer(box, c):
    x0, y0, x1, y1 = box
    return [
        (x0 + c, y0), (x1 - c, y0), (x1, y0 + c), (x1, y1 - c),
        (x1 - c, y1), (x0 + c, y1), (x0, y1 - c), (x0, y0 + c),
    ]


def arch_pts(box):
    x0, y0, x1, y1 = box
    mid = (x0 + x1) / 2
    shoulder = y0 + (y1 - y0) * 0.42
    rx = (x1 - x0) / 2
    ry = shoulder - y0
    pts = [(x0, y1), (x0, shoulder)]
    for i in range(1, 28):
        a = math.pi * (1 - i / 28)
        pts.append((mid + rx * math.cos(a), shoulder - ry * math.sin(a)))
    pts += [(x1, shoulder), (x1, y1)]
    return pts


def wax_image(diam: int, state: str) -> Image.Image:
    r = diam / 2
    yy, xx = np.mgrid[0:diam, 0:diam]
    cy = cx = (diam - 1) / 2
    dist = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    ang = np.arctan2(yy - cy, xx - cx)
    wobble = 0.045 * np.sin(6 * ang) + 0.025 * np.sin(11 * ang + 0.7)
    edge = r * (0.90 + wobble)
    inside = dist <= edge
    t = np.clip(dist / max(1, r), 0, 1)
    if state == "disabled":
        edge_c = np.array([92, 84, 82])
        mid_c = np.array([140, 128, 124])
        core = np.array([118, 110, 108])
    elif state == "pressed":
        edge_c = np.array([70, 16, 20])
        mid_c = np.array([122, 36, 38])
        core = np.array([86, 22, 26])
    elif state == "hover":
        edge_c = np.array([118, 32, 36])
        mid_c = np.array([186, 64, 58])
        core = np.array([140, 40, 42])
    else:
        edge_c = np.array([102, 26, 30])
        mid_c = np.array([168, 52, 48])
        core = np.array([124, 34, 36])
    col = edge_c * t[..., None] + mid_c * (1 - t[..., None])
    col = col * (1 - 0.25 * np.clip(1 - t, 0, 1)[..., None]) + core * (0.25 * np.clip(1 - t, 0, 1)[..., None])
    ring = np.exp(-((t - 0.68) ** 2) / 0.004)
    col = col * (1 - 0.28 * ring[..., None])
    star = (np.cos(ang * 8) > 0.35) & (dist < r * 0.46) & (dist > r * 0.16)
    col[star] *= 0.78
    hi = inside & (dist < r * 0.8) & (dist > r * 0.25) & (ang < -1.7) & (ang > -2.7)
    col[hi] = np.clip(col[hi] * 1.18 + 18, 0, 255)
    arr = np.zeros((diam, diam, 4), np.uint8)
    arr[inside, :3] = np.clip(col[inside], 0, 255).astype(np.uint8)
    arr[inside, 3] = 255
    return Image.fromarray(arr)


def style_01(p: Plate):
    box = (8, 6, 312, 66)
    p.vfill(box, p.tone((232, 206, 150)), p.tone((196, 164, 112)))
    p.grain(box, 6, 11)
    rng = np.random.default_rng(4)
    for _ in range(14):
        x = int(rng.integers(P(16), P(300)))
        y = int(rng.integers(P(14), P(58)))
        rad = int(rng.integers(P(0.6), P(1.8)))
        p.d.ellipse((x - rad, y - rad, x + rad, y + rad), fill=(120, 78, 40, 80))
    lo, hi, mid = p.tone((78, 52, 22)), p.tone((236, 204, 128)), p.tone((168, 122, 48))
    p.stroke_rect(box, lo, 1)
    p.stroke_rect(inset(box, 1.5), hi, 1)
    p.stroke_rect(inset(box, 3.2), mid, 1.2)
    p.stroke_rect(inset(box, 6.5), p.tone((92, 64, 32)), 0.8)
    for x, y, s in ((18, 16, 1), (302, 16, 1), (18, 56, 1), (302, 56, 1)):
        p.diamond(x, y, 3.2, p.tone((150, 106, 42)))
        p.diamond(x, y, 1.3, p.tone((232, 206, 140)))
    p.label("Nová hra", (160, 36), "EBGaramond.ttf", 22, 640, (48, 32, 18), "dark", 230)
    p.focus_rect(box)


def style_02(p: Plate):
    box = (8, 8, 312, 64)
    p.brush(box, p.tone((120, 128, 136)), p.tone((62, 68, 76)), amp=7, seed=2)
    p.bevel(box, p.tone((196, 202, 208)), p.tone((22, 24, 28)), 2)
    # zapustená tmavá plocha — svetlý text nesedí na svetlom kartáči
    well = (22, 18, 300, 54)
    p.vfill(well, p.tone((58, 64, 72)), p.tone((32, 36, 42)))
    p.bevel(well, p.tone((20, 22, 26)), p.tone((120, 126, 132)), 1)
    p.vfill((12, 16, 20, 56), p.tone((150, 42, 36)), p.tone((92, 24, 22)))
    metal = p.tone((140, 146, 152))
    for xy in ((28, 16), (292, 16), (28, 56), (292, 56)):
        p.rivet(*xy, 3.1, metal)
    p.label("Vyhlásiť vojnu", (166, 36), "SourceSans3.ttf", 16, 650, (244, 246, 248), "light", 210)
    p.focus_rect(box, (232, 196, 120))


def style_03(p: Plate):
    box = (10, 8, 310, 64)
    p.vfill(box, p.tone((16, 40, 34)), p.tone((8, 22, 18)))
    gold = p.tone((214, 176, 92))
    p.stroke_poly(chamfer(box, 8), gold, 1.6)
    p.stroke_poly(chamfer(inset(box, 5), 6), p.tone((120, 90, 44)), 0.8)
    for x, y in ((22, 18), (298, 18), (22, 54), (298, 54)):
        p.stroke_rect((x - 3, y - 3, x + 3, y + 3), gold, 0.7)
    cx = 160
    for i, ang in enumerate((-0.5, -0.25, 0, 0.25, 0.5)):
        x2 = cx + math.sin(ang) * 16
        y2 = 16 + (1 - math.cos(ang)) * 10
        p.d.line([(P(cx), P(14)), (P(x2), P(y2 + 6))], fill=rgba(gold), width=max(1, P(0.7)))
    p.label("Potvrdiť", (160, 40), "EBGaramond.ttf", 22, 650, (244, 228, 190), "light", 200)
    p.focus_rect(box, gold)


def style_04(p: Plate):
    box = (14, 10, 306, 62)
    p.vfill(box, p.tone((24, 28, 32)), p.tone((12, 14, 18)))
    brass = p.tone((186, 164, 112))
    oxide = p.tone((118, 132, 126))
    p.stroke_rect(box, brass, 0.8)
    p.stroke_rect(inset(box, 4), oxide, 0.7)
    arm = 12
    for x0, y0, sx, sy in (
        (box[0], box[1], 1, 1), (box[2], box[1], -1, 1),
        (box[0], box[3], 1, -1), (box[2], box[3], -1, -1),
    ):
        p.d.line([(P(x0), P(y0)), (P(x0 + sx * arm), P(y0))], fill=rgba(brass), width=max(1, P(1.1)))
        p.d.line([(P(x0), P(y0)), (P(x0), P(y0 + sy * arm))], fill=rgba(brass), width=max(1, P(1.1)))
    p.d.line([(P(40), P(36)), (P(78), P(36))], fill=rgba(oxide), width=max(1, P(0.8)))
    p.d.line([(P(242), P(36)), (P(280), P(36))], fill=rgba(oxide), width=max(1, P(0.8)))
    p.label("Výskum", (160, 36), "SourceSans3.ttf", 18, 620, (214, 224, 216), "light", 150)
    p.focus_rect(box, brass)


def style_05(p: Plate):
    rib = (86, 18, 304, 54)
    p.vfill(rib, p.tone((122, 32, 40)), p.tone((74, 18, 26)))
    p.stroke_rect(rib, p.tone((212, 170, 90)), 0.9)
    p.label("Potvrdiť", (196, 36), "EBGaramond.ttf", 20, 640, (250, 236, 214), "light", 150)
    seal = wax_image(P(54), p.state)
    p.im.paste(seal, (P(16), P(9)), seal)
    p.refresh()
    if p.state == "focus":
        p.d.ellipse((P(14), P(7), P(72), P(65)), outline=rgba((232, 196, 120)), width=max(1, P(1.5)))
        p.stroke_rect((82, 14, 308, 58), (232, 196, 120), 1.2)


def style_06(p: Plate):
    box = (8, 8, 312, 64)
    p.vfill(box, p.tone((124, 72, 44)), p.tone((78, 42, 26)))
    p.grain(box, 9, 21)
    gold = p.tone((212, 170, 86))
    p.stroke_rect(inset(box, 4), gold, 0.8)
    p.stroke_rect(inset(box, 7), p.tone((120, 78, 36)), 0.7)
    # stitching
    y_top, y_bot = 12, 60
    x = 16
    while x < 304:
        p.d.line([(P(x), P(y_top)), (P(x + 3.2), P(y_top))], fill=rgba(p.tone((230, 206, 160))), width=max(1, P(0.8)))
        p.d.line([(P(x), P(y_bot)), (P(x + 3.2), P(y_bot))], fill=rgba(p.tone((230, 206, 160))), width=max(1, P(0.8)))
        x += 9
    for x, y in ((20, 22), (300, 22), (20, 50), (300, 50)):
        p.diamond(x, y, 2.4, gold)
    p.label("Načítať hru", (160, 36), "EBGaramond.ttf", 20, 620, (250, 236, 214), "light", 220)
    p.focus_rect(box, gold)


def style_07(p: Plate):
    box = (8, 7, 312, 65)
    p.vfill(box, p.tone((206, 204, 200)), p.tone((168, 166, 162)))
    p.grain(box, 4, 8)
    rng = np.random.default_rng(15)
    for k in range(6):
        pts = []
        y = float(rng.uniform(14, 58))
        x = 14.0
        while x < 78:
            y = min(60, max(12, y + float(rng.normal(0, 0.8))))
            pts.append((P(x), P(y)))
            x += 4
        p.d.line(pts, fill=(90, 102, 112, 150), width=1)
        pts = []
        y = float(rng.uniform(14, 58))
        x = 242.0
        while x < 306:
            y = min(60, max(12, y + float(rng.normal(0, 0.8))))
            pts.append((P(x), P(y)))
            x += 4
        p.d.line(pts, fill=(90, 102, 112, 150), width=1)
    bronze = p.tone((138, 90, 46))
    patina = p.tone((78, 104, 90))
    for x0, y0, x1, y1, horiz in (
        (8, 7, 36, 7, True), (8, 7, 8, 28, False),
        (284, 7, 312, 7, True), (312, 7, 312, 28, False),
        (8, 65, 36, 65, True), (8, 44, 8, 65, False),
        (284, 65, 312, 65, True), (312, 44, 312, 65, False),
    ):
        p.d.line([(P(x0), P(y0)), (P(x1), P(y1))], fill=rgba(bronze), width=max(1, P(2.2)))
    p.rivet(16, 15, 2.2, bronze)
    p.rivet(304, 15, 2.2, patina)
    p.rivet(16, 57, 2.2, patina)
    p.rivet(304, 57, 2.2, bronze)
    p.label("Nastavenia", (160, 36), "LibreBaskerville.ttf", 16, 700, (32, 30, 28), "dark", 210)
    p.focus_rect(box, (120, 78, 36))


def style_08(p: Plate):
    box = (8, 7, 312, 65)
    p.vfill(box, p.tone((226, 214, 176)), p.tone((196, 178, 136)))
    p.grain(box, 4, 19)
    # rhumb
    navy = (24, 48, 82)
    ink_line = (46, 74, 110, 50)
    for i in range(5):
        y = 16 + i * 10
        p.d.line([(P(16), P(y)), (P(96), P(y + (i - 2)))], fill=ink_line, width=1)
        p.d.line([(P(230), P(y)), (P(300), P(y - (i - 2)))], fill=ink_line, width=1)
    # compass rose, faint
    cx, cy, rad = P(274), P(40), P(16)
    p.d.ellipse((cx - rad, cy - rad, cx + rad, cy + rad), outline=(24, 48, 82, 90), width=1)
    for ang in range(0, 360, 45):
        a = math.radians(ang)
        p.d.line(
            [(cx, cy), (cx + math.cos(a) * rad, cy + math.sin(a) * rad)],
            fill=(24, 48, 82, 80),
            width=1,
        )
    ink = p.tone(navy)
    p.stroke_rect(box, ink, 1.3)
    p.stroke_rect(inset(box, 3.5), p.tone((46, 78, 112)), 0.6)
    for x in (20, 300):
        p.d.line([(P(x), P(10)), (P(x), P(18))], fill=rgba(ink), width=max(1, P(0.8)))
    p.label("Lode", (150, 36), "EBGaramond.ttf", 24, 640, (20, 36, 64), "dark", 160)
    p.focus_rect(box, (24, 48, 82))


def style_09(p: Plate):
    box = (8, 7, 312, 65)
    ivory = p.tone((236, 226, 206))
    p.fill_rect(box, ivory)
    turq = p.tone((18, 104, 102))
    terra = p.tone((150, 58, 46))
    x = 16
    i = 0
    while x <= 304:
        p.diamond(x, 12, 3.4, turq if i % 2 == 0 else terra)
        p.diamond(x, 60, 3.4, terra if i % 2 == 0 else turq)
        x += 12
        i += 1
    y = 18
    j = 0
    while y <= 56:
        p.diamond(14, y, 3.2, turq if j % 2 == 0 else terra)
        p.diamond(306, y, 3.2, terra if j % 2 == 0 else turq)
        y += 11
        j += 1
    p.fill_rect((26, 20, 294, 52), ivory)
    p.stroke_rect((26, 20, 294, 52), turq, 0.8)
    p.label("Obchod", (160, 36), "CormorantGaramond.ttf", 22, 600, (22, 36, 34), "dark", 200)
    p.focus_rect(box, turq)


def style_10(p: Plate):
    box = (10, 9, 310, 63)
    p.vfill(box, p.tone((28, 22, 18)), p.tone((8, 7, 6)))
    # soft warm reflection, not gloss plastic
    p.d.rectangle((P(18), P(14), P(200), P(18)), fill=(180, 140, 80, 28))
    gold = p.tone((212, 168, 86))
    p.stroke_rect(box, gold, 0.7)
    # maki-e cloud on the right
    ox, oy = 250, 36
    for rad, col in ((16, (168, 124, 52, 180)), (11, (220, 180, 96, 200)), (6, (120, 84, 36, 160))):
        p.d.ellipse((P(ox - rad), P(oy - rad * 0.7), P(ox + rad * 0.4), P(oy + rad * 0.55)), outline=col, width=max(1, P(1.0)))
    p.d.arc((P(228), P(24), P(286), P(52)), 200, 20, fill=rgba(gold), width=max(1, P(1.1)))
    p.label("Burza", (128, 36), "CormorantGaramond.ttf", 26, 600, (236, 214, 160), "light", 140)
    p.focus_rect(box, gold)


def style_11(p: Plate):
    box = (8, 8, 312, 64)
    p.brush(box, p.tone((176, 132, 58)), p.tone((120, 84, 36)), amp=5, seed=11)
    p.bevel(box, p.tone((220, 180, 100)), p.tone((70, 46, 18)), 1.5)
    face = (24, 20, 292, 52)
    # svetlejšia plocha pod vrypom — tmavý text na tmavej mosadzi neprejde 4,5:1
    p.vfill(face, p.tone((236, 204, 132)), p.tone((214, 170, 96)))
    p.stroke_rect(face, p.tone((96, 64, 28)), 0.8)
    screw = p.tone((70, 48, 24))
    for xy in ((18, 16), (302, 16), (18, 56), (302, 56)):
        p.rivet(*xy, 2.6, p.tone((168, 124, 58)))
        p.d.line(
            [(P(xy[0] - 2.0), P(xy[1])), (P(xy[0] + 2.0), P(xy[1]))],
            fill=rgba(screw),
            width=max(1, P(0.7)),
        )
    p.label("Terén", (160, 36), "EBGaramond.ttf", 22, 650, (62, 36, 14), "dark", 180)
    p.focus_rect(box, (92, 60, 24))


def style_12(p: Plate):
    box = (78, 4, 242, 68)
    pts = arch_pts(box)
    stone0, stone1 = p.tone((214, 208, 196)), p.tone((168, 162, 150))
    p.fill_poly(pts, stone1)
    # inner lighter
    inner = arch_pts((86, 10, 234, 64))
    p.fill_poly(inner, stone0)
    p.grain((78, 4, 242, 68), 4, 12)
    mortar = p.tone((92, 86, 78))
    p.d.line([(P(90), P(30)), (P(230), P(30))], fill=rgba(mortar), width=max(1, P(0.8)))
    p.d.line([(P(94), P(60)), (P(226), P(60))], fill=rgba(mortar), width=max(1, P(0.8)))
    # trefoil hint in the crown
    for dx in (-8, 0, 8):
        p.d.ellipse((P(160 + dx - 3), P(16), P(160 + dx + 3), P(22)), outline=rgba(mortar), width=1)
    p.stroke_poly(pts, p.tone((78, 72, 64)), 1.2)
    p.label("Ciele", (160, 46), "LibreBaskerville.ttf", 16, 700, (36, 32, 28), "dark", 120)
    p.focus_poly([(x, y) for x, y in [
        (box[0] - 3, box[3] + 2), (box[0] - 3, 32), (160, 1), (box[2] + 3, 32), (box[2] + 3, box[3] + 2)
    ]])


def style_13(p: Plate):
    box = (8, 8, 312, 64)
    paper = p.tone((214, 228, 208))
    p.vfill(box, lighten(paper, 0.04) if p.state != "pressed" else paper, p.tone((186, 204, 180)))
    green = p.tone((36, 92, 64))
    # guilloche then cover center
    x0, y0, x1, y1 = p.b(box)
    for k in range(16):
        pts = []
        for x in range(x0, x1, 3):
            yy = (y0 + y1) / 2 + math.sin(x * 0.09 + k * 0.55) * (P(6) + (k % 4))
            pts.append((x, yy))
        p.d.line(pts, fill=rgba(green, 70), width=1)
    p.fill_rect(inset(box, 9), paper)
    p.stroke_rect(box, green, 1.2)
    p.stroke_rect(inset(box, 3.5), p.tone((70, 120, 86)), 0.6)
    p.stroke_rect((262, 18, 300, 54), green, 0.8)
    p.d.text((P(281), P(36)), "€", font=p.font("EBGaramond.ttf", 16, 640), fill=rgba(green), anchor="mm")
    p.label("Pôžička", (140, 36), "EBGaramond.ttf", 22, 640, (24, 48, 32), "dark", 160)
    p.focus_rect(box, (20, 70, 48))


def style_14(p: Plate):
    box = (8, 8, 312, 64)
    # ebonized wood stripes
    x0, y0, x1, y1 = p.b(box)
    h = y1 - y0
    yy = np.linspace(0, 1, h)[:, None]
    wave = 0.5 + 0.5 * np.sin(yy * 46)
    base = 22 + wave * 14
    if p.state == "hover":
        base = base + 8
    if p.state == "pressed":
        base = base * 0.8
    if p.state == "disabled":
        base = 48 + wave * 6
    arr = p.arr()
    arr[y0:y1, x0:x1, 0] = np.clip(base * 0.85, 0, 255).astype(np.uint8)
    arr[y0:y1, x0:x1, 1] = np.clip(base * 0.72, 0, 255).astype(np.uint8)
    arr[y0:y1, x0:x1, 2] = np.clip(base * 0.55, 0, 255).astype(np.uint8)
    arr[y0:y1, x0:x1, 3] = 255
    p.commit(arr)
    ivory = p.tone((236, 228, 210))
    p.fill_rect((28, 16, 292, 56), ivory)
    p.stroke_rect((28, 16, 292, 56), p.tone((168, 132, 72)), 0.8)
    p.rivet(18, 36, 2.3, p.tone((176, 140, 70)))
    p.rivet(302, 36, 2.3, p.tone((176, 140, 70)))
    p.label("Konzola", (160, 36), "SourceSans3.ttf", 16, 640, (36, 28, 22), "dark", 200)
    p.focus_rect(box, (212, 170, 90))


def style_15(p: Plate):
    box = (8, 8, 312, 64)
    x0, y0, x1, y1 = p.b(box)
    h, w = y1 - y0, x1 - x0
    ys = np.linspace(0, h, h)[:, None]
    xs = np.linspace(0, w, w)[None, :]
    wave = np.sin(ys * 0.20 + np.sin(xs * 0.045) * 4.2)
    wave2 = np.sin(ys * 0.48 + xs * 0.015)
    v = np.clip(0.22 + 0.20 * wave + 0.08 * wave2, 0, 0.62)
    if p.state == "hover":
        v = np.clip(v * 1.06, 0, 0.68)
    if p.state == "pressed":
        v = v * 0.78
    if p.state == "disabled":
        v = np.clip(0.20 + 0.05 * wave, 0, 0.4)
    gray = 22 + v * 120
    arr = p.arr()
    arr[y0:y1, x0:x1, 0] = np.clip(gray * 0.94, 0, 255)
    arr[y0:y1, x0:x1, 1] = np.clip(gray * 0.97, 0, 255)
    arr[y0:y1, x0:x1, 2] = np.clip(gray * 1.02, 0, 255)
    arr[y0:y1, x0:x1, 3] = 255
    p.commit(arr)
    p.bevel(box, p.tone((180, 186, 190)), p.tone((16, 16, 18)), 1.4)
    p.vfill((10, 52, 310, 60), p.tone((132, 36, 32)), p.tone((84, 20, 22)))
    p.label("Predať", (160, 32), "SourceSans3.ttf", 18, 680, (244, 244, 246), "light", 180)
    p.focus_rect(box)


def style_16(p: Plate):
    # folder tab, not a full-width bar
    box = (70, 16, 250, 66)
    vel = p.tone((108, 28, 44))
    p.vfill(box, lighten(vel, 0.08), darken(vel, 0.08))
    # nap
    x0, y0, x1, y1 = p.b(box)
    rng = np.random.default_rng(16)
    n = rng.normal(0, 8, (y1 - y0, x1 - x0, 1))
    arr = p.arr().astype(np.int16)
    arr[y0:y1, x0:x1, :3] = np.clip(arr[y0:y1, x0:x1, :3] + n, 0, 255)
    p.commit(arr.astype(np.uint8))
    # round the top by covering corners with panel — approximate with ellipses? 
    # redraw top lip in gold
    gold = p.tone((212, 170, 90))
    p.d.line([(P(70), P(16)), (P(250), P(16))], fill=rgba(gold), width=max(1, P(2)))
    p.d.line([(P(70), P(16)), (P(70), P(66))], fill=rgba(darken(vel, 0.3)), width=max(1, P(1)))
    p.d.line([(P(250), P(16)), (P(250), P(66))], fill=rgba(lighten(vel, 0.15)), width=max(1, P(1)))
    p.d.line([(P(40), P(66)), (P(280), P(66))], fill=rgba((140, 120, 80)), width=max(1, P(1.2)))
    p.label("Mapa", (160, 42), "EBGaramond.ttf", 20, 640, (250, 236, 220), "light", 140)
    p.focus_rect(box, gold)


def style_17(p: Plate):
    pts = [(18, 12), (188, 12), (236, 26), (200, 36), (248, 36), (200, 46), (236, 58), (188, 60), (18, 60)]
    field = p.tone((22, 48, 112))
    p.fill_poly(pts, field)
    p.stroke_poly(pts, p.tone((214, 176, 92)), 1.5)
    chev = [(168, 36), (214, 22), (228, 22), (182, 36), (228, 50), (214, 50)]
    p.fill_poly(chev, p.tone((196, 154, 70)))
    p.label("Vplyv", (100, 36), "EBGaramond.ttf", 20, 650, (244, 228, 190), "light", 90)
    p.focus_poly(pts, (214, 176, 92))


def style_18(p: Plate):
    box = (132, 8, 188, 64)
    p.vfill(box, p.tone((72, 78, 86)), p.tone((36, 40, 46)))
    p.bevel(box, p.tone((186, 192, 198)), p.tone((16, 18, 20)), 1.8)
    well = (140, 16, 180, 56)
    p.vfill(well, p.tone((40, 44, 50)), p.tone((24, 26, 30)))
    for xy in ((138, 14), (182, 14), (138, 58), (182, 58)):
        p.rivet(*xy, 1.8, p.tone((150, 156, 162)))
    prefer = (236, 230, 220)
    cx, cy = P(160), P(36)
    crop = np.asarray(p.im.crop((cx - 18, cy - 14, cx + 18, cy + 14)).convert("RGB")).reshape(-1, 3)

    def worst(fill):
        return min(contrast(fill, (int(a), int(b), int(c))) for a, b, c in crop[::2])

    fill = prefer
    w = worst(fill)
    if w < 4.6:
        fill = (250, 248, 244)
        w = worst(fill)
    col = rgba(fill)
    m = 18
    x0, y0, x1, y1 = box
    width = max(2, P(3.2))
    p.d.line([(P(x0 + m) + S, P(y0 + m) + S), (P(x1 - m) + S, P(y1 - m) + S)], fill=(0, 0, 0, 110), width=width)
    p.d.line([(P(x1 - m) + S, P(y0 + m) + S), (P(x0 + m) + S, P(y1 - m) + S)], fill=(0, 0, 0, 110), width=width)
    p.d.line([(P(x0 + m), P(y0 + m)), (P(x1 - m), P(y1 - m))], fill=col, width=width)
    p.d.line([(P(x1 - m), P(y0 + m)), (P(x0 + m), P(y1 - m))], fill=col, width=width)
    p.report = {"fill": rgb(fill), "worst": w, "size": 0, "text": "✕"}
    p.focus_rect(box)


CONCEPTS = [
    dict(num="01", slug="pergamen-mosadz", name="Pergamen a mosadz",
         inspiration="Europa Universalis IV — zažltnutý pergamen, mosadzný rám, rohové diamanty. Nie krémová SaaS karta.",
         shape="ostrý obdĺžnik", text="Nová hra", role="hlavné menu / primárne",
         font="EB Garamond, váha 640, 22 px", nine="22, 14, 22, 14",
         rect="x 8–312, y 6–66",
         colors={"pergamen": "#E4CE96", "mosadz": "#A87A30", "atrament": "#302010", "panel": "#202328"},
         draw=style_01),
    dict(num="02", slug="ocel-nity", name="Oceľ a nity",
         inspiration="Hearts of Iron IV — kartáčovaná oceľ, nity, ľavý smaltovaný pruh. Tlačidlo nebezpečnej akcie.",
         shape="obdĺžnik so skoseným bevelom", text="Vyhlásiť vojnu", role="nebezpečné",
         font="Source Sans 3, váha 650, 16 px", nine="28, 16, 28, 16",
         rect="x 8–312, y 8–64",
         colors={"ocel": "#4E565E", "svetlo": "#B0B8BE", "smalt": "#962820", "text": "#F4F6F8", "panel": "#202328"},
         draw=style_02),
    dict(num="03", slug="art-deco-zlato", name="Art deco zlato",
         inspiration="Victoria 3 — tmavozelený lak, skosený zlatý schod, vejár nad textom.",
         shape="osemuholník (skosené rohy)", text="Potvrdiť", role="potvrdiť",
         font="EB Garamond, váha 650, 22 px", nine="20, 14, 20, 14",
         rect="x 10–310, y 8–64",
         colors={"lak": "#102820", "zlato": "#D6B05C", "text": "#F4E4BE", "panel": "#202328"},
         draw=style_03),
    dict(num="04", slug="hviezdny-lept", name="Hviezdny lept",
         inspiration="Stellaris len ako technický lept: uhlie, mosadz a oxid. Žiadny neón, žiadny glow, žiadny fialový gradient.",
         shape="obdĺžnik s rohovými konzolami", text="Výskum", role="primárne (výskum)",
         font="Source Sans 3, váha 620, 18 px", nine="18, 12, 18, 12",
         rect="x 14–306, y 10–62",
         colors={"uhlie": "#12161A", "mosadz": "#BAA470", "oxid": "#76847E", "text": "#D6E0D8", "panel": "#202328"},
         draw=style_04),
    dict(num="05", slug="voskova-pecat", name="Vosková pečať",
         inspiration="Listina s karmínovou stuhou a vtlačenou pečaťou. Potvrdzujúce, slávnostné.",
         shape="stuha + kruhová pečať vľavo", text="Potvrdiť", role="potvrdiť",
         font="EB Garamond, váha 640, 20 px", nine="pečať sa neťahá; 9-patch len stuhy 18, 12, 16, 12",
         rect="stuha x 86–304, y 18–54; pečať ø 54 vľavo",
         colors={"vosk": "#A83234", "stuha": "#7A1820", "zlato": "#D4AA5A", "text": "#FAECD6", "panel": "#202328"},
         draw=style_05),
    dict(num="06", slug="kozena-vazba", name="Kožená väzba",
         inspiration="Viazačka kroniky: hnedá useň, zlaté linky, steh, rohové puncy.",
         shape="obdĺžnik s mäkkou hranou", text="Načítať hru", role="sekundárne / menu",
         font="EB Garamond, váha 620, 20 px", nine="20, 14, 20, 14",
         rect="x 8–312, y 8–64",
         colors={"usen": "#6E4224", "zlato": "#D4AA56", "steh": "#E6CEA0", "text": "#FAECD6", "panel": "#202328"},
         draw=style_06),
    dict(num="07", slug="mramor-bronz", name="Mramor a bronz",
         inspiration="Chladný sivý mramor, bronzové nárožníky a jedna patina. Nie teplý krém.",
         shape="obdĺžnik, ornament len v rohoch", text="Nastavenia", role="hlavné menu",
         font="Libre Baskerville, váha 700, 16 px", nine="36, 16, 36, 16",
         rect="x 8–312, y 7–65",
         colors={"mramor": "#C8C6C2", "zila": "#687078", "bronz": "#8A5A2E", "patina": "#4E685A", "panel": "#202328"},
         draw=style_07),
    dict(num="08", slug="namorna-mapa", name="Námorná mapa",
         inspiration="Admiralitná mapa: žltý papier, námornícka modrá linka, ružica kompasu.",
         shape="obdĺžnik", text="Lode", role="záložka / mapa",
         font="EB Garamond, váha 640, 24 px", nine="18, 12, 36, 12",
         rect="x 8–312, y 7–65",
         colors={"papier": "#D6C8A0", "ink": "#183052", "panel": "#202328"},
         draw=style_08),
    dict(num="09", slug="iznik-dlazba", name="Iznik dlažba",
         inspiration="Osmanský obklad: tyrkys, terakota, slonovina v medailóne. Ornament len v ráme.",
         shape="obdĺžnik s geometrickým bordúrou", text="Obchod", role="záložka / obchod",
         font="Cormorant Garamond, váha 600, 22 px", nine="26, 18, 26, 18",
         rect="x 8–312, y 7–65",
         colors={"slonovina": "#ECE2CE", "tyrkys": "#126866", "terakota": "#963A2E", "panel": "#202328"},
         draw=style_09),
    dict(num="10", slug="lak-urushi", name="Lak urushi",
         inspiration="Čierny japonský lak a zlaté maki-e obláčik vpravo. Matný, nie plastový lesk.",
         shape="nízky obdĺžnik, motív asymetrický", text="Burza", role="primárne",
         font="Cormorant Garamond, váha 600, 26 px", nine="16, 12, 48, 12",
         rect="x 10–310, y 9–63",
         colors={"lak": "#100E0C", "zlato": "#D4A856", "text": "#ECD6A0", "panel": "#202328"},
         draw=style_10),
    dict(num="11", slug="mosadzna-tabulka", name="Mosadzná tabuľka",
         inspiration="Rytá firemná tabuľka so skrutkami. Text je vrytý, nie nalepený.",
         shape="obdĺžnik", text="Terén", role="sekundárne",
         font="EB Garamond, váha 650, 22 px", nine="24, 16, 24, 16",
         rect="x 8–312, y 8–64",
         colors={"mosadz": "#C69A48", "vryp": "#301E0C", "skrutka": "#5C4424", "panel": "#202328"},
         draw=style_11),
    dict(num="12", slug="goticky-kamen", name="Gotický kameň",
         inspiration="Vápencový lomený oblúk, škáry muriva, náznak trojlístka.",
         shape="lomený oblúk (nie obdĺžnik)", text="Ciele", role="záložka",
         font="Libre Baskerville, váha 700, 16 px", nine="oblúk sa neťahá ako 9-patch; okraj ornamentu 18 px",
         rect="x 78–242, y 4–68",
         colors={"vapenec": "#D0CAC0", "skara": "#5C564E", "panel": "#202328"},
         draw=style_12),
    dict(num="13", slug="bankovy-sek", name="Bankový šek",
         inspiration="Zelený bankový papier, giloš v bordúre, políčko meny.",
         shape="obdĺžnik", text="Pôžička", role="potvrdiť / financie",
         font="EB Garamond, váha 640, 22 px", nine="16, 12, 48, 12",
         rect="x 8–312, y 8–64",
         colors={"papier": "#D6E4D0", "gilos": "#245C40", "panel": "#202328"},
         draw=style_13),
    dict(num="14", slug="eben-slonovina", name="Eben a slonovina",
         inspiration="Ebenové drevo a vložka zo slonoviny, dva mosadzné nity. Cheat konzola, nie herné CTA.",
         shape="obdĺžnik s vloženým panelom", text="Konzola", role="cheat konzola",
         font="Source Sans 3, váha 640, 16 px", nine="28, 16, 28, 16",
         rect="x 8–312, y 8–64",
         colors={"eben": "#16120E", "slonovina": "#ECE4D2", "mosadz": "#B08C46", "panel": "#202328"},
         draw=style_14),
    dict(num="15", slug="damaskova-ocel", name="Damašková oceľ",
         inspiration="Leptané damaskové vlny a tenký karmínový pruh. Nebezpečné, iné než nitovaná platňa.",
         shape="obdĺžnik", text="Predať", role="nebezpečné",
         font="Source Sans 3, váha 680, 18 px", nine="16, 14, 16, 18",
         rect="x 8–312, y 8–64",
         colors={"ocel": "#6A7076", "vlna": "#2A2E32", "smalt": "#841E1C", "text": "#F4F4F6", "panel": "#202328"},
         draw=style_15),
    dict(num="16", slug="zamatova-zalozka", name="Zamatová záložka",
         inspiration="Úzka zamatová záložka na hrane panela, zlatá hrana navrchu. Tvar tabu, nie lišta.",
         shape="užší tab (spodok zarovnaný na linku)", text="Mapa", role="záložka",
         font="EB Garamond, váha 640, 20 px", nine="tab sa neťahá do šírky; vnútro 16, 14, 16, 12",
         rect="x 70–250, y 16–66",
         colors={"zamat": "#6C1C2C", "zlato": "#D4AA5A", "text": "#FAECDC", "panel": "#202328"},
         draw=style_16),
    dict(num="17", slug="heraldicky-vimpl", name="Heraldický vimpel",
         inspiration="Lastovičí chvost, modrý smalt, zlatý chevrón. Vplyv / dynastia, nie CK3 asset.",
         shape="vimpel (lastovičí chvost)", text="Vplyv", role="ikonové / vplyv",
         font="EB Garamond, váha 650, 20 px", nine="tvar sa neťahá; 9-patch nevhodný, kresliť ako celok",
         rect="x 18–246, y 12–60",
         colors={"smalt": "#163070", "zlato": "#D6B05C", "text": "#F4E4BE", "panel": "#202328"},
         draw=style_17),
    dict(num="18", slug="kriz-zatvorit", name="Nitovaný kríž",
         inspiration="Štvorcové zatváracie tlačidlo: oceľ, štyri nity, skosené X. Bez textu.",
         shape="štvorec 56×56 uprostred platne", text="✕", role="zatvoriť (X)",
         font="— (len znak X, kreslený)", nine="celý štvorec je ornament; neťahať, okraj 10 px",
         rect="x 132–188, y 8–64",
         colors={"ocel": "#3A4046", "X": "#ECE6DC", "panel": "#202328"},
         draw=style_18),
]


def write_readme(meta: dict, rows: list[dict]) -> None:
    worst = min(r["worst"] for r in rows)
    lines = [
        f"# {meta['num']} — {meta['name']}",
        "",
        f"- **Inšpirácia:** {meta['inspiration']}",
        f"- **Tvar:** {meta['shape']}",
        f"- **Ukážkový text:** {meta['text']}",
        f"- **Rola:** {meta['role']}",
        f"- **Font:** {meta['font']}",
        f"- **9-patch okraje** (ľavý, horný, pravý, dolný, px od okraja kresby tlačidla): {meta['nine']}",
        f"- **Umiestnenie v náhľade 320×72:** {meta['rect']}",
        f"- **Najslabší kontrast v sade:** {worst:.2f}:1 (prah 4,5:1)",
        "- **Pozadie náhľadu:** panel hry `#202328` (rovnaký ako `BG_1` v `docs/UI_STYLE.md`).",
        "",
        "## HEX",
        "",
        "| Token | Hex |",
        "| --- | --- |",
    ]
    for k, v in meta["colors"].items():
        lines.append(f"| {k} | {v} |")
    lines += [
        "",
        "## Stavy",
        "",
        "Súbory: `normal.png`, `hover.png`, `pressed.png`, `disabled.png`, `focus.png`.",
        "Hover len zosvetlí materiál. Press stmaví a posunie text o 1 px (layout tlačidla sa nemení).",
        "Disabled je odsaturovaný, text ostáva čitateľný. Focus je mosadzný / materiálový prstenec, nie holý hover.",
        "",
        "| Stav | Farba textu | Najhorší pomer v ploche glyfov |",
        "| --- | --- | --- |",
    ]
    for r in rows:
        lines.append(f"| {r['state']} | {hex_of(r['fill'])} | {r['worst']:.2f}:1 |")
    lines.append("")
    (ROOT / meta["slug"]).joinpath("README.md")
    folder = ROOT / f"{meta['num']}-{meta['slug']}"
    (folder / "README.md").write_text("\n".join(lines), encoding="utf-8")


def write_overview_readme(results: list[tuple[dict, list[dict]]]) -> None:
    lines = [
        "# Návrhy tlačidiel — fáza 1",
        "",
        "Osemnásť odlišných materiálov a tvarov. Nie sú to farebné variácie jedného tlačidla.",
        "Každý stav je PNG 320×72 px na pozadí herného panelu `#202328`.",
        "Generátor: [`_src/render_concepts.py`](_src/render_concepts.py). Fonty OFL v `_src/fonts/`.",
        "",
        "Cinzel sa nepoužil: v latinke mu chýbajú slovenské znaky ľ, ň, ť, ď, ŕ, ĺ.",
        "",
        "| # | Priečinok | Štýl | Tvar | Text | Rola | Min. kontrast |",
        "| --- | --- | --- | --- | --- | --- | --- |",
    ]
    for meta, rows in results:
        worst = min(r["worst"] for r in rows)
        folder = f"{meta['num']}-{meta['slug']}"
        lines.append(
            f"| {meta['num']} | `{folder}` | {meta['name']} | {meta['shape']} | {meta['text']} | {meta['role']} | {worst:.2f}:1 |"
        )
    lines += [
        "",
        "Výber pre fázu 2 (príklad): „beriem č. 7, záložky č. 16, nebezpečné č. 2, zatvoriť č. 18“.",
        "Kým Ondrej nevyberie, téma hry sa nemení.",
        "",
    ]
    (ROOT / "README.md").write_text("\n".join(lines), encoding="utf-8")


def write_overview_png(results) -> None:
    pad, label_w, gap = 16, 228, 8
    img_w, img_h = 320, 72
    header_h = 86
    row_h = img_h + 10
    width = pad + label_w + 5 * (img_w + gap) + pad
    height = header_h + len(results) * row_h + 20
    canvas = Image.new("RGB", (width, height), (0x16, 0x18, 0x1B))
    d = ImageDraw.Draw(canvas)
    title_f = ImageFont.truetype(str(FONT_DIR / "EBGaramond.ttf"), 32)
    title_f.set_variation_by_axes([640])
    small = ImageFont.truetype(str(FONT_DIR / "SourceSans3.ttf"), 16)
    small.set_variation_by_axes([600])
    tiny = ImageFont.truetype(str(FONT_DIR / "SourceSans3.ttf"), 14)
    tiny.set_variation_by_axes([500])
    d.text((pad, 16), "Projekt-47 — návrhy tlačidiel (fáza 1)", font=title_f, fill=(236, 220, 188))
    d.text((pad, 54), "Každý riadok: normal · hover · pressed · disabled · focus. Pozadie #202328.", font=small, fill=(180, 176, 168))
    states = ["normal", "hover", "pressed", "disabled", "focus"]
    for i, (meta, _rows) in enumerate(results):
        y = header_h + i * row_h
        folder = ROOT / f"{meta['num']}-{meta['slug']}"
        d.text((pad, y + 8), meta["num"], font=title_f, fill=(232, 196, 120))
        d.text((pad + 52, y + 14), meta["name"], font=small, fill=(236, 232, 224))
        d.text((pad + 52, y + 36), meta["text"], font=tiny, fill=(168, 164, 156))
        for k, st in enumerate(states):
            im = Image.open(folder / f"{st}.png").convert("RGB")
            x = pad + label_w + k * (img_w + gap)
            canvas.paste(im, (x, y))
            d.rectangle((x, y, x + img_w - 1, y + img_h - 1), outline=(60, 64, 70))
    canvas.save(ROOT / "OVERVIEW.png", optimize=True)


def main() -> None:
    states = ["normal", "hover", "pressed", "disabled", "focus"]
    results = []
    failures = []
    for meta in CONCEPTS:
        folder = ROOT / f"{meta['num']}-{meta['slug']}"
        folder.mkdir(parents=True, exist_ok=True)
        rows = []
        for st in states:
            plate = Plate(st)
            meta["draw"](plate)
            img = plate.down()
            img.save(folder / f"{st}.png", optimize=True)
            rep = dict(plate.report)
            rep["state"] = st
            rows.append(rep)
            if rep.get("worst", 0) < 4.5:
                failures.append((meta["num"], st, rep.get("worst"), hex_of(rep.get("fill", (0, 0, 0)))))
            print(f"{meta['num']} {st:9} {rep.get('worst', 0):5.2f} {hex_of(rep.get('fill', (0,0,0)))} {rep.get('text')}")
        write_readme(meta, rows)
        results.append((meta, rows))
    write_overview_readme(results)
    write_overview_png(results)
    if failures:
        print("CONTRAST FAIL", failures)
        raise SystemExit(1)
    print("OK", len(CONCEPTS), "concepts")


if __name__ == "__main__":
    main()
