"""Original ship meshes for Projekt-47. No third-party geometry.

Axis matches Kenney watercraft already in the game:
  X beam (starboard +), Y up, keel near Y = 0, bow toward -Z.
"""
from __future__ import annotations

import io
import json
import math
import struct
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

MATERIALS = {
    "hull_blue": ((0.07, 0.20, 0.34, 1.0), 0.08, 0.55),
    "hull_green": ((0.06, 0.24, 0.16, 1.0), 0.08, 0.55),
    "hull_brown": ((0.29, 0.13, 0.08, 1.0), 0.10, 0.58),
    "antifoul": ((0.42, 0.08, 0.05, 1.0), 0.02, 0.72),
    "boot": ((0.90, 0.89, 0.84, 1.0), 0.02, 0.45),
    "white": ((0.86, 0.86, 0.82, 1.0), 0.04, 0.42),
    "deck": ((0.16, 0.15, 0.13, 1.0), 0.25, 0.78),
    "metal": ((0.55, 0.56, 0.57, 1.0), 0.85, 0.32),
    "dark_metal": ((0.18, 0.19, 0.20, 1.0), 0.70, 0.40),
    "glass": ((0.45, 0.62, 0.70, 1.0), 0.15, 0.08),
    "bronze": ((0.62, 0.40, 0.18, 1.0), 0.90, 0.28),
    "wood": ((0.45, 0.30, 0.16, 1.0), 0.02, 0.70),
    "crate": ((0.62, 0.48, 0.28, 1.0), 0.02, 0.66),
    "coil": ((0.40, 0.42, 0.44, 1.0), 0.80, 0.35),
    "sub": ((0.08, 0.09, 0.09, 1.0), 0.25, 0.48),
    "sub_panel": ((0.11, 0.12, 0.12, 1.0), 0.20, 0.55),
    "c_red": ((0.55, 0.12, 0.10, 1.0), 0.15, 0.48),
    "c_blue": ((0.10, 0.28, 0.55, 1.0), 0.15, 0.48),
    "c_green": ((0.12, 0.38, 0.22, 1.0), 0.15, 0.48),
    "c_orange": ((0.72, 0.38, 0.10, 1.0), 0.15, 0.48),
    "c_grey": ((0.45, 0.47, 0.48, 1.0), 0.20, 0.50),
    "yellow": ((0.78, 0.62, 0.12, 1.0), 0.20, 0.45),
    "black": ((0.04, 0.04, 0.045, 1.0), 0.40, 0.35),
}

CONTAINER_COLORS = ["c_red", "c_blue", "c_green", "c_orange", "c_grey"]


class Part:
    def __init__(self, material: str):
        self.material = material
        self.positions: list[tuple[float, float, float]] = []
        self.normals: list[tuple[float, float, float]] = []
        self.uvs: list[tuple[float, float]] = []
        self.indices: list[int] = []

    def _push(self, p, n, uv=(0.5, 0.5)) -> int:
        self.positions.append((float(p[0]), float(p[1]), float(p[2])))
        self.normals.append((float(n[0]), float(n[1]), float(n[2])))
        self.uvs.append((float(uv[0]), float(uv[1])))
        return len(self.positions) - 1

    def tri(self, a, b, c, na, nb, nc, uva=(0, 0), uvb=(1, 0), uvc=(1, 1)) -> None:
        ia, ib, ic = self._push(a, na, uva), self._push(b, nb, uvb), self._push(c, nc, uvc)
        self.indices.extend((ia, ib, ic))

    def quad(self, p0, p1, p2, p3, normal, uvs=None) -> None:
        n = _norm(np.asarray(normal, float))
        if uvs is None:
            uvs = ((0, 0), (1, 0), (1, 1), (0, 1))
        self.tri(p0, p1, p2, n, n, n, uvs[0], uvs[1], uvs[2])
        self.tri(p0, p2, p3, n, n, n, uvs[0], uvs[2], uvs[3])


def _norm(v: np.ndarray) -> np.ndarray:
    length = float(np.linalg.norm(v))
    if length < 1e-10:
        return np.array([0.0, 1.0, 0.0])
    return v / length


