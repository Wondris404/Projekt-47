# Report session Projekt-47

Dátum práce: 16.–17. október 2026.  
Priečinok: `C:\Users\ondre\Desktop\Projekt-47`.  
Tento súbor je súhrn všetkého, čo je na disku. Nie je to sľub celej pôvodnej vízie.

## Zadanie

Pôvodná požiadavka: kompletný offline pixel-art ekonomický a geopolitický simulátor v Godot 4. Hráč začína pôžičkou, zakladá firmy od kaviarne po zbrojovku a vlastnú banku. Svet mal mať reálne krajiny a dáta (World Bank, Global Macro Database, ITPD-S, FAO, Natural Earth, Correlates of War). Systémy mali byť modulárne: Industry, Market, Banking, Geopolitics, Agent, DataLoader.

Neskôr pribudlo:

- všetko ukladať len do Projekt-47, vrátane poznámok pre ďalšiu session,
- každých 5 minút snímok kódu a poznámok,
- priorita funkčného prototypu pred plným svetom.

Odhad rozsahu: úzka overená brána prototypu je hotová. Z pôvodnej veľkej vízie je spravených asi 30 %.

## Čo je hotové a overené

Godot 4.7.2 portable je v `tools/godot/`. Projekt sa spúšťa takto:

```
tools\godot\Godot_v4.7.2-stable_win64.exe --path C:\Users\ondre\Desktop\Projekt-47
```

Headless kontrola (musí skončiť `P47_PROBE_OK` a exit 0):

```
tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path C:\Users\ondre\Desktop\Projekt-47
```

Posledné dva behy, 17. 10. 2026 okolo 16:10, boli zhodné a bez `SCRIPT ERROR`:

| Sonda | Hodnota |
|---|---|
| Recept, plný vstup / 40 % vstupu | 1.500000 / 0.600000 |
| Znamienko ceny, nedostatok / prebytok | +1 / −1 |
| Región bodu vnútri prvého polygónu | SK |
| Zostatok úveru po jednom dni | 99956.1397 |
| Cena pšenice po jednom dni | 266.4341 |

Čo sonda reálne volá:

- `DataLoader` načíta JSON a skontroluje, že každý vstup a výstup receptu je komodita.
- `IndustrySystem.apply_recipe` na `wheat_farm`: plná elektrina vyrobí pšenicu podľa koeficientu, krátky vstup spraví prísne menej a nevymyslí cudzí tovar.
- `MarketSystem.adjust_price`: dopyt nad ponukou cenu zdvihne, ponuka nad dopytom ju zníži, cena ostane kladná a konečná. Ten istý vzorec používa denný `clear_all`.
- `GameState.new_game` vydá úver cez `_open_starter`. `GameState.simulate_day` zavolá `BankingSystem.apply_installment`. Hotovosť klesne o splátku, dlh o istinu (úrok = zostatok × sadzba / 365, istina = splátka − úrok).
- `WorldMap.regions_containing` a `region_at_world`: stred prvého obdĺžnika je SK, bod mimo mapy nie je v žiadnom polygóne.

V okne: Nová hra (úver 180 000 €, kaviareň v zvolenej krajine), +1 deň, Pauza, medzerník, šípka vpravo, koliesko priblíži mapu. Lišta ukazuje dátum, krajinu, hotovosť, dlh, cenu pšenice a hotovosť firmy.

## Architektúra

Autoloady v `project.godot`, v tomto poradí:

1. `DataLoader` — JSON do slovníkov.
2. `EconMath` — anuita, vzdialenosť, eurá, percentá.
3. `TimeSystem` — dátum, sezóna, Veľká noc.
4. `EventSystem` — počasie, sviatky, mesačné šoky.
5. `GeopoliticsSystem` — vzťahy, clá, vojny.
6. `MarketSystem` — knihy cien, clear, obchodné trasy.
7. `AgentSystem` — AI banky a AI firmy.
8. `IndustrySystem` — `apply_recipe` a denný tick prevádzok.
9. `BankingSystem` — úvery, vklady, dlhopisy, akcie.
10. `SaveSystem` — JSON slot do `saves/`.
11. `GameState` — nová hra, `simulate_day`, stav hráča.

UI: `scripts/main.gd`, `scripts/ui/world_map.gd`, `scripts/ui/region_view.gd`.  
Scéna: `scenes/main.tscn`.  
Účtovníctvo je v EUR. Stav hry sú slovníky, aby šiel save do JSON.

Denný poriadok v `simulate_day`: počasie, dopyt, plány firiem, trasy, clear cien, výroba a predaj, banka, výskum. Prvý deň mesiaca ešte makro, centrálne banky, geopolitika, AI a eventy. Štartovacia sonda má vojny a katastrofy vypnuté, seed 47, aby dva behy sedeli.

## Dáta v `data/`

