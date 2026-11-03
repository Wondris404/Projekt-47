# Dotykové miesta vzhľadu lodí

Jediný kreslič lodí na mape je `scripts/ui/atlas_traffic.gd`. Loď nevzniká ako Godot `BoxMesh` a v `scenes/` žiadna loď nie je. Scéna `scenes/main.tscn` len spúšťa `scripts/main.gd`, ktorý vytvorí `WorldMap` v kóde.

Os Kenney (už používaná vodnými modelmi aj štyrmi triedami): **Y up, bow -Z, keel Y=0**. `tools/ships/meshlib.py` to dopĺňa o X = šírka, pravobok +.

Na **origin/main** majú štyri triedy (Kontajnerová, Bulk, Všeobecná, Ponorka) **prázdne pole `model`**. Unit test `ship_model_missing_fallback` to očakáva: `ShipSystem.model_path()` vráti `""` a mapa kreslí fallback sprite, nie `cargo.glb` / `bulk.glb` / `merchant.glb` / `submarine.glb`. Tento pracovný strom je iný: `data/ships.json` má cesty vyplnené a `tests/phase_c_ships.gd` kontroluje `ship_model_cargo_bulk_merchant_sub`, nie `ship_model_missing_fallback`.

## Čo hráč uvidí (runtime)

1. `project.godot` — autoload `ShipSystem` (`scripts/autoload/ShipSystem.gd`).
2. `scripts/autoload/ShipSystem.gd` — načíta `data/ships.json`. `model_path(kind_id)` vráti pole `model` len keď je neprázdne a súbor existuje, inak `""`. `buy()` pridá záznam do `GameState.ext.fleet` (`kind_id`, nie mesh). `pos_of()` je bod, ktorý mapa kreslí. `ship_at()` trafí len civilnú loď (ponorka je `kind: military`, kreslí sa, klik ju nechytí).
3. `data/ships.json` — katalóg. Pole `model` je jediný odkaz na vizuál. Gameplay polia (speed, capacity, price, cargo, trasa) sa nekreslia.
4. `scripts/main.gd` — `WorldMapScript.new()` (~riadky 23 a 396). Tlačidlo „Lode“ (`_toggle_ships` / `_fill_ships`, ~2293) je textový nákup, nie 3D náhľad. Po `buy()` sa loď objaví až na mape.
5. `scripts/ui/world_map.gd` — v `_ready()` (riadok 110) pridá vrstvu `preload("res://scripts/ui/atlas_traffic.gd")` a na `draw` volá jej `queue_redraw`. `_click_at` (1011) len vypíše `ShipSystem.info`, nekreslí trup. `shipyard` v `atlas_infra` je budova prístavu, nie loď.
6. `scripts/ui/atlas_traffic.gd` — `_draw_ships()`:
   - najviac 32 civilných a 32 vojenských (`MAX_CIVIL_SHIPS`);
   - `model_path != ""`: pri `zoom >= NEAR_ZOOM` (8) a nie `GFX.low()` jeden snímok GLB do `SubViewport` 128×96 (`UPDATE_ONCE`, orto kamera v `(2.1, 2.3, 2.6)` na `(0, 0.55, 0)`, `size` 4.8); inak PNG `res://assets/sprites/ships/<kmeň súboru>.png`;
   - `model_path == ""`: `FALLBACK_SHIP` → `fallback_container.png` / `fallback_bulk.png` / `fallback_general.png` / `fallback_sub.png` (18×28 px);
   - keď chýba aj sprite: zlatý trojuholník `D5AB39`;
   - `_draw_ship_tex`: sprite má predok hore (−Y), otočenie `heading.angle() + PI/2`.
   - LOD súbory v `assets/models/ships/lod/` sa nenačítavajú. Blízky aj vzdialený záber berie len cestu z `model_path`.
7. `scripts/gfx.gd` — `GFX.low()` vypne blízky 3D náhľad lode (ostane vzdialený sprite alebo fallback).

## Štyri triedy → súbor

| Trieda | `kind` / id v `data/ships.json` | `model` v tomto strome | vzdialený sprite | fallback pri prázdnom `model` |
| --- | --- | --- | --- | --- |
| Kontajnerová | `container`: `feeder`, `panamax_box`, `neo_panamax`, `ulcv` (názvy „Kontajner …“) | `assets/models/ships/cargo.glb` | `assets/sprites/ships/cargo.png` | `fallback_container.png` |
| Bulk | `bulk`: `handy_bulk`, `supramax`, `panamax_bulk`, `capesize`, `vloc` (názvy „Bulk …“) | `assets/models/ships/bulk.glb` | `assets/sprites/ships/bulk.png` | `fallback_bulk.png` |
| Všeobecná | `general`: `roro`, `pctc`, `general` („Všeobecný náklad“), `reefer`, `heavy` | `assets/models/ships/merchant.glb` | `assets/sprites/ships/merchant.png` | `fallback_general.png` |
| Ponorka | `military`: `ssn`, `ssbn`, `ssgn`, `ssk` (názvy „Ponorka …“) | `assets/models/ships/submarine.glb` | `assets/sprites/ships/submarine.png` | `fallback_sub.png` |