def add_box(parts: list[Part], center, size, material: str, uv_span=(0.0, 0.0, 1.0, 1.0)) -> None:
    c = np.asarray(center, float)
    h = np.asarray(size, float) * 0.5
    part = Part(material)
    faces = [
        ([1, -1, -1], [1, -1, 1], [1, 1, 1], [1, 1, -1], (1, 0, 0)),
        ([-1, -1, 1], [-1, -1, -1], [-1, 1, -1], [-1, 1, 1], (-1, 0, 0)),
        ([-1, 1, -1], [1, 1, -1], [1, 1, 1], [-1, 1, 1], (0, 1, 0)),
        ([-1, -1, 1], [1, -1, 1], [1, -1, -1], [-1, -1, -1], (0, -1, 0)),
        ([1, -1, 1], [-1, -1, 1], [-1, 1, 1], [1, 1, 1], (0, 0, 1)),
        ([-1, -1, -1], [1, -1, -1], [1, 1, -1], [-1, 1, -1], (0, 0, -1)),
    ]
    u0, v0, u1, v1 = uv_span
    quad_uv = ((u0, v0), (u1, v0), (u1, v1), (u0, v1))
    for a, b, d, e, normal in faces:
        corners = [c + h * np.array(s, float) for s in (a, b, d, e)]
        part.quad(corners[0], corners[1], corners[2], corners[3], normal, quad_uv)
    parts.append(part)


def add_cylinder(parts: list[Part], a, b, radius: float, material: str, segs: int = 12, caps: bool = True) -> None:
    a = np.asarray(a, float)
    b = np.asarray(b, float)
    axis = b - a
    length = float(np.linalg.norm(axis))
    if length < 1e-6 or radius <= 0:
        return
    direction = axis / length
    helper = np.array([0.0, 1.0, 0.0]) if abs(float(direction[1])) < 0.85 else np.array([1.0, 0.0, 0.0])
    side = _norm(np.cross(direction, helper))
    up = _norm(np.cross(direction, side))
    ring_a, ring_b, normals = [], [], []
    for i in range(segs):
        ang = 2 * math.pi * i / segs
        n = math.cos(ang) * side + math.sin(ang) * up
        ring_a.append(a + n * radius)
        ring_b.append(b + n * radius)
        normals.append(n)
    part = Part(material)
    for i in range(segs):
        j = (i + 1) % segs
        part.tri(ring_a[i], ring_a[j], ring_b[j], normals[i], normals[j], normals[j])
        part.tri(ring_a[i], ring_b[j], ring_b[i], normals[i], normals[j], normals[i])
        if caps:
            part.tri(a, ring_a[j], ring_a[i], -direction, -direction, -direction)
            part.tri(b, ring_b[i], ring_b[j], direction, direction, direction)
    parts.append(part)


def add_tapered_box(parts: list[Part], center, size, top_scale: float, material: str) -> None:
    c = np.asarray(center, float)
    h = np.asarray(size, float) * 0.5
    y0, y1 = c[1] - h[1], c[1] + h[1]

    def corner(sx, sz, y, scale):
        return np.array([c[0] + sx * h[0] * scale, y, c[2] + sz * h[2] * scale])

    signs = ((-1, -1), (1, -1), (1, 1), (-1, 1))
    bot = [corner(sx, sz, y0, 1.0) for sx, sz in signs]
    top = [corner(sx, sz, y1, top_scale) for sx, sz in signs]
    part = Part(material)
    part.quad(bot[0], bot[3], bot[2], bot[1], (0, -1, 0))
    part.quad(top[0], top[1], top[2], top[3], (0, 1, 0))
    for i in range(4):
        j = (i + 1) % 4
        part.quad(bot[i], bot[j], top[j], top[i], np.cross(top[j] - top[i], top[i] - bot[i]))
    parts.append(part)


def _beam_factor(t: float) -> float:
    if t < 0.14:
        return 0.50 + 0.50 * (t / 0.14) ** 0.75
    if t < 0.58:
        return 1.0
    u = min(1.0, max(0.0, (t - 0.58) / 0.42))
    return max(0.015, (1.0 - u) ** 1.45)


def _section_factor(v: float) -> float:
    if v < 0.12:
        return 0.15 + 0.40 * (v / 0.12) ** 0.45
    if v < 0.70:
        return 0.55 + 0.45 * ((v - 0.12) / 0.58) ** 0.40
    return 1.0 + 0.07 * ((v - 0.70) / 0.30)


