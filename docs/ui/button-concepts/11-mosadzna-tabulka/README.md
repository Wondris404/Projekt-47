# 11 — Mosadzná tabuľka

- **Inšpirácia:** Rytá firemná tabuľka so skrutkami. Text je vrytý, nie nalepený.
- **Tvar:** obdĺžnik
- **Ukážkový text:** Terén
- **Rola:** sekundárne
- **Font:** EB Garamond, váha 650, 22 px
- **9-patch okraje** (ľavý, horný, pravý, dolný, px od okraja kresby tlačidla): 24, 16, 24, 16
- **Umiestnenie v náhľade 320×72:** x 8–312, y 8–64
- **Najslabší kontrast v sade:** 5.44:1 (prah 4,5:1)
- **Pozadie náhľadu:** panel hry `#202328` (rovnaký ako `BG_1` v `docs/UI_STYLE.md`).

## HEX

| Token | Hex |
| --- | --- |
| mosadz | #C69A48 |
| vryp | #301E0C |
| skrutka | #5C4424 |
| panel | #202328 |

## Stavy

Súbory: `normal.png`, `hover.png`, `pressed.png`, `disabled.png`, `focus.png`.
Hover len zosvetlí materiál. Press stmaví a posunie text o 1 px (layout tlačidla sa nemení).
Disabled je odsaturovaný, text ostáva čitateľný. Focus je mosadzný / materiálový prstenec, nie holý hover.

| Stav | Farba textu | Najhorší pomer v ploche glyfov |
| --- | --- | --- |
| normal | #3E240E | 7.29:1 |
| hover | #3E240E | 7.66:1 |
| pressed | #3E240E | 5.44:1 |
| disabled | #3E240E | 7.36:1 |
| focus | #3E240E | 7.29:1 |
