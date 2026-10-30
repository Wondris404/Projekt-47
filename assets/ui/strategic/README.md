# Vlastná pixelová grafika strategického UI

Vytvorené pre Projekt-47, 30. 10. 2026. Všetky pixely pochádzajú z vlastného deterministického generátora `tools/ui/generate_strategic_chrome.py` (Python/Pillow). Žiadne súbory ani výrezy HOI4/modov neboli použité. Neudeľuje sa tým nová verejná licencia celého projektu; pôvod grafiky: `LicenseRef-Projekt47-Original`.

11 transparentných ikon 32 × 32: money (minca €), debt (červená minca/šípka dole), influence (rečnícky pult), popularity (srdce), states (vlajka), employees (ľudia), clock, pause, speed_1x, speed_4x, speed_10x.

`metric_frame.png` (32 × 32) a `panel_frame.png` (64 × 64) sú vlastné kovové 9-slice rámy. `StyleBoxTexture` používa okraj 8 px; stred obsahuje jemný gradient a deterministickú textúru. Nenaťahuje sa celá pôvodná dlaždica `ui_chrome.png`. Ikony sa kreslia s nearest filtrom.

Bezpečnosť a firmy používajú pôvodné `assets/icons/pmc_unit.png` a `assets/icons/hq.png`. Všetkých 28 komoditných ikon v `assets/goods_icons/` zostalo bajtovo nezmenených. Uhlie, železná ruda a mäso majú odlišné podklady nového rámu, samotná ikona je pôvodná.
