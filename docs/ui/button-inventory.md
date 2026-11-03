# Inventár tlačidiel (Projekt-47, Godot 4)

Zdroj: vetva `feat/premium-ui`. Účel: theme pass môže restylovať ovládanie **bez zmeny logiky**.
Rozsah hľadania: `scripts/**/*.gd` (hlavne `scripts/main.gd`, `scripts/ui/*.gd`), `scenes/**/*.tscn`, `ui/**/*.tres`.

## Čo sa počíta

Počítajú sa len widgety, ktoré kód naozaj vytvorí: `Button`, `TextureButton`, `CheckBox`, `CheckButton`, `OptionButton`, `ColorPickerButton`.

| Typ | Počet v katalógu |
|---|---:|
| Button | 350 |
| CheckBox | 26 |
| OptionButton | 29 |
| ColorPickerButton | 2 |
| TextureButton | 0 |
| CheckButton | 0 |
| **Spolu** | **407** |

**407 je zjednotenie vetiev kódu** (každé `*.new()` s konštantným počtom v slučke), nie počet widgetov naraz na obrazovke.

Mimo 407 (neobmedzené alebo bez dát v tomto workspaci):

- Strom výskumu (`research_tree_view.gd`): 1 `Button` na každý záznam `data/research.json`. V `main` je **25** technológií. Do 407 sa nepočítajú, lebo vznikajú z dát, nie z pevnej slučky v kóde.
- `Detail: %s` v záložke Firma — 1 tlačidlo na firmu a na banku hráča.
- Záložné `CheckBox` v úverovom paneli a `CheckBox` firiem v burze — 1 na firmu hráča.
- Tlačidlá firiem v okne krajiny — 1 na firmu/banku v tej krajine.
- Karty bunkrov (DLC): **2 tlačidlá na bunker** (`Vylepšiť`, `Postaviť laboratórium`). Šablóna nie je v 407, lebo počet bunkrov je stav hry.
- Druhá a ďalšia parcela v meste sa už nerozklikáva (kód spracuje len prvú parcelu, max. 4 tlačidlá — tie **sú** v 407).

Naraz na obrazovke je menej než 407:

- Pauza maže deti a kreslí vždy len jednu obrazovku (domov = 5 tlačidiel, nie všetkých 20).
- Focus strom filtruje pohlavie: z 22 definícií je naraz 20 (muž/žena) alebo 18 (iné).
- Detail firmy skladá len vetvu podľa odvetvia (banka vs. fond vs. PMC vs. škola vs. burzový maklér).
- Skrytý blok `OldFinanceHidden` (6 tlačidiel) a skrytý riadok „Nastaviť úrok“ existujú v strome, ale `visible = false`.
- „Späť do hry“ sa vytvorí, no `show_home()` ho vždy nechá skryté (v kóde sa nikde nezapne).

## Čo zámerne nie je v súčte

- `scenes/main.tscn` ani iná scéna: žiadny Button / CheckBox / OptionButton / ColorPickerButton.
- `ui/theme_factorio.tres` len štýluje `Button` (normal/hover/pressed/disabled/focus + farby) a `OptionButton` (len `font_color`). CheckBox, CheckButton ani ColorPickerButton v téme nie sú. Inštancie nevytvára.
- `TabContainer` záložky bočného panela (Firma, Založiť, Pôžičky, Vplyv, Trh & banky, Štát & správy, Politika, Ciele, Výskum) sú `TabBar`, nie `Button`. Štýl: `TabContainer/styles/tab_*` v `theme_factorio.tres`.
- Šípky `SpinBox` a krížik okna `Window` / `AcceptDialog` sú engine chrome, nie projektový `Button`. Výnimka: OK tlačidlo editora loga (`ok_button_text`), to **je** v súčte.
- `scripts/ui/research_tree.gd` kreslí obdĺžniky, nie tlačidlá (starý náhľad vedľa skratiek výskumu).
- `hud_metric.gd` sú panely metrík, nie tlačidlá.
- Intro (`intro_scene.gd`) a splash (`main.gd` `_show_splash`) nemajú Button. Intro: medzerník = ďalej, Esc/klik = preskočiť. Splash: klik na celú plochu.
- Deklarované, ale **nikdy neinštancované**: `main_menu.gd` `tutorial_box: CheckBox`, `dev_button: Button` (dev režim nahradila cheat konzola).

Vlastné štýly mimo globálnej témy (theme pass ich nesmie prehliadnuť, inak ostanú staré):

- `main_menu.gd` `_menu_style` — úplný override StyleBoxov + hover dopisuje prefix `▸ ` (a pri odchode ho maže).
- `strategic_skin.gd` `button()` — horná lišta, suroviny, `hud_button.gd`.
- `build_menu.gd` hlavičky skupín: `flat = true`, farba `UiPalette.ACCENT`.

`scripts/ui/hud_button.gd` je triedda `extends Button` s vlastným tooltipom (`_make_custom_tooltip`). Samo o sebe nie je inštancia.

---

## 1. Hlavné menu — `scripts/ui/main_menu.gd`

Builder `_button()` (riadok 391): `Button`, min. výška 40, `_menu_style`, `pressed`.

### Domov — `_home()` ~235

| Premenná / meno | Text | Rola | Poznámka |
|---|---|---|---|
| `continue_button` / `Continue` | Pokračovať | hlavné menu | `disabled`, kým nie je slot 1–3 ani bežiaca hra |
| `nb` / `NewGame` | Nová hra | hlavné menu | otvorí výber módu |
| `save_button` | Uložiť hru | hlavné menu | skryté, kým hra nebeží; emituje `save_requested(1)` |
| (bez mena) | Načítať hru | hlavné menu | |
| (bez mena) | Nastavenia | hlavné menu | |
| (bez mena) | Koniec | hlavné menu | `quit_requested` → koniec procesu |
| `back_button` | Späť do hry | hlavné menu | vytvorené, v `show_home()` vždy `visible = false` |