def _bulb(t: float, v: float) -> float:
    dt = (t - 1.01) / 0.09
    dv = (v - 0.22) / 0.11
    if abs(dt) > 1.6 or abs(dv) > 1.7:
        return 0.0
    return math.exp(-2.2 * dt * dt - 2.4 * dv * dv)


def merchant_hull(length: float, beam: float, height: float, material: str, stations: int = 64, rings: int = 26, bulb: bool = True) -> list[Part]:
    t_end = 1.12 if bulb else 1.0
    ts = np.linspace(0.0, t_end, stations)
    vs = np.linspace(0.0, 1.0, rings)
    water = 0.40
    grid = np.zeros((stations, rings, 2, 3), dtype=np.float64)
    for i, t in enumerate(ts):
        sheer = height * (0.05 * (float(t) - 0.45) ** 2 + (0.04 * float(t) if t > 0.7 else 0.0))
        z = (0.5 - float(t)) * length
        for j, v in enumerate(vs):
            y = sheer + float(v) * height * (1.0 + 0.10 * abs(float(t) - 0.4))
            half = (beam * 0.5) * _beam_factor(min(float(t), 1.0)) * _section_factor(float(v))
            if bulb and t > 0.78:
                half += beam * 0.22 * _bulb(float(t), float(v))
                if t > 1.0 and v > 0.48:
                    half *= max(0.0, 1.0 - (float(v) - 0.48) / 0.52) * max(0.0, 1.0 - (float(t) - 1.0) / 0.12)
            grid[i, j, 0] = (half, y, z)
            grid[i, j, 1] = (-half, y, z)

    def skin(side: int) -> tuple[Part, Part, Part]:
        upper, lower, boot = Part(material), Part("antifoul"), Part("boot")
        for i in range(stations - 1):
            for j in range(rings - 1):
                v_mid = float((vs[j] + vs[j + 1]) * 0.5)
                if abs(v_mid - water) < 0.055:
                    dest = boot
                elif v_mid < water:
                    dest = lower
                else:
                    dest = upper
                a, b = grid[i, j, side], grid[i + 1, j, side]
                c, d = grid[i + 1, j + 1, side], grid[i, j + 1, side]
                uvs = ((float(ts[i]), float(vs[j])), (float(ts[i + 1]), float(vs[j])), (float(ts[i + 1]), float(vs[j + 1])), (float(ts[i]), float(vs[j + 1])))
                if side == 0:
                    dest.quad(a, b, c, d, np.cross(b - a, d - a), uvs)
                else:
                    dest.quad(a, d, c, b, np.cross(d - a, b - a), (uvs[0], uvs[3], uvs[2], uvs[1]))
        return upper, lower, boot

    parts = list(skin(0)) + list(skin(1))
    deck = Part("deck")
    for i in range(stations - 1):
        if float(ts[i]) > 1.02:
            continue
        a_s = grid[i, -1, 0].copy()
        b_s = grid[i + 1, -1, 0].copy()
        a_p = grid[i, -1, 1].copy()
        b_p = grid[i + 1, -1, 1].copy()
        mid_a = np.array([0.0, max(a_s[1], a_p[1]) + beam * 0.012, a_s[2]])
        mid_b = np.array([0.0, max(b_s[1], b_p[1]) + beam * 0.012, b_s[2]])
        deck.quad(mid_a, mid_b, b_s, a_s, (0, 1, 0))
        deck.quad(a_p, b_p, mid_b, mid_a, (0, 1, 0))
    parts.append(deck)
    transom = Part(material)
    for j in range(rings - 1):
        transom.quad(grid[0, j, 0], grid[0, j, 1], grid[0, j + 1, 1], grid[0, j + 1, 0], (0, 0, 1))
    parts.append(transom)
    _crease_normals(parts)
    return [p for p in parts if p.indices]


def _crease_normals(parts: list[Part]) -> None:
    for part in parts:
        if not part.indices:
            continue
        pos = np.asarray(part.positions, dtype=np.float64)
        acc = np.zeros_like(pos)
        idx = np.asarray(part.indices, dtype=np.int64)
        for t in range(0, len(idx), 3):
            a, b, c = int(idx[t]), int(idx[t + 1]), int(idx[t + 2])
            fn = np.cross(pos[b] - pos[a], pos[c] - pos[a])
            acc[a] += fn
            acc[b] += fn
            acc[c] += fn
        lengths = np.linalg.norm(acc, axis=1, keepdims=True)
        lengths[lengths < 1e-12] = 1.0
        acc /= lengths
        part.normals = [tuple(float(n) for n in row) for row in acc]


