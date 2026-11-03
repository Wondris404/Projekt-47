# 16 — Zamatová záložka

- **Inšpirácia:** Úzka zamatová záložka na hrane panela, zlatá hrana navrchu. Tvar tabu, nie lišta.
- **Tvar:** užší tab (spodok zarovnaný na linku)
- **Ukážkový text:** Mapa
- **Rola:** záložka
- **Font:** EB Garamond, váha 640, 20 px
- **9-patch okraje** (ľavý, horný, pravý, dolný, px od okraja kresby tlačidla): tab sa neťahá do šírky; vnútro 16, 14, 16, 12
- **Umiestnenie v náhľade 320×72:** x 70–250, y 16–66
- **Najslabší kontrast v sade:** 5.25:1 (prah 4,5:1)
- **Pozadie náhľadu:** panel hry `#202328` (rovnaký ako `BG_1` v `docs/UI_STYLE.md`).

## HEX

| Token | Hex |
| --- | --- |
| zamat | #6C1C2C |
| zlato | #D4AA5A |
| text | #FAECDC |
| panel | #202328 |

## Stavy

Súbory: `normal.png`, `hover.png`, `pressed.png`, `disabled.png`, `focus.png`.
Hover len zosvetlí materiál. Press stmaví a posunie text o 1 px (layout tlačidla sa nemení).
Disabled je odsaturovaný, text ostáva čitateľný. Focus je mosadzný / materiálový prstenec, nie holý hover.

| Stav | Farba textu | Najhorší pomer v ploche glyfov |
| --- | --- | --- |
| normal | #FAECDC | 6.41:1 |
| hover | #FAECDC | 5.25:1 |
| pressed | #FAECDC | 7.21:1 |
| disabled | #FAECDC | 7.28:1 |
| focus | #FAECDC | 6.41:1 |
