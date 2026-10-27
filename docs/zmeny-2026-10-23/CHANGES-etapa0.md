# CHANGES – etapa 0 (Projekt-47, work/ vs snap0/work_orig)
Godot 4.7.2.stable (oficiálny linux x86_64, /workspace/tools/godot/godot). Všetky testy: `work/tests/run_all.sh` → RESULT-etapa0.txt (0 zlyhaných krokov).
Dodávka: deliver/etapa0-changed-files.tar.gz (19 súborov, relatívne cesty). Overené: rozbalenie nad čistou kópiou originálu + run_all = OK.

## Baseline (pred zmenami, pôvodný kód; audit/BASELINE-probe.txt, BASELINE-stability.txt)
- Sonda: P47_LIVE + P47_PROBE_OK, exit 0. Výstup deterministický (2 behy rovnaký md5).
- Stabilita (seed 47, SK, sandbox, bez vojen/katastrof, štart bez pôžičky + update_rates ako request_loan): deň 1 SK pšenica ×2043, ropa ×322; deň 30 ×184/×84; deň 365 ×189/×86; globálne max ×1 098 741 (káva), min 0.005. Sadzba SK 0.047 (deň 1–30) → 0.40 (strop) od dňa 31 (deň 31: všetky krajiny 0.40), inflácia SK deň 31 = 132 (13 200 %), deň 365 = 7.3 (733 %). NaN/inf: 0. Zhoda s Miguelovým QA (×1992/×317, 0.047→0.40, infl 130) v rámci odlišnej konfigurácie (on: disasters, pôžička 180k, kaviareň).
- Prvá verzia baseline hlásila sadzbu 0 – chyba sondy (čítala len `base_rate`, ktoré vzniká až pri update_rates); opravené (fallback na `policy` + update_rates po new_game), stará verzia je BASELINE-stability.txt.old.

