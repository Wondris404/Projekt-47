# Alternatívne UI dizajny (D01–D30)

Kostra: `scripts/autoload/DesignManager.gd`, priečinky `themes/dNN/`, prepínač v Nastaveniach (hlavné menu aj pauza).

- **Auto-discovery:** každý priečinok `res://themes/<id>/` s platným `design.json` a `theme.tres` je dizajn. Spoločné súbory sa nemenia.
- **`current`** = súčasný dizajn (`ui/theme_factorio.tres`). Je predvolený a správa sa presne ako doteraz.
- **Uloženie:** `user://settings.cfg`, `[ui] design="dNN"`. Je to nastavenie hry, nie save hry, takže `SAVE_VERSION` ostáva 3.
- **Neplatný dizajn** (chýba priečinok, zlý JSON alebo chýba `theme.tres`) sa prepne na `current`.

## Pridanie dizajnu (3 kroky)

1. **Skopíruj šablónu:** `cp -r themes/d01 themes/dNN` (vo vlastnom worktree a vetve).
2. **Uprav súbory v `themes/dNN/`:**
   - `design.json`: `name`, `palette`, `fonts`, `menu`, `motion`, `map`;
   - `theme.tres`: Godot Theme pokrývajúci aspoň kľúče z `ui/theme_factorio.tres`;
   - `menu_bg.png` alebo `.tres`;
   - fonty do `themes/dNN/fonts/`;
   - `LICENSES.md`, `README.md`.
3. **Over a nafoť:**
   ```bash
   export XDG_DATA_HOME=/workspace/coding-p47/.userdata/<tvoj-wt>
   G=/workspace/coding-p47/tools/Godot_v4.7.2-stable_linux.x86_64
   $G --headless --path . --import              # .import pre nové .png/.ttf
   $G --headless --path . -- designs_unit        # musí byť rc=0, žiadny P47_UNIT_FAIL
   tools/design_shots.sh dNN                     # -> /workspace/coding-p47/designs/shots/dNN/{01_menu,02_mapa,03_burza}.png
   tools/design_collage.sh                       # -> /workspace/coding-p47/designs/shots/kolaz.png
   ```
   Commitni len `themes/dNN/` (vrátane `.import` k novým súborom). Screenshoty ostávajú v `designs/shots/dNN/`, mimo repa.

## Pravidlá

- **Meníš len `themes/dNN/`.** Spoločné súbory (`DesignManager.gd`, `main.gd`, `main_menu.gd`, `project.godot`, `CREDITS.md`, `docs/`) nemeníš. Ak niečo v kostre chýba, nahlás to Alt C. Vďaka tomu vetvy botov nemajú konflikty.
- **Fonty len OFL alebo CC0.** Súbor fontu daj do `themes/dNN/fonts/`, k nemu licenčný súbor (`OFL.txt` alebo `CC0.txt`) a riadok do `themes/dNN/LICENSES.md`. Zdieľané fonty z `assets/fonts/` (Noto, OFL) môžeš použiť bez kópie.
- **Pozadia len vlastné** (procedurálne, generované) **alebo CC0**, so zápisom v `LICENSES.md`. Nič s licenciou NC, ND alebo bez licencie.
- **Do hlavného `CREDITS.md` nepíšeš.** QA (Miguel) ho zlúči z `themes/*/LICENSES.md` pri merge.
- **Žiadne zmeny hernej logiky ani save formátu.** Dizajn je len vzhľad: Theme, paleta, fonty, pozadie menu, motion a tint mapy.
- Testy púšťaj vždy s vlastným `XDG_DATA_HOME`, lebo `user://` je zdieľaný.

## Čo dizajn ovplyvní (API)

| Kľúč v `design.json` | Efekt |
|---|---|
| `theme` (default `theme.tres`) | Theme celého UI (nastaví sa na `Main`, dedí ho menu, panely a okná) |
| `menu.background` | Textúra pozadia hlavného menu (cesta relatívne k `themes/dNN/`) |
| `menu.background_modulate`, `menu.shade` | Farba a stmavenie pozadia menu |
| `menu.logo_color`, `menu.logo_outline` | Farby titulku PROJEKT-47 |
| `menu.use_theme_buttons`, `menu.use_theme_panel` (default `true`) | Menu prevezme štýl tlačidiel a panelu z `theme.tres` namiesto natvrdo zadaného |
| `map.tint` | `self_modulate` vykresľovania mapy (`#ffffff` = bez zmeny) |
| `palette.*`, `motion.*`, `map.*` | Hodnoty pre nové UI prvky a animácie |

V kóde sa čítajú takto:

- `DesignManager.color("accent", UiPalette.ACCENT)`
- `DesignManager.motion("dur_normal", 0.2)`
- `DesignManager.map_value("hover", null)`
- `DesignManager.asset_path("x.png")`

Pre `current` vracajú vždy default volajúceho.

Signál `DesignManager.design_changed(id)` sa vyšle po prepnutí. Theme, menu a tint mapy sa prepnú hneď.

Na overenie možno vynútiť dizajn bez uloženia user argumentom `-- design=dNN` (používa ho `tools/design_shots.sh`).

**Obmedzenie kostry:** farby v kóde (`UiPalette`, `AtlasStyle`, `strategic_skin.gd`) a štýly nastavené natvrdo cez `add_theme_*_override` mimo hlavného menu Theme neprepíše. Takéto miesta sa napoja na `DesignManager.color()` v samostatnom commite kostry, nie vo vetvách dizajnov.
