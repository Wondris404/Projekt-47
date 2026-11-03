# 14 — Eben a slonovina

- **Inšpirácia:** Ebenové drevo a vložka zo slonoviny, dva mosadzné nity. Cheat konzola, nie herné CTA.
- **Tvar:** obdĺžnik s vloženým panelom
- **Ukážkový text:** Konzola
- **Rola:** cheat konzola
- **Font:** Source Sans 3, váha 640, 16 px
- **9-patch okraje** (ľavý, horný, pravý, dolný, px od okraja kresby tlačidla): 28, 16, 28, 16
- **Umiestnenie v náhľade 320×72:** x 8–312, y 8–64
- **Najslabší kontrast v sade:** 9.86:1 (prah 4,5:1)
- **Pozadie náhľadu:** panel hry `#202328` (rovnaký ako `BG_1` v `docs/UI_STYLE.md`).

## HEX

| Token | Hex |
| --- | --- |
| eben | #16120E |
| slonovina | #ECE4D2 |
| mosadz | #B08C46 |
| panel | #202328 |

## Stavy

Súbory: `normal.png`, `hover.png`, `pressed.png`, `disabled.png`, `focus.png`.
Hover len zosvetlí materiál. Press stmaví a posunie text o 1 px (layout tlačidla sa nemení).
Disabled je odsaturovaný, text ostáva čitateľný. Focus je mosadzný / materiálový prstenec, nie holý hover.

| Stav | Farba textu | Najhorší pomer v ploche glyfov |
| --- | --- | --- |
| normal | #241C16 | 13.25:1 |
| hover | #241C16 | 13.48:1 |
| pressed | #241C16 | 9.86:1 |
| disabled | #241C16 | 13.33:1 |
| focus | #241C16 | 13.25:1 |
