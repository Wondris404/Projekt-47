# Atlas: porovnania pred a po

Vykreslené cez Xvfb, OpenGL Compatibility a Mesa llvmpipe. Ide o screenshoty skutočnej hry, nie headless dummy renderer. FPS nie je meranie výkonu Radeon GPU.

Kamera PRED: opätovne zachytená na `08381a7` (tri zdedené PNG boli poškodené). Doprava a modely PRED: `975ddfc`. PO: aktuálna pracovná vetva. Scenáre sú pozastavené, seed 47; nepoužívajú hráčske savy.

## Kamera a doprava

- [camera_panel_closed_pair](pairs/camera_panel_closed_pair.png)
- [camera_panel_open_pair](pairs/camera_panel_open_pair.png)
- [camera_panel_reopened_pair](pairs/camera_panel_reopened_pair.png)
- [camera_window_resize_pair](pairs/camera_window_resize_pair.png)
- [transport_distant_pair](pairs/transport_distant_pair.png)
- [transport_pipe_motion_pair](pairs/transport_pipe_motion_pair.png)
- [transport_pipe_pair](pairs/transport_pipe_pair.png)
- [transport_rail_motion_pair](pairs/transport_rail_motion_pair.png)
- [transport_rail_pair](pairs/transport_rail_pair.png)

## Všetky mapové budovy

Každá strana má najviac 12 odvetví v rovnakom poradí. UI ikona nad modelom ostala pôvodná. [Prehľad zdrojových pixelových modelov](model_sources_contact_sheet.png) je pomocný kontaktný list, nie screenshot hry.

| Strana | Odvetvia | Region | Detail | City |
|---|---|---|---|---|
| 1 | Kaviareň, Farma, Plantáž, Chov, Ropný vrt, Uhoľná baňa, Baňa na rudu, Medená baňa, Elektráreň, Oceliareň, Chemička, Laboratórium | [region](pairs/models_region_01_pair.png) | [detail](pairs/models_detail_01_pair.png) | [city](pairs/models_city_01_pair.png) |
| 2 | Textilka, Elektronika, Automobilka, Zbrojovka, Stavbár, Logistika, Finančná kancelária, Súkromná bezpečnosť, Obchodná kancelária, Reštaurácia, Pekáreň, Fitko | [region](pairs/models_region_02_pair.png) | [detail](pairs/models_detail_02_pair.png) | [city](pairs/models_city_02_pair.png) |
| 3 | Autoservis, E-shop, Realitka, Hotel, Supermarket, Logistika a sklady, Softvérová firma, Reklamná agentúra, Súkromná klinika, Výroba čipov, Letecká spoločnosť, Telekom | [region](pairs/models_region_03_pair.png) | [detail](pairs/models_detail_03_pair.png) | [city](pairs/models_city_03_pair.png) |
| 4 | Solárna elektráreň, Plynová elektráreň, Jadrová elektráreň, Lodenica, Poisťovňa, Investičný fond, Televízia, Sociálna sieť, Noviny, Kasíno, Offshore firma, Letisko | [region](pairs/models_region_04_pair.png) | [detail](pairs/models_detail_04_pair.png) | [city](pairs/models_city_04_pair.png) |
| 5 | Ropná rafinéria, Plynáreň, Burza / obchodník s cennými papiermi, Vrt na zemný plyn, Letecká továreň, Dátové centrum, AI firma, Súkromná nemocnica, Nákladný prístav, Súkromná základná škola, Súkromná stredná škola, Súkromná univerzita | [region](pairs/models_region_05_pair.png) | [detail](pairs/models_detail_05_pair.png) | [city](pairs/models_city_05_pair.png) |
| 6 | Firemná akadémia, Banka | [region](pairs/models_region_06_pair.png) | [detail](pairs/models_detail_06_pair.png) | [city](pairs/models_city_06_pair.png) |

## Čo vizuálne overiť na PC

- Panely otvoriť/zatvoriť opakovane, meniť veľkosť okna aj počas plynulého zoomu; stred pod kurzorom a kliknutie na budovu musia sedieť.
- Vlaky: 0 % = bez dopravy, 15/50/100/150 % = rastúca hustota/frekvencia. Pri 50 % má byť viditeľný plný, polovičný a prázdny vagón. Pod zoomom 4 sa animácie vypnú.
- Potrubia: tok nulový / nízky / plný / preťažený; červená označuje prekročenie kapacity. Pulzy neurčujú reálny smer dodávok, ktorý model dopravy neukladá.
- Čitateľnosť všetkých modelov pri troch zoomoch, tmavších podkladoch a na reálnom rozlíšení monitora. Zvlášť nemocnica/klinika, školy/univerzita, banka, prístav a jadrová elektráreň.
- Zapnúť reálny veľký save, rýchlosť 10× a detail mapy; profilovať CPU/GPU na používateľovom PC.
