# PR 6 — `feat/ship-polish`

Návrh tela. Nie je to správa z merania. Počty trojuholníkov, veľkosti súborov, FPS, draw cally aj výsledok CI sú **TBD**, kým sa meshe a scéna nezmerajú. Žiadne číslo nižšie nie je nameraný výsledok.

Vetva: `feat/ship-polish`. **Závisí od PR 1** (`feat/ship-pipeline`) a od modelov z PR 2–5. Bez nich nie je čo na mape ani na hrdinskej obrazovke ukázať. Tento PR nerieši tvar trupu. Rieši čitateľnosť na mape, vzdialené sprity a hrdinskú obrazovku „Vlastné modely lodí“.

Hra dnes kreslí loď v `scripts/ui/atlas_traffic.gd`: zblízka textúru z náhľadu modelu, z diaľky `assets/sprites/ships/<meno>.png`, a keď model chýba, fallback alebo zlatý trojuholník. Tento návrh netvrdí, že sa to už upravilo.

## Čo sa zmenilo

Len čítanie lodí na mape a ich hrdinská prezentácia. Geometria ostáva v PR 2–5.

- Mapa: štyri siluety sa dajú rozoznať aj z oddialenia, podľa tvaru aj farby (modrá kontajnerovka, hnedý bulk, zelená všeobecná, tmavá ponorka). Zlatý trojuholník nie je ich bežný vzhľad, keď súbor existuje.
- Vzdialené sprity (nie náhrada za hero mesh): `assets/sprites/ships/cargo.png`, `bulk.png`, `merchant.png`, `submarine.png`. Fallbacky, ak model chýba: `fallback_container.png`, `fallback_bulk.png`, `fallback_general.png`, `fallback_sub.png`. Či sú tieto PNG už nové, tento text netvrdí.
- Hrdinská obrazovka „Vlastné modely lodí“: LOD0, pohľad 3/4, svetlé karty v štýle UI. Názov obrazovky sa nemení, ak v kóde znie inak (tlačidlo flotily je „Lode“). Nový názov sa nevymýšľa.
- Staré kocky sa nemažú. Ostávajú v `_unused/ships_old/`.

Hojdanie, brázda, pena a nočné svetlá sú v zadaní pri leštení. Tu nie sú hotové a nie sú zaškrtnuté. Kým nie sú lacné (shader, nie fyzika) a namerané, do hry nepatria.

## Čo sa NEzmenilo

- Herná logika lodí: rýchlosť, kapacita, náklad, trasy, ceny.
- Formát save (`SAVE_VERSION`).
- Golden výstupy testov.
- `tests/catalog_field_lock.txt`.
- Bunker a jeho pravidlá.
- Názvy lodí a slovenské texty v UI.
- Tvar trupov z PR 2–5 (tento PR ich neprekresľuje inou loďou).
- Kenney trupy a ich CC0 sprity (carrier, tanker a ďalšie) sa nepredstierajú ako vlastné modely týchto štyroch lodí.

## Obrázky pred a po

`docs/ships/before/` aj `docs/ships/after/` sú prázdne. Všetky snímky sú **TBD**. Tento PR potrebuje najmä mapu a hrdinskú obrazovku.

| Pohľad | Pred | Po |
| --- | --- | --- |
| hrdinská obrazovka | `docs/ships/before/hero_obrazovka.png` — TBD | `docs/ships/after/hero_obrazovka.png` — TBD |
| mapa blízko, štyri typy vedľa seba | `docs/ships/before/mapa_blizko_styri.png` — TBD | `docs/ships/after/mapa_blizko_styri.png` — TBD |
| mapa ďaleko, sprity | `docs/ships/before/mapa_daleko_sprity.png` — TBD | `docs/ships/after/mapa_daleko_sprity.png` — TBD |
| profil (kontrola, že sa tvar nezmenil) | `docs/ships/before/` — TBD | `docs/ships/after/` — TBD |

## Trojuholníky LOD0/1/2

