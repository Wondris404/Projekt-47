### REPORT M0 – 2026-10-24 14:53

0. ROZHODNUTIA ONDREJA, ako ich vidím: VOLBA_1_VIZUAL = ____ (NEVYPLNENÁ), VOLBA_2_KRAJINY = VSETKY, VOLBA_4_AI_SUPERI = ANO, VOLBA_3_TEMPLATES = ____ (NEVYPLNENÁ).

Priečinok: C:\Users\ondre\Desktop\Projekt-47 (nie záloha). PowerShell 5.1.26100.9711. pwsh na PC nie je. Godot 4.7.2.stable.official.ed1daf0bf. Obe binárky existujú: tools\godot\Godot_v4.7.2-stable_win64_console.exe a tools\godot\Godot_v4.7.2-stable_win64.exe. Checkpoint skript je tools\checkpoint.ps1.

PERF na tomto PC (PASS/FAIL):

| metrika | namerané | voči gate |
|---|---|---|
| run_all wall time | 432.801 s; po invariant parse 2348.389 s a 442.475 s | namerané; M0 nemá fail hranicu na wall time |
| FPS, ms/deň, RAM, VRAM, štart, save | nemerané | nedá sa označiť PASS |

1. Zhrnutie: Headless balík beží na tomto PC jedným príkazom a sedí s boxom štábu. Golden sa nemenil. M0 nie je DONE, kým nenapíšeš OK. M1 nezačínam. -- perf 365 a 10 min okno sú nespustené.

2. Zmeny (pilier: stabilita a determinizmus). Detail v docs\zmeny-2026-10-24\CHANGES-M0.md.

| súbor:riadky | čo | prečo | ID |
|---|---|---|---|
| tests\run_all.ps1:1-24 | Windows runner podľa A §5.3 | jeden príkaz na PS 5.1 | Q4 |
| tests\run_all.ps1:22 | inband_all cez InvariantCulture | sk-SK bodka nie je desatinná čiarka | Q4 |
| docs\PERF.md:1-34 | hardvér z CIM a wall time; zvyšok nemerané | kap. 10 | F2 |

3. Headless: PROBE OK, exit 0. P47_LIVE 1.4200 243375.3520 1 0.5887 0.0300 (zhoda s boxom). Unit 150 OK / 0 FAIL, exit 0. P47_STAB_CRIT day 365 inband_all 1.000 inband_SKDEUSBR 1.000 median_all 1.022, exit 0. Determinizmus OK (dva behy, 37 riadkov P47_, Compare-Object prázdny). Dva behy run_all.ps1 po invariant parse: oba import exit=0, OK golden, OK pasmo, VYSLEDOK fails=0, exit 0. Nové P47_* riadky hry nie sú. Golden zmenený? Nie. SHA256 tests\golden_probe.txt 225646A676F7A7A096ABBF779BD684FEE59479ACAF6240C8B85AE1222B838991 pred behmi aj po nich. Súbor má 37 riadkov P47_*, sonda 37. Text plánu píše 33. NaN/inf v hodnotách P47_* nie sú.

4. AK milníka:

| AK | stav | dôkaz |
|---|---|---|
| VYSLEDOK fails=0, exit 0 | splnené | dva behy po zmene parse, exit 0 |
| verzia PS zapísaná | splnené | 5.1.26100.9711 |
| golden bez regenerácie | splnené | hash nezmenený, Compare-Object prázdny |
| determinizmus | splnené | probeA/probeB, 37/37, OK |
| P47_LIVE ako na boxe | splnené | rovnaký reťazec |
| console exe | splnené | Test-Path True |
| 33 riadkov v texte plánu | súbor má 37 | zhoda so súborom golden, nie s vetou „33“ |

5. Overené v okne: nič. M0 okno nespúšťa. NEOVERENÉ ostáva GUI, F5, screenshot, FPS, diakritika fontov, Windows rename pri save. Kontrola až v M1, po OK: editor tools\godot\Godot_v4.7.2-stable_win64.exe, F5, Output bez SCRIPT ERROR.

6. Výkon: run_all wall time 432.801 s (runner pred invariant parse), potom 2348.389 s a 442.475 s (rovnaký skript s InvariantCulture). Nie je to ms/deň. Box štábu mal 1 min 47 s na inom stroji. FPS, tick, RAM procesu a VRAM hry sú nemerané. Hardvér prečítaný: LENOVO IdeaPad Flex 5 16ABR8 (Win32_ComputerSystem.Model 82XY), AMD Ryzen 7 7730U with Radeon Graphics, AMD Radeon (TM) Graphics, AdapterRAM z CIM 2147483648 (nie VRAM hry), TotalPhysicalMemory 14879617024 bajtov.

7. Bugy: nové žiadne, uzavreté žiadne. K1–K14 ostávajú vo svojich milníkoch.

8. Riziká a otázky:
1. Text plánu hovorí o 33 riadkoch P47_*, súbor golden aj sonda majú 37 a sú zhodné. Odporúčam brať súbor. Golden nemeníme.
2. --import hlási druhý project.godot v checkpoints\20261018-175520. Testy prešli. Checkpointy nemažem.
3. -- perf 365 a 10 min okno nie sú v M0. Kap. 10 ich dáva do M1/M2. Odporúčam merať ich až v M1.
4. VOLBA_1 a VOLBA_3 sú prázdne. M4b a export čakajú. M1 od nich nezávisí.
5. Prvý beh po zmene parse trval 2348.389 s, druhý 442.475 s. Príčinu rozdielu som nemeral. Nie je to fail hranica M0.

9. Checkpointy: prvý 20261024-134531 (files=115, robocopy=1), pred úpravou parse 20261024-140549 (files=132, robocopy=1), pred textom reportu 20261024-145351 (files=132, robocopy=1), snapshot s reportom 20261024-145436 (files=133, robocopy=1).

10. Ďalší milník je M1 (okno, AI firmy, minister, checkpoint slučka, F3). Čakám na OK. Bez neho M1 nezačínam.
