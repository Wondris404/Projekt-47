"""Container ship, round 2.1. Blender 4.2, headless.

Game axis after glTF export (Y-up): bow -Z, keel Y=0, beam X.
Blender is Z-up, so this file builds in game axis and converts with B().

v2.1 fixes, still procedural:
- side rails follow the deck edge, lashing posts sit outside the outer row
- wheelhouse windows are dark glass and clear the tallest stack
- bays are one 40 ft box or two 20 ft boxes, constant gap, no half-holes
"""
from __future__ import annotations

import math
import random
import sys
from pathlib import Path

import bpy
import bmesh

ROOT = Path(__file__).resolve().parents[3]

LENGTH = 3.5
BEAM = 0.64
HEIGHT = 0.44
CW = 0.100
CH = 0.096
ROW_PITCH = 0.108
BAY_GAP = 0.012
INNER_GAP = 0.01
# Bay step. A 40 ft box is the bay minus the constant gap, so the hole
# left by the old 0.44*pitch lengths cannot come back. Two 20 ft boxes
# fill that same length with INNER_GAP between them.
BAY_PITCH = 0.172


def B(x: float, y: float, z: float) -> tuple[float, float, float]:
    """Game (X beam, Y up, Z stern-positive) -> Blender (X, -Z, Y)."""
    return (x, -z, y)


def reset() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def beam_factor(t: float) -> float:
    if t < 0.14:
        return 0.50 + 0.50 * (t / 0.14) ** 0.75
    if t < 0.58:
        return 1.0
    u = min(1.0, max(0.0, (t - 0.58) / 0.42))
    return max(0.015, (1.0 - u) ** 1.45)


def section_factor(v: float) -> float:
    if v < 0.12:
        return 0.15 + 0.40 * (v / 0.12) ** 0.45
    if v < 0.70:
        return 0.55 + 0.45 * ((v - 0.12) / 0.58) ** 0.40
    return 1.0 + 0.07 * ((v - 0.70) / 0.30)


def bulb(t: float, v: float) -> float:
    dt = (t - 1.01) / 0.09
    dv = (v - 0.22) / 0.11
    if abs(dt) > 1.6 or abs(dv) > 1.7:
        return 0.0
    return math.exp(-2.2 * dt * dt - 2.4 * dv * dv)


def half_beam_at(z: float) -> float:
    """Half-width of the deck at z. Same factors as Ship.hull()."""
    t = 0.5 - z / LENGTH
    if t < 0.0 or t > 1.02:
        return 0.0
    v = 1.0
    half = (BEAM * 0.5) * beam_factor(min(t, 1.0)) * section_factor(v)
    if t > 0.78:
        half += BEAM * 0.22 * bulb(t, v)
        if t > 1.0 and v > 0.48:
            half *= max(0.0, 1.0 - (v - 0.48) / 0.52) * max(0.0, 1.0 - (t - 1.0) / 0.12)
    return max(0.0, half)


def deck_y_at(z: float) -> float:
    """Deck height at z, including the camber the hull mesh adds."""
    t = min(1.12, max(0.0, 0.5 - z / LENGTH))
    sheer = HEIGHT * (0.05 * (t - 0.45) ** 2 + (0.04 * t if t > 0.7 else 0.0))
    y = sheer + HEIGHT * (1.0 + 0.10 * abs(t - 0.4))
    return y + BEAM * 0.012


def min_half(z0: float, z1: float) -> float:
    return min(half_beam_at(z0), half_beam_at(z1), half_beam_at(0.5 * (z0 + z1)))


def aabb_of(center, size) -> tuple[float, float, float, float, float, float]:
    cx, cy, cz = center
    hx, hy, hz = size[0] * 0.5, size[1] * 0.5, size[2] * 0.5
    return (cx - hx, cy - hy, cz - hz, cx + hx, cy + hy, cz + hz)


def overlaps(a, b, tol: float = 0.001) -> bool:
    return (
        min(a[3], b[3]) - max(a[0], b[0]) > tol
        and min(a[4], b[4]) - max(a[1], b[1]) > tol
        and min(a[5], b[5]) - max(a[2], b[2]) > tol
    )


