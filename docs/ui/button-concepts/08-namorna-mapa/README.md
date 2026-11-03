# 08 — Námorná mapa

- **Inšpirácia:** Admiralitná mapa: žltý papier, námornícka modrá linka, ružica kompasu.
- **Tvar:** obdĺžnik
- **Ukážkový text:** Lode
- **Rola:** záložka / mapa
- **Font:** EB Garamond, váha 640, 24 px
- **9-patch okraje** (ľavý, horný, pravý, dolný, px od okraja kresby tlačidla): 18, 12, 36, 12
- **Umiestnenie v náhľade 320×72:** x 8–312, y 7–65
- **Najslabší kontrast v sade:** 5.50:1 (prah 4,5:1)
- **Pozadie náhľadu:** panel hry `#202328` (rovnaký ako `BG_1` v `docs/UI_STYLE.md`).

## HEX

| Token | Hex |
| --- | --- |
| papier | #D6C8A0 |
| ink | #183052 |
| panel | #202328 |

## Stavy

Súbory: `normal.png`, `hover.png`, `pressed.png`, `disabled.png`, `focus.png`.
Hover len zosvetlí materiál. Press stmaví a posunie text o 1 px (layout tlačidla sa nemení).
Disabled je odsaturovaný, text ostáva čitateľný. Focus je mosadzný / materiálový prstenec, nie holý hover.

| Stav | Farba textu | Najhorší pomer v ploche glyfov |
| --- | --- | --- |
| normal | #142440 | 7.64:1 |
| hover | #142440 | 8.04:1 |
| pressed | #142440 | 5.50:1 |
| disabled | #142440 | 7.75:1 |
| focus | #142440 | 7.64:1 |
