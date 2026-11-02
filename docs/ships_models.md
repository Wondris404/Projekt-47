# Fáza F – modely lodí

Každý riadok je jeden vizuál. Pole `kind` v `data/ships.json` je hrubšie (military, tanker, container, bulk, general, offshore), preto viac `id` zdieľa jeden `.glb`. Súbor bez povolenej licencie alebo bez stiahnutia ostáva starý placeholder. Do gitu nejde model, ktorého licenciu nevieme prečítať.

Povolené: CC0, CC-BY, CC-BY-SA, Royalty Free s redistribúciou. Zakázané: Personal Use Only, Editorial, Non-commercial (NC) a neznáma licencia.

## Obchodné lode

| Typ | Súbor | Zdroj | Autor | Licencia | Stav |
| --- | --- | --- | --- | --- | --- |
| Nákladná / kontajnerová | `cargo.glb` | https://kenney.nl/assets/watercraft-kit (`ship-cargo-a`) | Kenney | CC0 1.0 | Použité. Sketchfab cargo-ship-loaded ostal nestiahnutý (401). |
| Ropný tanker | `tanker.glb` | https://sketchfab.com/3d-models/tanker-ship-143b1286b149487ebc0afd194afef3ae | anandeva777 | licencia v API chýba (`license` je prázdne, `isDownloadable` false) | Zamietnuté. Neznáma licencia. Placeholder. |
| Všeobecná obchodná loď | `general.glb` | https://kenney.nl/assets/watercraft-kit (`ship-small`) | Kenney | CC0 1.0 | Použité namiesto Sketchfab ship-aaa (401). |
| Plynový tanker (LNG) | `lng.glb` | ten istý trup ako tanker + 4–5 gúľ | anandeva777 | závisí od tankera | Zamietnuté spolu s tankerom. Placeholder. |
| Ťažobná loď (FPSO) | `fpso.glb` | ten istý trup ako tanker + veža | anandeva777 | závisí od tankera | Zamietnuté spolu s tankerom. FPSO nie je riadok flotily, ostáva pixelový sprite odvetvia. |
| Zásobovacia loď (PSV/AHTS) | `psv.glb` | https://kenney.nl/assets/watercraft-kit model Boat Tug (`boat-tug-a`) | Kenney | CC0 1.0 | Povolené a použité. `psv` aj `ahts` zdieľajú tento model. |

## Vojnové lode

Stránky free3d.com vracajú 403 (Datadome). Text licencie sa nedá prečítať, preto sú pôvodné free3d modely zakázané. Náhrady sú CC-BY, ale Sketchfab ich bez prihlásenia nedá stiahnuť, takže v repe nie sú.

| Typ | Súbor | Pôvodný link | Licencia pôvodu | Náhrada | Autor náhrady | Licencia náhrady | Stav |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Lietadlová loď 1 | `carrier.glb` | https://free3d.com/3d-model/essex-class-aircraft-carrier-31660.html | neznáma (403) | https://sketchfab.com/3d-models/b7394547685749ae9e1c48afe29586ab | Muhamad Mirza Arrafi | CC-BY 4.0 | Náhrada povolená, download 401. Placeholder. |
| Lietadlová loď 2 | `carrier_2.glb` | https://free3d.com/3d-model/admiral-kuznetsov-92311.html | neznáma (403) | žiadna ďalšia náhrada v zadaní | — | — | Placeholder. Nový riadok katalógu sa nepridáva. |
| Fregata | `frigate.glb` | https://free3d.com/3d-model/iver-huitfeldt-87166.html | neznáma (403) | https://sketchfab.com/3d-models/e35dab813fe34035b66ac15989b1e2be | Duane's Mind | CC-BY 4.0 | Náhrada povolená, download 401. Placeholder. |
| Fregata 2 / torpédoborec | `destroyer.glb` | https://free3d.com/3d-model/admiral-sergey-gorshkov-56966.html | neznáma (403) | https://sketchfab.com/3d-models/17be09c31c6047e4a5969b68c29eba03 | Yi Tsung Lee | CC-BY 4.0 | Náhrada povolená, download 401. Placeholder. |
| Hliadkový / raketový čln | `patrol.glb` | https://free3d.com/3d-model/project-206mr-vikhr-ifq-8840.html | neznáma (403) | https://sketchfab.com/3d-models/ca6b98e1100e4c81adefdc36d1f5af19 | 42manako | CC-BY 4.0 | Náhrada povolená, download 401. Placeholder. |
| Korveta | `corvette.glb` | https://sketchfab.com/3d-models/81e24f73ff084a05914767dc3b7774c6 | CC-BY 4.0 (42manako, Nanuchka) | — | 42manako | CC-BY 4.0 | Povolené, download 401. Placeholder. |
| Ponorka | `submarine.glb` | https://sketchfab.com/3d-models/010dd1a5ac8243b890d80b3a026d9b1d | CC-BY 4.0 (spacelynxcanfly, Typhoon) | — | Projekt-47 originál | CC0 1.0 | Sketchfab 401. V repe je originálny nízkopolygónový trup, nie Typhoon. |
| Výsadková loď | `landing.glb` | https://sketchfab.com/3d-models/2346efbaa7074b958e0e487e5e209700 | CC-BY 4.0 (42manako, Ropucha) | — | 42manako | CC-BY 4.0 | Povolené, download 401. Placeholder. |

