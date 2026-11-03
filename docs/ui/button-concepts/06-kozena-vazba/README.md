# 06 — Kožená väzba

- **Inšpirácia:** Viazačka kroniky: hnedá useň, zlaté linky, steh, rohové puncy.
- **Tvar:** obdĺžnik s mäkkou hranou
- **Ukážkový text:** Načítať hru
- **Rola:** sekundárne / menu
- **Font:** EB Garamond, váha 620, 20 px
- **9-patch okraje** (ľavý, horný, pravý, dolný, px od okraja kresby tlačidla): 20, 14, 20, 14
- **Umiestnenie v náhľade 320×72:** x 8–312, y 8–64
- **Najslabší kontrast v sade:** 4.83:1 (prah 4,5:1)
- **Pozadie náhľadu:** panel hry `#202328` (rovnaký ako `BG_1` v `docs/UI_STYLE.md`).

## HEX

| Token | Hex |
| --- | --- |
| usen | #6E4224 |
| zlato | #D4AA56 |
| steh | #E6CEA0 |
| text | #FAECD6 |
| panel | #202328 |

## Stavy

Súbory: `normal.png`, `hover.png`, `pressed.png`, `disabled.png`, `focus.png`.
Hover len zosvetlí materiál. Press stmaví a posunie text o 1 px (layout tlačidla sa nemení).
Disabled je odsaturovaný, text ostáva čitateľný. Focus je mosadzný / materiálový prstenec, nie holý hover.

| Stav | Farba textu | Najhorší pomer v ploche glyfov |
| --- | --- | --- |
| normal | #FAECD6 | 5.97:1 |
| hover | #FAECD6 | 4.83:1 |
| pressed | #FAECD6 | 6.11:1 |
| disabled | #FAECD6 | 6.59:1 |
| focus | #FAECD6 | 5.97:1 |
