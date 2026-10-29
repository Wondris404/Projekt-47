# Projekt-47

Projekt-47 je rozpracovaná ekonomická strategická hra od Wondris404. Hráč buduje a riadi podniky, obchoduje s komoditami a sleduje vývoj ekonomiky na svetovej mape. Hra používa Godot 4 a počas hrania nepotrebuje internet.

## Inštalácia pre Windows

Po zverejnení testovacieho vydania otvorte **PowerShell** a zadajte jeden príkaz:

```powershell
& ([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/Wondris404/Projekt-47/main/tools/install-windows.ps1').Content))
```

Skript stiahne najnovší dostupný testovací balík z [GitHub Releases](https://github.com/Wondris404/Projekt-47/releases), overí kontrolný súčet SHA-256 a vypíše umiestnenie súboru `Projekt-47.exe`. Hru nainštaluje do nového priečinka v `%LOCALAPPDATA%\Projekt-47`; jestvujúce súbory neprepisuje. Pre stiahnutie je potrebné internetové pripojenie. Ak vydanie ešte neexistuje, skript oznámi, že balík zatiaľ nie je zverejnený.

Ide o vývojovú verziu: obsah a výkon sa ešte menia. Uložené hry si pred skúšaním nových zostavení zálohujte.

## Vývoj

Zdrojový projekt otvorte v Godot 4.7.2 cez `project.godot`. Dáta hry sú v `data/`, skripty v `scripts/`, testy v `tests/` a história zmien v `docs/WRAITH_DENNIK.md`. Požadované exportné šablóny nie sú súčasťou samotného zdrojového repozitára.