def gap_x(a, b) -> float:
    if a[3] <= b[0]:
        return b[0] - a[3]
    if b[3] <= a[0]:
        return a[0] - b[3]
    return -(min(a[3], b[3]) - max(a[0], b[0]))


def shares_yz(a, b) -> bool:
    return min(a[4], b[4]) > max(a[1], b[1]) and min(a[5], b[5]) > max(a[2], b[2])


def stripe_image(name: str, colors: list[tuple[float, float, float]], w: int = 64, h: int = 16):
    img = bpy.data.images.new(name, w, h, alpha=False)
    px = [0.0] * (w * h * 4)
    n = len(colors)
    for y in range(h):
        for x in range(w):
            c = colors[min(n - 1, int(x * n / w))]
            i = (y * w + x) * 4
            px[i : i + 4] = (c[0], c[1], c[2], 1.0)
    img.pixels.foreach_set(px)
    img.pack()
    return img


def hull_image():
    w, h = 256, 128
    img = bpy.data.images.new("hull_blue", w, h, alpha=False)
    blue = (0.11, 0.28, 0.42)
    red = (0.48, 0.11, 0.09)
    boot = (0.90, 0.89, 0.84)
    px = [0.0] * (w * h * 4)
    for y in range(h):
        v = y / (h - 1)
        if v < 0.40:
            c = red
        elif v < 0.47:
            c = boot
        else:
            c = blue
            if int(y) % 17 == 0:
                c = (c[0] * 0.85, c[1] * 0.85, c[2] * 0.85)
        for x in range(w):
            cc = c
            if v > 0.40 and x % 32 == 0:
                cc = (min(1, c[0] + 0.08), min(1, c[1] + 0.06), min(1, c[2] + 0.04))
            i = (y * w + x) * 4
            px[i : i + 4] = (*cc, 1.0)
    img.pixels.foreach_set(px)
    img.pack()
    return img


def deck_image():
    w, h = 128, 64
    img = bpy.data.images.new("deck_metal", w, h, alpha=False)
    base = (0.22, 0.28, 0.24)
    px = [0.0] * (w * h * 4)
    for y in range(h):
        for x in range(w):
            c = base
            if x % 16 == 0 or y % 10 == 0:
                c = (0.12, 0.14, 0.12)
            i = (y * w + x) * 4
            px[i : i + 4] = (*c, 1.0)
    img.pixels.foreach_set(px)
    img.pack()
    return img


def new_mat(name: str, color, metal: float, rough: float, image=None):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (color[0], color[1], color[2], 1.0)
    bsdf.inputs["Metallic"].default_value = metal
    bsdf.inputs["Roughness"].default_value = rough
    if image is not None:
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = image
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    return m


