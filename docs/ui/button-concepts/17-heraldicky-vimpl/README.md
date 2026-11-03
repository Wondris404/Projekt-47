# 17 — Heraldický vimpel

- **Inšpirácia:** Lastovičí chvost, modrý smalt, zlatý chevrón. Vplyv / dynastia, nie CK3 asset.
- **Tvar:** vimpel (lastovičí chvost)
- **Ukážkový text:** Vplyv
- **Rola:** ikonové / vplyv
- **Font:** EB Garamond, váha 650, 20 px
- **9-patch okraje** (ľavý, horný, pravý, dolný, px od okraja kresby tlačidla): tvar sa neťahá; 9-patch nevhodný, kresliť ako celok
- **Umiestnenie v náhľade 320×72:** x 18–246, y 12–60
- **Najslabší kontrast v sade:** 7.91:1 (prah 4,5:1)
- **Pozadie náhľadu:** panel hry `#202328` (rovnaký ako `BG_1` v `docs/UI_STYLE.md`).

## HEX

| Token | Hex |
| --- | --- |
| smalt | #163070 |
| zlato | #D6B05C |
| text | #F4E4BE |
| panel | #202328 |

## Stavy

Súbory: `normal.png`, `hover.png`, `pressed.png`, `disabled.png`, `focus.png`.
Hover len zosvetlí materiál. Press stmaví a posunie text o 1 px (layout tlačidla sa nemení).
Disabled je odsaturovaný, text ostáva čitateľný. Focus je mosadzný / materiálový prstenec, nie holý hover.

| Stav | Farba textu | Najhorší pomer v ploche glyfov |
| --- | --- | --- |
| normal | #F4E4BE | 9.87:1 |
| hover | #F4E4BE | 7.91:1 |
| pressed | #F4E4BE | 11.00:1 |
| disabled | #F4E4BE | 10.90:1 |
| focus | #F4E4BE | 9.87:1 |