## Zmeny (1 riadok = 1 zmena; test = unit.gd / sonda)
1. Kupón dlhopisu – BankingSystem.gd `_match_bond_orders`: `coupon = px/100` → kupón = `_bond_yield(home)` (fallback 0.05), `face = cost` (nominál = zaplatená suma; v 1. verzii etapy 0 bolo `BOND_FACE*q`, čo bol BLOKER: bid+ask s cenou 1 a q=1000 dal nominál 100 000 € za ~1 000 € – opravené po review). `post_bond_order`: pásmo ceny 50–150 (mimo → `ok:false, reason:price_band`), odmietne NaN/inf. UI spinbox ceny (1–10000) som nemenil, lebo ho zdieľa aj emisia dlhopisu; mimo pásma sa objednávka len neprijme (správa „filled 0“). Test: bond_coupon_sane, bond_face_cash, bond_daily_coupon_small, bond_face_eq_cost_{50,100,150}, bond_gain_le_cost_yield_*, bond_band_reject_{1,10000}, bond_reject_nan (mutačne overené: so starým kódom padajú).
2. `_bond_value`: perpetuita `face*coupon/yield` → súčasná hodnota podľa `years_left` (anuita+nominál), clamp 0.55–1.45 ponechaný. Test: bond_value_years_left, bond_value_near_par.
3. GameState.from_dict → vracia String chybu; nová `validate_save` (typy všetkých kľúčov, vnútro dlhopisov: country, face>0, coupon 0–1 (pre v1 bez horného limitu kvôli migrácii), years_left≥0, prázdny/chýbajúci `player` sa odmietne, prvky polí = slovníky, NaN/inf, dátum/rozsahy, day_index, speed_index, hotovosť, `v` – odmietne >2 aj <1, chýbajúce `v` = 1). Živý stav sa pri chybe nemení (validuje sa pred prepisom). Test: reject_* (10 prípadov + NaN + poškodený súbor), live_state_untouched(2).
4. GameState `_repair_after_load`: doplní chýbajúce krajiny, kľúče krajín, trhy/komodity a centrálne banky z DataLoaderu; `date` sa po loade normalizuje na int. MarketSystem: nový `default_book`, `_book()` (tolerantný prístup, nahradil `GameState.markets[iso][cid]` na 7 miestach vrátane `_clear_one`). Test: accept_missing_countries, repaired_world, sim_after_repair.
5. RNG: `to_dict` ukladá `rng_seed`/`rng_state` (ako reťazce – uint64 by cez JSON float stratil presnosť), `from_dict` ich obnoví. Test: rng_state_restored, save_load_deterministic (save→10 dní vs load→10 dní zhodné).
6. SaveSystem: cesta `user://saves` (fallback čítania z `res://saves`), atomický zápis (`.tmp` + kontrola veľkosti + rename), limit 64 MB, `last_error`; `save_slot` vracia cestu/text (API zachované), `load_slot` vracia ""/chybu, `has_slot` aj legacy. Test: save_ok_path, save_no_tmp_left, load_ok. Pozn.: na Windows rename nad existujúcim súborom rieši engine (nie je to striktne atomické) – NEOVERENÉ na Windows.
7. GeopoliticsSystem.monthly: mazanie vojen mimo iterácie (zber → `_end_war` po cykle), `_end_war` maže podľa identity (`is_same`) nie podľa obsahu; `w.days` sa už nepripočítava +30 mesačne (zostáva +1 denne; dôsledok: šanca na koniec vojny rastie pomalšie – polovičné `days`); `id` vojny = max existujúce+1 (unikátne). Test: war_ids_unique, war_days_single_count, war_monthly_runs.
8. DataLoader.share(): krajina chýbajúca v riadku komodity už nemá 0 ponuky, ale `_gdp_share(iso)` (explicitná 0.0 v riadku zostáva 0). **Vedľajší účinok: odstránilo explóziu cien** (max ×1 098 741 → ×2.35 deň 1; SK pšenica ×2043 → ×0.27). Test: share_missing_country_nonzero + stability.
9. Mŕtvy kód: 31 funkcií označených `# DEAD: dôvod` (nič nezmazané/nepresunuté – presun by menil skripty autoloadov): BankingSystem `issue_loan, offer_for, _max_loan, set_player_bank, inject, discount_window, sell_bond, rating_label, ipo, sell_stock, apply_installment, _service_explicit_loans (prvý riadok `return`, volaná z daily()), _pull_dividend, _default`; `demand_mult` v GeopoliticsSystem aj EventSystem (duplikát, bez volajúceho); DataLoader `ingest_raw`; EconMath `lerp_f`; GameState `add_facility, dividend, inject_firm, net_worth, newspaper, _bank_in`; LawSystem `in_customs_union`; MarketSystem `adjust_price, chart`; TimeSystem `leap, is_month_start, is_year_start`; main.gd `_on_production`. Pozn.: `_bond_value` volá len `GameState.net_worth`, ktorý je tiež DEAD (komentár pri `sell_bond` opravený). `_service_explicit_loans` sa **volá** (BankingSystem.gd `daily()`, r.~17), ale jej prvý riadok je `return` – telo je nedosiahnuteľné. Nepoužitá premenná IndustrySystem ~270 neriešená (len spomenutá v audite).
10. Presun sondy: `main.gd::_probe` (≈800 riadkov) → `tests/probe.gd` (`run(host, map)`; volania UI helperov cez `host.`); main.gd len deleguje. Headless argumenty: `-- stability [dni…]`, `-- unit`; bez argumentu sonda. Výstup P47_* zhodný s baseline (diff prázdny), exit code zachovaný.
11. Testy: `tests/run_all.sh` (sonda vs golden + unit + stabilita, exit = počet zlyhaní), `tests/golden_probe.txt` (37 riadkov, deterministický), `tests/stability.gd`, `tests/unit.gd` (77 kontrol). Stabilita je deterministická (2 behy rovnaký md5); golden pre stabilitu zámerne nie je (ceny sa menia v etape 1).
12. Dokumentácia: docs/DATA.md a README.md – 16 → 26 krajín (10 placeholderov, bez `fallback:true`). `emit_boot_data.ps1`: parameter `-Force`, `Write-Guarded` – nezapíše súbor, ak obsahuje `"authored": true` alebo ak má countries.json viac krajín než skript (dnes 26 vs 16; map.json má authored:true). NEOVERENÉ: PowerShell na boxe nie je, skript nespustený ani syntakticky nezkontrolovaný.