class Ship:
    def __init__(self) -> None:
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.new("UVMap")
        self.mats = []

    def add_mat(self, m) -> int:
        self.mats.append(m)
        return len(self.mats) - 1

    def quad(self, pts, mat: int, uvs) -> None:
        vs = [self.bm.verts.new(B(*p)) for p in pts]
        self.bm.verts.ensure_lookup_table()
        try:
            face = self.bm.faces.new(vs)
        except ValueError:
            return
        face.material_index = mat
        face.smooth = True
        for loop, uv in zip(face.loops, uvs):
            loop[self.uv].uv = uv

    def box(self, center, size, mat: int, uv=(0.5, 0.5)) -> None:
        cx, cy, cz = center
        hx, hy, hz = size[0] * 0.5, size[1] * 0.5, size[2] * 0.5
        faces = [
            [(cx + hx, cy - hy, cz - hz), (cx + hx, cy - hy, cz + hz), (cx + hx, cy + hy, cz + hz), (cx + hx, cy + hy, cz - hz)],
            [(cx - hx, cy - hy, cz + hz), (cx - hx, cy - hy, cz - hz), (cx - hx, cy + hy, cz - hz), (cx - hx, cy + hy, cz + hz)],
            [(cx - hx, cy + hy, cz - hz), (cx + hx, cy + hy, cz - hz), (cx + hx, cy + hy, cz + hz), (cx - hx, cy + hy, cz + hz)],
            [(cx - hx, cy - hy, cz + hz), (cx + hx, cy - hy, cz + hz), (cx + hx, cy - hy, cz - hz), (cx - hx, cy - hy, cz - hz)],
            [(cx - hx, cy - hy, cz + hz), (cx - hx, cy + hy, cz + hz), (cx + hx, cy + hy, cz + hz), (cx + hx, cy - hy, cz + hz)],
            [(cx + hx, cy - hy, cz - hz), (cx + hx, cy + hy, cz - hz), (cx - hx, cy + hy, cz - hz), (cx - hx, cy - hy, cz - hz)],
        ]
        u = (uv, uv, uv, uv)
        for f in faces:
            self.quad(f, mat, u)

    def cylinder(self, a, b, radius: float, mat: int, sides: int = 6) -> None:
        ax = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
        length = math.sqrt(ax[0] ** 2 + ax[1] ** 2 + ax[2] ** 2) or 1.0
        ax = (ax[0] / length, ax[1] / length, ax[2] / length)
        helper = (0.0, 1.0, 0.0) if abs(ax[1]) < 0.9 else (1.0, 0.0, 0.0)
        ux = (
            ax[1] * helper[2] - ax[2] * helper[1],
            ax[2] * helper[0] - ax[0] * helper[2],
            ax[0] * helper[1] - ax[1] * helper[0],
        )
        ul = math.sqrt(ux[0] ** 2 + ux[1] ** 2 + ux[2] ** 2) or 1.0
        ux = (ux[0] / ul, ux[1] / ul, ux[2] / ul)
        vx = (
            ax[1] * ux[2] - ax[2] * ux[1],
            ax[2] * ux[0] - ax[0] * ux[2],
            ax[0] * ux[1] - ax[1] * ux[0],
        )
        rings = []
        for p in (a, b):
            ring = []
            for i in range(sides):
                ang = i * math.tau / sides
                ring.append(
                    (
                        p[0] + radius * (math.cos(ang) * ux[0] + math.sin(ang) * vx[0]),
                        p[1] + radius * (math.cos(ang) * ux[1] + math.sin(ang) * vx[1]),
                        p[2] + radius * (math.cos(ang) * ux[2] + math.sin(ang) * vx[2]),
                    )
                )
            rings.append(ring)
        for i in range(sides):
            j = (i + 1) % sides
            self.quad([rings[0][i], rings[0][j], rings[1][j], rings[1][i]], mat, ((0, 0), (1, 0), (1, 1), (0, 1)))

    def hull(self, length, beam, height, mat_hull: int, mat_deck: int, stations=90, rings=28) -> float:
        t_end = 1.12
        ts = [i * t_end / (stations - 1) for i in range(stations)]
        vs = [j / (rings - 1) for j in range(rings)]
        grid = []
        deck_y = 0.0
        for t in ts:
            sheer = height * (0.05 * (t - 0.45) ** 2 + (0.04 * t if t > 0.7 else 0.0))
            z = (0.5 - t) * length
            ring = []
            for v in vs:
                y = sheer + v * height * (1.0 + 0.10 * abs(t - 0.4))
                half = (beam * 0.5) * beam_factor(min(t, 1.0)) * section_factor(v)
                if t > 0.78:
                    half += beam * 0.22 * bulb(t, v)
                    if t > 1.0 and v > 0.48:
                        half *= max(0.0, 1.0 - (v - 0.48) / 0.52) * max(0.0, 1.0 - (t - 1.0) / 0.12)
                ring.append((half, y, z, t, v))
            deck_y = max(deck_y, ring[-1][1])
            grid.append(ring)
        for side in (1.0, -1.0):
            for i in range(stations - 1):
                for j in range(rings - 1):
                    a, b = grid[i][j], grid[i + 1][j]
                    c, d = grid[i + 1][j + 1], grid[i][j + 1]
                    pts = [
                        (side * a[0], a[1], a[2]),
                        (side * b[0], b[1], b[2]),
                        (side * c[0], c[1], c[2]),
                        (side * d[0], d[1], d[2]),
                    ]
                    if side < 0:
                        pts = [pts[0], pts[3], pts[2], pts[1]]
                    uvs = ((a[3], a[4]), (b[3], b[4]), (c[3], c[4]), (d[3], d[4]))
                    if side < 0:
                        uvs = (uvs[0], uvs[3], uvs[2], uvs[1])
                    self.quad(pts, mat_hull, uvs)
        for i in range(stations - 1):
            if ts[i] > 1.02:
                continue
            a, b = grid[i][-1], grid[i + 1][-1]
            mid_a = (0.0, a[1] + beam * 0.012, a[2])
            mid_b = (0.0, b[1] + beam * 0.012, b[2])
            self.quad([mid_a, mid_b, (b[0], b[1], b[2]), (a[0], a[1], a[2])], mat_deck, ((0, 0), (1, 0), (1, 1), (0, 1)))
            self.quad([(-a[0], a[1], a[2]), (-b[0], b[1], b[2]), mid_b, mid_a], mat_deck, ((0, 0), (1, 0), (1, 1), (0, 1)))
            deck_y = max(deck_y, mid_a[1], mid_b[1])
        for j in range(rings - 1):
            a, b = grid[0][j], grid[0][j + 1]
            self.quad(
                [(a[0], a[1], a[2]), (-a[0], a[1], a[2]), (-b[0], b[1], b[2]), (b[0], b[1], b[2])],
                mat_hull,
                ((a[3], a[4]), (a[3], a[4]), (b[3], b[4]), (b[3], b[4])),
            )
        return deck_y

    def container(self, center, size, mat: int, band: int, bands: int = 5, ribs: int = 6) -> None:
        cx, cy, cz = center
        w, h, length = size
        hx, hy, hz = w * 0.5, h * 0.5, length * 0.5
        u = (band + 0.5) / bands
        uv = ((u, 0.15), (u, 0.15), (u, 0.85), (u, 0.85))
        y0, y1 = cy - hy, cy + hy
        for sign in (1.0, -1.0):
            x_face = cx + sign * hx
            for i in range(ribs):
                za = cz - hz + length * i / ribs
                zb = za + length / ribs
                proud = 0.004 * sign * (1 if i % 2 == 0 else -0.15)
                pts = [
                    (x_face + proud, y0, za),
                    (x_face + proud, y0, zb),
                    (x_face + proud, y1, zb),
                    (x_face + proud, y1, za),
                ]
                if sign < 0:
                    pts = [pts[1], pts[0], pts[3], pts[2]]
                self.quad(pts, mat, uv)
        for z_sign in (1.0, -1.0):
            z = cz + z_sign * hz
            pts = [
                (cx - hx, y0, z),
                (cx + hx, y0, z),
                (cx + hx, y1, z),
                (cx - hx, y1, z),
            ]
            if z_sign < 0:
                pts = [pts[1], pts[0], pts[3], pts[2]]
            self.quad(pts, mat, uv)
        self.quad(
            [(cx - hx, y1, cz - hz), (cx - hx, y1, cz + hz), (cx + hx, y1, cz + hz), (cx + hx, y1, cz - hz)],
            mat,
            uv,
        )
        self.quad(
            [(cx - hx, y0, cz - hz), (cx + hx, y0, cz - hz), (cx + hx, y0, cz + hz), (cx - hx, y0, cz + hz)],
            mat,
            uv,
        )

    def finish(self, path: Path) -> None:
        mesh = bpy.data.meshes.new("ContainerShip")
        self.bm.to_mesh(mesh)
        self.bm.free()
        for m in self.mats:
            mesh.materials.append(m)
        obj = bpy.data.objects.new("ContainerShip", mesh)
        bpy.context.collection.objects.link(obj)
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        mod = obj.modifiers.new("WeightedNormal", "WEIGHTED_NORMAL")
        mod.keep_sharp = True
        path.parent.mkdir(parents=True, exist_ok=True)
        bpy.ops.export_scene.gltf(
            filepath=str(path),
            export_format="GLB",
            export_apply=True,
            export_yup=True,
            use_selection=True,
        )


