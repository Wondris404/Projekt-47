# Poznámky

Report staršej session: `docs/REPORT.md`. Aktuálny stav jadra: `docs/STATUS.md`. Štart: `docs/LAUNCH_STATUS.md`. Dáta: `docs/DATA.md`.

Spustenie:

`tools\godot\Godot_v4.7.2-stable_win64.exe --path C:\Users\ondre\Desktop\Projekt-47`

Headless musí skončiť `P47_PROBE_OK` a exit 0.

## Čo funguje

Banka (`request_loan`, `create_bank`, `process_monthly_interest`, `check_bankruptcy`, `update_rates`), power-law ceny, dopytové faktory, placement, deň a mesiac, eventy, AI rozhodnutie, päť panelov, save/load.

## 18. 10. 2026 — simulate_day cez mesiac

Dva headless behy Godot 4.7.2, oba exit 0, zhodné riadky, `P47_PROBE_OK`, bez `SCRIPT ERROR`. Čísla: 22 komodít, úver 250000 pri sadzbe 0.071633, dlh po prvom mesiaci 246522.7661, jedna firma, bank run 1/0.

`P47_LIVE 1.4200 243024.7752 1 0.2000 0.0300` je jeden `GameState.simulate_day` z 31. 12. 2024. Kniha `food_service` má sviatok 1.42 a `demand_product` rovný súčinu populácia × príjem × deň × počasie × sviatok × konkurencia × geopolitika. Cena knihy sedí na power-law z `last_dem` a `last_sup`. Druhá splátka zníži dlh na 243024.7752. Rezervy 0 pri vkladoch 1e6 a `reserve_ratio` 0.5 dajú `bank_run` cez denný tick. `config.shock_war` spustí `_start_war` až po `_macro`, takže inflácia ostane o 0.03 vyššia, obchod klesne o štvrtinu absolútnej hodnoty plus 1 a `infra_damage` je true. `last_invest` 0.2000 je `investment_factor` sadzby z toho dňa (strop 0.40). Financie majú `capital_add` > 0.

Zmeškaná splátka ide ďalším `simulate_day` (hotovosť −1e9, 31. 1. 2025) a volá `check_bankruptcy`.

`P47_IDS 3.1000 1.5500 2.6000` je kniha Nemecka deň po začiatku vojny. Faktory sú `conflict_demand` pre id `arms`, `chemicals` a `pmc_services`. Recept `arms_plant` vyrába `arms`, `chem_plant` vyrába `chemicals`, `pmc_unit` berie `arms` a predáva `pmc_services`. Úverový strop banky používa `reserve_ratio`, nie pevnú desatinu.

Dopytový súčin v cene delí 1e6, inak by populácia pretlačila ceny o milióny. Surový súčin je v `demand_product`.

## Ďalší krok v hre

`P47_PLAY 0.9000 0.5000`: Logistika I po jednom dni výskumu dá `freight_mult` 0.9 a tlačidlo výroby nastaví využitie na 0.5. Bankrot berie firmu s najvyšším nákladom stavby plus hotovosťou. Beh na banku každý deň vyberie 4 % vkladov. V okne sú tlačidlá „Výskum: Logistika I“ a „Výroba 50 %“. Kredit Wondris404 ostáva nad panelmi. Headless po tejto zmene: exit 0, `P47_PROBE_OK`, bez `SCRIPT ERROR`.

## Právo

`P47_LAW 5 8 0.30`: Slovensko má päť zákonov, medzinárodné právo má osem listín, nemecká sadzba dane z príjmov právnických osôb je 0.30. Panel Právo ukazuje listiny aj zákony vybranej krajiny. Rezerva banky pod Bazilej III (8 %) sa zamietne. Vývoz zbraní do krajiny vo vojne zamietne Zmluva o obchode so zbraňami. Daň firmy ide zo zákona o dani z príjmov danej krajiny.

## Mapa a pixel-art