## Zdokumentované bez opravy (etapa 1+)
- Nastavenia bez účinku (overené grepom): `set_sale_price` (`fac.sale_prices` sa len zapisuje), `set_shifts` (`fac.shifts` číta len `firm_ledger` na zobrazenie), `sign_pmc`/`cancel_pmc` (`pmc_contract` číta len `firm_ledger`), `set_trade_route` (ponuky sa mažú v `MarketSystem.begin_day`, objednávka sa neopakuje), `fac.focus` sa len píše.
- Po oprave č. 8 je cenový model stále mimo pásma: deň 365 medián cena/base 0.0–0.9 podľa komodity (textil, elektronika, autá, food_service medián 0.00), 412/572 párov krajina×komodita mimo ±30 %, max ×3.24. Dôvod: ponuka z `supply_shares` (4 komodity) vs. GDP-podiel a populácia 2× – etapa 1.
- Inflačný vstup: `_macro` počíta `realized=(index/prev-1)*12` bez limitu; skok indexu z 1.0 na ~0.3 dá −233 % (deň 31 po poistke č. 8), pôvodne +13 200 %, a sadzba padne na strop 0.40/min 0.017. Experiment (audit/EXPERIMENT-inflation-guard.txt, len v kópii /tmp, NIE vo work/): clamp `realized` na [−0.25, 0.60] drží infláciu SK deň 31 = −2.5 %, deň 365 = 9.5 %, sadzbu 0.017→0.074. Nie je „bez zmeny modelu": zmení P47_LIVE (4. pole 0.2000 → 0.4357), preto neaplikované; vhodné ako dočasná poistka v etape 1 spolu s úpravou golden.
- Štartovacia kaviareň (Miguel): od dňa 2 revenue 0, −110 €/deň – neanalyzované v etape 0, patrí do etapy 1 (ponuka/dopyt `food_service`: medián ×0.00 po 365 dňoch).
- Sonda aj unit testy píšu len do dočasného `user://test_tmp_saves` (zmazaný po teste, pozri č. 16); `work/saves` (artefakt prvej sondy) presunutý do snap0/artifacts.
- NEOVERENÉ: okno/UI (nikdy nespustené, headless nevykresľuje), Windows správanie savu a PS skriptu, GL Compatibility render, výkon.

