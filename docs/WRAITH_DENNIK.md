# WRAITH DENNÍK

## AKTUÁLNY STAV

Audit 2. Posledný krok: A2-K0b scroll pravého panelu. Posuvník je stále viditeľný a pri prepnutí záložky sa obsah vráti hore.
Checkpoint pred krokom: `20261024-195653`.
Ďalej: A2-K0c.
V strome už sú menu a tutoriál, ale K4 a K0e ešte nie sú hotové. Golden hash `225646A676F7A7A096ABBF779BD684FEE59479ACAF6240C8B85AE1222B838991` nezmenený.

Milník: M1/M2 oprava okna je v kóde a na snímke. M0 je zelené.
VOLBA_1_VIZUAL = A (Factorio-like). VOLBA_2_KRAJINY = VSETKY. VOLBA_3_TEMPLATES = ____ (nevyplnená). VOLBA_4_AI_SUPERI = ANO.
Úlohy [ZÁVISÍ OD VOLBA_1] sú odblokované. M4b ešte nie je začaté. Pri M4b platí variant A z promptu a z feature_research.md sekcie 1.15.
Posledný krok: mapa kreslí farebné krajiny, panely sú tmavé (#2B2B2B, text #F2F2F2), pásy špendlíkov sú preč, top bar má dátum, hotovosť a čas, tlačidlá Založiť sú v ScrollContainer po kategóriách.
Snímky: `audit\M1-ui-before.png`, `audit\M1-ui-after.png`.
Headless po oprave: sonda exit 0, `P47_LIVE 1.4200 243375.3520 1 0.5887 0.0300`, `P47_PROBE_OK`, golden zhoda. Unit pred touto UI úpravou 153/0. Celý `run_all` po UI úprave ešte nespustený.
10 minút max rýchlosť: 15:20:51–15:30:52, zastavené po 600 s wall time, 0× SCRIPT ERROR, 0× Parse Error, posledný `P47_RUN day 9240` v `audit\M1-10min.log`. Ďalšie behy Godot len headless alebo skryté okno, nie do popredia.
Checkpoint: `20261024-153638` files=143 robocopy=1.
Ďalej: M2 zvyšok (Save/Load). Katalóg T01–T70, focus stromy a F1–F13 sú v data a loade. Golden a save formát sa nemenili. Godot okno sa nespúšťa.

### 2026-10-24 15:50 — katalóg 1950–2026
Súbory: `data\tech_catalog.json`, `data\focus_trees.json`, `data\forecasts.json`, `scripts\autoload\DataLoader.gd` (`history_catalog_errors`), `tests\unit.gd` (`_history_catalog`). `data\research.json` nezmenený. Logistika I po 28 dňoch stále `freight_mult` 0.9.
Headless: unit dvakrát exit 0, 0× `P47_UNIT_FAIL`. Dve sondy exit 0, `P47_PROBE_OK`, golden zhoda. Bez okna.
F1–F13 majú pole `name` (uzol/udalosť), napr. F3 „AI na úrovni človeka (HLMI)“. Unit to číta cez `DataLoader.forecast_by_id`.
Checkpoint pred zápisom: `20261024-154216`.

## ZÁPISY

### 2026-10-24 20:15 — A2-K0b scroll panelu
Súbory: `scripts\main.gd` `_tab` (posuvník vždy viditeľný, follow_focus vypnutý), `_reset_tab_scroll` pri zmene záložky, pravý panel min. šírka 300 a pomer 1.0 namiesto pevného splitu. Headless vetva `-- uitest` vypisuje `P47_UI_FIT` a `P47_UI_SCROLL`.
Headless: import 0, PROBE_OK áno, unit OK=183 FAIL=0, STAB_OK áno, STAB_NAN 0, run_all fails=0, golden hash zhodný áno. uitest: FIT 0 pri 1.0, 1.25 a 1.5; všetkých 6 záložiek `P47_UI_SCROLL … ok`.
Ručne (Ondrej): NEOVERENÉ.
Checkpoint: `20261024-195653`. Ďalej: A2-K0c.

#### PRE ONDREJA – A2-K0b
Čo sa zmenilo: Pravý panel má stále viditeľný posuvník. Keď prepneš záložku, zoznam začína znova hore, nie v polovici.
Ako to vyskúšať: Spusti hru, Nová hra, Štart. Otvor záložku Firma a kolieskom zíď až po výskum. Potom klikni na Založiť a znova na Firma.
Čo uvidíš: Posuvník vpravo a po návrate na záložku znova vrch zoznamu. Nič by nemalo byť odrezané mimo okna.
Čo ešte nefunguje: nič známe z tohto kroku. Tutoriál a menu ešte nie sú dokončené podľa neskorších krokov.

### 2026-10-24 18:33 — A2 baseline
Súbory: žiadna zmena. Checkpoint `20261024-182706`.
Headless: import 0, PROBE_OK áno, unit OK=183 FAIL=0, STAB_OK áno, STAB_NAN 0, run_all fails=0, golden hash zhodný áno.
Ručne (Ondrej): NEOVERENÉ.
Ďalej: A2-K0a.

### 2026-10-24 18:39 — A2-K0a zoom
Súbory: `scripts\main.gd` `_on_zoom` skrýva svetovú mapu, keď je región, a naopak. `scripts\ui\world_map.gd` a `scripts\ui\region_view.gd` `_ready` nastavujú `clip_contents`, aby zoom kolieskom nekreslil cez nadpis. `tests\unit.gd` `_zoom_exclusive` kontroluje, že po jednom prepnutí je viditeľná len regionálna mapa a po druhom len svet.
Headless: import 0, PROBE_OK áno, unit OK=184 FAIL=0, STAB_OK áno, STAB_NAN 0, run_all fails=0, golden hash zhodný áno.
Ručne (Ondrej): NEOVERENÉ. Svet/Región má prepínať mapy a koliesko nemá kresliť mimo rámu.
Checkpoint: `20261024-182706`. Ďalej: A2-K0b.

### 2026-10-24 14:04 — M0
Súbory: `tests\run_all.ps1:1-24` (runner, neskôr riadok 22 InvariantCulture), `docs\PERF.md`, `docs\zmeny-2026-10-24\CHANGES-M0.md`, `docs\zmeny-2026-10-24\REPORT-M0.md`.
Headless: import 0, `P47_LIVE 1.4200 243375.3520 1 0.5887 0.0300`, golden zhoda 37 riadkov, unit 150/0, inband_all 1.000, determinizmus OK, `VYSLEDOK fails=0`.
Wall time run_all: 432.801 s, potom 2348.389 s a 442.475 s.
Checkpointy: prvý `20261024-134531`, posledný M0 `20261024-145436`.
Ďalej: M1.

### 2026-10-24 15:11 — M1 kód
Súbory: `scripts\autoload\LawSystem.gd` minister_sheet (sadzba, CPI, inflácia, nezamestnanosť, zákony, vojny, sankcie, počet AI firiem; staré kľúče tax/debt/stability/rating ostali). `scripts\main.gd` panel ministra, F3 FPS, argument `maxspeed`. `tests\probe.gd` nový riadok `P47_MIN_DATA` (starý `P47_MIN` nezmenený). `tests\run_all.ps1` vynechá `P47_MIN_DATA` z golden porovnania. `tests\unit.gd` tri testy. `tools\checkpoint.ps1` odmietne plochu a zálohu, prepínač `-RotationTest`. `checkpoint.ps1` v koreni len volá tools skript.
Spawn AI firiem som nemenil (zmenil by golden). Save formát som nemenil.
Headless unit: exit 0, OK=153 FAIL=0. `ai_firm_spawn_deterministic 28`, `ai_firms_in_save_roundtrip`, `minister_data_not_nan`. `ROTATION_OK keep=12` exit 0.
`run_all` po tejto zmene: zatiaľ nespustené. Okno: nespustené.
Checkpoint: `20261024-151150`.
Ďalej: run_all, potom okno.

### 2026-10-24 15:19 — M1 headless po kóde
`run_all.ps1`: wall 433.534 s, exit 0, import 0, golden OK, unit 153/0, inband_all 1.000, `VYSLEDOK fails=0`. `P47_MIN 90.00 190.00` nezmenený.
Ďalej: okno.

### 2026-10-24 15:20 — M1 okno, prerušené
Krátky beh: 0× SCRIPT ERROR, 0× Parse Error, `P47_RUN` deň 30…270.
10 minút max rýchlosť: start 15:20:51, stop po 600 s o 15:30:52, 0× SCRIPT ERROR, 0× Parse Error, posledný riadok `P47_RUN day 9240`.
Ďalej: oprava mapy a UI.

### 2026-10-24 15:36 — M1/M2 vzhľad okna, VOLBA_1 = A
Rozhodnutie: VOLBA_1_VIZUAL = A (Factorio-like).
Súbory: `scripts\ui\world_map.gd` krajiny cez `draw_colored_polygon` (predtým tmavá dlaždica `terrain.png` na mori `#101820`, preto čierna plocha); preč sú špendlíky `border.png` na hranách. `scripts\main.gd` bez dlaždice `ui_chrome.png` a `border.png` (to boli pásy špendlíkov), téma panela `#2B2B2B` a text `#F2F2F2` (kontrast nad 4.5:1), top bar dátum / hotovosť / Pauza / 1 / 2 / 3 / +1 deň, ScrollContainer „Založiť“ s kategóriami Poľnohospodárstvo, Ťažba, Priemysel, Služby.
Snímky: `audit\M1-ui-before.png` (čierna mapa, béžové pásy, orezaný text), `audit\M1-ui-after.png` (farebná mapa, tmavé panely, top bar, kategórie).
Headless: sonda exit 0, golden zhoda, `P47_PROBE_OK`.
Checkpoint: `20261024-153638`.
Ďalej: M2 zvyšok a `run_all`.

### 2026-10-24 22:10 — JUAN-FIX (touchpad, mapa, zoom, Pokračovať, ukladanie, dividendy K0c4)
Robil Juan na kópii v boxe (nie Wraith). Zálohy: `*.orig_juan` (touchpad/mapa), `*.orig_juan2` (zvyšok).
Súbory:
- `scripts\main.gd` `_input`: touchpad (InputEventPanGesture), koliesko, PageUp/PageDown a šípky posúvajú aktívny pravý panel.
- `scripts\ui\world_map.gd`: ťahanie mapy ľavým tlačidlom (krátky klik = výber krajiny), `_zoom_at` zoom k miestu pod kurzorom.
- `scripts\ui\main_menu.gd`: Pokračovať bolo vypnuté, kým neexistoval save, a save sa nedal nikde vytvoriť. Teraz počas hry pokračuje v hre, inak načíta posledný slot. Nové tlačidlo „Uložiť hru“ (slot 1), „Načítať hru“ s obnovou stavu slotov.
- `scripts\main.gd`: `save_game()`, F5 a Ctrl+S = rýchle uloženie do slotu 1, hláška „Hra uložená“. Esc v menu = späť do hry s pôvodným stavom pauzy. Panel „Moje firmy“ (všetky firmy: krajina, tržby, náklady, zisk za 30 dní, hotovosť, rezerva, posledná dividenda). Hláška po založení s menom firmy. Toast „Dividendy z tvojich firiem: +X €“.
- `scripts\autoload\IndustrySystem.gd`: `pay_dividends()`, `firm_reserve()` (EMA nákladov × 30 dní), `firm_period_profit()`, `firm_summary()`, signál `dividends_paid`. Stratová firma nevypláca nič.
- `scripts\autoload\BankingSystem.gd`: `_pull_dividend(need, from_firm)` už nie je DEAD, prevod firma → hráč + správa „Dividenda z <firma>: +X €“.
- `scripts\autoload\GameState.gd`: volanie `IndustrySystem.pay_dividends()` v mesačnej vetve hneď za `_macro()`. Nové voliteľné kľúče firmy `last_div_day`, `last_dividend` (save `v:3` sa nemení).
- `tests\unit.gd`: `_juan2_dividends`, `_juan2_save_load` (8 testov).
Headless: unit OK=191 FAIL=0, `P47_DIVIDEND d30=4036200 d60=4198308 paid=162108`, STAB_OK áno, uitest FIT 0/0/0, SCROLL 6× ok, CLICK 4× ok. Golden: FAIL už na nedotknutej verzii (riadok `P47_MIN_DATA` navyše, prostredie / run_all.sh ho nefiltruje), diff po zmenách identický → zmeny golden nezmenili.
Ručne (Ondrej): NEOVERENÉ.
PRE ONDREJA: Esc → Uložiť hru (alebo F5 / Ctrl+S) → hláška „Hra uložená“. Pokračovať ťa vráti do hry. Založ firmu, pusti čas cez 1. deň mesiaca → v správach „Dividenda z …“ a hotovosť ti narastie. Záložka Firma → MOJE FIRMY ukáže všetky tvoje firmy.

## JUAN-FIX 3 (2026-10-24): Postaviť tu, úvery banky, detail firmy, pravá ruka
Zmenené: scripts/autoload/IndustrySystem.gd, BankingSystem.gd, GameState.gd, scripts/main.gd, scripts/ui/world_map.gd, nové scripts/ui/firm_chart.gd, tests/unit.gd. Zálohy *.orig_juan3. SAVE_VERSION ostáva 3 (nové kľúče sú voliteľné: firm.pos, month_hist, month_acc, manager, workers; bank.pos, cons_rate, cons_loans, cons_stats).
Čísla: Kaviareň 80 000 € + 17 600 € kapitál, Kancelária (finance_office) 220 000 € + 48 400 €, Banka 500 000 € licencia. Úvery ľuďom: 36 mesiacov, anuita, mesačne max 50 % voľnej likvidity, default ~0,2–0,5 %/mes. Bez pravej ruky: efektivita 80 %, dokúpi 50 % materiálu, odíde 5 % ľudí/mes. S pravou rukou: efektivita 90 % + 30 % × schopnosť, plat = náklad.
Testy: unit 218 OK / 0 FAIL, uitest P47_UI_PLACE placed=1 icon_click=1, P47_UI_DETAIL open=1 manager=1, stabilita OK; golden_probe padá ako predtým (riadok P47_MIN_DATA).

PRE ONDREJA:
1. Klikni na krajinu, choď do záložky Založiť, hore v POSTAVIŤ NA MAPE vyber Kaviareň, Kanceláriu alebo Banku a stlač „Postaviť tu“.
2. Klikni na miesto vnútri tej krajiny. Na tom mieste sa objaví ikona (tvoje majú rámik). Esc stavbu zruší.
3. Klikni na ikonu na mape alebo na „Detail: …“ v záložke Firma. Otvorí sa okno s grafom (tržby, náklady, zisk po mesiacoch, ukáže sa po prvom celom mesiaci), čo firma musí kúpiť, ľudia, mzdy, rezerva, dividendy.
4. V detaile daj „Najať pravú ruku“ (3 kandidáti so schopnosťou a platom). Bez nej firma ide horšie a ľudia odchádzajú. Dá sa aj prepustiť.
5. Banka: v záložke Trh & banky nastav „Úrok pre ľudí“. Každého 1. v mesiaci banka sama požičia ľuďom a vidíš požičané, splátky, úroky a defaulty. Vyšší úrok = menej záujemcov, viac defaultov.

## JUAN-FIX 4 (2026-10-24 noc): banka, menu s módmi, postava, intro, terén, mestá, politika, AI konkurencia, ciele, PMC
Robil Juan na kópii v boxe. Zálohy `*.orig_juan4`. SAVE_VERSION ostáva 3: nové kľúče sú voliteľné (`ext` = politika/ciele/konkurenti, `player.nick/gender/charm_discount/gender_action_day`, banka `sav_rate, savings, mort_rate, corp_rate, mort_loans, corp_loans, reserve_target, prod_stats, month_hist, recovered_total, written_off`, `config.difficulty/politics/rivals`). Starý save sa načíta a doplní defaulty (test j4_old_save_no_ext, j4_bank_save).
Nové súbory: scripts/autoload/Difficulty.gd, TerrainSystem.gd, PoliticsSystem.gd, RivalSystem.gd, BankProducts.gd, scripts/ui/intro_scene.gd, assets/intro/s1..s4_m|f.png, data/cities.json, tests/juan4.gd, data/countries_extra_juan4.json + data/map_extra_juan4.json (pripravené, nenačítané).
Obtiažnosť (Difficulty.gd): Easy štart 400 000 €, ceny ×0,80, udalosti ×0,5 (sila ×0,6), AI ×0,6, úroky −1 p.b., bez vojen | Tutoriál 200 000 €, ×0,90, ×0,5/0,7, AI ×0,7, −0,5 p.b. | Medium 150 000 €, všetko ×1 | Hard 50 000 €, ×1,25, ×1,6/1,4, AI ×1,5, +1,5 p.b. | Realistic 0 €, ×1,10, ×1,3/1,2, AI ×1,3, +1 p.b.
Krajiny: 26 → ostáva 26 v hre. Vygenerovaných 139 ďalších (Natural Earth + geonames), ale simulácia so 165 krajinami trvá 277 ms/deň oproti 25 ms/deň (11× pomalšie, rýchlosť 3 by nešla). Dáta sú v *_extra_juan4.json, treba najprv zrýchliť MarketSystem.trade_routes. Kosovo a Taiwan vynechané (otvorené rozhodnutie).

PRE ONDREJA:
1. Menu: hore sú módy Easy, Tutoriál, Medium, Hard, Realistic, Story. Story napíše „Na tomto sa pracuje — wondris404“. Ostatné otvoria nastavenie: prezývka, pohlavie (tooltip ukáže bonusy), krajina, seed, štartovací balík. Tutoriál = 10 krokov ako predtým.
2. Intro: po Štart ide 4-scénové intro (vyhodenie, rozchod, prísaha, jachta). Medzerník = ďalej, Esc alebo klik = preskočiť. Žena má partnera a mužov na jachte, muž partnerku a ženy.
3. Pohlavie: muž = mzdy −5 %, akcia Kampaň pre ženy (+5 reputácia, 70 %). Žena = Očariť pri vyjednávaní (ďalšia stavba −8 %, 60 %) a +5 % tržieb kaviarní a spotrebných firiem. Akcie sú v záložke Politika, raz za 90 dní. Iné = bez bonusov.
4. Banka: postav ju v meste, klikni na ikonu alebo Firma → „Detail: Banka …“. Uvidíš bilanciu, kapitálovú primeranosť (min 8 %, pod ňou sa zastavia nové úvery), produkty (spotrebiteľské, hypotéky, firemné, sporiace účty, bežné vklady), graf bilancie a graf rizika nesplácania. Nastav úroky aj cieľ rezerv a daj „Uložiť nastavenia banky“.
5. PMC vymáhanie: postav PMC (Založiť → PMC) do 300 km od banky, splň cieľ „Kontakty v miestnej vláde“ (Ciele) a v Politike daj „Úplatok ministrovi“ v tej krajine. Potom v detaile banky „Poslať PMC na nesplácačov“: vymôže 30–60 % nesplatených dlhov, stojí 15 000 € + 5 %, 20 % riziko škandálu (reputácia −15).
6. Terén: tlačidlo „Terén / suroviny“ pod mapou. Bane a vrty len na náleziskách (farebné kolieska) mimo miest, kaviareň/kancelária/banka len v meste (oranžové kruhy). Pri „Postaviť tu“ blikajú platné miesta.
7. Mesto: Svet / Región, klikni na mesto → panel s obyvateľmi, ekonomikou, budovami, tvojimi firmami a voľnými parcelami.
8. Vojna: tlačidlo Vojna zmizlo. Vojny vedú štáty, ty môžeš lobovať za mier alebo konflikt (Politika).
9. Politika: vláda, strana, dane, regulácia, voľby. Lobing a úplatky stoja peniaze, majú šancu a riziko škandálu.
10. Ciele: strom so 4 vetvami (Lobing, Médiá, Financie, Priemysel). Naraz beží jeden cieľ, každý trvá dni a dá trvalý bonus.
11. Konkurencia: AI firmy (Danubia Holding a spol.) zakladajú firmy, aj v tvojom odvetví, a pri cenovej vojne pridávajú výrobu. Podiel na trhu je v Politike dole.
12. Ciele postavy (vetva Postava, vidíš len svoje): muž – Old boys club (lobing a úplatky −8 % cena, riziko škandálu ×0,92), Tvrdý vyjednávač (úvery −0,6 p.b.); žena – Sieť žien v biznise (pravá ruka −8 % plat), Mediálna ikona (reputácia +1 mesačne, kampane účinnejšie). Každý 40 dní, tooltip ukáže bonus.
13. Strom cieľov (upresnené): záložka Ciele = posuvný strom s ikonami a čiarami (oranžová = splnená prerekvizita, červené ✕ = vylučujú sa), progress bar aktívneho cieľa, tooltip s efektom, trvaním, prerekvizitami. Vetvy Ekonomika, Politika, Podsvetie, Pohlavie (len tvoje). Trvanie 35–70 dní. Podsvetie: „Čistý podnikateľ“ (+5 reputácia, menej škandálov) VS „Korupcia a podsvetie“ (odomkne úplatky) → „Kontakty v miestnej vláde“ (odomkne PMC vymáhanie) → „Bezpečnostné kontakty“ (PMC +10 %). Úplatok ministrovi bez cieľa Korupcia nejde. Uložené v save (ext.focus).

## #14 JUAN-FIX 5 (2026-10-24 noc): všetkých 165 krajín + úrovňová simulácia (tiered LOD)
Robil Juan na kópii v boxe. Zálohy `*.orig_juan4`. SAVE_VERSION ostáva 3.
- DataLoader načíta aj `countries_extra_juan4.json` + `map_extra_juan4.json` → 165 krajín (TW/XK v dátach nie sú). Argument `-- core26` vráti pôvodných 26 (porovnanie so zlatým výstupom sondy: zhodný okrem známeho riadku P47_MIN_DATA).
- MarketSystem: tier 1 = top 70 ekonomík podľa HDP (`TIER1_TOP`) + pôvodných 26 + krajina hráča, vybraná krajina, krajiny s jeho firmami/bankou, krajiny vo vojne → plný denný trh. Tier 2 = ostatné (~95): prepočet raz za 7 dní, rozložený round-robin (1/7 denne), cena/zásoba/kapacita dobehnú 7 krokov naraz, CPI váha 7. Povýšenie je automatické každý deň (`refresh_tiers`). Po načítaní/novej hre prvý deň prepočíta všetko naplno.
- Optimalizácie bez zmeny výsledku: `_openness` už nie je O(n²) cez blocked() (len reálne blokované dvojice), denná cache počtu firiem a vojen, rýchly výpočet dopytu a ponuky (kontext krajiny raz za deň, ramadán raz za deň, polia namiesto string kľúčov), CPI váhy cache.
- Mapa: polygóny nových krajín so samoprienikom sa opravia (Clipper), všetkých 165 sa kreslí a dá sa kliknúť (test j5_map_clickable).
- Starý save s 26 krajinami: doplnia sa chýbajúce krajiny s rovnovážnym trhom (`init_country_books`) a centrálnou bankou, politika sa doplní.
- Výkon (box, 30 dní, headless): pred 165 krajín 272–277 ms/deň, 26 krajín 25 ms/deň → po 165 krajín ~31–35 ms/deň (cieľ ≤ 40 splnený s top 70), 26 krajín ~14–19 ms/deň. Rýchlosť 3 (24 dní/s) ≈ 0,8 s CPU za sekundu – hrateľné ako predtým s 26.
- Testy: tests/juan5.gd (benchmark, povýšenie tieru firmou aj vojnou, tier 2 sa hýbe bez NaN, starý save 26 krajín).

PRE ONDREJA:
1. V hre je všetkých 165 krajín. Mapa ich všetky kreslí a dajú sa kliknúť.
2. 70 najväčších ekonomík (plus tvoja krajina, krajiny s tvojimi firmami a krajiny vo vojne) sa počíta každý deň naplno. Malé krajiny sa počítajú raz za týždeň zjednodušene – keď tam niečo postavíš, hneď sa prepnú na plný výpočet. V Politike vidíš „tier 1/2“.
3. Rýchlosť 3 ide zhruba ako predtým s 26 krajinami.
4. Staré savy sa načítajú, chýbajúce krajiny sa doplnia.

## #15 JUAN-FIX 5: politika všetkých krajín (vlády, strany, lídri – paródie)
- data/politics_juan5.json (generátor /workspace/projekt47/work5/gen_pol.py): 165 krajín, typ vlády (demokracia 64, hybridný 39, autoritársky 48, monarchia 9, komunistický 5; zjednodušene podľa kategórií EIU), vládnuca strana, 2–4 strany (ideológia, popularita, `leader_name`), `leader_name` krajiny = satirické skomolené mená (napr. Donny Trumpeta, Vlado Putinko, Si Pingpong), malé krajiny generické vtipné mená.
- Typ vlády: cena úplatku (demokracia ×1,5 … autoritársky ×0,8), riziko škandálu, šanca, základná regulácia, voľby len demokracia (48 mes.) a hybridný (60 mes.). Voľby berú strany krajiny a ich popularitu.
- Nové akcie (záložka Politika, pre vybranú krajinu): Financovať stranu (popularita +6 % × účinnosť: demokracia 1, hybrid 0,7, autoritársky 0,35, monarchia 0,3, komunisti 0,25), Podporiť krajinu vo vojne (vzťahy +20 / s nepriateľmi −15, príjem z dodávok tvojich zbrojných/chemických/logistických/farma firiem, PMC kontrakt ak máš PMC, reputácia −2), Lobing za sankcie / za obchodnú dohodu (cieľ = výber krajiny), Štrajk (regulácia −5, podpora vlády −10 %, vysoké riziko škandálu). Všetko má cenu, šancu a škandál.
- Tier 2 krajiny: politika sa prepočíta raz za 3 mesiace. Starý save: strany a lídri sa doplnia (`_fill_juan5`).
- Upravený test j4_election (víťaz = prvá strana zoznamu krajiny).

PRE ONDREJA:
1. Každá krajina má typ vlády, lídra s vtipným menom a 2–4 strany s popularitou (Politika → text hore).
2. V autoritárskych režimoch sú úplatky lacnejšie a menej riskantné, voľby nie sú a financovanie strán skoro nefunguje.
3. Nové tlačidlá: Financovať stranu (vyber stranu), Podporiť krajinu vo vojne, Sankcie / Obchodná dohoda (vyber cieľovú krajinu), Štrajk.

## #16 JUAN-FIX 5: strom výskumu (oddelený od cieľov)
- data/research.json: pôvodných 8 uzlov ostáva (rovnaké id, cena, efekty) + 13 nových, 6 vetiev: Stroje a automatizácia, Ťažba a suroviny, Energetika, Logistika, Financie/IT, Spotrebné produkty (x/y pozícia, prerekvizity).
- Nové efekty: yield_factory, yield_mining, yield_consumer (IndustrySystem._yield_mult), survey (väčší dosah ložísk v TerrainSystem.deposit_at), research_speed, rate_bonus (PoliticsSystem.rate_bonus), reach_mult (zatiaľ len uložené). Efekty sa už neprepisujú naslepo – platí lepšia hodnota.
- Sloty: 1 základný, +1 cieľ „Výskumné oddelenie“ (nový uzol focus tree, Ekonomika, po fin1), +1 R&D centrum (250 000 €, tlačidlo v záložke Výskum). Ďalšie výskumy idú do fronty. Save: `player.research` = slot 1 (starý formát), nové voliteľné `player.research_extra`, `player.rnd_center`.
- UI: nová záložka „Výskum“ – posuvný strom (scripts/ui/research_tree_view.gd, rovnaký štýl ako strom cieľov), čiary prerekvizít, tooltip s cenou, trvaním a efektom.
- Upravený test logistics1_freight_still_0_9 (namiesto „presne 8 uzlov“ kontroluje, že pôvodných 8 existuje).

PRE ONDREJA:
1. Záložka Výskum: strom so 6 vetvami, klikni na uzol a výskum sa spustí (stojí peniaze a dni).
2. Naraz beží 1 výskum. Druhý slot dá cieľ „Výskumné oddelenie“, tretí R&D centrum.
3. Geologický prieskum zväčší náleziská na mape, Dátové centrum zrýchli výskum o 20 %.

## #17 Mená (anglické slovné hračky + personál podľa krajiny) — HOTOVO
- politics_juan5.json: lídri ako parodické slovné hračky (Donald Trumpet, Vladimir Putout, Xi Jinpong…); names_juan5.json: 60 skupín pre 165 krajín, ženské priezviská (-ová, -a…), poradie priezvisko-meno (JP, CN, KR, HU…).
- Testy: j5_name_* (unit 354 OK / 0 FAIL).

## Hlavné menu na celú obrazovku + splash + logo — HOTOVO
- Splash ~3 s (fade in/out, preskočí sa klikom alebo klávesom; v headless a dev sa nezobrazí): logo pečať + PROJEKT-47 + „developed by Wondris404“. Boot splash Godotu nahradený logom, logo je aj ikona aplikácie (assets/ui/logo.png, icon.png).
- Menu: pixelové nočné mesto s jachtou (assets/ui/menu_bg.png, pomalý pohyb), veľké logo, tlačidlá Pokračovať / Nová hra (→ Easy/Tutoriál/Medium/Hard/Realistic/Story) / Načítať hru / Nastavenia / Dev / Koniec, dole wondris404. Prispôsobí sa rozlíšeniu.
- Kým je menu otvorené, mapa a herné UI sú skryté a hra stojí. Esc v hre otvorí menu (Pokračovať / Späť do hry).
- Dev: hneď na mapu (bez intra, tutoriálu a prezývky), +50 M €, všetok výskum hotový, bez progresie. F12 = dev panel (+10 M, preskočiť 30 dní s ms/deň a FPS, dokončiť výskum). DEV hra sa neukladá do slotov.
- uitest: P47_UI_MENU_FULLSCREEN 1.

## #18 (časť) Letisko — HOTOVO, ostatné z #18 rozpracované
- Hotel už je (stredný podnik). Nové letisko = veľký podnik za 15 M €. Vyžaduje mesto (krajina má ≥ 1 mil. obyv.). Mesačné poplatky za lety (rastú s tvojimi leteckými spoločnosťami v krajine) a za pasažierov (rastú s tvojimi hotelmi a veľkosťou krajiny).
- Testy j5_airport_*.

### PRE ONDREJA
- Po spustení: logo → menu. Klik alebo kláves splash preskočí. Dev hra sa nedá uložiť (je to zámer).
- Letisko postav v krajine s mestom. Viac leteckých spoločností a hotelov v tej krajine = vyššie poplatky.
- Ešte chýba: kolaterálové úvery (zatiaľ len prázdna funkcia), UI pre vylepšenia firiem, #19 burza.

## #18 dokončenie: úvery, progresia, upgrady, letisko, Dev panel
- Limit úveru na štarte podľa obtiažnosti: Easy 200k, Tutoriál 180k, Medium 150k, Hard 120k, Realistic 100k. Rastie s čistým imaním, reputáciou a počtom splatených úverov.
- Úver so zálohou (panel „Úver so zálohou“ pod tlačidlom Pôžička). Vyberieš firmy alebo hotovosť. Banka uzná z firmy 50 %, z hotovosti 70 % hodnoty. Úver najviac do hodnoty záloh a do limitu.
- Založenú firmu nepredáš, nedáš na burzu ani do holdingu. Keď 3 mesiace nesplácaš alebo príde default, banka zálohy zoberie. Po splatení sa zálohy uvoľnia.
- Nezabezpečený úver najviac 30 000 € (úrok +4 %), naraz len jeden.
- Progresia platí v hrách z menu (nie v Dev): malé podniky hneď, stredné a veľké cez výskum alebo cieľ a minimálne čisté imanie.
- Detail firmy: úroveň 1–3 s tlačidlom Vylepšiť (výskum Modernizácia, potom Priemysel 4.0), Predať firmu, IPO.
- Letisko: reálne mesto z cities.json s aspoň 200 tis. obyvateľmi (zapíše sa do firmy).
- Dev panel (F12): +10 M, skok o 30 dní (ms/deň, FPS), dokončiť výskum a všetky ciele, udalosť (recesia a pád burzy), vojna (vybraná krajina proti susedovi), log chýb.

## #19 Burza, IPO, korporácia
- Nová karta „Burza“: index P47, nálada trhu, zoznam titulov (40 národných firiem z top-20 ekonomík s burzou, AI konkurenti, tvoje firmy a holdingy), graf (index alebo titul), portfólio.
- Cena sa riadi ziskom, rastom, sektorom (P/E), úrokmi, vojnami a udalosťami, náladou trhu a šumom; prepočítava sa týždenne. Dividendy mesačne: 40 % zisku, pri ovládanej firme 70 %.
- Nad 50 % akcií je možné prevzatie. AI konkurent ti pri ňom odovzdá firmy.
- IPO jednej firmy: hodnota aspoň 1 M €, predáš 30 % akcií, poplatok 5 %. Pod 50 % strácaš kontrolu nad firmou.
- Korporácia/holding: aspoň 2 firmy, hodnota = súčet + 5 % za každú ďalšiu firmu (max +25 %). Firmy sa dajú pridať aj vyčleniť (spin-off; ak je holding na burze, akcionári dostanú akcie novej firmy v rovnakom pomere). IPO holdingu funguje rovnako.
- Krajiny v úrovni 2 nemajú burzu. Odomknutie cez výskum Úverový scoring alebo Algoritmické hodnotenie úverov, prípadne cieľ Financie; IPO len cez Algoritmické hodnotenie úverov alebo cieľ.
- Save v3: stav je vo voliteľnom kľúči ext.exch, staré savy fungujú.
- Testy: j5_limit_*, j5_unsecured, j5_haircut, j5_secured_*, j5_pledged_*, j5_seized, j5_cash_release, j5_stock_*, j5_takeover*, j5_hostile_rival, j5_ipo*, j5_lose_control, j5_corp_*, j5_spinoff. uitest P47_UI_J5.

### PRE ONDREJA
- Peniaze: pod Pôžička klikni „Úver so zálohou“, zaškrtni, čo založíš, a zadaj sumu. Bez majetku zober nezabezpečených 30k.
- Burza: karta Burza, vyber titul, zadaj kusy, Kúpiť/Predať. Nad 50 % klikni Prevziať.
- IPO: detail firmy → IPO (firma musí mať hodnotu aspoň 1 M €). Holding: karta Burza dole, zaškrtni firmy a zadaj názov.
- Dev hra sa neukladá.

## Juan9 – Fáza A (2026-10-25)
- Banky: jedna cesta založenia (Založiť → Postaviť na mape → Banka, v meste), starý gombík „Založiť banku“ v Trh & banky odstránený. Viac vlastných bánk (player.bank_ids), detail = kliknutá banka. Jeden úrok vkladov/sporenia. Vysvetlenie úverov (limit, úrok, záloha, splátky) v hre: gombík „Ako fungujú úvery a banky?“ + tooltipy.
- Vnútorné dodávky: dodávateľ a odberateľ v tej istej krajine A v tom istom holdingu → odberateľ platí len dopravu (6 % trhovej ceny), platí pre všetky suroviny vrátane elektriny. Inak trhová cena.
- UI: ovládací panel vľavo, mapa vpravo. Burza = zatvárateľné okno nad mapou (gombík Burza pod mapou).
- Mapa: každý typ firmy sa stavia ručne kliknutím na mape (výber typu → klik na miesto). Pravidlá: obchody/služby v meste, letisko pri meste ≥200k (nie v centre), prístavné/logistické pri meste, elektrárne/chémia/oceliarne mimo mesta, bane na nálezisku. Jasná hláška pri zlom mieste.
- Zoom namiesto regiónov: ďaleko 1 ikonka + počet na krajinu (klik → zoznam mojich firiem s ikonkami), zblízka mestá s názvami a jednotlivé budovy; klik na mesto → čo tam vlastním. 53 vlastných pixel ikoniek (assets/icons).
- Ikona skratky „Spustiť hru“ = assets/ui/icon.ico.
- Testy: unit 407 OK (nové j9_*), uitest všetko 1.
### PRE ONDREJA
Firmy stavaj: Založiť → Postaviť na mape → vyber typ → klikni na mapu. Koliesko myši = priblíženie (mestá a budovy). Burza je gombík pod mapou. Holding (Burza → Korporácia) zlacní dodávky medzi tvojimi firmami v tej istej krajine.

## Juan10 – Fáza B (2026-10-25)
- Burza: 124 titulov v 11 sektoroch (Financie, Poľnohospodárstvo, Zbrojárstvo, Energetika, Technológie, Priemysel, Doprava, Médiá, Zdravotníctvo, Spotrebný tovar, Telekom), filter sektora, sektorové indexy a nálada sektora (zbrojárstvo rastie počas vojny). Pri >50 % gombík „Začleniť do korporácie“ (výber korporácie).
- Burza: živý náhľad obchodu (cena/akcia, spolu, poplatok 0,25 %, podiel po, hotovosť po), Kúpiť sa vypne pri nedostatku peňazí (červená hláška), náhľad predaja.
- Opravy: Moje firmy sa obnovia hneď po založení; bodka hlavného mesta sa neprekrýva s ikonkou krajiny.
- #5 Infraštruktúra (gombík pod mapou): diaľnice medzi mestami, letiská (mestá 1,5M+), prístavy (pobrežné mestá), námorné trasy. Nové: Ropná rafinéria (ropa → palivá), Plynáreň (zemný plyn), komodity Palivá a Zemný plyn. Budovy v meste kupuješ len cez vlastnú Realitku v krajine (nájom 0,6 %/mes.).
- #6 Investičné fondy: fond mesačne investuje 30 % hotovosti, vidno držby (titul, sektor, kusy, hodnota) a čo kúpil.
- #7 Charita: dar v krajine → popularita (klesajúci výnos, max +5/mes./krajina) + vplyv.
- #8 Osobné štatistiky (HOI4 lišta nad mapou + okno Impérium): majetok, hotovosť, zamestnanci, vplyv, popularita, bezpečnosť, firmy, krajiny, holdingy, budovy, štáty.
- #9 Kúpa štátu: cena podľa HDP a stability (napr. SK ~14 mld. €), treba čisté imanie 1,5× ceny; potom zmena politického systému; tvoje firmy tam platia polovičnú daň.
- HQ korporácie: umiestni sa na mapu do mesta, korporácia platí daň podľa krajiny HQ, presun kedykoľvek za poplatok (1 % hodnoty, min 50k). Finančná divízia: % zo ziskov do rozpočtu, report stratových firiem, upgrady ziskových, voliteľný predaj chronicky stratových, automatické obchodovanie (pod/nad kĺzavým priemerom), preberanie (>50 %) a začleňovanie do korporácie, limity (max na obchod, sektory), log aktivity.
- Save: všetko vo voliteľnom GameState.ext.emp. Testy: unit 437+ OK (j10_*), uitest bez chýb.
### PRE ONDREJA
Pod mapou: Burza, Impérium, Infraštruktúra. V Impériu: kúp štát, daruj, nastav HQ (vyber krajinu na mape → Umiestniť HQ → klikni do mesta) a zapni finančnú divíziu.

## Juan11 – Esc pauza + Portfólio (2026-10-25)
- Esc v hre už nehádže do hlavného menu: otvorí malé okno v strede (hra pozastavená): Pokračovať, Uložiť hru (sloty 1–3; DEV hra sa neukladá – hláška), Načítať hru (sloty, potvrdenie), Nastavenia (mierka UI, celá obrazovka), Ukončiť hru (Do hlavného menu / Na plochu, s potvrdením a možnosťou najprv uložiť). Druhé Esc okno zavrie.
- Okno „Impérium“ premenované na „Portfólio“ (titulok „Portfólio a majetok“).
### PRE ONDREJA
Esc = pauzové okno. Gombík pod mapou sa teraz volá Portfólio.

## Juan12 – zbalitelný panel + hlboký zoom (2026-10-25)
- Ovládací panel sa dá skryť gombíkom „◀ Skryť panel“ (pod mapou) alebo klávesou Tab; mapa sa roztiahne na celú šírku, späť „▶ Panel“.
- Zoom až 300× s plynulým priblížením ku kurzoru (koliesko). Úrovne: krajiny (<3×) → regióny a mestá (3–30×) → detail mesta (30×+): obrys mesta podľa veľkosti, hlavné triedy, pri 100×+ ulice a bloky, budovy na úrovni ulíc. Ukazovateľ „Zoom N× – úroveň“ pod mapou.
### PRE ONDREJA
Tab = skryť/ukázať panel. Koliesko myši ťa dovedie až na ulice mesta.

## Juan13 – právnici, závislosť krajín, Pôžičky (2026-10-25)
- Banka má Právne oddelenie (detail banky): najímanie/prepúšťanie právnikov (6 000 €/mes. každý), školenie (úroveň 1–3, 100k). Každý mesiac žalujú nesplatené dlhy: šanca ~45 % + bonus korporácie (gombík „Začleniť banku do korporácie“, podľa veľkosti) + úroveň + počet právnikov + závislosť krajiny; pri Úplnej závislosti ~99 %. Výhra: 50–80 % vymožené, súdne trovy 10 %; prehra: časť odpísaná, občas reputácia −2. Existuje popri PMC (aj PMC vymôže viac pri vyššej závislosti). Pri úplnej závislosti len satirické správy.
- Klik na krajinu: „Závislosť na tebe“ 0–100 (Žiadna/Nízka/Stredná/Vysoká/Úplná) z podielu na HDP, surovín/energie (zoznam komodít s množstvom a %), zamestnancov, úverov tvojich bánk, vplyvu; vlastnený štát = 100. Zvyšuje šancu lobingu a vymáhania.
- Stará záložka Financie (Bid/Ask, nepopísané polia) odstránená. Nová záložka Pôžičky: úver z banky (so zálohou/bez), vysvetlivky, a Dlhopisy – suma, kupón %, splatnosť, náhľad (koľko dostaneš podľa trhového výnosu, kupón ročne, úroky spolu, limit) a zoznam vydaných dlhopisov. Oprava: vlastné vydané dlhopisy sa rátajú ako dlh, nie majetok.
- Testy: unit 451 OK (j13_*), uitest bez chýb.
### PRE ONDREJA
Pôžičky = nová záložka (úvery + dlhopisy). Právnikov najmeš v detaile banky. Závislosť krajiny uvidíš po kliknutí na krajinu.

## Juan14 – oprava klikania na krajinu (t812u)
- `world_map.gd`: firma sa otvorí iba pri kliku do skutočného polomeru ikonky (`icon_px()*0.6+2`, škáluje so zoomom); predtým bol polomer 9×zoom (pri zoome 8 až 72 px), takže klik do krajiny chytil najbližšiu firmu.
- Klik mimo ikonky → detail krajiny (Závislosť na tebe + zoznam firiem). Mestský panel len pri zoome ≥12 (detail mesta). Oddialene: agregovaná ikonka krajiny → detail krajiny.
- Logika kliku v `_click_at()`; uitest `P47_UI_J14_CLICK country/firm/aggregate`.
### PRE ONDREJA
Klikni kamkoľvek do krajiny → otvorí sa okno „<Krajina> – závislosť a tvoje firmy“. Firmu otvoríš len kliknutím priamo na jej ikonku.

## Juan15 – DEV ukladanie, Burzová firma, Odberatelia + klik na HQ (t813u…)
- **DEV save:** odstránené zámky v `main.gd save_game()` a `pause_popup.gd` (_save_dlg, potvrdenie pri odchode). DEV hra sa ukladá do bežných slotov (formát v3), pridá `ext.dev=true`; načítanie obnoví `config.dev`. uitest `P47_UI_J15_DEVSAVE` (uloženie → načítanie → stále DEV).
- **Burza / obchodník s cennými papiermi** (`stock_broker`, Financie, len v meste, vlastná ikonka): každý týždeň obchoduje akcie všetkých kótovaných firiem z vlastného kapitálu – kupuje pod 8-týždňovým priemerom, predáva nad ním; poplatky 1 500 €/týž. + 0,2 % obratu; občas chybný obchod (strata). V detaile firmy: P/L, poplatky, nerealizovaný zisk, držané akcie, log, prepínače (Obchodovať, Kapitál %, Riziko nízke/stredné/vysoké), vklad/výber 1 M€. Dividenda z nej len zo zisku, kapitál ostáva. Bez dvojitého obchodovania s finančnou divíziou HQ (ticker drží len jeden z nich). Ukladá sa vo firme (`firm.broker`).
- **Klik na HQ** na mape → Portfólio zamerané na tú korporáciu (HQ má pri kliku prednosť).
- **Odberatelia** v Portfóliu: kto kupuje od tvojej korporácie / všetkých firiem – krajina, odberateľ (domácnosti a štát, konkrétne AI/zahraničné firmy, ostatné), tovar, množstvo a € za mesiac, triedenie (€, množstvo, krajina, tovar), súčty podľa krajín. Kľúče `ext.emp.cust` / `cust_prev`.
- Testy: unit `j15_*`, uitest `P47_UI_J15 hq_portfolio/customers/broker`.
### PRE ONDREJA
DEV hru už vieš uložiť (Esc → Uložiť hru). Novú firmu „Burza / obchodník“ postavíš cez Založiť → Financie; nastav jej riziko a kapitál v detaile. Klikni na svoju centrálu na mape → uvidíš, kto ti čo kupuje.

## Juan16 – krajšia mapa, mesto zhora, téma, ikonky, menu (t818u)
- **Mapa** (`world_map.gd`): gradient hĺbky vody, pobrežné plytčiny, terénna paleta krajín podľa zemepisnej šírky (trópy/púšte/mierne pásmo/tundra) + jemný politický odtieň, mäkšie hranice, oranžová žiara okolo krajín, kde máš firmy/štát, hlavné mestá ako svetlé bodky, mestá v regióne ako jemné zastavané plochy.
- **Mesto zhora** (procedurálne, žiadne reálne satelitné snímky): bloky so strechami rôznych farieb + tiene, ulice, široké hlavné triedy, parky so stromami, rieka, okraj mesta sa rozpadá do polí a záhrad. 3 úrovne detailu podľa zoomu (zoom < 25 / < 100 / ≥ 100). Celé mesto je jeden predpočítaný mesh na mesto+úroveň (cache) → plynulé. Tvoje budovy: ikonka na tmavom podklade so žiarou a oranžovým rámom. Klikanie (JUAN14) bez zmeny.
- **Téma** (`ui/theme_factorio.tres`): zaoblené rohy, tiene panelov, hover tlačidiel s akcentom, nadpisy s obrysom, jednotné medzery.
- **Ikonky** (`assets/icons/*.png`, 32×32): jednotný štýl – zaoblený štvorec s prechodom, obrys, tieň, ostrejší glyf, farebný pásik podľa kategórie (malé/stredné/veľké/financie/médiá/šedá zóna).
- **Hlavné menu**: pixelové tlačidlá s hover „▸“, postupné objavenie tlačidiel, dýchajúca pečať, pulz a tieň titulku.
- Náhľady: `preview/j16_before_*` vs `preview/j16_after_*` (menu, world, region, city, city_close, panels, icons).
### PRE ONDREJA
Priblíž mapu až na mesto – uvidíš strechy, ulice, parky a rieku ako zo satelitu (vymyslené, nie Google). Krajiny, kde podnikáš, žiaria oranžovo.

## Juan17 – mapový mód Odberatelia, opravené ikonky, náhľad HOI4 štýlu (t819u)
- Tlačidlo **Odberatelia** vedľa Terén/suroviny: krajiny zafarbené podľa toho, koľko od teba (všetky tvoje firmy) kupujú za mesiac (posledný celý mesiac, inak tento doteraz). Plynulý gradient: tmavozelená = najviac → svetlozelená → žltá → oranžová → svetločervená → tmavočervená = nič. Logaritmická škála (aj malý odberateľ nie je červený). Legenda s 8 stupňami a € hodnotami. Tooltip krajiny: € za mesiac + top 3 tovary. Klikanie bez zmeny. `Empire.customers_by_iso()`, `world_map.cust_*`.
- Ikonky bez symbolu prekreslené: `construction_co` (žltá – žeriav), `nuclear_plant` (žltá – symbol radiácie), `power_coal` (sivá – komín + blesk).
- **Náhľad HOI4-štýlu mapy** (zatiaľ NEintegrovaný): offline render `/workspace/projekt47/mockup_hoi4/render.py` – procedurálny reliéf s tieňovaním (vlastné hrebene pohorí + šum), tmavomodré more s textúrou, ľad pri póloch, polopriehľadné „maľované" farby krajín s papierovou textúrou a tmavším vnútorným okrajom, veľké zakrivené názvy pozdĺž dlhej osi krajiny. Žiadne cudzie assety.
- Testy: unit `j17_*`, `P47_UI_J17` (j17_shot).
### PRE ONDREJA
Klikni „Odberatelia" dole pri mape – uvidíš, kto ti koľko platí. Pozri náhľady j17_hoi4_mockup_far/close a povedz, či takýto štýl mapy chceš.

## Juan18 – HOI mapa náhľad v2 + prepínač (len DEV)
- Prepínač „Mapa: Pixelová / HOI" pri mape, viditeľný len v DEV hre; uložený v `user://settings.cfg` [map] style. V normálnej hre vždy pixelová. HOI vykresľovanie zatiaľ NEintegrované (čaká na schválenie). uitest `P47_UI_J18`.
- Náhľad v2 (`mockup_hoi4/render2.py`): bez medzier medzi krajinami (pevnina z Natural Earth, medzery vyplnené najbližšou krajinou), reálny reliéf z Natural Earth SR_50M (public domain), skaly a sneh na horách, lesy so stromčekmi, púšte s dunami, tundra, rieky a jazerá (NE), mestá ako malé 3D zhluky budov podľa veľkosti.

## Juan19 – železnice, ropovody/plynovody, logistika, plyn, zdroje vstupov, % mesta (2026-10-25, len BOX)
- Nový autoload `Transport.gd`: stavba tratí „Železnica“ a „Ropovod / plynovod“ (klik A → klik B na mape, cena za km, kapacita, vyťaženie).
- Firmy hráča: vstupy od vlastného výrobcu (rovnaká korporácia/krajina) = len doprava; inak trhová cena + doprava. Železnica/potrubie/logistické centrum (rádius X km, Y % dopravy zadarmo, rastie s úrovňou) dopravu zlacňujú. Detail firmy: sekcia „ZDROJE VSTUPOV“ (vlastné vs kúpené, doprava, ušetrené).
- Nová firma „Vrt na zemný plyn“ (ložiská plynu, ikona). Plynová elektráreň a Plynáreň používajú zemný plyn.
- Klik na mesto: % budov v meste, ktoré vlastní hráč.
- Neumiestnené firmy sa kreslia blízko hlavného mesta (predtým rad stovky km na východ).
- DEV prepínač mapy premenovaný na „Mapa: Pixelová / Atlas“. Náhľady Atlasu: 3D izometrické budovy firiem hráča so zvýraznením, diaľnice/cesty, železnice, ropovod, letiská, prístavy, elektrárne a vedenia VN do miest (preview/j19_atlas_*.png) – ČAKÁ NA SCHVÁLENIE, v hre zatiaľ nie je.
- Testy: unit 477 OK / 0 FAIL, uitest bez chýb.
### PRE ONDREJA
Železnicu a potrubie postavíš tlačidlami pod mapou. Plyn: postav vrt na ložisku plynu, elektráreň potom platí len dopravu. Pozri náhľady Atlasu a povedz, či to tak chceš do hry.

## Juan20 – Atlas mapa v hre (2026-10-25, len BOX, Ondrej schválil „Áno“)
- Prepínač „Mapa: Pixelová / Atlas“ (len DEV; normálna hra vždy pixelová). Uloží sa do user://settings.cfg.
- Zapečený terén: assets/atlas/world.jpg (2880×1440) + 69 dlaždíc 30°×30° (960×960, 32 px/stupeň), spolu 7,6 MB. Hra ich načíta lenivo raz a drží v pamäti (cache). Skript tools/bake_atlas.py (Natural Earth – public domain, vlastné procedúry; potrebuje dáta NE, v hre netreba).
- Viac 3D: silnejší hillshade, vrhané tiene (JV), ambient occlusion v horách, stromy s tieňom; mestá ako vyššie izometrické budovy so stenami, oknami a tieňmi; pri CITY_ZOOM prechod do satelitného mesta (pôvodné JUAN16).
- Firmy hráča: 3D modely podľa typu (baňa, vrt, elektráreň s komínom, jadrovka s chladiacimi vežami, rafinéria s nádržami, farma, logistika s kontajnermi, kancelárska veža, letisko, lodenica, solár) + oranžové zvýraznenie + ikona.
- Pri priblížení: diaľnice, cesty, železnice, ropovody/plynovody (vrt → najbližšia rafinéria/plynáreň zo save), prístavy, letiská, elektrárne (aj AI firmy zo save) s vedeniami VN a stožiarmi do 2 najbližších miest; postavené trate hráča (JUAN19).
- Názvy krajín miznú s priblížením, názvy miest sú odsadené od stredu a kreslia sa navrchu.
- Mapové módy (Terén/Suroviny, Odberatelia) aj kliky (firma vs krajina) fungujú; overené v j20_shot.
- Naklonená kamera (tilt) NEROBENÁ – rozbila by presné klikanie a výkon; 3D dojem robia izometrické modely + tiene.
- Výkon (BOX, softvérové OpenGL cez Xvfb, 1024×600; na reálnej GPU bude rýchlejšie): Atlas región 52 ms kreslenie vs Pixel 48 ms, blízko 37 vs 42 ms, mesto 36–40 ms; načítanie dlaždíc spolu 0,24 s raz; výpočet infraštruktúry 0,15 s raz (potom cache).
- Testy: unit 481 OK / 0 FAIL, uitest OK, j18_ui OK.
### PRE ONDREJA
V DEV hre klikni dole na „Mapa: Pixelová“ → prepne sa na Atlas. Priblíž kolieskom: najprv krajiny, potom cesty/železnice/elektrárne, potom mesto zblízka.

## Juan21 – logá, názvy, AI/dátové centrá, premenovanie, výrobky, nehnuteľnosti (2026-10-26, len BOX)
- Logo korporácie: Portfólio → „Upraviť logo“ (tvar, pozadie, farba symbolu/textu, 10 symbolov, iniciály max 4). Uložené v save (ext.brand.logos). Zobrazuje sa v Portfóliu, na burze (ikona holdingu), na mape na HQ (veľké) a ako malý odznak na firmách korporácie (Pixel aj Atlas).
- Burza: národné tituly majú parodické názvy (Mikrosoftt, Macrohard, Teslo, Koka-Kola, Goldman Sax…), sektory ostávajú, žiadne skutočné logá; v burze poznámka o satire. Starý save sa premenuje automaticky raz. Nový sektor „AI a dáta“.
- Nové firmy (Veľké podniky): Dátové centrum (elektrina + elektronika/čipy → výpočtový výkon), AI firma (výpočtový výkon → AI služby pre firmy a štát; +4 % výroby tvojim firmám v krajine za každú, max +12 %), Letecká továreň (lietadlá). Lodenica teraz vyrába lode. Ikony + 3D modely v Atlase.
- Premenovanie: v detaile firmy pole s názvom + „Premenovať firmu“ / „Premenovať korporáciu“; v Portfóliu aj premenovanie korporácie. Názov sa prenesie aj na burzu.
- Výrobky: autá, lode, lietadlá – detail firmy ukazuje, v ktorých krajinách skončili (60 % domáci trh, 40 % export podľa veľkých ekonomík); tlačidlo „Ukázať na mape“ kreslí oblúky s počtami.
- Nehnuteľnosti: typy Kancelárie / Byty / Obchody / Sklady / Prázdna parcela (rôzna cena a nájom; parcela bez nájmu, dá sa zastavať). Staré budovy = kancelárie. Portfólio → NEHNUTEĽNOSTI: súčty, rozpis podľa typu, zoznam podľa mesta/krajiny/typu, filter typu, zoradenie; klik na mesto priblíži mapu.
- Testy: unit 515 OK / 0 FAIL (34 nových), uitest OK, j20 kliky OK.
### PRE ONDREJA
Logo: Portfólio → Upraviť logo. Firmu premenuješ v jej detaile. Nehnuteľnosti kúpiš klikom na mesto (vyber typ), prehľad je v Portfóliu.

## Juan22 – koľko % ľudí používa tvoje médiá a telekom (2026-10-26, len BOX)
- Telekom, Noviny, Televízia, Sociálna sieť: v detaile firmy riadok „DOSAH: X % obyvateľov krajiny (počet zákazníkov/čitateľov/divákov/používateľov), podiel na trhu, strop, konkurenti“.
- Výpočet (živý, nič sa neukladá – save v3 bez zmeny): strop typu (telekom 95 %, soc. sieť 80 %, TV 85 %, noviny 35 %) × príjmový faktor krajiny (0,35 + HDP/os./40 000, max 1). Dopyt = populácia × strop. Kapacita firmy = základ typu (2,5 mil./3 mil./1,5 mil./0,4 mil.) × úroveň (+80 % za úroveň) × obsadenosť zamestnancov. Domáci hráči držia kapacitu 60 % dopytu. Používatelia = dopyt × kapacita firmy / (kapacity všetkých firiem typu v krajine + domáci hráči), max kapacita firmy.
- Portfólio: nová sekcia MÉDIÁ A TELEKOM (každá firma: % obyvateľov, počet, podiel). Detail krajiny aj mesta: riadok TVOJE MÉDIÁ A TELEKOM.
### PRE ONDREJA
Postav Telekom/Noviny/Televíziu/Sociálnu sieť – v detaile firmy a v Portfóliu uvidíš, koľko % ľudí v krajine ich používa. Vyššia úroveň a viac zamestnancov = viac ľudí, konkurencia = menej.

## Juan23 – optimalizácia výkonu (2026-10-26, len BOX)
Meranie: nový režim `-- perf23` (62 firiem hráča v 12 krajinách, 90 firiem spolu, železnica, ropovod, budovy). CPU časy v ms, pred → po:
- simulácia 1 dňa: 160,9 → ~64 (Transport.discount 30 ms → 0,1 ms; settle 97 → 11)
- kreslenie mapy Pixel svet/región/detail/mesto: 50,8/56,6/48,2/53,3 → 8,9/17,5/10,2/11,5
- kreslenie mapy Atlas svet/región/detail/mesto: 33,3/58,8/50,2/48,0 → 6,6/18,7/13,2/12,9
- hra na rýchlosti 3 (snímka, box bez GPU): priemer 600 → 53, najhoršia 784 → 90 ms (≈1,7 → 19 FPS v softvérovom renderi; na GPU viac)
Čo sa zmenilo (hrateľnosť a výsledky simulácie rovnaké – stabilitný test aj nový test j23_phased_same dávajú identické čísla; save v3 bez zmeny):
- Transport: cache polôh firiem, napojenia na trate, logistického hubu a zliav (platí v rámci dňa/snímky; predtým O(n²) a `load()` pri každom volaní).
- Deň simulácie rozdelený na fázy s časovým rozpočtom na snímku (9 ms, pri rýchlosti 3 14 ms) – obraz sa neseká; pred uložením sa rozpracovaný deň dokončí.
- UI lišta a prekreslenie mapy po dňoch max. 5× za sekundu (predtým každý snímok).
- Mapa: krajiny ako predpočítané meshe + kreslenie cez transformáciu (bez prepočtu každého bodu), plytčiny tiež; cache ťažísk, rozmerov textov, hlavných miest, zoznamu firiem.
- Atlas: priestorová mriežka (kreslí sa len viditeľné), cesty/železnice/diaľnice ako predpočítané polia jedným volaním, 3D mestá a elektrárne v jednom dávkovom volaní, rozloženie budov miest v cache, LOD (z diaľky len veľké mestá), dlaždice terénu sa prednačítajú na pozadí (vlákna) – žiadne seknutie pri posune.
- Nastavenia → Grafika: automaticky / vysoká / nízka. Automaticky = nízka na integrovanej grafike (AMD Ryzen): bez animácií mapy, plytčín a stožiarov. Limit 60 FPS + VSync (notebook sa neprehrieva).
- Pamäť: navyše rádovo stovky MB (dlaždice Atlasu ~250 MB, meshe a cache), ďaleko pod limitom 8 GB.
### PRE ONDREJA
Hra by sa už nemala sekať: mapa sa kreslí 3–6× rýchlejšie, deň simulácie 2,5× rýchlejšie a rozkladá sa do viacerých snímok. Ak by sa ešte sekala, daj v Nastaveniach „Grafika: nízka“. Na rýchlosti 3 môže hra bežať o niečo menej dní za sekundu, ale plynulo.

## Aktualizácia referenčnej sondy (2026-10-27)
- Referenčný výstup zodpovedá aktuálnemu svetu so 165 krajinami a 28 komoditami; aktualizované sú aj počty aktívnych krajín a firiem. Shellový test ignoruje diagnostický riadok P47_MIN_DATA rovnako ako PowerShellový test.
- Východisková sonda prešla, stabilita po 365 dňoch bola v pásme 100 %. Jednotkové testy: 527 OK, 1 FAIL (výkonnostný limit 80 ms/deň; namerané 153,7 ms/deň na tomto behu).
- Testy bežali v oddelenej kópii s vlastnými používateľskými dátami. V kópii bolo vypnuté mazanie dočasných súborov; herná logika ani kontrolné asercie sa nemenili.

## Čiastková optimalizácia trhového dňa (2026-10-27)
- Výpočty dopytu a ponuky sa v bežiacej hre spracúvajú po dvojiciach komodít; aktualizácia kapacít a plánovanie/vyhodnotenie trás sú oddelené fázy. Poradie výpočtov zostalo zachované. Pri ukladaní sa rozpracovaný deň aj naďalej dokončí.
- Pevný seed 47, 62 hráčových firiem: úplný uložený stav po 35 dňoch je identický pred úpravou aj po úprave, vrátane simulácie po fázach. Kontrola `j23_phased_same` prešla.
- Meranie na tomto počítači: priemerný snímok pri rýchlostiach 1/2/3 pred úpravou 30,33/69,13/74,16 ms, po úprave 27,60/44,65/51,36 ms; najhoršie snímky pred 121,07/223,85/179,09 ms, po 112,51/141,18/129,90 ms. Testovací deň v náročnejšom scenári 199,26 → 187,14 ms; toto meranie zahŕňa všetky systémy a je citlivé na záťaž počítača.
- Sonda a ročná stabilita prešli; jednotkové testy 527 OK, 1 FAIL: výkonový limit 80 ms/deň (127,7 ms v tomto behu). Súborové čistenie bolo pri skúške vypnuté iba v izolovanej testovacej kópii.
- Optimalizácia ešte nie je dokončená: stále sú výrazné špičky vrátane vykresľovania mapy, aktualizácie panelu a ďalších fáz simulácie.

## Prehľad firiem bez zbytočného prekresľovania (2026-10-27)
- Počet firiem a bánk sa kontroluje najviac päťkrát za sekundu, nie pri každom snímku. Text a tlačidlá prehľadu sa obnovujú pri viditeľnom paneli, zmene dňa alebo výslovnej zmene; po otvorení panelu či záložky sa obsah obnoví aj v pauze. Signatúra tlačidiel zahŕňa aj názvy bánk.
- Skúška používateľského rozhrania prešla: opakované obnovenie v tom istom dni využilo existujúci text, premenovanie a návrat na záložku sa zobrazili správne. V scenári so 62 firmami merané pravidelné obnovenie bez zmien približne 29 → 16 ms; výsledok závisí od zaťaženia počítača.
- Sonda a ročná stabilita prešli, jednotkové testy 527 OK / 1 FAIL (výkonová hranica 80 ms/deň, meranie 130,7 ms/deň). Testovalo sa v izolovanej kópii s vypnutým odstraňovaním testovacích súborov.

## Vyúčtovanie firiem a ochrana rozpracovaného dňa (2026-10-27)
- Vyúčtovanie firiem sa spracúva v pôvodnom poradí po štyroch firmách; pri bežnej synchrónnej simulácii aj pri simulácii po fázach zostal celý stav po 35 dňoch so seedom 47 identický s pôvodným stavom.
- Pred klikom alebo klávesovou akciou sa rozpracovaný deň dokončí, aby hráč nemenil firmu alebo trh uprostred vyúčtovania. Dokončenie môže dočasne spôsobiť čakanie pri ovládaní; toto zostáva na ďalšiu optimalizáciu. Pri pauze a priamom ukladaní sa deň dokončí; krok dňa dokončí prípadne rozpracovaný deň bez pridania druhého. Neplatný save už nezahodí rozpracovanú fázu.
- Opravené obnovenie prehľadu po premenovaní cez detail firmy. Cielený GUI test overil premenovanie, návrat na záložku, pauzu, odmietnutie neplatného savu, klik, krok dňa a uloženie.
- V skúšobnom meraní boli priemery snímky pri rýchlostiach 1/2/3 25,37/35,44/41,93 ms, najhoršie 110,02/128,43/131,31 ms. Pri rýchlosti 2 prebehlo 9 dní za šesť sekúnd oproti 12 v predchádzajúcom meraní; ide o kompromis medzi plynulosťou a priepustnosťou. Celý deň v náročnom scenári 201,05 ms; rozdiely ovplyvňuje aj záťaž počítača.
- Sonda a ročná stabilita prešli; jednotkové testy 527 OK / 1 FAIL (výkonová hranica 80 ms/deň, meranie 125,7 ms/deň). Použitá izolovaná kópia bez čistenia testovacích súborov.

## Kreslenie viditeľnej časti mapy (2026-10-27)
- Hlavné mestá, značky firiem a žiara hraníc sa pri kreslení vynechávajú, ak aj s bezpečnou rezervou ležia mimo okna mapy. Súhrny značiek krajín sa používajú z rovnakého prekreslenia bez opakovaného výpočtu.
- Osem porovnaných snímok Pixel/Atlas pri rôznych priblíženiach bolo pixelovo zhodných pred a po úprave. Na tomto počítači kreslenie Pixel región 90,56 → 71,39 ms, Pixel detail 48,67 → 33,42 ms, Pixel mesto 45,37 → 30,37 ms; Atlas región 66,84 → 66,03 ms. Merania sú citlivé na záťaž počítača a mapa stále prekračuje cieľ.
- Sonda a ročná stabilita prešli; jednotkové testy 527 OK / 1 FAIL (výkonová hranica 80 ms/deň, namerané 129,5 ms/deň). Izolovaná kópia nepoužívala mazanie testovacích súborov.

## Výpočet trhových cien (2026-10-27)
- Pri úprave ceny sa používajú rovnaké vstavané číselné operácie bez opakovaných volaní pomocného autoloadu. Rýchla cesta už pre každú dvojicu krajina/tovar nevytvára prázdny slovník faktorov. Poradie výpočtov a kontrol ostáva rovnaké.
- Úplný stav po 35 dňoch so seedom 47 zostal v simulácii po fázach bajtovo zhodný s pôvodným stavom. Krátky benchmark celého dňa na tomto počítači pred 131,7 ms, po 122,8 ms; meranie sa mení so záťažou.
- Sonda a ročná stabilita prešli; jednotkové testy 527 OK / 1 FAIL (výkonová hranica 80 ms/deň, v tomto behu 120,0 ms/deň). Skúšky bežali v oddelenej kópii bez odstraňovania testovacích súborov.

## Slovenské popisy podnikov (2026-10-27)
- Všetkých 55 typov podnikov má stručný popis činnosti; materiálové vstupy a predávané výstupy sa dopĺňajú priamo z receptov. Obchodná kancelária, obchodník s akciami a banka majú vysvetlené aj špecifické zdroje príjmu. Popisy sú v nápovedách ponuky stavby a v detaile firmy či banky.
- Do kategórií ponuky stavby doplnené letisko, ropná rafinéria a plynáreň, ktoré už v hre existovali, ale chýbali v zozname. Obmedzenia ich stavby zostávajú zachované.
- GUI test overil všetkých 55 položiek ponuky, ich receptové vstupy a výstupy, detail firmy aj banky. Úplná sada v izolovanej kópii: 532 OK / 0 FAIL; sonda a ročná stabilita prešli. Výkonový test nameral 58,2 ms/deň v tomto behu; výsledok kolíše so záťažou počítača. Testovacie súbory sa nemažú.

## Vodorovne posúvateľná lišta mapy (2026-10-27)
- Spodná lišta tlačidiel má vodorovný posuvník a šípky doľava/doprava; pod kurzorom reaguje aj na koliesko a gesto touchpadu. Tlačidlá tak zostávajú dostupné aj pri užšom okne alebo otvorenom bočnom paneli.
- GUI skúška v okne širokom 1000 px overila obe šípky, gesto, koliesko a dostupnosť tlačidla ropovodu na pravom konci. Úplná sada v izolovanej kópii: 532 OK / 0 FAIL, sonda aj ročná stabilita prešli; výkonový test 59,7 ms/deň v tomto behu. Testovacie súbory sa nemažú.

## Atlas ako mapa celej hry (2026-10-27)
- Atlas je jediný zobrazovaný štýl mapy v normálnej aj DEV hre; prepínač na pixelovú mapu je skrytý. Staré nastavenie pixelového štýlu sa ignoruje a uložený stav v3 sa nemení. Pôvodné súbory pixelovej mapy zostávajú zachované.
- GUI skúška overila novú normálnu hru, načítanie stavu v3, DEV mód a vrstvy terénu aj odberateľov. Aktualizovaná staršia UI skúška potvrdila, že pixelový štýl nemožno opäť zapnúť. Výstupy výkonnostnej sondy mapy sa ukladajú v priečinku projektu.
- Úplná sada v izolovanej kópii: 532 OK / 0 FAIL; sonda a ročná stabilita prešli. Výkonnostný test 57,0 ms/deň v tomto behu; skutočná plynulosť závisí od nastavení grafiky a záťaže.

## Investičné fondy nakupujú budovy (2026-10-27)
- Fond môže raz mesačne kúpiť budovu v niektorom meste svojej krajiny z vlastnej voľnej hotovosti. Predvolený cieľ je 30 % kapitálu v nehnuteľnostiach a hráč ho môže v detaile fondu nastaviť od 0 do 100 %. Jedna celá budova môže cieľ prekročiť najviac o polovicu svojej ceny; fond nepredáva budovy automaticky.
- Budovy sa zobrazujú v portfóliu a započítajú do podielu mesta. Ich nájom ide do hotovosti fondu; ak fond prestane patriť hráčovi, budovy zostávajú hráčovi a nájom dostáva priamo. V detaile fondu sú vklady/výbery kapitálu, hodnota budov a nájom. Starý save bez nastavenia fondu dostane predvolený cieľ, verzia savu zostáva v3.
- Zmena rovnováhy: dividenda fondu je obmedzená na zisk obdobia, aby sa nevyplatil vložený kapitál. Nákupy akcií rešpektujú prevádzkovú rezervu a peniaze potrebné na cieľ budov; nehnuteľnosť sa nekúpi bez dostatočnej hotovosti.
- Podľa požiadavky na kratšie testovanie vykonaných 22 cielených kontrol (22 OK, 0 FAIL) a jedna grafická skúška cieľa, vkladu, výberu, vlastníctva mesta a portfólia (OK). Overené aj mesačné automatické nákupy, nájom bez dvojitého pripísania, starý stav a načítanie v3. Úplná 532-testová sada sa po tejto zmene nespúšťala.

## 2026-10-27 – Prehľad výroby a predaja podnikov

- Detail hráčovej firmy zobrazuje za posledných 30 dní skutočnú výrobu, predaj a tržby podľa produktu a krajiny trhu, ako aj dodávky vlastnej korporácii a nákupy vstupov s množstvom, jednotkou a cenou. Záznam vzniká pri existujúcom zúčtovaní výroby bez zmeny ekonomických výpočtov; staré uložené hry bez záznamov zostávajú kompatibilné s formátom v3.
- Trh spája tovar súhrnne, preto nie je možné spoľahlivo označiť konkrétnu kupujúcu korporáciu ani konečnú krajinu po ďalšom vývoze. Zobrazená krajina je krajina trhu predaja; obmedzenie je uvedené aj v hre. Samostatné obchodné pulty bez výrobného receptu nemajú tento výrobný prehľad.
- Overenie: pred zmenou 22 cielených kontrol fondu bez chyby; po zmene 10 cielených kontrol výroby, trhu a kompatibility uloženia bez chyby. Plná sada nebola spustená podľa aktuálneho limitu testovania.

## 2026-10-27 – Čiastková oprava bánk

- Pri krachu jednej banky sa už neodstraňuje výber inej aktívnej banky; výbery a odliv sporenia sú obmedzené stavom vkladov. Nastavenie spoločnej úrokovej sadzby vkladu a sporenia má teraz jeden ovládací prvok, ktorý zodpovedá existujúcemu modelu.
- Overenie: pred úpravou 15 bankových kontrol úspešných, po úprave 17 vrátane kontroly aktívnej banky a súvahy. Poradca a štátne úvery zatiaľ nie sú dokončené.

## 2026-10-27 – Rozšírenie prehľadu toku tovaru

- Detail výrobného podniku doplnený o aktuálny sklad výrobkov. Obchodná firma zaznamenáva skutočne vykonaný presun komodity medzi trhmi, deň, množstvo, pôvodnú a cieľovú krajinu, celkové náklady vrátane cla a dopravy, tržbu a obchodnú maržu; prehľad sumarizuje posledných 30 dní. Údaje sa ukladajú do obmedzeného denníka firmy a staršie uloženia v3 fungujú s prázdnymi údajmi.
- Obmedzenie: súčasná burza používa agregovanú ponuku a dopyt, nepáruje konkrétnych predávajúcich s konkrétnymi kupujúcimi. Nebolo preto možné zaznamenať skutočné meno dodávateľa, odberateľa, kategóriu domácnosti/štát ani konečnú destináciu výrobku po súhrnnom predaji bez zavedenia novej alokácie; tieto informácie sa nevymýšľajú. Burzový broker obchodujúci s akciami nemá evidenciu komoditných obchodov, ak ich v simulácii nevykonáva. Požadovaná úplná evidencia zostáva nedokončená.
- Overenie: 15 cielených kontrol úspešných, vrátane v3, výpisu skladu a medzinárodnej trasy. Porovnanie pri jednom riadenom obchode so zapnutou a vypnutou evidenciou potvrdilo rovnakú hotovosť a zásoby; kompletné porovnanie celej simulácie a testy individuálneho párovania nie sú vykonateľné bez existujúceho párovania. Jeden prvý test zobrazenia zlyhal pre odlišný názov krajiny v dátach, následne opravený a úspešne opakovaný.

## 2026-10-27 – Konkrétne vnútorné dodávky a porovnanie simulácie

- Pri skutočne odovzdanom tovare medzi podnikmi jednej korporácie sa zaznamenajú konkrétny dodávateľ a príjemca, komodita, množstvo, krajina a deň. Dodávky sa zobrazujú v oboch podnikoch; nezaznamenávajú sa neuskutočnené rezervácie. Evidencia nemení výpočet dodávky ani jej cenu.
- Overenie: 20 cielených kontrol úspešných vrátane dodávok baňa–elektráreň, obchodnej trasy, zobrazenia a starého save. Tri simulované dni z rovnakého východiskového uloženia so zapnutou a vypnutou evidenciou mali po odstránení samotného denníka zhodný kompletný uložený stav vrátane RNG.
- Obmedzenie predchádzajúceho zápisu naďalej platí: hromadná burza nemá existujúci individuálny výsledok párovania. Skutočné protistrany a konečné destinácie z nej nemožno rekonštruovať; na ich získanie je potrebná zmena modelu alebo označené dopočítanie, ktoré je iba odhadom.

## 2026-10-27 – Párovanie miestneho trhu (rozpracované)

- Po dennom zúčtovaní sa podľa stabilného poradia priraďujú vykázané nákupy a predaje jednotlivých firiem na rovnakom trhu. Výsledné dvojice, množstvo, deň, ceny oboch strán a krajina sa ukladajú v obmedzenom 30-dňovom denníku; v detaile hráčovej firmy sa zobrazujú aj domácnosti a štát. Trh je sprostredkovateľ a priraďovanie prebieha po existujúcom súhrnnom výpočte, nie ako nové priame finančné zúčtovanie medzi dvoma firmami.
- Limit: zásoby a medzinárodné prenosy sú stále agregované, takže tento krok nesleduje konečnú krajinu konkrétneho výrobku po vývoze, ani nemení fyzické účtovanie skladu na individuálne zásielky. Plná implementácia zvoleného modelu párovania a výkonu ešte nie je dokončená.
- Overenie: 28 cielených kontrol úspešných, vrátane viacerých kupujúcich, domácností, súčtov, uchovávania 30 dní a trojdňového porovnania stavu so zapnutou a vypnutou evidenciou. Meranie headless 30 dní: 71,28 ms/deň bez evidencie a 63,16 ms/deň s evidenciou v tomto poradí; poradie a rozptyl zahrievania nedovoľujú tvrdiť, že evidencia hru zrýchlila. Výkon pri vykresľovaní ani zlepšenie využitia CPU neboli overené.

## 2026-10-27 – Záznam medzinárodných presunov

- Denník trhov zaznamenáva reálne presuny spoločných zásob medzi dvoma krajinami a obidve strany skutočného obchodu obchodnej firmy s trhom vrátane dňa, komodity, množstva a cien. Pôvod konkrétnej firmy v spoločnej trhovej zásobe sa týmto neurčuje.
- Overenie: 31 cielených kontrol vrátane porovnania troch dní simulácie a samostatného merania presunu SK → CZ podľa skutočne zmenených zásob, úspešne. Časť detailnej evidencie individuálneho pôvodu cez spoločné zásoby a viacjadrová optimalizácia zostávajú rozpracované.

## 2026-10-27 – Výpočet vzdialeností na pozadí

- Vzdialenosti medzi krajinami sa predpočítajú z nemenných súradníc na najviac štyroch pracovných úlohách, pričom sa ponechá aspoň jedno logické jadro pre ostatné časti hry. Kým výpočet nie je hotový, doprava používa pôvodný výpočet; výsledky sa nemajú meniť. Atlas a limit 60 FPS zostávajú zachované.
- Overenie: 33 cielených kontrol úspešných; 495 dvojíc vzdialeností presne zhodných s pôvodnou funkciou a trojdňový stav simulácie po vypnutí a zapnutí evidencie zhodný. Samostatné headless meranie 20 000 výpočtov: pôvodná funkcia 31,90 ms, cache 22,26 ms. Meranie 30 dní: 62,26 ms/deň bez evidencie a 65,31 ms/deň s evidenciou; kolísanie a rozdielny stav zahriatia neumožňujú garantovať zlepšenie FPS. Väčšina simulácie stále beží na hlavnom vlákne a dlhšie záťaže notebooku a jednotlivé snímky neboli týmto meraním overené.

## 2026-10-27 – Uvoľnenie starých záznamov trhu

- Trhový denník odstráni záznamy staršie ako 30 herných dní aj v deň bez nových obchodov. Overenie: 34 cielených kontrol úspešných vrátane prázdneho dňa, starého uloženia a porovnania simulácie.

## 2026-10-27 – Overenie detailov podnikov

- Doplnené cielené kontroly, že existujúci detail továrne/elektrárne skutočne obsahuje záznamy dodávok a že detail obchodnej firmy obsahuje obchodné presuny a maržu. Spolu 36 cielených kontrol úspešných; vizuálny test vykreslenia ani plynulosti tým nie je nahradený.

## 2026-10-27 – Korporácia v prehľade obchodu

- Pri konkrétnom obchodnom partnerovi sa pri dostupnej príslušnosti zobrazuje okrem firmy aj meno jej korporácie. Ide len o zobrazenie existujúcich údajov; neznámy spoločný trh zostáva označený ako trh.
- Overenie: 37 cielených kontrol úspešných vrátane názvu korporácie, porovnania stavu simulácie a presnosti vzdialeností.

## 2026-10-27 – Chýbajúce ikony komodít

- Pridaných 28 nových 32 × 32 PNG ikon komodít v pixelovom štýle; existujúce ikony podnikov sa nemenili. Ponuka stavby a detail firmy zobrazujú ikony vstupov a výstupov s názvom a jednotkou pri podržaní myši. Načítané obrázky sa opakovane využívajú z cache; stav uloženia hry sa nemení.
- Overenie pred zmenou: 37 cielených kontrol toku tovaru úspešných. Po zmene: 7 cielených kontrol pokrytia všetkých komodít, rozmerov, cache a výstupov UI úspešných; GUI kontrola 55 typov aj prítomnosti ikon v ponuke a detaile úspešná. GUI test pri ukončení vypísal varovanie o 66 zostávajúcich inštanciách ObjectDB; príčina ešte nebola overená. Ukážka ikon je v tests/goods_icon_preview.png.

## 2026-10-27 – Aktualizácia ikon po výbere stavby

- Pri výbere podniku z ponuky stavieb sa teraz spolu s vybraným druhom aktualizujú aj ikony komodít a nápoveda. Pred úpravou prešlo 7 cielených kontrol ikon a GUI skúška; po úprave prešla GUI skúška aj pri prepnutí banka → kaviareň cez ponuku stavieb. Pri ukončení testu pretrváva upozornenie na 66 inštancií ObjectDB.

## 2026-10-27 – Sadzby existujúcich bankových úverov

- Nové spotrebiteľské, hypotekárne a firemné úvery si ukladajú dohodnutú úrokovú sadzbu; zmena sadzby pre nové úvery už nemení výpočet úrokov a splátok už existujúcich zmlúv. Pri starých uloženiach v3 bez tejto položky sa pri najbližšej mesačnej uzávierke použije aktuálna sadzba banky a následne sa uloží. Súhrnné denné NPC úvery sú naďalej samostatný existujúci model s premenlivou sadzbou.
- Rovnováha: zmena sadzby teraz ovplyvňuje postupne poskytované nové úvery, nie okamžite celé portfólio; budúce výnosy a riziko sa preto môžu vyvíjať pomalšie. Zobrazenie banky tento rozdiel vysvetľuje.
- Pred zmenou úspešne prešlo 17 bankových kontrol; po zmene 22 cielených kontrol vrátane sadzieb starých a nových úverov, spotrebiteľského úveru a načítania save v3. Bankový poradca a štátne pôžičky zatiaľ nie sú dokončené.

## 2026-10-27 – Riziko existujúcich spotrebiteľských úverov

- Pri odhade nesplácania konkrétneho spotrebiteľského úveru sa zohľadní sadzba jeho zmluvy, nie nová sadzba banky. Ostatné faktory rizika sa naďalej vyvíjajú podľa stavu krajiny; hypotéky a firemné úvery majú zatiaľ svoje pôvodné súhrnné výpočty rizika.
- Rovnováha: zmena ponukovej sadzby už okamžite nemení časť rizika existujúcich spotrebiteľských úverov. Pred zmenou prešlo 22 bankových kontrol, po zmene 23 cielených kontrol vrátane rôznych sadzieb a kompatibility save v3.

## 2026-10-27 – Riziko hypoték a firemných úverov

- Mesačné riziko nesplácania hypotéky a firemného úveru sa počíta podľa dohodnutej sadzby konkrétnej zmluvy. Zmena sadzby nových úverov tak okamžite nemení tento faktor pri starších zmluvách; nezamestnanosť a ďalšie podmienky krajiny sa naďalej zohľadňujú.
- Zmena môže postupne upraviť straty banky pri rozdielnych historických sadzbách. Pred úpravou prešlo 23 cielených bankových kontrol, po úprave 25 vrátane oboch typov zmlúv a starého uloženia.

## 2026-10-27 – Bankový poradca

- Hráč môže v detaile banky najať alebo prepustiť poradcu za 3 500 € mesačne. Plat sa odpočítava z rezerv aj vlastného kapitálu a zobrazuje v mesačných nákladoch; pri nedostatku rezerv poradca odíde. Záznam posledných 24 rozhodnutí sa ukladá k banke a detail ukazuje posledných päť. Staré save v3 bez poradcu zostávajú platné.
- Poradca mesačne nastavuje vkladové a úverové sadzby, prísnosť podľa nezamestnanosti a politického rizika a cieľ rezerv minimálne podľa zákona. Jeho pravidlá pri nových úveroch zohľadňujú rezervy, sporenie a konzervatívny kapitálový limit. Manuálna zmena hráčom má prednosť 30 dní, po ktorých poradca pokračuje. Schvaľovanie je zatiaľ na úrovni súhrnného modelu úverov, nie individuálnych žiadostí; štátne úvery a ich limity ešte nie sú implementované.
- Rovnováha: poradca účtuje reálny plat a môže obmedziť objem nových úverov; vyššia prísnosť a rezervy môžu znížiť straty aj príjmy. Zisk nie je garantovaný. V jednom 120-dňovom scenári s počiatočným kapitálom 10,5 mil. € vzrástol kapitál na 10 523 821,05 €.
- Overenie: pred úpravou 25 cielených bankových kontrol úspešných; po úprave 20 kontrol poradcu, 25 regresných bankových kontrol a GUI skúška najatia a prepustenia úspešné. Pri skončení GUI skúšky pretrváva predchádzajúce upozornenie na 66 inštancií ObjectDB.

## 2026-10-27 – Štátne úvery hráčovej banky

- Banka môže poskytnúť vybranému štátu úver s hráčom zadanou sumou, ročnou sadzbou a splatnosťou 1–120 mesiacov. Minimálna sadzba vychádza z dlhu/HDP, stability a politického rizika. Poskytnutie rešpektuje rezervy a kapitál banky; pohľadávka je v jej bilancii a kapitálovom limite.
- Štát mesačne spláca istinu a úroky; príslušne sa mení jeho dlh/HDP a mesačný rozpočet. Zriedkavý default závisí od rizika krajiny, banka získa späť polovicu nesplatenej istiny a druhú polovicu odpíše ako stratu. Stav zmlúv sa ukladá v save v3; starý save bez zmlúv používa prázdny zoznam.
- Poradcovi možno povoliť pôžičky zvolenej krajine s hráčom nastaveným maximálnym rizikom, podielom kapitálu a splatnosťou. Úvery a rozhodnutia sú v detaile banky. Štáty sú zatiaľ zastúpené agregovaným modelom dlhu a rozpočtu; neprebieha individuálne vyjednávanie ani explicitná simulácia štátnych príjmov na úhradu každej splátky.
- Rovnováha: štátne úvery prinášajú úroky, obsadzujú rezervy a kapitál, vytvárajú štátny dlh a môžu spôsobiť 50 % stratu nesplatenej istiny pri defaulte. Zisk nie je garantovaný.
- Overenie: pred úpravou úspešných 25 bankových a 20 kontrol poradcu. Po úprave 18 cielených kontrol štátnych úverov a 25 regresných bankových kontrol, všetky úspešné; GUI skúška poskytnutia úveru a uloženia limitov poradcu prešla. Pred úpravou kapitálovej primeranosti prešlo aj 20 regresných kontrol poradcu. GUI test pri ukončení stále hlási 66 inštancií ObjectDB.

## 2026-10-27 – Kalendárna uzávierka štátnych úverov

- Rozšírené cielené overenie mesačnej uzávierky: pri prechode mesiaca sa skutočne spláca štátny úver, úrok vstupuje do grafu banky a povolený poradca poskytne ďalší úver v medziach nastavení. Všetkých 21 kontrol štátnych úverov prešlo.

## 2026-10-27 – Úplnejšia kapitálová primeranosť banky

- Do rizikovo vážených aktív sa započítavajú aj súhrnné úvery NPC a explicitné úvery, nielen spotrebiteľské, hypotéky, firemné a štátne úvery. Tým sa neprehliada časť existujúceho úverového portfólia; poradca a štátne úvery rovnakú položku nezapočítavajú dvakrát.
- Rovnováha: banka s veľkým existujúcim úverovým portfóliom môže dosiahnuť kapitálový limit skôr, čo obmedzí ďalšie úvery. Pred zmenou prešlo 25 bankových kontrol; po zmene 26 bankových a 21 kontrol štátnych úverov, všetky úspešné.

## 2026-10-27 – Kapitálový limit aj bez poradcu

- Kapitálový limit pri nových denných, spotrebiteľských, hypotekárnych a firemných úveroch platí aj pre banku bez najatého poradcu. Výpočet započítava existujúce rizikovo vážené portfólio a nedovoľuje poskytnutím nových úverov prekročiť limit.
- Rovnováha: slabšie kapitalizované banky môžu poskytovať menej nových úverov a ich výnosy môžu byť nižšie; obmedzenie znižuje ďalšie prehlbovanie rizika. Pred úpravou prešlo 26 cielených bankových kontrol; po úprave 27 bankových a 20 kontrol poradcu vrátane 120-dňového scenára, všetky úspešné.

## 2026-10-27 – Audit počtu zamestnancov

- V docs/EMPLOYEE_AUDIT_20261027.md je tabuľka aktuálnych pracovných jednotiek a predbežných počtov pre všetkých 55 druhov podnikov, plus návrh pre bankovú pobočku. Ide o prípravu, ktorá nemení hru; počty ešte neboli zavedené ani vyvážené.
- Zistenie: súčasná hodnota labor naraz ovplyvňuje počet zamestnancov, mzdy aj obsadenosť. Jednoduché navýšenie by násobne zmenilo náklady a následne výrobu a trhové ceny. Migrácia starých save musí zachovať percento obsadenosti a nesmie sa vykonať opakovane. Nevykonávali sa herné testy, keďže sa menila iba dokumentácia.

## 2026-10-27 – Oprava prehľadu zamestnancov

- Celkový počet zamestnancov aj podiel pracovných miest v krajine teraz pri novej firme bez výslovne uloženej hodnoty používajú rovnaký predvolený počet ako detail firmy a simulácia. Výslovne uložená nula alebo čiastočná obsadenosť zostáva zachovaná.
- Rovnováha: podiel zamestnancov vo výpočte závislosti krajiny sa môže po založení firmy zobraziť vyšší, pretože predtým až do prvej mesačnej uzávierky počítal nulu. Samotná výroba, mzdy a recepty sa touto opravou nemenia; realistické počty z auditu ešte nie sú zavedené.
- Pred zmenou 22 cielených kontrol fondu úspešných; po zmene 6 cielených kontrol predvoleného, nulového a čiastočného stavu, podielu v krajine a save v3 úspešných.

## 2026-10-27 – Štátne pôžičky v závislosti krajiny

- Výpočet závislosti krajiny zohľadňuje aj zostávajúcu istinu úverov, ktoré hráčove banky poskytli priamo tomuto štátu. Úver sa priradí krajine dlžníka aj vtedy, ak je banka založená inde; nezapočítava sa druhej krajine.
- Rovnováha: štátna pôžička môže zvýšiť existujúci index závislosti príjemcu, ktorý má v hre ďalšie následky. Samostatný požadovaný panel politickej moci a lobingu tým ešte nie je dokončený.
- Pred zmenou prešlo 6 cielených kontrol zamestnanosti; po zmene 8 kontrol, vrátane pôžičky z českej banky Slovensku a správneho priradenia krajinám.

## 2026-10-27 – Cache konkurencie pri vyúčtovaní

- Pri vyúčtovaní sa počty otvorených firiem podľa krajiny a odvetvia pripravia raz za deň namiesto opakovaného prechádzania všetkých firiem pri každom lokálnom predaji. Mimo vyúčtovania sa zachová pôvodný výpočet. Zatvorené firmy a prevádzky v inej krajine sú zohľadnené rovnako ako predtým.
- Pred úpravou prešli cielené kontroly toku tovaru vrátane porovnania simulácie; po úprave prešli 4 cielené kontroly vrátane porovnania celého uloženého stavu po troch dňoch so zapnutou a vypnutou cache, so zhodným výsledkom. Pri 2 000 volaniach v scenári s 24 firmami: pôvodný výpočet 69,29 ms, cache 4,50 ms. Nie je to meranie celej snímky ani záruka 60 FPS.

## 2026-10-27 – Meranie celého dňa po cache konkurencie

- Opakované porovnanie troch dní pri rovnakom štartovom stave a 24 hráčových firmách: pôvodný výpočet 97,73 ms/deň, s cache 97,64 ms/deň. Ide o krátke headless meranie v pevnom poradí, bez kontroly kolísania záťaže; preukazuje zhodný výsledný stav, nie spoľahlivý celkový nárast FPS. Samotných 2 000 výpočtov konkurencie trvalo 65,15 → 4,86 ms. Štyri cielené kontroly prešli.

## 2026-10-27 – Rozdelenie medzinárodných trás po komoditách

- V priebežnej simulácii sa trasy spracúvajú v pôvodnom poradí po troch komoditách; synchronická simulácia zachováva pôvodné celé volanie. Dokončenie rozpracovaného dňa pred uložením a vstupom hráča ostáva zachované.
- Päť cielených kontrol prešlo: rozdelenie fázy, zhodný celý stav po troch dňoch so seedom 47 vrátane denníka, a dokončenie rozpracovaného dňa. V headless profile 72 hráčových firiem, 10 dní, trasa pred úpravou priemerne 9,85 ms a maximum 16,26 ms na jedno volanie; po rozdelení priemer 0,65 ms a maximum 1,43 ms na čiastkové volanie. Ostatné fázy sa v týchto meraniach menili so záťažou; pred úpravou bol zaznamenaný aj jeden 23,17 ms výkyv inej fázy. Toto nie je meranie kompletnej grafickej snímky ani dôkaz stabilných 60 FPS.

## 2026-10-27 – Rozdelenie plánovania podnikov

- Denné plánovanie a vystavovanie ponúk sa v priebežnej simulácii vykonáva v pôvodnom poradí po štyroch firmách. Príprava vnútropodnikových dodávok zostáva pred plánovaním; synchronická simulácia prejde všetky firmy v jednom volaní.
- Sedem cielených kontrol prešlo: porovnanie úplného stavu po troch dňoch so seedom 47, rozdelenie oboch fáz a dokončenie rozpracovaného dňa pri plánovaní aj pri obchodných trasách. V headless profile 72 firiem a 10 dní malo samotné plánovanie pred úpravou priemerne 4,65 ms a maximum 5,70 ms na volanie; po úprave priemerne 0,19 ms a maximum 0,38 ms na čiastkové volanie. Príprava vnútorných dodávok sa teraz meria v predchádzajúcej fáze, ktorej maximum bolo 12,07 ms. Ide o čas fáz, nie kompletné snímky; stabilných 60 FPS stále nie je preukázaných.

## 2026-10-27 – Rozdelenie aktualizácie trhových kapacít

- Aktualizácia referenčnej kapacity trhu prebieha v pôvodnom poradí po 12 krajinách. V synchronických volaniach zostáva dostupné spracovanie všetkých krajín naraz.
- Osem cielených kontrol prešlo vrátane porovnania trhových kníh pri celom a delenom výpočte a celého stavu po troch dňoch. V headless profile so 72 firmami a 10 dňami mala táto fáza pred zmenou priemer 5,76 ms a maximum 10,01 ms na volanie; po rozdelení priemer 0,42 ms a maximum 0,95 ms na čiastkové volanie. Profil nemeria celú grafickú snímku ani dlhodobejšie zaťaženie notebooku.

## 2026-10-27 – Krok 1: Realistické počty zamestnancov
- Každý recept má nové pole `staff` = počet ľudí pri úrovni 1 (napr. kaviareň 8, automobilka 1 000, jadrová elektráreň 700, rafinéria 650, nákladný prístav 1 200, pobočka banky 25). Tabuľka starých a nových hodnôt je v docs/EMPLOYEE_COUNTS_20261027.md.
- `labor` ostáva ekonomická pracovná jednotka, takže mzdové náklady, výroba, recepty a save v3 sa nemenia; zachová sa aj obsadenosť (ľudia = cieľ × workers / target_workers). Detail firmy, Portfólio, horný pruh a závislosť krajiny ukazujú skutočných ľudí. Zobrazená mzda je celkový mzdový náklad; mzda na osobu je v hernej mierke nižšia ako v realite (plné prepočítanie by vyžadovalo zmeniť celý trhový model).
- Aktualizovaný test tests/employment_stats.gd na nové počty (8 kontrol OK).

## 2026-10-27 – Krok 2: Moc a vplyv, lobing, zákony
- Nový autoload scripts/autoload/Society.gd. Moc v krajine 0–100 %: HDP tvojich firiem (25 b.), pracovné miesta (20), dosah médií (15), štátne úvery tvojich bánk (15), lobing a vzťahy (25, existujúci vplyv z PoliticsSystem). Vlastnený štát = 100 %. Prepočet raz mesačne a pri otvorení panelu.
- Lobing konkrétnych politikov (líder vlády, ministri, šéfovia frakcií, poslanci podľa strán krajiny): peniaze zvyšujú lojalitu, vplyv rastie postupne každý mesiac, lojalita vyprcháva. Mesačné riziko škandálu podľa výdavkov a typu vlády: pokuta, vplyv −10, reputácia −5.
- Klik na krajinu: panel „MOC A VPLYV“ (percento, rozpad zdrojov, lobovaní politici, odomknuté akcie). Nad 50 % = kontrola: zákony daňová úľava (×0,75 pre tvoje firmy v krajine), dotácie (1,5 % tržieb mesačne), rýchle povolenia (stavba −15 %), vládne zákazky (mesačná platba podľa HDP), voľné nasadenie PMC.

## 2026-10-27 – Krok 3: PMC, gangy a kriminalita
- PMC: vojaci = zamestnanci (150 na úrovni 1), 1 jednotka = 10 vojakov, výcvik a vybavenie 0–100 (platené vylepšenie, mesačne mierne klesá), mesačné náklady nasadenia. Nasadenie do mesta len pri kontrole nad 50 % alebo s vládnou bezpečnostnou zmluvou (cena za jednotku, trvanie, max. jednotiek; vláda prijme do limitu podľa kriminality a vplyvu, inak dá protinávrh). Zmluva mesačne platí PMC.
- Každé mesto má kriminalitu 0–100 (nezamestnanosť, chudoba, slabé inštitúcie, veľkosť mesta, vzdelanie) a 1–3 procedurálne gangy (meno, sila, územie). Mesačné udalosti pre tvoje firmy: krádež, vydieranie, sabotáž, útok na zamestnancov (škoda, nižšia spokojnosť, odchod ľudí). PMC znižuje šancu udalostí, silu a územie gangov. Bez boja, len abstraktne. Orgány/otroctvo len ako zriedkavý satirický text v denníku.

## 2026-10-27 – Krok 4: Spokojnosť zamestnancov
- Každá tvoja firma má spokojnosť 0–100 (mesačne): základ, pravá ruka, kriminalita mesta (znižuje PMC ochrana), nemocnica/klinika +8, poisťovňa +6, PMC +5, všetky tri +6 navyše, škola +4, akadémia +5, nedávny útok −10. Výhody majú skutočné, ale zľavnené náklady (3 / 2 / 1,5 % mzdového nákladu). Výkon ×0,8–1,2; pod 50 rastie fluktuácia (bez pravej ruky odchádzajú ľudia, s pravou rukou platíš nábor).
- Zobrazenie v detaile firmy (hodnota, príčiny, náklady benefitov) a v paneli mesta (priemer, výhody). Nová nemocnica (Súkromná nemocnica, 600 ľudí).

## 2026-10-27 – Krok 5: Nákladné prístavy
- Nový typ Nákladný prístav (9 mil. €, 1 200 ľudí) len pri prímorskom alebo riečnom meste (data/port_cities.json: pobrežie odvodené z polygónov mapy + ručne doplnené prístavy, napr. Bratislava, Hamburg, Rotterdam; odhad). Kapacita 20 000 TEU/mes. (+25 % pri napojení na železnicu/potrubie), poplatky z tovaru tvojho aj konkurencie, tvoje firmy v krajine majú o 20 % lacnejšiu dopravu tovaru, infraštruktúra krajiny +1 % za úroveň (max +3 %). Ikona na Atlas mape a v Portfóliu.

## 2026-10-27 – Krok 6: Súkromné školy
- Len súkromné: základná škola, stredná škola, univerzita, firemná akadémia. Školné nastavuje majiteľ (vyššie = menej žiakov), štátna dotácia 5–10 % nákladov na žiaka podľa tvojho vplyvu. Učitelia/personál 45 / 70 / 650 / 30, kapacita 400 / 600 / 6 000 / 300.
- Vzdelanie mesta 0–100 pomaly rastie podľa vážených žiakov; zvyšuje produktivitu firiem v meste, od 55 odomkne kvalifikované miesta (+5 % pre tech/energetiku) a znižuje kriminalitu. Akadémia +4 % produktivity a +5 spokojnosti v meste, univerzita +3 % (max +9 %) pre tech, AI a energetické firmy v krajine, škola +4 spokojnosti. Vzdelanie v paneli mesta, školy na Atlas mape a v Portfóliu.
- Služby (nemocnica, prístav, školy) nepoužívajú burzu: denné mzdy, nájom, údržba a elektrina; príjem sa prepočíta raz za mesiac. AI štátne firmy a rivali ich nezakladajú (správanie NPC sa nemení).

## 2026-10-27 – Krok 7: Ikony nových podnikov
- Pridané 32×32 ikony cargo_port, hospital, school_primary, school_high, university, corp_academy v rovnakom štýle (rámik a tieň z port.png, prechod farby, biely glyf, farebný pruh). Generátor scripts/generate_service_icons.py neprepisuje existujúce súbory. Pôvodné ikony (aj PMC) sa nemenili.

## 2026-10-27 – Overenie
- Podľa limitu najviac 50 testov spolu: 29 cielených kontrol tests/society.gd (29 OK), 8 kontrol zamestnanosti (8 OK), 1 GUI skúška panelov (detail firmy, škola, PMC, Moc a vplyv, mesto, Portfólio, ikony – OK), stabilita 1/30/365 dní (OK, NaN 0, inband 1,000), 1 porovnanie rovnováhy so starou verziou. Úplná sada a sonda sa nespúšťali (golden sonda je zastaraná).
- Rovnováha (SK, seed 47, 5 firiem, 120 dní): hotovosť hráča 29 824 158 → 29 816 731 €, tržby firiem −1,3 % (spokojnosť/kriminalita), NPC firmy a ceny zhodné, 44,8 → 43,8 ms/deň.

## 2026-10-27 – AI stavia služobné podniky samo (JUAN-P47)
- Nové: `Society.ai_monthly()` (raz mesačne v `Society.monthly`, žiadna práca za snímku). AI konkurenti (napr. Danubia Holding) aj štátne firmy stavajú nemocnice, prístavy, súkromné školy, univerzity, firemné akadémie, poisťovne a PMC **nezávisle od hráča**.
- Pravidlá: prístav len v meste z `port_cities.json` (max 1 + HDP/400 mld €, najviac 3 na krajinu, 1 na mesto); univerzita len v meste ≥ 500 tis. obyv. (1 na mesto); nemocnica v meste ≥ 200 tis. (1 + pop/1 mil. na mesto, ráta aj kliniky); ZŠ/SŠ v meste ≥ 100 tis. (1 + pop/300 tis. na typ); akadémia len keď má konkurent ≥ 3 firmy v krajine; poisťovňa 1 a PMC 1 na konkurenta a krajinu (PMC len pri kriminalite ≥ 40).
- Rozpočet: konkurent stavia len z vlastnej hotovosti s rezervou 30 % (cena × 1,3), max 1 podnik mesačne (šanca 35 % × agresivita), max 5 služobných podnikov spolu. Štát: len nemocnica a prístav (školy sú iba súkromné), 18 krajín ako pri štátnych AI firmách, šanca 12 %/mesiac, max 2 na krajinu, cena ≤ 0,05 % HDP.
- Odstránené: konkurent už nekopíruje hráčov služobný podnik cez `RivalSystem.found_for` (tam sa ignoruje), takže neexistuje podmienka „až keď to postaví hráč“.
- Školy konkurencie zvyšujú vzdelanie mesta (`city_services` ráta aj ich študentov); výhody spokojnosti (nemocnica/poisťovňa/PMC) dáva naďalej len vlastná firma.
- Save v3: nové firmy sú bežné záznamy v `firms` (+ voliteľné kľúče `city`, `ai_svc`, `state_svc`); staré savy fungujú.
- Test (seed 47, SK, konkurenti zapnutí, 365 dní): AI postavila 21 služobných podnikov – štát 11 nemocníc + 6 prístavov, konkurenti 3 SŠ + 1 akadémia. Konkurenti majú malú hotovosť (3 mil. € a ich pokladnica nerastie), preto zatiaľ nestavajú drahé nemocnice/univerzity.
- Výkon: rozhodovanie AI spolu ~7 ms za celý rok; beh 365 dní 43–44 ms/deň s AI aj bez nej (rozdiel v šume merania).
- Kontroly: 9 cielených (prístavy len v prístavných mestách, univerzita len vo veľkom meste, štát bez škôl, limity/rozpočet, niečo postavené, save/load) – všetky OK.

## 2026-10-27 – príjem AI konkurentov (JUAN-P47)
- `RivalSystem.profit_share()` (mesačne v `RivalSystem.monthly`): 50 % čistého zisku každej firmy konkurenta za posledných 30 dní sa presunie z pokladnice firmy do rozpočtu konkurenta; pri strate rozpočet doplní firmu 50 % straty (rozpočet nikdy pod 0). Navyše holding stiahne polovicu hotovosti firmy nad prevádzkovou rezervou (25 % ceny podniku, min. 90 tis. €). Peniaze sa nevytvárajú, len presúvajú.
- Nové voliteľné polia konkurenta `income_month`, `income_total` (predvolene 0) – save v3 kompatibilný, staré savy bez nich fungujú.
- `Society._rival_build`: max 2 podniky rovnakého typu na konkurenta; po 2 lacných službách (školy, akadémia, poisťovňa, PMC) už konkurent šetrí len na nemocnicu/univerzitu/prístav. Ostatné limity bez zmeny (5 služieb, 1 mesačne, rezerva 30 %, MAX_FIRMS 6).
- Beh seed 47, SK, 1095 dní: príjem konkurentov za 1. rok len 0–0,24 mil. € (hotovosť idú najprv do bežných firiem), za 3 roky 2,6–6,9 mil. €. Danubia Holding skončila so 7,42 mil. € (nemocnica potrebuje 7,8 mil. € s rezervou), takže drahú nemocnicu/univerzitu by postavila až zhruba v 4. roku. Univerzitu na Slovensku nepostaví, lebo Bratislava má < 500 tis. obyvateľov.
- Výkon: 44 ms/deň ako predtým, rozhodovanie AI ~23 ms za 3 roky.
- Kontroly: 10 (rozpočet nikdy pod 0 ×2, limity ×2, starý save bez nových polí, save/load) – všetky OK.

## 2026-10-27 – presúvateľné a zväčšiteľné okná (JUAN-P47)
- Nový spoločný pomocník `scripts/ui/window_drag.gd` (uzol `WindowDrag` v main): okno sa presúva ťahaním za titulný pruh (horných 40 px), zväčšuje/zmenšuje ťahaním za okraje alebo roh (úchyt vpravo dole), má min. veľkosť, drží sa na obrazovke (aj po zmene veľkosti okna hry), kliknuté okno ide navrch. Žiadna práca za snímku – len udalosti myši.
- Zaregistrované okná: detail firmy/banky, mesto, krajina (závislosť + MOC A VPLYV), Burza, Portfólio, DEV panel. Infraštruktúra nie je okno (prepínač vrstvy mapy), bočný panel je ukotvený.
- Detail firmy, mesto a krajina majú teraz pevný titulok a posuvný obsah (ScrollContainer), takže sa dajú zmenšiť.
- Poloha/veľkosť sa pamätá podľa typu okna počas relácie a v nastaveniach `user://ui_windows.cfg` – nie v save v3.
- Oprava: spodný riadok v okne krajiny (politik + suma + Lobovať, aj riadok zmluvy PMC) je HFlowContainer a pri úzkom okne sa zalomí; zoznam politikov/PMC orezáva dlhý text, tlačidlá firiem tiež.
- Test (xvfb, 1280×720): 10 kontrol – riadok sa zmestí, aj v úzkom okne, presun, zmena veľkosti rohom, min. veľkosť, orezanie na obrazovku, zápis/čítanie nastavení, všetky okná majú posuv, screenshot `preview/p47_windows_country.png` – OK; „pamäť po zatvorení/otvorení“ zlyhala (uvoľnenie tlačidla mimo okna sa nezapísalo). Opravené (poloha sa ukladá už počas ťahania, ukladá sa aj pri zatvorení), ale znovu netestované – limit 10 testov vyčerpaný.


## 2026-10-28 – Úvodný audit hrateľnosti a UI

- Na GitHube vytvorená vetva `codex/audit-ux-20261028` z main `88849d621ee983c4b9c26f9777e8aa78d6941a95`; prvotné nálezy s prioritami boli oznámené pred opravami a sú uložené v `docs/AUDIT_UX_20261028.md`.
- Čítaním aktuálneho kódu overené riziko vnútorných dodávok bez konkrétneho dodávateľa a doplnené riziko neaktuálnych polí nastavení pri činnosti bankového poradcu. Nálezy vyžadujú reprodukciu a overenie; herný kód ani grafika v tomto kroku zmenené neboli.
- Nové testy ani merania zatiaľ neboli spustené. Predchádzajúce výsledky z `docs/PERFORMANCE_AUDIT_20261027.md` pochádzajú z iného východiskového commitu a nepreukazujú stav novej vetvy. Na GitHube zatiaľ nebol nájdený pripravený workflow ani uložený spúšťač Godot testov.


## 2026-10-28 – Kontrola limitu uložených hier

- Do `docs/AUDIT_UX_20261028.md` pridaný staticky zistený rozdiel: ukladanie neoveruje 64 MiB limit, ktorý neskôr uplatňuje načítanie; navyše doterajšia kontrola zápisu porovnáva znaky a nie bajty. Oprava ani reprodukcia v Godote zatiaľ neprebehla. Herný kód a existujúce savy sa nemenili.


## 2026-10-28 – Vzdialený testovací beh na GitHube

- Na auditnej vetve pridaný GitHub Actions workflow pre existujúce `unit`, `audit_unit`, `stability 1 30 365` a `performance_audit`. Beží na oddelených Linux runneroch s Godotom 4.7.2 z oficiálneho vydania, overeným SHA-256, a používa samostatné dočasné používateľské dáta. Herné súbory sa nemenili.
- Prvá verzia workflow zlyhala pred spustením úloh pre chybný kontext ciest runnera; konfigurácia bola opravená. Beh 40652483767 sa už spustil, výsledky zatiaľ nie sú uzavreté. Toto nie je grafické overenie cez Xvfb ani meranie FPS na notebooku.


## 2026-10-28 – Ochrana pred príliš veľkým savom (overovanie prebieha)

- Ukladanie pred zápisom kontroluje rovnaký limit 64 MiB v UTF-8 bajtoch ako načítanie. Pri prekročení vráti chybu ešte pred vytvorením dočasného súboru, takže predchádzajúci slot ostane zachovaný. Formát v3 ani pravidlá hry sa nemenia.
- Pridané štyri cielené regresné kontroly hranice viacbajtového textu, úspešného uloženia, odmietnutia veľkého stavu a zachovania slotu. GitHub Actions beh po zmene ešte musí potvrdiť výsledok; záznam sa po dokončení aktualizuje.


## 2026-10-28 – Výsledky ochrany saveu

- GitHub Actions na commite `dee8a650c4eb5873bde77b6f01d94ef5dd3d611e`: `audit_unit` 28 OK / 0 FAIL, vrátane štyroch nových kontrol veľkého saveu; stabilita 1, 30 a 365 dní prešla. Úplná sada `unit` v čase zápisu ešte beží. Pred opravou audit_unit aj stabilita prešli; úplná sada mala 531 OK / 1 FAIL kvôli chýbajúcej referencii katalógu a navyše tri runtime chyby testov mapy mimo stromu.
- Headless benchmark 100 dní, 72 hráčových firiem: pred 87,79 ms/deň, po 77,65 ms/deň; jednotlivé vzdialené runnery majú rôznu záťaž, preto výsledok nedokazuje celkové zrýchlenie ani výkon notebooku. Beh: https://github.com/Wondris404/Projekt-47/actions/runs/40652812617.


## 2026-10-28 – Mapa vytvorená mimo stromu scény (overovanie prebieha)

- `WorldMap._ready` kontroluje existenciu okna pred pripojením signálu straty fokusu. Bežný pripojený viewport používa rovnaký postup ako predtým; vzhľad, kamera aj herné pravidlá sa nemenia.
- Pred opravou úplná sada na GitHube: 531 OK / 1 FAIL (chýbajúca referencia katalógu) a tri chyby `focus_exited` pri testoch mimo stromu. Pridaná jedna cielená kontrola a CI kontrola výpisu `SCRIPT ERROR`; výsledok po oprave ešte musí dobehnúť.


## 2026-10-28 – Priebežné overenie kontroly okna mapy

- GitHub Actions pre commit `bdbdc442094361c8741c47741b5a88b4ba138b24`: `audit_unit` 29 OK / 0 FAIL vrátane vytvorenia mapy mimo stromu a kontroly výpisu GDScript chýb; stabilita 1, 30 a 365 dní prešla. Úplná `unit` sada pri tomto zápise ešte beží.
- Headless výkonnostná sonda 100 dní na 72 firmách: 62,52 ms/deň; predchádzajúce behy na iných cloudových runneroch namerali 87,79 a 77,65 ms/deň. Rozdiel môže byť záťažou runnera a nedokazuje zrýchlenie ani FPS na notebooku. Prvá úprava kontroly chybového výpisu mala chybné formátovanie workflow, opravené v samostatnom commite pred týmto behom.
- Vyhľadanie `tests/catalog_field_lock.txt` v troch ďalších vetvách ani v histórii tohto súboru na main nevrátilo referenciu. Aktuálny katalóg nebol použitý na vytvorenie novej referencie.


## 2026-10-28 – Výsledok úplnej sady po oprave mapy

- GitHub Actions `40653443499` na kóde `bdbdc442094361c8741c47741b5a88b4ba138b24`: `unit` 531 OK / 1 FAIL (`catalog_fields_match_brief`, chýbajúca referencia). Predchádzajúce tri `SCRIPT ERROR` pri vytvorení mapy mimo stromu sa v samotnom teste už nevyskytli. `audit_unit` 29 OK, stabilita 1/30/365 prešla, výkonnostná sonda dokončená; celý workflow ostáva červený kvôli testu katalógu.
- V priebehu importu čerstvej kópie Godot vypisuje chyby o zdrojoch, ktoré ešte nie sú importované; treba ich samostatne preveriť. Výsledok nepovažovať za úplne čistý beh ani za vizuálnu kontrolu hry.


## 2026-10-28 – Vzdialené grafické meranie

- Pridaný samostatný GitHub Actions workflow pre východiskové snímky Atlasu cez Xvfb a Mesa softvérové vykresľovanie. Používa existujúci `atlas_visual_audit`, nový tag snímok a izolované dáta; do hry ani existujúcich UI ikon nezasahuje. Výsledky ukladá ako artefakty behu; pri samotných grafických úpravách bude ešte potrebné uložiť porovnania pred/po do `audit/screenshots/` v repozitári.
- Beh `40654081381` sa začal; úspech snímok, vizuálna kontrola a kompletné porovnania pred/po zatiaľ nie sú potvrdené. FPS softvérového renderera nereprezentuje výkon notebooku.


## 2026-10-28 – Východiskové snímky Atlasu

- Vzdialený beh `40654081381` skončil úspešne cez Xvfb, OpenGL a Mesa llvmpipe. Uložil 27 nových východiskových snímok v artefakte `p47-atlas-baseline`; scenáre pokrývajú kameru, dopravu a modely budov. Pri zatvorení/otvorení panelu a zmene veľkosti okna zaznamenal drift 0 px.
- Obrázky zatiaľ nie sú vizuálne posúdené ani uložené ako porovnania pred/po v repozitári. Import čerstvého projektu vypísal pred dokončením importu chyby zdrojov; samotný vizuálny beh nemal `SCRIPT ERROR`. FPS llvmpipe nie sú meraním notebooku. Beh: https://github.com/Wondris404/Projekt-47/actions/runs/40654081381.


## 2026-10-28 – Menej opakovaných testovacích behov

- GitHub Actions pre celý audit ignoruje commity meniace iba dokumentáciu alebo samostatný grafický workflow; herné a testovacie zmeny ho naďalej spúšťajú a zostáva dostupné ručné spustenie. Pred zmenou prešiel audit_unit a stabilita; úprava mení len spúšťanie workflow a po zápise sa ešte neoverilo každé pravidlo spúšťania.


## 2026-10-28 – Prenositeľný výstup testu okien

- Grafická skúška `window_ui` ukladá snímku do `audit/screenshots/window-audit/` v skúšanej kópii namiesto pevnej cesty z iného počítača; snímka má odlíšiteľný tag. GitHub Actions spúšťa existujúce kontroly presunu, veľkosti a pamäte okien cez Xvfb a ukladá výslednú snímku a log ako artefakty. Herné rozhranie a jeho správanie sa nemenili.
- Pred úpravou prešla grafická sonda Atlasu; výsledok skúšky okien na tejto verzii ešte nie je potvrdený. Artefakt treba vizuálne skontrolovať; nie je to automatické porovnanie pred/po.


## 2026-10-28 – Grafická skúška okien

- Vzdialený beh `40654635533` preveril 10 existujúcich kontrol okna krajiny: deväť prešlo, kontrola presnej polohy a veľkosti po zatvorení a znovuotvorení zlyhala. Príčina sa ešte skúma; nejde zatiaľ o potvrdenie konkrétnej chyby herného kódu. Východisková snímka a log sú uložené ako artefakty behu https://github.com/Wondris404/Projekt-47/actions/runs/40654635533.
- Test používal Xvfb a softvérové vykresľovanie, preto nepotvrdzuje vzhľad ani výkon na notebooku. Beh Atlasu prešiel, ale jeho snímky zatiaľ neboli vizuálne posúdené.


## 2026-10-28 – Diagnostika pamäte okna

- Grafický workflow do dočasnej kópie pri teste doplní výpis polohy, uloženej polohy a minimálnej veľkosti pred a po znovuotvorení okna. Zdrojový kód hry sa tým nemení. Beh `40655073099` prebieha; záver ešte nie je známy.


## 2026-10-28 – Výsledok diagnostiky okna krajiny

- Beh `40655073099` nameral pred otvorením inej krajiny obdĺžnik (940, 500; 340 × 220), rovnaký ako v pamäti. Po otvorení mal panel šírku 477 px pre minimálnu šírku obsahu; jeho pravý okraj tak presahoval viewport široký 1280 px. Deväť ďalších kontrol prešlo. Konkrétny vnútorný prvok sa ešte zisťuje; oprava zatiaľ nie je urobená.
- Nadväzujúca diagnostika vo workﬂow vypisuje aj vnútorné ovládacie prvky so širokým minimom; mení len dočasnú kópiu na runneri. https://github.com/Wondris404/Projekt-47/actions/runs/40655073099


## 2026-10-28 – Zalomenie správy v paneli krajiny

- Diagnostika `40655287108` ukázala, že minimálnu šírku 449 px vytvoril text v krajine bez hráčových firiem. Správa sa teraz zalamuje, aby nevyžadovala široký panel. Herné pravidlá, dáta ani existujúce ikony sa nemenia.
- Grafický workflow bol rozšírený o snímku znovuotvoreného panelu a automatické spustenie po zmene hlavného UI. Overenie po oprave a porovnanie snímok ešte prebieha; nie je potvrdené, že oprava funguje.


## 2026-10-28 – Overenie panelu krajiny po oprave

- V grafickom behu `40667390401` prešlo všetkých 10 existujúcich kontrol. Po otvorení inej krajiny zostal panel na (940, 500) s veľkosťou 340 × 220 px; minimálna šírka obsahu klesla zo 477 na 288 px. Testované cez Xvfb/llvmpipe pri viewporte 1280 × 720.
- Pridaný workflow `country-comparison.yml` pripravuje samostatné snímky pred/po a obraz vedľa seba, a po úspešnej kontrole ich má uložiť do vetvy. Výsledok vytvorenia snímok a ich vizuálna kontrola zatiaľ nie sú potvrdené. https://github.com/Wondris404/Projekt-47/actions/runs/40667390401


## 2026-10-28 – Testy po zalomení textu

- Beh `40667327638`: `audit_unit` 29 OK / 0 FAIL, stabilita 1/30/365 prešla, `unit` 531 OK / 1 FAIL na tej istej chýbajúcej referencii katalógu ako pred zmenou. Testovacia vetva teda stále nemá úplne zelenú základnú sadu.
- Headless sonda s rovnakým scenárom uvádza priemer 59,52 ms/deň, medián 58,92 ms, p95 67,65 ms a maximum 72,95 ms. Pôvodný beh mal 87,79 ms/deň; rozdielne vyťaženie vzdialených runnerov neumožňuje z toho dokázať zrýchlenie ani vylúčiť zhoršenie na notebooku. Nejde o meranie času snímky. https://github.com/Wondris404/Projekt-47/actions/runs/40667327638


## 2026-10-28 – Snímky okna pred a po

- Workflow `40667619876` zopakoval rovnaký scenár na kóde pred opravou a po nej: pred opravou zlyhalo zapamätanie okna, po oprave prešlo všetkých desať kontrol. Tri nové obrázky sú v `audit/screenshots/window-audit/`: `country_before_20261028.png`, `country_after_20261028.png` a `country_comparison_20261028.png` (vedľa seba).
- Obrázky vznikli cez Xvfb/llvmpipe. Ich vizuálne posúdenie zatiaľ nie je potvrdené; nejde o meranie výkonu GPU notebooku. https://github.com/Wondris404/Projekt-47/actions/runs/40667619876


## 2026-10-28 – Príprava reprodukcie nastavení banky

- Pridaná grafická skúška detailu banky s tromi kontrolami: obnovenie nezmenených polí po externej zmene, zachovanie rozpracovanej úpravy a uloženie aktuálnych hodnôt. Test vykonáva zmeny len v izolovanej testovacej hre, nemení bankovú mechaniku v bežnom hraní.
- Grafický workflow test spúšťa a ukladá jeho log. Výsledok prvého behu ešte nie je potvrdený; možná chyba nastavení zostáva otvorená.


## 2026-10-28 – Potvrdená chyba nastavení banky

- Grafický beh `40668251403` potvrdil reprodukciu: po zmene sadzieb zvonka sa nezmenené vstupné polia neobnovili a stlačenie uloženia prepísalo aktuálne sadzby starými hodnotami. Kontrola zachovania rozpracovanej hodnoty prešla. Zmena sa zatiaľ v simulácii vykonala len v izolovanej testovacej hre.
- Oprava ešte nie je vykonaná. Pri návrhu treba zachovať manuálne editované hodnoty a neprepisovať presné automatické sadzby zaokrúhlenými hodnotami z formulára. https://github.com/Wondris404/Projekt-47/actions/runs/40668251403


## 2026-10-28 – Presnosť a snímka nastavení banky

- Reprodukcia bankového formulára doplnená o kontrolu, že sa nezmenená presná sadzba neprepíše zaokrúhlenou hodnotou políčka. Test vie tiež v izolovanom grafickom behu uložiť snímku otvorených nastavení.
- Workflow pripravuje východiskovú snímku pred opravou; výsledok rozšírenej skúšky a snímky ešte nie je potvrdený.


## 2026-10-28 – Obnovenie nastavení banky

- Pred opravou rozšírená grafická skúška `40668639338`: nezmenené polia sa neobnovili, uloženie prepísalo aktuálne sadzby a zaokrúhlilo inú presnú sadzbu; zachovanie editovaného poľa prešlo. Snímka pred opravou je zatiaľ v artefakte behu.
- Úprava obnovuje iba polia, ktoré hráč nezmenil, a ponecháva rozpracované pole aj pole práve editované. Pri ukladaní pre nezmenené polia používa presné aktuálne hodnoty banky. Existujúca funkcia manuálneho zásahu do práce poradcu zostáva zachovaná. Výsledky po oprave ešte nie sú potvrdené.


## 2026-10-28 – Overenie nastavení banky po oprave

- Grafický beh `40668934073`: všetky štyri kontroly prešli (obnovenie nezmeneného poľa, zachovanie úpravy, uloženie aktuálnych sadzieb, presnosť sadzby). Prešlo aj 10 kontrol okna krajiny. Pridaný workflow pripravuje snímky banky pred/po a ich porovnanie; jeho výsledok ešte nie je potvrdený.
- Headless beh `40668934094`: `audit_unit` 29 OK / 0 FAIL, stabilita 1/30/365 prešla, `unit` 531 OK / 1 FAIL na chýbajúcom súbore referencie katalógu. Sonda výkonu 93,91 ms/deň oproti pôvodným 87,79 ms/deň; rozdiel na rozdielnych runneroch nedokazuje ani nevyvracia regresiu, preto treba porovnanie na rovnakom stroji. https://github.com/Wondris404/Projekt-47/actions/runs/40668934094


## 2026-10-28 – Párové meranie výkonu

- Pridaný vzdialený workflow porovnávajúci predchádzajúci a opravený `main.gd` na rovnakom runneri v poradí pred, po, po, pred. Používa existujúcu 100-dňovú headless sondu a nemení súbory ani nastavenia hráča. Výsledky zatiaľ nie sú potvrdené; sú to časy simulácie, nie FPS na notebooku.


## 2026-10-28 – Snímky nastavení banky pred a po

- Workflow `40671103738` zopakoval tú istú grafickú skúšku na pôvodnom a opravenom formulári. Pôvodný formulár mal 1 zo 4 kontrol úspešnú, opravený 4 zo 4. Pridané súbory `audit/screenshots/bank-audit/bank_before20261028.png`, `bank_after20261028.png` a `bank_comparison20261028.png` ukazujú oba stavy aj vedľa seba.
- Snímky vznikli cez Xvfb/llvmpipe a zatiaľ neboli vizuálne posúdené. https://github.com/Wondris404/Projekt-47/actions/runs/40671103738


## 2026-10-28 – Párové výsledky výkonu bankovej opravy

- Beh `40671193033` na tom istom runneri: pred 85,94 a 85,72 ms/deň, po 85,87 a 85,38 ms/deň; priemery dvojíc sú približne 85,83 a 85,63 ms/deň. V tejto krátkej headless sonde sa zhoršenie neprejavilo, rozdiel nie je dôkazom zrýchlenia a nemeria FPS ani notebook. https://github.com/Wondris404/Projekt-47/actions/runs/40671193033


## 2026-10-28 – Ďalšie kontroly bankového formulára

- Grafická skúška bola rozšírená o skutočný mesačný zásah poradcu a o zachovanie textu v práve editovanom políčku. Workflow teraz spúšťa grafickú kontrolu aj po zmene testu. Testy používajú izolovanú testovaciu hru; výsledok rozšírenej skúšky sa ešte overuje.


## 2026-10-28 – Kontrola validácie starých savov

- Audit zaznamenal neistotu pri povinných poliach v3: validácia ich vyžaduje, hoci opravná funkcia pozná predvolené hodnoty, a existujúce testy kontrolujú ich povinnosť. Zatiaľ nie je známe, či niektorá vydaná v3 takéto polia nemala; preto sa validácia ani testy nemenili. Nález a ďalší postup sú v `docs/AUDIT_UX_20261028.md`.


## 2026-10-28 – Výsledok rozšírenej skúšky banky

- V grafickom behu `40671536677` prešlo všetkých šesť kontrol, vrátane skutočného mesačného rozhodnutia poradcu a zachovania písaného textu v aktívnom políčku. https://github.com/Wondris404/Projekt-47/actions/runs/40671536677
- História GitHubu obsahuje pre `GameState.gd` iba pôvodný import projektu a neskoršiu opravu cache; neurčuje, či existovali ešte staršie platné v3 savy bez povinných polí. Zmena validácie preto zostáva otvorená.


## 2026-10-28 – Riziko prepísania savu na Windowse

- Audit zdrojového kódu Godotu 4.7.2 zistil, že jeho Windows implementácia pri premenovaní na existujúci cieľ najprv odstráni cieľ a potom presunie nový súbor. Ak druhý krok zlyhá, hra môže prísť o predchádzajúci slot. Nález a návrh pred opravou sú v `docs/AUDIT_UX_20261028.md`.
- Pripravuje sa overovaná kópia pôvodného slotu a načítanie pri chýbajúcom origináli, bez zmeny JSON formátu v3. Zatiaľ neopravené a netestované na Windowse.


## 2026-10-28 – Ochrana pred stratou slotu pri prepise

- Pred nahradením existujúceho slotu sa vytvorí jeho kópia `.backup` a porovná sa SHA-256 oboch súborov. Ak kópiu nemožno overiť, uloženie sa zastaví ešte pred premenovaním. Ak hlavný slot po neúspešnom presune chýba, vyhľadávanie slotu používa záložnú kópiu. Formát JSON a verzia v3 sa nemenia.
- Pridané štyri kontroly: obsah zálohy, prednosť aktuálneho slotu, obnova v3 pri chýbajúcom hlavnom súbore a zachovanie slotu pri neúspešnom vytvorení zálohy. Scenár chýbajúceho súboru sa simuluje presunutím, bez vymazania. Výsledky po úprave zatiaľ nie sú potvrdené; pri behu na Linuxe sa nesimuluje skutočné Windows API ani výpadok napájania.


## 2026-10-28 – Windows test ukladania

- Pridaný samostatný GitHub Actions beh na Windows pre auditné a nové kontroly zálohy slotu. Používa oficiálny Godot 4.7.2 s overeným SHA-256 a izolovaný dočasný runner. Výsledok zatiaľ nie je známy; chýbajúci slot sa v teste simuluje presunutím súboru, nie skutočným zlyhaním Windows API.


## 2026-10-28 – Priebežné overenie ochrany slotu

- Linuxový `audit_unit` v behu `40673444595` prešiel vrátane všetkých štyroch nových kontrol uloženia; stabilita 1/30/365 a headless výkonnostná sonda tiež prešli, úplná `unit` ešte beží. Windows kontrola zatiaľ prebieha.
- Pri prepise sa navyše číta a zapisuje predchádzajúci save a čítajú sa jeho kontrolné súčty; veľké savy preto môžu trvať dlhšie a zaberajú miesto aj v jednej záložnej kópii na slot. Výpadok napájania, chyby disku a skutočné zlyhanie presunu na Windowse test nedokazuje. https://github.com/Wondris404/Projekt-47/actions/runs/40673444595


## 2026-10-28 – Windows overenie ochrany slotu

- Windows GitHub Actions `40673584344` s oficiálnym Godotom 4.7.2: `audit_unit` 33 OK / 0 FAIL vrátane všetkých štyroch kontrol kópie, prednosti hlavného slotu, obnovy v3 a zastavenia pri chybe kópie. Správanie po skutočnom zlyhaní systémového presunu ani po výpadku napájania nie je týmto simulovaným testom dokázané. https://github.com/Wondris404/Projekt-47/actions/runs/40673584344


## 2026-10-28 – Úplná sada po oprave ochrany slotu

- Linuxový beh `40673444595`: `unit` 531 OK / 1 FAIL na chýbajúcej referencii katalógu, `audit_unit` 33 OK / 0 FAIL, stabilita 1/30/365 prešla. Samotný test nevypísal GDScript chybu; pri úvodnom importe zdrojov sa opäť objavili dosiaľ nevyšetrené chyby načítania. Headless sonda uviedla 62,68 ms/deň; iné runnery sa líšia a nejde o FPS notebooku.


## 2026-10-28 – Reprodukcia hlásenia pri obnove slotu

- Pridaná grafická skúška, ktorá vytvorí dve verzie testovacieho savu, presunutím hlavného súboru vyvolá načítanie zálohy a kontroluje obnovený stav aj informáciu pre hráča. Vie uložiť snímku obrazovky; testovacie súbory sú v izolovanom profile runnera. Výsledok pred doplnením hlásenia sa overuje.


## 2026-10-28 – Výsledok reprodukcie hlásenia obnovy

- Grafický beh `40674124613` úspešne načítal stav zo záložnej kópie, no potvrdil chýbajúce upozornenie pre hráča. Východisková snímka a log sú v artefakte `p47-save-recovery-ui`; po úprave bude treba kontrolu a snímky zopakovať. https://github.com/Wondris404/Projekt-47/actions/runs/40674124613


## 2026-10-28 – Hlásenie pri obnove zálohy

- Po úspešnom načítaní záložného slotu hra hlási „Hra načítaná zo záložnej kópie“; pri bežnom slote zachováva pôvodné hlásenie. Príznak zdroja načítania je iba pre aktuálnu reláciu, neukladá sa do v3 JSON a pri začatí ďalšieho načítania sa vymaže.
- Testy kontrolujú aj správny príznak pri hlavnom slote a zálohe a normálne hlásenie pri štandardnom načítaní. Výsledky po zmene a snímky pred/po zatiaľ nie sú potvrdené.


## 2026-10-28 – Overenie hlásenia obnovy

- Grafický beh `40674500224` overil normálne načítanie, obnovenie stavu zo zálohy a oznámenie hráčovi: všetky tri kontroly prešli. Šesť kontrol banky aj desať kontrol okien tiež prešlo. Windows `audit_unit` v behu `40674500295` prešiel; stabilita a auditná sada na Linuxe tiež prešli, úplná sada ešte beží.
- Pridaný workflow na párové snímky hlásenia obnovy; jeho výsledok a vizuálne posúdenie zatiaľ nie sú potvrdené.


## 2026-10-28 – Menej nadbytočných testov

- Úplný auditný workflow sa už automaticky nespúšťa pri commitoch, ktoré menia iba workflowy, snímky auditu alebo dokumentáciu. Pri zmene herného kódu či testov sa naďalej spúšťa; samostatné grafické, Windows a porovnávacie workflowy majú vlastné spúšťače. Zmena upravuje len pravidlá spúšťania, nie hru.


## 2026-10-28 – Snímky hlásenia obnovy

- V behu `40674747084` na pôvodnom stave prešli dve kontroly načítania a zlyhalo upozornenie, po oprave prešli všetky tri. Snímky `recovery_before20261028.png`, `recovery_after20261028.png` a `recovery_comparison20261028.png` sú v `audit/screenshots/save-audit/`.
- Snímky z Xvfb/llvmpipe zatiaľ neboli vizuálne posúdené. https://github.com/Wondris404/Projekt-47/actions/runs/40674747084


## 2026-10-28 – Kontrola straty fokusu počas presunu okna

- Grafický test okna bol rozšírený o začatie presunu a vyvolanie straty fokusu pred udalosťou uvoľnenia myši. Overuje, či sa presun zastaví; nejde o zmenu správania hry. Pôvodný audit toto riziko evidoval ako neoverené. Výsledok reprodukcie zatiaľ nie je známy.


## 2026-10-28 – Pull request na kontrolu zmien

- Existujúci pull request č. 3 pre pracovnú vetvu bol doplnený o prehľad opráv, testov, meraní, otvorených obmedzení a odkazy na porovnávacie snímky. Ďalšie commity tejto vetvy sa v ňom zobrazia automaticky. https://github.com/Wondris404/Projekt-47/pull/3


## 2026-10-28 – Výsledok skúšky straty fokusu

- Grafický beh `40692508020` mal desať úspešných kontrol okien a jednu neúspešnú: test nezaevidoval ukončenie presunu po strate fokusu. Treba ešte oddeliť, či sa simulovaný presun naozaj začal, od samotného spracovania straty fokusu; oprava zatiaľ nie je urobená. https://github.com/Wondris404/Projekt-47/actions/runs/40692508020


## 2026-10-28 – Diagnostika skúšky fokusu

- Grafický workflow do dočasnej testovacej kópie doplní výpis, či sa presun začal a aký režim zostal po strate fokusu. Produkčný kód hry sa touto diagnostikou nemení. Výsledok zatiaľ čaká na beh.


## 2026-10-28 – Ukončenie presunu okna pri strate fokusu

- Diagnostika `40693049934` potvrdila, že simulovaný presun sa začal a po strate fokusu zostal aktívny (`started=true`, `mode_after=1`). Správca okien teraz pri strate fokusu zastaví aktívny presun alebo zmenu veľkosti a zapamätá si posledný obdĺžnik.
- Grafická skúška bola doplnená aj o zmenu veľkosti; výsledky po oprave sa ešte overujú. https://github.com/Wondris404/Projekt-47/actions/runs/40693049934


## 2026-10-28 – Overenie straty fokusu

- Grafický beh `40693779749` prešiel všetkými 12 kontrolami okien: po strate fokusu sa zastavil presun aj zmena veľkosti. Prešlo aj 6 kontrol banky a 3 kontroly obnovy savu. Popis pull requestu bol doplnený o túto opravu a výsledky. https://github.com/Wondris404/Projekt-47/actions/runs/40693779749


## 2026-10-28 – Profil mesačnej uzávierky

- Pridaný vzdialený headless profil s pevným seed-om, 72 hráčovými firmami a 70 dňami. V dočasnej kópii dopĺňa merania jednotlivých mesačných systémov a fáz simulácie, aby zachytil dva prechody mesiaca. Produkčný kód ani ekonomiku nemení. Výsledok ešte nie je známy a nepôjde o meranie FPS notebooku.


## 2026-10-28 – Úplné testy po oprave fokusu

- Beh `40693779778`: `audit_unit` 33 OK / 0 FAIL, stabilita 1/30/365 prešla, `unit` 531 OK / 1 FAIL na tej istej chýbajúcej referencii katalógu. Headless sonda uviedla priemer 80,46 ms/deň; hodnoty z rozdielnych runnerov nemožno považovať za dôkaz zmeny výkonu notebooku. https://github.com/Wondris404/Projekt-47/actions/runs/40693779778


## 2026-10-28 – Výsledok profilu mesačnej uzávierky

- Headless beh `40694620596`, pevný seed, 70 dní a 72 hráčových firiem: maximálny meraný jednotlivý krok fázy ukončenia dňa bol 16,322 ms; pri dvoch mesačných uzávierkach systém `Society.monthly` trval 8,539 a 8,654 ms, dividendy 1,859 a 2,838 ms, makro 0,968 a 0,990 ms. Najvyššie maximá ostatných fáz boli pod 5,6 ms.
- Časy obsahujú réžiu diagnostiky a dva mesačné vzorky na cloudovom CPU; nejde o čas celej vykreslenej snímky, FPS notebooku ani dôkaz, že sa náročnejší save správa rovnako. Profil nemenil herné výsledky ani produkčný kód. https://github.com/Wondris404/Projekt-47/actions/runs/40694620596


## 2026-10-28 – Podrobnejší profil spoločnosti

- Vzdialená sonda bola rozšírená o jednotlivé časti mesačnej aktualizácie spoločnosti a výpočet služieb v mestách. Meracie výpisy sa vkladajú len do dočasnej kópie na runneri; produkčný kód ani poradie herných výpočtov sa nemení. Výsledok ďalšieho behu zatiaľ nie je známy.


## 2026-10-28 – Podrobnosti profilu spoločnosti

- V behu `40694951436` zabrali výpočty vplyvu krajín pri mesačnej uzávierke 6,54 a 6,64 ms, mestská časť 5,87 a 5,69 ms vrátane jednotlivých výpisov. Približne 1,2 ms z mestskej časti patrilo výpočtom služieb miest. Celý spoločenský systém v tejto podrobne inštrumentovanej sonde trval 13,17 a 13,62 ms, maximum fázy 23,00 ms; tento beh obsahuje viac výpisov a nemá sa priamo porovnávať s menej inštrumentovaným profilom.
- Nález aj obmedzenia boli doplnené do popisu pull requestu. Najprv sa skúma zdieľanie už vypočítaných údajov o zamestnancoch pri zachovaní presných výsledkov; herné výpočty zatiaľ neboli zmenené. https://github.com/Wondris404/Projekt-47/actions/runs/40694951436


## 2026-10-28 – Zdieľanie počtu zamestnancov pri výpočte vplyvu

- Výpočet vplyvu môže použiť rovnaký súčet zamestnancov, ktorý bezprostredne predtým vypočíta pre závislosť krajiny. Referenčná cesta pôvodného výpočtu zostáva dostupná na porovnanie; poradie ostatných výpočtov a ich vedľajšie účinky zostávajú zachované.
- Pridané kontroly prípravy scenára a presnej zhody celého uloženého stavu po 62 dňoch pri pevnom seed-e, cez dve mesačné uzávierky. Výsledok testov, prípadné zrýchlenie a výkon notebooku ešte nie sú potvrdené.


## 2026-10-28 – Zhoda simulácie po optimalizácii vplyvu

- Linuxový `audit_unit` v behu `40695557618` prešiel vrátane porovnania celého serializovaného stavu po 62 dňoch a dvoch mesačných uzávierkach s pôvodnou aj optimalizovanou cestou. Stabilita 1/30/365 prešla; úplná `unit` a Windows kontrola ešte bežia.
- Rýchlosť novej cesty sa musí porovnať na tom istom runneri. Zhoda jedného scenára nie je dôkazom totožnosti pre každú možnú uloženú hru. https://github.com/Wondris404/Projekt-47/actions/runs/40695557618


## 2026-10-28 – Párový profil výpočtu vplyvu

- Pridaný vzdialený profil na porovnanie pôvodného a optimalizovaného výpočtu na tom istom runneri v poradí pred/po/po/pred, s rovnakým seed-om a dvoma mesačnými uzávierkami. Produkčný kód sa meracími výpismi nemení. Výsledky ešte nie sú známe.
- Windowsový auditný beh `40695557675` prešiel aj po optimalizácii; presný počet kontrol a párové merania sa ešte zapisujú.


## 2026-10-28 – Oprava meracej sondy

- Prvý párový profil `40695893182` sa pred meraním zastavil na 404, pretože v adrese pôvodnej revízie bol preklep. Adresa bola opravená na skutočného rodiča optimalizačného commitu; meranie sa opakuje. Tento neúspešný beh nevypovedá o výkone hry. https://github.com/Wondris404/Projekt-47/actions/runs/40695893182


## 2026-10-28 – Párový výsledok výpočtu vplyvu

- Beh `40696075993` na jednom cloudovom runneri, poradie pred/po/po/pred: štyri mesačné merania výpočtu vplyvu pred úpravou 6,816; 6,622; 6,355; 6,562 ms, po úprave 5,426; 5,514; 5,748; 5,520 ms. Priemery sú približne 6,59 a 5,55 ms, teda o 1,04 ms menej v tomto scenári.
- Najdlhší jednotlivý krok ukončenia dňa mal v týchto behoch pred úpravou 21,76 a 20,79 ms, po úprave 19,57 a 19,99 ms. Meranie používalo 70 dní, 72 hráčových firiem a diagnostické výpisy; má málo mesačných vzoriek, nezahŕňa vykreslenú snímku ani výkon notebooku a nedokazuje odstránenie sekania. https://github.com/Wondris404/Projekt-47/actions/runs/40696075993
- Linux aj Windows prešli porovnaním celého serializovaného stavu po 62 dňoch pri použití starej a novej cesty. Úplná základná sada ešte beží; optimalizáciu treba preveriť aj na rozsiahlejšom uloženom stave.


## 2026-10-28 – Úplná sada po optimalizácii vplyvu

- Linuxový beh `40695557618` dokončil `unit` s 531 OK / 1 FAIL na chýbajúcej referencii katalógu; `audit_unit` 35 OK a stabilita 1/30/365 prešli. Windowsový auditný beh mal tiež 35 OK. Stav optimalizácie a párové meranie boli doplnené do pull requestu. https://github.com/Wondris404/Projekt-47/actions/runs/40695557618


## 2026-10-28 – Skupiny firiem pri mesačných službách

- Mesačný výpočet služieb môže použiť už vytvorené skupiny hráčových firiem podľa mesta; pri iných volaniach sa zachová pôvodný úplný prechod. Referenčná cesta zostáva dostupná na porovnanie a ekonomické výpočty ani ich poradie sa nemenia.
- Skúška bola rozšírená o viac miest a samostatné porovnanie celého stavu po 62 dňoch pri pôvodnej a optimalizovanej ceste. Výsledky, časová úspora a správanie na rozsiahlych savoch ešte nie sú potvrdené.


## 2026-10-28 – Zhoda mesačných skupín firiem

- Linuxový beh `40696718198` a Windowsový `40696717980` prešli `audit_unit` 36 OK / 0 FAIL. Presný serializovaný stav po 62 dňoch sa zhodoval pri pôvodnej aj novej ceste v scenári s viacerými mestami; Linuxová stabilita 1/30/365 prešla. Úplná `unit` ešte beží.
- Jedna testovacia konfigurácia nedokazuje zhodu všetkých savov; časová úspora sa ešte musí zmerať na rovnakom runneri.


## 2026-10-28 – Párový profil mestských služieb

- Pridaný profil porovnávajúci pôvodnú a optimalizovanú cestu mestských služieb na rovnakom runneri v poradí pred/po/po/pred. Meria celú mestskú časť aj samotné služby počas dvoch mesačných uzávierok; meracie zásahy zostávajú v dočasnej kópii. Výsledky zatiaľ nie sú potvrdené.


## 2026-10-28 – Párový výsledok mestských služieb

- Beh `40697119316` na rovnakom runneri, poradie pred/po/po/pred a štyri mesačné vzorky: samotné služby pred úpravou 1,188; 1,212; 1,181; 1,191 ms, po úprave 0,420; 0,405; 0,402; 0,408 ms. Priemery sú približne 1,19 a 0,41 ms. Priemer celej mestskej časti bol približne 4,84 a 4,03 ms.
- Najdlhší jednotlivý krok ukončenia dňa bol pred úpravou 20,64 a 20,39 ms, po úprave 19,37 a 19,39 ms. Ide o krátku headless sondu so 72 hráčovými firmami a meracou réžiou, nie o FPS notebooku ani o dôkaz odstránenia všetkého sekania. Zhodu celého stavu po 62 dňoch overili Linux aj Windows. https://github.com/Wondris404/Projekt-47/actions/runs/40697119316


## 2026-10-28 – Úplná sada po optimalizácii mestských služieb

- Beh `40696718198`: `unit` 531 OK / 1 FAIL na chýbajúcej referencii katalógu, `audit_unit` 36 OK / 0 FAIL a stabilita 1/30/365 prešla. Výsledok optimalizácie a párové meranie boli doplnené do pull requestu. https://github.com/Wondris404/Projekt-47/actions/runs/40696718198


## 2026-10-28 – Príčiny upozornení GitHub Actions

- Opakované chyby `Projekt-47 audit / baseline (unit)` pochádzajú z existujúceho testu s chýbajúcim referenčným súborom; nejde o nasadenie hry. Pri každom spustení vygeneroval GitHub nové upozornenie.
- Samostatný profil `40695893182` predtým zlyhal kvôli preklepu v revízii a po oprave prešiel. Novší profil `40697719549` zlyhal v meracom skripte: po optimalizácii sa zmenilo volanie mestských služieb a diagnostika hľadala jeho starý presný text. Skript bol upravený, nový beh ešte nie je potvrdený. Produkčný kód hry týmto chybným meraním zmenený nebol.


## 2026-10-28 – Menej opakovaných upozornení na známu chybu

- `unit` sa naďalej celý spúšťa. Ak sa dokončí a jeho jediným zlyhaním je `catalog_fields_match_brief` pri neprítomnom `tests/catalog_field_lock.txt`, workflow túto známu neoverenú referenciu zobrazí ako varovanie namiesto opakovaného neúspešného behu. Výsledok testu zostáva v logu 531 OK / 1 FAIL; nejde o opravenie ani overenie katalógu.
- Iné zlyhanie, chyba GDScriptu, timeout, nedokončená sada alebo chyba pri existujúcej referencii zostáva chybou. Pridaná samostatná kontrola siedmich scenárov klasifikácie; reálny beh a samokontrola sa ešte overujú.


## 2026-10-28 – Opakované meranie dividend

- Opravený profil `40698325056` prešiel. Pri dvoch mesačných uzávierkach nameral výpočet obdobného zisku 1,11 a 2,09 ms, výpočet rezerv 0,70 a 0,94 ms a prevod dividend 0,25 a 0,24 ms. Merania zahŕňajú réžiu časovačov a nemerajú snímky ani výkon notebooku.
- Správy v Gmaile boli iba prečítané; príčiny jednotlivých neúspešných behov sa zhodujú s auditným logom. https://github.com/Wondris404/Projekt-47/actions/runs/40698325056


## 2026-10-28 – Overenie upozornenia na katalóg

- Beh `40698639465` prešiel siedmimi syntetickými kontrolami klasifikácie a potom spustil celú `unit` sadu. Log obsahuje 531 OK / 1 FAIL (`catalog_fields_match_brief`); GitHub zobrazuje výslovné varovanie, že referencia chýba a katalóg nie je overený. `audit_unit`, stabilita a sonda výkonu prešli.
- Testy klasifikácie overili, že ďalšie zlyhanie, chyba skriptu, timeout, nedokončená sada a zlyhanie pri existujúcej referencii zostávajú neúspešné. Toto je dočasné odlíšenie známeho problému, nie oprava referencie katalógu. https://github.com/Wondris404/Projekt-47/actions/runs/40698639465


## 2026-10-28 – Audit základných finančných polí savu

- Zaznamenané podozrenie, že validácia považuje chýbajúcu hotovosť hráča alebo firmy za prijateľnú, hoci niektoré herné funkcie tieto údaje očakávajú. Pred zmenou treba reprodukovať správanie a preveriť kompatibilitu pôvodných verzií savov. Zatiaľ bez úpravy.


## 2026-10-28 – Skúška neúplného savu

- Pridaná izolovaná sonda, ktorá v dočasnej testovacej hre odstráni hotovosť hráča alebo firmy z kópie savu a zaznamená, či ju načítanie prijalo. Test nezasahuje do skutočných uložených hier, produkčného kódu ani balansu. Výsledok zatiaľ nie je známy.


## 2026-10-28 – Potvrdenie neúplných finančných polí

- Izolovaná sonda `40699855377` potvrdila, že save bez `player.cash` aj save bez `firm.cash` prešiel validáciou a neúplný slovník nahradil živý stav. Dostupné historické definície zakladania hráča a firiem obsahujú hotovosť; skutočné historické savy však nie sú v GitHube dostupné.
- Navrhnuté je odmietnuť chýbajúcu základnú hotovosť ešte pred zmenou živého stavu a zachovať existujúce migrácie a predvolené hodnoty pre novšie polia. Zatiaľ neopravené. https://github.com/Wondris404/Projekt-47/actions/runs/40699855377


## 2026-10-28 – Odmietnutie savu bez základnej hotovosti

- Validácia teraz odmietne chýbajúcu `cash` u hráča alebo firmy ešte pred nahradením živého stavu. Pôvodné migračné polia a predvolené hodnoty novších údajov sa nemenia; dostupné historické definície hráča a firiem obsahujú hotovosť.
- Pridaných sedem kontrol pre neúplný stav a prijatie úplných vzoriek označených v1/v2/v3. Skutočné historické savy nie sú v repozitári a uvedené vzorky ich nenahrádzajú. Výsledky testov po úprave ešte nie sú potvrdené.


## 2026-10-28 – Overenie chýbajúcich finančných polí

- Linuxový beh `40700401490` aj Windowsový `40700401478` prešli `audit_unit` 43 OK / 0 FAIL. Všetkých šesť kontrol odmietlo chýbajúcu hotovosť hráča/firmy vo vzorkách v1/v2/v3 bez zmeny živého stavu; úplné vzorky všetkých troch verzií sa prijali. Linuxová stabilita 1/30/365 prešla, úplná `unit` ešte beží.
- Skutočné historické savy nie sú v repozitári; tieto syntetické vzorky nenahrádzajú ich kontrolu. https://github.com/Wondris404/Projekt-47/actions/runs/40700401490


## 2026-10-28 – Úplná sada po oprave neúplného savu

- Beh `40700401490`: `unit` 531 OK / 1 FAIL kvôli chýbajúcej referencii katalógu, ktorú GitHub označil viditeľným varovaním; `audit_unit` 43 OK, stabilita 1/30/365 a výkonnostná sonda prešli. Rovnakých 43 auditných kontrol prešlo aj na Windowse. Referencia katalógu zostáva neoverená. https://github.com/Wondris404/Projekt-47/actions/runs/40700401490


## 2026-10-28 – Skupiny firiem pri mesačnom vplyve

- Pri mesačnom prepočte sa vytvoria skupiny hráčových firiem podľa krajiny a použijú pri výpočte závislosti a mediálneho dosahu. Ostatné volania ponechávajú pôvodný prechod; výpočty majú rovnaké poradie a referenčná cesta zostáva dostupná na porovnanie.
- Skúška presnej zhody stavu po 62 dňoch bola rozšírená o samostatné porovnanie tejto cesty. Testy aj párové meranie ešte nie sú potvrdené; výkon notebooku zostáva neoverený.


## 2026-10-28 – Zhoda skupín firiem podľa krajiny

- Linuxový beh `40701608943` aj Windowsový `40701609001` prešli `audit_unit` 44 OK / 0 FAIL. Porovnanie celého stavu po 62 dňoch prešlo samostatne pre všetky tri optimalizačné cesty. Stabilita 1/30/365 prešla; úplná `unit` a párové meranie ešte prebiehajú.
- Zhoda testovacieho scenára nezaručuje zhodu všetkých reálnych savov. https://github.com/Wondris404/Projekt-47/actions/runs/40701608943


## 2026-10-28 – Párový profil skupín podľa krajiny

- Pridaný párový profil pôvodného a nového prechodu firiem v poradí pred/po/po/pred na tom istom runneri. Používa pevný seed a 70 dní; výsledok ešte nie je známy a profil nemení produkčný kód ani save.


## 2026-10-28 – Párový výsledok skupín podľa krajiny

- Beh `40702082461` na rovnakom runneri, poradie pred/po/po/pred: štyri mesačné merania výpočtu vplyvu pred úpravou 5,552; 5,821; 5,209; 5,497 ms, po úprave 3,895; 4,094; 3,860; 4,218 ms. Priemery sú približne 5,52 a 4,02 ms.
- Najdlhší krok ukončenia dňa bol v oboch behoch pred úpravou 19,62 a 18,69 ms, po úprave 17,28 a 18,74 ms. Test obsahuje diagnostickú réžiu, iba štyri mesačné vzorky a nezahŕňa vykreslenie ani notebook; nepotvrdzuje odstránenie sekania. Presný stav po 62 dňoch sa zhodoval na Linuxe aj Windowse. https://github.com/Wondris404/Projekt-47/actions/runs/40702082461


## 2026-10-28 – Úplné testy po skupinách podľa krajiny

- Beh `40701608943` dokončil `unit` s 531 OK / 1 známym FAIL na chýbajúcej referencii katalógu; workflow ho zobrazuje ako výslovné varovanie. `audit_unit` 44 OK a stabilita 1/30/365 prešli na Linuxe; auditná sada prešla aj na Windowse. https://github.com/Wondris404/Projekt-47/actions/runs/40701608943


## 2026-10-28 – Mediálny súhrn bez nepotrebného počtu konkurentov

- Interný súhrn mediálneho dosahu preskakuje vytváranie zoznamu konkurentov, keďže z detailu používa iba počet používateľov. Bežný detail média naďalej počíta a zobrazuje konkurentov; výpočet dosahu a ostatné údaje sa nemenia.
- Pridané kontroly plného detailu, zhodných hodnôt súhrnu a presného stavu simulácie po 62 dňoch. Testy, časová úspora a správanie na rozsiahlejších savoch ešte nie sú potvrdené.


## 2026-10-28 – Zhoda mediálneho súhrnu

- Linuxový `40702803419` a Windowsový `40702803147` prešli `audit_unit` 46 OK / 0 FAIL. Detail média si zachoval počet konkurentov, používané hodnoty sú rovnaké a úplný stav po 62 dňoch sa zhodoval s referenčným výpočtom. Stabilita 1/30/365 prešla; úplná `unit` a párové meranie ešte bežia. https://github.com/Wondris404/Projekt-47/actions/runs/40702803419


## 2026-10-28 – Párový profil mediálneho súhrnu

- Pridaný profil pôvodného a nového mediálneho súhrnu na rovnakom runneri v poradí pred/po/po/pred, s pevným seed-om a dvoma mesačnými uzávierkami. Výsledok ešte nie je známy; nejde o meranie FPS notebooku.


## 2026-10-28 – Prehliadka porovnávacích snímok a úplná sada

- V zmenšenom náhľade na GitHube je vidieť, že po oprave panel krajiny zostáva v okne hry a bankový panel zobrazuje aktualizovanú sadzbu. Náhľad nie je dostatočne detailný na kontrolu všetkého textu; správu pri obnove uloženia preto vizuálne nepotvrdzujem. Správanie obnovy aj banky kontrolujú aj samostatné grafické testy.
- Beh `40702803419`: `unit` 531 OK / 1 známy FAIL pre chýbajúcu referenciu katalógu, viditeľný ako varovanie; `audit_unit` 46 OK a stabilita 1/30/365 prešli. Párové meranie médií ešte prebieha. https://github.com/Wondris404/Projekt-47/actions/runs/40702803419


## 2026-10-28 – Oprava opakovaného merania médií

- Pri kontrole párového merania sa zistilo, že cyklus mohol opakovane vložiť časovač do toho istého skriptu a následne spôsobiť chybu. Profil pred každým meraním obnovuje pôvodnú testovaciu kópiu skriptu a až potom pridá časovač. Produkčná hra sa tým nemení.
- Prvý beh už bol spustený s pôvodným postupom a môže zlyhať; opravený profil aj jeho výsledok treba ešte overiť. https://github.com/Wondris404/Projekt-47/actions/runs/40703252724


## 2026-10-28 – Výsledok párového merania mediálneho súhrnu

- Opravený beh `40704325707` na rovnakom runneri a v poradí pred/po/po/pred nameral výpočet vplyvu pred zmenou 2,645; 2,725; 2,651; 2,733 ms a po zmene 2,518; 2,591; 2,400; 2,586 ms. Priemery sú 2,69 a 2,52 ms, úspora asi 0,16 ms v tomto scenári.
- Maximálny krok uzávierky bol pred zmenou 13,64 a 13,34 ms, po zmene 13,89 a 13,94 ms. Štyri vzorky a diagnostická réžia nestačia na záver o zmene maxima ani o FPS notebooku. Detail média a stav po 62 dňoch prešli na Linuxe a Windowse; rozsiahlejšie savy nie sú overené. https://github.com/Wondris404/Projekt-47/actions/runs/40704325707


## 2026-10-28 – Ukončenie starého profilu médií

- Pôvodný beh `40703252724` skončil neúspešne; išlo o už spustenú starú verziu meracieho postupu. Opravený opakovaný beh `40704325707` prešiel a jeho čísla sú uvedené vyššie. https://github.com/Wondris404/Projekt-47/actions/runs/40703252724


## 2026-10-28 – Základná sonda na notebooku

- Po povolení používateľa bol spustený lokálny Godot 4.7.2, existujúca lokálna kópia projektu a test `profile_sim` s 72 firmami a 10 dňami. Používateľské dáta boli smerované do samostatného priečinka `audit/laptop_profile_userdata`. Lokálna kópia nie je Git repozitár a nebola zamenená za vetvu PR.
- Najdlhšie namerané jednotlivé volanie fázy malo 17,815 ms (fáza 6); súčet priemerných časov fáz je približne 261 ms na simulovaný deň. Toto je headless profil bez renderovania a mesačnej uzávierky, nie meranie snímok, FPS ani porovnanie aktuálneho PR. https://github.com/Wondris404/Projekt-47/pull/3


## 2026-10-28 – Príprava verzie PR na notebooku

- Vetva PR bola naklonovaná do samostatného podpriečinka `audit/pr-laptop-20261028`; pôvodná kópia sa neprepísala. Import čistého projektu skončil s kódom 0, no na začiatku vypísal chyby fontu a obrázkov a hlásenie o bezpečnom zápise nastavení. Po importe prešla headless sonda `profile_sim` s 72 firmami a 10 dňami.
- Súčet časov fáz je približne 248 ms/simulovaný deň, maximum jedného volania 18,936 ms. Ide o jednu krátku vzorku bez vykresľovania či mesačnej uzávierky; nemožno z nej vyvodzovať FPS, porovnanie výkonu ani pripravenosť dema. Spustenie grafiky a základnej hry ešte treba overiť.


## 2026-10-28 – Vyriešenie konfliktu mapy v PR

- Do pracovnej vetvy PR bola pripravená aktuálna hlavná vetva vrátane novšieho Atlasu. Konflikt pripojenia signálu v world_map.gd je vyriešený kontrolou existencie okna aj toho, či je signál už pripojený. Hlavná vetva sa tým nemení.
- Import čistého projektu prebehol; prvotné chyby zdrojov počas importu zostávajú otvorené. Výsledky testov budú doplnené po dokončení.

- Lokálny Windows audit_unit skončil s kódom 0, vrátane kontroly odpojenej mapy a 62-dňovej zhody simulácie. Test zálohy úmyselne vyvolal chybu otvorenia súboru a potvrdil ochranu pôvodného slotu.


## 2026-10-28 – Príprava Windows balíka pre testerov

- Pridaný exportný profil pre 64-bitový Windows a postup GitHub Actions na vytvorenie ZIP balíka. Postup overuje SHA-256 oficiálneho Godotu a šablón, exportuje hru a spúšťa headless sondu priamo z exportovaného programu s oddelenými používateľskými dátami.
- Prvé zostavenie a spustenie ešte nie sú potvrdené. Balík je plánovaný ako časovo obmedzený artefakt GitHub Actions, nie zverejnený release; grafické spustenie a použiteľnosť na počítači testera treba samostatne overiť.


## 2026-10-28 – Overenie Windows exportu

- Prvý pokus skončil chybou, pretože release export neobsahoval konzolový spúšťač testu. Exportný profil bol upravený; opakovaný beh `40712990280` úspešne overil kontrolné súčty, zostavil hru a z exportu vykonal 10 dní simulácie bez GDScript chyby.
- GitHub vytvoril artefakt `Projekt-47-Windows`, dostupný 30 dní v danom behu. Artefakt je ZIP obsahujúci ďalší ZIP hry, takže treba rozbaliť oba. Jeho stiahnutie môže vyžadovať prihlásenie do GitHubu. Grafické spustenie na notebooku a ukladanie z exportu ešte neboli overené; chyby pri prvom importe zdrojov zostávajú otvorené. https://github.com/Wondris404/Projekt-47/actions/runs/40712990280


## 2026-10-28 – Oprava prípravy Windows balíka po zlúčení

- Všetky štyri existujúce PR sú zlúčené. Staršie neúspešné behy exportu a profilu boli opravené a ich opakované behy prešli; referencia katalógu zostáva neoverená.
- Postup zostavenia Windows balíka bol upravený, aby sa spustil aj po relevantnej zmene hlavnej vetvy a artefakt tvoril jediný ZIP s hrou a návodom. Test zmeneného postupu a grafické spustenie na notebooku ešte nie sú potvrdené.


## 2026-10-28 – Overenie opravy balíka

- Beh `40715336351` úspešne zostavil Windows hru, vykonal headless skúšku 10 dní a odovzdal artefakt `Projekt-47-Windows`. Nový postup odovzdáva súbory hry priamo do artefaktu namiesto vnútorného ZIPu. Automatické spustenie na `main` sa prejaví až po zlúčení; grafické spustenie a uloženie z balíka zostávajú neoverené. https://github.com/Wondris404/Projekt-47/actions/runs/40715336351


## 2026-10-28 – Skúška malého viewportu

- Pridaná diagnostika `tests/small_viewport_probe.gd`. Pri lokálnom Windows headless spustení v izolovaných používateľských dátach ukázala: fyzické okno 240 × 150 má logický viewport 1280 × 800, zatiaľ čo umelý podviewport 240 × 150 vytvorí panel 300 × 180 mimo jeho hraníc.
- Sonda nemení herný stav ani ekonomiku. Nie je to dôkaz chyby pri bežnom hraní; grafické zobrazenie, škálovanie a obsah okien treba ďalej overiť. Úprava panelov zatiaľ nebola vykonaná. Lokálna verzia testu prešla s návratovým kódom 0; úplná testovacia sada sa pri tejto čisto diagnostickej zmene nespúšťala.

- Nezávislé čítanie kódu potvrdilo logický základ 1280 × 720 a režim `canvas_items`/`expand`. Pri bežnej zmene veľkosti sa nenašiel dôkaz logického viewportu pod minimami panelov; titulky a zatváracie tlačidlá ležia mimo posúvaného obsahu a niektoré prvky majú vlastné minimá. Samotné zmenšenie panelov by preto nemuselo sprístupniť celý obsah.


## 2026-10-28 – Grafická skúška malého okna na notebooku

- Po súhlase používateľa sa lokálna izolovaná kópia hry spustila cez OpenGL Compatibility na AMD Radeon Graphics. Pri fyzických veľkostiach 800 × 450 a 480 × 270 bol logický viewport 1280 × 720. V testovanej scéne bol panel krajiny vrátane tlačidla zatvorenia v hraniciach viewportu. Snímky sa vizuálne skontrolovali; pri 480 × 270 je text veľmi drobný.
- Počiatočná snímka obsahovala úvodné logo, nie hru; nepoužíva sa ako dôkaz. Opakovaná skúška po ukončení úvodnej obrazovky zachytila herný panel. Toto nie je test všetkých panelov, systémových mierok DPI ani skutočného kliknutia; hranica umelého SubViewportu zostáva. Save a ekonomika sa nemenili.

- Následná grafická skúška poslala udalosti stlačenia a uvoľnenia myši cez vstupný systém Godotu na tlačidlo zatvorenia panelu krajiny. Panel sa zavrel pri oboch rozmeroch 800 × 450 a 480 × 270. Nejde o fyzické kliknutie ani o test ostatných panelov či systémového škálovania.
## 2026-10-28 – Diagnostika dát mimo zdrojov hry

- Overený nález z dokumentu od Copilota: `DataLoader._log_data` zapisoval pri proxy dátach do `res://docs/DATA.md`. V izolovanej kópii Windows sonda pred opravou potvrdila zmenu projektového súboru a neprítomnosť používateľského logu.
- Diagnostika sa teraz pripája do `user://data_warnings.log`; pri chybe zápisu sa zobrazí varovanie. Po oprave sonda potvrdila nezmenený projektový súbor a obe pridané správy, exit 0. Log sa môže časom zväčšovať; rotácia nie je zavedená. Ekonomické výpočty a save sa nemenia. Ďalšia auditná sada sa ešte vykonáva.

- Po oprave prešla na Windowse lokálna auditná sada `audit_unit` (46 kontrol, exit 0), vrátane porovnania stavu po 62 dňoch. Kontrola chyby zálohy zámerne vyvolala chybu otvorenia izolovaného súboru a potvrdila ochranu slotu. Úplná jednotková sada nebola v tomto kroku spustená.


## Pre-Beta-0.9 — základ 3D geometrie krajín (2026-10-28)

- Pridaný prevod už vyčistenej a triangulovanej 2D geometrie krajín do roviny X/Z v 3D. Prevádza existujúce súradnice a indexy bez zmeny ekonomiky, RNG alebo uložených hier; zatiaľ sa nezapája do bežnej hry.
- Headless kontrola porovnala polohy vrcholov a indexy pre 165 neprázdnych geometrických objektov krajín: 0 chýb, exit 0. Grafická skúška na notebooku (Godot 4.7.2, AMD Radeon Graphics, GL Compatibility) vykreslila 1280 × 720 náhľad; snímka je v `audit/screenshots/prebeta-3d/world-geometry.png`. Test používa jednoduché diagnostické farby a obojstranný materiál.
- Ide iba o statický geometrický základ, nie hrateľný 3D režim. Chýbajú výšky terénu, interakcia a kamera v hre, mestá, firmy, rieky, modely, výkonové merania a vizuálne porovnanie rovnakej oblasti v oboch režimoch. Pred týmto novým prevodníkom neexistovala jeho 3D implementácia; bežný predchádzajúci audit prešiel pri práci na PR #9. Používanie obojstranného materiálu a orientácia trojuholníkov vyžadujú ďalšie riešenie.
## Pre-Beta-0.9 — grafická sonda snímok na notebooku (2026-10-28)

- Pridaná `tests/prebeta_frame_probe.gd`: nová hra so seedom 47 pre každý index rýchlosti 1/2/3, 90 zahrievacích a 240 meraných snímok; meria intervaly medzi signálmi snímok vrátane čakania na obmedzenie FPS. Výsledky uvádzajú priemer, p95, p99, maximum, počet intervalov nad 16,67 ms a počet dokončených dní. Nejde o čistý CPU alebo GPU čas a zaokrúhlenie i časovač pri limite 60 FPS ovplyvňujú počet nad prahom.
- Dva lokálne grafické behy s AMD Radeon Graphics, GL Compatibility a Godot 4.7.2 (izolované dáta, pracovná kópia s rozpracovaným PR #9): index 1 priemer 17,29/16,81 ms, p95 22,27/20,36 ms, p99 28,89/28,44 ms, max 31,47/31,31 ms; index 2 priemer 20,26/20,28 ms, p95 37,31/37,50 ms, p99 38,44/38,39 ms, max 40,40/39,95 ms; index 3 priemer 27,16/27,49 ms, p95 42,57/43,33 ms, p99 43,80/44,77 ms, max 45,38/47,91 ms. Oba behy exit 0. Krátka vzorka môže obsahovať zahriatie, šum OS a rôzny simulačný deň; nie je párovým porovnaním verzií.
- Skript bol spustený na lokálnej verzii s PR #9, nie na čistom main; na GitHub main treba ešte overiť presný commit, všetky scenáre a výkon exportu. Pamäť, GPU časy, hustá oblasť a portfólio zatiaľ neboli zmerané. 3D režim ešte neexistuje.

- Overený lokálny experiment zmenšil dávku `IndustrySystem.settle_chunk` zo 4 firiem na 1 bez zmeny ich poradia. Po zmene rovnaká krátka sonda namerala pri indexe 1 priemer 16,88 ms, p99 26,67 ms, indexe 2 priemer 22,79 ms, p99 41,64 ms a indexe 3 priemer 25,60 ms, p99 44,18 ms. Jediný beh nepreukázal konzistentné zlepšenie (najmä index 2 sa zhoršil), preto experiment nebol zaradený do PR a lokálny kód bol vrátený na pôvodnú hodnotu. Nemeriame tým vplyv na stav ekonomiky; pokračovať treba diagnostikou jednotlivých fáz a grafických nákladov.
## Pre-Beta-0.9 — úvodný vizuálny inventár (2026-10-28)

- Pridaný `docs/PREBETA_09_VIZUALNY_INVENTAR.md`: východiskový zoznam 61 podnikových typov a 28 komodít z GitHub main `5d8f407`, plus ďalšie skupiny na inventarizáciu 3D podkladov.
- Kontrola katalógov pred tvorbou a kontrola pokrytia ID v uloženom dokumente prešli; ID sú jedinečné a názvy neprázdne. Stav modelov a licencií je zatiaľ neoverený, nejde o zoznam hotových modelov. Zmena je iba dokumentačná, bez zmien hry alebo ekonomiky.
- Ďalej: overiť geografické údaje, zostaviť vizuálnu špecifikáciu, vybrať referenčnú oblasť a vytvoriť hrateľný 3D prototyp s meraním výkonu. Kompletný inventár UI a správ ešte chýba.
## Pre-Beta-0.9 — úvodné zmapovanie a lokálna sonda (2026-10-28)

- Schválený zámer: strategická 3D mapa, obnoviteľný pixelový režim, nové rozhranie a slovník, 3D modely a optimalizácia. Implementácia ešte nezačala.
- GitHub main používa GL Compatibility; PR #8 pre škálovanie okien je stále rozpracované. Testovací `tests/run_all.sh` má pascu, ktorá maže dočasný priečinok; vzhľadom na zákaz mazania sa nespúšťal.
- Existujúci `tests/profile_sim.gd` sa spustil v lokálnom projekte (ktorý nie je overenou kópiou aktuálneho main), Godot 4.7.2, seed 47, 72 firiem a 10 dní, izolované používateľské dáta. Dokončil sa s exit 0. Súčet priemerov fáz podľa vypísaných vzoriek je približne 263,45 ms/deň; najdlhšie volanie fázy 20,415 ms. Ide o jednu headless vzorku bez merania FPS alebo grafiky, nie porovnanie výkonu verzií.
- Ďalej: zosúladiť čistý pracovný základ s GitHub main bez zásahu do existujúcich zmien, zmerať snímky v reálnom grafickom okne pri všetkých rýchlostiach, vykonať cielené testy a vybudovať hrateľný prototyp. 3D mapa ani modely zatiaľ nie sú hotové.


## Pre-Beta-0.9 — návrat voľby pixelovej mapy (2026-10-28)

- V hernej lište je opäť prepínač Atlas / Pixelová mapa; zmena sa ukladá do používateľských nastavení a predvolenou mapou starých nastavení je Atlas. Poloha kamery a herný stav sa pri prepnutí nemenia. Nový 3D režim zatiaľ neexistuje.
- Izolovaný pracovný základ vychádza z lokálneho commitu PR #3; zmenené herné skripty oproti GitHub main boli porovnané pomocou Git blob SHA a DataLoader bol doplnený z main. Nejde o úplne totožnú git históriu GitHub main.
- Pred zmenou prešiel headless `audit_unit` (exit 0; zámerná chyba vytvorenia zálohy v teste sa vypísala ako ERROR). Po zmene na notebooku s AMD Radeon Graphics a rendererom Compatibility prešli dve grafické sondy: prepnutie, zachovanie kamery, uloženie a obnovenie nastavenia; test načítania v3 a mapových vrstiev. Godot pri ukončení sond uviedol úniky ObjectDB (33 a 57); nie je potvrdené, či sa prejavujú počas hry. FPS a reálne systémové DPI sa v tomto kroku nemerali.
- Ďalej: grafický prototyp 3D mapy a výkonové merania; celá Pre-Beta-0.9 ešte nie je dokončená.
## 2026-10-28 – Kontrola a rozpracovaná oprava panelov pri mierke

- Na notebooku s AMD Radeon Graphics sa pri veľkostiach okna 1280 × 720, 800 × 450 a 480 × 270 kontrolovali panely krajiny, mesta, firmy, burzy a portfólia: hranice, dostupnosť tlačidla, simulované zatvorenie cez Godot a nastavenie zvislého posuvu. V týchto scenároch prešli všetky kombinácie, text v najmenšom okne bol veľmi drobný.
- Pri simulácii mierky Godotu 100 %, 125 % a 150 % (nie zmeny systémového DPI Windows) sa pri 150 % potvrdil presah panelov Burza a Portfólio a čiastočne skryté zatvorenie. Ich obsah má väčšiu vnútornú minimálnu šírku než bola použitá pri výpočte polohy.
- Rozpracovaná oprava na vetve `codex/fix-scaled-window-position` zohľadňuje minimálnu veľkosť obsahu a pri jej zmene opätovne upraví polohu okna. Lokálna grafická sonda na notebooku po oprave vykázala úspešných 15 kombinácií panelov a mierok; pred/po snímky sú zatiaľ len v lokálnom testovacom priečinku. Pridaná samostatná regresná sonda sa ešte musí samostatne spustiť, celá sada ani dopad na FPS neboli po zmene overené. Skutočné systémové DPI a panely nad rámec uvedených piatich zostávajú neoverené.


## Overenie presnej sondy PR #8 (2026-10-28)

- Presné súbory `tests/scaled_panels_ui.gd` a `scripts/ui/window_drag.gd` z vetvy PR #8 sa spustili v samostatnej lokálnej kópii projektu na AMD Radeon Graphics s Godot 4.7.2 a GL Compatibility. Všetkých 15 kombinácií piatich panelov a faktorov Godotu 100/125/150 % prešlo: rám a tlačidlo zatvorenia v logickom viewporte, posúvanie a simulované zavretie; exit 0.
- Prvý pokus pred importom zdrojov neprešiel, keďže čistá kópia nemala importované textúry. Po importe bol test spustený znova úspešne; prvý import vypísal známe chyby zdrojov pri inicializácii.
- GitHub kontrola `windows-demo` pre head 5f4fd484 prešla. Systémové DPI Windows, fyzické kliknutie, presun a zmena veľkosti po oprave a výkon ešte nie sú týmto testom overené. PR zostáva rozpracované.

- Následne na rovnakej izolovanej kópii s presným kódom PR prešlo 12 existujúcich GUI kontrol vrátane simulovaného ťahania, zmeny veľkosti, obmedzenia na viewport a straty fokusu (`window_ui`, exit 0). Pridané sú lokálne snímky Burzy pred/po pri faktore Godotu 150 % z predchádzajúcej lokálnej experimentálnej sondy; nejde o snímky zo systémového DPI Windows.


## Pre-Beta-0.9 — skúšobný 3D pohľad v hre (2026-10-28)

- V lište je experimentálne tlačidlo „3D skúška“. Otvára 3D pohľad z existujúcich vyčistených hraníc, podporuje ťahanie, koliesko a výber krajiny s otvorením jej panelu. Pri prepnutí sa prenáša stred a približná mierka kamery; po návrate sa 3D scéna uvoľní. Výpočet a save formát sa nemenia.
- Na notebooku s AMD Radeon Graphics a Godot 4.7.2 GL Compatibility prešla grafická sonda prepnutia, prevodu súradníc, výberu Slovenska, zoomu, zachovania stredu kamery a návratu, aj kontrola pozastaveného dňa. Samostatná existujúca sonda pixel/Atlas prešla. Pri ukončení sond Godot hlásil 15 a 33 ObjectDB únikov; príčina nebola zisťovaná. Snímky pred a po sú v audit/screenshots/prebeta-3d/. Simulované udalosti nenahrádzajú fyzickú skúšku vstupu.
- Toto je len skúšobný pohľad, nie dokončená 3D hra: chýba terén, mestá, firmy a ich výber, rieky, modely, vrstvy obchodu, vhodná grafika aj meranie FPS a pamäte. Vytváranie 165 mesh objektov pri otvorení môže spôsobovať zásek; zatiaľ nebolo merané. Prepínanie počas stavby a regionálneho pohľadu treba preveriť. Grafická skúška porovnáva ten istý stred, nie rovnaký výtvarný vzhľad.


## Pre-Beta-0.9 — skutočné mestá v skúšobnom 3D pohľade (2026-10-28)

- Skúšobný 3D pohľad načíta mestá cez existujúci TerrainSystem a zobrazí ich v rovnakých mapových súradniciach pomocou zdieľaného MultiMesh. Pri priblížení možno vybrať mesto a otvoriť existujúci mestský panel. Výber prázdneho územia stále otvára krajinu; ekonomické dáta a save sa nemenia.
- Na notebooku s AMD Radeon Graphics a Godot 4.7.2 prešla rozšírená grafická sonda: výber Bratislavy otvoril jej panel, výber krajiny fungoval, prechod a stred kamery, zoom a pozastavený deň ostali správne. Dva behy exit 0; pri ukončení druhého bolo hlásených 12 ObjectDB únikov. Snímka detailu je v `audit/screenshots/prebeta-3d/cities-detail.png`. Skúška vstupu je simulovaná.
- Budovy sú zatiaľ jednoduché dočasné hranoly, všetky mestá sú v jednom MultiMesh a plné culling a výkon ešte neboli zmerané. Mestské popisy na mape, firmy, výškový terén, rieky, vizuálne modely a kompletná interakcia zatiaľ chýbajú; neoznačovať to za hotový 3D režim.


## Pre-Beta-0.9 — hráčove firmy v skúšobnom 3D pohľade (2026-10-28)

- Hráčove otvorené firmy sa zobrazujú na ich existujúcich mapových pozíciách oranžovým dočasným modelom. Výber má pri priblížení prednosť pred mestom a otvorí existujúci detail firmy. Poloha používa rovnakú funkciu ako pôvodná mapa; pri vytvorení, presune alebo zavretí sa zoznam aktualizuje po zmene údajov, nie na každej snímke. Firma nemá v tomto kroku nový ekonomický stav ani nové save polia.
- Grafická sonda na notebooku (Godot 4.7.2, AMD Radeon Graphics, GL Compatibility) prešla dvakrát: vytvorenie testovacej kaviarne, pozícia, výber a otvorenie detailu, presun a odstránenie zatvorenej firmy z vrstvy, ako aj existujúce kontroly kamery a výberu miest/krajín. Druhý beh skončil exit 0 s hlásením 6 ObjectDB únikov pri ukončení. Snímky pred založením a po založení testovacej firmy: `audit/screenshots/prebeta-3d/firm-before.png` a `firm-after.png`.
- Tvar firmy je stále diagnostický hranol, nie hotový typovo odlíšený model. Chýbajú konkurenčné podniky a bankové značky, menovky, terén, optimalizované načítavanie po regiónoch, výkonnostné meranie a fyzická skúška myšou. Plná 3D mapa nie je dokončená.


## Pre-Beta-0.9 — prvý licencovaný 3D model mesta (2026-10-28)

- Do skúšobného 3D pohľadu bol pridaný model `building-a.glb` od Kenney z City Kit (Commercial), CC0. Zdroj prevzatého GLB, pôvodný balík, hash a úpravy sú uvedené v `assets/models/city_kenney/README.md`. Model sa zdieľa cez MultiMesh; pri nedostupnom importe sa použije jednoduchý náhradný tvar.
- Kamera je mierne naklonená, aby boli viditeľné fasády. Výber mesta, firmy a krajiny, zväčšenie a prevod stredu kamery testovala grafická sonda na notebooku (Godot 4.7.2, AMD Radeon Graphics, GL Compatibility): exit 0, pri ukončení 6 hlásených ObjectDB únikov. Starší plochý pohľad je `audit/screenshots/prebeta-3d/cities-detail.png`, nový `audit/screenshots/prebeta-3d/cities-kenney.png`; ide o podobnú oblasť s iným uhlom kamery.
- Použitie modelu v exporte, výkon vrstvy, detailná čitateľnosť a rôzne veľkosti miest zostávajú neoverené. Jeden opakovaný model nestačí na dokončenie katalógu a 3D režim zostáva prototypom; chýbajú terén, rieky a typové modely firiem.


## Pre-Beta-0.9 — rozloženie prípravy 3D geometrie (2026-10-28)

- Meranie na notebooku (Godot 4.7.2, AMD Radeon Graphics, GL Compatibility, 48 hráčových firiem, seed 47) ukázalo jednorazové prvé otvorenie 3D 104,03 ms. Príprava geometrie krajín sa teraz odkladá a po približne 2 ms práce sa prenesie do ďalšej snímky. Tlačidlo zobrazí pohľad ihneď, hranice pribúdajú postupne. Opravené je aj otvorenie pri nulovej veľkosti mapy a rýchle zatvorenie, ktoré predtým mohlo nastaviť neplatný posun kamery.
- Rovnaká krátka sonda po zmene zaznamenala prvé otvorenie 57,61 ms; ďalšie otvorenia 4,84 a 5,73 ms, pred zmenou 13,03 a 12,54 ms. Ide o jednotlivé behy v tom istom scenári, nie štatisticky spoľahlivé porovnanie; otvorenie stále prekračuje 16,7 ms. Predchádzajúci skorý pokus bez vyčistenia nahromadeného časového dlhu nebol použitý na porovnanie.
- Ustálené 3D snímky: priemer pred/po pre rýchlosti 1/2/3 16,62/16,63; 16,67/16,65; 20,14/20,31 ms; p99 18,76/17,66; 27,88/27,54; 35,81/35,95 ms. Sú to intervaly medzi snímkami vrátane limitu FPS, vzorky 180 snímok, 45 zahrievacích snímok. Rýchlosť 3 naďalej presahuje cieľ; príčina a pamäť zostávajú na ďalšie meranie. Sonda je `tests/prebeta_3d_profile.gd`.
- Grafická regresia prešla na rovnakom notebooku: dokončenie geometrie, mestá, firmy, výber, kamera a rýchle zavretie/opätovné otvorenie. Po oprave neplatnej kamery exit 0 bez zistených chýb v zobrazenom výstupe. Rozloženie nemení výpočet hospodárstva ani formát uloženia; úplná ekonomická porovnávacia sonda a test v exportovanej hre sa pri tomto kroku nespustili.


## Pre-Beta-0.9 — mapový podklad a hranice v 3D skúške (2026-10-28)

- 3D geometria krajín má UV súradnice odvodené z pôvodnej mapy a používa existujúcu textúru `assets/atlas/world.jpg`. Pridané sú tmavé obrysy hraníc ako jeden spoločný čiarový mesh; nezasahuje sa do geografických dát, výpočtov ani save. Pri chýbajúcej textúre zostáva náhradné farebné zobrazenie. Výsledok je stále plochý, nejde o výškový terén.
- Test prevodu geometrie pre 165 neprázdnych objektov overil súradnice, indexy a UV, exit 0; grafická sonda na notebooku (Godot 4.7.2, AMD Radeon Graphics, GL Compatibility) overila zobrazenie a predchádzajúce interakcie, exit 0. Snímky rovnakého pohľadu pred/po sú v `audit/screenshots/prebeta-3d/terrain-before.png` a `terrain-after.png`.
- Krátka sonda so seedom 47 a 48 firmami: prvé otvorenie 3D pred/po 57,61/66,04 ms; ustálený priemer pre rýchlosti 1/2/3 16,63/16,66; 16,65/16,67; 20,31/20,29 ms, p99 17,66/18,06; 27,54/27,95; 35,95/35,31 ms. Každá hodnota pochádza z jedného krátkeho behu, intervaly zahŕňajú limit FPS a nie sú štatisticky spoľahlivým meraním samotného GPU. Otvorenie i rýchlosť 3 zostávajú nad cieľom.
- Chýbajú 3D výšky, podrobné textúry pri veľkom priblížení, menovky, rieky a kompletné modely. Hranice pribudnú až po dokončení postupného vytvárania geometrie; čas vytvorenia celého čiarového meshu a veľké výrezy ešte vyžadujú profilovanie. Export hry ani fyzický vstup v tomto kroku neboli overené.


## Pre-Beta-0.9 — názvy krajín a miest v 3D skúške (2026-10-28)

- Pridaná samostatná priehľadná vrstva názvov: pri oddialení používa názvy a vypočítané stredy krajín, pri priblížení skutočné názvy a súradnice miest. Kolízie textových obdĺžnikov sa obmedzujú podľa poradia; vrstva neodoberá vstup myši. Názvy sa prekresľujú po presune, zoome a zmene veľkosti, geometria stredov krajín sa počíta pri otvorení.
- Na notebooku s AMD Radeon Graphics a Godot 4.7.2 prešla existujúca grafická sonda miest, firiem, kamery, výberu a opätovného otvorenia (exit 0), navyše kontrola, že textová vrstva neblokuje myš. Snímky pred/po: `audit/screenshots/prebeta-3d/labels-before.png` a `labels-after.png`, priblížené mestá `labels-cities.png`. Kontrola názvov je vizuálna, nie úplný automatizovaný audit čitateľnosti a geografickej presnosti.
- Krátky lokálny profil finálnej verzie (30 snímok, 48 firiem, 0 dokončených dní) nameral prvé otvorenie 79,35 ms, priemer 18,34 ms a maximum 71,44 ms. Nejde o meranie ustáleného FPS a výpočet otvorenia aj asynchrónna geometria ešte prekračujú rozpočet; ďalšia optimalizácia a meranie počas presunu mapy sú potrebné. Texty sa v hustých miestach zámerne vynechávajú, zatiaľ bez ďalšieho výberu priority.


## Pre-Beta-0.9 — skúšobný model priemyselnej firmy (2026-10-28)

- Pre 12 vybraných typov priemyselných podnikov a skladov sa v 3D skúške zobrazuje prvý spoločný model Kenney City Kit (Industrial) s oranžovou značkou vlastníka. Aktuálne pozície a kliknutia používajú existujúce údaje firiem; ostatné firmy majú pôvodný dočasný marker. Model a externá textúra vrátane zdroja, licencie CC0 a hashov sú zaznamenané v `assets/models/industrial_kenney/README.md`.
- Model sa načítava na pozadí; počas načítania zostáva jednoduchý marker. Grafická sonda na notebooku (Godot 4.7.2, AMD Radeon Graphics, GL Compatibility) prešla pre vytvorenie oceliarne, načítanie modelu, výber a otvorenie detailu, zatvorenie firmy, výber mesta, krajiny a prenos kamery, exit 0. Pri ukončení sa objavilo jedno upozornenie o uvoľnení ObjectDB; opakované otváranie sa má ďalej sledovať. Snímky `audit/screenshots/prebeta-3d/factory-before.png` a `factory-after.png` sú podobná oblasť pred/po vytvorení firmy, nie porovnanie tej istej uloženej hry.
- Krátka sonda so 48 firmami a bez dokončeného simulačného dňa: prvé otvorenie približne 84,35 ms, priemer 18,30 ms a maximum 69,32 ms na 30 snímkach po zavedení asynchrónneho načítania. Pred pridaním modelu obdobná sonda ukázala 79,35 ms; nejde o spoľahlivé párové meranie. Cieľ 16,7 ms zatiaľ nie je dosiahnutý a účinok na export ešte nie je overený. Modely pre jednotlivé typy, elektrárne, ďalšie firmy a detailný terén zostávajú otvorené.


## 2026-10-29 – Príprava inštalátora Windows

- Doplnený PowerShell inštalátor: vyberie zverejnené demo, overí SHA-256 a nainštaluje do nového priečinka bez prepisovania súborov. README obsahuje jeden spúšťací príkaz.
- Po úspešnom exporte môže manuálne spustený workflow vytvoriť predbežné vydanie s unikátnym tagom, balíkom a kontrolným súčtom; existujúce vydania sa neprepisujú.
- Overenie v PowerShell 5.1: funkčný lokálny falošný balík, odmietnutie existujúceho cieľa, nesprávneho súčtu a neočakávaného obsahu. Overený lokálny cyklus zabalenie → overenie → inštalácia. Skutočné vydanie a verejné stiahnutie v tomto okamihu ešte nie sú overené.


## 2026-10-29 – Prvé zverejnenie testovacieho balíka

- Publikačný krok sa okrem manuálneho spustenia môže spustiť jednorazovo konkrétnym iniciačným commitom nad uvedeným rodičom. Stále závisí od úspešného zostavenia a skúšky exportu; ďalšie bežné commity vydanie nevytvárajú. Vydanie používa unikátny tag a existujúce súbory neprepisuje.
- Kontrola podmienky: manuálne spustenie na main je povolené; bežný push, pull request aj push z iného rodiča sú odmietnuté. Skutočný beh a verejné stiahnutie treba po commite ešte overiť.
