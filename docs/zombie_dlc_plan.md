# Halloween DLC – plán krokov Z0–Z15 (+ Z11b)

Vetva `feat/halloween-dlc` (PR #20). Stojí na fázach A→F, mergovať až po #14–#19.
Stav: ✅ hotové · 🟡 hotové s obmedzením · ⬜ chýba.

## Ako je hra zložená
- Deň: `GameState.simulate_day` → `_finish_day` → `ZombieSystem.daily()`. Pri vypnutom DLC sa `daily()` hneď vráti, hra sa nemení.
- Save ostáva **v3**. `game_settings.zombie_mode`, `game_settings.zombie_start_money` a slovník `zombie` sú voliteľné; starý save ich nemá → DLC vypnuté (test `zombie_old_save`).
- Čísla sú v `data/zombie_balance.json`, logika v `scripts/autoload/ZombieSystem.gd`.
- Správy: fáza B, `GameState.post_news(text, "nákaza")` → panel **Noviny**, filter „nákaza“.
- Doprava: fáza C, `ShipSystem.air_traffic()` → kreslí `scripts/ui/atlas_traffic.gd` spolu s loďami.

## Kroky
| Krok | Čo | Kde | Stav |
|---|---|---|---|
| Z0 | Tento plán a mapa systémov | `docs/zombie_dlc_plan.md` | ✅ |
| Z1 | Odomknutie heslom na obrazovke Nová hra. V kóde je len SHA-256 hash, odomknutie v `user://settings.cfg`. Heslo nie je v README. Kto číta kód, vie to obísť. | `ZombieSystem.password_ok`, `main_menu.gd` | ✅ |
| Z2 | Výber štartovných peňazí 10 000 € – 1 000 000 000 €, uložené ako `zombie_start_money` | `main_menu.gd` (SpinBox), `main.gd` | ✅ |
| Z3 | Deň 7 správa o fiktívnej **United Wealth Corp.** (paródia), deň 8 vypuknutie v Krakove na 5 % | `_story`, `news_day`, `outbreak_day`, `outbreak_pct` | ✅ |
| Z4 | Model nákazy po mestách: rast, hustota, šírenie cestou/vlakom/prístavom/letecky, stav ohrozený/padol | `_grow_and_spread`, `_spread_from` | ✅ |
| Z5 | Mapová vrstva „Nákaza“ (Atlas aj Mapa: Pixelová), tooltip mesta a krajiny | `world_map.gd` | ✅ |
| Z6 | 3D zombíci: Quaternius Animated Zombie Pack (CC0) → `assets/models/zombies/zombie.glb`, na mape 1–5 modelov na región (render modelu) | `model_count`, `world_map.gd`, `CREDITS.md` | ✅ |
| Z7 | Evakuačné zóny: prístav, letisko, doprava hráča | `toggle_evac` | ✅ |
| Z8 | Helikoptéry: nákup, odvoz ľudí do safe zóny, strata nad padnutým regiónom | `buy_helicopter`, `_flights` | ✅ |
| Z9 | Safe zóny kreslené čiarami; len so zmluvou s vládou, vplyvom ≥ 50 % alebo vlastným štátom | `can_zone`, `add_draw_point`, `_close_zone` | ✅ |
| Z10 | Stavby v zóne: nemocnica, karanténa, sklady; zásoby jedla/liekov/paliva | `build_in_zone`, `_zones` | ✅ |
| Z11 | Múr (WWZ) presne 2 úrovne: 50 % a 90 %; stíhačky z tvojho letiska do 600 km od safe zóny, armáda | `wall_hold`, `airport_near`, `assign_army` | ✅ |
| Z11b | Animácie: stíhačky hliadkujú a útočia (záblesk, strely), helikoptéra sa pri nakladaní vznáša, havária (oheň a dym), pri oddialení ikony; modely CC0/CC-BY v `assets/models/aircraft/` | `ShipSystem.air_traffic`, `atlas_traffic._draw_air` | ✅ |
| Z12 | Ekonomika: zbrane, lieky, jedlo, palivo dražejú; PMC kontrakt má ~3× účinok armády | `_economy`, `has_pmc`, `pmc_effect` | ✅ |
| Z13 | Politika nakazených vo vlastnom štáte: vyhnať (helikoptéra, peniaze), zabiť (pokles reputácie + sankcie BR OSN), nechať | `set_policy` | ✅ |
| Z14 | Vakcína: vyvíja **len hráč alebo AI firma**. Zničené laboratórium (padnutý región) = výskum stratený. Bez vakcíny sa nákaza šíri ďalej. | `start_vaccine`, `_vaccine`, `_ai_pick_lab` | ✅ |
| Z15 | Koniec hry a štatistiky (výhra: vakcína alebo prežitie, prehra: padli všetky safe zóny); funguje aj z GitHub Release ZIP a zo zdrojákov, bez online servera | `_ending`, `_stats` | 🟡 ZIP sa stavia CI / ručne, pozri report |

## Testy
`tests/zombie_dlc.gd`: starý save bez DLC, šírenie z Krakova, správy v Noviny, vakcína len hráč/AI, strata výskumu AI laboratória.
