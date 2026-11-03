# 18 — Nitovaný kríž

- **Inšpirácia:** Štvorcové zatváracie tlačidlo: oceľ, štyri nity, skosené X. Bez textu.
- **Tvar:** štvorec 56×56 uprostred platne
- **Ukážkový text:** ✕
- **Rola:** zatvoriť (X)
- **Font:** — (len znak X, kreslený)
- **9-patch okraje** (ľavý, horný, pravý, dolný, px od okraja kresby tlačidla): celý štvorec je ornament; neťahať, okraj 10 px
- **Umiestnenie v náhľade 320×72:** x 132–188, y 8–64
- **Najslabší kontrast v sade:** 9.73:1 (prah 4,5:1)
- **Pozadie náhľadu:** panel hry `#202328` (rovnaký ako `BG_1` v `docs/UI_STYLE.md`).

## HEX

| Token | Hex |
| --- | --- |
| ocel | #3A4046 |
| X | #ECE6DC |
| panel | #202328 |

## Stavy

Súbory: `normal.png`, `hover.png`, `pressed.png`, `disabled.png`, `focus.png`.
Hover len zosvetlí materiál. Press stmaví a posunie text o 1 px (layout tlačidla sa nemení).
Disabled je odsaturovaný, text ostáva čitateľný. Focus je mosadzný / materiálový prstenec, nie holý hover.

| Stav | Farba textu | Najhorší pomer v ploche glyfov |
| --- | --- | --- |
| normal | #ECE6DC | 12.26:1 |
| hover | #ECE6DC | 9.73:1 |
| pressed | #ECE6DC | 13.16:1 |
| disabled | #ECE6DC | 12.67:1 |
| focus | #ECE6DC | 12.26:1 |
