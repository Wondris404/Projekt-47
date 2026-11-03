# 01 — Pergamen a mosadz

- **Inšpirácia:** Europa Universalis IV — zažltnutý pergamen, mosadzný rám, rohové diamanty. Nie krémová SaaS karta.
- **Tvar:** ostrý obdĺžnik
- **Ukážkový text:** Nová hra
- **Rola:** hlavné menu / primárne
- **Font:** EB Garamond, váha 640, 22 px
- **9-patch okraje** (ľavý, horný, pravý, dolný, px od okraja kresby tlačidla): 22, 14, 22, 14
- **Umiestnenie v náhľade 320×72:** x 8–312, y 6–66
- **Najslabší kontrast v sade:** 4.67:1 (prah 4,5:1)
- **Pozadie náhľadu:** panel hry `#202328` (rovnaký ako `BG_1` v `docs/UI_STYLE.md`).

## HEX

| Token | Hex |
| --- | --- |
| pergamen | #E4CE96 |
| mosadz | #A87A30 |
| atrament | #302010 |
| panel | #202328 |

## Stavy

Súbory: `normal.png`, `hover.png`, `pressed.png`, `disabled.png`, `focus.png`.
Hover len zosvetlí materiál. Press stmaví a posunie text o 1 px (layout tlačidla sa nemení).
Disabled je odsaturovaný, text ostáva čitateľný. Focus je mosadzný / materiálový prstenec, nie holý hover.

| Stav | Farba textu | Najhorší pomer v ploche glyfov |
| --- | --- | --- |
| normal | #302012 | 6.44:1 |
| hover | #302012 | 6.85:1 |
| pressed | #302012 | 4.67:1 |
| disabled | #302012 | 6.52:1 |
| focus | #302012 | 6.44:1 |
