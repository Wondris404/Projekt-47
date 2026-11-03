# 04 — Hviezdny lept

- **Inšpirácia:** Stellaris len ako technický lept: uhlie, mosadz a oxid. Žiadny neón, žiadny glow, žiadny fialový gradient.
- **Tvar:** obdĺžnik s rohovými konzolami
- **Ukážkový text:** Výskum
- **Rola:** primárne (výskum)
- **Font:** Source Sans 3, váha 620, 18 px
- **9-patch okraje** (ľavý, horný, pravý, dolný, px od okraja kresby tlačidla): 18, 12, 18, 12
- **Umiestnenie v náhľade 320×72:** x 14–306, y 10–62
- **Najslabší kontrast v sade:** 10.95:1 (prah 4,5:1)
- **Pozadie náhľadu:** panel hry `#202328` (rovnaký ako `BG_1` v `docs/UI_STYLE.md`).

## HEX

| Token | Hex |
| --- | --- |
| uhlie | #12161A |
| mosadz | #BAA470 |
| oxid | #76847E |
| text | #D6E0D8 |
| panel | #202328 |

## Stavy

Súbory: `normal.png`, `hover.png`, `pressed.png`, `disabled.png`, `focus.png`.
Hover len zosvetlí materiál. Press stmaví a posunie text o 1 px (layout tlačidla sa nemení).
Disabled je odsaturovaný, text ostáva čitateľný. Focus je mosadzný / materiálový prstenec, nie holý hover.

| Stav | Farba textu | Najhorší pomer v ploche glyfov |
| --- | --- | --- |
| normal | #D6E0D8 | 13.40:1 |
| hover | #D6E0D8 | 10.95:1 |
| pressed | #D6E0D8 | 13.79:1 |
| disabled | #D6E0D8 | 13.71:1 |
| focus | #D6E0D8 | 13.40:1 |
