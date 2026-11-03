#!/usr/bin/env bash
# Zapíše LOD1 a LOD2 vedľa vstupného .glb. Vstupný súbor nemení.
#
# Presné príkazy (gltfpack 1.3). Iné prepínače skript nepridáva:
#   gltfpack -i VSTUP.glb -o VSTUP_lod1.glb -si 0.18 -sp
#   gltfpack -i VSTUP.glb -o VSTUP_lod2.glb -si 0.025 -sp
#
# -i     vstupný .glb
# -o     výstupný .glb
# -si R  simplify meshes targeting triangle/point count ratio R
#        (predvolené 1; R je 0 až 1)
# -sp    permissive simplification: zjednodušenie smie prejsť cez šev atribútu
#
# Samotné -si nestačí. Predvolené -se 0.01 a švy atribútov zjednodušenie
# zastavia skôr, než sa pomer uplatní. Namerané gltfpack 1.3 na
# assets/models/ships/cargo.glb (25 930 tris, súbor sa ním nemení):
#   -si 0.18        → 7 489 tris
#   -si 0.04        → 7 440 tris
#   -si 0.18 -sp    → 4 770 tris
#   -si 0.025 -sp   → 1 474 tris
# Submarine.glb má len 16 776 tris, takže tie isté príkazy dali 3 102 a 566.
# To nie je pásmo kola 2. Pomer v skripte je pevný; po behu trojuholníky
# spočítaj. Pri LOD0 blízko 20 000 môže LOD1 spadnúť pod 4 000. Pri 40 000
# môže LOD1 prekročiť 6 000 a LOD2 prekročiť 1 500.
#
# gltfpack pri týchto príkazoch aj tak kvantizuje (KHR_mesh_quantization).
# Skript nepridáva -c, -sa, -tc, -kn ani -noq. Meno uzla `ship` sa tým stratí.
set -euo pipefail

SI_LOD1=0.18
SI_LOD2=0.025

if [[ $# -ne 1 ]]; then
  echo "Použitie: $0 <model.glb>" >&2
  echo "Zapíše <kmeň>_lod1.glb a <kmeň>_lod2.glb do toho istého priečinka." >&2
  echo "Presné flagy: gltfpack -i <vstup> -o <kmeň>_lod1.glb -si ${SI_LOD1} -sp" >&2
  echo "              gltfpack -i <vstup> -o <kmeň>_lod2.glb -si ${SI_LOD2} -sp" >&2
  exit 1
fi

input=$1
if [[ ! -f "$input" ]]; then
  echo "Súbor neexistuje: $input" >&2
  exit 1
fi
case "$input" in
  *.glb|*.GLB) ;;
  *)
    echo "Vstup musí byť .glb: $input" >&2
    exit 1
    ;;
esac

find_pack() {
  if [[ -n "${GLTFPACK:-}" && -x "${GLTFPACK}" ]]; then
    printf '%s\n' "${GLTFPACK}"
    return 0
  fi
  if command -v gltfpack >/dev/null 2>&1; then
    command -v gltfpack
    return 0
  fi
  local p
  for p in \
    /opt/gltf-tools/node_modules/.bin/gltfpack \
    /usr/local/bin/gltfpack \
    /usr/bin/gltfpack
  do
    if [[ -x "$p" ]]; then
      printf '%s\n' "$p"
      return 0
    fi
  done
  return 1
}

if ! pack=$(find_pack); then
  echo "gltfpack nie je k dispozícii (PATH, GLTFPACK, /opt/gltf-tools/node_modules/.bin/gltfpack)." >&2
  echo "Globálna inštalácia, ak sieť dovolí: npm install -g @gltf-transform/cli gltfpack" >&2
  echo "Ak globálna zlyhá, lokálne do /opt/gltf-tools. LOD sa nezapísali." >&2
  exit 2
fi

dir=$(dirname -- "$input")
base=$(basename -- "$input")
stem=${base%.*}
lod1="${dir}/${stem}_lod1.glb"
lod2="${dir}/${stem}_lod2.glb"

if [[ "$lod1" == "$input" || "$lod2" == "$input" ]]; then
  echo "Názov výstupu by prepísal vstup. Premenuj GLB." >&2
  exit 1
fi

stamp_before=$(stat -c '%s %Y %Z' -- "$input")
# Presne tieto dva riadky.
"$pack" -i "$input" -o "$lod1" -si "$SI_LOD1" -sp
"$pack" -i "$input" -o "$lod2" -si "$SI_LOD2" -sp
stamp_after=$(stat -c '%s %Y %Z' -- "$input")
if [[ "$stamp_before" != "$stamp_after" ]]; then
  echo "CHYBA: gltfpack zmenil vstup, to je zakázané: $input" >&2
  exit 3
fi

echo "LOD1 ${lod1}  (gltfpack -i ${input} -o ${lod1} -si ${SI_LOD1} -sp)"
echo "LOD2 ${lod2}  (gltfpack -i ${input} -o ${lod2} -si ${SI_LOD2} -sp)"
