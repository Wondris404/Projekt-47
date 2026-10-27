# Projekt-47 — podrobný report k 18. 10. 2026

Hru spravil vývojár Wondris404. Text je v okne nad panelmi, v titulku a v popise projektu.

Toto je early-access jadro lokálneho ekonomického a geopolitického simulátora v Godot 4.7.2. Beží offline. Sieťové API sa za behu nevolajú. Z pôvodnej veľkej hry (pixel-art, skutočné hranice, plný svetový dataset, diplomacia, kampaň) je hotových asi 30 %. Zo spustiteľného jadra, ktoré sonda overuje, asi 90 %.

## Ako sa to spúšťa

Projekt je v `C:\Users\ondre\Desktop\Projekt-47`.

Okno:

`tools\godot\Godot_v4.7.2-stable_win64.exe --path C:\Users\ondre\Desktop\Projekt-47`

Kontrola bez okna:

`tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path C:\Users\ondre\Desktop\Projekt-47`

Hlavná scéna je `scenes/main.tscn`. Skript `scripts/main.gd` v headless režime nespúšťa panely. Spustí `_probe()` so seedom 47 a proces skončí. Úspech je riadok `P47_PROBE_OK` a exit 0. Posledný čistý beh po práve mal tieto riadky:

```
P47_RECIPE 1.500000 0.600000
P47_COMMODITIES 22
P47_LAW 5 8 0.30
P47_PRICE_LAW 200.000000 400.000000
P47_REGION SK
P47_RATE 0.260000 0.021000
P47_CAP 250000.0000 0.071633
P47_MONTH_DEBT 246522.7661
P47_PLACE 1
P47_BANK_RUN 1 0
P47_LIVE 1.4200 243024.7752 1 0.2000 0.0300
P47_IDS 3.1000 1.5500 2.6000
P47_HOLDINGS 1 1
P47_SAVE ok
P47_WAR 3.1000 0.7500
P47_DATE 2024-03-02
P47_PLAY 0.9000 0.5000
P47_EVENT 1.4200 0.7200 0.0100
P47_AI invest
P47_ZOOM region world
P47_LOADER 0
P47_PROBE_OK
```

Okno s panelmi som po posledných úpravách nespúšťal. Overenie je headless sonda, ktorá volá tie isté funkcie ako tlačidlá.

## Ako je hra poskladaná

Godot drží systémy ako autoload, v tomto poradí:

1. `EconMath` — pomocná matematika, nie je v povinnej desiatke.
2. `DataLoader`
3. `GameState`
4. `TimeSystem`
5. `MarketSystem`
6. `BankingSystem`
7. `IndustrySystem`
8. `GeopoliticsSystem`
9. `AgentSystem`
10. `EventSystem`
11. `SaveSystem`
12. `LawSystem` — pridaný za desiatku, poradie desiatky nemení.

`GameState` nemá `_ready`. Počas bootu nevolá systémy, ktoré ešte nie sú načítané. Nová hra vznikne až v `new_game()`.

Stav je jeden slovník: dátum, hráč, firmy, banky, centrálne banky, svet, trhy, vojny, vzťahy, správy. Deň ide funkciou `simulate_day()`:

1. počasie a sviatky
2. dopyt a ponuka firiem
3. zúčtovanie trhu
4. denná banka
5. posun dátumu o jeden deň
6. ak sa zmenil mesiac: makro, sadzby, mesačná splátka, vojny, AI, eventy

V Godot 4.7 sa na Variant nepíše `:=`. Parser to berie ako chybu. V projekte je `=`.

## Dáta

`DataLoader` načíta JSON z `res://data`. Keď súbor chýba alebo je neplatný, vyrobí malé proxy dáta a pripíše riadok do `docs/DATA.md`. Čistý boot nechá `DataLoader.errors` prázdne.

Boot sada má 16 krajín a príznak `fallback: true`: SK, CZ, DE, PL, AT, HU, FR, UA, US, CN, RU, SA, NO, NL, GB, BR. Čísla sú zjednodušený štart, nie živý ťah zo Svetovej banky. Mapa sú neprekrývajúce sa obdĺžniky 1440×720. Klik dovnútra prvého obdĺžnika vráti SK, bod mimo mapy nevráti nič.

22 komodít. Medzi nimi sú povinné id `arms`, `chemicals`, `pmc_services`. Staršie id `weapons` a `pmc` ostali ako súvisiaci tovar.

Recepty sú slovník `{komodita: množstvo}`. `IndustrySystem.io_map` prijme aj pole `{commodity, amount}`. Plný beh pšeničnej farmy dá 1.5 pšenice, beh so 40 % vstupu dá 0.6 a nič navyše nevymyslí.

Priemysly: ťažba, poľnohospodárstvo, výroba (zbrane, chémia, elektronika), služby, logistika, energia, financie, PMC. `arms_plant` vyrába `arms`, `chem_plant` vyrába `chemicals`, `pmc_unit` berie `arms` a predáva `pmc_services`.