def add_windows(parts: list[Part], origin, across: int, up: int, size, axis: str = "z") -> None:
    o = np.asarray(origin, float)
    sx, sy = size
    for ix in range(across):
        for iy in range(up):
            if axis == "z":
                add_box(parts, o + np.array([ix * sx * 1.7, iy * sy * 1.8, 0.0]), (sx, sy, 0.012), "glass")
            else:
                add_box(parts, o + np.array([0.0, iy * sy * 1.8, ix * sx * 1.7]), (0.012, sy, sx), "glass")


def add_railing(parts: list[Part], z0: float, z1: float, x: float, y: float, posts: int = 10) -> None:
    if posts < 2:
        return
    for i in range(posts):
        z = z0 + (z1 - z0) * i / (posts - 1)
        add_cylinder(parts, (x, y, z), (x, y + 0.045, z), 0.006, "metal", segs=6, caps=False)
    add_cylinder(parts, (x, y + 0.045, z0), (x, y + 0.045, z1), 0.004, "dark_metal", segs=5, caps=False)


def add_container(parts: list[Part], center, size, material: str, ribs: int = 8) -> None:
    c = np.asarray(center, float)
    w, h, length = size
    hx, hy, hz = w * 0.5, h * 0.5, length * 0.5
    part = Part(material)
    y0, y1 = c[1] - hy, c[1] + hy
    ribs = max(int(ribs), 2)
    for sign in (1.0, -1.0):
        x_face = c[0] + sign * hx
        for i in range(ribs):
            za = c[2] - hz + length * i / ribs
            zb = za + length / ribs
            proud = 0.008 * sign * (1 if i % 2 == 0 else -0.15)
            p0 = np.array([x_face + proud, y0, za])
            p1 = np.array([x_face + proud, y0, zb])
            p2 = np.array([x_face + proud, y1, zb])
            p3 = np.array([x_face + proud, y1, za])
            if sign > 0:
                part.quad(p0, p1, p2, p3, (sign, 0, 0))
            else:
                part.quad(p1, p0, p3, p2, (sign, 0, 0))
    for z_sign, outward in ((1.0, (0, 0, 1)), (-1.0, (0, 0, -1))):
        z = c[2] + z_sign * hz
        inset = 0.006 if z_sign < 0 else 0.0
        p0 = np.array([c[0] - hx, y0, z + z_sign * inset])
        p1 = np.array([c[0] + hx, y0, z + z_sign * inset])
        p2 = np.array([c[0] + hx, y1, z + z_sign * inset])
        p3 = np.array([c[0] - hx, y1, z + z_sign * inset])
        if z_sign > 0:
            part.quad(p0, p1, p2, p3, outward)
        else:
            part.quad(p1, p0, p3, p2, outward)
    part.quad(
        np.array([c[0] - hx, y1, c[2] - hz]),
        np.array([c[0] - hx, y1, c[2] + hz]),
        np.array([c[0] + hx, y1, c[2] + hz]),
        np.array([c[0] + hx, y1, c[2] - hz]),
        (0, 1, 0),
    )
    part.quad(
        np.array([c[0] - hx, y0, c[2] - hz]),
        np.array([c[0] + hx, y0, c[2] - hz]),
        np.array([c[0] + hx, y0, c[2] + hz]),
        np.array([c[0] - hx, y0, c[2] + hz]),
        (0, -1, 0),
    )
    parts.append(part)
    if ribs <= 2:
        return
    for sx in (-1, 1):
        for sz in (-1, 1):
            for sy in (-1, 1):
                add_box(
                    parts,
                    (c[0] + sx * (hx - 0.008), c[1] + sy * (hy - 0.006), c[2] + sz * (hz - 0.008)),
                    (0.016, 0.014, 0.016),
                    "dark_metal",
                )


def add_hatch(parts: list[Part], center, size) -> None:
    add_box(parts, center, size, "deck")
    cx, cy, cz = center
    w, h, length = size
    lip = 0.012
    add_box(parts, (cx, cy + h * 0.5, cz), (w + 0.02, lip, length + 0.02), "dark_metal")
    for i in range(4):
        z = cz - length * 0.5 + length * (i + 0.5) / 4
        add_box(parts, (cx, cy + h * 0.5 + lip * 0.5, z), (w * 0.92, 0.01, 0.012), "metal")


