# Projekt-47: dokončenie Atlasu, 28. 10. 2026

Vetva: `codex/atlas-completion-20261027`, základ `975ddfc` na GitHube. Autor pokračovania: Codex (GPT-6; presný variant runtime nie je sprístupnený). Predchádzajúci model nemožno určiť len z autora Git commitu. [Denník krokov a dôvodov](DEVELOPMENT_LOG_20261028.md).

## Výsledné správanie

- Oprava kamery už bola nahratá na GitHub v dvoch commitoch `08381a7`/`975ddfc`; pokračovanie ich zachováva. Otvorenie, zatvorenie a opätovné otvorenie panelu a resize zachovajú polohu sveta. Plynulý zoom po zmene layoutu je navyše testovaný. Vykreslený scenár: drift po zatvorení panelu **0 px**, po resize **0 px**.
- Kliknutie funguje aj na viditeľnej streche vysokého pixelového modelu a na jeho existujúcej ikonke. Transparentný roh modelu nie je novou plnou klikacou plochou.
- Vlaky používajú agregované vyťaženie z posledného uzavretého dňa (`used_prev/cap`). Najviac štyri súpravy na trať, dva až štyri viditeľné články podľa zoomu. Pri 50 % vyťažení sú tri vagóny plný/polovičný/prázdny. Pri 0 % nejazdia. Hustota/frekvencia rastie do vizuálneho limitu, preťaženie sa stále zobrazuje pôvodným percentom nad 100 %.
- Potrubia majú najviac 24 pulzov na viditeľnú líniu; intenzita/rýchlosť a farba ukazujú vyťaženie. Preťaženie je červené. Simulácia smer dodávok neukladá: pulzy ani vlaky nepotvrdzujú skutočný smer konkrétnej zásielky.
- Animácie sú na samostatnej vrstve pri 10 Hz, najviac 64 viditeľných aktívnych liniek, pod zoomom 4 alebo v nízkej grafike vypnuté. Pri pauze sa čas animácie zastaví. Kvôli nim sa neprekresľuje statický Atlas. Detaily dlhých tratí sa orežú na viewport a majú pevný limit.
- 62 mapových modelov: 61 odvetví z katalógu + banka. Vlastné PNG v jednotnom pixelovom štýle, generátor je v `tools/generate_map_models.py`. Textúry sa načítajú raz na typ. UI ikony sa nezmenili.
- Základný manažment umožňuje plný nákup vstupov a dopĺňanie pracovníkov bez povinnej pravej ruky. Výkon nemá pôvodnú automatickú 20 % penalizáciu. Pravá ruka zachováva plat, bonus spokojnosti a pôvodný vzorec výkonu s dolnou hranicou 1. Staré manažérske polia sa nemenia, save zostal v3. Fluktuácia z nespokojnosti/kriminality zostáva.

## Screenshoty

[Galéria 27 párov pred/po](../audit/screenshots/atlas-update/README.md): kamera, trate s 0/15/50/100/150 %, potrubia, vzdialený zoom a všetky budovy pri region/detail/city. Celkom 54 herných PNG + 27 porovnaní + 1 kontaktný list modelov; všetkých 82 PNG sa úspešne dekódovalo. Tri poškodené zdedené obrázky kamery PRED sa znovu zachytili na pôvodnom kóde `08381a7`. Ostatné porovnania PRED používajú `975ddfc`.

Zachytené cez Xvfb, Mesa llvmpipe, OpenGL Compatibility (skutočný renderer). Nejde o FPS Radeon grafiky. Mapové modely boli vizuálne skontrolované na kontaktnom liste a reprezentatívnych screenshotových stránkach; definitívna čitateľnosť všetkých modelov na monitore zostáva na používateľské posúdenie.

## Výkon simulácie

Godot **4.6.3**, Linux x86_64, virtuálny Intel Xeon Platinum 8573C. Toto prostredie sa líši od pôvodného auditu na Godot 4.7.2/EPYC aj od Ryzen 7 7730U. Páry sú samostatné procesy pripnuté na CPU 0. Počas prijatých meraní bola veľká testovacia sada pozastavená; exkluzívny fyzický CPU nie je zaručený.

Seed 47, 165 krajín, 72 založených hráčskych firiem, 110 firiem na konci, konkurenti, 5 zahrievacích + 100 meraných dní. Všetky mesačné uzávierky sú zahrnuté. Autorizovaný nový manažment mení ekonomický stav, preto nejde o porovnanie identických výsledných stavov.

| Prijatý pár | Pred ms/deň | Po ms/deň |
|---|---:|---:|
| 2 | 118,00047 | 111,29261 |
| 3 | 99,27236 | 115,05572 |
| 4 | 120,36558 | 98,76080 |
| Medián priemerov | **118,00047** | **111,29261** |