Hover cez `_menu_style` dočasne zmení text na `▸ {text}`.

### Módy — `_modes()` ~199

Nadpis „NOVÁ HRA — vyber mód“. Mriežka 2 stĺpce.

| Meno uzla | Text | Rola | Poznámka |
|---|---|---|---|
| `Mode_easy` | Easy | hlavné menu | tooltip = `Difficulty.describe` |
| `Mode_tutorial` | Tutoriál | hlavné menu | popis + neskôr vetva tutoriálu; nie je to CheckBox |
| `Mode_medium` | Medium | hlavné menu | predvolený mód v kóde |
| `Mode_hard` | Hard | hlavné menu | |
| `Mode_realistic` | Realistic | hlavné menu | |
| `Mode_story` | Story | hlavné menu | nespustí hru; poznámka „Na tomto sa pracuje — wondris404“ |
| (bez mena) | Späť | hlavné menu | späť na domov |

### Nová hra — `_new_game()` ~258 + lišta `NewButtons` ~135

Lišta je **mimo** scrollu, viditeľná len na tomto paneli.

| Premenná / meno | Text | Rola | Poznámka |
|---|---|---|---|
| `bb` | Späť | hlavné menu | späť na módy, nie na domov |
| `sb2` / `StartButton` | Štart | primárne | `_emit_new`; pri DLC bez odomknutia najprv heslo |
| `gender_box` | položky: muž, žena, iné | výber | tooltip z `PoliticsSystem.GENDER_TIPS`, mení sa s výberom |
| `starter_box` | Štartovací balík (pôžička a kaviareň) | prepínač | default zapnuté; tutoriál ho vypne |
| `dlc_box` | Halloween DLC: Zombie apokalypsa | DLC | default vypnuté; `toggled` → heslo alebo suma |

Žiadny samostatný CheckBox „tutoriál“ — tutoriál je mód `Mode_tutorial`.
Heslo DLC je `LineEdit` („Heslo DLC“), nie tlačidlo. Suma je `SpinBox` („Štart “).

### Načítať — `_load_game()` ~343

| Text | Rola | Poznámka |
|---|---|---|
| `Slot %d` alebo `Slot %d (prázdny)` × 3 | hlavné menu | `load_buttons[i]`; prázdny slot `disabled`; text sa obnoví v `_refresh_load_buttons` |
| Späť | hlavné menu | |

### Nastavenia — `_settings()` ~364

| Premenná / meno | Text | Rola | Poznámka |
|---|---|---|---|
| `scale` (bez mena) | Mierka 1.0 / 1.25 / 1.5 | výber | signál `scale_selected` |
| `gq` / `GfxQuality` | Grafika: automaticky / vysoká / nízka (slabší notebook) | výber | tooltip o animáciách mapy |
| (bez mena) | Zopakovať tutoriál | sekundárne | `tutorial_repeat_requested` |
| (bez mena) | Späť | hlavné menu | |

Súčet menu: **22 Button + 2 CheckBox + 3 OptionButton**.

---

## 2. Horná lišta a mapa HUD

### Horná lišta — `scripts/ui/top_bar.gd`

Všetky sú `hud_button.gd` + `strategic_skin.button()`. Vznik v `_ready` / `_clock_button` ~57–106.

| Premenná | Text | Rola | Poznámka |
|---|---|---|---|
| `pause_button` | (bez textu, ikona `pause`) | ikonové | `toggle_mode`; tooltip „Pauza / pokračovať · Medzerník“; stav z `GameState.paused` |
| `speed_buttons[1]` | ikona `speed_1x` | ikonové | `toggle_mode` + `ButtonGroup`; tooltip „Rýchlosť 1x · 1,2 herných dní/s“ |
| `speed_buttons[2]` | ikona `speed_4x` | ikonové | „Rýchlosť 4x · 6 herných dní/s“ |
| `speed_buttons[3]` | ikona `speed_10x` | ikonové | „Rýchlosť 10x · 24 herných dní/s“ |
| `day_button` | +1 deň | sekundárne | tooltip „Uzavrieť jeden herný deň“ |
| `resources_button` | Suroviny a energia | sekundárne | `toggle_mode`; ikona electricity; otvára resource drawer; sync s viditeľnosťou draweru |

Metriky (Peniaze, Dlh, …) nie sú tlačidlá.

### Lišta mapy — `scripts/main.gd` `_build_play()` ~413–525

Rodič: `MapToolbarScroll` (HBox). Šípky sú mimo scrollu.

| Premenná / meno | Text | Rola | Poznámka |
|---|---|---|---|
| `scroll_left` / `ToolbarScrollLeft` | ◀ | ikonové | tooltip „Posunúť ovládací panel doľava.“; scroll −220 |
| `scroll_right` / `ToolbarScrollRight` | ▶ | ikonové | „… doprava.“; +220 |
| `pb` / `panel_btn` / `PanelToggle` | ◀ Skryť panel | sekundárne | po skrytí text „▶ Panel“; aj kláves Tab |
| `burza_b` / `BurzaButton` | Burza | primárne | `toggle_burza` |
| `emp_b` / `EmpireButton` | Portfólio | primárne | tooltip o štatistikách, štáte, charite, HQ |
| `inf_b` / `InfraToggle` | Infraštruktúra | prepínač | `toggle_mode`; diaľnice, letiská, prístavy, trasy |
| `zoom` | Priblížiť / oddialiť | sekundárne | tooltip o úrovniach mapy |
| `terr_b` / `TerrainToggle` | Terén / suroviny | prepínač | `toggle_mode` → `map.overlay` |
| `cust_b` / `CustomersMapToggle` | Odberatelia | prepínač | `toggle_mode`; farby krajín podľa €/mesiac |
| `map_style_b` / `MapStyleToggle` | Mapa: Atlas **alebo** Mapa: Pixelová | prepínač | text až v `_sync_map_style` ~2127; nie je `toggle_mode`, cyklus pixel/hoi; tooltip „Prepnúť vzhľad mapy“ |
| `news_b` / `NewsButton` | Noviny | sekundárne | tooltip o kategóriách správ |
| `ship_b` / `ShipsButton` | Lode | sekundárne | tooltip kúpa/lodenica/predaj |
| `arms_b` / `ArmsButton` | Návrhy | sekundárne | tooltip zbrojovka / letecký závod |
| `preview_3d_button` / `Prototype3DButton` | 3D skúška | sekundárne | rozpracovaný 3D náhľad |
| `lb` / `Build_rail` | Železnica | sekundárne | tooltip s cenou €/km; kreslenie línie na mape |
| `lb` / `Build_pipe` | Ropovod / plynovod | sekundárne | to isté pre potrubie |

