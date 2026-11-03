# PR 4 — `feat/ship-general`

Návrh tela. Nie je to správa z merania. Počty trojuholníkov, veľkosti súborov, FPS, draw cally aj výsledok CI sú **TBD**, kým sa meshe a scéna nezmerajú. Žiadne číslo nižšie nie je nameraný výsledok.

Vetva: `feat/ship-general`. **Závisí od PR 1** (`feat/ship-pipeline`). Bez neho sa nemerguje. Kontajner, bulk, ponorka a leštenie mapy sem nepatria.

Loď v zadaní: všeobecná / multipurpose, menšia a kratšia. Súbor, ktorý má generátor zapísať: `assets/models/ships/merchant.glb` a LOD `assets/models/ships/lod/merchant_lod1.glb`, `assets/models/ships/lod/merchant_lod2.glb`. Jeden mesh zdieľajú id `roro`, `pctc`, `general`, `reefer`, `heavy`. Názvy v `data/ships.json` sa nemenia. Súbor sa zámerne nevolá `general.glb`.

## Čo sa zmenilo

Len vzhľad všeobecnej lode, cez vlastný generátor z PR 1.

- Zelený trup, kratší ako kontajnerovka a bulk, mostík vzadu alebo uprostred, nie hranol z kociek.
- Ťažké žeriavy alebo stožiare s ramenami, otvorené podpalubie s debnami, drevom a zvitkom, jeden kontajner na palube, zábradlie, kotva, záchranný čln, komín.
- Textúra trupu z generátora: `docs/ships/textures/hull_green.png` (vlastná doska, nie AI).
- Stará kocka sa nemaže. Leží v `_unused/ships_old/merchant_box.glb`.

Či je mesh v strome už finálny a či spĺňa rozpis (2–3 žeriavy, palety, sudy, viac potrubí a rebríkov), tento text netvrdí. Snímky „po“ chýbajú.

## Čo sa NEzmenilo

- Herná logika lodí: rýchlosť, kapacita, náklad, trasy, ceny.
- Formát save (`SAVE_VERSION`).
- Golden výstupy testov.
- `tests/catalog_field_lock.txt`.
- Bunker a jeho pravidlá.
- Názvy lodí a slovenské texty v UI.
- Ostatné typy lodí (kontajner, bulk, ponorka, Kenney trupy).
- Zapojenie na mape, vzdialené sprity a obrazovka „Vlastné modely lodí“ (to je PR 6).

## Obrázky pred a po

`docs/ships/before/` aj `docs/ships/after/` sú prázdne. Všetky snímky sú **TBD**.

| Pohľad | Pred | Po |
| --- | --- | --- |
| zblízka 3/4 | `docs/ships/before/general_zblizka.png` — TBD | `docs/ships/after/general_zblizka.png` — TBD |
| bočný profil | `docs/ships/before/general_profil.png` — TBD | `docs/ships/after/general_profil.png` — TBD |
| mapa blízko | `docs/ships/before/general_mapa_blizko.png` — TBD | `docs/ships/after/general_mapa_blizko.png` — TBD |
| mapa ďaleko | `docs/ships/before/general_mapa_daleko.png` — TBD | `docs/ships/after/general_mapa_daleko.png` — TBD |

## Trojuholníky LOD0/1/2

**TBD.** Platí pre `merchant.glb` a oba LOD súbory. Ciele zo zadania nie sú výsledok:

| LOD | Cieľ (nie meranie) | Namerané |
| --- | --- | --- |
| LOD0 | 15 000–40 000 | TBD |
| LOD1 | asi 5 000 | TBD |
| LOD2 | 800–1 500, silueta všeobecnej lode | TBD |

Počet materiálov, textúr a veľkosť súborov: **TBD**.

## FPS

**TBD.** FPS a draw cally pred a po, scéna so 100 loďami, sa nemerali. Cieľ zo zadania (pokles najviac 10 %) nie je ani splnený, ani vyvrátený.

## Licencie

Všetko vlastné. Generátor je `tools/ships/` (`meshlib.py`, `build_ships.py`). Žiadne CC-BY assety. Sketchfab merchant sa nesťahuje a do tohto PR nepatrí. Do `CREDITS.md` sa pre všeobecnú loď nepridáva tretia strana.

## Ako vrátiť

`git revert` commitu tejto vetvy. Stará kocka ostáva v `_unused/ships_old/merchant_box.glb` a nemaže sa. Ňou sa dá vrátiť vzhľad, ak revert sám nestačí.

## CI / P47_UNIT_OK

**TBD.** Tento návrh netvrdí, že testy prešli ani že je CI zelené.

## Checklist z rozpisu lode

Len všeobecná loď. Body kontajnera, bulk a ponorky tento PR nerieši a nezaškrtáva. Nič nižšie nie je hotové, kým to neukáže snímka a meranie.

- [ ] Zelený trup, menšia a kratšia loď ako kontajnerovka a bulk.
- [ ] Mostík vzadu alebo uprostred. Červený antifouling, biela čiara ponoru, ponorové značky.
- [ ] Bulbózna príď, zúženie k prove, kýl. Z mapy je to všeobecná loď, nie kocka.
- [ ] 2–3 ťažké žeriavy alebo stožiare s ramenami (derricks).
- [ ] Otvorené alebo pootvárané podpalubie s nákladom: palety, debny, sudy, drevo, oceľové zvitky.
- [ ] Robotný vzhľad: viac potrubí, rebríky, zábradlia.
- [ ] Na palube je kontajner alebo dva, nie celá paluba kontajnerov.
- [ ] Komín, kotva, záchranný čln, vrtuľa a kormidlo.
- [ ] LOD1 a LOD2 držia siluetu a zelenú farbu. Počty trojuholníkov sú až po meraní (TBD).
- [ ] Save, golden, lock, bunker a logika lodí sú nedotknuté.
