# PR 1 — `feat/ship-pipeline`

Návrh tela. Nie je to správa z merania. Počty trojuholníkov, veľkosti súborov, FPS, draw cally aj výsledok CI sú **TBD**, kým sa meshe a scéna nezmerajú. Žiadne číslo nižšie nie je nameraný výsledok.

Vetva: `feat/ship-pipeline`. Ďalšie PR (2–5) na nej stoja. Tento PR sa merguje prvý.

**Vzhľad v hre sa nemení.** Mapa, sprity aj obrazovka modelov ostávajú ako pred touto vetvou. Generátor a spoločné diely sú len základ. Žiadna loď v hre sa na nový mesh neprepína, ani za prepínačom.

## Čo sa zmenilo

Len spoločný postup, nie vzhľad štyroch lodí v hre.

- `tools/ships/meshlib.py` — vlastná geometria a zápis `.glb` (generátor `p47-shipyard`). Žiadna cudzia sieť.
- `tools/ships/build_ships.py` — volanie toho istého generátora. V tomto PR ním hra ešte nekreslí.
- Spoločný trup obchodnej lode (os `-Z` je príď, `Y` hore, kýl pri `Y = 0`), valcový trup ponorky, PBR faktory materiálov, procedúrna doska trupu (antifouling, biela čiara, ponorové značky) do `docs/ships/textures/`.
- Spoločné diely v knižnici: zábradlie, záchranný čln, kotvy, vrtuľa a kormidlo, mostík, okná, komín, poklop, žeriav, kontajner.
- Tri úrovne LOD vie generátor poskladať (LOD0 / LOD1 / LOD2). Hra ich v tomto PR nečíta.
- Render náhľadov do `docs/ships/before/` a `docs/ships/after/` v tomto PR nie je. Oba priečinky sú prázdne.

Do tohto PR nepatria hotové hrdinské meshe kontajnerovej lode, bulk carrieru, všeobecnej lode ani ponorky ako to, čo hráč vidí. Tie sú PR 2–5. Mapa, vzdialené sprity a obrazovka „Vlastné modely lodí“ sú PR 6.

## Čo sa NEzmenilo

- Herná logika lodí: rýchlosť, kapacita, náklad, trasy, ceny.
- Formát save (`SAVE_VERSION`).
- Golden výstupy testov.
- `tests/catalog_field_lock.txt`.
- Bunker a jeho pravidlá.
- Názvy lodí a slovenské texty v UI.
- Dátové JSON, vrátane `data/ships.json` (cesty modelov sa neprepisujú).
- Kenney trupy (carrier, tanker, fregata a ďalšie) a ich CC0 licencia.

## Obrázky pred a po

Vzhľad v hre je zámerne ten istý, preto „pred“ a „po“ nemajú čo ukázať. Snímky nie sú vygenerované.

| Pohľad | Pred | Po |
| --- | --- | --- |
| zblízka | `docs/ships/before/` — TBD, priečinok je prázdny | `docs/ships/after/` — TBD, priečinok je prázdny |
| profil | TBD | TBD |
| mapa blízko | TBD | TBD |
| mapa ďaleko | TBD | TBD |

## Trojuholníky LOD0/1/2

**TBD.** Meshe sa pre tento text nemerali. Ciele zo zadania nie sú výsledok:

| LOD | Cieľ (nie meranie) | Namerané |
| --- | --- | --- |
| LOD0 | 15 000–40 000 | TBD |
| LOD1 | asi 5 000 | TBD |
| LOD2 | 800–1 500, silueta | TBD |

Počet materiálov, textúr a veľkosť súborov: **TBD**.

## FPS

**TBD.** FPS a draw cally pred a po, scéna so 100 loďami, sa nemerali. Cieľ zo zadania (pokles najviac 10 %) nie je ani splnený, ani vyvrátený.

## Licencie

Všetko vlastné. Generátor je `tools/ships/` (`meshlib.py`, `build_ships.py`). Žiadne CC-BY assety, žiadny Sketchfab, žiadny Free3D, žiadne logá reálnych liniek. Do `CREDITS.md` sa pre tieto štyri lode nepridáva tretia strana.

## Ako vrátiť

`git revert` commitu tejto vetvy. Hra vyzerá rovnako aj pred reverom, lebo vzhľad sa nemení. Staré kocky ostávajú na mieste a nemažú sa:

- `_unused/ships_old/cargo_box.glb`
- `_unused/ships_old/bulk_box.glb`
- `_unused/ships_old/merchant_box.glb`
- `_unused/ships_old/submarine_box.glb`

## CI / P47_UNIT_OK

**TBD.** Tento návrh netvrdí, že testy prešli ani že je CI zelené.

## Checklist z rozpisu lode

Body sú požiadavky, nie hotové kroky. Nič nie je zaškrtnuté. Kým to nie je overené na vetve, nie je to pravda o hre.

Spoločný postup (tento PR):

- [ ] Generátor v `tools/ships/` je jediný zdroj geometrie týchto štyroch lodí a neťahá cudzie meshe.
- [ ] Trup v knižnici nie je hranol: bulbózna príď, zúženie k prove, kýl, normály bez falošných hrán tam, kde nemajú byť.
- [ ] Materiál trupu vie dvojfarebnosť (farba nad čiarou, červený antifouling, biela čiara, ponorové značky) bez AI textúry.
- [ ] Spoločné diely sú v knižnici: zábradlie, záchranný čln, kotvy, vrtuľa a kormidlo.
- [ ] LOD0, LOD1 a LOD2 sú v generátore oddelené. Hra ich v tomto PR nekreslí.
- [ ] Diff nemení save, golden, `catalog_field_lock.txt`, bunker ani logiku lodí.
- [ ] V hre sa vzhľad nezmenil: mapa aj karty lodí sú ako pred vetvou.

Kontajner, bulk, general a ponorka (rozpis detailov) do tohto PR nepatria. Všetky ich body ostávajú nezaškrtnuté a overujú sa až v PR 2–5. Tu sa netvrdí, že loď v hre má kontajnery, poklopy, žeriavy ani vežu ponorky.
