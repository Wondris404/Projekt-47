# 09 — Iznik dlažba

- **Inšpirácia:** Osmanský obklad: tyrkys, terakota, slonovina v medailóne. Ornament len v ráme.
- **Tvar:** obdĺžnik s geometrickým bordúrou
- **Ukážkový text:** Obchod
- **Rola:** záložka / obchod
- **Font:** Cormorant Garamond, váha 600, 22 px
- **9-patch okraje** (ľavý, horný, pravý, dolný, px od okraja kresby tlačidla): 26, 18, 26, 18
- **Umiestnenie v náhľade 320×72:** x 8–312, y 7–65
- **Najslabší kontrast v sade:** 9.27:1 (prah 4,5:1)
- **Pozadie náhľadu:** panel hry `#202328` (rovnaký ako `BG_1` v `docs/UI_STYLE.md`).

## HEX

| Token | Hex |
| --- | --- |
| slonovina | #ECE2CE |
| tyrkys | #126866 |
| terakota | #963A2E |
| panel | #202328 |

## Stavy

Súbory: `normal.png`, `hover.png`, `pressed.png`, `disabled.png`, `focus.png`.
Hover len zosvetlí materiál. Press stmaví a posunie text o 1 px (layout tlačidla sa nemení).
Disabled je odsaturovaný, text ostáva čitateľný. Focus je mosadzný / materiálový prstenec, nie holý hover.

| Stav | Farba textu | Najhorší pomer v ploche glyfov |
| --- | --- | --- |
| normal | #162422 | 12.47:1 |
| hover | #162422 | 12.69:1 |
| pressed | #162422 | 9.27:1 |
| disabled | #162422 | 12.53:1 |
| focus | #162422 | 12.47:1 |
