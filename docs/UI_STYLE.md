# Štýl A — Factorio-like

Tmavé kovové panely, oranžový akcent, ploché StyleBoxFlat bez textúr. Font je `res://assets/fonts/NotoSans-Regular.ttf`, veľkosť 16. Jediná téma je `ui/theme_factorio.tres`. Hex farby sú len v `scripts/ui/ui_palette.gd`. Čiary sa kreslia s vypnutým antialiasingom.

## Paleta

| Token | Hex | Použitie |
| --- | --- | --- |
| BG_0 | #16181B | pozadie okna |
| BG_1 | #202328 | panel |
| BG_2 | #2B2F35 | tlačidlo |
| BG_3 | #363B42 | hover a posuvník |
| BORDER | #4A5059 | obrys 1 px |
| BORDER_HI | #6B727D | horná hrana panelu, svetlejší obrys krajiny |
| ACCENT | #F08C1A | stlačené tlačidlo, výber, hlavičky |
| ACCENT_DIM | #B8660F | bežiaci výskum |
| TEXT | #E8E6E3 | bežný text |
| TEXT_DIM | #A9ADB3 | vypnutý text a kredit |
| TEXT_ON_ACCENT | #16181B | text na oranžovej |
| OK | #6FBF5A | kladná hotovosť |
| WARN | #E3B33C | varovanie |
| BAD | #E0524A | záporný stav; na paneli sa zosvetlí o 0.15 |
| WATER | #1B2836 | more |
| LAND_BORDER | #0D0F11 | obrys krajiny 2 px |
| GRATICULE | #223244 | mriežka 30° |

## Kontrast (WCAG)

Vypočítané relatívnou svietivosťou sRGB. Prah je 4.5:1.

| Text | Pozadie | Pomer |
| --- | --- | --- |
| TEXT #E8E6E3 | BG_1 #202328 | 12.65:1 |
| TEXT_DIM #A9ADB3 | BG_2 #2B2F35 | 5.97:1 |
| ACCENT #F08C1A | BG_1 #202328 | 6.36:1 |
| TEXT #E8E6E3 | BG_3 #363B42 | 9.06:1 |
| TEXT_ON_ACCENT #16181B | ACCENT #F08C1A | 7.18:1 |
| TEXT #E8E6E3 | BG_0 #16181B | 14.28:1 |
| TEXT #E8E6E3 | BG_2 #2B2F35 | 10.80:1 |
| OK #6FBF5A | BG_1 #202328 | 6.96:1 |
| BAD #E0524A zosvetlená o 0.15 | BG_1 #202328 | 4.99:1 |

Surová BAD na BG_1 má 4.11:1, preto hotovosť v mínuse používa `BAD.lightened(0.15)`.

## Pravidlá

- Okno má okraj 8 px. Mapa je v ľavom expand-fill stĺpci, zoznamy sú v scroll záložkách.
- Rýchlosti 1x / 4x / 10x volajú indexy 1 / 2 / 3. Simulácia ostáva 1.2 / 6 / 24 dní za sekundu. Krok 6b (presne 1.2 / 4.8 / 12) je preskočený.
- Mierka UI 1.0 / 1.25 / 1.5 ide do `user://settings.cfg`, nie do savu hry.
- Mapa nekreslí terén, hranicu ani mestskú textúru. Ikony firiem ostávajú.

## Matica rozlíšenie × mierka

Meranie 2026-10-24, skript volá `_build_play` a pri každej mierke čaká na layout. Bunka je OK len keď `map_ok`, `top_ok` aj `credit_ok` sú true: výška mapy > 0 a ≤ výška viewportu, prvý text top baru na x ≥ 8, kredit končí vnútri viewportu.

| | 1.0 | 1.25 | 1.5 |
| --- | --- | --- | --- |
| 1280×720 | OK | OK | OK |
| 1920×1080 | OK | OK | OK |
| 1920×1200 | OK | OK | OK |
| 1280×800 | OK | OK | OK |

1280×720, okno 1280×720: mapa 856×574 / 600×430 / 429×334, viewport 1280×720 / 1024×576 / 853×480, topx=16, kredit končí na 1264 / 1008 / 837.
1920×1080, okno 1920×1080: rovnaké logické veľkosti, lebo pomer 16:9 sedí s base 1280×720 a plátno sa len natiahne. Mapa ostáva v rámiku.
1920×1200 sa na monitore otvorilo ako klient 1920×1175. Viewport 1280×783 / 1024×626 / 853×522, mapa 856×637 / 600×480 / 429×376. Všetky tri bunky OK.
1280×800, okno 1280×800: mapa 856×654 / 600×494 / 429×387, viewport 1280×800 / 1024×640 / 853×533, topx=16, kredit končí na 1264 / 1008 / 837. Všetky tri bunky OK.

Pri každej bunke: 0 TextureRect, téma `res://ui/theme_factorio.tres`, 26 krajín, 4 skupiny, prvá rozbalená, `ocel` nájde Oceliareň, rýchlosti 1x/4x/10x a 1,2 / 6 / 24 dní/s.

`world_map._process` nevolá `queue_redraw` každý snímok. Kreslí len po zmene veľkosti, po zoome, ťahaní, zmene hoveru, kliku a pri animácii ikon najviac 10-krát za sekundu. Bez animovanej ikony `_process` skončí skôr.

FPS na AMD iGPU: NEOVERENE.
