# Bench flotily nie je cesta mapy

Strategická mapa nekreslí živé 3D lode. `scripts/ui/atlas_traffic.gd` kreslí každú loď ako 2D billboard:

- Zblízka (zoom aspoň `NEAR_ZOOM`, nie nízke GFX): model sa raz vloží do `SubViewport` (128×96, `render_target_update_mode = UPDATE_ONCE`). Textúra sa potom kreslí ako otočený sprite. Ďalšie snímky ten viewport neprekresľujú.
- Zdiaľky: hotový sprite z `_far_sprite` (`res://assets/sprites/ships/<meno modelu>.png`).
- Strop je 32 civilných a 32 vojenských ikon (`MAX_CIVIL_SHIPS`).

`tools/ships/bench_fleet.gd` je samostatný headless skript (`extends SceneTree`). Načíta `res://assets/models/ships/cargo.glb`, ak existuje, a vloží ho 100-krát pod `Node3D` do mriežky. To je meracia scéna so živými `MeshInstance3D`, nie cesta mapy. Hru, save ani `data/ships.json` nemení.

Ak `.glb` chýba alebo to nie je `PackedScene`, vypíše `P47_SHIP_BENCH missing` a skončí cez `quit()` s kódom 0. Inak, keď vie viewport kresliť, nechá pár snímok prejsť kamerou. V headless režime kresliť nevie, ale aj tak spočíta uzly `MeshInstance3D` a ich povrchy a vypíše `P47_SHIP_BENCH <počet inštancií> <počet povrchov>`, potom `quit()`.

```
godot --headless --path . -s res://tools/ships/bench_fleet.gd
```
