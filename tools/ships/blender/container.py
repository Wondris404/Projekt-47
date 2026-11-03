"""Container ship, round 2. Blender 4.2, headless.

Game axis after glTF export (Y-up): bow -Z, keel Y=0, beam X.
Blender is Z-up, so this file builds in game axis and converts with B().
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

import bpy
import bmesh

ROOT = Path(__file__).resolve().parents[3]


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
            # +X
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
                proud = 0.006 * sign * (1 if i % 2 == 0 else -0.2)
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
            # Door bars on the aft end.
            self.quad(pts, mat, uv)
            if z_sign > 0:
                self.box((cx, cy, z + 0.004), (w * 0.08, h * 0.86, 0.006), mat, (u, 0.5))
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


def build(out: Path, level: int = 0) -> None:
    reset()
    if level <= 0:
        stations, rings, bays, ribs = 110, 34, 10, 6
    elif level == 1:
        stations, rings, bays, ribs = 32, 12, 8, 1
    else:
        stations, rings, bays, ribs = 12, 5, 4, 1
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
    deck_y = ship.hull(3.5, 0.64, 0.44, hull_mat, deck_mat, stations=stations, rings=rings)
    # Forecasttle and anchors. Bow is -Z.
    ship.box((-0.0, deck_y + 0.03, -1.50), (0.30, 0.08, 0.26), paint_mat, (0.12, 0.5))
    ship.box((-0.12, deck_y + 0.02, -1.64), (0.04, 0.10, 0.03), metal_mat)
    ship.box((0.12, deck_y + 0.02, -1.64), (0.04, 0.10, 0.03), metal_mat)
    bays_n = bays
    z_bow = -1.30
    z_bridge = 0.78
    pitch = (z_bridge - z_bow) / bays_n
    rows = 5 if level < 2 else 2
    for b in range(bays_n):
        z = z_bow + (b + 0.5) * pitch
        t = b / (bays - 1)
        tiers = 2 + int(round(3 * t))
        long = b % 3 != 1
        length = pitch * (0.88 if long else 0.44)
        for r in range(rows):
            x = (r - (rows - 1) / 2.0) * 0.108
            local_tiers = tiers if r not in (0, rows - 1) else max(2, tiers - 1)
            for tier in range(local_tiers):
                y = deck_y + 0.055 + tier * 0.100
                band = (b * 3 + r + tier) % 5
                ship.container((x, y, z), (0.100, 0.096, length), box_mat, band, ribs=ribs)
        if b < bays_n - 1:
            zb = z_bow + (b + 1) * pitch
            top = deck_y + 0.055 + max(1, tiers - 1) * 0.100 + 0.02
            ship.box((0.0, top, zb), (0.52, 0.016, 0.016), paint_mat, (0.37, 0.5))
            ship.box((-0.26, (deck_y + top) * 0.5, zb), (0.016, top - deck_y, 0.016), metal_mat)
            ship.box((0.26, (deck_y + top) * 0.5, zb), (0.016, top - deck_y, 0.016), metal_mat)
    # Bridge aft, white.
    ship.box((0.0, deck_y + 0.28, 1.02), (0.48, 0.56, 0.40), paint_mat, (0.12, 0.5))
    ship.box((0.0, deck_y + 0.66, 1.00), (0.34, 0.18, 0.26), paint_mat, (0.12, 0.5))
    for i in range(5):
        ship.box((-0.16 + i * 0.08, deck_y + 0.42, 0.80), (0.05, 0.05, 0.012), metal_mat)
    ship.box((0.0, deck_y + 0.34, 1.22), (0.14, 0.22, 0.12), paint_mat, (0.12, 0.5))
    ship.box((0.0, deck_y + 0.34, 1.22), (0.10, 0.06, 0.13), paint_mat, (0.37, 0.5))
    ship.box((0.22, deck_y + 0.10, 1.28), (0.16, 0.05, 0.05), paint_mat, (0.37, 0.5))
    # Rails. LOD2 keeps the silhouette without the posts.
    if level < 2:
        for x in (-0.30, 0.30):
            ship.box((x, deck_y + 0.08, -0.2), (0.012, 0.012, 2.2), metal_mat)
            if level == 0:
                for k in range(8):
                    ship.box((x, deck_y + 0.04, -1.2 + k * 0.30), (0.012, 0.08, 0.012), metal_mat)
    # Nav lights.
    ship.box((-0.24, deck_y + 0.22, 0.78), (0.03, 0.03, 0.03), paint_mat, (0.62, 0.5))
    ship.box((0.24, deck_y + 0.22, 0.78), (0.03, 0.03, 0.03), paint_mat, (0.87, 0.5))
    # Prop and rudder. Stern is +Z.
    ship.box((0.0, 0.08, 1.62), (0.04, 0.04, 0.10), metal_mat)
    for k in range(4):
        ang = k * math.pi / 2
        ship.box((math.cos(ang) * 0.06, 0.08 + math.sin(ang) * 0.04, 1.66), (0.02, 0.06, 0.012), metal_mat)
    ship.box((0.0, 0.10, 1.52), (0.015, 0.16, 0.08), metal_mat)
    ship.finish(out)
    print(f"wrote {out} level {level}")
    if level == 0:
        render_shots(ROOT / "docs" / "ships" / "v2" / "after")


def render_shots(folder: Path) -> None:
    from mathutils import Vector

    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 24
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
    fill.energy = 400
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
    shots = {
        "cargo_hero.png": (B(2.6, 1.7, -2.4), B(0.0, 0.5, 0.0)),
        "cargo_profile.png": (B(4.2, 1.05, 0.0), B(0.0, 0.45, 0.0)),
    }
    for name, (eye, target) in shots.items():
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
        if len(extra) > 1:
            level = int(extra[1])
    build(dest, level)
