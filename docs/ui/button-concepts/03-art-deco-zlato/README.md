# 03 — Art deco zlato

- **Inšpirácia:** Victoria 3 — tmavozelený lak, skosený zlatý schod, vejár nad textom.
- **Tvar:** osemuholník (skosené rohy)
- **Ukážkový text:** Potvrdiť
- **Rola:** potvrdiť
- **Font:** EB Garamond, váha 650, 22 px
- **9-patch okraje** (ľavý, horný, pravý, dolný, px od okraja kresby tlačidla): 20, 14, 20, 14
- **Umiestnenie v náhľade 320×72:** x 10–310, y 8–64
- **Najslabší kontrast v sade:** 10.88:1 (prah 4,5:1)
- **Pozadie náhľadu:** panel hry `#202328` (rovnaký ako `BG_1` v `docs/UI_STYLE.md`).

## HEX

| Token | Hex |
| --- | --- |
| lak | #102820 |
| zlato | #D6B05C |
| text | #F4E4BE |
| panel | #202328 |

## Stavy

Súbory: `normal.png`, `hover.png`, `pressed.png`, `disabled.png`, `focus.png`.
Hover len zosvetlí materiál. Press stmaví a posunie text o 1 px (layout tlačidla sa nemení).
Disabled je odsaturovaný, text ostáva čitateľný. Focus je mosadzný / materiálový prstenec, nie holý hover.

| Stav | Farba textu | Najhorší pomer v ploche glyfov |
| --- | --- | --- |
| normal | #F4E4BE | 13.49:1 |
| hover | #F4E4BE | 10.88:1 |
| pressed | #F4E4BE | 14.14:1 |
| disabled | #F4E4BE | 14.03:1 |
| focus | #F4E4BE | 13.49:1 |