def add_crane(parts: list[Part], base, reach: float = 0.34) -> None:
    bx, by, bz = base
    add_cylinder(parts, (bx, by, bz), (bx, by + 0.16, bz), 0.028, "yellow", segs=10)
    add_cylinder(parts, (bx, by + 0.15, bz), (bx, by + 0.22, bz - reach), 0.012, "yellow", segs=8)
    add_cylinder(parts, (bx, by + 0.22, bz - reach), (bx, by + 0.02, bz - reach), 0.004, "dark_metal", segs=5, caps=False)
    g = (bx, by + 0.015, bz - reach)
    add_box(parts, g, (0.03, 0.02, 0.03), "dark_metal")
    add_box(parts, (g[0] - 0.02, g[1] - 0.02, g[2]), (0.008, 0.03, 0.02), "metal")
    add_box(parts, (g[0] + 0.02, g[1] - 0.02, g[2]), (0.008, 0.03, 0.02), "metal")


def add_funnel(parts: list[Part], center, size, band: str = "yellow") -> None:
    add_tapered_box(parts, center, size, 0.72, "white")
    cx, cy, cz = center
    _, h, _ = size
    add_box(parts, (cx, cy + h * 0.05, cz), (size[0] * 0.78, h * 0.18, size[2] * 0.78), band)
    add_box(parts, (cx, cy + h * 0.55, cz), (size[0] * 0.5, 0.02, size[2] * 0.5), "black")


def add_lifeboat(parts: list[Part], center, length: float = 0.22) -> None:
    c = np.asarray(center, float)
    segs_l, segs_a = 10, 12
    rings = []
    for i in range(segs_l):
        t = i / (segs_l - 1)
        z = (t - 0.5) * length
        profile = math.sin(t * math.pi) ** 0.6
        ry = 0.035 * profile + 0.01
        rx = 0.028 * profile + 0.008
        ring = []
        for a in range(segs_a):
            ang = 2 * math.pi * a / segs_a
            ring.append(c + np.array([math.cos(ang) * rx, math.sin(ang) * ry * 0.7 + 0.01, z]))
        rings.append(ring)
    part = Part("c_orange")
    for i in range(segs_l - 1):
        for a in range(segs_a):
            b = (a + 1) % segs_a
            part.quad(rings[i][a], rings[i][b], rings[i + 1][b], rings[i + 1][a], rings[i][a] - c)
    parts.append(part)
    _crease_normals([part])
    add_box(parts, c + np.array([0.0, 0.04, 0.0]), (0.04, 0.02, length * 0.45), "white")


def add_anchor(parts: list[Part], center) -> None:
    c = np.asarray(center, float)
    add_cylinder(parts, c, c + np.array([0.0, -0.08, 0.0]), 0.008, "dark_metal", segs=6)
    add_box(parts, c + np.array([0.0, -0.09, 0.02]), (0.05, 0.012, 0.03), "dark_metal")
    add_box(parts, c + np.array([-0.02, -0.07, 0.03]), (0.012, 0.03, 0.02), "metal")
    add_box(parts, c + np.array([0.02, -0.07, 0.03]), (0.012, 0.03, 0.02), "metal")


def add_prop_and_rudder(parts: list[Part], stern_z: float, y: float) -> None:
    hub = np.array([0.0, y, stern_z - 0.02])
    add_cylinder(parts, hub, hub + np.array([0.0, 0.0, 0.06]), 0.018, "bronze", segs=10)
    for k in range(4):
        ang = k * math.pi / 2 + 0.4
        direction = np.array([math.cos(ang), math.sin(ang) * 0.35, 0.15])
        direction = direction / np.linalg.norm(direction)
        tip = hub + direction * 0.09
        add_box(parts, (hub + tip) * 0.5, (0.012, 0.045, 0.02), "bronze")
    add_box(parts, (0.0, y, stern_z + 0.06), (0.012, 0.12, 0.07), "antifoul")
    add_cylinder(parts, (0, y + 0.06, stern_z + 0.06), (0, y + 0.12, stern_z + 0.06), 0.008, "dark_metal", segs=6)


