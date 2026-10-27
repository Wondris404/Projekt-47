# Status

Early-access core is runnable in Godot 4.7.2 headless. The window has the map, cashflow, market prices, bank accounts, news, law, diplomacy, research buttons, a production slider, and a bond book.

## What works

- Monthly loans: cap from cashflow, credit score, and country stability. Rate is `base_rate + risk_premium`. Over-cap and underfunded requests do not add cash. A day inside the month does not charge the installment. Crossing into the next month does.
- `update_rates` raises `base_rate` when inflation is high or stability is low.
- `check_bankruptcy` after a missed payment drops credit score, closes a firm, and records a bankruptcy event.
- `create_bank` stores deposit rate, loan rate, and reserve ratio, takes an NPC deposit, lends to an AI book, and sets `bank_run` when liquidity is under the reserve ratio.
- Bonds and shares reduce cash and increase holdings.
- Higher policy rate lowers `investment_factor` inside facility throughput and raises finance demand through `capital_demand`.
- Commodity demand in the daily market uses population, income, time of day, weather, holiday, competition, and geopolitics.
- A missed monthly installment calls `check_bankruptcy` on the month path.
- The player bank tick uses `reserve_ratio` via `flag_liquidity`.
- Starting a war calls `apply_war_shock`, which cuts the trade balance and marks infrastructure damage.
- One `simulate_day` from 31 Dec 2024 writes those effects itself: holiday factor and the demand product on the market book, power-law price, finance `capital_add`, monthly installment, `bank_run` from `reserve_ratio`, war shock after the macro pass, and `last_invest` from `investment_factor`. A later month-boundary day with unpaid cash calls `check_bankruptcy`.
- Price law `base * (demand / supply) ^ elasticity`.
- War multipliers for arms, chemicals, and pmc_services. Infrastructure damage lowers the supply multiplier. A war shock raises inflation and cuts trade balance.
- Placement rejects an oil well in Slovakia and adds one cafe when it is paid for.
- One day advances the calendar. Holiday, storm, and recession each move a factor. AI `month_decision` can switch to invest.
- Save slot 9 restores cash, firm count, and the player bank deposit rate.
- Cashflow starts Logistika I and the other seven research projects from `research.json`. A production slider calls `set_production`. One finished research day sets `freight_mult` to 0.9. The bank panel shows deposits and the run withdrawal.
- Each country has five statutes in `data/laws.json` (tax, labor, banks, environment, arms). International law covers the UN Charter, the Geneva Conventions, GATT/WTO, Basel III, the Arms Trade Treaty, Security Council sanctions, the Vienna Convention on the Law of Treaties, and the TFEU for EU members. Corporate tax follows the statute. A bank reserve under the Basel floor is rejected. Arms export into an active war is refused. The Právo panel lists the rules for the selected country.
- Region hit test: the projected Bratislava point is SK, a point outside every outline is empty, and a point in Slovakia's box but outside the polygon is empty. Zoom flips `world` / `region`. Region view redraws that country's outline. Capitals use stored latitude and longitude. Roads, ports, energy sites, interior regions, and infrastructure damage are located records in `data/places.json`.
- The boot set has 26 countries. Records include population, GDP, inflation, unemployment, trade, and resources. They are not flagged `fallback: true`.

## Still missing

- Finer than 110m coastlines and a live World Bank refresh. The shipped outlines are the stored Natural Earth 110m countries plus 10m admin-1 regions.
- A downloaded World Bank refresh. `tools/build_world_data.py` keeps the authored files when `map.json` has `authored: true`, so a failed download does not replace them.
- Pixel-art animation, a tileset that builds the whole map, and sound.

## Known bugs

- `check_bankruptcy` seizes the open player firm with the highest build cost plus cash. It still takes only one firm per missed payment.
- While `bank_run` is set, each daily tick withdraws 4 % of deposits. The bank panel shows the deposit stock and the withdrawn total.
- Headless probe appends `invalid countries -> proxy` to `docs/DATA.md` on every run.
- Map zoom draws the selected outline. It is still a simplified polygon, not a full coastline.