DLC na tej istej lište (až keď `ZombieSystem.active()`, `_ensure_zombie_ui` ~1434):

| Meno | Text | Rola | Poznámka |
|---|---|---|---|
| `ZombieLayerButton` | Nákaza | DLC | nie `toggle_mode`; prepína `map.infection_mode`; skryté, keď DLC nebeží |
| `ZombieOpenButton` | Zombie | DLC | otvára `ZombiePanel` |

`zoom_lbl` je Label („Zoom …×“), nie tlačidlo.

---

## 3. Bočný panel — firma, úvery, výskum, ceny

Záložky `TabContainer` nie sú Button (pozri vyššie). Obsah:

### Záložka Firma — `_build_play` ~557–661

| Premenná | Text | Rola | Poznámka |
|---|---|---|---|
| `place_b` | Založiť firmu | primárne | `_on_place` (nie „Postaviť tu“) |
| `price_b` | Cena predaja | sekundárne | |
| `shift_b` | Zmena 2 | sekundárne | |
| `pmc_b` | PMC kontrakt | sekundárne | |
| `pmc_x` | Zrušiť PMC | zrušiť | |
| `imp_b` | Dovoz pšenice | sekundárne | |
| `exp_b` | Vývoz pšenice | sekundárne | |
| `research_b` | Výskum: Logistika I | sekundárne | natvrdo `logistics1` |
| `rb` × 7 | Výskum: logistics2 / auto1 / agro1 / chem1 / arms1 / energy1 / score1 | sekundárne | text je **anglické id**, nie slovenský názov (`research_button_ids` ~212) |

Dynamika `_sync_firm_buttons` ~2548, kontajner `MojeFirmyDetail`:

- `Detail: %s` — firma hráča, ikona typu, `open_firm_detail`. **Mimo 407.**
- `BankDetailButton`, text `Detail: %s` — každá banka hráča. **Mimo 407.**

Posuvník výroby je `HSlider`, nie Button.

### Záložka Založiť

`_build_place_panel` ~2482:

| Premenná / meno | Text | Rola | Poznámka |
|---|---|---|---|
| `place_kind` / `PlaceKind` | `{názov} ({cena})` pre každý kľúč `DataLoader.industries` + `Banka` | výber | tooltip = popis odvetvia; ikona typu; počet položiek = dáta + 1 |
| `b` | Postaviť tu | primárne | tooltip: vyber krajinu, potom klik na mape, Esc zruší |

Menu stavieb `scripts/ui/build_menu.gd` `setup()` ~26. Hlavička skupiny je Button (`flat`, `toggle_mode`), text `▾/▸ {skupina} ({počet})`. Položka: `Button`, text = `industries[id].name` (JSON v checkoute chýba), tooltip „popis / Cena / Trieda“. `clip_text`. Skupina sa dá zložiť; filter `Hľadať…` je LineEdit.

| Skupina (hlavička = záložka) | Počet tlačidiel odvetví (sekundárne), ak id existuje v dátach | id |
|---|---:|---|
| Malé podniky | 6 | restaurant, bakery, gym, auto_service, eshop, real_estate |
| Poľnohospodárstvo | 4 | cafe, wheat_farm, coffee_farm, livestock |
| Ťažba | 8 | oil_well, gas_well, offshore_oil_rig, offshore_gas_rig, fpso, coal_mine, iron_mine, copper_mine |
| Priemysel | 11 | power_coal, steel_mill, chem_plant, pharma_lab, textile_mill, electronics_plant, auto_plant, arms_plant, construction_co, oil_refinery, gas_works |
| Služby | 6 | logistics_hub, finance_office, pmc_unit, trade_desk, cargo_port, hospital |
| Školstvo | 4 | school_primary, school_high, university, corp_academy |
| Stredné podniky | 6 | hotel, supermarket, warehouse, software, ad_agency, clinic |
| Veľké podniky | 11 | chip_fab, airline, telecom, solar_plant, gas_plant, nuclear_plant, shipyard, aircraft_plant, data_center, ai_firm, airport |
| Financie | 3 | insurance, invest_fund, stock_broker |
| Médiá | 3 | tv_station, social_network, newspaper |
| Šedá zóna | 2 | casino, offshore |

Spolu **11 záložiek + 64 sekundárnych**, ak dáta obsahujú všetky id. Chýbajúce id sa preskočí (`DataLoader.industries.has`).

### Záložka Pôžičky

