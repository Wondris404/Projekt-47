# 05 — Vosková pečať

- **Inšpirácia:** Listina s karmínovou stuhou a vtlačenou pečaťou. Potvrdzujúce, slávnostné.
- **Tvar:** stuha + kruhová pečať vľavo
- **Ukážkový text:** Potvrdiť
- **Rola:** potvrdiť
- **Font:** EB Garamond, váha 640, 20 px
- **9-patch okraje** (ľavý, horný, pravý, dolný, px od okraja kresby tlačidla): pečať sa neťahá; 9-patch len stuhy 18, 12, 16, 12
- **Umiestnenie v náhľade 320×72:** stuha x 86–304, y 18–54; pečať ø 54 vľavo
- **Najslabší kontrast v sade:** 8.27:1 (prah 4,5:1)
- **Pozadie náhľadu:** panel hry `#202328` (rovnaký ako `BG_1` v `docs/UI_STYLE.md`).

## HEX

| Token | Hex |
| --- | --- |
| vosk | #A83234 |
| stuha | #7A1820 |
| zlato | #D4AA5A |
| text | #FAECD6 |
| panel | #202328 |

## Stavy

Súbory: `normal.png`, `hover.png`, `pressed.png`, `disabled.png`, `focus.png`.
Hover len zosvetlí materiál. Press stmaví a posunie text o 1 px (layout tlačidla sa nemení).
Disabled je odsaturovaný, text ostáva čitateľný. Focus je mosadzný / materiálový prstenec, nie holý hover.

| Stav | Farba textu | Najhorší pomer v ploche glyfov |
| --- | --- | --- |
| normal | #FAECD6 | 9.98:1 |
| hover | #FAECD6 | 8.27:1 |
| pressed | #FAECD6 | 11.43:1 |
| disabled | #FAECD6 | 11.97:1 |
| focus | #FAECD6 | 9.98:1 |
