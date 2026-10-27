# Audit počtov zamestnancov – 2026-10-27

Návrh základného počtu ľudí na prevádzku prvej úrovne. Sú to herné odhady, nie overené údaje o konkrétnych firmách; zatiaľ nemenia simuláciu. Úrovne 2 a 3 v súčasnom modeli menia mierku prevádzky približne ×1,35 a ×1,8225.

| Typ | Súčasná pracovná jednotka | Navrhovaní zamestnanci |
|---|---:|---:|
| Kaviareň (`cafe`) | 5 | 8 |
| Farma (`wheat_farm`) | 2 | 8 |
| Plantáž (`coffee_farm`) | 6 | 25 |
| Chov (`livestock`) | 3 | 12 |
| Ropný vrt (`oil_well`) | 8 | 150 |
| Uhoľná baňa (`coal_mine`) | 10 | 300 |
| Baňa na rudu (`iron_mine`) | 10 | 350 |
| Medená baňa (`copper_mine`) | 12 | 350 |
| Elektráreň (`power_coal`) | 6 | 250 |
| Oceliareň (`steel_mill`) | 14 | 800 |
| Chemička (`chem_plant`) | 12 | 600 |
| Laboratórium (`pharma_lab`) | 10 | 500 |
| Textilka (`textile_mill`) | 9 | 350 |
| Elektronika (`electronics_plant`) | 16 | 700 |
| Automobilka (`auto_plant`) | 28 | 1000 |
| Zbrojovka (`arms_plant`) | 18 | 650 |
| Stavbár (`construction_co`) | 8 | 160 |
| Logistika (`logistics_hub`) | 6 | 200 |
| Finančná kancelária (`finance_office`) | 4 | 30 |
| Súkromná bezpečnosť (`pmc_unit`) | 10 | 150 |
| Obchodná kancelária (`trade_desk`) | 3 | 15 |
| Reštaurácia (`restaurant`) | 9 | 18 |
| Pekáreň (`bakery`) | 4 | 12 |
| Fitko (`gym`) | 3 | 12 |
| Autoservis (`auto_service`) | 4 | 12 |
| E-shop (`eshop`) | 1 | 15 |
| Realitka (`real_estate`) | 3 | 15 |
| Hotel (`hotel`) | 25 | 100 |
| Supermarket (`supermarket`) | 30 | 70 |
| Logistika a sklady (`warehouse`) | 12 | 100 |
| Softvérová firma (`software`) | 15 | 80 |
| Reklamná agentúra (`ad_agency`) | 8 | 40 |
| Súkromná klinika (`clinic`) | 20 | 100 |
| Výroba čipov (`chip_fab`) | 40 | 1200 |
| Letecká spoločnosť (`airline`) | 60 | 1200 |
| Telekom (`telecom`) | 30 | 900 |
| Solárna elektráreň (`solar_plant`) | 3 | 35 |
| Plynová elektráreň (`gas_plant`) | 6 | 160 |
| Jadrová elektráreň (`nuclear_plant`) | 40 | 700 |
| Lodenica (`shipyard`) | 50 | 1500 |
| Poisťovňa (`insurance`) | 12 | 300 |
| Investičný fond (`invest_fund`) | 6 | 50 |
| Televízia (`tv_station`) | 30 | 350 |
| Sociálna sieť (`social_network`) | 25 | 400 |
| Noviny (`newspaper`) | 10 | 120 |
| Kasíno (`casino`) | 20 | 180 |
| Offshore firma (`offshore`) | 1 | 12 |
| Letisko (`airport`) | 80 | 900 |
| Ropná rafinéria (`oil_refinery`) | 12 | 650 |
| Plynáreň (`gas_works`) | 6 | 120 |
| Burza / obchodník s cennými papiermi (`stock_broker`) | 8 | 80 |
| Vrt na zemný plyn (`gas_well`) | 6 | 120 |
| Letecká továreň (`aircraft_plant`) | 90 | 1800 |
| Dátové centrum (`data_center`) | 12 | 200 |
| AI firma (`ai_firm`) | 25 | 120 |

Banka je samostatný systém mimo zoznamu receptov; pre pobočku je pracovný návrh 25 ľudí na prvej úrovni.

## Riziká a postup

- Aktuálne `labor` súčasne určuje cieľový počet ľudí, mzdové náklady a obsadenosť prevádzky. Jeho samotné navýšenie násobne zvýši náklady a môže zavrieť firmy alebo zmeniť ceny.
- Staré save v3 môžu obsahovať čiastočne obsadené firmy. Pri migrácii treba zachovať pôvodný podiel obsadenosti, nie nastaviť všetkých na plný stav, a zabrániť opakovanej migrácii.
- Na zachovanie zmysluplnej mzdy na osobu treba súčasne prepočítať produkčnú kapacitu, vstupy, náklady a prípadne veľkosť prevádzky. Pre každú skupinu treba zmerať zisk, ceny, trh a dostupný kapitál pred a po zmene; nezamieňať počet ľudí s účtovnými pracovnými jednotkami.
- Návrh nie je implementácia a pred nasadením vyžaduje porovnanie ekonomiky a prehľad dopadov.
