# Projekt-47

Lokálny ekonomický simulátor v Godot 4.7. Bez siete za behu. Spravil vývojár Wondris404.

## Spustenie

```
tools\godot\Godot_v4.7.2-stable_win64.exe --path C:\Users\ondre\Desktop\Projekt-47
```

Nová hra založí kaviareň a štartovací úver. Medzerník pauzuje, šípka vpravo posunie jeden deň. Klik na obdĺžnik vyberie krajinu.

Headless kontrola (má skončiť riadkom `P47_PROBE_OK`):

```
tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path C:\Users\ondre\Desktop\Projekt-47
```

## Dáta

`data/` drží komodity, recepty, krajiny a mapu. Aktuálne je to sada 26 krajín (ručne zadané odhady pre rok 2023, časť sú zástupné hodnoty). Skript `emit_boot_data.ps1` pozná len 16 krajín a bez `-Force` neprepíše už upravené dáta (`authored: true` alebo viac krajín v súbore). Plný sťahovač je `tools/build_world_data.py` (v tomto priečinku treba Python spustiť izolovane, inak spadne na prefixe).

Stav systémov: `docs/NOTES.md`.
