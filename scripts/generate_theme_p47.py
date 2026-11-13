#!/usr/bin/env python3
"""Generator jednotnej UI temy Projekt-47 (p47/gfx) -> ui/theme_p47.tres.
Paleta je zhodna so scripts/ui/ui_palette.gd. Spustenie: python3 scripts/generate_theme_p47.py
Stara tema ui/theme_factorio.tres ostava v repe ako zaloha."""
import os

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "ui", "theme_p47.tres")

P = {  # paleta (hex) – drzat v sulade s UiPalette
    "BG_0": "0F1216", "BG_1": "171B21", "BG_2": "1F242C", "BG_3": "2A313B",
    "BORDER": "3A424E", "BORDER_HI": "5B6676", "ACCENT": "E8A33D", "ACCENT_HI": "F6C66B",
    "ACCENT_DIM": "9C6A22", "TEXT": "ECE8DF", "TEXT_DIM": "A7ADB6", "TEXT_ON_ACCENT": "14171C",
    "FIELD": "0D1014", "TOOLTIP_BG": "0B0D10",
}


def col(key, a=1.0):
    h = P.get(key, key)
    r, g, b = (int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    return "Color(%.4f, %.4f, %.4f, %.3g)" % (r, g, b, a)


subs = []   # (id, type, props)
exts = []   # (id, type, path)


def ext(kind, path):
    rid = "%d_p47" % (len(exts) + 1)
    exts.append((rid, kind, path))
    return 'ExtResource("%s")' % rid


def box(name, bg=None, bg_a=1.0, border=None, border_a=1.0, bw=(0, 0, 0, 0), r=6, m=(8, 4, 8, 4),
        shadow=0, shadow_a=0.35, shadow_off=(0, 2), draw_center=True, expand=None, flat_kind="StyleBoxFlat"):
    props = []
    props += ["content_margin_left = %.1f" % m[0], "content_margin_top = %.1f" % m[1],
              "content_margin_right = %.1f" % m[2], "content_margin_bottom = %.1f" % m[3]]
    if flat_kind == "StyleBoxEmpty":
        subs.append((name, flat_kind, props))
        return 'SubResource("%s")' % name
    if bg:
        props.append("bg_color = " + col(bg, bg_a))
    if not draw_center:
        props.append("draw_center = false")
    for side, w in zip(("left", "top", "right", "bottom"), bw):
        if w:
            props.append("border_width_%s = %d" % (side, w))
    if border:
        props.append("border_color = " + col(border, border_a))
    if isinstance(r, int):
        r = (r, r, r, r)
    for corner, v in zip(("top_left", "top_right", "bottom_right", "bottom_left"), r):
        if v:
            props.append("corner_radius_%s = %d" % (corner, v))
    if expand:
        for side, v in zip(("left", "top", "right", "bottom"), expand):
            if v:
                props.append("expand_margin_%s = %.1f" % (side, v))
    if shadow:
        props += ["shadow_color = Color(0, 0, 0, %.2f)" % shadow_a, "shadow_size = %d" % shadow,
                  "shadow_offset = Vector2(%d, %d)" % shadow_off]
    props.append("anti_aliasing = true")
    props.append("anti_aliasing_size = 0.8")
    subs.append((name, flat_kind, props))
    return 'SubResource("%s")' % name


def build():
    font = ext("FontFile", "res://assets/fonts/Inter-Regular.ttf")
    font_semi = ext("FontFile", "res://assets/fonts/Inter-SemiBold.ttf")
    oswald = ext("FontFile", "res://assets/fonts/Oswald-Variable.ttf")
    ic = {n: ext("Texture2D", "res://assets/ui/p47/%s.svg" % n) for n in (
        "check_off", "check_on", "radio_off", "radio_on", "toggle_off", "toggle_on",
        "grabber", "grabber_hi", "arrow_down")}
    # FontVariation pre nadpisy (Oswald SemiBold, mierne rozostupy)
    subs.append(("FontVariation_head", "FontVariation", [
        "base_font = " + oswald, 'variation_opentype = {2003265652: 600}', "spacing_glyph = 1"]))  # 2003265652 = tag 'wght'
    head_font = 'SubResource("FontVariation_head")'

    b_normal = box("btn_normal", "BG_2", 1, "BORDER", 1, (1, 1, 1, 1), 6, shadow=2, shadow_a=0.30, shadow_off=(0, 1))
    b_hover = box("btn_hover", "BG_3", 1, "ACCENT", 0.85, (1, 1, 1, 2), 6, shadow=4, shadow_a=0.35, shadow_off=(0, 2))
    b_pressed = box("btn_pressed", "ACCENT", 1, "ACCENT_HI", 1, (1, 1, 1, 1), 6)
    b_disabled = box("btn_disabled", "BG_2", 0.6, "BORDER", 0.6, (1, 1, 1, 1), 6)
    b_focus = box("btn_focus", None, 1, "ACCENT_HI", 0.9, (2, 2, 2, 2), 7, draw_center=False, expand=(1, 1, 1, 1))
    panel = box("panel", "BG_1", 0.96, "BORDER", 1, (1, 1, 1, 1), 8, m=(8, 8, 8, 8), shadow=10, shadow_a=0.45, shadow_off=(0, 4))
    panel_flat = box("panel_flat", "BG_1", 0.96, "BORDER", 0.8, (1, 1, 1, 1), 6, m=(6, 6, 6, 6))
    popup = box("popup", "BG_1", 0.98, "ACCENT_DIM", 1, (1, 1, 1, 1), 8, m=(6, 6, 6, 6), shadow=14, shadow_a=0.55, shadow_off=(0, 6))
    field = box("field", "FIELD", 1, "BORDER", 1, (1, 1, 1, 1), 5, m=(8, 4, 8, 4))
    field_focus = box("field_focus", "FIELD", 1, "ACCENT", 1, (1, 1, 1, 1), 5, m=(8, 4, 8, 4))
    tab_sel = box("tab_sel", "BG_1", 1, "ACCENT", 1, (0, 2, 0, 0), (6, 6, 0, 0), m=(12, 5, 12, 5))
    tab_unsel = box("tab_unsel", "BG_0", 1, "BORDER", 0.7, (0, 0, 0, 1), (6, 6, 0, 0), m=(12, 5, 12, 5))
    tab_hover = box("tab_hover", "BG_2", 1, "ACCENT", 0.5, (0, 1, 0, 0), (6, 6, 0, 0), m=(12, 5, 12, 5))
    tab_panel = box("tab_panel", "BG_1", 0.97, "BORDER", 0.9, (1, 0, 1, 1), (0, 8, 8, 8), m=(10, 10, 10, 10), shadow=8, shadow_a=0.4, shadow_off=(0, 3))
    tooltip = box("tooltip", "TOOLTIP_BG", 0.97, "ACCENT_DIM", 1, (1, 1, 1, 1), 6, m=(10, 6, 10, 6), shadow=8, shadow_a=0.5, shadow_off=(0, 3))
    sc_bg = box("scroll_bg", "BG_0", 0.55, None, 1, (0, 0, 0, 0), 4, m=(2, 2, 2, 2))
    sc_grab = box("scroll_grab", "BG_3", 1, None, 1, (0, 0, 0, 0), 4, m=(3, 3, 3, 3))
    sc_grab_hi = box("scroll_grab_hi", "ACCENT_DIM", 1, None, 1, (0, 0, 0, 0), 4, m=(3, 3, 3, 3))
    sc_grab_pr = box("scroll_grab_pr", "ACCENT", 1, None, 1, (0, 0, 0, 0), 4, m=(3, 3, 3, 3))
    item_sel = box("item_sel", "ACCENT", 0.22, "ACCENT", 0.8, (2, 0, 0, 0), 3, m=(4, 2, 4, 2))
    item_hover = box("item_hover", "BG_3", 0.8, None, 1, (0, 0, 0, 0), 3, m=(4, 2, 4, 2))
    pb_bg = box("pb_bg", "FIELD", 1, "BORDER", 1, (1, 1, 1, 1), 5, m=(0, 0, 0, 0))
    pb_fill = box("pb_fill", "ACCENT", 1, None, 1, (0, 0, 0, 0), 5, m=(0, 0, 0, 0))
    slider = box("slider", "FIELD", 1, "BORDER", 1, (1, 1, 1, 1), 3, m=(0, 3, 0, 3))
    slider_area = box("slider_area", "ACCENT_DIM", 1, None, 1, (0, 0, 0, 0), 3, m=(0, 3, 0, 3))
    slider_area_hi = box("slider_area_hi", "ACCENT", 1, None, 1, (0, 0, 0, 0), 3, m=(0, 3, 0, 3))
    sep = box("sep_line", "BORDER", 0.9, None, 1, (0, 0, 0, 0), 0, m=(0, 0, 0, 0))
    empty = box("empty", flat_kind="StyleBoxEmpty", m=(0, 0, 0, 0))
    head_band = box("head_band", "BG_2", 1, "ACCENT", 1, (3, 0, 0, 1), (6, 6, 0, 0), m=(10, 4, 8, 4))
    card = box("card", "BG_2", 0.95, "BORDER", 1, (3, 1, 1, 1), 8, m=(12, 9, 10, 9), shadow=6, shadow_a=0.35, shadow_off=(0, 2))
    menu_hover = box("menu_hover", "ACCENT", 0.2, None, 1, (0, 0, 0, 0), 4, m=(6, 3, 6, 3))

    t = col("TEXT")
    dim = col("TEXT_DIM")
    acc = col("ACCENT")
    acc_hi = col("ACCENT_HI")
    dark = col("TEXT_ON_ACCENT")
    props = [
        "default_font = " + font,
        "default_font_size = 15",
        # Button + OptionButton + MenuButton (rovnaky vzhlad)
    ]
    for ty in ("Button", "OptionButton", "MenuButton"):
        props += [
            "%s/colors/font_color = %s" % (ty, t),
            "%s/colors/font_hover_color = %s" % (ty, col("FFFFFF")),
            "%s/colors/font_pressed_color = %s" % (ty, dark),
            "%s/colors/font_hover_pressed_color = %s" % (ty, dark),
            "%s/colors/font_focus_color = %s" % (ty, t),
            "%s/colors/font_disabled_color = %s" % (ty, col("TEXT_DIM", 0.8)),
            "%s/colors/icon_normal_color = %s" % (ty, t),
            "%s/colors/icon_hover_color = %s" % (ty, acc_hi),
            "%s/colors/icon_pressed_color = %s" % (ty, dark),
            "%s/colors/icon_hover_pressed_color = %s" % (ty, dark),
            "%s/colors/icon_focus_color = %s" % (ty, acc),
            "%s/colors/icon_disabled_color = %s" % (ty, col("TEXT_DIM", 0.6)),
            "%s/constants/h_separation = 8" % ty,
            "%s/styles/normal = %s" % (ty, b_normal),
            "%s/styles/hover = %s" % (ty, b_hover),
            "%s/styles/pressed = %s" % (ty, b_pressed),
            "%s/styles/hover_pressed = %s" % (ty, b_pressed),
            "%s/styles/disabled = %s" % (ty, b_disabled),
            "%s/styles/focus = %s" % (ty, b_focus),
        ]
    props += [
        "OptionButton/icons/arrow = " + ic["arrow_down"],
        "OptionButton/constants/arrow_margin = 6",
        # CheckBox / CheckButton
        "CheckBox/icons/checked = " + ic["check_on"],
        "CheckBox/icons/unchecked = " + ic["check_off"],
        "CheckBox/icons/radio_checked = " + ic["radio_on"],
        "CheckBox/icons/radio_unchecked = " + ic["radio_off"],
        "CheckBox/colors/font_color = " + t,
        "CheckBox/colors/font_hover_color = " + col("FFFFFF"),
        "CheckBox/colors/font_pressed_color = " + acc_hi,
        "CheckBox/colors/font_hover_pressed_color = " + acc_hi,
        "CheckBox/styles/normal = " + empty,
        "CheckBox/styles/hover = " + menu_hover,
        "CheckBox/styles/pressed = " + empty,
        "CheckBox/styles/hover_pressed = " + menu_hover,
        "CheckButton/icons/checked = " + ic["toggle_on"],
        "CheckButton/icons/unchecked = " + ic["toggle_off"],
        "CheckButton/colors/font_color = " + t,
        "CheckButton/colors/font_hover_color = " + col("FFFFFF"),
        "CheckButton/colors/font_pressed_color = " + acc_hi,
        "CheckButton/colors/font_hover_pressed_color = " + acc_hi,
        "CheckButton/styles/normal = " + empty,
        "CheckButton/styles/hover = " + menu_hover,
        "CheckButton/styles/pressed = " + empty,
        "CheckButton/styles/hover_pressed = " + menu_hover,
        # texty
        "Label/colors/font_color = " + t,
        "Label/colors/font_shadow_color = Color(0, 0, 0, 0.35)",
        "Label/constants/shadow_offset_x = 0",
        "Label/constants/shadow_offset_y = 1",
        "HeaderLabel/base_type = &\"Label\"",
        "HeaderLabel/fonts/font = " + head_font,
        "HeaderLabel/font_sizes/font_size = 17",
        "HeaderLabel/colors/font_color = " + acc,
        "HeaderLabel/colors/font_outline_color = Color(0, 0, 0, 0.55)",
        "HeaderLabel/colors/font_shadow_color = Color(0, 0, 0, 0.5)",
        "HeaderLabel/constants/outline_size = 2",
        "HeaderLabel/constants/shadow_offset_y = 2",
        "HeaderLabel/styles/normal = " + head_band,  # kolo 2: sekcie panela ako hlavicky kariet
        "CardLabel/base_type = &\"Label\"",  # kolo 2: textove bloky panela ako karty
        "CardLabel/styles/normal = " + card,
        "CardLabel/colors/font_color = " + t,
        "CardLabel/font_sizes/font_size = 15",
        "CardLabel/constants/line_spacing = 3",
        "TitleLabel/base_type = &\"Label\"",
        "TitleLabel/fonts/font = " + head_font,
        "TitleLabel/font_sizes/font_size = 22",
        "TitleLabel/colors/font_color = " + acc_hi,
        "RichTextLabel/colors/default_color = " + t,
        "RichTextLabel/fonts/bold_font = " + font_semi,
        "RichTextLabel/styles/normal = " + empty,
        "LinkButton/colors/font_color = " + acc,
        "LinkButton/colors/font_hover_color = " + acc_hi,
        # polia
        "LineEdit/colors/font_color = " + t,
        "LineEdit/colors/font_placeholder_color = " + col("TEXT_DIM", 0.6),
        "LineEdit/colors/caret_color = " + acc_hi,
        "LineEdit/colors/selection_color = " + col("ACCENT", 0.35),
        "LineEdit/styles/normal = " + field,
        "LineEdit/styles/focus = " + field_focus,
        "LineEdit/styles/read_only = " + field,
        "TextEdit/colors/font_color = " + t,
        "TextEdit/styles/normal = " + field,
        "TextEdit/styles/focus = " + field_focus,
        "SpinBox/colors/font_color = " + t,
        "SpinBox/styles/normal = " + field,
        # kontajnery
        "BoxContainer/constants/separation = 6",
        "VBoxContainer/constants/separation = 6",
        "HBoxContainer/constants/separation = 6",
        "PanelContainer/styles/panel = " + panel,
        "Panel/styles/panel = " + panel_flat,
        "ScrollContainer/styles/panel = " + empty,
        "PopupPanel/styles/panel = " + popup,
        "PopupMenu/styles/panel = " + popup,
        "PopupMenu/styles/hover = " + menu_hover,
        "PopupMenu/colors/font_color = " + t,
        "PopupMenu/colors/font_hover_color = " + col("FFFFFF"),
        "PopupMenu/icons/checked = " + ic["check_on"],
        "PopupMenu/icons/unchecked = " + ic["check_off"],
        "PopupMenu/icons/radio_checked = " + ic["radio_on"],
        "PopupMenu/icons/radio_unchecked = " + ic["radio_off"],
        "AcceptDialog/styles/panel = " + popup,
        # zalozky
        "TabContainer/styles/tab_selected = " + tab_sel,
        "TabContainer/styles/tab_unselected = " + tab_unsel,
        "TabContainer/styles/tab_hovered = " + tab_hover,
        "TabContainer/styles/panel = " + tab_panel,
        "TabContainer/colors/font_selected_color = " + acc_hi,
        "TabContainer/colors/font_unselected_color = " + dim,
        "TabContainer/colors/font_hovered_color = " + t,
        "TabBar/styles/tab_selected = " + tab_sel,
        "TabBar/styles/tab_unselected = " + tab_unsel,
        "TabBar/styles/tab_hovered = " + tab_hover,
        "TabBar/colors/font_selected_color = " + acc_hi,
        "TabBar/colors/font_unselected_color = " + dim,
        "TabBar/colors/font_hovered_color = " + t,
        # zoznamy
        "ItemList/styles/panel = " + field,
        "ItemList/styles/focus = " + empty,
        "ItemList/styles/selected = " + item_sel,
        "ItemList/styles/selected_focus = " + item_sel,
        "ItemList/styles/hovered = " + item_hover,
        "ItemList/colors/font_color = " + t,
        "ItemList/colors/font_selected_color = " + acc_hi,
        "ItemList/colors/font_hovered_color = " + col("FFFFFF"),
        "ItemList/colors/guide_color = " + col("BORDER", 0.35),
        "Tree/styles/panel = " + field,
        "Tree/styles/selected = " + item_sel,
        "Tree/styles/selected_focus = " + item_sel,
        "Tree/colors/font_color = " + t,
        # progress, slidery, separatory
        "ProgressBar/styles/background = " + pb_bg,
        "ProgressBar/styles/fill = " + pb_fill,
        "ProgressBar/colors/font_color = " + t,
        "ProgressBar/colors/font_outline_color = Color(0, 0, 0, 0.8)",
        "ProgressBar/constants/outline_size = 2",
        "HSlider/styles/slider = " + slider,
        "HSlider/styles/grabber_area = " + slider_area,
        "HSlider/styles/grabber_area_highlight = " + slider_area_hi,
        "HSlider/icons/grabber = " + ic["grabber"],
        "HSlider/icons/grabber_highlight = " + ic["grabber_hi"],
        "VSlider/styles/slider = " + slider,
        "VSlider/styles/grabber_area = " + slider_area,
        "VSlider/styles/grabber_area_highlight = " + slider_area_hi,
        "VSlider/icons/grabber = " + ic["grabber"],
        "VSlider/icons/grabber_highlight = " + ic["grabber_hi"],
        "HSeparator/styles/separator = " + sep,
        "HSeparator/constants/separation = 9",
        "VSeparator/styles/separator = " + sep,
        # scrollbary (tenke, zaoblene)
    ]
    for ty in ("VScrollBar", "HScrollBar"):
        props += [
            "%s/styles/scroll = %s" % (ty, sc_bg),
            "%s/styles/scroll_focus = %s" % (ty, sc_bg),
            "%s/styles/grabber = %s" % (ty, sc_grab),
            "%s/styles/grabber_highlight = %s" % (ty, sc_grab_hi),
            "%s/styles/grabber_pressed = %s" % (ty, sc_grab_pr),
        ]
    props += [
        "TooltipPanel/styles/panel = " + tooltip,
        "TooltipLabel/colors/font_color = " + t,
        "TooltipLabel/font_sizes/font_size = 14",
    ]

    lines = ['[gd_resource type="Theme" load_steps=%d format=3]' % (len(exts) + len(subs) + 1), ""]
    for rid, kind, path in exts:
        lines.append('[ext_resource type="%s" path="%s" id="%s"]' % (kind, path, rid))
    lines.append("")
    for name, kind, pr in subs:
        lines.append('[sub_resource type="%s" id="%s"]' % (kind, name))
        lines += pr
        lines.append("")
    lines.append("[resource]")
    lines += props
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print("P47_THEME", OUT, len(subs), "styles", len(props), "props")


if __name__ == "__main__":
    build()