def add_bridge(parts: list[Part], center, size, windows_forward: bool = True) -> None:
    add_box(parts, center, size, "white")
    cx, cy, cz = center
    w, h, length = size
    house = (cx, cy + h * 0.5 + 0.07, cz - length * 0.05)
    add_box(parts, house, (w * 0.72, 0.12, length * 0.62), "white")
    if windows_forward:
        add_windows(parts, (cx - w * 0.22, cy - h * 0.15, cz - length * 0.5 - 0.008), 4, 2, (0.035, 0.028), axis="z")
        add_windows(parts, (house[0] - w * 0.18, house[1] - 0.02, house[2] - length * 0.31 - 0.008), 3, 1, (0.04, 0.03), axis="z")
    add_box(parts, (cx - w * 0.5 - 0.02, cy + h * 0.15, cz), (0.06, 0.04, length * 0.28), "white")
    add_box(parts, (cx + w * 0.5 + 0.02, cy + h * 0.15, cz), (0.06, 0.04, length * 0.28), "white")
    add_cylinder(parts, (cx, cy + h * 0.5 + 0.16, cz + length * 0.15), (cx, cy + h * 0.5 + 0.34, cz + length * 0.15), 0.008, "metal", segs=6)
    add_box(parts, (cx, cy + h * 0.5 + 0.33, cz + length * 0.12), (0.06, 0.012, 0.06), "dark_metal")


def add_sail(parts: list[Part], center, size, material: str = "sub_panel") -> None:
    cx, cy, cz = center
    w, h, length = (float(v) for v in size)
    add_box(parts, center, (w * 0.62, h, length * 0.72), material)
    for z_sign in (-1.0, 1.0):
        add_cylinder(
            parts,
            (cx, cy - h * 0.48, cz + z_sign * length * 0.28),
            (cx, cy + h * 0.48, cz + z_sign * length * 0.28),
            w * 0.34,
            material,
            segs=14,
        )
    add_cylinder(parts, (cx, cy + h * 0.42, cz), (cx, cy + h * 0.55, cz), w * 0.28, "sub", segs=14)


def lathe_sub(length: float, radius: float, along: int = 96, around: int = 48) -> list[Part]:
    body = Part("sub")
    rings = []
    for i in range(along):
        t = i / (along - 1)
        z = (0.5 - t) * length
        if t < 0.10:
            r = radius * (0.25 + 0.75 * (t / 0.10) ** 0.7)
        elif t > 0.86:
            u = max(0.0, (1.0 - t) / 0.14)
            r = radius * (u ** 0.55)
        else:
            r = radius * (1.0 - 0.04 * math.cos((t - 0.1) * math.pi))
        ring = []
        for a in range(around):
            ang = 2 * math.pi * a / around
            panel = 1.0 + (0.004 if (i % 8 == 0 or a % 8 == 0) else 0.0)
            ring.append(np.array([math.cos(ang) * r * 1.02 * panel, math.sin(ang) * r * 0.92 * panel + radius, z]))
        rings.append(ring)
    for i in range(along - 1):
        for a in range(around):
            b = (a + 1) % around
            p0, p1 = rings[i][a], rings[i][b]
            p2, p3 = rings[i + 1][b], rings[i + 1][a]
            body.quad(p0, p3, p2, p1, np.cross(p3 - p0, p1 - p0))
    parts = [body]
    _crease_normals(parts)
    return parts


