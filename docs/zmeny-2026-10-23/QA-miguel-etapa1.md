# QA etapa 1 Projekt-47, balík "v2" (Miguel, 23. 10. 2026, ~12:35 Europe/Bratislava)

Čerstvá kópia `/workspace/projekt47-qa/e1v2/` (work/ + rozbalený tarball etapy 1). Nič v `/workspace/projekt47/` som nemenil. Moje skripty: `/workspace/projekt47-qa/e1_qa_scripts/` (+ kópie v `e1v2/scripts/`). Surové výstupy: `/workspace/projekt47-qa/e1v2_*.txt`. Všetko nižšie je z tejto relácie (spustené alebo prečítané).

## BLUF
**Verdikt: GO** (pre etapu 1 ako "stabilná cenotvorba v čistom configu"). Žiadny bloker. Kritérium pásma ±30 % som nezávisle potvrdil: 572/572 pri 365/1095/2190/4380 d, medián 1,022–1,039, NaN 0, dva behy bajt-identické, 0 hlásení SCRIPT ERROR vo všetkých mojich behoch. Opravy v2 (správa Prímerie, drift `gdp_growth`, validácia nových polí, `lift_embargo`, SAVE_VERSION 3, sadzba po 2 vojnách) sú v kóde aj v meraní overené. Pumpa dlhopisov sa nevrátila. **Pred odovzdaním Juanovi však treba opraviť 3 nepresné tvrdenia v dokumentácii** (č. 1, 2, 3 nižšie) a doplniť 4 poznámky o správaní mimo čistého configu. Stabilita je stále konštrukčná (obchodný uzáver), čo CHANGES poctivo priznáva.

## 1. Obal
| Kontrola | Stav | Dôkaz |
|---|---|---|
| work/ == tar etapy 0 | **overené** | 19 súborov, `cmp` každého = work/ (bez rozdielu) |
| tar etapy 1 == work1/ | **overené** | 11 súborov, `cmp` každého = work1/; zoznam = `CHANGED-FILES-etapa1.txt` (11 riadkov) |
| sha256 tarballu | **overené** | `18d6534fdf80f5c168861db0821998069fa6e92fbad50678f17d30ddfa87416c` |
| `DIFF-etapa1.patch` na etapu 0 = work1/ | **overené** | `patch -p0` rc=0, `diff -rq` s work1/ prázdny (bez .godot/.import/.uid) |
| src/ a p47.zip == snap0/work_orig | **overené** | `diff -rq src snap0/work_orig` prázdny; po rozbalení `p47.zip` = `snap0/work_orig` |

## 2. run_all.sh (`e1v2_run_all.txt`)
- **rc=0**, „zlyhane kroky = 0“, `OK golden_probe zhodny`, **unit OK 150 / FAIL 0**, stabilita OK (d365: 0/572 mimo pásma, max 1,028 d1 → 1,149 d365), `OK kriterium pasma d365: inband_all=1.000`.
- **mktemp:** `tests/run_all.sh:17-18` `TMP=$(mktemp -d "${TMPDIR:-/tmp}/p47_run.XXXXXX")` + `trap 'rm -rf "$TMP"' EXIT`; `grep /tmp run_all.sh` = len tento riadok. Po behu v `/tmp` nezostal žiadny `p47_run.*`; staré `/tmp/p47_*.txt` (z môjho v1 behu, 11:35–11:36) sa v2 behom nezmenili → v2 do pevných /tmp nepíše.
- **golden:** `diff work/tests/golden_probe.txt work1/tests/golden_probe.txt` = presne 4 riadky (`P47_RATE 0.272500 0.038500`, `P47_CAP 250000.0000 0.091713`, `P47_MONTH_DEBT 246700.2854`, `P47_LIVE 1.4200 243375.3520 1 0.5887 0.0300`). Ostatných 33 riadkov nezmenených. Zdôvodnenie všetkých 4 je v CHANGES-etapa1.md (sekcia „Golden probe“), P47_LIVE = 0,5887 ✓. Číselne som zmeny ručne neprepočítaval.
- Testy etapy 0 (bond_band_reject, bond_face_eq_cost, bond_gain_le_cost, reject_future_version, v1_migrated_coupon, rng_state_restored, live_state_untouched, war_monthly_ids_unique…) sú v `tests/unit.gd` a prechádzajú (150/0).