def _rows_for(half: float, cap: int) -> int:
    n = max(1, int(math.floor((2.0 * half - 0.06) / ROW_PITCH)))
    n = min(n, cap)
    while n > 1:
        outer = (n - 1) * 0.5 * ROW_PITCH + CW * 0.5
        if outer <= half - 0.04:
            break
        n -= 1
    return n


def _check(containers, fittings) -> None:
    hits = 0
    for fname, fa, kind in fittings:
        for cname, ca in containers:
            if overlaps(fa, ca):
                hits += 1
                print(f"OVERLAP {fname} x {cname} fit={tuple(round(v, 3) for v in fa)} box={tuple(round(v, 3) for v in ca)}")
            elif shares_yz(fa, ca):
                gap = gap_x(fa, ca)
                need = 0.005 if kind == "post" else 0.01
                if gap < need:
                    hits += 1
                    print(f"GAP {gap:.4f} < {need} {fname} x {cname}")
    if hits:
        print(f"OVERLAP_FAIL {hits}")
        sys.exit(1)
    print("OVERLAP_OK 0")


def build(out: Path, level: int = 0) -> None:
    reset()
    if level <= 0:
        stations, rings, bays, ribs, cap = 120, 34, 10, 4, 5
        rail_post = 0.15
        windows = True
        details = True
    elif level == 1:
        stations, rings, bays, ribs, cap = 34, 12, 8, 1, 4
        rail_post = 0.45
        windows = True
        details = False
    else:
        stations, rings, bays, ribs, cap = 16, 7, 6, 1, 3
        rail_post = 0.0
        windows = False
        details = False
    ship = Ship()
    hull_mat = ship.add_mat(new_mat("hull", (0.11, 0.28, 0.42), 0.15, 0.48, hull_image()))
    deck_mat = ship.add_mat(new_mat("deck", (0.22, 0.28, 0.24), 0.45, 0.62, deck_image()))
    colors = [
        (0.62, 0.16, 0.12),
        (0.12, 0.28, 0.55),
        (0.14, 0.40, 0.24),
        (0.72, 0.42, 0.12),
        (0.45, 0.47, 0.46),
    ]
    box_mat = ship.add_mat(new_mat("containers", (0.5, 0.5, 0.5), 0.25, 0.5, stripe_image("boxes", colors)))
    paint_mat = ship.add_mat(
        new_mat(
            "paint",
            (0.9, 0.9, 0.88),
            0.05,
            0.4,
            stripe_image("paint", [(0.90, 0.90, 0.86), (0.78, 0.62, 0.12), (0.65, 0.12, 0.10), (0.10, 0.45, 0.22)]),
        )
    )
    metal_mat = ship.add_mat(new_mat("metal", (0.45, 0.46, 0.48), 0.82, 0.32))
    glass_mat = ship.add_mat(new_mat("glass", (0.05, 0.08, 0.12), 0.10, 0.15))
    ship.hull(LENGTH, BEAM, HEIGHT, hull_mat, deck_mat, stations=stations, rings=rings)

    containers: list[tuple[str, tuple]] = []
    fittings: list[tuple[str, tuple, str]] = []
    length40 = BAY_PITCH - BAY_GAP
    length20 = (length40 - INNER_GAP) * 0.5
    z_first = -0.98
    profile = [2, 2, 3, 3, 4, 4, 5, 5, 5, 5]
    rng = random.Random(47)
    band_ids = [0, 1, 2, 3, 4]
    band_w = [15, 20, 15, 15, 35]
    max_top = deck_y_at(0.0)
    placed = 0

    for b in range(bays):
        origin = z_first + b * BAY_PITCH
        z_a = origin
        z_b = origin + length40
        half = min_half(z_a, z_b)
        rows = _rows_for(half, cap)
        outer = (rows - 1) * 0.5 * ROW_PITCH + CW * 0.5
        if outer + 0.006 > half - 0.04:
            print(f"SKIP bay {b} half={half:.3f} outer={outer:.3f}")
            continue
        t_along = b / max(1, bays - 1)
        tiers = profile[min(len(profile) - 1, int(round(t_along * (len(profile) - 1))))]
        if level == 2:
            tiers = max(1, tiers - 2)
        y_deck = max(deck_y_at(z_a), deck_y_at(z_b), deck_y_at(0.5 * (z_a + z_b)))
        twenty = b % 4 == 1
        pieces = []
        if twenty:
            pieces = [
                (z_a + length20 * 0.5, length20),
                (z_a + length20 + INNER_GAP + length20 * 0.5, length20),
            ]
        else:
            pieces = [(z_a + length40 * 0.5, length40)]
        hatch_z = z_a + length40 * 0.5
        ship.box((0.0, y_deck + 0.005, hatch_z), (outer * 2 - 0.01, 0.01, length40), metal_mat)
        for r in range(rows):
            x = (r - (rows - 1) / 2.0) * ROW_PITCH
            for pz, plen in pieces:
                for tier in range(tiers):
                    y = y_deck + 0.010 + CH * 0.5 + tier * (CH + 0.004)
                    band = rng.choices(band_ids, weights=band_w, k=1)[0]
                    ship.container((x, y, pz), (CW, CH, plen), box_mat, band, ribs=ribs)
                    box = aabb_of((x, y, pz), (CW + 0.008, CH, plen))
                    containers.append((f"box b{b} r{r} p{pz:.2f} t{tier}", box))
                    max_top = max(max_top, y + CH * 0.5)
                    placed += 1
        post_x = outer + 0.012 + 0.005
        if post_x + 0.005 < half - 0.004 and level < 2:
            top = y_deck + 0.010 + tiers * (CH + 0.004) + 0.016
            beam_y = top + 0.012
            beam_z = hatch_z
            for sign in (1.0, -1.0):
                post_h = beam_y - y_deck - 0.02
                post_c = (sign * post_x, y_deck + 0.02 + post_h * 0.5, beam_z)
                post_s = (0.010, post_h, 0.010)
                ship.box(post_c, post_s, metal_mat)
                fittings.append((f"post b{b} {sign:+.0f}", aabb_of(post_c, post_s), "post"))
            beam_c = (0.0, beam_y, beam_z)
            beam_s = (post_x * 2, 0.012, 0.012)
            ship.box(beam_c, beam_s, paint_mat, (0.37, 0.5))
            fittings.append((f"lash b{b}", aabb_of(beam_c, beam_s), "beam"))

    # Rails follow the deck edge. Posts every 0.15 on LOD0.
    z = -1.35
    z_stop = 1.55
    house_z0, house_z1 = 0.90, 1.40
    while z < z_stop - 0.02:
        z2 = min(z_stop, z + 0.18)
        zm = 0.5 * (z + z2)
        if house_z0 - 0.04 < zm < house_z1 + 0.02:
            z = z2
            continue
        half = half_beam_at(zm)
        if half < 0.08:
            z = z2
            continue
        x = half - 0.02
        y = deck_y_at(zm) + 0.06
        seg_len = z2 - z
        for sign in (1.0, -1.0):
            c = (sign * x, y, zm)
            s = (0.010, 0.010, seg_len)
            ship.box(c, s, metal_mat)
            fittings.append((f"rail {sign:+.0f} z{zm:.2f}", aabb_of(c, s), "rail"))
        if rail_post > 0 and level == 0:
            posts = max(1, int(seg_len / rail_post))
            for k in range(posts):
                zp = z + (k + 0.5) * seg_len / posts
                hp = half_beam_at(zp)
                if hp < 0.08:
                    continue
                xp = hp - 0.02
                yp = deck_y_at(zp)
                for sign in (1.0, -1.0):
                    c = (sign * xp, yp + 0.03, zp)
                    s = (0.010, 0.06, 0.010)
                    ship.box(c, s, metal_mat)
                    fittings.append((f"stanchion {sign:+.0f} z{zp:.2f}", aabb_of(c, s), "rail"))
        z = z2

    _check(containers, fittings)

    # Bridge. Window sill is 0.05 above the real top of the tallest box.
    sill = max_top + 0.05
    wh_h = 0.18
    wh_bottom = sill - 0.045
    y_house = deck_y_at(1.12)
    house_h = max(0.28, wh_bottom - y_house)
    house_c = (0.0, y_house + house_h * 0.5, 1.16)
    house_s = (0.42, house_h, 0.44)
    ship.box(house_c, house_s, paint_mat, (0.12, 0.5))
    wh_c = (0.0, wh_bottom + wh_h * 0.5, 1.10)
    wh_s = (0.36, wh_h, 0.32)
    ship.box(wh_c, wh_s, paint_mat, (0.12, 0.5))
    front_z = wh_c[2] - wh_s[2] * 0.5
    win_y = sill + 0.028
    if windows:
        n_front = 9 if level == 0 else 6
        span = wh_s[0] - 0.04
        for i in range(n_front):
            x = -span * 0.5 + (i + 0.5) * span / n_front
            ship.box((x, win_y, front_z - 0.002 - 0.004), (0.026, 0.055, 0.008), glass_mat)
        side_x = wh_s[0] * 0.5
        for sign in (1.0, -1.0):
            for i in range(3):
                zz = wh_c[2] - 0.09 + i * 0.09
                ship.box((sign * (side_x + 0.002 + 0.004), win_y, zz), (0.008, 0.055, 0.028), glass_mat)
        # Accommodation, two or three rows, front and sides.
        rows_w = 3 if level == 0 else 2
        for row in range(rows_w):
            yy = y_house + 0.08 + row * (house_h - 0.12) / max(1, rows_w - 1)
            for i in range(5 if level == 0 else 3):
                x = -0.16 + i * (0.32 / (4 if level == 0 else 2))
                ship.box((x, yy, house_c[2] - house_s[2] * 0.5 - 0.006), (0.028, 0.032, 0.008), glass_mat)
            for sign in (1.0, -1.0):
                for i in range(3 if level == 0 else 2):
                    zz = house_c[2] - 0.12 + i * 0.12
                    ship.box((sign * (house_s[0] * 0.5 + 0.006), yy, zz), (0.008, 0.032, 0.03), glass_mat)
    # Wings out to the hull at window height.
    wing_y = win_y
    reach = half_beam_at(wh_c[2]) - 0.015
    for sign in (1.0, -1.0):
        inner = wh_s[0] * 0.5
        width = max(0.04, reach - inner)
        ship.box((sign * (inner + width * 0.5), wing_y, wh_c[2] + 0.02), (width, 0.012, 0.10), paint_mat, (0.12, 0.5))
    # Funnel, darker, banded, leaned aft.
    funnel_base = (0.0, y_house + house_h * 0.55, 1.46)
    funnel_top = (0.0, y_house + house_h * 0.55 + 0.36, 1.56)
    ship.cylinder(funnel_base, funnel_top, 0.055, metal_mat, sides=8 if level == 0 else 5)
    ship.cylinder(
        (funnel_base[0], funnel_base[1] + 0.08, funnel_base[2] + 0.02),
        (funnel_top[0], funnel_base[1] + 0.13, funnel_base[2] + 0.035),
        0.050,
        paint_mat,
        sides=8 if level == 0 else 5,
    )
    # Forecastle and hawse pipes with a short chain.
    bow_y = deck_y_at(-1.55)
    ship.box((0.0, bow_y + 0.03, -1.48), (0.22, 0.06, 0.22), paint_mat, (0.12, 0.5))
    if details:
        for sign in (1.0, -1.0):
            mouth = (sign * 0.10, bow_y + 0.02, -1.58)
            hawse = (sign * (half_beam_at(-1.58) - 0.02), bow_y - 0.06, -1.66)
            ship.cylinder(mouth, hawse, 0.012, metal_mat, sides=6)
            ship.box(hawse, (0.03, 0.05, 0.012), metal_mat)
    elif level < 2:
        ship.box((-0.12, bow_y + 0.01, -1.62), (0.03, 0.06, 0.02), metal_mat)
        ship.box((0.12, bow_y + 0.01, -1.62), (0.03, 0.06, 0.02), metal_mat)
    # Prop and rudder. Stern is +Z.
    ship.box((0.0, 0.08, 1.62), (0.04, 0.04, 0.10), metal_mat)
    if level < 2:
        for k in range(4):
            ang = k * math.pi / 2
            ship.box((math.cos(ang) * 0.06, 0.08 + math.sin(ang) * 0.04, 1.66), (0.02, 0.06, 0.012), metal_mat)
    ship.box((0.0, 0.10, 1.52), (0.015, 0.16, 0.08), metal_mat)

    print(
        f"STACK top={max_top:.3f} sill={sill:.3f} boxes={placed} "
        f"length40={length40:.3f} length20={length20:.3f} gap={BAY_GAP:.3f}"
    )
    ship.finish(out)
    print(f"wrote {out} level {level}")
    if level == 0:
        render_shots(
            ROOT / "docs" / "ships" / "v2" / "after",
            focus=(0.0, win_y, wh_c[2]),
        )


