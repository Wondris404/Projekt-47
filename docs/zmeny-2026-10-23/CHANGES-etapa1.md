# CHANGES-etapa1 (work1 vs work = Etapa 0). 1 riadok = 1 zmena. Cisla riadkov = work1.

## Krok 1 - ponuka z kapacit, populacia, normalizacia share
- scripts/autoload/MarketSystem.gd:411-427 `_one_demand`: dvojite zapocitanie populacie odstranene (spend uz obsahuje HDP; product/population namiesto product/1e6).
- scripts/autoload/MarketSystem.gd:343-352 `_update_capacity`: nova kapacita `dref` (EMA tau=60 d referencneho dopytu pri base cene, bez tod/weekday vplyvu).
- scripts/autoload/MarketSystem.gd:384-409 `_cache_supply`: ponuka = svetovy dref x normalizovany share x sokovy nasobok (sezona vydelena); obchodny uzaver S=(1-phi)P+phi*f*dref; netradovatelne S=dref*sok.
- scripts/autoload/MarketSystem.gd:363-382 `_openness`: otvorenost phi z blokovanych/embargovanych partnerov (vaha HDP), x0.55 vo vojne.
- scripts/autoload/MarketSystem.gd:27-48 `init_books`: knihy startuju v rovnovahe (cena=base, zasoba=42 dni dopytu, dref nastavene).
- scripts/autoload/MarketSystem.gd:66-73 `begin_day`: volanie `_cache_demand/_update_capacity/_cache_supply` raz za den.
- scripts/autoload/DataLoader.gd:163-190 `share`, `_normalized_shares`, `_raw_share`: share normalizovany na sucet 1 po komodite (povodna logika = `_raw_share`; sucet bol 1.4-2.0).
- scripts/autoload/GameState.gd:598 `validate_save`: pole "dref" medzi ciselnymi polami knihy (stare savy bez dref sa doplnia pri prvom begin_day).
- scripts/autoload/GameState.gd (`validate_save`, world): volitelne `cpi_hist` (pole <=60 cisel, 0<x<=1e6, bez NaN/inf), `cpi_acc`, `cpi_n` (cele >=0), `war_gdp_pen`; (central): `prev_rate` (-0.5..10), `upd_day` (cele >=-1). Pokazene = odmietnute.
- scripts/autoload/GameState.gd (`_repair_after_load`): defaulty chybajucich poli (cpi_hist=[], cpi_acc=0, cpi_n=0, prev_rate=base_rate/policy, upd_day=-1) -> save v2 z etapy 0 sa nacita (test e1_load_v2_without_new_fields, e1_reject_* 16 pripadov).
## Krok 2 - stabilne ceny
- scripts/autoload/MarketSystem.gd:255-291 `_clear_one`: namiesto bezpamatoveho base*(D/S)^e sa vola `adjust_price` (denny tlmeny krok); `power_price` ostava (sonda), nova cena sa uz nevyraba z neho.
- scripts/autoload/MarketSystem.gd:192-200 `adjust_price`: pouzita beze zmeny (gap orezany (-0.65,1.1)*0.05, vplyv zasob +-0.012, pasmo 0.22-6.5 x base).
- scripts/autoload/MarketSystem.gd:411+ `_one_demand`: financny clen dopytu delený cenou (EUR -> jednotky), predtym necitlivy na cenu.
## Krok 3 - CPI
- scripts/autoload/MarketSystem.gd:210-253 `CPI_BASKET`, `cpi_weights`, `cpi_index`, `_accumulate_cpi`, `cpi_month_average`: vazeny kosik 10 komodit (vaha komodity x nasobok chudobni/bohati), denna akumulacia, mesacny priemer.
- scripts/autoload/MarketSystem.gd:202-208 `clear_all`: po cisteni volá `_accumulate_cpi(iso)`.
- scripts/autoload/GameState.gd:172-190 `_macro`: yoy z priemeru 3 mesiacov vs rovnake 3 mesiace pred rokom (`cpi_hist`, 25 hodnot), pouzite az od 15 mesiacov historie (predtym ostava datova inflacia), orezanie [-0.25, 0.60], lerp 0.3.
- scripts/autoload/GameState.gd:42-43 `INFL_MIN/INFL_MAX`.
## Krok 4 - sadzba
- scripts/autoload/BankingSystem.gd:649-655 konstanty TAYLOR_* a RATE_SMOOTH/RATE_MIN/RATE_MAX.
- scripts/autoload/BankingSystem.gd:657-675 `update_rates`: Taylor (r*=0.015, pi*=0.02, a_pi=1.5, a_y=0.5, + premia stability), vyhladzovanie RATE_SMOOTH=0.6 na krok (krok = mesacne volanie z GameState:166; denna poistka `prev_rate`/`upd_day` len proti viacnasobnemu volaniu v ten isty den) (`prev_rate`/`upd_day`), podlaha 0.002, strop 0.40.
## Krok 5 - soky
- scripts/autoload/GeopoliticsSystem.gd:350-369 `WAR_GDP_PEN`, `_start_war`: odpocet gdp_growth -0.015 sa eviduje v `world[iso].war_gdp_pen` (nove pole).
- scripts/autoload/GeopoliticsSystem.gd (`_end_war`) : VRATENE `post_news("Prímerie: ...")` z work/ (v prvej verzii etapy 1 chybalo) + test e1_end_war_news.
- scripts/autoload/GeopoliticsSystem.gd (`_war_recovery`): vrati presne -0.015 za KAZDU skoncenu vojnu (nie len raz); `infra_damage` sa ruší az ked krajina nema dalsiu vojnu; stary save bez `war_gdp_pen` = predpoklad 0.015 za vojnu. Testy e1_two_wars_*, e1_war_recovery_old_save.
- scripts/autoload/GeopoliticsSystem.gd:146-162 `make_peace`: ukoncene vojny volaju `_war_recovery` (cesta hraca).
- Navrat cien po soku zabezpecuje denny tlmeny krok `adjust_price` + EMA kapacity (ziadna dalsia zmena modelu); SANKCIA sa ruší `lift_sanction`, EMBARGO inou funkciou `lift_embargo` (GeopoliticsSystem.gd:84; `lift_sanction` po embargu vrati "Žiadna sankcia." a `blocked` ostane true - overene testom e1_lift_sanction_does_not_lift_embargo). Povodne tvrdenie 'embargo cez lift_sanction' bolo NESPRAVNE; test sankcia+embargo (e1_embargo_sanction_recovers) pouziva lift_embargo aj lift_sanction.
## Testy a nastroje
- scripts/main.gd:16-26: argumenty `stability [dni...] [home=XX]`, `load("res://tests/stability.gd")`.
- tests/stability.gd: `run(days, home)`, riadky P47_STAB_CRIT/CONFIG, 12-rocny beh (365/1095/2190/4380) -> audit/ETAPA1-merania.txt.
- tests/unit.gd: nahradene `_share()` (3 kontroly), pridane `_e1_supply/_e1_price/_e1_cpi/_e1_rate/_e1_shocks`; 77 -> 150 OK; `_chk` vypisuje aj info.
- tests/probe.gd: kontrola zivej ceny porovnava s `adjust_price(px_prev, ..., stock_prev, base)` namiesto `power_price` (pri adaptivnom kroku povodna rovnost neplati).
- tests/run_all.sh: pridana kontrola kriteria pasma (inband_all >= 0.95 po 365 d); docasne subory cez `mktemp -d` ($TMP, trap rm -rf po behu) namiesto pevnych /tmp/p47_*.txt.
## Golden probe (tests/golden_probe.txt) - 4 riadky, nevyhnutne (stav po poslednej uprave: RATE_SMOOTH 0.6, INFL_DECAY 0.3)
- P47_RATE 0.260000 0.021000 -> 0.272500 0.038500: nove Taylorove pravidlo + vyhladzovanie 0.6 (rychlejsia reakcia sadzby na jeden krok).
- P47_CAP 250000.0000 0.071633 -> 250000.0000 0.091713: urok uveru odvodeny od novej sadzby.
- P47_MONTH_DEBT 246522.7661 -> 246700.2854: splatka pri inej sadzbe.
- P47_LIVE ... 243024.7752 ... 0.2000 -> 243375.3520 ... 0.5887: dlh pri novej sadzbe; investicny faktor 0.2 (sadzba na strope 0.40) -> 0.5887.