| Premenná / meno | Text | Rola | Súbor / miesto |
|---|---|---|---|
| `loan_b` | Pôžička | primárne | `main.gd` ~566; tooltip `BankingSystem.HELP` |
| `help_b` | Ako fungujú úvery a banky? | sekundárne | `toggle_mode`; len ukáže/skryje Label |
| `t` / `CreditToggle` | Úver so zálohou / bez zálohy ▸ | záložka | `credit_panel.gd` ~13; šípka v texte sa po rozbalení **nemeni** |
| `b` / `SecuredLoan` | Požiadať o úver so zálohou | primárne | v tele, default skryté |
| `u` / `UnsecuredLoan` | Nezabezpečený úver 30 000 € (vyšší úrok) | sekundárne | |
| `cb` × firmy | `{firma} – hodnota {€}` + „ (už založená)“ | prepínač | **mimo 407**; `disabled`, ak je už založená |
| `issue_b` / `IssueBond` | Vydať dlhopis | primárne | `bonds_view.gd` ~32; `disabled`, keď `bond_quote.reason` nie je prázdny |

### Záložka Výskum — `_build_research_tab` ~3277

| Meno | Text | Rola | Poznámka |
|---|---|---|---|
| `rb` / `BuildRnd` | Postaviť R&D centrum (+1 slot, {cena}) | primárne | cena `GameState.RND_CENTER_COST` |
| `Research_{id}` | `{✔\|▶\|⏳} {ikona} {názov}\n{cena} · {dni} dní` | iné | `research_tree_view.gd` `rebuild` ~33; **počet = dáta, mimo 407**; `disabled` ak nedostupné alebo vo fronte; hotové zelený `modulate`; tooltip cena/efekt/predpoklady |

### Záložka Ciele

| Text / meno | Rola | Poznámka |
|---|---|---|
| `Ciele: obnoviť strom` | sekundárne | `main.gd` ~3198, `_on_focus_refresh` |
| `Focus_{id}` × 22 definícií | iné | `focus_tree_view.gd` ~33; v súčte je celý katalóg |

Viditeľný text uzla: `{✔\|▶} {ikona} {názov}\n{dni} dní`. `disabled`, kým nie je dostupný alebo už beží iný cieľ. Hotový uzol je zelenší. Tooltip: efekt, vyžaduje, vylučuje.

Vetvy a názvy (zo `PoliticsSystem.FOCUS`):

- Ekonomika: Štandardizácia, Vlastní dodávatelia, Monopolná pozícia, Dobré vzťahy s bankármi, Ratingová agentúra, Daňová optimalizácia, Výskumné oddelenie
- Politika: Kontakty v parlamente, Lobistická kancelária, Tieňový minister, PR oddelenie, Vlastný denník, Televízia
- Podsvetie: Čistý podnikateľ, Transparentná firma, Korupcia a podsvetie, Kontakty v miestnej vláde, Bezpečnostné kontakty
- Pohlavie muž: Old boys club, Tvrdý vyjednávač
- Pohlavie žena: Sieť žien v biznise, Mediálna ikona

### Záložka Politika — `_build_juan4_tabs` ~3132

| Meno | Text | Rola |
|---|---|---|
| `pol_party` / `PolParty` | `{strana} ({%})` | výber |
| `pol_target` / `PolTarget` | krajiny podľa `name_sk` | výber |
| `Pol_{akcia}` | názov z `PoliticsSystem.ACTIONS` | sekundárne, okrem štyroch nebezpečných |
| `Gender_campaign` | Kampaň pre ženy (reputácia) | sekundárne |
| `Gender_charm` | Očariť pri vyjednávaní (zľava) | sekundárne |

Nebezpečné akcie: Úplatok ministrovi, Lobing za konflikt (zbrojári), Zorganizovať štrajk (tlak na vládu), Lobing: embargo voči cieľu.

Ostatné (sekundárne): Lobing: nižšie dane, Lobing: menej regulácie, Podpora strany vo voľbách, Lobing za mier, Financovať stranu (popularita), Podporiť krajinu vo vojne, Lobing: sankcie voči cieľu, Lobing: obchodná dohoda s cieľom, Lobing: colná úľava s cieľom, Mediálna kampaň (vplyv).

### Záložka Vplyv

Samostatné okno nie je — je to panel `influence_view.gd` (sekcia 4).

### Záložka Trh & banky

| Premenná | Text | Rola | Poznámka |
|---|---|---|---|
| `cons_b` | Nastaviť úrok | iné | rodič `cons_row.visible = false`; úrok sa nastavuje v detaile banky |

### Záložka Štát & správy

| Premenná | Text | Rola | Poznámka |
|---|---|---|---|
| `tax_b` | Nastaviť daň | sekundárne | |
| `event_b` | Reagovať na recesiu | sekundárne | |
| `scale_box` | 1.0 / 1.25 / 1.5 | výber | duplicita voči menu a pauze; bez mena uzla |

### Skryté staré financie — `OldFinanceHidden` ~538

Rodič `visible = false`. Rola všetkých šiestich: **iné**.

| Premenná | Text |
|---|---|
| `bid_free` | Bid dlhopis |
| `ask_free` | Ask dlhopis |
| `stock_bid` | Bid akcie |
| `stock_ask` | Ask akcie |
| `issue_bond_b` | Vydať dlhopis |
| `issue_share_b` | Vydať akcie |

### Suroviny — `scripts/ui/resource_drawer.gd`

Okno nad mapou, nie záložka. Všetko `hud_button.gd` + `Chrome.button`.

| Premenná / meno | Text | Rola | Poznámka |
|---|---|---|---|
| `pin` | Pripnúť / Pripnuté | prepínač | `toggle_mode`; tooltip o pripnutí a ťahaní |
| `close` / `CloseResources` | ✕ | zatvoriť | tooltip „Zavrieť · Esc“ |
| `clear_button` | Klikni na surovinu → zvýrazni tvoje firmy na Atlase | sekundárne | po výbere: `Zrušiť zvýraznenie: {názov} · {n} firiem` |
| hlavička skupiny × 4 | `{Energia\|Suroviny\|Polotovary\|Výrobky}  ▾/▸` | záložka | `toggle_mode`; ikona |
| `Resource_{id}` × 28 | názov komodity z dát (Label vnútri, nie `button.text`) | prepínač | `toggle_mode` + spoločný `ButtonGroup`; výška 78/111; tooltip výroba/spotreba/sklad/cena |

