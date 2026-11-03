# PR 5 — `feat/ship-submarine`

Návrh tela. Nie je to správa z merania. Počty trojuholníkov, veľkosti súborov, FPS, draw cally aj výsledok CI sú **TBD**, kým sa meshe a scéna nezmerajú. Žiadne číslo nižšie nie je nameraný výsledok.

Vetva: `feat/ship-submarine`. **Závisí od PR 1** (`feat/ship-pipeline`). Bez neho sa nemerguje. Kontajner, bulk, všeobecná loď a leštenie mapy sem nepatria.

Loď v zadaní: moderná útočná ponorka, podobná trieda ako Virginia/Astute, ale nie kópia skutočného typu. Súbor, ktorý má generátor zapísať: `assets/models/ships/submarine.glb` a LOD `assets/models/ships/lod/submarine_lod1.glb`, `assets/models/ships/lod/submarine_lod2.glb`. Jeden mesh zdieľajú id `ssn`, `ssbn`, `ssgn`, `ssk` (názvy Ponorka SSN / SSBN / SSGN / SSK). Názvy v `data/ships.json` sa nemenia.

## Čo sa zmenilo

Len vzhľad ponorky, cez vlastný generátor z PR 1.

- Štíhly valcový trup, tmavý povrch, veža (sail), stožiare a periskopy, horizontálne plochy, X-záď, prstenec pumpjetu.
- Nie je to Sketchfab Typhoon ani iný cudzí model. Geometria je z `lathe_sub` v `tools/ships/meshlib.py`.
- Stará kocka sa nemaže. Leží v `_unused/ships_old/submarine_box.glb`.

Či je mesh v strome už finálny a či spĺňa rozpis (hladké prechody, anechoické panely, poklopy, 2–3 ponorové značky, nie kópia skutočnej triedy), tento text netvrdí. Snímky „po“ chýbajú. Ponorenie na mape (len veža a periskopy nad vodou) je PR 6, nie tento PR.

## Čo sa NEzmenilo

- Herná logika lodí: rýchlosť, kapacita, náklad, trasy, ceny.
- Formát save (`SAVE_VERSION`).
- Golden výstupy testov.
- `tests/catalog_field_lock.txt`.
- Bunker a jeho pravidlá.
- Názvy lodí a slovenské texty v UI.
- Ostatné typy lodí (kontajner, bulk, všeobecná, Kenney trupy).
- Zapojenie na mape, vzdialené sprity a obrazovka „Vlastné modely lodí“ (to je PR 6).

## Obrázky pred a po

`docs/ships/before/` aj `docs/ships/after/` sú prázdne. Všetky snímky sú **TBD**.

| Pohľad | Pred | Po |
| --- | --- | --- |
| zblízka 3/4 | `docs/ships/before/ponorka_zblizka.png` — TBD | `docs/ships/after/ponorka_zblizka.png` — TBD |
| bočný profil | `docs/ships/before/ponorka_profil.png` — TBD | `docs/ships/after/ponorka_profil.png` — TBD |
| mapa blízko | `docs/ships/before/ponorka_mapa_blizko.png` — TBD | `docs/ships/after/ponorka_mapa_blizko.png` — TBD |
| mapa ďaleko | `docs/ships/before/ponorka_mapa_daleko.png` — TBD | `docs/ships/after/ponorka_mapa_daleko.png` — TBD |

## Trojuholníky LOD0/1/2

**TBD.** Platí pre `submarine.glb` a oba LOD súbory. Ciele zo zadania nie sú výsledok:

| LOD | Cieľ (nie meranie) | Namerané |
| --- | --- | --- |
| LOD0 | 15 000–40 000 | TBD |
| LOD1 | asi 5 000 | TBD |
| LOD2 | 800–1 500, silueta ponorky | TBD |

Počet materiálov, textúr a veľkosť súborov: **TBD**.

## FPS

**TBD.** FPS a draw cally pred a po, scéna so 100 loďami, sa nemerali. Cieľ zo zadania (pokles najviac 10 %) nie je ani splnený, ani vyvrátený.

## Licencie

Všetko vlastné. Generátor je `tools/ships/` (`meshlib.py`, `build_ships.py`). Žiadne CC-BY assety. Sketchfab Typhoon sa nesťahuje a do tohto PR nepatrí. Do `CREDITS.md` sa pre ponorku nepridáva tretia strana.

## Ako vrátiť

`git revert` commitu tejto vetvy. Stará kocka ostáva v `_unused/ships_old/submarine_box.glb` a nemaže sa. Ňou sa dá vrátiť vzhľad, ak revert sám nestačí.

## CI / P47_UNIT_OK

**TBD.** Tento návrh netvrdí, že testy prešli ani že je CI zelené.

## Checklist z rozpisu lode

Len ponorka. Body kontajnera, bulk a general tento PR nerieši a nezaškrtáva. Nič nižšie nie je hotové, kým to neukáže snímka a meranie.

- [ ] Štíhly valcový trup s hladkými prechodmi. Nie je to hranol a nie je to kópia Virginia, Astute ani Typhoon.
- [ ] Tmavý antireflexný povrch s jemnými panelmi (anechoic tiles).
- [ ] Veža (sail) s periskopmi, anténami a rádiovým stožiarom.
- [ ] Horizontálne kormidlá na veži alebo na prove.
- [ ] Krížová alebo X-záď s kormidlami.
- [ ] Vrtuľa alebo pumpjet, nie oboje ako dve nesúvisiace hračky.
- [ ] Poklopy na palube.
- [ ] 2–3 malé ponorové značky.
- [ ] Silueta aj farba sú z mapy odlíšiteľné od troch obchodných lodí.
- [ ] LOD1 a LOD2 držia siluetu. Počty trojuholníkov sú až po meraní (TBD).
- [ ] Save, golden, lock, bunker a logika lodí sú nedotknuté.
- [ ] Ponorenie (nad vodou len veža a periskopy) sa v tomto PR nerobí. Patrí do PR 6 a tu ostáva nezaškrtnuté.
