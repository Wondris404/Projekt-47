# Pre-Beta-0.9: inventár grafických podkladov

Východiskový katalóg podľa `data/industries.json` a `data/commodities.json` vo verzii main `5d8f40756919480bb8a440debdbb41eb2ef1d229`. Je to zoznam na výber a overovanie 3D podkladov, nie dôkaz, že modely už existujú alebo chýbajú.

V aktuálnej hre sa Atlas a pixelová mapa vykresľujú cez `scripts/ui/world_map.gd` a `scripts/ui/atlas_layer.gd`; prepínač je predmetom rozpracovaného PR #9. Godot projekt používa GL Compatibility. Projekt obsahuje aj existujúce 2D ikony a mapové podklady, ktoré treba pri práci inventarizovať podľa použitia.

Podklady treba skontrolovať z hľadiska jednotného štýlu, polohy na mape, variantov, náhľadu a licencie. Nižšie uvedený stav znamená, že výber modelu a overenie licencie pre tento účel ešte neboli zaznamenané.

## Podniky

| ID | Názov | Zóna | 3D model a licencia |
| --- | --- | --- | --- |
| cafe | Kaviareň | commercial | Neoverené |
| wheat_farm | Farma | industrial | Neoverené |
| coffee_farm | Plantáž | industrial | Neoverené |
| livestock | Chov | industrial | Neoverené |
| oil_well | Ropný vrt | industrial | Neoverené |
| coal_mine | Uhoľná baňa | industrial | Neoverené |
| iron_mine | Baňa na rudu | industrial | Neoverené |
| copper_mine | Medená baňa | industrial | Neoverené |
| power_coal | Elektráreň | industrial | Neoverené |
| steel_mill | Oceliareň | industrial | Neoverené |
| chem_plant | Chemička | industrial | Neoverené |
| pharma_lab | Laboratórium | industrial | Neoverené |
| textile_mill | Textilka | industrial | Neoverené |
| electronics_plant | Elektronika | industrial | Neoverené |
| auto_plant | Automobilka | industrial | Neoverené |
| arms_plant | Zbrojovka | industrial | Neoverené |
| construction_co | Stavbár | industrial | Neoverené |
| logistics_hub | Logistika | port | Neoverené |
| finance_office | Finančná kancelária | commercial | Neoverené |
| pmc_unit | Súkromná bezpečnosť | industrial | Neoverené |
| trade_desk | Obchodná kancelária | commercial | Neoverené |
| restaurant | Reštaurácia | commercial | Neoverené |
| bakery | Pekáreň | commercial | Neoverené |
| gym | Fitko | commercial | Neoverené |
| auto_service | Autoservis | commercial | Neoverené |
| eshop | E-shop | commercial | Neoverené |
| real_estate | Realitka | commercial | Neoverené |
| hotel | Hotel | commercial | Neoverené |
| supermarket | Supermarket | commercial | Neoverené |
| warehouse | Logistika a sklady | port | Neoverené |
| software | Softvérová firma | commercial | Neoverené |
| ad_agency | Reklamná agentúra | commercial | Neoverené |
| clinic | Súkromná klinika | commercial | Neoverené |
| chip_fab | Výroba čipov | industrial | Neoverené |
| airline | Letecká spoločnosť | port | Neoverené |
| telecom | Telekom | commercial | Neoverené |
| solar_plant | Solárna elektráreň | industrial | Neoverené |
| gas_plant | Plynová elektráreň | industrial | Neoverené |
| nuclear_plant | Jadrová elektráreň | industrial | Neoverené |
| shipyard | Lodenica | port | Neoverené |
| insurance | Poisťovňa | commercial | Neoverené |
| invest_fund | Investičný fond | commercial | Neoverené |
| tv_station | Televízia | commercial | Neoverené |
| social_network | Sociálna sieť | commercial | Neoverené |
| newspaper | Noviny | commercial | Neoverené |
| casino | Kasíno | commercial | Neoverené |
| offshore | Offshore firma | commercial | Neoverené |
| airport | Letisko | port | Neoverené |
| oil_refinery | Ropná rafinéria | industrial | Neoverené |
| gas_works | Plynáreň | industrial | Neoverené |
| stock_broker | Burza / obchodník s cennými papiermi | commercial | Neoverené |
| gas_well | Vrt na zemný plyn | industrial | Neoverené |
| aircraft_plant | Letecká továreň | industrial | Neoverené |
| data_center | Dátové centrum | industrial | Neoverené |
| ai_firm | AI firma | commercial | Neoverené |
| hospital | Súkromná nemocnica | commercial | Neoverené |
| cargo_port | Nákladný prístav | port | Neoverené |
| school_primary | Súkromná základná škola | commercial | Neoverené |
| school_high | Súkromná stredná škola | commercial | Neoverené |
| university | Súkromná univerzita | commercial | Neoverené |
| corp_academy | Firemná akadémia | commercial | Neoverené |

## Komodity

| ID | Názov | Jednotka | 3D náhľad a licencia |
| --- | --- | --- | --- |
| wheat | Pšenica | t | Neoverené |
| coffee | Káva | t | Neoverené |
| meat | Mäso | t | Neoverené |
| crude_oil | Ropa | bbl | Neoverené |
| coal | Uhlie | t | Neoverené |
| iron_ore | Železná ruda | t | Neoverené |
| copper | Meď | t | Neoverené |
| steel | Oceľ | t | Neoverené |
| chemicals | Chemikálie | t | Neoverené |
| pharma | Liečivá | šarža | Neoverené |
| textiles | Textil | bal | Neoverené |
| electronics | Elektronika | ks | Neoverené |
| automobiles | Automobily | ks | Neoverené |
| weapons | Zbrane | šarža | Neoverené |
| electricity | Elektrina | MWh | Neoverené |
| construction | Stavba | zmluva | Neoverené |
| logistics | Logistika | zásielka | Neoverené |
| food_service | Pohostinstvo | porcia | Neoverené |
| finance | Finančné služby | mandát | Neoverené |
| pmc | Súkromná bezpečnosť | kontrakt | Neoverené |
| arms | Zbrane a munícia | šarža | Neoverené |
| pmc_services | Kontrakty PMC | kontrakt | Neoverené |
| fuel | Palivá (benzín, nafta) | t | Neoverené |
| natural_gas | Zemný plyn | MWh | Neoverené |
| ships | Lode | ks | Neoverené |
| aircraft | Lietadlá | ks | Neoverené |
| compute | Výpočtový výkon | GPU-h | Neoverené |
| ai_services | AI služby | licencia | Neoverené |

## Ďalšie vizuálne skupiny

Mestá a ich veľkosti; lesy a terén; rieky a pobrežie; hranice krajín; cesty, železnice a potrubia; prístavy, letiská a objekty v `data/places.json`; značky vlastníctva a ovládacie prvky. Ich presné pokrytie, geografické zdroje a modely ešte vyžadujú overenie.

## Kontroly a ďalší postup

Katalógy obsahujú 61 typov podnikov a 28 komodít. Pri kontrole všetkých ID a názvov neboli nájdené chýbajúce hodnoty ani duplicitné ID. Počet môže zmeniť budúca zmena katalógu; zoznam treba aktualizovať spolu s ňou.

Najprv vybrať reprezentatívnu oblasť s miestnymi dátami, overiť geografické zdroje riek a modely a vytvoriť hrateľný prototyp; potom dopĺňať overené podklady a ich licencie po skupinách. Úplná inventarizácia UI, sprav, 3D modelov a meranie GPU zatiaľ neboli dokončené.
