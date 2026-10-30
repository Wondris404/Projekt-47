# Projekt-47

Projekt-47 je rozpracovaná ekonomická strategická hra od Wondris404. Hráč buduje a riadi podniky, obchoduje s komoditami a sleduje vývoj ekonomiky na svetovej mape. Hra používa Godot 4 a počas hrania nepotrebuje internet.

## Inštalácia a aktualizácia pre Windows

**Na prvú inštaláciu aj každú ďalšiu aktualizáciu stačí jeden rovnaký príkaz.** Ukončite hru, otvorte PowerShell a zadajte:

```powershell
& ([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/Wondris404/Projekt-47/main/tools/update-windows.ps1').Content))
```

Aktualizátor:

1. Vyhľadá štandardnú inštaláciu v `%LOCALAPPDATA%\Projekt-47\game` a staršie inštalácie `%LOCALAPPDATA%\Projekt-47\demo-<32 hex znakov>`. Ak nájde viacero, požiada o výber.
2. Zistí zaznamenanú verziu (`demo-...`). **Staré inštalácie nemajú verziový súbor:** vtedy oznámi „neznáma“, nepredstiera, že pozná pôvodnú verziu.
3. Overí najnovšie kompatibilné vydanie na [GitHub Releases](https://github.com/Wondris404/Projekt-47/releases) a opýta sa, či chcete pokračovať. Ak už máte tú istú alebo novšiu známu verziu, nič nemení.
4. Stiahne **celý** vydaný ZIP a overí jeho SHA-256 podľa `SHA256SUMS.txt`. Rozbalí výhradne očakávané súbory, vypíše nové/zmenené/nezmenené súbory a prepíše **iba tie, ktorých obsah sa líši**.
5. Pred výmenou vytvorí zálohu spravovaných súborov. Pri chybe obnoví pôvodný stav; po prerušení transakcie sa pri ďalšom spustení pokúsi o obnovu.
6. **Nemaže osobné súbory v inštalačnom priečinku, ani Godot `user://`**, kde sa nachádzajú uložené pozície. Aktualizáciu odmietne, ak je hra spustená.

V aktuálnom Windows balíku sú len `Projekt-47.exe` a `CITAJ-MA.txt`. Herné skripty a dáta sú zbalené vo vnútri EXE, preto sa pri zmene hry obyčajne vymení celý EXE; nejde o sťahovanie jednotlivých `.gd` súborov alebo binárnych rozdielov. Na kontrolu je potrebný internet a **nový GitHub Release**. Samotný commit na `main` nie je nová inštalovateľná verzia.

### Ak máte hru nainštalovanú inde

Spustite ten istý skript s explicitnou cestou. Príklad (nahraďte skutočným priečinkom s `Projekt-47.exe`):

```powershell
& ([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/Wondris404/Projekt-47/main/tools/update-windows.ps1').Content)) -InstallPath 'D:\Hry\Projekt-47'
```

Pri výbere **viacerých** starých inštalácií ich skript automaticky nezlučuje. Upraví len zvolený priečinok. Ak chcete znova overiť obsah aktuálneho vydania, môžete pridať `-Force`.

Starý príkaz `tools/install-windows.ps1` zostáva zachovaný kvôli spätnej kompatibilite, ale vytvára vždy **novú** inštaláciu. Pre bežných hráčov používajte nový príkaz vyššie.

> Ide o testovaciu verziu: pred aktualizáciou odporúčame zálohovať dôležité uložené pozície. Aktualizátor nemení ich súbory, no nový herný kód môže mať vlastné chyby alebo zmeny kompatibility save. PowerShell skripty spúšťajte len z dôveryhodného zdroja.

## Vývoj

Zdrojový projekt otvorte v Godot 4.7.2 cez `project.godot`. Dáta hry sú v `data/`, skripty v `scripts/`, testy v `tests/` a história zmien v `docs/WRAITH_DENNIK.md`. Požadované exportné šablóny nie sú súčasťou samotného zdrojového repozitára.

Windows aktualizátor: `tools/update-windows.ps1`; jeho izolované testy: `tools/tests/update-windows.tests.ps1`. Testy vytvárajú **fiktívne** ZIP balíky v dočasnom priečinku a spúšťajú sa na Windows GitHub Actions v `.github/workflows/windows-updater-tests.yml`. Nové verejné vydanie sa publikuje samostatne cez existujúci workflow `Windows demo package` (`workflow_dispatch`); obyčajný commit sám o sebe novú verziu hráčom neposkytne.
