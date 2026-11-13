#!/usr/bin/env python3
"""Vlastne SVG ikony UI pre Projekt-47 (p47/gfx). Autor: Projekt-47, licencia CC0 1.0.
Spustenie: python3 scripts/generate_ui_icons_p47.py  -> assets/ui/p47/*.svg
Ikony su biele (#FFFFFF); farbu dava Theme (icon_*_color) alebo modulate."""
import os

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "ui", "p47")
W = '#FFFFFF'
GOLD = '#E8A33D'
STROKE = f'fill="none" stroke="{W}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"'


def svg(body, w=24, h=None):
    h = w if h is None else h
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
            f'viewBox="0 0 {w} {h}">{body}</svg>\n')


ICONS = {
    # menu / dialogy (24 px, linkove)
    "icon_play": svg(f'<path d="M8 5.5v13l10.5-6.5z" fill="{W}"/>'),
    "icon_new": svg(f'<circle cx="12" cy="12" r="8.5" {STROKE}/><path d="M12 8v8M8 12h8" {STROKE}/>'),
    "icon_load": svg(f'<path d="M3.5 7.5a2 2 0 0 1 2-2h4l2 2h7a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2h-13a2 2 0 0 1-2-2z" {STROKE}/>'),
    "icon_save": svg(f'<path d="M5 4h11l3 3v12a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1z" {STROKE}/><path d="M8 4v5h7V4M8 20v-6h8v6" {STROKE}/>'),
    "icon_settings": svg(f'<circle cx="12" cy="12" r="3" {STROKE}/><path d="M12 2.8v2.6M12 18.6v2.6M2.8 12h2.6M18.6 12h2.6M5.5 5.5l1.9 1.9M16.6 16.6l1.9 1.9M5.5 18.5l1.9-1.9M16.6 7.4l1.9-1.9" {STROKE}/><circle cx="12" cy="12" r="6.6" {STROKE}/>'),
    "icon_quit": svg(f'<path d="M12 3.5v8" {STROKE}/><path d="M7.2 6.6a7.5 7.5 0 1 0 9.6 0" {STROKE}/>'),
    "icon_back": svg(f'<path d="M14.5 6l-6 6 6 6" {STROKE}/>'),
    "icon_continue": svg(f'<path d="M5 5.5v13l8-6.5zM13 5.5v13l8-6.5z" fill="{W}"/>'),
    "icon_tutorial": svg(f'<circle cx="12" cy="12" r="8.5" {STROKE}/><path d="M9.6 9.4a2.5 2.5 0 1 1 3.4 2.3c-.7.3-1 .8-1 1.5v.6" {STROKE}/><circle cx="12" cy="16.8" r="1.1" fill="{W}"/>'),
    "icon_dev": svg(f'<path d="M8 7l-5 5 5 5M16 7l5 5-5 5M13.5 5l-3 14" {STROKE}/>'),
    # ovladacie prvky (18 px)
    "check_off": svg('<rect x="2" y="2" width="14" height="14" rx="3.5" fill="#0D1014" stroke="#5B6676" stroke-width="1.5"/>', 18),
    "check_on": svg(f'<rect x="2" y="2" width="14" height="14" rx="3.5" fill="{GOLD}"/><path d="M5.2 9.3l2.5 2.5 5-5.2" fill="none" stroke="#14171C" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>', 18),
    "radio_off": svg('<circle cx="9" cy="9" r="6.8" fill="#0D1014" stroke="#5B6676" stroke-width="1.5"/>', 18),
    "radio_on": svg(f'<circle cx="9" cy="9" r="6.8" fill="#0D1014" stroke="{GOLD}" stroke-width="1.5"/><circle cx="9" cy="9" r="3.6" fill="{GOLD}"/>', 18),
    "toggle_off": svg('<rect x="1" y="4" width="32" height="18" rx="9" fill="#0D1014" stroke="#5B6676" stroke-width="1.5"/><circle cx="10" cy="13" r="6" fill="#A7ADB6"/>', 34, 26),
    "toggle_on": svg(f'<rect x="1" y="4" width="32" height="18" rx="9" fill="{GOLD}"/><circle cx="24" cy="13" r="6" fill="#14171C"/>', 34, 26),
    "grabber": svg(f'<circle cx="8" cy="8" r="6" fill="#ECE8DF" stroke="#14171C" stroke-width="1.5"/>', 16),
    "grabber_hi": svg(f'<circle cx="8" cy="8" r="6.5" fill="{GOLD}" stroke="#14171C" stroke-width="1.5"/>', 16),
    "arrow_down": svg(f'<path d="M4 6.5l5 5 5-5" fill="none" stroke="{W}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>', 18),
    "spark": svg('<defs><radialGradient id="g"><stop offset="0" stop-color="#FFFFFF"/><stop offset=".35" stop-color="#FFE3A8" stop-opacity=".85"/><stop offset="1" stop-color="#E8A33D" stop-opacity="0"/></radialGradient></defs><circle cx="16" cy="16" r="16" fill="url(#g)"/>', 32),
}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, data in ICONS.items():
        with open(os.path.join(OUT, name + ".svg"), "w", encoding="utf-8") as f:
            f.write(data)
    print("P47_ICONS", len(ICONS))


if __name__ == "__main__":
    main()
