# PERF – Projekt-47

Merania na tomto PC. Číslo bez behu je **nemerané**. Značka NEOVERENÉ sa tu ruší len pri tom, čo príkaz reálne vrátil (24. 10. 2026).

## Hardvér (prečítané, nie odhad)

| Zdroj | Hodnota |
|---|---|
| Win32_ComputerSystem.Model | 82XY |
| Win32_ComputerSystemProduct.Version | IdeaPad Flex 5 16ABR8 |
| Win32_ComputerSystemProduct.Vendor | LENOVO |
| Win32_Processor.Name | AMD Ryzen 7 7730U with Radeon Graphics |
| Win32_VideoController.Name | AMD Radeon (TM) Graphics |
| Win32_VideoController.AdapterRAM | 2147483648 (hodnota z CIM; nie je to VRAM hry) |
| Win32_ComputerSystem.TotalPhysicalMemory | 14879617024 bajtov |

VRAM procesu, FPS a ms/deň sú naďalej nemerané.

## Tabuľka

| metrika | cieľ | fail | namerané | dátum | checkpoint |
|---|---|---|---|---|---|
| run_all wall time (celý beh, nie ms/deň) | box štábu 1 min 47 s (iný stroj, nie cieľ tohto PC) | v M0 nie je | 432.801 s (pred invariant parse); po InvariantCulture 2348.389 s a 442.475 s | 2026-10-24 | 20261024-134531 a 20261024-140549 |
| FPS 1080p pauza Medium | 60 | < 45 | nemerané | | |
| FPS max rýchlosť, 195 krajín + AI | ≥ 45 | < 30 | nemerané (svet je stále 26 krajín, AI súperi nie sú) | | |
| sim tick p50 / p95 | ≤ 8 ms / ≤ 16 ms | p95 > 33 ms | nemerané (`-- perf 365` v kóde nie je; M1/M2) | | |
| mesačný krok | ≤ 50 ms rozložené | hitch > 100 ms | nemerané | | |
| AI rozpočet | ≤ 4 ms/deň, ≤ 30 ms/mesiac | p95 2× | nemerané | | |
| RAM proces | ≤ 1 GB | > 2 GB | nemerané | | |
| VRAM | ≤ 512 MB | > 768 MB | nemerané | | |
| štart do menu / load | ≤ 5 s / ≤ 3 s | > 10 s / > 8 s | nemerané | | |
| save 195 krajín / čas zápisu | ≤ 2 MB / ≤ 300 ms | > 8 MB / > 1 s | nemerané | | |

Legacy26 budget z kap. 10 (FPS max ≥ 30 fail < 20, RAM ≤ 400 MB, save ≤ 300 KB) je tiež nemerané. Jediné číslo z tohto PC v M0 je wall time `run_all.ps1`.