## Čo hráč uvidí

- `psv` a `ahts`: z diaľky malý sprite zhora v `assets/sprites/ships/psv.png`, zblízka 3D `assets/models/ships/psv.glb`.
- Kenney Watercraft Kit (CC0 1.0, https://kenney.nl/assets/watercraft-kit) je znovu zapojený. Toto zadanie ho povoľuje, nielen Boat Tug:

| Súbor | id |
| --- | --- |
| `carrier.glb` | carrier |
| `landing.glb` | lhd, lpd, lst, hospital |
| `destroyer.glb` | destroyer, cruiser |
| `frigate.glb` | frigate, corvette |
| `patrol.glb` | patrol, missile, sweeper, minelayer |
| `tanker.glb` | oiler, handy_tanker, panamax_tanker, aframax, suezmax, vlcc, ulcc, mr, lr, chem_tanker |
| `lng.glb` | lng, lpg |
| `psv.glb` | psv, ahts |

- Cargo, bulk, general a ponorky majú vlastný model (nie zlatý trojuholník, ak existuje sprite aj glb):

| Súbor | id | Zdroj |
| --- | --- | --- |
| `cargo.glb` | feeder, panamax_box, neo_panamax, ulcv | Kenney `ship-cargo-a`, CC0 |
| `bulk.glb` | handy_bulk, supramax, panamax_bulk, capesize, vloc | Kenney `boat-tow-a`, CC0 |
| `general.glb` | roro, pctc, general, reefer, heavy | Kenney `ship-small`, CC0 |
| `submarine.glb` | ssn, ssbn, ssgn, ssk | originál Projekt-47, CC0 (Sketchfab Typhoon sa bez účtu nestiahol) |

Sprite zhora: `assets/sprites/ships/<kmeň>.png`. Chýbajúci súbor hru nespustí pád; `ShipSystem.model_path` vráti prázdny reťazec a mapa kreslí zlatý trojuholník.
- Civilných lodí na mape ostáva najviac 32. Vojenské sa na mape nekreslia, rovnako ako doteraz.
- Sketchfab (401 bez prihlásenia) a Free3D (403) sa nesťahovali a ostávajú zakázané.

## Linky na ručné stiahnutie

Sketchfab vyžaduje účet. Súbory patria do `C:\Users\ondre\Downloads\p47-ships\`, nie do gitu, kým nemajú potvrdenú licenciu a prevod.

- https://sketchfab.com/3d-models/cargo-ship-loaded-c14144edcd6f4827a84be12456b51e18
- https://sketchfab.com/3d-models/ship-aaa-re-upload-0d869536fb064a288df36925e207c725
- https://sketchfab.com/3d-models/b7394547685749ae9e1c48afe29586ab
- https://sketchfab.com/3d-models/e35dab813fe34035b66ac15989b1e2be
- https://sketchfab.com/3d-models/17be09c31c6047e4a5969b68c29eba03
- https://sketchfab.com/3d-models/ca6b98e1100e4c81adefdc36d1f5af19
- https://sketchfab.com/3d-models/81e24f73ff084a05914767dc3b7774c6
- https://sketchfab.com/3d-models/010dd1a5ac8243b890d80b3a026d9b1d
- https://sketchfab.com/3d-models/2346efbaa7074b958e0e487e5e209700

Tanker sa nesťahuje: https://sketchfab.com/3d-models/tanker-ship-143b1286b149487ebc0afd194afef3ae

## Stav po overení licencií

Kenney Watercraft Kit, CC0 1.0, https://kenney.nl/assets/watercraft-kit je povolený a zapojený v `data/ships.json` (pozri tabuľku vyššie). `psv.glb` ostáva Boat Tug pre `psv` a `ahts`.

Sketchfab a Free3D sa do repa nedostali:

- Tanker, LNG a FPSO zo Sketchfabu: tanker nemá licenciu (`license` prázdne, `isDownloadable` false). Namiesto nich je Kenney `tanker.glb` a `lng.glb`.
- Free3D (Essex, Kuznetsov, Huitfeldt, Gorškov, Vichr): stránka vracia 403, licencia sa nedá prečítať, preto sú zakázané. Náhradné Sketchfab modely sú CC-BY 4.0, ale download API vracia 401 bez prihlásenia, takže v repe nie sú. Namiesto nich sú Kenney trupy.
- Cargo, merchant, korveta zo Sketchfabu a ponorka Typhoon: CC-BY 4.0, download bez prihlásenia nejde (401). Korveta používa Kenney `frigate.glb`. Cargo, bulk a general používajú Kenney `cargo.glb`, `bulk.glb` a `general.glb` (CC0). Ponorka v hre je originál CC0 `submarine.glb`, nie Typhoon.
