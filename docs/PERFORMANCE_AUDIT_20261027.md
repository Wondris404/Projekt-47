# Projekt-47: výkon a audit, 27. 10. 2026

Východiskový commit: `526f79264aaa91e1a5dfd8531466af35a157dbfd`.
Opravy sú na samostatnej lokálnej vetve `codex/performance-audit-20261027`; hlavná vetva sa nemenila. Zápis na GitHub konektor odmietol chybou 403 `Resource not accessible by integration`. Preto sa dodáva patch so samostatnými commitmi; na GitHube zatiaľ nie sú. GitHub je zdrojová pracovná kópia. Google Drive a záloha `Projekt-47_BACKUP_2026-10-23_pred-opravami` sa pri tejto práci nepoužili ani nezmenili.

## Meranie a jeho hranice

Godot 4.7.2, Linux x86_64, host CPU AMD EPYC 9V74. Nejde o meranie na používateľovom Ryzen 7 7730U. Virtuálne prostredie má kolísajúci výkon. Opakované párové merania sa pripli na jeden CPU; nie je to záruka exkluzívneho prístupu k fyzickému procesoru.

Simulácia: seed 47, 165 krajín, 72 úspešne založených hráčskych firiem v 12 krajinách, zapnutí konkurenti, bez vojen, 5 zahrievacích a 100 meraných dní. Na konci 110 firiem vrátane AI. Pred/po boli samostatné procesy a rovnaký scenár, 3 opakovania. Celkový deň sa meral bez vložených funkčných časovačov. Mesačné uzávierky sú zahrnuté.

Prvé profilovanie použilo dočasnú kópiu zdrojákov s časovačmi vybraných funkcií (Time.get_ticks_usec). Jeho vnorené časy sa nesčítavajú; profilovanie samo pridáva réžiu. Prvý profil: priemer celého dňa 97,95 ms, p50 93,34 ms, p95 123,06 ms, maximum 195,63 ms.

Atlas a UI: grafický server tu nebol dostupný. Meral sa CPU čas callbackov v headless režime s dummy rendererom. `perf23` vytvoril 62 hráčskych a celkovo 92 firiem; toto nie je rovnaký scenár ako 100-dňová simulácia. Screenshot a čakanie na GPU frame sa vynechali iba v dočasnej kópii. Údaje NIE SÚ FPS ani GPU čas. V tomto prostredí nemožno potvrdiť plynulosť na Radeon grafike.

## Top 10 pred opravami

Zoradené podľa priemerného času jednej meranej operácie. Obsahujú denné, mesačné a vykresľovacie operácie; nie sú navzájom sčítateľné. Ide o prvé profilovanie, nie mediány neskorších párových behov.

| Operácia | Priemer | Interval |
|---|---:|---|
| IndustrySystem.settle | 38,11 ms | denne |
| MarketSystem.begin_day | 28,52 ms | denne |
| Atlas region, zoom 6 | 21,86 ms | prekreslenie CPU |
| MarketSystem.clear_all | 17,92 ms | denne |
| Atlas detail, zoom 20 | 14,90 ms | prekreslenie CPU |
| StockView.refresh | 12,86 ms | volanie |
| Society.monthly | 12,63 ms | mesačne, 3 vzorky |
| Atlas city, zoom 60 | 11,88 ms | prekreslenie CPU |
| main._refresh_label | 10,71 ms | volanie |
| WorldMap.atlas_infra | 9,47 ms | priemer 20 volaní vrátane prvého zostavenia |

Ďalšie denné fázy: obchodné trasy 6,00 ms, plánovanie výroby 4,94 ms. AgentSystem.monthly 1,49 ms a RivalSystem.monthly 0,45 ms na mesačné volanie. Ekonomika ich firiem je navyše zahrnutá v denných fázach. Prvý 10-dňový fázový benchmark ukázal najhorší nameraný krok 7,92 ms; tento krátky scenár nezahŕňa mesačnú uzávierku a nepreukazuje pevné dodržanie rozpočtu 9/14 ms v celej hre.

## Výsledok pred/po

Medián priemerov troch 100-dňových behov: **95.22 → 84.58 ms/deň**, o **11.2 % menej času**, približne **1.13× vyššia priepustnosť**. Rozsahy a všetky jednotlivé vzorky sú v `measurements.json`. Časy celých dní nie sú časmi jednotlivých snímok.

