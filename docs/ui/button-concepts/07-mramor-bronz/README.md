# 07 — Mramor a bronz

- **Inšpirácia:** Chladný sivý mramor, bronzové nárožníky a jedna patina. Nie teplý krém.
- **Tvar:** obdĺžnik, ornament len v rohoch
- **Ukážkový text:** Nastavenia
- **Rola:** hlavné menu
- **Font:** Libre Baskerville, váha 700, 16 px
- **9-patch okraje** (ľavý, horný, pravý, dolný, px od okraja kresby tlačidla): 36, 16, 36, 16
- **Umiestnenie v náhľade 320×72:** x 8–312, y 7–65
- **Najslabší kontrast v sade:** 5.29:1 (prah 4,5:1)
- **Pozadie náhľadu:** panel hry `#202328` (rovnaký ako `BG_1` v `docs/UI_STYLE.md`).

## HEX

| Token | Hex |
| --- | --- |
| mramor | #C8C6C2 |
| zila | #687078 |
| bronz | #8A5A2E |
| patina | #4E685A |
| panel | #202328 |

## Stavy

Súbory: `normal.png`, `hover.png`, `pressed.png`, `disabled.png`, `focus.png`.
Hover len zosvetlí materiál. Press stmaví a posunie text o 1 px (layout tlačidla sa nemení).
Disabled je odsaturovaný, text ostáva čitateľný. Focus je mosadzný / materiálový prstenec, nie holý hover.

| Stav | Farba textu | Najhorší pomer v ploche glyfov |
| --- | --- | --- |
| normal | #201E1C | 7.16:1 |
| hover | #201E1C | 7.66:1 |
| pressed | #201E1C | 5.29:1 |
| disabled | #201E1C | 7.39:1 |
| focus | #201E1C | 7.16:1 |