## 3. Merania
**long (12 r., seed 47, čistý config, vlastný skript `qa_e1_long.gd`; `e1v2_long_seed47_a.txt`):**
| deň | v pásme | medián | min / max | NaN | sadzby (med / max) | inflácia (med / max) |
|---|---|---|---|---|---|---|
| 365 | 572/572 | 1,0222 | 0,780 / 1,149 | 0 | 0,0020 / 0,0601 | 0,0011 / 0,0106 |
| 1095 | 572/572 | 1,0328 | 0,981 / 1,155 | 0 | 0,0020 / 0,0215 | 0,0016 / 0,0028 |
| 2190 | 572/572 | 1,0309 | 1,005 / 1,143 | 0 | 0,0020 / 0,0174 | ≈0 |
| 4380 | 572/572 | 1,0385 | 1,007 / 1,140 | 0 | 0,0020 / 0,0173 | ≈0 |
Zhoda s Cedricom: medián 1,023/1,033/1,031/1,038 ✓, d365 min 0,78 ✓, d4380 min/max 1,007/1,140 ✓, d365 inflácia max 0,011 a sadzby max 0,060 ✓. **det:** druhý nezávislý beh (`_b.txt`) je bajt-identický (`cmp` aj po dobehnutí všetkých paralelných behov; 6 riadkov vrátane md5 hashu všetkých 572 cien).
**seeds 1/7/123:** výstup je **bajt-identický so seedom 47** (rovnaké hashe) – v čistom configu žiadne RNG neovplyvňuje ceny, takže iné seedy tu nenesú novú informáciu (poznámka, nie chyba). V configu `wars+disasters` (seedy 1/7/123/47) 572/572 vo všetkých 4 bodoch, d365 max sadzba 0,060–0,064, žiadne NaN.
**Dôležité obmedzenie merania (nález F4):** kontrolné body sú len 4 dni. Denné extrémy (`qa_e1_extreme.gd`, `e1v2_extreme.txt`) ukazujú, že v čistom configu je pásmo prekročené **prechodne**: max **1,332** (IN/finance, d44) a min **0,7435** (UA/finance, d259). Netýka sa to ničoho okrem komodity `finance` (cena závisí od sadzby cez `capital_demand`). Cedricovo „100 % po 1/3/6/12 r.“ platí v kontrolných dňoch, nie v každom dni.
**wars (12 r.):** v configu `wars:true` (aj `hot:true`) **nevznikne za 12 rokov ani jedna vojna** (`e1v2_wars_check.txt`: distinct_wars=0; relácie ≤ −50 nevznikajú, wars.json/tension_seed sú prázdne – už známe). Katastrofy (suchá, búrky, zima) prebiehajú. Preto som vojny **vyvolával sám** (`qa_e1_warstress.gd`: nová náhodná vojna každých 120 d, každý rok aj druhá súbežná, spolu 35–37 vojen, až 9 súbežných): NaN 0, ale pásmo klesá na **61–95 %** (d1095 452/572, d2190 439/572 a 347/572 pri seede 7, d4380 522–530/572), ceny 0,22–2,55× base, sadzby max 0,40, inflácia −0,16…+0,29 (`e1v2_warstress_seed{47,7}.txt`). Hra sa nerozbije (žiadny crash/NaN), ale „stabilná“ nie je – to Cedric ani netvrdí (NEOVERENÉ v CHANGES) a teraz je to zmerané.