| Súbor | Obsah |
|---|---|
| `commodities.json` | 20 komodít: pšenica, káva, mäso, ropa, uhlie, železná ruda, meď, oceľ, chemikálie, liečivá, textil, elektronika, autá, zbrane, elektrina, stavba, logistika, pohostinstvo, financie, súkromná bezpečnosť |
| `recipes.json` / `industries.json` | 21 odvetví: kaviareň, farma, plantáž, chov, ropný vrt, uhoľná baňa, baňa na rudu, medená baňa, elektráreň, oceliareň, chemička, laboratórium, textilka, elektronika, automobilka, zbrojovka, stavbár, logistika, finančná kancelária, súkromná bezpečnosť, obchodná kancelária |
| `research.json` | 8 výskumov (logistika, automatizácia, odrody, chémia, zbrane, energia, scoring) |
| `scenarios.json` | sandbox, kaviareň, obchodník, banka, priemysel, napätý svet |
| `countries.json` | 16 krajín, `fallback: true`, približné čísla okolo roku 2023: SK, CZ, DE, PL, AT, HU, FR, UA, US, CN, RU, SA, NO, NL, GB, BR |
| `map.json` | 16 neprekrývajúcich sa obdĺžnikov 150×110 na plátne 1440×720 |
| `supply_shares.json` | podiely ropy, pšenice, uhlia a kávy; ostatné idú podľa HDP. USD za 1 EUR = 1.08 |
| `wars.json`, `tension_seed.json` | prázdne polia `[]` |

Font s diakritikou: `assets/fonts/NotoSans-Regular.ttf`. Samostatné pixel sprity sa nerobili. Vzhľad mapy je kreslený v kóde.

## Čo je v skriptoch, ale nie je to hrateľná obrazovka

Toto nie je overené sondou ako samostatná funkcia a v okne na to nie je tlačidlo:

- založenie iného odvetvia než kaviarne, ďalšia prevádzka, dividenda, vklad kapitálu do firmy,
- vlastná banka: vklady, sadzby, prísnosť, defaulty, bank run, diskontné okno,
- ďalší úver podľa ratingu, dlhopisy, akcie, IPO,
- výskumný strom a efekty (menej práce, lacnejšia doprava, vyšší výťažok),
- AI firmy a AI banky (vzniknú pri novej hre a tikajú),
- obchodné trasy, clá, embargá, vojny, počasie, sviatky, makro (inflácia, dlh, rozpočet),
- save/load slot,
- `RegionView` (mriežka zón commercial / industrial / port) nie je zapojená do hlavného okna.

## Čo sa nepodarilo

Živý sťah World Bank, Natural Earth, Our World in Data, Correlates of War a Frankfurter sa nespustil do konca. `python` v tomto priečinku skončí hneď: `sys.prefix` je `C:\Users\ondre\Desktop\Projekt-47` a chýba modul `encodings`. Preto nie sú reálne obrysy, nie je 200 krajín a `data/raw/` je prázdny. `tools/build_world_data.py` je pripravený. Spúšťať ho len takto:

```
$env:PYTHONHOME = "C:\Users\ondre\AppData\Local\Programs\Python\Python314"
python -I tools\build_world_data.py
```

Boot dáta, ktoré hra teraz číta, skladá `tools/emit_boot_data.ps1`.

V Godot 4.7 je `:=` pri Variante parse error. V skriptoch je obyčajné `=`.

Global Macro Database a ITPD-S sa nestiahli. GMD chce e-mail alebo balík. ITPD-S má stovky miliónov riadkov, celý zip sa nemal ťahať.

## Ukladanie

`tools/checkpoint.ps1` kopíruje projekt do `checkpoints/<čas>/` a necháva posledných 12 snímok. Preskakuje `tools/godot`, `data/raw`, `.godot` a staršie checkpointy. Medzera je `Start-Sleep -Seconds 300`. Jeden beh bez slučky: `powershell -File tools\checkpoint.ps1 -Once`.

Log: `docs/CHECKPOINT_LOG.md`. Najnovší snímok pred týmto reportom bol `checkpoints/20261017-162556`. Po zápise tohto reportu pribudne novší snímok.

Poznámky pre pokračovanie: `docs/NOTES.md`. Krátky stav: `docs/FAZA.md`. Návod na spustenie: `README.md`.

## Ako pokračovať ďalšími úlohami

Bezpečný základ je headless `P47_PROBE_OK`. Nové úlohy stavať na `apply_recipe`, `adjust_price`, `apply_installment` a `region_at_world`, nie vedľa nich. Po zmene skriptu znova spustiť konzolový Godot headless a porovnať riadky `P47_`.

Najbližšie diery, ak príde nové zadanie:

1. dialóg na ľubovoľné odvetvie z `industries.json`,
2. obrazovka banky (vklady, úver, run),
3. tabuľka cien vybraného štátu,
4. reálne polygóny krajín, až keď Python build prejde.
