$ErrorActionPreference = 'Stop'
$installer = Join-Path $PSScriptRoot '..\tools\install-windows.ps1'
$root = Join-Path $PSScriptRoot ('..\audit\installer-test-' + [guid]::NewGuid().ToString('N'))
$source = Join-Path $root 'source'
New-Item -ItemType Directory -Path $source | Out-Null
Set-Content -LiteralPath (Join-Path $source 'Projekt-47.exe') -Value 'fake executable for installer test'
Set-Content -LiteralPath (Join-Path $source 'CITAJ-MA.txt') -Value 'test instructions'
$zip = Join-Path $root 'release.zip'
Compress-Archive -Path (Join-Path $source '*') -DestinationPath $zip
$sum = Join-Path $root 'SHA256SUMS.txt'
$hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath $sum -Value "$hash  Projekt-47-Windows.zip"
$destination = Join-Path $root 'installed'
& $installer -InstallPath $destination -ArchivePath $zip -ChecksumPath $sum
if ((Get-Content -LiteralPath (Join-Path $destination 'Projekt-47.exe') -Raw).Trim() -ne 'fake executable for installer test') { throw 'Extracted game differs.' }

$rejected = $false
try { & $installer -InstallPath $destination -ArchivePath $zip -ChecksumPath $sum } catch { $rejected = $true }
if (-not $rejected) { throw 'Existing destination must not be overwritten.' }

$badSum = Join-Path $root 'bad-sum.txt'
Set-Content -LiteralPath $badSum -Value (('0' * 64) + '  Projekt-47-Windows.zip')
$badDest = Join-Path $root 'bad-hash-destination'
$rejected = $false
try { & $installer -InstallPath $badDest -ArchivePath $zip -ChecksumPath $badSum } catch { $rejected = $true }
if (-not $rejected -or (Test-Path -LiteralPath $badDest)) { throw 'Invalid hash must fail without extracting.' }

$badSource = Join-Path $root 'bad-source'
New-Item -ItemType Directory -Path $badSource | Out-Null
Set-Content -LiteralPath (Join-Path $badSource 'unexpected.txt') -Value 'unexpected content'
$badZip = Join-Path $root 'bad.zip'
Compress-Archive -Path (Join-Path $badSource '*') -DestinationPath $badZip
$badZipSum = Join-Path $root 'bad-zip-sum.txt'
Set-Content -LiteralPath $badZipSum -Value (((Get-FileHash -LiteralPath $badZip -Algorithm SHA256).Hash) + '  Projekt-47-Windows.zip')
$badZipDest = Join-Path $root 'bad-zip-destination'
$rejected = $false
try { & $installer -InstallPath $badZipDest -ArchivePath $badZip -ChecksumPath $badZipSum } catch { $rejected = $true }
if (-not $rejected -or (Test-Path -LiteralPath $badZipDest)) { throw 'Unexpected content must fail without extracting.' }
Write-Host 'INSTALLER_TEST_OK: valid installation, existing target, checksum mismatch, invalid archive'