## Revízia po review (Kai/Sam/Reese) – zmeny oproti prvej verzii etapy 0
13. **BLOKER opravený:** nominál dlhopisu z knihy = zaplatená suma (pozri č. 1) + pásmo ceny 50–150. Probe/golden bez zmeny (probe používa ceny 90/100/110). Nové unit testy (cena 1 a 10000, q 1000 → odmietnuté; 50/100/150 → face == cost, ročný zisk ≤ cost·yield).
14. `SAVE_VERSION` 1 → 2. Migrácia v1 → v2 pri načítaní (`GameState._migrate_v1_bonds`): štátne dlhopisy s kupónom > 0.25 sa prepočítajú na `_bond_yield(krajina)` (fallback 0.05); emisie hráča (`issuer: player`) a rozumné kupóny sa nemenia. Save v1 sa stále načíta (chýbajúce `v` = v1). Test: v1_migrated_coupon, v1_small_coupon_kept, v1_player_issue_kept, reject_future_version.
15. `validate_save`: kontrola vnútra dlhopisov, odmietnutie prázdneho/chýbajúceho `player`. Testy: reject_bond_*, reject_empty_player, reject_missing_player.
16. Testy a sonda už nepíšu do skutočných slotov: `SaveSystem.use_test_dir()` → `user://test_tmp_saves`, po teste `cleanup_test_dir()` (zmaže súbory aj adresár; v tomto režime sa nečíta ani `res://saves`). Opravená precedencia v `save_ok_path`. Staré sloty 5/8/9 v box `user://saves` sú zvyšky z prvého behu pred touto zmenou (nemazané).
17. Reálne aserie: `war_monthly_days_unchanged` + `war_monthly_ids_unique` (nahradili `war_monthly_runs` = true), `share_missing_country_fallback` (hodnota == `_gdp_share`) + `share_missing_case_exists` + `share_present_unchanged`.
18. `emit_boot_data.ps1`: v hlavičke upozornenie – pred `-Force` zálohovať `data/`; `-Force` prepíše 5 súborov (countries, map, supply_shares, wars, tension_seed) 16-krajinovou sadou. NEOVERENÉ (PowerShell nie je na boxe).

## Známe obmedzenia a vedľajšie účinky (doplnené po review)
- **AgentSystem.country_policy (AgentSystem.gd:161-165)** vynucuje mier pri `days >= 30`. Po oprave `days` (len +1/deň, nie +30 mesačne navyše) sa tento prah dosiahne po ~30 dňoch reálne, ale `days` rastie pomalšie než pred opravou (vtedy ≈2×), takže vojny trvajú dlhšie a šanca na koniec vojny (`0.06 + days/8000`) je nižšia. Zmena správania, nie regresia v teste.
- **K1 (nulová ponuka) len čiastočne:** `share()` dopĺňa podiel podľa HDP bez normalizácie súčtu podielov na 1 → celková ponuka je nafúknutá (ODHAD ×1.36–1.97, z Reeseinej repliky, nie meranie v hre). **K2 (populácia 2×) a V1 = etapa 1.** Medián cien je preto stále 0.00–0.81 base.
- Fallback kupónu pri chýbajúcej centrálnej banke: 0.05.
- `tests/run_all.sh` je bash (Windows: Git Bash alebo WSL; premenná `GODOT`).
- `*.import` a `*.uid` súbory nie sú v dodávke (editor ich vytvorí pri prvom otvorení projektu).
- Stabilitný test padá len na NaN/inf, nie na rozbité ceny (kritérium ±30 % je etapa 1).
- Neovplyvnené z review: UI spinbox ceny dlhopisu (1–10000) sa zdieľa s emisiou dlhopisu – pásmo sa vynucuje v logike, nie v UI.

## Doplnok po QA (Miguel) a review
19. **Hlboká validácia savu** (`validate_save`, helper `_num_ok`): čísla vo svete (každé číselné pole referenčnej krajiny z DataLoadera musí byť číslo, nie reťazec/NaN/inf; population/gdp ≥ 0), trhoch (cena > 0 a konečná; stock/last_dem/last_sup/… konečné), firmách (`cash`, `id/country/industry` string), bankách, úveroch, akciách hráča, centrálnych bankách (povinná číselná `policy`), `player.cash` v ±1e15, dlhopisoch (krajina musí existovať), dátum aj s počtom dní v mesiaci (31. 2. a 29. 2. neprestupného roka sa odmietnu). Limity sú zámerne široké (v rozbitej ekonomike sú `stock` ≈ 2·10¹⁹, ceny až ≈ 10⁶). Savy bez `v` a bez RNG sa naďalej prijímajú (legacy, RNG sa nemení). Test `_save_deep`: 11 poškodených savov (osem z Miguelovho QA + záporná cena, reťazcová inflácia a policy) zapísaných do dočasných slotov a načítaných cez `SaveSystem.load_slot` – všetky odmietnuté, živý stav nedotknutý; plus 4 akceptačné (legacy, platný, int namiesto float).
20. `main.gd` používa `load("res://tests/…")` (nie `preload`) pre sondu/stabilitu/unit, takže bez priečinka `tests/` v exporte hra naštartuje (parse error nehrozí); testy v headless režime `tests/` potrebujú. Export filter nie je v projekte nastavený – ak sa nastaví, `tests/*` môže zostať vylúčené.
21. Komentár pri `sell_bond` opravený (pozri č. 9). Poznámka: „atomický“ zápis platí striktne len na POSIX; Windows NEOVERENÉ.

