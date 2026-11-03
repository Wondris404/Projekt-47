#!/usr/bin/env bash
# Skontroluje jeden alebo viac .glb súborov oficiálnym gltf_validator.
# Nič nezapisuje: validuje kópiu v dočasnom priečinku a report ide na stdout
# (gltf_validator --stdout). Vedľa vstupu nevznikne <súbor>.report.json.
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Použitie: $0 <model.glb> [ďalší.glb ...]" >&2
  echo "Bez nainštalovaného gltf_validator / gltf-validator končí kódom 2. To nie je úspech." >&2
  exit 1
fi

find_validator() {
  if [[ -n "${GLTF_VALIDATOR:-}" && -x "${GLTF_VALIDATOR}" ]]; then
    printf '%s\n' "${GLTF_VALIDATOR}"
    return 0
  fi
  local c
  for c in gltf_validator gltf-validator; do
    if command -v "$c" >/dev/null 2>&1; then
      command -v "$c"
      return 0
    fi
  done
  local p
  for p in \
    /opt/gltf-validator/gltf_validator \
    /usr/local/bin/gltf_validator \
    /usr/local/bin/gltf-validator
  do
    if [[ -x "$p" ]]; then
      printf '%s\n' "$p"
      return 0
    fi
  done
  return 1
}

if ! validator=$(find_validator); then
  echo "gltf-validator nie je k dispozícii (hľadal som gltf_validator aj gltf-validator v PATH, GLTF_VALIDATOR a /opt/gltf-validator/gltf_validator)." >&2
  echo "Oficiálny linux balík: https://github.com/KhronosGroup/glTF-Validator/releases (gltf_validator-*-linux64.tar.xz)." >&2
  echo "Validácia sa nespustila. Koniec s kódom 2 nie je úspešný výsledok a nesmie sa hlásiť ako pass." >&2
  exit 2
fi

rc=0
for input in "$@"; do
  if [[ ! -f "$input" ]]; then
    echo "Súbor neexistuje: $input" >&2
    rc=1
    continue
  fi
  tmp=$(mktemp -d)
  cp -p -- "$input" "$tmp/asset.glb"
  stamp_before=$(stat -c '%s %Y %Z' -- "$input")
  set +e
  "$validator" --stdout "$tmp/asset.glb"
  status=$?
  set -e
  stamp_after=$(stat -c '%s %Y %Z' -- "$input")
  rm -rf "$tmp"
  if [[ "$stamp_before" != "$stamp_after" ]]; then
    echo "CHYBA: validácia zmenila vstup, to je zakázané: $input" >&2
    exit 3
  fi
  if [[ "$status" -ne 0 ]]; then
    echo "Validácia zlyhala (kód ${status}): $input" >&2
    rc=$status
  else
    echo "Validácia bez chýb: $input" >&2
  fi
done

exit "$rc"