Python skript `tools/build_world_data.py` v tomto priečinku spadne, lebo Python si prefix nastaví na Projekt-47. Plný svet sa ním nestiahol. Boot JSON ide z `tools/emit_boot_data.ps1`.

## Banka

Súbor `scripts/autoload/BankingSystem.gd`.

Centrálna sadzba:

`base_rate = 0.01 + max(inflácia, 0) * 0.6 + max(−rast, 0) * 0.25 + (100 − stabilita) / 100 * 0.1`

Výsledok je orezaný na 0.001 až 0.40. Vysoká inflácia a nízka stabilita dvíhajú sadzbu. Sonda: Slovensko v šoku 0.260000, Česko v kľude 0.021000. `policy` sa nastaví na tú istú hodnotu. Mesačný krok volá `update_rates()` znova, takže živá sadzba ostane vzorec.

Strop úveru:

`20 000 + cashflow * 3 + credit_score * 2 000 + rating krajiny * 1 500`

Úrok = `base_rate + risk_premium`. Prirážka je `(100 − skóre) / 100 * 0.05 + (100 − rating) / 100 * 0.03`.

Sonda pustila 250 000 pri sadzbe 0.071633. Žiadosť nad strop a žiadosť do banky bez rezerv hotovosť nezvýšia.

Splátka je mesačná anuita. Deň vnútri mesiaca dlh nemení. Prechod mesiaca zníži istinu o `splátka − úrok` a hotovosť o celú splátku. Po januári 2024 je dlh 246522.7661. Ďalší prechod, z 31. 12. 2024, ho zníži na 243024.7752.

Keď hotovosť splátku neutiahne, `process_monthly_interest()` zavolá `check_bankruptcy()`. Skóre klesne o 15, vznikne event `bankruptcy` a zatvorí sa otvorená firma s najvyšším súčtom ceny stavby a hotovosti firmy. V sonde padla oceľiareň a kaviareň ostala. Keď niet čo zabrať a hotovosť je nulová alebo záporná, hráč je v bankrote a ďalšie dni sa nespustia.

`create_bank(vkladová sadzba, úverová sadzba, rezerva)` zoberie 20 000 kapitálu, príjme vklad NPC 80 000 a požičia AI knihe 50 000. Sadzby sa uložia aj ako `lending_rate`. Rezerva pod 8 % z Bazileja III sa zamietne skôr, než sa kapitál strhne. Dôvod je `law`.

Likvidita je rezervy / vklady. Pod `reserve_ratio` je `bank_run`. Každý taký deň odíde ďalších 4 % vkladov. Panel banky ukáže stav vkladov aj súhrnný odliv. Beh je príznak plus tento denný odliv. Nie je to ešte viacdňová panika s radom pred pobočkou.

Hráč kúpi jeden dlhopis a jednu akciu. Hotovosť klesne, držba stúpne. Plná kniha objednávok za tým nie je.

Vyššia sadzba zníži `investment_factor = 1 / (1 + sadzba * 10)` v priepustnosti továrne a zvýši dopyt po kapitáli `HDP * (0.01 + sadzba * 0.2)` na komodite `finance`.

## Trh a výroba

Cena v zúčtovaní:

`cena = základ * (dopyt / ponuka) ^ elasticita`

Elasticity sú na komodite. Pri elasticite 1 a dopyte dvojnásobku ponuky je cena dvojnásobok základu (sonda 200 a pri elasticite 2 hodnota 400).

Dopytový súčin je

`populácia * príjem * deň v týždni * počasie * sviatok * konkurencia * geopolitika`

Do množstva ide tento súčin delený 1 000 000, inak by populácia pretlačila ceny o milióny. Surový súčin je na knihe v `demand_product`. Ponuka je produkcia firiem v krajine plus dovozový podiel.

24. decembra má pohostinstvo v kresťanskej krajine sviatkový faktor 1.42. Búrka na stavbe je 0.72. Recesia zníži rast HDP o 0.02.

Placement: ropný vrt na Slovensku neprejde, lebo ložisko je pod prahom 0.3. Kaviareň, keď je zaplatená (80 000 plus prevádzkový kapitál 22 %), pridá presne jednu firmu v zvolenej krajine.

Tlačidlo „Výroba 50 %“ volá `set_production(0.5)`. Vypne automatiku a nastaví využitie otvorených firiem hráča. Sonda prečíta 0.5000.

## Čas, eventy, AI

`TimeSystem.roll()` posunie deň a na konci mesiaca aj mesiac a rok. Sonda z 1. 3. 2024 spraví 2. 3. 2024.

`EventSystem` má sviatky, počasie, recesiu. Vojnový šok je v `GeopoliticsSystem.apply_war_shock`: inflácia +0.03, obchodná bilancia klesne o štvrtinu svojej absolútnej hodnoty plus 1, `infra_damage` je true. Poškodená infraštruktúra násobí ponuku 0.75. Vojna sama násobí ponuku 0.82.

