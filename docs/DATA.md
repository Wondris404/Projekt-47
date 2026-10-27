# Data

`DataLoader.load_all` reads `res://data/countries.json`, `commodities.json`, `recipes.json`, `industries.json`, `research.json`, `scenarios.json`, `map.json`, `wars.json`, `tension_seed.json`, and `supply_shares.json`. A clean boot leaves `DataLoader.errors` empty.

Countries are normalized with `id`, `population`, `gdp`, `gdp_per_capita`, `resources`, `infrastructure`, `risk`, `stability`, `trade_balance`, `inflation`, `unemployment`, and `tax_rate`.

Commodities include `arms`, `chemicals`, and `pmc_services` (plus the older set, more than 15). Recipes stay as dictionaries `{commodity: amount}`. `IndustrySystem.io_map` also accepts `{commodity, amount}` arrays.

`DataLoader.ingest_raw` turns invalid JSON into a proxy list and appends a line here. The headless probe no longer calls that path, so a green launch does not add another `invalid countries -> proxy` line. Boot of `res://data` leaves `DataLoader.errors` empty (`P47_LOADER 0`). `P47_LIVE` from that pair: holiday 1.4200, debt after the second month 243024.7752, bank_run 1, investment factor 0.2000, inflation bump 0.0300. The same pair prints `P47_IDS 3.1000 1.5500 2.6000` for `arms`, `chemicals`, and `pmc_services` on the Germany book the day after the war starts. Recipes `arms_plant`, `chem_plant`, and `pmc_unit` output or consume those ids.

Known gap: `data/countries.json` has 26 countries (hand-authored 2023-scale estimates, none flagged `fallback: true`; about 10 of them are still placeholder-quality), not a live World Bank or Natural Earth pull. `emit_boot_data.ps1` only knows 16 of them and now refuses to overwrite authored data without `-Force`. `wars.json` is an empty array. Map polygons are rectangles.

invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
invalid countries -> proxy
