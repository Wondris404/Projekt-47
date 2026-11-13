# CREDITS

## Fáza F

Nové sprity budov (`ai_services`, `crude_oil`, `fuel`, `weapons`, `offshore_oil_rig`, `offshore_gas_rig`, `fpso`) a jednotiek lodí okrem PSV/AHTS sú zástupné pixel-art tvary projektu.

## Halloween DLC

- **Animated Zombie Pack** – Quaternius – CC0 1.0 (https://quaternius.com/packs/animatedzombie.html). `assets/models/zombies/zombie.glb` je prevod z `Zombie.blend` (s animáciami Idle/Walk/Run/Attack/Bite/Crawl) cez Blender 4.2 (`tools/render_dlc_models.py`). `zombie_sprite.png` je z neho vyrenderovaný sprite pre mapu.
- **Helicopter** – kazuma – CC0 1.0 (https://poly.pizza/m/EQJ2MECUbx). `assets/models/aircraft/heli.glb`, sprite `heli_sprite.png`.
- **Jet** – Poly by Google – CC-BY 3.0 (https://poly.pizza/m/dukcCKsLDrS). `assets/models/aircraft/fighter.glb`, sprite `fighter_sprite.png`. Licencia vyžaduje uvedenie autora: „Jet“ by Poly by Google, via Poly Pizza.

Staré `*_placeholder.png` ostávajú v repe ako záloha, hra ich už nepoužíva.

## Bunker (Halloween DLC)

- **Star Wars Endor Bunker** – aclarke064 – CC BY-NC-SA 4.0 – https://sketchfab.com/3d-models/star-wars-endor-bunker-1c54abb1c6824f26a0a087d2bd7a635a – nekomerčné použitie. `assets/models/bunker/bunker.glb` je prevod (predok na -Z, spodok na Y = 0, textúry 1024 px). Licencia je v `assets/models/bunker/LICENSE.txt`.

## Lode

- **Boat Tug** (`boat-tug-a`) – Kenney – CC0 1.0 – https://kenney.nl/assets/watercraft-kit. Súbor `assets/models/ships/psv.glb` je prevod tohto modelu (predok na osi -Z, trup na Y = 0, textúra 512×512 vložená). `assets/sprites/ships/psv.png` je pohľad zhora. Používajú ho `psv` a `ahts`.
- **Kenney Watercraft Kit** – Kenney – CC0 1.0 – https://kenney.nl/assets/watercraft-kit. Zapojené trupy: `carrier.glb` (carrier), `landing.glb` (lhd, lpd, lst, hospital), `destroyer.glb` (destroyer, cruiser), `frigate.glb` (frigate, corvette), `patrol.glb` (patrol, missile, sweeper, minelayer), `tanker.glb` (ropné tankery a oiler), `lng.glb` (lng, lpg). Cargo, bulk, general a ponorky ostávajú na fallback sprite.

## UI grafika (vetva p47/gfx)

- **Inter** (Regular, SemiBold) – The Inter Project Authors (Rasmus Andersson) – SIL Open Font License 1.1 – https://github.com/rsms/inter (release v4.1). Súbory `assets/fonts/Inter-Regular.ttf`, `assets/fonts/Inter-SemiBold.ttf`, licencia `assets/fonts/OFL-Inter.txt`. Základné písmo UI témy.
- **Oswald** (variabilný) – The Oswald Project Authors (Vernon Adams a i.) – SIL Open Font License 1.1 – https://github.com/googlefonts/OswaldFont (súbor z https://github.com/google/fonts/tree/main/ofl/oswald). Súbor `assets/fonts/Oswald-Variable.ttf`, licencia `assets/fonts/OFL-Oswald.txt`. Nadpisy (`HeaderLabel`, `TitleLabel`).
- **UI ikony** `assets/ui/p47/*.svg` – vlastné, Projekt-47 – CC0 1.0. Generuje ich `scripts/generate_ui_icons_p47.py`.
- **UI téma** `ui/theme_p47.tres` – vlastná, Projekt-47 – CC0 1.0. Generuje ju `scripts/generate_theme_p47.py`. Stará `ui/theme_factorio.tres` ostáva v repe.