Id skupín (`strategic_hud_data.gd`):

- Energia (5): electricity, coal, crude_oil, natural_gas, fuel
- Suroviny (5): iron_ore, copper, wheat, coffee, meat
- Polotovary (3): steel, chemicals, textiles
- Výrobky (15): electronics, pharma, automobiles, weapons, arms, ships, aircraft, construction, logistics, food_service, finance, pmc, pmc_services, compute, ai_services

---

## 4. Okná

Spoločný vzor: `PanelContainer` + titulok + Button na zatvorenie. Okná registruje `window_drag.gd` (ťahanie za hlavičku, bez vlastného Button).

### Detail firmy — `_ensure_firm_detail` / `_fill_firm_detail` ~2579

Shell (raz): **Zavrieť ✕** — zatvoriť.

Pri nebankovej firme (znova pri každom refreshi):

| Meno | Text | Rola | Kedy |
|---|---|---|---|
| `UpgradeFirm` | Vylepšiť na úroveň {n} ({cena}) | primárne | len úroveň < 3; tooltip o výskume |
| (bez mena) | IPO: predať 30 % akcií na burze | sekundárne | vždy |
| `RenameFirm` | Premenovať firmu | sekundárne | `_brand_ui` ~4493; vedľa LineEdit |
| `RenameCorpFromFirm` | Premenovať korporáciu | sekundárne | len ak firma je v korporácii |
| `ShowProducts` | Ukázať na mape, kam sa predali / Skryť na mape | sekundárne | len vozidlové odvetvia (`Brand.makes_vehicles`) |
| (bez mena) | Predať firmu | nebezpečné | vždy |
| `ZombieEvac` | Označiť ako evakuačnú zónu | DLC | len aktívne zombie DLC |
| (bez mena) | Skúmať vakcínu tu | DLC | DLC + `pharma_lab` alebo `hospital` |
| `FundDeposit` | Vložiť | sekundárne | len `invest_fund` |
| `FundWithdraw` | Vybrať | sekundárne | len `invest_fund` |
| (bez mena) | Obchodovať | prepínač | CheckBox, len `stock_broker` |
| `BrokerRisk` | Riziko nízke / stredné / vysoké | výber | len `stock_broker` |
| (bez mena) | Vložiť kapitál {1 M €} | sekundárne | len `stock_broker` |
| (bez mena) | Vybrať {1 M €} | sekundárne | len `stock_broker` |
| `Pmc_training` | Výcvik +10 ({cena}) | sekundárne | len `pmc_unit` |
| `Pmc_equipment` | Vybavenie +10 ({cena}) | sekundárne | len `pmc_unit` |
| `PmcCity` | `{krajina} – {mesto}` | výber | len `pmc_unit` |
| `PmcDeploy` | Nasadiť | sekundárne | len `pmc_unit`; 0 jednotiek = stiahnuť |
| `SchoolTuitionSet` | Nastaviť | sekundárne | škola / akadémia |

### Banka (ten istý panel, vetva `_fill_bank_detail` ~2926)

Stavba polí je jednorazová (`_bank_ctrl_built`).

| Meno | Text | Rola | Poznámka |
|---|---|---|---|
| `_bank_advisor_button` / `BankAdvisor` | Najať bankového poradcu ({€}/mes.) **alebo** Prepustiť bankového poradcu | sekundárne | text sa mení podľa `advisor.hired` |
| `ab` / `BankApply` | Uložiť nastavenia banky | potvrdiť | |
| `_sovereign_country` / `SovereignCountry` | krajiny `name_sk` | výber | tooltip riziko krajiny po zmene |
| `lend` / `SovereignLend` | Poskytnúť štátny úver | primárne | |
| `_sovereign_auto` | Poradca môže požičiavať vybranej krajine | prepínač | |
| `save` / `SovereignAdvisorLimits` | Uložiť limity štátnych úverov | potvrdiť | |
| `pb` / `PmcCollect` | Poslať PMC na nesplácačov | nebezpečné | |
| (bez mena) | Najať právnika | sekundárne | `_build_legal_ui` ~4093 |
| (bez mena) | Prepustiť | zrušiť | právnici, nie celá banka |
| (bez mena) | Školenie (+úroveň) | sekundárne | |
| `cb` / `BankToCorp` | Začleniť banku do korporácie | sekundárne | cyklus existujúcich korporácií; tooltip o sile právnikov |

### Burza — `_build_burza_window` ~3692 + `stock_view.gd`

| Meno | Text | Rola | Poznámka |
|---|---|---|---|
| `cb` | Zavrieť ✕ | zatvoriť | |
| `sector_pick` / `SectorPick` | Všetky sektory + 12 sektorov | výber | Financie, Poľnohospodárstvo, Zbrojárstvo, Energetika, Technológie, Priemysel, Doprava, Médiá, Zdravotníctvo, Spotrebný tovar, Telekom, AI a dáta |
| `buy_b` | Kúpiť | primárne | `disabled`, keď quote nie je ok |
| `sell_b` | Predať | sekundárne | `disabled` podľa quote predaja |
| (bez mena) | Prevziať (>50 %) | nebezpečné | |
| `absorb_b` / `AbsorbButton` | Začleniť do korporácie | sekundárne | skryté, kým `can_absorb`; `disabled` bez korporácie; tooltip |
| (bez mena) | Založiť korporáciu z vybraných firiem | primárne | |
| `corp_pick` | `{názov} ({ticker}, {n} firiem, hodnota)` | výber | ikona loga |
| (bez mena) | IPO korporácie (30 %) | sekundárne | |
| (bez mena) | Pridať vybranú firmu | sekundárne | |
| (bez mena) | Spin-off vybranej | sekundárne | |
| `cb` v `corp_firms` | `{názov firmy} [{corp}]` | prepínač | **mimo 407**, 1 na firmu hráča, prekreslí sa v `refresh()` |

