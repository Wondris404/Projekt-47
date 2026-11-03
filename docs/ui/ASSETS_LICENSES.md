# Licencie UI assetov

Fáza 1 nepridáva nič do exportu hry. `export_presets.cfg` už má `exclude_filter="audit/*,docs/*"`. Priečinok `docs/ui` má `.gdignore`, aby Godot PNG a skripty z dokumentácie neimportoval.

## Fonty použité v návrhoch tlačidiel

Len mockupy v `docs/ui/button-concepts/_src/fonts/`. Do `assets/fonts/` sa nič nekopírovalo. Všetky sú SIL Open Font License 1.1, plné súbory (nie subset), slovenčina vrátane č ď ľ ň š ť ž ŕ ĺ ô ä je overená v náhľadoch.

| Font | Súbor | Licencia | Zdroj |
| --- | --- | --- | --- |
| EB Garamond | `EBGaramond.ttf` (variable) | OFL 1.1, `OFL-EBGaramond.txt` | [google/fonts ofl/ebgaramond](https://github.com/google/fonts/tree/main/ofl/ebgaramond) |
| Cormorant Garamond | `CormorantGaramond.ttf` | OFL 1.1, `OFL-CormorantGaramond.txt` | [google/fonts ofl/cormorantgaramond](https://github.com/google/fonts/tree/main/ofl/cormorantgaramond) |
| Libre Baskerville | `LibreBaskerville.ttf` | OFL 1.1, `OFL-LibreBaskerville.txt` | [google/fonts ofl/librebaskerville](https://github.com/google/fonts/tree/main/ofl/librebaskerville) |
| Source Sans 3 | `SourceSans3.ttf` | OFL 1.1, `OFL-SourceSans3.txt` | [google/fonts ofl/sourcesans3](https://github.com/google/fonts/tree/main/ofl/sourcesans3) |

Cinzel sa sťahoval a **nepoužil**. V latinke mu chýbajú ľ ň ť ď ŕ ĺ, takže nespĺňa podmienku diakritiky.

V hre už je `assets/fonts/NotoSans-Regular.ttf` a `NotoSerif-Variable.ttf` (OFL, `assets/fonts/OFL-NotoSerif.txt`). Fáza 1 ich nemení.

## Kresba tlačidiel

PNG v `docs/ui/button-concepts/` sú vygenerované skriptom `_src/render_concepts.py` (Pillow, numpy). Žiadna prevzatá textúra, logo ani asset Paradoxu. Licencia: vlastné dielo, rovnako ako zvyšok repozitára.

## Referenčné skilly (nie sú v builde)

`docs/ui/skills-reference/` — texty na čítanie, `.gdignore` + exclude `docs/*`.

| Balík | Licencia | Súbor |
| --- | --- | --- |
| frontend-design, canvas-design, theme-factory | Apache-2.0, Copyright 2026 Anthropic, PBC | `ANTHROPIC_SKILLS_LICENSE.txt` a `LICENSE.txt` v každom skille |
| godot-ui-theming, godot-ui-containers, godot-tweening | GNU LGPLv3 (verbatim kópia textu skillu; samotná hra sa tým nestáva LGPL, skripty sa neimportujú) | `GAMEDDEV_SKILLS_LICENSE.txt` |
| Fonty v `canvas-design/canvas-fonts/` | SIL OFL 1.1, vlastné `*-OFL.txt` vedľa TTF | len referencia canvas-design, v návrhoch sa nepoužili |

Upstream:

- https://github.com/anthropics/skills/tree/main/skills/frontend-design
- https://github.com/anthropics/skills/tree/main/skills/canvas-design
- https://github.com/anthropics/skills/tree/main/skills/theme-factory
- https://github.com/thedivergentai/Game-Dev-Agentic-Skills/tree/main/skills/godot-ui-theming
- https://github.com/thedivergentai/Game-Dev-Agentic-Skills/tree/main/skills/godot-ui-containers
- https://github.com/thedivergentai/Game-Dev-Agentic-Skills/tree/main/skills/godot-tweening
