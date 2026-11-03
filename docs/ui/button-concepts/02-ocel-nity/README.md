# 02 — Oceľ a nity

- **Inšpirácia:** Hearts of Iron IV — kartáčovaná oceľ, nity, ľavý smaltovaný pruh. Tlačidlo nebezpečnej akcie.
- **Tvar:** obdĺžnik so skoseným bevelom
- **Ukážkový text:** Vyhlásiť vojnu
- **Rola:** nebezpečné
- **Font:** Source Sans 3, váha 650, 16 px
- **9-patch okraje** (ľavý, horný, pravý, dolný, px od okraja kresby tlačidla): 28, 16, 28, 16
- **Umiestnenie v náhľade 320×72:** x 8–312, y 8–64
- **Najslabší kontrast v sade:** 8.92:1 (prah 4,5:1)
- **Pozadie náhľadu:** panel hry `#202328` (rovnaký ako `BG_1` v `docs/UI_STYLE.md`).

## HEX

| Token | Hex |
| --- | --- |
| ocel | #4E565E |
| svetlo | #B0B8BE |
| smalt | #962820 |
| text | #F4F6F8 |
| panel | #202328 |

## Stavy

Súbory: `normal.png`, `hover.png`, `pressed.png`, `disabled.png`, `focus.png`.
Hover len zosvetlí materiál. Press stmaví a posunie text o 1 px (layout tlačidla sa nemení).
Disabled je odsaturovaný, text ostáva čitateľný. Focus je mosadzný / materiálový prstenec, nie holý hover.

| Stav | Farba textu | Najhorší pomer v ploche glyfov |
| --- | --- | --- |
| normal | #F4F6F8 | 11.27:1 |
| hover | #F4F6F8 | 8.92:1 |
| pressed | #F4F6F8 | 12.76:1 |
| disabled | #F4F6F8 | 11.87:1 |
| focus | #F4F6F8 | 11.27:1 |
