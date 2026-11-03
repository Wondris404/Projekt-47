# 10 — Lak urushi

- **Inšpirácia:** Čierny japonský lak a zlaté maki-e obláčik vpravo. Matný, nie plastový lesk.
- **Tvar:** nízky obdĺžnik, motív asymetrický
- **Ukážkový text:** Burza
- **Rola:** primárne
- **Font:** Cormorant Garamond, váha 600, 26 px
- **9-patch okraje** (ľavý, horný, pravý, dolný, px od okraja kresby tlačidla): 16, 12, 48, 12
- **Umiestnenie v náhľade 320×72:** x 10–310, y 9–63
- **Najslabší kontrast v sade:** 10.90:1 (prah 4,5:1)
- **Pozadie náhľadu:** panel hry `#202328` (rovnaký ako `BG_1` v `docs/UI_STYLE.md`).

## HEX

| Token | Hex |
| --- | --- |
| lak | #100E0C |
| zlato | #D4A856 |
| text | #ECD6A0 |
| panel | #202328 |

## Stavy

Súbory: `normal.png`, `hover.png`, `pressed.png`, `disabled.png`, `focus.png`.
Hover len zosvetlí materiál. Press stmaví a posunie text o 1 px (layout tlačidla sa nemení).
Disabled je odsaturovaný, text ostáva čitateľný. Focus je mosadzný / materiálový prstenec, nie holý hover.

| Stav | Farba textu | Najhorší pomer v ploche glyfov |
| --- | --- | --- |
| normal | #ECD6A0 | 13.22:1 |
| hover | #ECD6A0 | 10.90:1 |
| pressed | #ECD6A0 | 13.46:1 |
| disabled | #ECD6A0 | 13.38:1 |
| focus | #ECD6A0 | 13.22:1 |
