# Launch status

Binary: `tools/godot/Godot_v4.7.2-stable_win64_console.exe`  
Command: `--headless --path C:\Users\ondre\Desktop\Projekt-47`  
Result on 18 Oct 2026: both runs **exit 0**, both logs contain `P47_PROBE_OK`, no `SCRIPT ERROR`, no `Parse Error`, no `P47_FAIL`. `P47_LIVE` is one `simulate_day` from 31 Dec 2024 into January. `P47_IDS` is the next day on the Germany book while that war is still on: geopolitics factors for `arms`, `chemicals`, and `pmc_services`.

Probe lines (identical on both runs):

```
P47_RECIPE 1.500000 0.600000
P47_COMMODITIES 22
P47_LAW 5 8 0.30
P47_PRICE_LAW 200.000000 400.000000
P47_REGION SK
P47_RATE 0.260000 0.021000
P47_CAP 250000.0000 0.071633
P47_MONTH_DEBT 246522.7661
P47_PLACE 1
P47_BANK_RUN 1 0
P47_LIVE 1.4200 243024.7752 1 0.2000 0.0300
P47_IDS 3.1000 1.5500 2.6000
P47_HOLDINGS 1 1
P47_SAVE ok
P47_WAR 3.1000 0.7500
P47_DATE 2024-03-02
P47_PLAY 0.9000 0.5000
P47_EVENT 1.4200 0.7200 0.0100
P47_AI invest
P47_ZOOM region world
P47_LOADER 0
P47_PROBE_OK
```

## Errors found and fixes

- Godot 4.7 rejected `:=` when the right-hand side is a Variant (`Cannot infer the type`). Replaced with `=`. Warnings are not errors in `project.godot`.
- Autoload order is now EconMath (helper), then DataLoader, GameState, TimeSystem, MarketSystem, BankingSystem, IndustrySystem, GeopoliticsSystem, AgentSystem, EventSystem, SaveSystem. GameState has no `_ready`, so it does not call later autoloads during boot.
- `class_name WorldMap` was not visible on the first parse of `main.gd`. The scene preloads `res://scripts/ui/world_map.gd` instead of a UID.
- `scenes/main.tscn` has no UID references. NotoSans is at `assets/fonts/NotoSans-Regular.ttf` and is loaded only in the windowed UI theme.
- Player bank dictionaries had `loan_rate` but ticks read `lending_rate` and threw a script error. `create_bank` now stores both, and ticks use `.get`.
- Daily loan annuity charged cash inside a month. Installments now run only in `process_monthly_interest()` when the date crosses a month.
- Missing art is a ColorRect panel plus the drawn map. There is no external tileset to fail.

Windowed GL was not used as the gate. Headless is the launch check.