**TBD.** Tento PR ich nevymýšľa znova. Berie čísla z PR 2–5, až keď budú namerané. Dovtedy:

| LOD | Cieľ (nie meranie) | Namerané |
| --- | --- | --- |
| LOD0 (hrdinská obrazovka) | 15 000–40 000 | TBD |
| LOD1 (priblížená mapa) | asi 5 000 | TBD |
| LOD2 (oddialená mapa) | 800–1 500, silueta | TBD |

Z diaľky má ísť sprite, nie plný mesh. Či to tak kreslí beh, je neoverené. Počet materiálov, textúr a veľkosť súborov: **TBD**.

## FPS

**TBD.** FPS a draw cally pred a po, scéna so 100 loďami, sa nemerali. Cieľ zo zadania (pokles najviac 10 %) nie je ani splnený, ani vyvrátený. Bez toho sa leštenie nedá označiť za hotové.

## Licencie

Všetko vlastné. Generátor je `tools/ships/` (`meshlib.py`, `build_ships.py`). Sprity týchto štyroch lodí sú pôvodné siluety projektu, nie CC-BY. Žiadne CC-BY assety sa v tomto PR nepridávajú. Do `CREDITS.md` sa pre ne nepridáva tretia strana.

## Ako vrátiť

`git revert` commitu tejto vetvy. Mapa sa vráti na predchádzajúce sprity a náhľady. Staré kocky ostávajú v `_unused/ships_old/` (`cargo_box.glb`, `bulk_box.glb`, `merchant_box.glb`, `submarine_box.glb`) a nemažú sa.

## CI / P47_UNIT_OK

**TBD.** Tento návrh netvrdí, že testy prešli ani že je CI zelené.

## Checklist z rozpisu lode

Tvarové body kontajnera, bulk, general a ponorky patria do PR 2–5. Tu ostávajú nezaškrtnuté, lebo tento PR ich znova neoveruje a snímky chýbajú. Nižšie sú body, ktoré musia byť pravdivé práve pre mapu, sprity a hrdinskú obrazovku. Ani jeden nie je splnený týmto textom.

Čitateľnosť mapy:

- [ ] Z oddialenia ide rozoznať kontajnerovku, bulk, všeobecnú loď a ponorku podľa siluety aj farby.
- [ ] Blízka mapa kreslí model (alebo jeho LOD), nie zlatý trojuholník, keď `.glb` existuje.
- [ ] Ponorka pri ponorení ukazuje nad vodou len vežu a periskopy. Kým to v hre nie je, bod ostáva prázdny.
- [ ] Hojdanie, brázda a pena sú buď lacný shader s nameraným FPS, alebo v hre nie sú. V tomto návrhu nie sú hotové.

Vzdialené sprity:

- [ ] `assets/sprites/ships/cargo.png`, `bulk.png`, `merchant.png` a `submarine.png` zodpovedajú novým siluetám, nie starej kocke.
- [ ] Fallback `fallback_container.png`, `fallback_bulk.png`, `fallback_general.png`, `fallback_sub.png` sa kreslí len keď model chýba.
- [ ] Sprity nemajú cudzie logo ani CC-BY textúru.

Hrdinská obrazovka:

- [ ] Obrazovka modelov ukazuje LOD0 v pohľade 3/4 (alebo turntable), na svetlých kartách v štýle UI.
- [ ] Kontaktný tieň a svetlo nesmú rozbiť čitateľnosť panelu. Nie je to overené.
- [ ] Názvy lodí ostávajú slovenské a rovnaké ako v dátach.

Spoločné, stále nezaškrtnuté, lebo meranie chýba:

- [ ] Trojuholníky LOD0/1/2 sú v cieľoch zadania. Čísla sú TBD.
- [ ] Scéna so 100 loďami: FPS a draw cally pred a po sú TBD, pokles najviac 10 % nie je preukázaný.
- [ ] Save, golden, lock, bunker a logika lodí sú nedotknuté.
