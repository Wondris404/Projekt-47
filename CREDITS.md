# CREDITS

## Fáza F

Nové sprity budov (`ai_services`, `crude_oil`, `fuel`, `weapons`, `offshore_oil_rig`, `offshore_gas_rig`, `fpso`) a jednotiek lodí okrem PSV/AHTS sú zástupné pixel-art tvary projektu.

## Halloween DLC

- **Animated Zombie Pack** – Quaternius – CC0 1.0 (https://quaternius.com/packs/animatedzombie.html). `assets/models/zombies/zombie.glb` je prevod z `Zombie.blend` (s animáciami Idle/Walk/Run/Attack/Bite/Crawl) cez Blender 4.2 (`tools/render_dlc_models.py`). `zombie_sprite.png` je z neho vyrenderovaný sprite pre mapu.
- **Helicopter** – kazuma – CC0 1.0 (https://poly.pizza/m/EQJ2MECUbx). `assets/models/aircraft/heli.glb`, sprite `heli_sprite.png`.
- **Jet** – Poly by Google – CC-BY 3.0 (https://poly.pizza/m/dukcCKsLDrS). `assets/models/aircraft/fighter.glb`, sprite `fighter_sprite.png`. Licencia vyžaduje uvedenie autora: „Jet“ by Poly by Google, via Poly Pizza.

Staré `*_placeholder.png` ostávajú v repe ako záloha, hra ich už nepoužíva.

## Lode

- **Boat Tug** (`boat-tug-a`) – Kenney – CC0 1.0 – https://kenney.nl/assets/watercraft-kit. Súbor `assets/models/ships/psv.glb` je prevod tohto modelu (predok na osi -Z, trup na Y = 0, textúra 512×512 vložená). `assets/sprites/ships/psv.png` je pohľad zhora. Používajú ho `psv` a `ahts`.
- Súbory `carrier.glb`, `landing.glb`, `destroyer.glb`, `frigate.glb`, `patrol.glb`, `tanker.glb` a `lng.glb` sú tiež z Kenney Watercraft Kit (CC0, https://kenney.nl/assets/watercraft-kit), ale flotila ich nepoužíva. Povolený Kenney trup v zadaní je len Boat Tug. Ostatné typy ostávajú placeholder, kým nie je originál s overenou licenciou v repe.
