# Projekt-47

Projekt-47 je rozpracovaná ekonomická strategická hra od Wondris404. Hráč buduje a riadi podniky, obchoduje s komoditami a sleduje vývoj ekonomiky na svetovej mape. Hra používa Godot 4 a počas hrania nepotrebuje internet.

V tomto zdrojovom strome (po zlúčení PR #14–#20 do `main`) už sú noviny, lode, vlastné návrhy zbraní, burza, železnice a potrubia aj voliteľné Halloween DLC. **Samotný commit na `main` nie je hráčske vydanie.** Windows balík vznikne až novým [GitHub Release](https://github.com/Wondris404/Projekt-47/releases). Tento README žiadne nové vydanie nezakladá.

## Inštalácia a aktualizácia pre Windows

**Na prvú inštaláciu aj každú ďalšiu aktualizáciu stačí jeden rovnaký príkaz.** Ukončite hru, otvorte PowerShell a zadajte:

```powershell
& ([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/Wondris404/Projekt-47/main/tools/update-windows.ps1').Content))
```

Aktualizátor:

1. Vyhľadá štandardnú inštaláciu v `%LOCALAPPDATA%\Projekt-47\game` a staršie inštalácie `%LOCALAPPDATA%\Projekt-47\demo-<32 hex znakov>`. Ak nájde viacero, požiada o výber.
2. Zistí zaznamenanú verziu (`demo-...`). **Staré inštalácie nemajú verziový súbor:** vtedy oznámi „neznáma“, nepredstiera, že pozná pôvodnú verziu.
3. Overí najnovšie kompatibilné vydanie na [GitHub Releases](https://github.com/Wondris404/Projekt-47/releases) a opýta sa, či chcete pokračovať. Ak už máte tú istú alebo novšiu známu verziu, nič nemení.
4. Stiahne **celý** vydaný ZIP a overí jeho SHA-256 podľa `SHA256SUMS.txt`. Rozbalí výhradne očakávané súbory, vypíše nové/zmenené/nezmenené súbory a prepíše **iba tie, ktorých obsah sa líši**.
5. Pred výmenou vytvorí zálohu spravovaných súborov. Pri chybe obnoví pôvodný stav; po prerušení transakcie sa pri ďalšom spustení pokúsi o obnovu.
6. **Nemaže osobné súbory v inštalačnom priečinku, ani Godot `user://`**, kde sa nachádzajú uložené pozície. Aktualizáciu odmietne, ak je hra spustená.

V aktuálnom Windows balíku sú len `Projekt-47.exe` a `CITAJ-MA.txt`. Herné skripty a dáta sú zbalené vo vnútri EXE, preto sa pri zmene hry obyčajne vymení celý EXE; nejde o sťahovanie jednotlivých `.gd` súborov alebo binárnych rozdielov. Na kontrolu je potrebný internet a **nový GitHub Release**. Samotný commit na `main` nie je nová inštalovateľná verzia.

### Ak máte hru nainštalovanú inde

Spustite ten istý skript s explicitnou cestou. Príklad (nahraďte skutočným priečinkom s `Projekt-47.exe`):

```powershell
& ([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/Wondris404/Projekt-47/main/tools/update-windows.ps1').Content)) -InstallPath 'D:\Hry\Projekt-47'
```

Pri výbere **viacerých** starých inštalácií ich skript automaticky nezlučuje. Upraví len zvolený priečinok. Ak chcete znova overiť obsah aktuálneho vydania, môžete pridať `-Force`.

Starý príkaz `tools/install-windows.ps1` zostáva zachovaný kvôli spätnej kompatibilite, ale vytvára vždy **novú** inštaláciu. Pre bežných hráčov používajte nový príkaz vyššie.

## Ovládanie na mape

Na lište nad mapou (súbor `scripts/main.gd`) sú okrem iného tieto tlačidlá:

| Tlačidlo | Čo robí |
| --- | --- |
| **Noviny** | Panel správ. Filtre: všetko, firmy, vojna, ceny, politika, šoky, nákaza, ostatné. Najviac 40 titulkov. |
| **Lode** | Kúpa lode od štátu, alebo stavba vo vlastnej lodenici za 72 % ceny. Katalóg je `data/ships.json`. |
| **Návrhy** | Blueprint a vlastný návrh zbrane, tanku alebo lietadla. Katalóg je `data/blueprints.json`. |
| **Burza** | Zatvárateľné okno nad mapou, nie záložka v bočnom paneli. |
| **Železnica** | Klik na začiatok a koniec trate. |
| **Ropovod / plynovod** | Klik na začiatok a koniec potrubia. |
| **Mapa: Pixelová** / **Mapa: Atlas** | Prepína vzhľad mapy. Voľba sa ukladá do `user://settings.cfg`. |

### Noviny

Správy zapisuje hra cez `GameState.post_news`. Halloween DLC posiela svoje vety do kategórie **nákaza**. Panel nič nevymýšľa: ukáže len to, čo je už v zozname správ.

### Lode

`ShipSystem` načíta `data/ships.json`. Prázdna flotila nič nemení: žiadny náhodný hod a žiadny podiel na námornom poole. Civilná loď jazdí medzi prístavmi a berie podiel z freight poolu. Vojenskú loď vieš predať štátu; boj lodí v hre nie je. Vlastná lodenica (`shipyard`) zníži cenu na 72 %.

Morské plošiny (`offshore_oil_rig`, `offshore_gas_rig`, `fpso`) stoja na mori pri ložisku. Bez lode PSV alebo AHTS platí každá taká firma servis 12 000 € denne. Odvetvie `offshore` v šedej zóne je finančná schránka, nie plošina.

Trupy s poľom `model` kreslí mapa z Kenney modelov (CC0), zoznam je v `CREDITS.md`. Ponorky a typy bez modelu (náklad, bulk, general) model nemajú: mapa ich kreslí zlatým trojuholníkom.

### Návrhy zbraní

`ArmsSystem` načíta štyri blueprinty: zbraň a tank chcú zbrojovku (`arms_plant`), vojenské aj civilné lietadlo letecký závod (`aircraft_plant`). Najprv kúpiš blueprint, potom tlačidlom **Navrhnúť** založíš pomenovaný návrh. Toto tlačidlo do návrhu zapíše pevnú cenu, silu a kvalitu z kódu, nie posuvníky. Štát kúpi prvý návrh v zozname. Bez návrhov sú zbrojný aj letecký násobiteľ presne 1,0. Kvalita návrhu ich zdvihne najviac o štvrtinu (`1 + kvalita/400`, kvalita je zovretá na 1–100).

### Burza

`StockMarket` drží národné veľké firmy a AI konkurentov, IPO hráčovej firmy, holding so spin-offom, dividendy a nepriateľské prevzatie nad 50 %. Krajina v trhovej úrovni 2 vlastnú burzu nemá. Okno otvára tlačidlo **Burza**.

### Železnica a potrubie

`Transport`: železnica stojí 45 000 €/km, potrubie 30 000 €/km (násobené obtiažnosťou). Trasa musí mať aspoň 10 km a najviac 2 500 km. Firma do približne 17 km od trate je napojená. Železnica zlacní dopravu tovaru o 60 %. Potrubie zlacní dopravu ropy, plynu a palív o 85 %. Plné využitie kapacity zľavu znižuje.

### Médiá a telekom

Pri firme typu telekom, sociálna sieť, televízia alebo noviny ukáže detail dosah v percentách obyvateľov krajiny (`Brand.media_text`). Počíta sa za behu, do savu sa nezapisuje. Strop typu pred príjmovým koeficientom krajiny je 95 % (telekom), 80 % (sociálna sieť), 85 % (televízia) a 35 % (noviny).

### Ciele firmy a historický katalóg

Záložka **Ciele** kreslí hrateľný strom firemných cieľov z `PoliticsSystem.FOCUS` (vetvy Ekonomika, Politika, Podsvetie, Pohlavie). Naraz beží jeden cieľ, trvá desiatky dní, má predpoklady a niektoré dvojice sa vylučujú. Ciele viazané na pohlavie sa ukážu len tomu pohlaviu, ktoré máš v novej hre.

Súbor `data/focus_trees.json` je **iný** katalóg: historické stromy (USA, SU, CN, UK, FR, DE, JP, IN a generic). `DataLoader` ho načíta a jednotkové testy kontrolujú počty, cykly a vzájomné vylúčenie. Hráčske rozhranie tieto historické uzly neponúka. Nie sú to ciele, na ktoré sa v záložke **Ciele** kliká.

## Halloween DLC

Voliteľný režim zombie apokalypsy. Na obrazovke novej hry zaškrtni **Halloween DLC: Zombie apokalypsa**. Ak odomknutie ešte nie je uložené, hra pýta heslo (pole je skryté) a po správnom hesle štartovacie peniaze. Heslo v tomto README nie je. V kóde je len kontrola SHA-256, nie heslo v čitateľnej podobe. Po prvom správnom hesle ostane odomknutie v `user://settings.cfg` (kľúč `dlc/unlocked`, rovnaký Godot priečinok v editore aj v exportovanej Windows hre), takže ho netreba písať pri každej novej hre.

Vypnuté DLC nič v bežnej hre nemení: `ZombieSystem.daily()` nerobí nič, žiadna nákaza, žiadne ceny, žiadny náhodný hod. Uložená pozícia bez týchto polí sa načíta ako bežná hra. Zapnutý režim pridá tlačidlá **Nákaza** a **Zombie**. Vrstva nákazy funguje aj pri **Mapa: Pixelová**. Panel **Zombie** ovláda evakuáciu, safe zóny, múr, politiku nákazy, helikoptéry, stíhačky, vakcínu a bunkre.

Bunkre sú len v zombie režime. Tlačidlo **Postaviť bunker** berie pravidlá z `data/bunkers.json` (úroveň 1 a 2, kapacita, jedlo, údržba, laboratórium, ktoré zrýchli vakcínu o 10 %). Padnutý bunker nakazí ľudí vnútri. Na mape je model `assets/models/bunker/bunker.glb`.

Zombie a lietadlá **nie sú** zelené a modré zástupné tvary. Mapa kreslí rendery z licencovaných modelov: `zombie_sprite.png` (Quaternius), `heli_sprite.png` (kazuma) a `fighter_sprite.png` (Poly by Google). Staré `*_placeholder.png` v `assets/models/` ostávajú v repe ako záloha; skripty ich nenačítavajú. Helikoptéry a stíhačky DLC lietajú cez `ShipSystem.air_traffic`, len ako poloha na mape.

> **Bunker sa nesmie predávať.** `assets/models/bunker/bunker.glb` je fan-art Star Wars Endor Bunker od aclarke064, licencia [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). Zdroj: [Star Wars Endor Bunker na Sketchfabe](https://sketchfab.com/3d-models/star-wars-endor-bunker-1c54abb1c6824f26a0a087d2bd7a635a). Kým je tento model v hre, hra sa nesmie predávať. Úpravy sa šíria pod tou istou licenciou. Text licencie je aj v `assets/models/bunker/LICENSE.txt` a v `CREDITS.md`.

> Ide o testovaciu verziu: pred aktualizáciou odporúčame zálohovať dôležité uložené pozície. Aktualizátor nemení ich súbory, no nový herný kód môže mať vlastné chyby alebo zmeny kompatibility save. PowerShell skripty spúšťajte len z dôveryhodného zdroja.

## Licencie modelov

Podrobnosti sú v `CREDITS.md`. Skrátene, nič z toho tento README nepridáva:

- **Animated Zombie Pack** – Quaternius – CC0 1.0. `assets/models/zombies/zombie.glb`.
- **Helicopter** – kazuma – CC0 1.0. `assets/models/aircraft/heli.glb`.
- **Jet** – Poly by Google – CC-BY 3.0. `assets/models/aircraft/fighter.glb`. Treba uviesť autora: „Jet“ by Poly by Google, via Poly Pizza.
- **Lode** – Kenney Watercraft Kit – CC0 1.0. Zapojené trupy sú v `CREDITS.md` (PSV/AHTS zdieľajú `psv.glb`).
- **Bunker** – aclarke064 – CC BY-NC-SA 4.0 – nekomerčné. Pozri varovanie vyššie.

## Vývoj

Zdrojový projekt otvorte v Godot 4.7.2 cez `project.godot` (`config/features` je 4.7; export vo workflow sťahuje stabilné 4.7.2). Dáta hry sú v `data/`, skripty v `scripts/`, testy v `tests/` a história zmien v `docs/WRAITH_DENNIK.md`. Požadované exportné šablóny nie sú súčasťou samotného zdrojového repozitára.

Headless jednotkové testy:

```bash
godot --headless --path . -- unit
```

Každá kontrola vypíše `P47_UNIT_OK` alebo `P47_UNIT_FAIL`. Proces skončí s kódom 1, ak niektorá zlyhá (`tests/unit.gd`).

Ďalší argument v `scripts/main.gd` `_ready`, ktorý workflow Windows demo naozaj púšťa na exportovanom EXE:

```bash
godot --headless --path . -- profile_sim
```

Vypíše `P47_PHASE_DONE` (v kóde ide o 10 dní simulácie). Ten istý `_ready` pozná aj ďalšie headless argumenty, ak ich uvediete za `--`: `stability`, `camera_unit`, `map_compat_unit`, `atlas_update_unit`, `atlas_levels_unit`, `atlas_style_unit`, `atlas_city_scale_unit`, `strategic_hud_unit`, `audit_unit`, `fund_unit`, `flow_unit`, `goods_icons_unit`, `bank_audit_unit`, `bank_advisor_unit`, `sovereign_unit`, `employment_stats_unit`, `society_unit`, `local_comp_unit`, `performance_audit`, `phase_routes_unit`, `bench`, `bench_flow`, `bench_distance`, `uitest`, `society_ui`. Iný argument spustí `tests/probe.gd`.

Windows aktualizátor: `tools/update-windows.ps1`; jeho izolované testy: `tools/tests/update-windows.tests.ps1`. Testy vytvárajú **fiktívne** ZIP balíky v dočasnom priečinku a spúšťajú sa na Windows GitHub Actions v `.github/workflows/windows-updater-tests.yml`. Nové verejné vydanie sa publikuje samostatne cez existujúci workflow `Windows demo package` (`workflow_dispatch`); obyčajný commit sám o sebe novú verziu hráčom neposkytne.
