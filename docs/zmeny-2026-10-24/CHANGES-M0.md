# CHANGES-M0 (2026-10-24)

Checkpoint pred zmenou: `tools\checkpoint.ps1 -Once` → `20261024-134531` files=115 robocopy=1. Skript nie je v koreni (`.\checkpoint.ps1` chýba). `$root` = rodič `tools\`, `project.godot` existuje, fallback na plochu sa nepoužil.

1. tests\run_all.ps1:1-24 | nový Windows runner, text z A §5.3 bez zmeny logiky | headless balík jedným príkazom na PS 5.1 (pwsh na PC nie je) | Q4 | `powershell -NoProfile -ExecutionPolicy Bypass -File tests\run_all.ps1` → import exit=0, OK golden, unit OK=150 FAIL=0 exit=0, P47_STAB_CRIT day 365 inband_all 1.000, OK pasmo, VYSLEDOK fails=0, exit 0, wall 432.801 s
2. docs\PERF.md:1-34 | hardvér z CIM + wall time run_all; ostatné metriky nemerané | kap. 10 bod M0, značka NEOVERENÉ len pri prečítaných poliach | F2 | Get-CimInstance + Measure-Command
3. tests\run_all.ps1:22 | pásmo `inband_all` cez `[double]::Parse(..., InvariantCulture)` | sk-SK: `[double]'1.000'` je 1 (bodka = oddeľovač tisícov); kap. 5.3 povoľuje len túto úpravu | Q4 | dva behy po zmene, checkpoint 20261024-140549: oba exit 0, OK pasmo, VYSLEDOK fails=0; wall 2348.389 s a 442.475 s

Golden sa nemení. P47_LIVE na PC = `1.4200 243375.3520 1 0.5887 0.0300` (zhoda s boxom). Súbor golden má 37 riadkov P47_*, sonda 37, Compare-Object prázdny. Text plánu hovorí o 33 riadkoch; súbor a QA etapa 0 hovoria o 37. Diff voči súboru nie je.