## Poctivé zhodnotenie ceny/ponuky (QA Miguel, review)
- `share()` fix **nie je stabilizácia ekonomiky**: chýba normalizácia podielov na súčet 1, populácia sa v dopyte počíta 2× (MarketSystem.gd ~r.287 `qty *= product/1e6`, `product` už obsahuje `population`), súčet ponuky pri 4 komoditách (crude_oil, wheat, coal, coffee) je 1,4–2,0× svetový dopyt (ropa 1,68; pšenica 1,41; uhlie 1,42; káva 2,03; výpočet Miguela z dát). SK pšenica ×0,42 je posun zo ×186 nad base na pod base, NIE správna cena. K2 a V1 = etapa 1.
- Čísla v RESULT/BASELINE platia pre **čistý config** (bez vojen, bez katastrof, bez firiem a pôžičky), seed 47, SK. S vojnami a firmou bola SK pšenica v deň 130 ×75,6 (Miguel, iný config); inflácia je chaotická (SK deň 31 −234 %, deň 365 −17 až −20 % podľa konfigurácie), medián sadzieb 0,17–0,19 podľa konfigurácie (0,194 v Cedricovom, 0,174 v Miguelovom).

## Dodatok po re-review štábu (23. 10. 2026, verdikt Kai/Sam/Reese: GO, 0 blokerov)
Ne-blokery, nezmenené v kóde, riešiť v etape 1:
1. `bond_orders` zo savu sa nevaliduje (cena/qty) (`BankingSystem.gd:195-206`, `GameState.gd:56,708`).
2. Migračný prah kupónu 0,25 nechá v v1 savoch kupóny 5–25 %.
3. `BOND_FACE` (`BankingSystem.gd:3`) je teraz mŕtva konštanta.
4. `issue_bond` nemá horný limit kupónu, validácia save povolí max 1,0.
5. Štátny výnos je clampnutý 0,004–0,3 (`_bond_yield`), teda až 30 % ročne; strop je zámerne vysoký a patrí do ladenia v etape 1 (nález V1).
6. UI SpinBox ceny je 1–10000, pásmo je 50–150: mimo pásma ticho „filled 0“ (UX).
7. `run_all.sh` nevynucuje počet kontrol.
8. Komentár `tests/probe.gd:3` ešte hovorí o preload (kód používa `load()`).
Neoverené: UI/okno, Windows (rename pri save, PowerShell, bash pre run_all), Desktop BACKUP z boxu.

Dodatok po QA Miguela (etapa 0 = GO):
9. Chýbajúci `date` v save sa ticho nastaví na 2024-01-01.
10. Z 42 poškodených savov v QA prejde 5: doplnenie `central`/`world`/`markets` je zámer, `bond_orders` bez validácie prejde.
11. `issue_bond(10000, 1.5, 3)` cez API prejde, ale `validate_save` taký save odmietne (limit kupónu 1,0). Hra volá s kupónom 0,05, takže to nehrozí.
12. `_bond_value` volá `net_worth` aj `sell_bond` a testy (obe sú DEAD); tvrdenie „len net_worth“ v komentári a v zmene č. 9 je nepresné.
13. Párovanie vlastných bid 150 / ask 50 dáva ≈ 7,2 % ročne = štátny výnos, nie exploit.