Rovnaký `model_path` → `atlas_traffic` kreslí aj ostatné trupy (Kenney): `carrier.glb`, `landing.glb`, `destroyer.glb`, `frigate.glb`, `patrol.glb`, `tanker.glb`, `lng.glb`, `psv.glb` a ich PNG v `assets/sprites/ships/`. Tie štyri triedy medzi ne nepatria.

## Assety

- `assets/models/ships/cargo.glb`, `bulk.glb`, `merchant.glb`, `submarine.glb` — LOD0, generator `p47-shipyard`, jeden node `ship` / mesh `hull`. Godot ich importuje ako `PackedScene` (`*.glb.import` vedľa súboru). Blízka mapa inštancuje práve tento súbor.
- `assets/models/ships/lod/{cargo,bulk,merchant,submarine}_lod1.glb` a `_lod2.glb` — vygenerované, hra ich nečíta.
- `assets/models/ships/{carrier,landing,destroyer,frigate,patrol,tanker,lng,psv}.glb` (+ `*_colormap.png` tam, kde je) — ostatné triedy, ten istý kreslič.
- `assets/sprites/ships/{cargo,bulk,merchant,submarine}.png` — 64×96, predok hore. Ostatné trupy v tom istom priečinku sú 64×32.
- `assets/sprites/ships/fallback_{container,bulk,general,sub}.png` — 64×96, kreslia sa len keď `model_path` je prázdny.
- `docs/ships/textures/hull_{blue,brown,green}.png` — zdrojová albedo textúra zapečená do LOD0 GLB. Godot ju ako `res://` nenačítava.
- `_unused/ships_old/{cargo,bulk,merchant,submarine}_box.glb` — staré kocky (generator `p47-original`). Mapa ich nenačítava.

`assets/map_models/units/{feeder,vlcc,destroyer,psv,ahts}.png` (32×16) hra nekreslí. Kontroluje ich len `tests/atlas_new_models.gd`.

## Testy, ktoré držia vizuál (nesiahaj na ne v tomto zadaní)

- `tests/phase_c_ships.gd` — v tomto strome `ship_model_cargo_bulk_merchant_sub` (`feeder`→`cargo.glb`, `handy_bulk`→`bulk.glb`, `general`→`merchant.glb`, `ssn`/`ssbn`→`submarine.glb`) a `ship_model_file_*` / `ship_model_psv_ahts`. `ships_civil_cap` čaká `atlas_traffic.MAX_CIVIL_SHIPS == 32`.
- `tests/unit.gd` — volá `phase_c_ships.gd`.
- Na **origin/main** namiesto toho platí `ship_model_missing_fallback`: štyri triedy majú `model` prázdne.

## Kde sa štyri meshe skladajú (mimo behu hry, `/tools/` je v `.gitignore`)

- `tools/ships/meshlib.py` — geometria. Komentár osi: Y up, kýl pri Y = 0, príď −Z. `add_box` je lokálny kváder v GLB, nie Godot `BoxMesh`. `write_glb` píše generator `p47-shipyard`.
- `tools/ships/build_ships.py` — `cargo` / `bulk` / `general` / `submarine` → `cargo.glb`, `bulk.glb`, `merchant.glb`, `submarine.glb` a `lod/*`. Do `data/ships.json` nezapisuje.
- `tools/make_ship_glbs.py` — starý generátor kociek (`def box`, generator `p47-original`). Vedel prepísať `model` v `data/ships.json` a skopírovať fallback PNG na `cargo.png` / `bulk.png` / `merchant.png` / `submarine.png`. Výsledok je v `_unused/ships_old/*_box.glb`.

## Čo loď nekreslí

- `BoxMesh` je v hre len v `scripts/ui/prototype_world_3d.gd` (riadky 105 a 186): kocky firiem a miest. Lode tam nie sú.
- Obrazovka „Vlastné modely lodí“ nie je v Godot strome. Statické karty „Kontajnerová loď“, „Bulk carrier“, „Všeobecná loď“, „Ponorka“ sú v sandboxe mimo hry (`/workspace/src/components/atlas/AtlasApp.tsx`, PNG `public/modely_*.png`). `atlas_traffic` ich nečíta.
- `docs/ships_models.md` a `assets/models/ships/_inbox/STIAHNI.txt` sú poznámky k licenciám, nie loader.
- `scripts/ui/atlas_draw.gd` kreslí ikonu lodenice, nie trup.
