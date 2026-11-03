# 15 — Damašková oceľ

- **Inšpirácia:** Leptané damaskové vlny a tenký karmínový pruh. Nebezpečné, iné než nitovaná platňa.
- **Tvar:** obdĺžnik
- **Ukážkový text:** Predať
- **Rola:** nebezpečné
- **Font:** Source Sans 3, váha 680, 18 px
- **9-patch okraje** (ľavý, horný, pravý, dolný, px od okraja kresby tlačidla): 16, 14, 16, 18
- **Umiestnenie v náhľade 320×72:** x 8–312, y 8–64
- **Najslabší kontrast v sade:** 7.12:1 (prah 4,5:1)
- **Pozadie náhľadu:** panel hry `#202328` (rovnaký ako `BG_1` v `docs/UI_STYLE.md`).

## HEX

| Token | Hex |
| --- | --- |
| ocel | #6A7076 |
| vlna | #2A2E32 |
| smalt | #841E1C |
| text | #F4F4F6 |
| panel | #202328 |

## Stavy

Súbory: `normal.png`, `hover.png`, `pressed.png`, `disabled.png`, `focus.png`.
Hover len zosvetlí materiál. Press stmaví a posunie text o 1 px (layout tlačidla sa nemení).
Disabled je odsaturovaný, text ostáva čitateľný. Focus je mosadzný / materiálový prstenec, nie holý hover.

| Stav | Farba textu | Najhorší pomer v ploche glyfov |
| --- | --- | --- |
| normal | #F4F4F6 | 7.47:1 |
| hover | #F4F4F6 | 7.12:1 |
| pressed | #F4F4F6 | 9.17:1 |
| disabled | #F4F4F6 | 11.70:1 |
| focus | #F4F4F6 | 7.47:1 |