def render_shots(folder: Path, focus=(0.0, 0.9, 1.1)) -> None:
    from mathutils import Vector

    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 16
    scene.cycles.device = "CPU"
    scene.render.resolution_x = 960
    scene.render.resolution_y = 540
    scene.render.film_transparent = False
    world = scene.world or bpy.data.worlds.new("World")
    scene.world = world
    world.color = (0.04, 0.10, 0.14)
    sun = bpy.data.lights.new("Sun", "SUN")
    sun.energy = 4.0
    sun_obj = bpy.data.objects.new("Sun", sun)
    sun_obj.rotation_euler = (0.85, 0.15, 0.4)
    bpy.context.collection.objects.link(sun_obj)
    fill = bpy.data.lights.new("Fill", "AREA")
    fill.energy = 500
    fill.size = 4
    fill_obj = bpy.data.objects.new("Fill", fill)
    fill_obj.location = B(-2.2, 2.4, 2.0)
    bpy.context.collection.objects.link(fill_obj)
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.lens = 48
    cam = bpy.data.objects.new("Cam", cam_data)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam
    folder.mkdir(parents=True, exist_ok=True)
    fx, fy, fz = focus
    shots = {
        "cargo_hero.png": (B(2.6, 1.7, -2.4), B(0.0, 0.55, 0.1), False),
        "cargo_profile.png": (B(4.4, 1.15, 0.1), B(0.0, 0.55, 0.1), False),
        "cargo_bridge.png": (B(1.15, fy + 0.28, fz - 0.95), B(0.05, fy, fz), False),
        "cargo_top.png": (B(0.0, 4.6, 0.05), B(0.0, 0.4, 0.05), True),
    }
    for name, (eye, target, ortho) in shots.items():
        cam_data.type = "ORTHO" if ortho else "PERSP"
        if ortho:
            cam_data.ortho_scale = 4.6
        else:
            cam_data.lens = 42 if "bridge" in name else 48
        cam.location = eye
        cam.rotation_euler = (Vector(target) - Vector(eye)).to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = str(folder / name)
        bpy.ops.render.render(write_still=True)
        print(f"rendered {folder / name}")


if __name__ == "__main__":
    dest = ROOT / "assets" / "models" / "ships" / "cargo.glb"
    level = 0
    if "--" in sys.argv:
        extra = sys.argv[sys.argv.index("--") + 1 :]
        if extra:
            dest = Path(extra[0])
            if not dest.is_absolute():
                dest = ROOT / dest
        if len(extra) > 1:
            level = int(extra[1])
    build(dest, level)