## Znamé obmedzenia / NEOVERENE
- Cena v zakladnom stave je ~base z konstrukcie (obchodny uzaver phi=1, bez prepravy); stabilita zavisi od tohto predpokladu. Sok sa prejavi pri phi<1 (vojna, embargo) a sezone.
- Model nema cenovy drift: po vyhasnuti datovej inflacie (~15. mesiac) je inflacia ~0 a sadzby na podlahe 0.002 (d1095+ median 0.002). Je to vlastnost modelu, nie nastavenia pravidla; "realisticky" inflacny proces = samostatna uloha.
- ZMENA (c): vstupna datova inflacia (a +0.03 za vojnu z apply_war_shock) uz NEDRZI 14 mesiacov, ale dozniva k 0 (INFL_DECAY 0.3/mes, GameState.gd:44,195); od 15. mesiaca yoy z CPI. Dovod: Miguel v1 videl sadzbu 0.156 -> 0.006 (skok pri prechode na yoy v 15. mesiaci; rekonstruovane: 2 vojny -> inflacia 0.11 drzana, sadzba rastla na 0.25, potom pad). Dosledok: v d365 inflacia max 0.011 a sadzby max 0.060 (predtym max 0.534 / 0.40) - krajiny s vysokou datovou inflaciou (napr. AR/TR) NEMAJU vysoku inflaciu a sadzby po prvych ~6 mesiacoch; ak ju chceme drzat, treba realny inflacny proces (etapa 2).
- Medziprodukty (412 -> 179 -> 60 -> 13 -> 0 mimo pasma) su z iteracii, subory neulozene.
- Povodne vzorce nahradene v tele funkcii (power_price v _clear_one, share, inflacia, update_rates) NIE su inline oznacene `# DEAD:`; povodny kod je v work/ a v DIFF-etapa1.patch. Nevyuzity ostava `power_price` (pouziva ho sonda) a `chart` (DEAD z etapy 0).
- NEOVERENE: UI/okno, Windows, ine seedy nez 47, rezim s vojnami/katastrofami (dlhodoby 12-rocny beh), vykon, GL render, hracove firmy/pozicie pocas 12 rokov, home= nema vplyv na vystup (bez hraca).

