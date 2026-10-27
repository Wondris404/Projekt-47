# Projekt-47: stav opráv k 23. 10. 2026 (Cedric)

Zmenený kód: etapa 0 (zapísaná) a etapa 1 (balík `etapa1-changed-files.tar.gz`, čaká na schválenie).
Bez práce nad etapou 1: žiadne ďalšie zmeny kódu ani rozrobené súbory.

## Overenie
- Headless Godot 4.7.2: `P47_LIVE` (0.5887 po etape 1), `P47_PROBE_OK`, unit 150 OK / 0 FAIL, stabilita bez NaN/inf.
- QA Miguel: GO (etapa 0 aj etapa 1 v2). Review štábu: GO, 0 blokerov.
- Čistý config, seed 47, 572 párov krajina × komodita: 0 mimo ±30 % po 1/3/6/12 rokoch.

## Známe obmedzenia a ďalší krok
- Stabilita je z veľkej časti daná konštrukciou modelu (obchodný uzáver, bez cenového driftu); reálny inflačný proces chýba (etapa 2, ~2–3 dni).
- Pri skriptovaných vojnách (až 9 súbežných) pásmo kleslo na 61–95 %; komodita `finance` je prechodne mimo pásma.
- Neoverené: okno/UI, Windows, PowerShell skript, iné seedy, výkon.
- Ďalej: etapa 2 (inflácia), potom UI scroll a tlačidlá save/load.
- Detail: `CHANGES-etapa0.md`, `CHANGES-etapa1.md`, `RESULT-etapa1.txt`, `QA-miguel-etapa1.md` (v `/workspace/projekt47/audit/`).
