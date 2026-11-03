# 13 — Bankový šek

- **Inšpirácia:** Zelený bankový papier, giloš v bordúre, políčko meny.
- **Tvar:** obdĺžnik
- **Ukážkový text:** Pôžička
- **Rola:** potvrdiť / financie
- **Font:** EB Garamond, váha 640, 22 px
- **9-patch okraje** (ľavý, horný, pravý, dolný, px od okraja kresby tlačidla): 16, 12, 48, 12
- **Umiestnenie v náhľade 320×72:** x 8–312, y 8–64
- **Najslabší kontrast v sade:** 7.98:1 (prah 4,5:1)
- **Pozadie náhľadu:** panel hry `#202328` (rovnaký ako `BG_1` v `docs/UI_STYLE.md`).

## HEX

| Token | Hex |
| --- | --- |
| papier | #D6E4D0 |
| gilos | #245C40 |
| panel | #202328 |

## Stavy

Súbory: `normal.png`, `hover.png`, `pressed.png`, `disabled.png`, `focus.png`.
Hover len zosvetlí materiál. Press stmaví a posunie text o 1 px (layout tlačidla sa nemení).
Disabled je odsaturovaný, text ostáva čitateľný. Focus je mosadzný / materiálový prstenec, nie holý hover.

| Stav | Farba textu | Najhorší pomer v ploche glyfov |
| --- | --- | --- |
| normal | #183020 | 10.70:1 |
| hover | #183020 | 10.93:1 |
| pressed | #183020 | 7.98:1 |
| disabled | #183020 | 10.75:1 |
| focus | #183020 | 10.70:1 |
