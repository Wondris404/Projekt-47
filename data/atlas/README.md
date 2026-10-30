# Geografické obrysy zastavaných oblastí Atlasu

`urban_footprints.json` obsahuje triangulované obrysy **Natural Earth 1:10m urban areas** v rovnakej ekvidištančnej valcovej projekcii ako `WorldMap.project`. Zastavaná plocha sa nezväčšuje podľa populácie, herného servisného polomeru ani minimálneho počtu pixelov. Súvislé aglomerácie sú jeden geografický útvar, takže sa nevykresľujú opakovane pre každé mesto.

## Pôvod a licencia

- Natural Earth, autori projektu Tom Patterson, Nathaniel Vaughn Kelso a prispievatelia.
- [Popis dát](https://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-urban-area/).
- [Zdroj GeoJSON](https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_10m_urban_areas.geojson), stiahnutý 30. 10. 2026.
- SHA-256 vstupu: `5136ffd816a9b28c0f295e6797b4c03eaa421be80d78b90f542db4a932dd4497`.
- **Public domain**. [Podmienky](https://www.naturalearthdata.com/about/terms-of-use/): „All versions of Natural Earth raster + vector map data found on this website are in the public domain.“ Umožňujú úpravy aj elektronickú distribúciu. Nejde o aktíva HOI4 alebo Sketchfab.

Ide o generalizované zastavané oblasti, nie administratívne hranice miest ani presný stav roku 2026. Zdroj opisuje pôvod v satelitných dátach MODIS 2002–2003 s rozlíšením 1 km a odkazuje aj na neskoršie aktualizácie. Na strategickej mape poskytuje geografické rozmery namiesto zväčšených kruhov; nehodí sa na overovanie dnešných jednotlivých ulíc alebo parciel.

## Transformácia

`tools/atlas/build_urban_footprints.py` (Python + Shapely 2.2.0) zjednoduší obrysy s toleranciou 0,002° a zachovaním topológie. Obmedzená triangulácia zachováva aj diery. Žiadne transformácie veľkosti jednotlivých miest sa nepridávajú. Súradnice sa premietnu rovnakým vzorcom ako terén a rozdelia do 5° dávok na orezanie mimo obrazovky. Textúra blokov je vlastná dekorácia orezaná skutočným obrysom, nie zamerané ulice.

```bash
python tools/atlas/build_urban_footprints.py /tmp/ne_10m_urban_areas.geojson
```

Audit v `urban_footprints_audit.json`: 11 878 oblastí, zachovaných 228 dier, 569 dávok, 181 056 trojuholníkov. Zjednodušenie zachováva 99,893 % súčtu plôch v súradniciach zdroja; pri každej oblasti sa kontroluje zhoda plochy triangulácie s obrysom.

Príklady obálok súvislej aglomerácie (nie vyplneného obdĺžnika): Bratislava 22,26 × 21,02 km; Viedeň vrátane južného pásu predmestí 34,57 × 67,58 km; Paríž s predmestiami 101,60 × 76,99 km. Skutočná kresba sleduje nepravidelné polygóny aj voľné miesta vo vnútri.
