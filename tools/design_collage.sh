#!/usr/bin/env bash
# P47 DESIGNS: kolaz vsetkych existujucich screenshotov dizajnov.
# Pouzitie: tools/design_collage.sh [shots_dir]   (default /workspace/coding-p47/designs/shots)
# Vystup:   <shots_dir>/kolaz.png – riadok na dizajn (current prvy, potom dNN), 3 stlpce menu/mapa/burza.
set -euo pipefail
DIR="${1:-${P47_SHOTS_DIR:-/workspace/coding-p47/designs/shots}}"
python3 - "$DIR" <<'PY'
import os, sys, json, glob
from PIL import Image, ImageDraw, ImageFont
d = sys.argv[1]
names = ["01_menu.png", "02_mapa.png", "03_burza.png"]
rows = sorted([x for x in os.listdir(d) if os.path.isdir(os.path.join(d, x)) and any(os.path.exists(os.path.join(d, x, n)) for n in names)],
              key=lambda x: (x != "current", x))
if not rows:
    sys.exit("CHYBA: ziadne screenshoty v " + d)
W, H, PAD, LBL = 400, 225, 8, 180
try:
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 22)
    small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 14)
except Exception:
    font = small = ImageFont.load_default()
wt = os.environ.get("P47_WT", "/workspace/coding-p47/wt-designs")
out = Image.new("RGB", (LBL + 3 * (W + PAD) + PAD, PAD + len(rows) * (H + PAD)), (18, 18, 22))
dr = ImageDraw.Draw(out)
for i, r in enumerate(rows):
    y = PAD + i * (H + PAD)
    title = r
    try:
        title = json.load(open(os.path.join(wt, "themes", r, "design.json"), encoding="utf-8")).get("name", r)
    except Exception:
        title = "Súčasný" if r == "current" else r
    dr.text((PAD, y + 8), r, fill=(255, 200, 80), font=font)
    dr.multiline_text((PAD, y + 40), title[:60].replace(" – ", "\n"), fill=(220, 220, 230), font=small)
    for j, n in enumerate(names):
        p = os.path.join(d, r, n)
        x = LBL + j * (W + PAD)
        if os.path.exists(p):
            out.paste(Image.open(p).convert("RGB").resize((W, H), Image.LANCZOS), (x, y))
        else:
            dr.rectangle([x, y, x + W, y + H], outline=(90, 90, 90))
            dr.text((x + 10, y + 10), "chýba " + n, fill=(160, 160, 160), font=small)
dst = os.path.join(d, "kolaz.png")
out.save(dst)
print("P47_COLLAGE_OK %s rows=%d" % (dst, len(rows)))
PY