| Atlas CPU | Pred: medián 3 behov | Po: medián 3 behov |
| world | 20.98 ms | 23.37 ms |
| region | 24.74 ms | 16.33 ms |
| detail | 17.35 ms | 12.63 ms |
| city | 12.85 ms | 12.45 ms |

Najväčšie zlepšenie Atlasu je v regionálnom pohľade a detaile, kde sa opakuje geometria miest. Pohľad na celý svet nezrýchlil; tento limit sa nezakrýva. Geometria sa cacheuje len pri presne zhodnej polohe, mierke a priehľadnosti; pri pohybe/zoome sa môže znovu počítať. Limit 512 položiek je pevný, nie neobmedzená cache.

## Nálezy ukázané pred opravami

Riadky sú z pôvodného commitu, aby sa po úpravách neposúvali.

| Závažnosť | Miesto | Nález | Stav / postup |
|---|---|---|---|
| Vysoká | IndustrySystem.gd:558,819 | Obchodný desk mení cash, ale neúčtuje realizované tržby/nákupy do zisku a dane. | Opravené. Vráti súčty a settlement ich zaúčtuje. Reprodukcia pred opravou: 4 chybné účtovné kontroly. |
| Vysoká | IndustrySystem.gd:485–517,915 | Nákup rešpektuje power_mult, spotreba receptu nie. | Opravené cez kópiu efektívnych vstupov; zdieľaný recept sa nemení. Reprodukcia s power_mult=0,5 predtým vyrobila iba polovicu plánovaného výstupu. |
| Vysoká | GameState.gd:62,936; Empire.gd:740; Transport.gd:197; MarketSystem.gd:88 | Cache zostávajú platné po výmene sveta v rovnakom dni. | Opravené runtime revíziou sveta a resetom CPI/aktívnych trhov/sviatkových cache. Revízia sa neukladá do savu. |
| Vysoká, otvorené | IndustrySystem.gd:340–397 | Vnútorný pool počíta aj budúcu produkciu a odberateľ môže dostať viac než reálne dodané množstvo. | Bez zmeny. Treba rozhodnúť poradie/časovanie výroby a dodávok; nejde bezpečne hádať mechaniku. |
| Stredná | IndustrySystem.gd:574,1002,1040 | Údržba chýba v sumarizovaných nákladoch a rezervách. | Opravené. Náklady historického riadka sa získajú z rev−profit; funguje aj pre staré v3 riadky bez maintain. Nové riadky maintain ukladajú ako voliteľné pole. |
| Stredná, výkon | Transport.gd:147–196; Brand.gd:311 | Opakované skenovanie hráčskych firiem pre logistiku, prístavy a AI výnos. | Indexy v existujúcej životnosti transport cache a v settlemente. Bez zmeny koeficientov; porovnaný celý výsledný stav referenčného a indexovaného výpočtu. |
| Stredná | world_map.gd:1470 | Počet firiem/tratí neodhalí presun, zatvorenie ani iný svet s rovnakým počtom objektov. | Opravené porovnaním relevantnej geometrie a revízie sveta; zneplatnia sa staré priestorové indexy vedení. |
| Stredná, výkon | world_map.gd:1651–1677; atlas_draw.gd:130 | Zostavovanie rovnakých trojuholníkov miest pri opakovanom prekreslení. | Cache s limitom 512, presná kontrola vrcholov aj farieb pri opakovaní, posune, zoome a fade. Bez úpravy ikon. |
| Nízka | MarketSystem.gd:375–393 | Duplikácia clear_all a clear_chunk. | Návrh na zjednotenie, zatiaľ nezmenené. |
| Nízka | world_map.gd:567,679,1001; region_view.gd; súbory *.before_* | Historické mapové vetvy a kópie, čiastočne duplicitné helpery. | Len návrh na odstránenie/oddelenie. Nijaký súbor nebol zmazaný; pixelová mapa sa nezapla. |

## Ďalšie otvorené body