## 4. Šoky a opravy
| Test | Stav | Dôkaz |
|---|---|---|
| vojna SK–CZ 120 d + 730 d po konci (`_end_war`, aj `make_peace`) | **overené** | `e1v2_shock_war.txt`, `_war_peace.txt`: počas vojny SK+CZ v pásme 0,66–0,70 (celkom 0,97; pšenica SK 1,10–1,13), po konci +730 d 572/572, `infra_damage` false, vojen 0 |
| sankcia CZ 100 d + zrušenie + 365 d | **overené** | `e1v2_shock_sanction.txt`: po 365 d 572/572 |
| embargo CZ | **overené** | `e1v2_shock_embargo.txt` + `e1v2_embargo.txt` |
| sucho SK 22 d (od d30 aj od d20), 240 d | **overené** | `e1v2_shock_drought22*.txt`, `_drought240.txt`: všetko späť v pásme |
| 2 súbežné vojny, `war2` | **overené** | `e1v2_shock_war2.txt` |
| veľká vojna US–CN 365 d | **overené** | `e1v2_shock_bigwar.txt`: počas vojny celkový pásmový podiel 0,94, min 0,55 / max 2,38; +730 d po konci 572/572 |
| (1) `_end_war` → news „Prímerie“ | **overené** | `e1v2_misc.txt`: „news 'Prímerie' nájdená: true“, aj cesta `make_peace` (news „Mier:“) |
| (2) drift `gdp_growth` pri 2 súbežných vojnách | **overené** | po 2 vojnách CZ −0,030, pen 0,030; po konci 1. vojny −0,015 (infra ostáva true), po konci 2. 0,000 a infra false. Stres 12 r.: `sum war_gdp_pen=0`; bez katastrof `max |gdp_growth − pôvodné| = 0,000000`; s katastrofami −0,010 = hodnota z `EventSystem.gd:213` (udalosť, nie vojna) |
| (a) `lift_sanction` neruší embargo, `lift_embargo` áno | **overené** | `e1v2_embargo.txt`: `impose_embargo(CZ)` blocked=true; `lift_sanction(CZ)` → „Žiadna sankcia.“, blocked=true; `lift_embargo(CZ)` → '' a blocked=false; opakované → „Nič také neplatí.“; neplatný ISO → „Neplatná krajina.“ |
| otvorenosť SK 1,000 → 0,944 (embargo CZ + sankcia DE) | **overené** | `e1v2_open.txt`; vojna SK–CZ 0,548 |
| (c) sadzba SK po 2 vojnách | **overené** | `e1v2_shock_war2.txt`: sadzba SK 0,0671 (d30) → 0,0835 (vojna) → 0,0523 (d150) → 0,0178 (d241) → 0,0020 od d332, monotónne klesá, bez skoku; v posledných 6 mesiacoch rozsah 0,000 (Cedric 0,0013 pre inú dvojicu vojen) |
| (c) INFL_DECAY 0,3 / RATE_SMOOTH 0,6, vedľajší efekt | **overené** | d365 max inflácia 0,0106 a sadzby max 0,0601 (viď tabuľka); kód `GameState.gd:44,195`, `BankingSystem.gd:653,672` |
| (d) sucho: 0,98–1,02 vs. 1,085 | **vysvetlené** | môj skript `drought22` meria pšenicu SK vrchol **1,0854 v dni 17** (od nastavenia sucha); `drought22_d20`: 1,0854 v dni 20; `drought240`: 1,096. Moje pôvodné 0,98–1,02 (v1) boli vzorky v dňoch 60–70 a neskôr, t. j. až po vrchole. Káva/mäso SK: v mojom behu vrchol 1,029/1,031 až okolo d258–262 od štartu (príčinu som nevyšetroval), Cedricove 0,993/0,991 som nereprodukoval – rozdiel môže byť v metrike (vrchol za celé obdobie vs. okno) – NEPOTVRDENÉ |
| (b) SAVE_VERSION 3 + migrácia | **overené** | `GameState.gd:40` SAVE_VERSION = 3; `_fill_e1_fields` :719, `_migrate_v2_to_v3` :740, volané z `from_dict` :789. `e1v2_savemig2.txt`: v2 (bez nových polí) → načíta, v po loade 3, dref 0.0 → po 365 d 572/572; **v1 s pumpou** (kupón 1,0) → kupóny `[0.0945, 0.2]` (štátny výnos, 0,2 pod prahom), v=3 → 572/572; idempotencia load→to_dict→load = rovnaké; **25 pokazených v3** (chýbajúce dref/cpi_hist/cpi_n/prev_rate/upd_day, cpi_hist str/NaN/<0/str prvok/61 prvkov/1e9, war_gdp_pen NaN/str/1e12, cpi_n −1/1,5, cpi_acc inf, prev_rate NaN/99, upd_day 1,5/str, dref NaN/str/1e300, v=4) = **25/25 odmietnutých**, stav nezmenený, 0 chýb. Pozn.: Cedric uvádza „7 pokazených“, testov je viac. Save z etapy 0 (`e1v2_savemig_detail.txt`): validate '' a načíta sa, po 365 d bez NaN, ale **566/572 v pásme**: 6× `finance` (CN, RU, BR, TR, IN, MX) ×0,62–0,70 (vysoké sadzby z e0 sa znížia → klesne dopyt po `finance`) |

