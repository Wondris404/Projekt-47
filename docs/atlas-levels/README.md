# Galéria Atlasu — 65 typov, tri úrovne

Všetky obrázky vznikli v Godote 4.7.2 cez Xvfb a softvérový renderer Mesa llvmpipe.
Každý prehľad obsahuje tri úrovne pri spoločnej mierke a malé vzorky 24/32/48 px.
Samostatné obrázky v `individual/` sú výrezy príslušných stĺpcov, nie ďalší render.

[Úplný popis, licencie a otvorené body](../PREBETA_09_PRIESKUM_IKON.md) · [Filtrovaná HTML galéria](index.html)

Banka, HQ, samostatný žeriav a diaľnica majú L2/L3 iba ako pripravené grafické varianty.
V testovacích Atlas scénach sú typy umiestnené do pravidelnej mriežky na kontrolu;
nejde o uloženú používateľskú hru ani nové ekonomické pravidlá umiestnenia.

## Reprodukcia

```bash
python tools/atlas/generate_levels.py
python tools/atlas/validate_levels.py
P47_GODOT_BIN=/cesta/k/godot-4.7.2 P47_XVFB_BIN=Xvfb bash tools/atlas/capture_levels.sh
```

Skript používa dočasné XDG priečinky a vlastný Xvfb displej. Nenačítava ani
neukladá reálne hráčove savy. Potrebné: Python 3, Pillow, Godot 4.7.2, Xvfb, Mesa.

## Snímky na mape

[Strana 1](atlas_01.png) · [Strana 2](atlas_02.png) · [Strana 3](atlas_03.png) · [Strana 4](atlas_04.png) · [Strana 5](atlas_05.png) · [Strana 6](atlas_06.png) · [Strana 7](atlas_07.png) · [Strana 8](atlas_08.png) · [Strana 9](atlas_09.png) · [Strana 10](atlas_10.png) · [Strana 11](atlas_11.png) · [Strana 12](atlas_12.png) · [Strana 13](atlas_13.png)

## Priebeh upgradu

- Úroveň 1 → 2: [0 %](upgrade_to_2_0.png) · [25 %](upgrade_to_2_1.png) · [50 %](upgrade_to_2_2.png) · [75 %](upgrade_to_2_3.png) · [100 %](upgrade_to_2_4.png)
- Úroveň 2 → 3: [0 %](upgrade_to_3_0.png) · [25 %](upgrade_to_3_1.png) · [50 %](upgrade_to_3_2.png) · [75 %](upgrade_to_3_3.png) · [100 %](upgrade_to_3_4.png)

## Všetky typy

### Kaviareň — `cafe`

Kaviareň so štítom a vonkajším slnečníkom.

![Kaviareň — všetky úrovne](cafe.png)

### Farma — `wheat_farm`

Stodola, obilné pole a silo.

![Farma — všetky úrovne](wheat_farm.png)

### Plantáž — `coffee_farm`

Plantáž s kávovníkmi a stodolou.

![Plantáž — všetky úrovne](coffee_farm.png)

### Chov — `livestock`

Farma so stodolou a zvieratami.

![Chov — všetky úrovne](livestock.png)

### Ropný vrt — `oil_well`

Ťažobné čerpadlo s vahadlom a obslužnou budovou.

![Ropný vrt — všetky úrovne](oil_well.png)

### Uhoľná baňa — `coal_mine`

Ťažná veža so zvislým kolesom a kopou uhlia.

![Uhoľná baňa — všetky úrovne](coal_mine.png)

### Baňa na rudu — `iron_mine`

Stupňovitá rudná baňa s dopravníkom.

![Baňa na rudu — všetky úrovne](iron_mine.png)

### Medená baňa — `copper_mine`

Stupňovitá medená baňa, obslužná budova a manipulačný žeriav.

![Medená baňa — všetky úrovne](copper_mine.png)

### Elektráreň — `power_coal`

Turbínová hala, červené komíny a zásoba uhlia.

![Elektráreň — všetky úrovne](power_coal.png)

### Oceliareň — `steel_mill`

Tehlová oceliareň, vysoká pec a žeravá oceľ.

![Oceliareň — všetky úrovne](steel_mill.png)

### Chemička — `chem_plant`

Procesné nádoby a prepojené potrubie na hale.

![Chemička — všetky úrovne](chem_plant.png)