`simulate_day` cez hranicu mesiaca tento šok spustí, keď je v configu `shock_war` s dvoma kódmi krajín. Šok ide až po makro prepočte, aby ho mesačná inflácia hneď nepremazala.

Vojna na `arms` dá faktor 3.10, na `chemicals` 1.55, na `pmc_services` 2.60. Sonda to prečíta z nemeckej knihy deň po vypuknutí vojny, nie z priameho volania bokom.

AI firma s hotovosťou nad 5 000 a v mieri dostane rozhodnutie `invest`. Inak vie obchodovať alebo militarizovať.

## Právo

Dáta sú v `data/laws.json`. `LawSystem` ich na začiatku hry napojí na svet.

Každá z 16 krajín má päť oblastí: daň, práca, banky, životné prostredie, zbrane. Názvy sú skutočné predpisy. Príklady: zákon č. 595/2003 Z. z. o dani z príjmov, nemecký KWG a Außenwirtschaftsgesetz, americký Arms Export Control Act a Internal Revenue Code.

Medzinárodné listiny: Charta OSN čl. 2 ods. 4, Ženevské dohovory, GATT 1994 a WTO, Bazilej III, Zmluva o obchode so zbraňami, sankcie podľa čl. 41 Charty, Viedenský dohovor o zmluvnom práve, Zmluva o fungovaní EÚ.

Čo z toho hra naozaj počíta:

- daň firmy je sadzba zo zákona krajiny, kde stojí (SK 21 %, DE 30 %, HU 9 %)
- rezervný pomer banky pod 8 % sa nedá založiť
- vývoz zbraní do krajiny, ktorá je vo vojne, zamietne Zmluva o obchode so zbraňami
- člen EÚ má v paneli aj colnú úniu

Panel sa volá Právo a text skladá `LawSystem.summary` pre vybranú krajinu.

## Obrazovka a slučka

V okne sú panely Mapa, Cashflow, Market prices, Bank accounts, Právo a News. Nad nimi je kredit Wondris404.

Tlačidlá volajú herné funkcie: pôžička, založenie kaviarne, +1 deň, Logistika I, výroba 50 %, založenie banky, recesia, zoom. Medzerník pauzuje, šípka vpravo posunie deň. Klik na obdĺžnik vyberie krajinu. Zoom prepne `world` a `region`. Region view je mriežka z farebných obdĺžnikov, pripravená na neskorší pixel-art. Nie je to geografický zoom tvaru krajiny.

Nová hra v okne dá úver a kaviareň. Save slot 9 uloží hotovosť, firmy a sadzby banky a load ich vráti.

Výskum v dátach má osem projektov. V okne je tlačidlo len na Logistiku I. Po dokončení dní klesne `freight_mult` na 0.9. Ostatné projekty `start_research` prijme, tlačidlá nemajú.

## Čo som opravoval, aby to vôbec naštartovalo

- Godot nebol na PATH. Portable 4.7.2 je v `tools/godot`.
- `:=` na Variant padalo ako parse error.
- `class_name WorldMap` nebolo vidieť pri prvom parse. Scéna skript prednačíta cez `preload`.
- Chýbajúci `lending_rate` na hranej banke hádzal script error. `create_bank` ho ukladá, ticky čítajú cez `.get`.
- Denná anuita úveru bola nahradená mesačnou splátkou. Staré číslo dlhu okolo 99956 po jednom dni už neplatí.
- Sonda pôvodne dokazovala vzorce priamym volaním pomocných funkcií. Teraz ich číta z výsledku `simulate_day`.
- Firma bez poľa `history` zhodila mesačný prepočet. Čítanie histórie ide cez `.get`.

Snímky kódu sú v `checkpoints/`. Posledný po práve je `checkpoints/20261018-163415`. Päťminútová slučka, ktorú si predtým zastavil, sa znova nerozbieha. Po väčšom bloku ide jeden snímok cez `tools/checkpoint.ps1 -Once`.

## Čo v hre ešte nie je

- Skutočné obrysy krajín a plný dataset Svetovej banky.
- Pixel-art, animácia, zvuk.
- Diplomatická obrazovka. Vzťahy a clá existujú v `GeopoliticsSystem`, hráč ich z UI nezadáva. Sankciu podľa čl. 41 hra popisuje v práve, samostatné tlačidlo sankcie nie je.
- Zvyšok výskumného stromu v UI, posuvník výroby po komoditách, kniha dlhopisov.
- Bankrot berie jednu firmu za splátku, tú najdrahšiu, nie celý majetok.
- Každý headless beh pripíše do `docs/DATA.md` riadok `invalid countries -> proxy`, lebo sonda schválne pošle neplatný JSON.

## Ako čítať ďalšie súbory

- `docs/STATUS.md` — čo jadro robí a známe medzery
- `docs/NOTES.md` — pracovné poznámky a posledné čísla sondy
- `docs/LAUNCH_STATUS.md` — štart a opravy pádov
- `docs/DATA.md` — schémy JSON a proxy log
- `docs/REPORT.md` — starší report z predchádzajúcej session
