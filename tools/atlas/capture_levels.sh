#!/usr/bin/env bash
# Requires Godot 4.7.2, Xvfb and Mesa llvmpipe. Does not touch real user saves.
set -euo pipefail
cd "$(dirname "$0")/../.."
p47_godot="${P47_GODOT_BIN:-godot}"
p47_xvfb="${P47_XVFB_BIN:-Xvfb}"
p47_tmp="$(mktemp -d /tmp/p47-atlas-capture.XXXXXX)"
trap 'if [[ -n "${p47_pid:-}" ]]; then kill "$p47_pid" 2>/dev/null || true; fi' EXIT
"$p47_xvfb" -displayfd 3 -screen 0 1280x800x24 -nolisten tcp -ac 3>"$p47_tmp/display" >"$p47_tmp/xvfb.log" 2>&1 &
p47_pid=$!
for ((i=0;i<50;i++)); do
    [[ -s "$p47_tmp/display" ]] && break
    sleep 0.1
done
[[ -s "$p47_tmp/display" ]] || { cat "$p47_tmp/xvfb.log"; exit 1; }
export DISPLAY=":$(cat "$p47_tmp/display")"
export LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe
export XDG_DATA_HOME="$p47_tmp/data" XDG_CONFIG_HOME="$p47_tmp/config" XDG_CACHE_HOME="$p47_tmp/cache"
"$p47_godot" --headless --path . --editor --import >"$p47_tmp/import.log" 2>&1
"$p47_godot" --path . --rendering-method gl_compatibility --audio-driver Dummy --resolution 1280x800 -- atlas_levels_capture
