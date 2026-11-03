"""Build the four original hero ships and their LOD files."""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))

from ships.meshlib import (  # noqa: E402
    add_anchor,
    add_box,
    add_bridge,
    add_container,
    add_crane,
    add_cylinder,
    add_funnel,
    add_hatch,
    add_lifeboat,
    add_prop_and_rudder,
    add_railing,
    add_sail,
    add_windows,
    count_tris,
    hull_albedo,
    lathe_sub,
    merchant_hull,
    write_glb,
)

OUT = ROOT / "assets" / "models" / "ships"
LOD = OUT / "lod"
TEX = ROOT / "docs" / "ships" / "textures"


def _lod_kwargs(lod: int) -> dict:
    if lod <= 0:
        return {"stations": 88, "rings": 32, "ribs": 8, "detail": True}
    if lod == 1:
        return {"stations": 36, "rings": 16, "ribs": 0, "detail": False}
    return {"stations": 18, "rings": 10, "ribs": 0, "detail": False}


def cargo(lod: int = 0) -> list:
    k = _lod_kwargs(lod)
    parts = merchant_hull(3.5, 0.62, 0.42, "hull_blue", k["stations"], k["rings"], bulb=True)
    # Forecastle and anchors. Bow is -Z.
    add_box(parts, (0.0, 0.40, -1.48), (0.28, 0.08, 0.28), "white")
    if k["detail"]:
        add_anchor(parts, (-0.10, 0.40, -1.62))
        add_anchor(parts, (0.10, 0.40, -1.62))
        add_railing(parts, -1.55, -1.25, 0.16, 0.46, 6)
        add_railing(parts, -1.55, -1.25, -0.16, 0.46, 6)
    # Container stacks. 40-foot bays, 5 across, up to 4 high. Bridge stays clear at the stern.
    colors = ["c_red", "c_blue", "c_green", "c_orange", "c_grey"]
    bays = 5 if lod < 2 else 3
    rows = 5 if lod < 2 else 1
    tiers = 4 if lod == 0 else (2 if lod == 1 else 1)
    bay_l = 0.30
    z0 = -1.05
    for b in range(bays):
        z = z0 + b * (bay_l + 0.03)
        for r in range(rows):
            x = (r - (rows - 1) / 2) * 0.105
            stack = tiers if r in (0, rows - 1) else tiers
            if lod == 0 and b % 2 == 0 and r == 2:
                stack = tiers
            for t in range(stack):
                mat = colors[(b * 3 + r + t) % len(colors)]
                add_container(parts, (x, 0.58 + t * 0.105, z), (0.098, 0.098, bay_l * 0.92), mat, ribs=k["ribs"] or 2)
        if k["detail"] and b < bays - 1:
            # Lashing bridge between bays.
            add_box(parts, (0.0, 0.78, z + bay_l * 0.5 + 0.015), (0.50, 0.02, 0.02), "yellow")
    # Accommodation block aft.
    add_bridge(parts, (0.0, 0.58, 1.05), (0.42, 0.28, 0.46))
    add_funnel(parts, (0.0, 0.78, 1.28), (0.12, 0.16, 0.10), "hull_blue")
    if k["detail"]:
        add_lifeboat(parts, (0.0, 0.55, 1.42), 0.20)
        add_railing(parts, 0.85, 1.45, 0.24, 0.48, 8)
        add_railing(parts, 0.85, 1.45, -0.24, 0.48, 8)
    add_prop_and_rudder(parts, 1.62, 0.08)
    return parts


def bulk(lod: int = 0) -> list:
    k = _lod_kwargs(lod)
    if lod == 0:
        k["stations"], k["rings"] = 108, 36
    parts = merchant_hull(3.6, 0.70, 0.46, "hull_brown", k["stations"], k["rings"], bulb=True)
    add_box(parts, (0.0, 0.44, -1.52), (0.34, 0.08, 0.26), "white")
    if k["detail"]:
        add_anchor(parts, (-0.12, 0.46, -1.66))
        add_anchor(parts, (0.12, 0.46, -1.66))
        add_railing(parts, -1.6, 0.7, 0.30, 0.50, 14)
        add_railing(parts, -1.6, 0.7, -0.30, 0.50, 14)
    hatches = 7 if lod == 0 else (5 if lod == 1 else 3)
    z0 = -1.15
    span = 2.15
    for i in range(hatches):
        z = z0 + span * (i + 0.5) / hatches
        add_hatch(parts, (0.0, 0.50, z), (0.46, 0.05, span / hatches * 0.72))
        if k["detail"] and i % 2 == 1:
            add_crane(parts, (0.28, 0.52, z - span / hatches * 0.45), reach=0.36)
    add_bridge(parts, (0.0, 0.62, 1.18), (0.48, 0.32, 0.40))
    add_funnel(parts, (0.08, 0.86, 1.36), (0.11, 0.18, 0.10), "black")
    if k["detail"]:
        add_lifeboat(parts, (-0.16, 0.62, 1.40), 0.18)
    add_prop_and_rudder(parts, 1.68, 0.09)
    return parts