### Portfólio — `toggle_empire` ~3930 + `empire_view.gd`

| Meno | Text | Rola | Poznámka |
|---|---|---|---|
| `cb` | Zavrieť ✕ | zatvoriť | |
| (bez mena) | Kúpiť štát | primárne | vybraná krajina na mape |
| `gov_pick` | Demokracia, Hybridný režim, Autoritársky režim, Monarchia, Komunistický režim | výber | `disabled`, kým hráč štát nevlastní |
| (bez mena) | Zmeniť systém | nebezpečné | |
| `db` / `DonateButton` | Darovať | sekundárne | suma je SpinBox |
| `corp_pick` | `{korporácia} ({n} firiem)` | výber | |
| `lb` / `EditLogo` | Upraviť logo | sekundárne | otvorí `LogoEditor` |
| `rb` / `RenameCorp` | Premenovať | sekundárne | |
| `hb` / `PlaceHQ` | Umiestniť / presunúť HQ na mape | sekundárne | |
| `cust_scope` / `CustScope` | Vybraná korporácia / Všetky moje firmy | výber | |
| `cust_sort` / `CustSort` | Zoradiť: € / množstvo / krajina / tovar | výber | |
| `re_group` / `ReGroup` | Podľa mesta / krajiny / typu | výber | `_opt` ~306 |
| `re_type` / `ReType` | Všetky typy + Kancelárie, Byty / apartmány, Obchody, Sklady, Prázdna parcela | výber | |
| `re_sort` / `ReSort` | Zoradiť: hodnota / príjem / počet / názov | výber | |

Finančná divízia (`_fill_fin`, len ak je vybraná korporácia; pri refreshi sa zmaže a vznikne znova):

| Meno | Text | Rola |
|---|---|---|
| `on` / `FinOn` | Finančná divízia zapnutá | prepínač |
| `cb` × 4 | Optimalizovať (upgrady ziskových firiem); Predávať chronicky stratové (6+ mes.); Obchodovať akcie (kúp pod priemerom, predaj nad); Preberať firmy (>50 %) a začleňovať do korporácie | prepínač |
| `sc` × 12 | názvy sektorov burzy (rovnaký zoznam ako filter burzy) | prepínač |

### Logo — `logo_editor.gd` (AcceptDialog, dieťa portfólia)

| Premenná | Popisok | Rola | Poznámka |
|---|---|---|---|
| vstavané OK | Uložiť logo | potvrdiť | `ok_button_text`; nie je `Button.new()`, ale je to Button dialógu |
| `shape_p` | Tvar: Kruh, Štvorec, Štít, Šesťuholník, Kosoštvorec | výber | |
| `sym_p` | Symbol: Bez symbolu, Hviezda, Blesk, List, Koruna, Hora, Kvapka, Šípka, Vlna, Ozubené koleso, Glóbus | výber | |
| `bg_b` | Pozadie | iné | ColorPickerButton, min. 90×28 |
| `fg_b` | Symbol a text | iné | ColorPickerButton |

Krížik titulku dialógu nie je projektový Button.

### Krajina — `open_country_firms` ~3742

| Meno | Text | Rola | Poznámka |
|---|---|---|---|
| `cb` | ✕ | zatvoriť | |
| `b` | `{firma} – {typ} ({mesto})` | sekundárne | **mimo 407**; ikona; `clip_text`; tooltip = celý text |
| `pp` / `LobbyPolitician` | `{meno} ({rola}) – lojalita {n}` | výber | `_power_ui` ~4895 |
| `lb` / `LobbyGo` | Lobovať | sekundárne | tooltip o škandále |
| `cb` / `Law_{id}` × 4 | daňová úľava; dotácie; rýchle povolenia; vládne zákazky | prepínač | **len ak** `Society.has_control` |
| `fp` / `ContractPmc` | názvy PMC firiem hráča | výber | len ak hráč má `pmc_unit` |
| `go` / `ContractPropose` | Navrhnúť bezpečnostnú zmluvu | sekundárne | to isté |

Zákony (texty): „Daňová úľava pre tvoje firmy (daň ×0,75)“, „Dotácie (1,5 % tržieb tvojich firiem v krajine mesačne)“, „Rýchle povolenia (stavba v krajine −15 %)“, „Vládne zákazky (mesačná platba podľa HDP)“.

### Mesto — `open_city_panel` ~3391

| Meno | Text | Rola | Poznámka |
|---|---|---|---|
| `cb` | Zavrieť ✕ | zatvoriť | shell, raz |
| `bb` | Postaviť v tomto meste | sekundárne | zavrie panel, prepne záložku Založiť |
| `tpick` / `PropType` | `{typ} – {cena}` | výber | prekreslí sa pri každom otvorení (`BuyBuilding` sa zmaže) |
| `bb2` | Kúpiť cez realitku | primárne | tooltip: treba Realitku v krajine |
| `db` × 4 | `{Kancelárie\|Byty / apartmány\|Obchody\|Sklady} ({cena})` | sekundárne | len prvá prázdna parcela v meste |
| `zb` / `ZombieCity` | Toto mesto je safe zóna | DLC | len aktívne DLC |

### Noviny — `_build_news_panel` ~2249

