# Blender — os a limity lodí (kolo 2)

Platí pre GLB, ktorý ide do hry. Blender sám je Z-up; dohoda nižšie je o súbore po exporte glTF, nie o pohľade v viewporte.

## Os

| | |
| --- | --- |
| Hore | **Y-up** |
| Príď | **−Z** (bow = −Z) |
| Kýl | **Y = 0** |
| Dĺžka | pozdĺž **Z**, asi **3,4** |
| Šírka (beam) | pozdĺž **X** (pravobok +) |

Exportér glTF v Blenderi predvolene mapuje bod `(x, y, z)` na `(x, z, −y)`. Preto v súbore Blend:

- výška je os Z a kýl leží na Z = 0 (po exporte Y = 0);
- príď smeruje na **+Y** v Blendri, aby po exporte bola na **−Z**;
- šírka ostáva na X.

Ak exportér Y-up konverziu vypne, GLB je zle a do hry nepatrí. Jednotky nech sú také, aby dĺžka trupu v GLB bola asi 3,4, nie dĺžka skutočnej lode v metroch.

## Materiály

Najviac **5 materiálov** na jednu loď.

Farby kontajnerov sú **jeden atlas** (jedna textúra, rôzne UV). Samostatný materiál na každú farbu kontajnera je zakázaný.

## Trojuholníky a veľkosť

| Úroveň | Trojuholníky | Súbor |
| --- | --- | --- |
| LOD0 (hrdina) | 20 000–40 000 | ≤ 4 MB |
| LOD1 | 4 000–6 000 | ≤ 1 MB |
| LOD2 | 800–1 500 | ≤ 1 MB |

LOD vedľa hero súboru vyrába `tools/ships/make_lods.sh`. Presné príkazy (gltfpack 1.3):

```text
gltfpack -i <lod.glb> -o <lod>_lod1.glb -si 0.18 -sp
gltfpack -i <lod.glb> -o <lod>_lod2.glb -si 0.025 -sp
```

`-si` je pomer počtu trojuholníkov voči vstupu (0–1). `-sp` dovolí zjednodušeniu prejsť cez šev atribútu. Bez `-sp` predvolené `-se 0.01` pomer skoro neuplatní: na `cargo.glb` (25 930 tris) dalo `-si 0.18` 7 489 tris a `-si 0.04` 7 440. S `-sp` ten istý súbor dal 4 770 (`-si 0.18`) a 1 474 (`-si 0.025`). Iný počet tris na vstupe dá iný výsledok. Po behu treba trojuholníky spočítať znova. Skript nepridáva `-c`, `-sa`, `-kn` ani `-noq`. Kvantizácia `KHR_mesh_quantization` je predvolené správanie gltfpacku a vo výstupe je.

Kontrola súboru bez zápisu reportu vedľa neho: `tools/ships/validate_glb.sh`. Ak `gltf_validator` na stroji nie je, skript skončí kódom 2. To nie je úspech.

## Čo sa do modelu nesmie

- Meshe vyrobené umelou inteligenciou.
- Modely zo Sketchfabu (ani „inšpirované“ stiahnutou sieťou).
- Cudzia geometria. Kreslí sa tu, alebo ju skladá `tools/ships/build_ships.py`.
