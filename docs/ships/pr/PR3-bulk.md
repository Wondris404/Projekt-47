# PR 3 — `feat/ship-bulk`

Návrh tela. Nie je to správa z merania. Počty trojuholníkov, veľkosti súborov, FPS, draw cally aj výsledok CI sú **TBD**, kým sa meshe a scéna nezmerajú. Žiadne číslo nižšie nie je nameraný výsledok.

Vetva: `feat/ship-bulk`. **Závisí od PR 1** (`feat/ship-pipeline`). Bez neho sa nemerguje. Kontajner, všeobecná loď, ponorka a leštenie mapy sem nepatria.

Loď v zadaní: bulk carrier, Capesize/Panamax. Súbor, ktorý má generátor zapísať: `assets/models/ships/bulk.glb` a LOD `assets/models/ships/lod/bulk_lod1.glb`, `assets/models/ships/lod/bulk_lod2.glb`. Jeden mesh zdieľajú id `handy_bulk`, `supramax`, `panamax_bulk`, `capesize`, `vloc`. Názvy v `data/ships.json` sa nemenia.

## Čo sa zmenilo

Len vzhľad bulk carrieru, cez vlastný generátor z PR 1.

- Hnedočervený trup, mostík úplne vzadu, nie hranol z kociek.
- Rad veľkých nákladových poklopov s výstuhami.
- Palubné žeriavy medzi poklopmi, kotvy, zábradlie na prove, komín, záchranný čln, vrtuľa a kormidlo.
- Textúra trupu z generátora: `docs/ships/textures/hull_brown.png` (vlastná doska, nie AI).
- Stará kocka sa nemaže. Leží v `_unused/ships_old/bulk_box.glb`.

Či je mesh v strome už finálny a či spĺňa rozpis (7–9 poklopov, drapáky, silueta z mapy), tento text netvrdí. Snímky „po“ chýbajú.

## Čo sa NEzmenilo

- Herná logika lodí: rýchlosť, kapacita, náklad, trasy, ceny.
- Formát save (`SAVE_VERSION`).
- Golden výstupy testov.
- `tests/catalog_field_lock.txt`.
- Bunker a jeho pravidlá.
- Názvy lodí a slovenské texty v UI.
- Ostatné typy lodí (kontajner, všeobecná, ponorka, Kenney trupy).
- Zapojenie na mape, vzdialené sprity a obrazovka „Vlastné modely lodí“ (to je PR 6).

## Obrázky pred a po

`docs/ships/before/` aj `docs/ships/after/` sú prázdne. Všetky snímky sú **TBD**.

| Pohľad | Pred | Po |
| --- | --- | --- |
| zblízka 3/4 | `docs/ships/before/bulk_zblizka.png` — TBD | `docs/ships/after/bulk_zblizka.png` — TBD |
| bočný profil | `docs/ships/before/bulk_profil.png` — TBD | `docs/ships/after/bulk_profil.png` — TBD |
| mapa blízko | `docs/ships/before/bulk_mapa_blizko.png` — TBD | `docs/ships/after/bulk_mapa_blizko.png` — TBD |
| mapa ďaleko | `docs/ships/before/bulk_mapa_daleko.png` — TBD | `docs/ships/after/bulk_mapa_daleko.png` — TBD |

## Trojuholníky LOD0/1/2

**TBD.** Platí pre `bulk.glb` a oba LOD súbory. Ciele zo zadania nie sú výsledok:

| LOD | Cieľ (nie meranie) | Namerané |
| --- | --- | --- |
| LOD0 | 15 000–40 000 | TBD |
| LOD1 | asi 5 000 | TBD |
| LOD2 | 800–1 500, silueta bulk carrieru | TBD |

Počet materiálov, textúr a veľkosť súborov: **TBD**.

## FPS

**TBD.** FPS a draw cally pred a po, scéna so 100 loďami, sa nemerali. Cieľ zo zadania (pokles najviac 10 %) nie je ani splnený, ani vyvrátený.

## Licencie

Všetko vlastné. Generátor je `tools/ships/` (`meshlib.py`, `build_ships.py`). Žiadne CC-BY assety. Do `CREDITS.md` sa pre bulk carrier nepridáva tretia strana.

## Ako vrátiť

`git revert` commitu tejto vetvy. Stará kocka ostáva v `_unused/ships_old/bulk_box.glb` a nemaže sa. Ňou sa dá vrátiť vzhľad, ak revert sám nestačí.

## CI / P47_UNIT_OK

**TBD.** Tento návrh netvrdí, že testy prešli ani že je CI zelené.

## Checklist z rozpisu lode

Len bulk. Body kontajnera, general a ponorky tento PR nerieši a nezaškrtáva. Nič nižšie nie je hotové, kým to neukáže snímka a meranie.

- [ ] Hnedočervený alebo čierny trup, červený antifouling, biela čiara ponoru a ponorové značky.
- [ ] Mostík je úplne vzadu.
- [ ] Bulbózna príď, zúženie k prove, kýl. Z mapy je to bulk, nie kontajnerovka ani kocka.
- [ ] 7–9 veľkých nákladových poklopov (side-rolling hatch covers) s výstuhami.
- [ ] 4 palubné žeriavy medzi poklopmi, s ramenami a drapákmi (grab).
- [ ] Silná príď so zábradlím a kotevné zariadenie.
- [ ] Komín a záchranný čln.
- [ ] Vrtuľa a kormidlo pod vodou.
- [ ] LOD1 a LOD2 držia siluetu a farbu. Počty trojuholníkov sú až po meraní (TBD).
- [ ] Save, golden, lock, bunker a logika lodí sú nedotknuté.