Placeholder dlaždice 16×16 sú v `assets/sprites/` aj `assets/tilesets/`: terén, hranica, mesto, kaviareň, továreň, banka, zbrojovka, chemička a rám UI. Import má `filter=nearest` a mipmapy vypnuté. Projektový filter ostal nearest.

Svetová mapa kreslí krajiny týmito dlaždicami, každá krajina má vlastný odtieň, dlaždicu hranice na každej hrane a ikonu hlavného mesta s názvom. Región skladá zóny z tej istej terénnej dlaždice, prefarbenej podľa vybranej krajiny, a tiež ukáže hlavné mesto. Pozadie okna a linky panelov sú dlaždica UI. Hit-test sa nezmenil: vnútro Slovenska je SK, bod mimo mapy je prázdny. Dva headless behy po tejto zmene mali exit 0, zhodné riadky a `P47_PROBE_OK`. Banka a trh sa nemenili.

## Uloženie

Celý stav k tomuto bodu je v priečinku Projekt-47. Podrobný report je `docs/REPORT_DETAIL_2026-10-18.md`. Posledný snímok po tomto uložení je najnovší priečinok v `checkpoints/`. Päťminútová slučka sa nespúšťa.

## Doplnené po reporte

Každá z 16 krajín v `data/map.json` je konkávny obrys, nie štvorcový obdĺžnik. `P47_OUTLINE 9` je slovenský polygón. Bod (175, 90) leží v jeho obdĺžniku, ale mimo polygónu, a hit-test je prázdny. Stred polygónu je stále SK.

Dlaždice sú 32×32, viacfarebné. `P47_ART 3` je najmenší počet farieb na vzorke.

Panel Diplomacy vie uložiť a zrušiť sankciu voči CZ. `P47_DIPLO 0.0000 0.8500`: clo v únii je 0, po sankcii 0.85. Save slot 8 a load ju vrátia.

Sedem tlačidiel výskumu volá `start_research`. `P47_UI 7 0.75`: druhý výskum počas bežiaceho vráti chybu obsadenosti a posuvník nastaví využitie na 0.75. Sonda predtým stále overí 0.50.

Kniha dlhopisov: bid 90 proti ask 100 ostane otvorený, bid 110 sa spáruje. `P47_BOOK 1 1`. Jednorazový nákup `P47_HOLDINGS 1 1` ostal. Panel Bond book volá `post_play_bond` a vypisuje otvorené príkazy cez `open_bond_orders`. Tlačidlá sú Bid 90, Ask 100 a Bid 110.

## Mapa zo súradníc

26 krajín, `fallback` nie je true. Obrysy sú pobrežia Natural Earth 110m uložené v `data/map.json`. Slovensko má 8 krajov z Natural Earth 10m. `P47_REGION SK` je premietnutá Bratislava. `P47_WORLD 26`, `P47_OUTLINE 33`. Bod v obdĺžniku Slovenska, ale mimo polygónu, je prázdny. Región kreslí obrys vybranej krajiny. Cesty, prístavy, elektrárne, vnútroštátne regióny a poškodenie infraštruktúry sú v `data/places.json`. Vojna označí infra miesto. `tools/build_world_data.py` pri `authored: true` súbory neprepíše a skončí `DONE authored`. Zelený headless beh už nepripisuje proxy riadok do `docs/DATA.md`.

## Diplomacia

Panel Diplomacy ukáže vzťah ku každej z ostatných 25 krajín. Tlačidlá Embargo, Spojenectvo, Obchodná zmluva, Colná úľava, Vojna, Mier a Sankcia idú na krajinu zvolenú v zozname. `P47_ACT 25 0.8500 0.0000 0.0100`: embargo zdvihne clo na 0.85, spojenectvo ho zrazí na 0, colná úľava je 0.01. Vojna a mier prejdú cez `declare_war` a `make_peace`. Stará sankcia voči CZ ostáva `P47_DIPLO 0.0000 0.8500`.