## Dodatok po review etapy 1 (Kai/Sam/Reese) - dokumentovane, BEZ zmeny kodu (okrem opráv vyssie)
- Sadzby na podlahe 0.002 od d1095 => statny vynos (a kupony dlhopisov) je 2,35–2,66 % pri sadzbach na podlahe (QA Miguel); 0,4 % je len spodny clamp `_bond_yield`. Rozhodnutie o balanse = etapa 2; test `bond_coupon_sane` to nechyti (kontroluje len zdravy rozsah).
- golden_probe je regenerovany z NOVEHO kodu (4 riadky, zdovodnene vyssie) a `probe.gd` porovnava `adjust_price` sam so sebou (slaba ochrana pred regresiou vzorca; chybu v samotnom `adjust_price` nechyti; kryju ju len unit e1_price_* a stabilita).
- P47_LIVE 0.2 -> 0.5887 (po poslednej uprave; predtym 0.6092): investicny faktor kaviarne sa z 0.2 (sadzba na strope 0.40) zvysil ~3x. Je to herny balans - treba posudit (nie technicka chyba).
- Stabilita je konstrukcna: obchodny uzaver phi=1 (ceny ~base), ziadny drift inflacie. `DataLoader.share()` HDP-fallback (ked chyba produkcia) dava napr. JP/SK podiel na rope/kave; sok velkeho producenta (vypadok exportera) a sankcia ako "viditelny" efekt NEMERANE (meral sa len navrat po vojne SK-CZ, suchu, sankcii CZ).
- `_share_cache` (DataLoader) sa nikdy neruší (staticke data; ak by sa menili countries za behu, treba invalidovat). Vykon `_openness` (~2700 volani `blocked()`/den) NEMERANY; 12-rocny beh trva ~2 min headless.
- `BOND_FACE` (BankingSystem) je mrtva konstanta (od opravy etapy 0 nominal = zaplatena suma); nezmazana.
- `apply_war_shock` sa po mieri vracia len ciastocne: vrati sa `infra_damage` a `gdp_growth`. Nevracia sa inflacia +0.03 a trade_balance -25 %-1 (inflaciu po 15 mesiacoch prepise CPI yoy; trade_balance ide len do sheetu), political_risk +0.08 za vojnu a `site.damaged` (original mechanika).

