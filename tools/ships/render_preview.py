"""Raster previews of the original ships. Used for the hero cards, not at runtime."""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))

from ships.build_ships import BUILDERS  # noqa: E402
from ships.meshlib import MATERIALS  # noqa: E402


def _camera(yaw: float, pitch: float, dist: float, target: np.ndarray):
    eye = target + np.array([
        dist * np.cos(pitch) * np.cos(yaw),
        dist * np.sin(pitch) + 0.15,
        dist * np.cos(pitch) * np.sin(yaw),
    ])
    forward = target - eye
    forward = forward / np.linalg.norm(forward)
    right = np.cross(forward, np.array([0.0, 1.0, 0.0]))
    right = right / np.linalg.norm(right)
    up = np.cross(right, forward)
    return eye, right, up, forward


def render(parts, path: Path, title: str, yaw: float = -0.55, pitch: float = 0.38) -> None:
    pos, cols, idx = [], [], []
    for part in parts:
        if not part.indices:
            continue
        base = len(pos)
        rgb = MATERIALS[part.material][0]
        pos.extend(part.positions)
        cols.append(np.tile(np.array(rgb[:3], dtype=np.float32), (len(part.positions), 1)))
        idx.extend(i + base for i in part.indices)
    positions = np.asarray(pos, dtype=np.float64)
    colors = np.vstack(cols)
    indices = np.asarray(idx, dtype=np.int64).reshape(-1, 3)
    center = (positions.min(0) + positions.max(0)) * 0.5
    radius = float(np.linalg.norm(positions.max(0) - positions.min(0))) * 0.55
    eye, right, up, forward = _camera(yaw, pitch, radius * 2.4, center)
    light = np.array([-0.35, 0.85, -0.25])
    light = light / np.linalg.norm(light)
    view = positions - eye
    cam = np.stack((view @ right, view @ up, view @ forward), axis=1)
    W, H = 1100, 640
    # Fit the projected ship to the frame.
    span = max(float(cam[:, 0].max() - cam[:, 0].min()), float(cam[:, 1].max() - cam[:, 1].min()), 0.001)
    scale = 0.78 * min(W, H) / span
    sx = W * 0.5 + (cam[:, 0] - cam[:, 0].mean()) * scale
    sy = H * 0.52 - (cam[:, 1] - cam[:, 1].mean()) * scale
    sz = cam[:, 2]
    zbuf = np.full(W * H, 1e9, dtype=np.float32)
    image = np.full((H, W, 3), (214 / 255, 224 / 255, 230 / 255), dtype=np.float32)
    light_dir = light
    for a, b, c in indices:
        xa, ya, za = sx[a], sy[a], sz[a]
        xb, yb, zb = sx[b], sy[b], sz[b]
        xc, yc, zc = sx[c], sy[c], sz[c]
        minx = int(max(0, min(xa, xb, xc)))
        maxx = int(min(W - 1, max(xa, xb, xc) + 1))
        miny = int(max(0, min(ya, yb, yc)))
        maxy = int(min(H - 1, max(ya, yb, yc) + 1))
        if minx >= maxx or miny >= maxy:
            continue
        area = (yb - yc) * (xa - xc) + (xc - xb) * (ya - yc)
        if abs(area) < 0.5:
            continue
        n = np.cross(positions[b] - positions[a], positions[c] - positions[a])
        ln = np.linalg.norm(n)
        if ln < 1e-8:
            continue
        n /= ln
        if np.dot(n, eye - positions[a]) <= 0:
            continue
        shade = 0.28 + 0.72 * max(0.0, float(np.dot(n, light_dir)))
        col = colors[a] * shade
        ys, xs = np.mgrid[miny:maxy + 1, minx:maxx + 1]
        w0 = ((yb - yc) * (xs - xc) + (xc - xb) * (ys - yc)) / area
        w1 = ((yc - ya) * (xs - xc) + (xa - xc) * (ys - yc)) / area
        w2 = 1.0 - w0 - w1
        mask = (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
        if not mask.any():
            continue
        z = w0 * za + w1 * zb + w2 * zc
        flat = (ys * W + xs).ravel()
        m = mask.ravel()
        zf = z.ravel()[m]
        ff = flat[m]
        closer = zf < zbuf[ff]
        if not closer.any():
            continue
        ff = ff[closer]
        zbuf[ff] = zf[closer]
        image.reshape(-1, 3)[ff] = col
    out = Image.fromarray(np.clip(image * 255, 0, 255).astype(np.uint8), "RGB")
    draw = ImageDraw.Draw(out)
    draw.rectangle((0, 0, W, 46), fill=(20, 24, 18))
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 22)
    except OSError:
        font = ImageFont.load_default()
    draw.text((16, 12), title, fill=(243, 234, 215), font=font)
    path.parent.mkdir(parents=True, exist_ok=True)
    out.save(path)
    print(path)


def main() -> None:
    titles = {
        "cargo": "Kontajnerová loď",
        "bulk": "Bulk carrier",
        "merchant": "Všeobecná loď",
        "submarine": "Ponorka",
    }
    out = ROOT / "docs" / "ships" / "after"
    for name, (fn, _rgb) in BUILDERS.items():
        render(fn(0), out / f"{name}_hero.png", titles[name], yaw=-0.7, pitch=0.32)
        render(fn(0), out / f"{name}_profile.png", titles[name] + " — profil", yaw=-1.25, pitch=0.12)


if __name__ == "__main__":
    main()