- `tests/catalog_field_lock.txt` chýba v pôvodnom GitHub commite aj v aktuálnej vetve. Existujúci test `catalog_fields_match_brief` preto zlyháva. Rovnaké zlyhanie bolo samostatne reprodukované na pôvodnom commite. Nevyrobil som nový očakávaný snapshot podľa skúšaných dát: to by zakrylo potenciálny drift katalógu. Treba doplniť schválenú referenciu pre aktuálny katalóg.
- `Society._firm_month` (pôvodne 799+) a `_crime_event` (839+) odpočítavajú mesačné benefity, nábor a škody priamo z cash; tieto položky nevstupujú do mesačného month_acc tak ako bežný settlement. Niektoré ďalšie mesačné platby majú podobný vzor. Samostatný návrh účtovného uzatvorenia, nie neohlásená zmena daní/balansu.
- `_finish_day` obsahuje mesačné uzávierky v jednom kroku; prvý profil nameral maximum 42,01 ms. Časový rozpočet sa kontroluje až po kroku. Rozdelenie tejto fázy na ďalšie snímky a kontrola na veľkom reálnom savu zostávajú otvorené.
- Svetový Atlas, náročnosť UI a zmena zoomu potrebujú grafický profil na používateľovom PC. CPU merania bez GPU nedokazujú FPS.
- Validácia vnorených rozšírení savu nie je úplný schema validator. Testy v1/v2/v3 a poškodených základných polí prešli; nie je to dôkaz odolnosti voči ľubovoľne poškodenému vnorenému JSON.
- Exaktné duplicity aktívnych helperov: EmpireView._cid / StockView._corp_id; WorldMap._draw_anim / RegionView._draw_anim; WorldMap._building_icon / RegionView._building_icon; IndustrySystem._main_recipe / Society.recipe_of. Navrhnuté na neskoršie zdieľanie, nie odstránené.
- Existujúce warnings o ObjectDB/resources pri ukončení UI/probe testov zostali zaznamenané. Nejde o dokončený audit únikov počas dlhého hrania.

## Testy a kompatibilita

- Nová sada `audit_unit`: **24 kontrol, všetky prešli**. Žiadne existujúce testy sa neodstránili; limit ~50 sa dodržal pre nové regresné kontroly.
- Existujúca veľká sada `unit`: **531 OK, 1 FAIL** (`catalog_fields_match_brief`, vyššie). Pri teste úmyselne poškodeného JSON sa očakávane vypíše parse error. Prvý pokus mal timeout 180 s; úplný beh s dlhším limitom dobehol za 269,71 s.
- Prešli fund_unit, flow_unit, goods_icons_unit, bank_audit_unit, bank_advisor_unit, sovereign_unit, employment_stats_unit, society_unit, local_comp_unit, phase_routes_unit a 365-dňová stability.
- Probe: `P47_PROBE_OK`.
- UI assertion testy descriptions/toolbar/Atlas-only/fund prešli v dočasnej headless kópii bez screenshot exportu. Nejde o vizuálnu kontrolu rozloženia alebo ikon.
- Save vytvorený pôvodným commitom po 105 dňoch sa načítal v opravenom kóde a pokračoval do dňa 108 bez chybných čísel. Formát ostal v3. Pôvodné migračné testy v1/v2 a validácie v3 prešli.
- `git diff --check` prešiel. Diff neobsahuje zmazané súbory, zmenené assety, receptové koeficienty ani herné texty. Satirické texty o orgánoch a otroctve ostali iba textami eventov.

## Spustenie

```sh
godot --headless --path . -- performance_audit
godot --headless --path . -- profile_sim
godot --headless --path . -- audit_unit
godot --headless --path . -- unit
godot --headless --path . -- phase_routes_unit
godot --headless --path . -- stability 1 30 365
```

Prvý príkaz je nový reprodukovateľný benchmark; druhý je pôvodný fázový benchmark. Na grafickom počítači možno spustiť pôvodný `godot --path . -- perf23`, ale jeho pomocné izolované volania menia stav scenára: na porovnanie sa má používať iba čerstvý testovací proces, nie rozbehnutá uložená hra.

Rozsah auditu: automatický štrukturálny prechod všetkých 53 aktívnych GDScript súborov (21 347 riadkov pred zmenami), kontrola duplicít a volaní, ručné čítanie kritických ciest ekonomiky, uloženia, cache a mapy. Nejde o dôkaz bezchybnosti každej funkcie ani o kompletné grafické QA.

## Prenos commitov do pracovného repozitára

Patch obsahuje 11 oddelených commitov a vychádza z vyššie uvedeného pôvodného commitu. V čistom pracovnom repozitári na tomto základe:

```sh
git switch -c codex/performance-audit-20261027 526f79264aaa91e1a5dfd8531466af35a157dbfd
git am /cesta/k/Projekt47-performance-audit.patch
```

Príkazy vytvoria samostatnú vetvu; nemenia hlavnú vetvu. Zápis na GitHub potrebuje spojenie s oprávnením zápisu do repozitára.