def general(lod: int = 0) -> list:
    k = _lod_kwargs(lod)
    if lod == 0:
        k["stations"], k["rings"] = 108, 36
    parts = merchant_hull(2.7, 0.52, 0.38, "hull_green", k["stations"], k["rings"], bulb=True)
    add_bridge(parts, (0.0, 0.52, 0.72), (0.36, 0.26, 0.36))
    add_funnel(parts, (0.0, 0.74, 0.92), (0.09, 0.14, 0.08), "c_orange")
    # Two heavy derricks.
    if lod < 2:
        add_crane(parts, (-0.16, 0.46, 0.15), reach=0.40)
        add_crane(parts, (0.16, 0.46, -0.25), reach=0.38)
    # Open hold with cargo.
    add_box(parts, (0.0, 0.40, -0.35), (0.36, 0.06, 0.55), "dark_metal")
    if lod < 2:
        for i, z in enumerate((-0.52, -0.34, -0.16)):
            add_box(parts, (-0.08, 0.48, z), (0.12, 0.08, 0.12), "crate")
            add_box(parts, (0.08, 0.48, z), (0.10, 0.10, 0.14), "wood")
        add_cylinder(parts, (0.0, 0.50, 0.05), (0.0, 0.50, 0.22), 0.06, "coil", segs=12)
        add_container(parts, (0.0, 0.52, -0.85), (0.10, 0.10, 0.22), "c_grey", ribs=k["ribs"] or 2)
    if k["detail"]:
        add_anchor(parts, (0.0, 0.40, -1.22))
        add_lifeboat(parts, (0.18, 0.50, 0.85), 0.16)
        add_railing(parts, -1.15, 0.45, 0.22, 0.42, 10)
        add_railing(parts, -1.15, 0.45, -0.22, 0.42, 10)
        add_windows(parts, (-0.12, 0.48, 0.72 - 0.19), 3, 2, (0.03, 0.025), axis="z")
    add_prop_and_rudder(parts, 1.25, 0.07)
    return parts


def submarine(lod: int = 0) -> list:
    along = 128 if lod == 0 else (56 if lod == 1 else 28)
    around = 64 if lod == 0 else (28 if lod == 1 else 16)
    parts = lathe_sub(3.3, 0.26, along, around)
    add_sail(parts, (0.0, 0.58, -0.25), (0.18, 0.20, 0.46))
    if lod < 2:
        # Masts and periscopes.
        for z, r in ((-0.38, 0.008), (-0.28, 0.006), (-0.16, 0.007)):
            add_cylinder(parts, (0.0, 0.68, z), (0.0, 0.86, z), r, "dark_metal", segs=8)
        add_box(parts, (0.0, 0.84, -0.16), (0.03, 0.02, 0.05), "black")
        # Fairwater planes.
        add_box(parts, (-0.16, 0.56, -0.22), (0.16, 0.012, 0.08), "sub_panel")
        add_box(parts, (0.16, 0.56, -0.22), (0.16, 0.012, 0.08), "sub_panel")
        # Deck hatches.
        for z in (-0.85, 0.35):
            add_cylinder(parts, (0.0, 0.50, z), (0.0, 0.53, z), 0.025, "dark_metal", segs=10)
    # X-stern.
    tail = (0.0, 0.26, 1.45)
    for sx, sy in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
        add_box(parts, (sx * 0.10, 0.26 + sy * 0.10, 1.48), (0.14, 0.012, 0.10), "sub_panel")
    # Pumpjet ring.
    add_cylinder(parts, (0.0, 0.26, 1.62), (0.0, 0.26, 1.72), 0.09, "sub_panel", segs=16 if lod == 0 else 8, caps=False)
    add_cylinder(parts, (0.0, 0.26, 1.58), (0.0, 0.26, 1.70), 0.035, "bronze", segs=12, caps=False)
    if lod == 0:
        # Bow planes.
        add_box(parts, (-0.18, 0.30, -1.15), (0.14, 0.01, 0.07), "sub_panel")
        add_box(parts, (0.18, 0.30, -1.15), (0.14, 0.01, 0.07), "sub_panel")
    return parts


BUILDERS = {
    "cargo": (cargo, (24, 78, 112)),
    "bulk": (bulk, (92, 48, 32)),
    "merchant": (general, (20, 92, 48)),
    "submarine": (submarine, (28, 30, 32)),
}


def main() -> None:
    TEX.mkdir(parents=True, exist_ok=True)
    LOD.mkdir(parents=True, exist_ok=True)
    colors = {
        "cargo": hull_albedo((28, 78, 120), TEX / "hull_blue.png"),
        "bulk": hull_albedo((120, 52, 32), TEX / "hull_brown.png"),
        "merchant": hull_albedo((22, 90, 58), TEX / "hull_green.png"),
        "submarine": None,
    }
    hull_mats = {
        "cargo": {"hull_blue"},
        "bulk": {"hull_brown"},
        "merchant": {"hull_green"},
        "submarine": set(),
    }
    for name, (fn, _rgb) in BUILDERS.items():
        for lod in (0, 1, 2):
            parts = fn(lod)
            tris = count_tris(parts)
            dest = OUT / f"{name}.glb" if lod == 0 else LOD / f"{name}_lod{lod}.glb"
            write_glb(dest, parts, colors[name] if lod == 0 else None, hull_mats[name])
            print(f"{name} lod{lod}: {tris} tris -> {dest.name} ({dest.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
