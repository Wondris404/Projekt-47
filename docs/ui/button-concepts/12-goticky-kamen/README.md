# 12 — Gotický kameň

- **Inšpirácia:** Vápencový lomený oblúk, škáry muriva, náznak trojlístka.
- **Tvar:** lomený oblúk (nie obdĺžnik)
- **Ukážkový text:** Ciele
- **Rola:** záložka
- **Font:** Libre Baskerville, váha 700, 16 px
- **9-patch okraje** (ľavý, horný, pravý, dolný, px od okraja kresby tlačidla): oblúk sa neťahá ako 9-patch; okraj ornamentu 18 px
- **Umiestnenie v náhľade 320×72:** x 78–242, y 4–68
- **Najslabší kontrast v sade:** 6.61:1 (prah 4,5:1)
- **Pozadie náhľadu:** panel hry `#202328` (rovnaký ako `BG_1` v `docs/UI_STYLE.md`).

## HEX

| Token | Hex |
| --- | --- |
| vapenec | #D0CAC0 |
| skara | #5C564E |
| panel | #202328 |

## Stavy

Súbory: `normal.png`, `hover.png`, `pressed.png`, `disabled.png`, `focus.png`.
Hover len zosvetlí materiál. Press stmaví a posunie text o 1 px (layout tlačidla sa nemení).
Disabled je odsaturovaný, text ostáva čitateľný. Focus je mosadzný / materiálový prstenec, nie holý hover.

| Stav | Farba textu | Najhorší pomer v ploche glyfov |
| --- | --- | --- |
| normal | #24201C | 9.03:1 |
| hover | #24201C | 9.33:1 |
| pressed | #24201C | 6.61:1 |
| disabled | #24201C | 9.18:1 |
| focus | #24201C | 9.03:1 |