### Laboratórium — `pharma_lab`

Laboratórna budova s krížom a chladením.

![Laboratórium — všetky úrovne](pharma_lab.png)

### Textilka — `textile_mill`

Textilná hala so sedlovou strechou, komínom a cievkami.

![Textilka — všetky úrovne](textile_mill.png)

### Elektronika — `electronics_plant`

Výrobná hala, strešné svetlíky a zelený elektronický znak.

![Elektronika — všetky úrovne](electronics_plant.png)

### Automobilka — `auto_plant`

Montážna hala, automobilový znak a hotové vozidlo.

![Automobilka — všetky úrovne](auto_plant.png)

### Zbrojovka — `arms_plant`

Tehlová zbrojovka s obranným emblémom a muničnou debnou.

![Zbrojovka — všetky úrovne](arms_plant.png)

### Stavbár — `construction_co`

Stavebný areál s vežovým žeriavom a materiálom.

![Stavbár — všetky úrovne](construction_co.png)

### Logistika — `logistics_hub`

Nízke prekladisko, kamióny a rampy.

![Logistika — všetky úrovne](logistics_hub.png)

### Finančná kancelária — `finance_office`

Finančná budova s mincovým emblémom.

![Finančná kancelária — všetky úrovne](finance_office.png)

### Súkromná bezpečnosť — `pmc_unit`

Bezpečnostná základňa so štítom.

![Súkromná bezpečnosť — všetky úrovne](pmc_unit.png)

### Obchodná kancelária — `trade_desk`

Kancelária s vonkajšou obrazovkou kurzov.

![Obchodná kancelária — všetky úrovne](trade_desk.png)

### Reštaurácia — `restaurant`

Európska reštaurácia s komínom a zastrešenou terasou.

![Reštaurácia — všetky úrovne](restaurant.png)

### Pekáreň — `bakery`

Európska pekáreň, sedlová strecha, komín a chlieb na štíte.

![Pekáreň — všetky úrovne](bakery.png)

### Fitko — `gym`

Športová budova s dominantnou činkou.

![Fitko — všetky úrovne](gym.png)

### Autoservis — `auto_service`

Servisná hala so znakom auta a vozidlom.

![Autoservis — všetky úrovne](auto_service.png)

### E-shop — `eshop`

Expedičná hala, dodávka a balíky.

![E-shop — všetky úrovne](eshop.png)

### Realitka — `real_estate`

Dom so sedlovou strechou a ceduľou PREDAJ.

![Realitka — všetky úrovne](real_estate.png)

### Hotel — `hotel`

Výškový hotel s balkónmi, strešným bazénom a krytým príjazdom.

![Hotel — všetky úrovne](hotel.png)

### Supermarket — `supermarket`

Predajná hala s dlhým zeleným označením.

![Supermarket — všetky úrovne](supermarket.png)

### Logistika a sklady — `warehouse`

Vysoká regálová hala s rebrovaným exteriérom.

![Logistika a sklady — všetky úrovne](warehouse.png)

### Softvérová firma — `software`

Kancelária so symbolom kódu.

![Softvérová firma — všetky úrovne](software.png)

### Reklamná agentúra — `ad_agency`

Strešný billboard na kancelárii.

![Reklamná agentúra — všetky úrovne](ad_agency.png)

### Súkromná klinika — `clinic`

Nízka ambulancia s červeným krížom.

![Súkromná klinika — všetky úrovne](clinic.png)

### Výroba čipov — `chip_fab`

Uzavretá čistá výroba s technickým strešným blokom a odťahmi.

![Výroba čipov — všetky úrovne](chip_fab.png)

### Letecká spoločnosť — `airline`

Prevádzková budova a dominantný chvost lietadla s vlastným znakom.

![Letecká spoločnosť — všetky úrovne](airline.png)

### Telekom — `telecom`

Telekomunikačná budova s vysokým anténovým stožiarom.

![Telekom — všetky úrovne](telecom.png)

### Solárna elektráreň — `solar_plant`

Rady solárnych panelov a meničová budova.

![Solárna elektráreň — všetky úrovne](solar_plant.png)

### Plynová elektráreň — `gas_plant`

Turbínové bloky a dvojica svetlých výfukových komínov.

![Plynová elektráreň — všetky úrovne](gas_plant.png)