## 5. Kód a vplyv na hru
- **Delenie nulou / NaN / hranice:** `adjust_price` (`MarketSystem.gd:192`) má `max(supply,0.001)`, `max(target,0.001)`, `is_bad → base`, clamp 0,22–6,5× base; `_cache_supply` ošetruje `tp/dw` (`dw>0`), `sup_day ≥ 0,05·dref`; `_update_capacity` ošetruje `is_bad(cur)`; `cpi_month_average` strážil `n>0`; `_normalized_shares` rieši `total<=0` (rovnomerné podiely); `_one_demand` delí `max(px,0.05)`, `max(population,1)`. V mojich behoch (4 × 12 r., 35+ vojen, hráč) 0 NaN/inf.
- **Hráč/firmy/banky/dlhopisy** (`qa_e1_player.gd`, 2 a 5 r.; `e1v2_player2y/5y.txt`): bez bankrotu, dlh klesne 180 000 → 3 723 za 5 r., firma kaviareň rastie (cash 73 594 → 359 498), **pumpa nefunguje** (`price_band` pri cene 1, qty 1000). Pri nízkych sadzbách (`e1v2_floor.txt`, d1100): štátny výnos min 0,0235, medián 0,0266, max 0,0756; úver 180 000 / 5 r. za 2,66 % (splátka 3 207 €), dlhopis (kupón 0,0266, hodnota/nominál 1,000); po 5 r. dlh 0, hotovosť 4 988 891, bez bankrotu. Hra sa nerozbije.
- **Poznámka k priebehu sadzby (hráč, 5 r.):** rateSK 0,002 (r1) → **0,0358 (r2)** → 0,002 (r3+), inflácia 0,001 → 0,0158 → 0,002: po prechode na yoy z CPI v 15. mesiaci je krátka „hrbka“ (výnos dlhopisu 0,027 → 0,060 → 0,027). Nie je to chyba, ale nemonotónnosť, ktorú CHANGES nespomína.
- **Po vojne trvá blokáda ~27 mesiacov:** `relation` zostane −85 po `_end_war`, `blocked()` (`GeopoliticsSystem.gd:214`, relation ≤ −60) vracia true, kým relácia nevyhasne (`e1v2_embargo.txt`: 27 mesiacov). Ceny sa pritom vrátia do pásma (merané). CHANGES to nespomína.
- Stabilita z konštrukcie (obchodný uzáver, φ=1) a „inflácia ~0, sadzby na podlahe od ~15.–22. mesiaca, nie je reálny inflačný proces“ sú v CHANGES priznané a mnou **zmerané** (viď tabuľka v bode 3). V d1095+ je 22–25 z 52 krajín na podlahe 0,002.

