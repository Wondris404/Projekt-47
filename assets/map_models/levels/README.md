# Pôvodné pixelové modely Atlasu

195 exteriérov: 61 druhov podnikov a 4 mapové objekty, každý v troch úrovniach.
Zdrojom je [generátor](../../../tools/atlas/generate_levels.py), nie Sketchfab,
generované obrázky z obrazového modelu ani skopírované textúry. Tvary sú zostavené
z explicitných geometrických dielov a rasterizované do jednotnej palety.

Autorstvo/pôvod: pôvodná procedurálna tvorba pre Projekt-47.
Označenie `LicenseRef-Projekt47-Original` v manifeste znamená vlastný projektový
obsah, nie CC-BY/CC0 dielo iného autora. Táto zmena neudeľuje novú verejnú licenciu
na projekt. Neobsahuje prevzaté modely, textúry, logá ani fonty; písmená PREDAJ
majú vlastnú jednoduchú pixelovú kresbu. Nie sú potrebné atribúcie Sketchfabu.

Generovanie: `python tools/atlas/generate_levels.py` (Python 3 a Pillow).
Každý typ má jednu spoločnú projekciu vypočítanú zo všetkých troch variantov.
Rozmery dielov, ich počet a výška sa pri upgrade menia; hotové obrázky sa
nepreškálovávajú na vytvorenie ďalšej úrovne. `manifest.json` zaznamenáva diely,
priestorové hranice, spoločnú projekciu a kontrolné súčty.

PNG: 64 × 72, priehľadné pozadie, spoločný kotviaci bod (32, 62), nearest filter.
Modely sa načítavajú do cache podľa typu a levelu; negenerujú sa počas hry.
Pôvodné jednourovňové PNG v nadradenom priečinku zostávajú ako záloha.

Banka, centrála, diaľnica a prístavný žeriav majú pripravené tri grafické varianty,
ale ich systémy nemajú `IndustrySystem.upgrade_firm`; v hre ostávajú na úrovni 1.
Úrovne 2–3 týchto štyroch objektov sú zatiaľ iba vizuálne podklady.
