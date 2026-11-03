# PR 2 — `feat/ship-container`

Návrh tela. Nie je to správa z merania. Počty trojuholníkov, veľkosti súborov, FPS, draw cally aj výsledok CI sú **TBD**, kým sa meshe a scéna nezmerajú. Žiadne číslo nižšie nie je nameraný výsledok.

Vetva: `feat/ship-container`. **Závisí od PR 1** (`feat/ship-pipeline`). Bez neho sa nemerguje. Bulk, všeobecná loď, ponorka a leštenie mapy sem nepatria.

Loď v zadaní: kontajnerová, Post-Panamax, v pomere asi 300 m. Súbor, ktorý má generátor zapísať: `assets/models/ships/cargo.glb` a LOD `assets/models/ships/lod/cargo_lod1.glb`, `assets/models/ships/lod/cargo_lod2.glb`. Jeden mesh zdieľajú id `feeder`, `panamax_box`, `neo_panamax`, `ulcv`. Názvy v `data/ships.json` sa nemenia.

## Čo sa zmenilo

Len vzhľad kontajnerovej lode, cez vlastný generátor z PR 1.

- Modrý trup, červený spodok, biela nadstavba (mostík) vzadu, nie hranol z kociek.
- Bloky kontajnerov (farby červená, modrá, zelená, šedá, oranžová), rebrovanie, bez loga linky.
- Lávky medzi blokmi (lashing bridges), komín s pásom, kotvy na prove, záchranný čln na zádi, vrtuľa a kormidlo pod vodou.
- Textúra trupu z generátora: `docs/ships/textures/hull_blue.png` (vlastná doska, nie AI).
- Stará kocka sa nemaže. Leží v `_unused/ships_old/cargo_box.glb`.

Či je mesh v strome už finálny a či spĺňa rozpis, tento text netvrdí. Snímky „po“ chýbajú.

## Čo sa NEzmenilo

- Herná logika lodí: rýchlosť, kapacita, náklad, trasy, ceny.
- Formát save (`SAVE_VERSION`).
- Golden výstupy testov.
- `tests/catalog_field_lock.txt`.
- Bunker a jeho pravidlá.
- Názvy lodí a slovenské texty v UI.
- Ostatné typy lodí (bulk, všeobecná, ponorka, Kenney trupy).
- Zapojenie na mape, vzdialené sprity a obrazovka „Vlastné modely lodí“ (to je PR 6).

## Obrázky pred a po

`docs/ships/before/` aj `docs/ships/after/` sú prázdne. Všetky snímky sú **TBD**.

| Pohľad | Pred | Po |
| --- | --- | --- |
| zblízka 3/4 | `docs/ships/before/kontajner_zblizka.png` — TBD | `docs/ships/after/kontajner_zblizka.png` — TBD |
| bočný profil | `docs/ships/before/kontajner_profil.png` — TBD | `docs/ships/after/kontajner_profil.png` — TBD |
| mapa blízko | `docs/ships/before/kontajner_mapa_blizko.png` — TBD | `docs/ships/after/kontajner_mapa_blizko.png` — TBD |
| mapa ďaleko | `docs/ships/before/kontajner_mapa_daleko.png` — TBD | `docs/ships/after/kontajner_mapa_daleko.png` — TBD |

## Trojuholníky LOD0/1/2

**TBD.** Platí pre `cargo.glb` a oba LOD súbory. Ciele zo zadania nie sú výsledok:

| LOD | Cieľ (nie meranie) | Namerané |
| --- | --- | --- |
| LOD0 | 15 000–40 000 | TBD |
| LOD1 | asi 5 000 | TBD |
| LOD2 | 800–1 500, silueta kontajnerovky | TBD |

Počet materiálov, textúr a veľkosť súborov: **TBD**.

## FPS

**TBD.** FPS a draw cally pred a po, scéna so 100 loďami, sa nemerali. Cieľ zo zadania (pokles najviac 10 %) nie je ani splnený, ani vyvrátený.

## Licencie

Všetko vlastné. Generátor je `tools/ships/` (`meshlib.py`, `build_ships.py`). Žiadne CC-BY assety. Sketchfab cargo ship sa nesťahuje a do tohto PR nepatrí. Do `CREDITS.md` sa pre kontajnerovú loď nepridáva tretia strana.

## Ako vrátiť

`git revert` commitu tejto vetvy. Stará kocka ostáva v `_unused/ships_old/cargo_box.glb` a nemaže sa. Ňou sa dá vrátiť vzhľad, ak revert sám nestačí.

## CI / P47_UNIT_OK

**TBD.** Tento návrh netvrdí, že testy prešli ani že je CI zelené.

## Checklist z rozpisu lode

Len kontajner. Body bulk, general a ponorka tento PR nerieši a nezaškrtáva. Nič nižšie nie je hotové, kým to neukáže snímka a meranie.

- [ ] Modrý trup, červený spodok, biela čiara ponoru a ponorové značky na prove a zádi.
- [ ] Biela nadstavba (mostík) vzadu alebo v dvoch tretinách dĺžky, nie kocka namiesto lode.
- [ ] Bulbózna príď, zúženie k prove, kýl. Z mapy je to kontajnerová loď, nie hranol.
- [ ] Kontajnery 20 a 40 stôp v blokoch, radoch a vrstvách. Podpalubie je aspoň naznačené.
- [ ] Farby kontajnerov: modrá, červená, zelená, šedá, oranžová. Rebrovanie a dvere na konci. Žiadne logo Maersk, MSC ani inej firmy.
- [ ] Lashing bridges medzi blokmi a poklopy nákladových priestorov.
- [ ] Komín s farebným pásom, radarový stožiar.
- [ ] Záchranný free-fall čln na zádi.
- [ ] Kotvy a kotevné reťaze na prove.
- [ ] Vrtuľa a kormidlo pod vodou.
- [ ] Variant nákladu: ak to hra už vie, náklad sa dá skryť podľa naloženia. Ak to hra nevie, ostáva plne naložená. Tento stav nie je overený.
- [ ] LOD1 a LOD2 držia siluetu a farbu. Počty trojuholníkov sú až po meraní (TBD).
- [ ] Save, golden, lock, bunker a logika lodí sú nedotknuté.