Filtre (sekundárne): všetko, firmy, vojna, ceny, politika, šoky, nákaza, ostatné. Plus **Zavrieť** (zatvoriť). Vzniknú až pri prvom kliku na Noviny.

### Lode — `_toggle_ships` ~2291

| Meno | Text | Rola |
|---|---|---|
| `pick` / `ShipPick` | `{názov lode} ({cena})` z `ShipSystem.catalog` | výber |
| `buy` | Kúpiť od štátu | sekundárne |
| `yard` | Postaviť v lodenici (72 %) | sekundárne |
| `sell` | Predať prvú vojenskú loď štátu | sekundárne |
| `close` | Zavrieť | zatvoriť |

### Návrhy — `_toggle_arms` ~2358

| Meno | Text | Rola |
|---|---|---|
| `pick` / `BpPick` | názov z `ArmsSystem.catalog` | výber |
| `buy` | Kúpiť blueprint | sekundárne |
| `make` | Navrhnúť | sekundárne |
| `sell` | Predať prvý návrh štátu | sekundárne |
| `close` | Zavrieť | zatvoriť |

Názov návrhu je LineEdit „Vlastný názov“.

### Lobing (záložka Vplyv) — `influence_view.gd`

| Meno | Text | Rola | Poznámka |
|---|---|---|---|
| `target2` / `InfluenceTarget2` | krajiny `name_sk` | výber | „Krajina B“ |
| `party` | strany vybranej krajiny | výber | dynamické položky |
| `Inf_{id}` × 12 | `{akcia} – {cena}, šanca {%}, škandál {%}` | sekundárne (úplatok = nebezpečné) | text sa pri `refresh()` / `_show()` zmaže a vznikne znova; `autowrap` |

Akcie: Mediálna kampaň (zvýši vplyv), Financovať stranu, Podporiť stranu pred voľbami, Lobovať: colná úľava s krajinou B, Lobovať: obchodná zmluva s krajinou B, Lobovať: sankcie na krajinu B (konkurent), Lobovať: embargo voči krajine B, Lobovať za mier, Podporiť vo vojne (dodávky/financie), Lobovať: nižšie dane, Lobovať: menej regulácie, Úplatok (len s cieľom Korupcia) — posledná je **nebezpečné**.

### DLC panel — `_build_zombie_panel` ~1486, helper `_zbtn` ~1532

Všetky **DLC**. Vzniknú len pri aktívnom DLC.

Kresliť safe zónu; Kúpiť helikoptéru; Kúpiť stíhačku; Priradiť armádu a letectvo; Stavba v zóne: nemocnica / letisko / karantena / baraky / pristav / zeleznica / mur; Politika: vyhnanstvo helikoptérou; Politika: zabiť nakazených (trest smrti — stále rola DLC, nie samostatná „nebezpečné“, aby Halloween ostal jedna rodina); Politika: nechať tak; Začať vakcínu; Zrýchliť vakcínu; Nasadiť vakcínu; Postaviť bunker; Zavrieť.

Karty bunkrov (`_fill_bunker_cards`): na každý bunker **Vylepšiť** a **Postaviť laboratórium**. Mimo 407, násobok počtu bunkrov.

---

## 5. Pauza, tutoriál, intro

### Pauza — `scripts/ui/pause_popup.gd`

`_b()` ~63 skladá Button (min. výška 38). `_clear()` deti **zmaže**, preto v strome nie je naraz všetkých 20 tlačidiel. V katalógu 407 sú všetky vetvy.

| Obrazovka | Text | Meno | Rola | Poznámka |
|---|---|---|---|---|
| PAUZA | Pokračovať | `PauseContinue` | primárne | `close()` |
| PAUZA | Uložiť hru | `PauseSave` | sekundárne | |
| PAUZA | Načítať hru | `PauseLoad` | sekundárne | |
| PAUZA | Nastavenia | `PauseSettings` | sekundárne | |
| PAUZA | Ukončiť hru | `PauseQuit` | nebezpečné | |
| ULOŽIŤ | `Slot %d` + ` – prepísať` ak existuje × 3 | `SaveSlot1..3` | sekundárne | po uložení zostane na tejto obrazovke |
| ULOŽIŤ | Späť | | zrušiť | |
| NAČÍTAŤ | `Slot %d` / ` (prázdny)` × 3 | `LoadSlot1..3` | sekundárne | prázdny `disabled`; potom dialóg POTVRDIŤ |
| NAČÍTAŤ | Späť | | zrušiť | |
| NASTAVENIA | Mierka UI 1.0 / 1.25 / 1.5 | | výber | `host._on_ui_scale` |
| NASTAVENIA | Celá obrazovka | | prepínač | CheckBox, prepína fullscreen |
| NASTAVENIA | Späť | | zrušiť | |
| UKONČIŤ | Do hlavného menu | `QuitMenu` | nebezpečné | ešte raz potvrdí |
| UKONČIŤ | Na plochu | `QuitDesktop` | nebezpečné | `get_tree().quit()` |
| UKONČIŤ | Späť | | zrušiť | |
| POTVRDIŤ | Najprv uložiť (slot 1) a pokračovať | `ConfirmSave` | potvrdiť | vetva je vždy zapnutá (`if true`) |
| POTVRDIŤ | Áno | `ConfirmYes` | potvrdiť | |
| POTVRDIŤ | Nie | `ConfirmNo` | zrušiť | späť na pauzu |

### Tutoriál — `scripts/ui/tutorial_overlay.gd` ~34

| Premenná | Text | Rola | Poznámka |
|---|---|---|---|
| `next_button` | Ďalej | sekundárne | na poslednom kroku text **Zavrieť**; `focus_mode = FOCUS_NONE` |