def count_tris(parts: list[Part]) -> int:
    return sum(len(p.indices) // 3 for p in parts)


def bounds(parts: list[Part]) -> tuple[np.ndarray, np.ndarray]:
    pos = np.vstack([np.asarray(p.positions, dtype=np.float64) for p in parts if p.positions])
    return pos.min(axis=0), pos.max(axis=0)


def hull_albedo(color: tuple[int, int, int], path: Path | None = None) -> bytes:
    w, h = 1024, 512
    img = Image.new("RGB", (w, h), color)
    px = img.load()
    for y in range(h):
        v = y / (h - 1)
        if v < 0.40:
            col = (122, 28, 22)
        elif v < 0.46:
            col = (230, 228, 220)
        else:
            col = color
        for x in range(w):
            c = col
            if 0.46 <= v < 0.62 and (x * 17 + y * 3) % 47 == 0:
                c = tuple(max(0, ch - 35) for ch in col)
            if v > 0.90 and x % 64 < 2:
                c = tuple(min(255, ch + 30) for ch in col)
            px[x, y] = c
    draw = ImageDraw.Draw(img)
    for i, label in enumerate(("2", "4", "6", "8")):
        y = int(h * (0.18 + i * 0.07))
        x = w - 70
        draw.rectangle([x, y, x + 28, y + 3], fill=(20, 16, 14))
        draw.text((x + 32, y - 4), label, fill=(20, 16, 14))
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    if path is not None:
        path.write_bytes(buf.getvalue())
    return buf.getvalue()


def write_glb(path: Path, parts: list[Part], hull_png: bytes | None = None, hull_materials: set[str] | None = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    used = []
    for part in parts:
        if part.indices and part.material not in used:
            used.append(part.material)
    blobs: list[bytes] = []
    views = []
    accessors = []
    primitives = []

    def push_blob(raw: bytes, target: int | None) -> int:
        offset = sum(len(b) for b in blobs)
        pad = (4 - (len(raw) % 4)) % 4
        blobs.append(raw + b"\x00" * pad)
        view = {"buffer": 0, "byteOffset": offset, "byteLength": len(raw)}
        if target is not None:
            view["target"] = target
        views.append(view)
        return len(views) - 1

    image_view = push_blob(hull_png, None) if hull_png else None
    for part in parts:
        if not part.indices:
            continue
        pos = np.asarray(part.positions, dtype=np.float32)
        nrm = np.asarray(part.normals, dtype=np.float32)
        uv = np.asarray(part.uvs, dtype=np.float32)
        idx = np.asarray(part.indices, dtype=np.uint32)
        vp, vn, vu, vi = (
            push_blob(pos.tobytes(), 34962),
            push_blob(nrm.tobytes(), 34962),
            push_blob(uv.tobytes(), 34962),
            push_blob(idx.tobytes(), 34963),
        )
        base = len(accessors)
        accessors.extend([
            {"bufferView": vp, "componentType": 5126, "count": int(pos.shape[0]), "type": "VEC3", "min": pos.min(0).tolist(), "max": pos.max(0).tolist()},
            {"bufferView": vn, "componentType": 5126, "count": int(nrm.shape[0]), "type": "VEC3"},
            {"bufferView": vu, "componentType": 5126, "count": int(uv.shape[0]), "type": "VEC2"},
            {"bufferView": vi, "componentType": 5125, "count": int(idx.shape[0]), "type": "SCALAR"},
        ])
        primitives.append((part.material, base))
    mat_index = {name: i for i, name in enumerate(used)}
    hull_set = hull_materials or set()
    materials = []
    for name in used:
        color, metal, rough = MATERIALS[name]
        pbr = {"baseColorFactor": list(color), "metallicFactor": metal, "roughnessFactor": rough}
        if hull_png and name in hull_set and image_view is not None:
            pbr["baseColorTexture"] = {"index": 0}
        materials.append({"name": name, "doubleSided": False, "pbrMetallicRoughness": pbr})
    doc = {
        "asset": {"version": "2.0", "generator": "p47-shipyard"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"name": "ship", "mesh": 0}],
        "materials": materials,
        "meshes": [{"name": "hull", "primitives": [{
            "attributes": {"POSITION": base, "NORMAL": base + 1, "TEXCOORD_0": base + 2},
            "indices": base + 3,
            "material": mat_index[mat],
            "mode": 4,
        } for mat, base in primitives]}],
        "accessors": accessors,
        "bufferViews": views,
        "buffers": [{"byteLength": sum(len(b) for b in blobs)}],
    }
    if hull_png and image_view is not None:
        doc["images"] = [{"bufferView": image_view, "mimeType": "image/png"}]
        doc["textures"] = [{"source": 0}]
        doc["samplers"] = [{"magFilter": 9729, "minFilter": 9986}]
    js = json.dumps(doc, separators=(",", ":")).encode("utf-8")
    js += b" " * ((4 - len(js) % 4) % 4)
    blob = b"".join(blobs)

    def chunk(kind: int, data: bytes) -> bytes:
        return struct.pack("<II", len(data), kind) + data

    body = chunk(0x4E4F534A, js) + chunk(0x004E4942, blob)
    path.write_bytes(struct.pack("<III", 0x46546C67, 2, 12 + len(body)) + body)