## 6. Poctivosť CHANGES-etapa1.md / RESULT-etapa1.txt
Zhodné s meraním/kódom: medián a min/max z RESULT, golden zdôvodnený a regenerovaný z nového kódu, `mktemp`, embargo/`lift_embargo`, SAVE_VERSION 3, drift gdp, otvorenosť 0,944, d365 inflácia max 0,011 a sadzby max 0,060, `_end_war` news, riadky kódu (okrem nižšie), výkon „12-ročný beh ~2 min“ (môj beh 1 min 51 s – 1 min 58 s, v paralelnom zaťažení ďalších behov).
**Nepravdivé / zavádzajúce:**
1. **CHANGES, dodatok po review: „kupóny štátnych dlhopisov ~0,4 %“** – nezmerané správne. `_bond_yield = policy + political_risk·0,35 + …` (`BankingSystem.gd:249`), clamp 0,004 je len spodná hranica. Zmeraný výnos pri sadzbách na podlahe: **min 2,35 %, medián 2,66 %** (`e1v2_floor.txt`). Oprava: „~2,4–2,7 %, dolná hranica 0,4 % sa nedosiahne“.
2. **RESULT-etapa1.txt, prvý odsek „Sadzby: d365 med 0.121 (max 0.40 …)“** je zastaralý (stav pred INFL_DECAY): aktuálne d365 med 0,0020, max 0,0601. Neskoršie odseky „po úprave“ ho opravujú, ale súbor si protirečí. Podobne „počas vojny pásmo SK 0.64“ je staršie číslo (moje: SK+CZ 0,66–0,70, iná metrika). Oprava: zjednotiť, resp. označiť prvý odsek ako historický.
3. **CHANGES „7 pokazených v3“** v dodatku (b) – overil som 25 prípadov (všetky odmietnuté); číslo je nižšie než skutočnosť (nie je to chyba, len nepresnosť). A **bod 5 v pôvodnom dodatku („100 % po 1/3/6/12 r.“)** platí len pre 4 kontrolné dni (viď F4: prechodne 1,33× a 0,74×, komodita `finance`).
Drobné: staré čísla riadkov v CHANGES (`validate_save GameState.gd:598` → v kóde dref na :618; `_macro` :172 vs. :174; DataLoader `share` 163 vs. 166) – cosmetic.

## 7. Nálezy – súhrn
| # | Závažnosť | Nález |
|---|---|---|
| F1 | stredná (doc) | „kupóny ~0,4 %“ je nepravda; skutočné 2,4–2,7 % |
| F2 | nízka (doc) | RESULT obsahuje zastarané čísla (sadzby d365, pásmo SK počas vojny) |
| F3 | nízka (doc) | „7 pokazených v3“ vs. 25 overených |
| F4 | nízka | pásmo ±30 % sa prechodne prekročí (finance: 1,332 d44, 0,7435 d259); platí len v kontrolných dňoch |
| F5 | informatívna | seed v čistom configu nemá vplyv (seeds 1/7/123 identické); `wars:true` nevytvorí vojny (prázdne dáta) |
| F6 | informatívna | pri hustých vojnách (stres, až 9 súbežných) pásmo 61–95 %, ceny 0,22–2,55× – stabilita je len pre čistý config |
| F7 | nízka | save z etapy 0: 6 pároch `finance` mimo pásma po 365 d (pomalá úprava) |
| F8 | nízka | po vojne blokáda ~27 mesiacov (relation −85 sa nerieši v `_end_war`); sadzba SK v 2. roku mierne stúpne (0,002 → 0,036 → 0,002) |

## NEOVERENÉ
UI/okno (SpinBox, panely sankcií/embargo), Windows, PowerShell, výkon (merané len hrubo, v paralelnom zaťažení), GL render, hráčove firmy dlhšie než 5 r., ručný prepočet 4 golden hodnôt, realizmus čísel (inflačný proces neexistuje), dlhodobé vojny vyvolané len cez UI (mojich 35–37 vojen bolo vyvolaných skriptom).
