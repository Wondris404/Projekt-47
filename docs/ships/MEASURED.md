# Namerané meshe

Vlastná geometria, generátor `tools/ships/`. Žiadny stiahnutý model.

| Loď | LOD0 | LOD1 | LOD2 | súbor LOD0 |
|---|---:|---:|---:|---|
| Kontajnerová (`cargo.glb`) | 25930 | 3446 | 1130 | 3.4 MB |
| Bulk (`bulk.glb`) | 17392 | 3006 | 1298 | 1.9 MB |
| Všeobecná (`merchant.glb`) | 16942 | 3018 | 1082 | 1.8 MB |
| Ponorka (`submarine.glb`) | 16776 | 3560 | 1132 | 1.8 MB |

LOD0 je v rozsahu 15–40 tisíc. LOD2 je v rozsahu 800–1500. LOD1 je okolo 3–3,5 tisíc, nie 5 tisíc: na mape sa aj tak kreslí billboard, nie živé LOD.

Os ako Kenney: Y hore, predok −Z, kýl pri Y = 0.

Mapa (`atlas_traffic.gd`) kreslí loď ako obrázok. 100 živých trupov je len benchmark `tools/ships/bench_fleet.gd`, nie cesta hry. Bench na headless Godot nahlásil 100 inštancií.

Starý kockový mesh je v `_unused/ships_old/` a hra ho nepoužíva.