### Jadrová elektráreň — `nuclear_plant`

Reaktorový blok s kupolou a chladiace veže.

![Jadrová elektráreň — všetky úrovne](nuclear_plant.png)

### Lodenica — `shipyard`

Lodenica s halou, dvoma žeriavmi a rozostavanou loďou.

![Lodenica — všetky úrovne](shipyard.png)

### Poisťovňa — `insurance`

Modrý panel s dáždnikom na fasáde.

![Poisťovňa — všetky úrovne](insurance.png)

### Investičný fond — `invest_fund`

Štíhla sklenená veža.

![Investičný fond — všetky úrovne](invest_fund.png)

### Televízia — `tv_station`

Štúdiová budova so satelitnými taniermi.

![Televízia — všetky úrovne](tv_station.png)

### Sociálna sieť — `social_network`

Kampus s vlastným symbolom prepojenia.

![Sociálna sieť — všetky úrovne](social_network.png)

### Noviny — `newspaper`

Tehlová tlačiareň s komínom a novinovým štítom.

![Noviny — všetky úrovne](newspaper.png)

### Kasíno — `casino`

Dve zlaté výškové veže, neónové pásy a diamantový vstupný znak.

![Kasíno — všetky úrovne](casino.png)

### Offshore firma — `offshore`

Vila, palma a bazénová terasa.

![Offshore firma — všetky úrovne](offshore.png)

### Letisko — `airport`

Terminál, riadiaca veža a značenie letiskovej plochy.

![Letisko — všetky úrovne](airport.png)

### Ropná rafinéria — `oil_refinery`

Destilačné kolóny, technologická hala a valcová nádrž.

![Ropná rafinéria — všetky úrovne](oil_refinery.png)

### Plynáreň — `gas_works`

Plynárenská hala so zásobníkom a odťahom.

![Plynáreň — všetky úrovne](gas_works.png)

### Burza / obchodník s cennými papiermi — `stock_broker`

Burzová kancelária s kurzovou obrazovkou a zlatou kupolou.

![Burza / obchodník s cennými papiermi — všetky úrovne](stock_broker.png)

### Vrt na zemný plyn — `gas_well`

Vrtná veža, potrubie a ventil.

![Vrt na zemný plyn — všetky úrovne](gas_well.png)

### Letecká továreň — `aircraft_plant`

Výrobný hangár s celým lietadlom.

![Letecká továreň — všetky úrovne](aircraft_plant.png)

### Dátové centrum — `data_center`

Uzavretá hala s dvojicou strešných chladiacich jednotiek.

![Dátové centrum — všetky úrovne](data_center.png)

### AI firma — `ai_firm`

Serverové skrine na streche a anténa.

![AI firma — všetky úrovne](ai_firm.png)

### Súkromná nemocnica — `hospital`

Viacposchodová nemocnica s krížom.

![Súkromná nemocnica — všetky úrovne](hospital.png)

### Nákladný prístav — `cargo_port`

Kontajnerový terminál, žeriav a loď s kontajnermi.

![Nákladný prístav — všetky úrovne](cargo_port.png)

### Súkromná základná škola — `school_primary`

Škola so sedlovou strechou, vlajkou a ihriskom.

![Súkromná základná škola — všetky úrovne](school_primary.png)

### Súkromná stredná škola — `school_high`

Školská budova s hodinovou vežou.

![Súkromná stredná škola — všetky úrovne](school_high.png)

### Súkromná univerzita — `university`

Univerzita s portikom, stĺpmi a kupolou.

![Súkromná univerzita — všetky úrovne](university.png)

### Firemná akadémia — `corp_academy`

Školiace centrum so zeleným znakom a presklenou časťou.

![Firemná akadémia — všetky úrovne](corp_academy.png)

### Banka — `bank`

Výšková finančná veža so stĺpovým vstupom a zlatou stupňovitou korunou.

![Banka — všetky úrovne](bank.png)

### Centrála — `hq`

Najvyššia kancelárska veža s heliportom.

![Centrála — všetky úrovne](hq.png)

### Prístavný žeriav — `port`

Samostatné prístavné žeriavy na móle.

![Prístavný žeriav — všetky úrovne](port.png)

### Diaľnica — `highway`

Diaľničný most na pilieroch.

![Diaľnica — všetky úrovne](highway.png)