Tutoriál len zvýrazňuje cudzie tlačidlá (hľadá text „1x“, „Pauza“, „Kaviareň“, „Pôžička“, „Logistika I“, „Svet / Región“). Vlastné ďalšie Button nevytvára. „Pauza“ v texte kroku je tooltip hornej lišty, nie nápis na tlačidle (tlačidlo je ikona).

### Intro — `scripts/ui/intro_scene.gd`

Žiadny Button, CheckBox, OptionButton ani ColorPickerButton. Nápoveda je Label: „Medzerník = ďalej    Esc / klik = preskočiť“.

---

## 6. Cheat konzola — `scripts/ui/cheat_console.gd`

**Žiadny Button, TextureButton, CheckBox, CheckButton, OptionButton ani ColorPickerButton.**

Otvára sa 3× Ctrl+C počas hry. UI je `RichTextLabel` (`CheatOutput`) + `LineEdit` (`CheatInput`, placeholder „príkaz…“). Zatvorenie: príkaz `close` / `exit` alebo Esc. Príkazy (`help`, `money`, `research all`, `unlock all`, `dev`, `skip`, `event`, `war`, `errors`, `fps`, `clear`) nie sú tlačidlá.

---

## 7. Ostatné UI skripty

| Súbor | Čo vytvára | Poznámka |
|---|---|---|
| `build_menu.gd` | 11 hlavičiek (záložka) + až 64 odvetví (sekundárne) | pozri §3 |
| `empire_view.gd` | 6 Button, 7 OptionButton, CheckBox divízie (1+4+12) | pozri §4; `logo_editor` je dieťa |
| `stock_view.gd` | 8 Button, 2 OptionButton, CheckBox × firmy | pozri §4 |
| `credit_panel.gd` | 3 Button + CheckBox × firmy | pozri §3 |
| `bonds_view.gd` | 1 Button `IssueBond` | pozri §3 |
| `influence_view.gd` | 2 OptionButton + 12 Button | pozri §4 |
| `focus_tree_view.gd` | Button na každý focus (katalóg 22) | pozri §3 |
| `research_tree_view.gd` | Button na každý výskum | **mimo 407**, v `data/research.json` je 25 záznamov |
| `logo_editor.gd` | 1 OK, 2 OptionButton, 2 ColorPickerButton | pozri §4 |
| `pause_popup.gd` | 20 Button (nie naraz) + 1 OptionButton + 1 CheckBox | pozri §5 |
| `tutorial_overlay.gd` | 1 Button | pozri §5 |
| `top_bar.gd` | 6 Button | pozri §2 |
| `resource_drawer.gd` | 35 Button | pozri §3 |
| `hud_button.gd` | trieda, 0 inštancií sama | tooltip |
| `cheat_console.gd` | 0 | §6 |
| `intro_scene.gd` | 0 | §5 |
| `research_tree.gd` | 0 (kresba) | |
| `strategic_skin.gd` | 0 (štýlovač) | |
| `window_drag.gd`, `world_map.gd`, `region_view.gd`, `firm_chart.gd`, atlas skripty | 0 týchto typov | myš sú `InputEventMouseButton`, nie widget |

---

## Súhrn podľa roly

Jedna rola na widget. DLC má prednosť pred „nebezpečné“ / „zatvoriť“ (Halloween ostane jedna koža). Skryté legacy tlačidlá sú „iné“. Uzly stromu cieľov sú „iné“ (hustá mriežka, nie lištové CTA).

| Rola | Počet |
|---|---:|
| hlavné menu | 20 |
| primárne | 16 |
| sekundárne | 173 |
| ikonové | 6 |
| záložka | 16 |
| zatvoriť | 9 |
| potvrdiť | 5 |
| zrušiť | 7 |
| nebezpečné | 12 |
| prepínač | 58 |
| výber (OptionButton) | 29 |
| DLC | 25 |
| cheat konzola | 0 |
| iné | 31 |
| **Spolu** | **407** |

Z toho prepínač = 33 Button (lišta, pin, 28 surovín) + 25 CheckBox. DLC = 24 Button + 1 CheckBox (Halloween v novej hre). „Iné“ = 7 skrytých finančných Button + 22 focus uzlov + 2 ColorPickerButton.

### Najväčšie rodiny pre theme pass

1. **Menu** (`_menu_style`, zlatý hover, prefix `▸`) — nespájať s hernou lištou.
2. **Strategické HUD** (`hud_button` + `strategic_skin`) — pauza, rýchlosti, deň, suroviny, pin, ✕, skupiny a riadky komodít.
3. **Lišta mapy** — textové CTA (Burza, Portfólio, …) vs. ikonové ◀▶ vs. prepínače vrstiev.
4. **Zoznam stavieb** — 11 plochých hlavičiek + desiatky rovnakých odvetvových Button (ellipsis, tooltip).
5. **Stromy** — focus (22) a výskum (N): malé 150×46, dvojrriadkový text, disabled + zelený modulate. Research shortcuty v záložke Firma majú anglické id.
6. **Dialógy okien** — jednotný „Zavrieť ✕“ / „✕“; primárne akcie (kúpiť, IPO, úver, R&D) vs. predaj/prevzatie/PMC.
7. **Pauza** — päť úrovní, ktoré sa nahrádzajú; nebezpečné sú ukončenia, potvrdiť je Áno / uložiť pred odchodom.
8. **Výber** — 29 OptionButton (mierka je na troch miestach: menu, štát, pauza).
9. **DLC** — lišta Nákaza/Zombie + panel + safe zóna + evakuácia/vakcína v detaile. Bez Button v cheat konzole.
10. **Dynamika mimo 407** — `Detail: %s`, zálohy, firmy v burze a v krajine, bunkre, celý strom výskumu. Theme musí sedieť aj na tlačidlo vzniknuté neskôr, lebo žiadne z nich nedostane inú triedu než `Button` / `CheckBox`.