`P47_STATE trade militarize 2 0.849`: krajina s nízkym rizikom obchoduje, s vysokým uvalí sankciu, vo vojne zbrojí. Vojna SK–JP prežije dva denné ticky (dni 2, intenzita rastie) a skončí mierom. Tlačidlo BR OSN zapíše svetovú udalosť `un_sanction` a clo voči cieľu je 0.85. Mesačná AI diplomacia beží len pri `ai_diplomacy`, takže staré čísla vojny sa nemenia.

## Miesta a kniha

`P47_PLACES 1 1 1 1 33`: Slovensko má cestu, prístav, elektráreň a infra miesto. Region view kreslí ten istý 33-bodový obrys. `P47_EQ 1 2`: voľná kniha akcií, ask 4 za 3 kusy ostane, bid 4 za 2 kusy sa spáruje a hráč má 2 akcie. Dlhopisy aj akcie sa zadávajú cenou a množstvom v paneloch SpinBox.

## Koniec dňa 18. 10. 2026

Uložené v Projekt-47. Posledný snímok je najnovší priečinok v `checkpoints/`. Päťminútová slučka sa nespúšťa.

Overené pred prerušením: výskumná fronta, efekty `P47_TECH 0.78 0.84 1.18 1.16 1.15 0.80 0.70`, noviny `P47_NEWS 7`, pobrežia, diplomacia, firmy, kniha a emisia. Headless sonda vtedy skončila `P47_PROBE_OK`.

Na disku, ale bez dokončenej sondy: AI firma vie založiť pobočku, presunúť výrobu a zatvoriť sa pri strate. Minister má daň, dlh, stabilitu a rating. `LawSystem.set_tax` mení daň, ktorú počíta `IndustrySystem.tax_due`. Zajtra overiť `P47_MIN` headless behom.

## Výskum a noviny

`P47_TECH 0.78 0.84 1.18 1.16 1.15 0.80 0.70` je doprava, práca, úroda, chémia, zbrane, elektrina a default banky po dokončení projektov cez denný tik. Druhý projekt ide do fronty a po skončení prvého začne. Strom kreslí čiary `logistics1→logistics2` a `auto1→arms1`. `P47_NEWS 7` sú druhy vojna, sankcia, sviatok, búrka, recesia, bankrot a výskum. Panel Počasie a sviatky číta krajinu, počasie a holiday group.

## Kupóny a emisia

`P47_ISSUE 10 1`: hráč vydá dlhopis (hotovosť stúpne) a 10 akcií firmy. `service_bonds` ide každý deň. Krátky dlhopis dostane denný kupón a pri `years_left` pod nulou sa splatí menovitá hodnota a zmizne z knihy. Vlastný dlhopis kupón vypláca, cudzí ho prijíma. Tlačidlá sú Vydať dlhopis a Vydať akcie.

## Firmy

Každé odvetvie z `industries.json` má tlačidlo Založiť. Posuvník nastaví výrobu jednej firmy a komodity. Ďalšie tlačidlá nastavia cenu predaja, druhú zmenu, PMC kontrakt a jeho zrušenie, dovoz a vývoz pšenice. Panel ukáže daň, mzdy, zmeny a sklad z `firm_ledger`. `P47_FIRM 21 9.5 2`.

## Čo chýba

Pobrežie z plného Natural Earth a stiahnutý refresh Svetovej banky. Pozri `docs/STATUS.md`.

## Past

- V Godot 4.7 nepísať `:=` na Variant.
- Python v tomto priečinku potrebuje `python -I` a `PYTHONHOME` na skutočnú inštaláciu.
- Splátka úveru je mesačná, nie denná.
- ID komodít vojny sú `arms`, `chemicals`, `pmc_services`.

Obrazovka Bond book je v _build_play: tlačidlá Bid 90, Ask 100 a Bid 110 volajú post_play_bond, ktoré volá BankingSystem.post_bond_order. _refresh_label píše bond_book_text() z open_bond_orders. Dva headless behy 18. 10. 2026 po tomto zapojení: exit 0, zhodné, P47_BOOK 1 1, P47_PROBE_OK.