Medián klesol o **5,68 %**. Jednotlivé páry kolíšu; jeden je pomalší. V tomto scenári sa nepotvrdil pokles mediánového výkonu, nejde však o dôkaz pre každý save či pevnú hranicu snímkového času. Prvý pár prekrýval iné testy a bol vyradený, surové logy zostávajú priložené. [Všetky prijaté vzorky a metodika](../audit/verification-20261028/measurements.json).

## Overenia

- `camera_unit`: 9 úspešných kontrol.
- `atlas_update_unit`: 22 úspešných kontrol (spolu 31 nových mapových kontrol, limit ~50 dodržaný).
- `audit_unit`: 24, `society_unit`: 29, `phase_routes_unit`: 8 úspešných kontrol.
- `stability 1 30 365`: P47_STAB_OK, žiadne neplatné čísla.
- Úplná `unit`: **531 OK, 1 FAIL**, chýbajúci `tests/catalog_field_lock.txt` / `catalog_fields_match_brief`, rovnaký známy nález ako v odovzdaní. Snapshot sa nevymýšľal. Migrácie v1/v2/v3, histórie, manažérske platy, bonusy a nový základný manažment prešli.
- Tento úplný beh odhalil aj tri script errors zo zdedenej inicializácie `get_window()` mimo stromu. Guard bol opravený a tri miesta následne znovu preverené existujúcimi sekciami Juan5/Juan9 bez script errors. Samostatná regresia inicializácie tiež prešla.
- Izolovaný beh Juan5/Juan9 mal 229 úspešných kontrol a zlyhal iba na hardvérovom limite `j5_bench_ms_per_day` (147,7 ms a pri opakovaní s affinity 107,4 ms pri limite 80; pri úplnom behu vyšiel 72,3 ms a prešiel). Na pôvodnom základe v rovnakom izolovanom teste vyšiel 77,9 ms (prešiel); aj na ňom sa reprodukovali tri chyby chýbajúceho okna. Tento limit sa nezvýšil. Hostiteľské časovanie je nestabilné; párové meranie hlavného scenára je uvedené vyššie.
- Očakávaná chyba parsera pri úmyselne poškodenom JSON a warnings ObjectDB/resources pri ukončení zostávajú v surových logoch. Toto nie je audit únikov dlhého hrania.
- `git diff --check` prešiel. Žiadne zmazané súbory ani zmenené UI ikony/receptové koeficienty.

[Strojovo čitateľné kontroly](../audit/verification-20261028/checks.json) a úplné logy sú v `audit/verification-20261028/`.

## Reprodukcia

```sh
godot --headless --path . -- camera_unit
godot --headless --path . -- atlas_update_unit
godot --headless --path . -- audit_unit
godot --headless --path . -- society_unit
godot --headless --path . -- phase_routes_unit
godot --headless --path . -- stability 1 30 365
godot --headless --path . -- unit
godot --headless --path . -- performance_audit
LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -s '-screen 0 1600x1000x24' godot --path . --rendering-method gl_compatibility --rendering-driver opengl3 --audio-driver Dummy -- atlas_visual_audit after all
python tools/create_atlas_pairs.py
```

Vizuálny scenár vytvára nový pozastavený testovací svet; nesmie sa spúšťať v rozbehnutom hráčskom save. Nečíta/neukladá hráčske sloty. Skript porovnaní potrebuje Pillow. Simulačný benchmark nemá zapnutý grafický renderer.

## Kontrola na PC

Opakovane prepínať panel aj počas zoomu, meniť rozmery okna, klikať na základne/strechy/ikony budov. Pozrieť trate a potrubia pri rôznom využití, vzdialený zoom a nízku grafiku. Posúdiť všetkých 62 modelov pri troch zoomoch. Na veľkom reálnom save skontrolovať grafický profil CPU/GPU a plynulosť pri 10×. Overiť jeden starý save s najatou pravou rukou aj firmu bez nej cez mesačnú uzávierku.

Záloha `Projekt-47_BACKUP_2026-10-23_pred-opravami` ani Drive sa nepoužili. Žiadne projektové súbory sa nezmazali, pixelová mapa sa nezapla, Do main sa z tejto vetvy nezapisovalo. Súbežne zlúčený main `88849d6` bol zahrnutý do histórie pracovnej vetvy; alternatívna vlaková vetva `codex/atlas-trains-20261028` ostáva samostatná. Starší otvorený nález vnútorných výrobných dodávok, chýbajúci schválený katalógový snapshot a širší účtovný audit z predchádzajúceho reportu zostávajú otvorené.