## Dodatok - posledne drobnosti pred QA (Miguel v1)
- (a) Embargo ruší `lift_embargo` (existuje od etapy 0, GeopoliticsSystem.gd:84, UI main.gd:78); `lift_sanction` ruší len sankciu. Ziadna zmena kodu, opraveny popis a test (e1_embargo_blocks, e1_lift_sanction_does_not_lift_embargo, e1_lift_embargo_unblocks, e1_embargo_sanction_recovers: embargo CZ + sankcia DE 100 d, zrusene oboje, po 365 d 100 % v pasme; otvorenost SK pocas 1.000 -> 0.944, pasmo SK pocas 1.00 = embargo/sankcia ceny v +-30 % nevytlaci, "visible" efekt je len v otvorenosti).
- (b) SAVE_VERSION 2 -> 3 (GameState.gd:40). `_fill_e1_fields` (:719) + `_migrate_v2_to_v3` (:740, volane z from_dict pri v<3, :789) doplnia cpi_hist/cpi_acc/cpi_n, prev_rate/upd_day, dref=0.0 (0 = "nenastavene", MarketSystem._update_capacity ho pri prvom begin_day inicializuje); idempotentne. `new_game` vola `_fill_e1_fields`, takze v3 save ich ma vzdy. `validate_save` pre v>=3 POZADUJE tieto polia (:595, :618, :633), pre v1/v2 su volitelne. Testy: e1_load_v1, e1_load_v2, e1_load_v3, e1_migration_idempotent, e1_v2_loaded_runs_and_dref_initialized, pokazene v3 saves (chybajuce polia, zly typ, v4; v QA Miguela overenych 25 pokazenych v3, vsetky odmietnute). Test reject_future_version teraz pouziva SAVE_VERSION+1; save_version_current.
- (c) Test e1_two_wars_rate_stable_after_12m: SK-CZ + SK-PL od dna 30, 120 d, potom koniec oboch, 365 d; rozsah sadzby SK za poslednych 6 mesiacov = 0.0013 (limit 0.02). PRED opravou test padal (rozsah 0.0386, sadzba 0.25 -> 0.21). Pricina: inflacia +0.03 za vojnu a datova inflacia sa drzali do 15. mesiaca, potom skok na yoy (nie Taylor/clamp). Oprava: INFL_DECAY (vyssie) + RATE_SMOOTH 0.8 -> 0.6 (pri mesacnom kroku mala casova konstanta ~5 mesiacov; dozvuk sadzby siahal za okno).
- (d) Sucho v teste: JEDINA krajina SK, weather="drought", weather_left=22 d, nastavene v dni 20 (EventSystem: ponuka SK x0.62 pre wheat/coffee/meat; dopyt pseniece SK weather_factor x1.2 a demand_mult x1.05). Namerane vrcholy SK: pseniica 1.085, kava 0.993, maso 0.991; DE pseniica 0.958 (e1_drought_decomposition). Vrchol 1.09 je teda z DOPYTOVEJ zlozky pseniice; ponukovy sok SK (maly podiel na svete, obchodny uzaver phi=1 ho rozdeli globalne) cenu temer nehybe. Miguelovych 0.98-1.02 nemam jeho nastavenie, ale zodpoveda kave/masu v mojom scenari (alebo inej komodite/krajine bez dopytoveho clena) - NEPOTVRDENE, treba jeho presne nastavenie (krajina, komodita, den merania).

## Dodatok po re-review štábu v2 (23. 10. 2026, Kai/Sam/Reese: GO, 0 blokerov)
Ne-blokery, kód nezmenený, riešiť v etape 2:
1. `INFL_DECAY` 0,3 je dočasné a nerealistické: vstupná inflácia klesne pod 5 % za ~2/6/7 mesiacov pre vstup 0,10/0,30/0,534 (ODHAD Reese). Reálny inflačný proces chýba.
2. `request_loan` volá `update_rates` (`BankingSystem.gd:677`) a posúva vyhladzovanie sadzby.
3. Doplniť testy: zlý `cpi_hist` nad v1/v2 a `v:"3"` (reťazec).
4. `bond_orders` zo savu bez validácie (aj z etapy 0).
5. Po zrušení sankcie ostáva vzťah znížený, `blocked()` môže ostať true pri relation ≤ −60 (balans).
6. `P47_LIVE` 0,5887 a štátny výnos 2,35–2,66 % pri podlahe sadzieb sú herný balans na posúdenie.

## Opravy dokumentácie po QA Miguela (kód a tar bez zmeny, sha256 tar 18d6534f…416c)
- „Kupóny ~0,4 %“ bolo nepresné: štátny výnos pri sadzbách na podlahe je 2,35–2,66 %; 0,4 % je len spodný clamp.
- „100 % v pásme“ platí len pre 4 kontrolné dni (365/1095/2190/4380), nie pre každý deň.
- Počet pokazených v3 savov: v testoch pracovníka 7, Miguel overil 25, všetky odmietnuté.

## Známe obmedzenia (info, nie chyby; z QA Miguela)
- Komodita `finance` je prechodne mimo pásma (max 1,332 v d44, min 0,7435 v d259). Po načítaní savu z etapy 0 + 365 d je 6 párov `finance` mimo pásma (566/572).
- `wars:true`/`hot:true` za 12 rokov nevytvorí náhodnú vojnu (`wars.json` a `tension_seed` sú prázdne).
- Pri vojnách vyvolaných skriptom (35–37, až 9 súbežných) hra nespadla, ale pásmo kleslo na 61–95 % a ceny boli 0,22–2,55× base.
- Blokáda po vojne trvá ~27 mesiacov; sadzba SK v 2. roku krátko 0,002 → 0,036 → 0,002.
- Seedy 1, 7 a 123 sú v čistom configu identické so seedom 47.
- NEOVERENÉ: UI/okno, Windows, PowerShell, GL, výkon, firmy hráča nad 5 rokov, ručný prepočet 4 golden hodnôt.
