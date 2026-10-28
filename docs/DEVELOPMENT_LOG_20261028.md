# Denník pokračovania Projekt-47

Model: Codex (GPT-6; presný variant runtime nie je sprístupnený).
Vetva: `codex/atlas-completion-20261027`.

## Overenie odovzdania

Na GitHube existujú oba deklarované commity: `08381a7` (vizuálny scenár) a `975ddfc` (kamera). Nová vetva vychádza z `975ddfc`, nad 11 auditovými commitmi. `main` zostáva bez zmeny. Existuje deväť regresných kontrol kamery a osem screenshotov pred/po. Ostatné štyri požadované funkcie v tomto základe chýbajú.

Záloha ani Google Drive sa nepoužívajú. Save v3 a UI ikony zachovávame. Animácie používajú existujúce `used_prev/cap`; smer toku simulácia nezaznamenáva, preto vizuál neurčuje skutočný smer dodávok.

## Železnice — Codex (GPT-6)

Samostatná vrstva vykresľuje najviac štyri vlaky na viditeľnú trať pri 10 Hz. Hustota a frekvencia rastú s existujúcim vyťažením, náklad vo vagónoch sa plní po dĺžke interiéru. Pri nulovom toku nejazdí vlak; pod zoomom 4 a v nízkej grafike sú animácie vypnuté. Oba smery sú vizuálne, smer dodávok nie je v dátach. Podvaly a spojky sa počítajú len pre orezaný viditeľný úsek a majú pevný limit. Statický Atlas sa kvôli pohybu vlakov neprekresľuje.

## Potrubia — Codex (GPT-6)

Pulzy zobrazujú existujúce zaťaženie potrubia: intenzita, hustota a rýchlosť rastú, preťaženie je červené. Najviac 24 značiek na viditeľnú líniu. Ide o agregovaný prietok, nie o potvrdený smer konkrétnej komodity. Ekonomika, kapacita a save zostali bez zmeny.

## Voliteľná pravá ruka — Codex (GPT-6)

Základný manažment nakupuje 100 % dostupných potrebných vstupov, udržiava cieľový počet pracovníkov a nemá automatickú 20 % penalizáciu výkonu. Najatý manažér stále poberá pôvodnú mzdu a má pôvodný bonus spokojnosti; výkon je najmenej na úrovni základu (pôvodný vzorec sa orezáva zdola na 1). Existujúce mená, schopnosti a platy sa nemigrujú. Fluktuácia z nespokojnosti/kriminality zostáva zachovaná a základný manažment stav pri mesačnej uzávierke doplní. Je to jediná autorizovaná zmena balansu.

## Mapové modely — Codex (GPT-6)

62 pôvodných pixelových modelov pokrýva celý katalóg 61 odvetví a banku. Nemocnice/klinika majú kríž, školy školské krídla a vlajku/hodiny, univerzita stĺporadie, prístav mólo, loď a kontajnery, jadrová elektráreň chladiace veže. Výrobné prevádzky majú vybavenie svojho odvetvia. Generátor v `tools/generate_map_models.py` umožňuje reprodukciu. Modely sú samostatné PNG s nearest filtrovaním na Atlase; UI ikony sa nemenia. Textúry sa načítajú raz na typ, kreslenie modelu je jedno texture volanie.

## Regresné kontroly — Codex (GPT-6)

Pridaných 17 kontrol: limit/hustota vlakov, orezanie tratí, úplnosť modelov, plný nákup a personál bez manažéra, zachovanie v3 manažéra a prevádzka bez poľa manager, bonus aj po prepustení a plynulý zoom pri zmene rodičovského layoutu. Existujúce testy manažmentu sa prispôsobili výslovne požadovanej mechanike; žiadna kontrola nebola vymazaná. Spolu s deviatimi zdedenými testmi kamery je to 26 nových kontrol tejto mapovej úlohy.

## Náklad jednotlivých vagónov — Codex (GPT-6)

Po vizuálnej kontrole sa náklad rozdeľuje medzi vagóny: pri 50 % je prvý plný, druhý polovičný a tretí prázdny. Dve ďalšie regresné kontroly overujú túto vizuálnu požiadavku (spolu 28 kontrol vrátane kamery). Mení sa len prezentácia agregovaného vyťaženia.

## Obnovenie dôkazov kamery — Codex (GPT-6)

Pri dekódovaní zdedených PNG boli tri zo štyroch obrázkov `camera_*_before.png` poškodené. Namiesto použitia nečitateľných dôkazov sa scenár znovu vykreslil cez llvmpipe na pôvodnom kóde kamery `08381a7` v oddelenej dočasnej pracovnej kópii. Posun pred opravou: panel 662,31 px, resize 40 px; po oprave na aktuálnej vetve: oba 0 px. Pôvodné poškodené bajty zostávajú v histórii Git. Nové screenshoty sú dekódovateľné, páry sa vytvárajú reprodukovateľným skriptom. FPS sa neinterpretuje ako výkon používateľovho GPU.

## Kliknutie na vysoké modely — Codex (GPT-6)

Dodatočná kontrola odhalila, že pôvodné vyberanie používalo iba malý kruh okolo základne budovy. Strecha/chladiace veže nového modelu mohli byť mimo tohto kruhu. Výber teraz používa rovnaký obdĺžnik ako kreslenie a nepriehľadné pixely modelu; transparentné okraje nekradnú kliknutia. Prekrytie sa vyhodnotí v opačnom poradí kreslenia. Doplnené dve kontroly strechy a priehľadného rohu (spolu 30 mapových kontrol).
