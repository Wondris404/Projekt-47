#!/usr/bin/env bash
# P47 DESIGNS: 3 screenshoty dizajnu pod Xvfb s izolovanym XDG_DATA_HOME.
# Pouzitie: tools/design_shots.sh <dNN|current> [worktree]
# Vystup:   /workspace/coding-p47/designs/shots/<dNN>/{01_menu,02_mapa,03_burza}.png
set -euo pipefail
ID="${1:?pouzitie: tools/design_shots.sh <dNN|current> [worktree]}"
WT="${2:-$(cd "$(dirname "$0")/.." && pwd)}"
ROOT="${P47_ROOT:-/workspace/coding-p47}"
GODOT="${GODOT:-$ROOT/tools/Godot_v4.7.2-stable_linux.x86_64}"
OUT="${P47_SHOTS_DIR:-$ROOT/designs/shots}/$ID"
export XDG_DATA_HOME="${XDG_DATA_HOME_SHOTS:-$ROOT/.userdata/shots-$ID}"
mkdir -p "$OUT" "$XDG_DATA_HOME"
if [ "$ID" != "current" ] && [ ! -f "$WT/themes/$ID/design.json" ]; then
  echo "CHYBA: $WT/themes/$ID/design.json neexistuje" >&2; exit 2
fi
rm -f "$OUT/01_menu.png" "$OUT/02_mapa.png" "$OUT/03_burza.png"
# import (novy .png/.ttf v themes/dNN potrebuje .import)
"$GODOT" --headless --path "$WT" --import >/dev/null 2>&1 || true
LOG="$OUT/shots.log"
timeout 300 xvfb-run -a -s '-screen 0 1280x720x24' env LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe \
  "$GODOT" --path "$WT" --rendering-method gl_compatibility --rendering-driver opengl3 --audio-driver Dummy \
  --resolution 1280x720 -- design_shots "design=$ID" "out=$OUT" >"$LOG" 2>&1 || true
ACTIVE=$(grep -o 'P47_DESIGN_ACTIVE [^ ]*' "$LOG" | awk '{print $2}' | tail -1)
if ! grep -q P47_DESIGN_SHOTS_OK "$LOG"; then
  echo "CHYBA: screenshoty zlyhali, log: $LOG" >&2; tail -20 "$LOG" >&2; exit 1
fi
if [ "$ACTIVE" != "$ID" ]; then
  echo "CHYBA: aktivny dizajn je '$ACTIVE', nie '$ID' (neplatny dizajn -> current), log: $LOG" >&2; exit 3
fi
ls -1 "$OUT"/0*.png
echo "P47_DESIGN_SHOTS_OK $ID -> $OUT"
