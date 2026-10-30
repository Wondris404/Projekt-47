# Isolated Windows PowerShell integration tests. Uses fake release ZIPs: no real game,
# no network, no changes to the user's LOCALAPPDATA or Godot save directory.
$ErrorActionPreference = 'Stop'
$root = Join-Path ([IO.Path]::GetTempPath()) ('p47-updater-tests-' + [guid]::NewGuid().ToString('N'))
$oldLocal = $env:LOCALAPPDATA
$oldRoaming = $env:APPDATA
$oldFault = $env:P47_UPDATER_TEST_FAIL_AFTER
$updater = (Resolve-Path (Join-Path $PSScriptRoot '../update-windows.ps1')).Path
$passed = 0

function Assert-P47([bool]$condition, [string]$description) {
    if (-not $condition) { throw "FAILED: $description" }
    $script:passed++
    Write-Host "PASS: $description"
}
function Make-Package([string]$id, [string]$exeText, [string]$readmeText) {
    $folder = Join-Path $root ('release-' + $id)
    $payload = Join-Path $folder 'payload'
    New-Item -ItemType Directory -Path $payload -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $payload 'Projekt-47.exe') -Value $exeText -Encoding Ascii
    Set-Content -LiteralPath (Join-Path $payload 'CITAJ-MA.txt') -Value $readmeText -Encoding Ascii
    $archive = Join-Path $folder 'Projekt-47-Windows.zip'
    Compress-Archive -LiteralPath @((Join-Path $payload 'Projekt-47.exe'), (Join-Path $payload 'CITAJ-MA.txt')) -DestinationPath $archive
    $sums = Join-Path $folder 'SHA256SUMS.txt'
    $sha = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    Set-Content -LiteralPath $sums -Value "$sha  Projekt-47-Windows.zip" -Encoding Ascii
    return [pscustomobject]@{ zip = $archive; sum = $sums }
}
function Apply-Package([string]$folder, $package, [string]$tag, [bool]$force = $false) {
    & $updater -InstallPath $folder -ArchivePath $package.zip -ChecksumPath $package.sum -ReleaseTag $tag -Yes -Force:$force
}
function File-Text([string]$folder, [string]$name) {
    return (Get-Content -LiteralPath (Join-Path $folder $name) -Raw).Trim()
}
function Installed-Tag([string]$folder) {
    return [string]((Get-Content -LiteralPath (Join-Path $folder '.p47-install.json') -Raw | ConvertFrom-Json).tag)
}
function Must-Fail([scriptblock]$action, [string]$description) {
    $failed = $false
    try { & $action | Out-Null } catch { $failed = $true }
    Assert-P47 $failed $description
}

try {
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    $env:LOCALAPPDATA = Join-Path $root 'Local'
    $env:APPDATA = Join-Path $root 'Roaming'
    New-Item -ItemType Directory -Path $env:LOCALAPPDATA, $env:APPDATA -Force | Out-Null
    $game = Join-Path $env:LOCALAPPDATA 'Projekt-47/game'
    $save = Join-Path $env:APPDATA 'Godot/app_userdata/Projekt-47/saves/slot1.json'
    New-Item -ItemType Directory -Path (Split-Path $save) -Force | Out-Null
    Set-Content -LiteralPath $save -Value 'real-player-save' -Encoding Ascii
    $p1 = Make-Package '1' 'fake-exe-v1' 'same-instructions'
    $p2 = Make-Package '2' 'fake-exe-v2' 'same-instructions'
    $p3 = Make-Package '3' 'fake-exe-v3' 'new-instructions'
    $tag1 = 'demo-10000000001-1'
    $tag2 = 'demo-10000000002-1'
    $tag3 = 'demo-10000000003-1'

    # Fresh installation from local verified package.
    Apply-Package $game $p1 $tag1
    Assert-P47 (Test-Path -LiteralPath (Join-Path $game 'Projekt-47.exe') -PathType Leaf) 'fresh install creates game'
    Assert-P47 ((Installed-Tag $game) -eq $tag1) 'fresh install records release tag'
    Assert-P47 ((File-Text $game 'Projekt-47.exe') -eq 'fake-exe-v1') 'fresh install has verified payload'
    Assert-P47 ((File-Text (Split-Path $save) 'slot1.json') -eq 'real-player-save') 'fresh install preserves Godot save'

    # Incremental per-file replacement: only exe changes, installed readme remains untouched.
    Set-Content -LiteralPath (Join-Path $game 'player-notes.txt') -Value 'keep forever' -Encoding Ascii
    $readme = Join-Path $game 'CITAJ-MA.txt'
    (Get-Item -LiteralPath $readme).LastWriteTimeUtc = [datetime]'2020-01-01T00:00:00Z'
    $unchangedTime = (Get-Item -LiteralPath $readme).LastWriteTimeUtc
    Apply-Package $game $p2 $tag2
    Assert-P47 ((File-Text $game 'Projekt-47.exe') -eq 'fake-exe-v2') 'update replaces changed packaged exe'
    Assert-P47 ((Get-Item -LiteralPath $readme).LastWriteTimeUtc -eq $unchangedTime) 'update does not replace identical packaged readme'
    Assert-P47 ((File-Text $game 'player-notes.txt') -eq 'keep forever') 'update preserves unrelated local data'
    Assert-P47 ((File-Text (Split-Path $save) 'slot1.json') -eq 'real-player-save') 'update preserves Godot saves'
    Assert-P47 ((Installed-Tag $game) -eq $tag2) 'update records new version'

    # No update, no downgrade when current version already equals/exceeds release.
    Apply-Package $game $p2 $tag2
    Assert-P47 ((Installed-Tag $game) -eq $tag2) 'same release causes no update'
    Apply-Package $game $p1 $tag1
    Assert-P47 ((File-Text $game 'Projekt-47.exe') -eq 'fake-exe-v2') 'older release cannot downgrade installed version by default'

    # Incorrect SHA must be rejected before any packaged file changes.
    $wrongSum = Join-Path $root 'wrong-SHA256SUMS.txt'
    Set-Content -LiteralPath $wrongSum -Value ("$([string]::new('0',64))  Projekt-47-Windows.zip") -Encoding Ascii
    Must-Fail { & $updater -InstallPath $game -ArchivePath $p3.zip -ChecksumPath $wrongSum -ReleaseTag $tag3 -Yes } 'bad archive SHA is rejected'
    Assert-P47 ((File-Text $game 'Projekt-47.exe') -eq 'fake-exe-v2') 'bad SHA leaves original executable untouched'
    Assert-P47 (-not (Test-Path -LiteralPath (Join-Path $game '.p47-update'))) 'bad SHA cleans working directory'

    # Failure after the first file replacement must restore previous exe, readme and version.
    $env:P47_UPDATER_TEST_FAIL_AFTER = '1'
    Must-Fail { Apply-Package $game $p3 $tag3 } 'injected failure is detected'
    $env:P47_UPDATER_TEST_FAIL_AFTER = $null
    Assert-P47 ((File-Text $game 'Projekt-47.exe') -eq 'fake-exe-v2') 'failed update rolls back exe'
    Assert-P47 ((File-Text $game 'CITAJ-MA.txt') -eq 'same-instructions') 'failed update leaves original readme'
    Assert-P47 ((Installed-Tag $game) -eq $tag2) 'failed update preserves original version'
    Assert-P47 (-not (Test-Path -LiteralPath (Join-Path $game '.p47-update'))) 'successful rollback cleans recovery state'
    Assert-P47 ((File-Text (Split-Path $save) 'slot1.json') -eq 'real-player-save') 'rollback preserves saves'

    # A crash-recovery journal must be honored before doing any new work.
    $work = Join-Path $game '.p47-update'
    $backup = Join-Path $work 'backup'
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $work '.managed') -Value 'Projekt-47 updater v1' -Encoding Ascii
    foreach ($name in @('Projekt-47.exe', 'CITAJ-MA.txt', '.p47-install.json')) {
        Copy-Item -LiteralPath (Join-Path $game $name) -Destination (Join-Path $backup $name)
    }
    @{ schema = 1; existed = @{
        'Projekt-47.exe' = $true; 'CITAJ-MA.txt' = $true; '.p47-install.json' = $true
    }} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $work 'transaction.json') -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $game 'Projekt-47.exe') -Value 'interrupted-update' -Encoding Ascii
    Apply-Package $game $p2 $tag2
    Assert-P47 ((File-Text $game 'Projekt-47.exe') -eq 'fake-exe-v2') 'next invocation recovers interrupted transaction'
    Assert-P47 (-not (Test-Path -LiteralPath $work)) 'crash recovery removes transaction journal'

    # Several previous GUID installs require an explicit choice with -Yes, not accidental overwrite.
    $legacyRoot = Join-Path $env:LOCALAPPDATA 'Projekt-47'
    $legacyA = Join-Path $legacyRoot ('demo-' + ('a' * 32))
    $legacyB = Join-Path $legacyRoot ('demo-' + ('b' * 32))
    New-Item -ItemType Directory -Path $legacyA, $legacyB -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $legacyA 'Projekt-47.exe') -Value 'legacy-A' -Encoding Ascii
    Set-Content -LiteralPath (Join-Path $legacyB 'Projekt-47.exe') -Value 'legacy-B' -Encoding Ascii
    Must-Fail { & $updater -ArchivePath $p2.zip -ChecksumPath $p2.sum -ReleaseTag $tag2 -Yes } 'ambiguous legacy installs require explicit folder'
    Apply-Package $legacyA $p2 $tag2
    Assert-P47 ((File-Text $legacyA 'Projekt-47.exe') -eq 'fake-exe-v2') 'explicit legacy install updates in place'
    Assert-P47 ((File-Text $legacyB 'Projekt-47.exe') -eq 'legacy-B') 'other legacy installation is not modified'
    Assert-P47 ((File-Text (Split-Path $save) 'slot1.json') -eq 'real-player-save') 'legacy update preserves saves'

    # A running executable must block replacement even with -Force.
    if ($env:OS -eq 'Windows_NT') {
        $program = Join-Path $legacyB 'Projekt-47.exe'
        Copy-Item -LiteralPath (Join-Path $env:WINDIR 'System32/cmd.exe') -Destination $program -Force
        $proc = $null
        try {
            $proc = Start-Process -FilePath $program -ArgumentList '/c ping -n 30 127.0.0.1 >NUL' -PassThru -WindowStyle Hidden
            Start-Sleep -Seconds 1
            Assert-P47 (@(Get-Process -Name 'Projekt-47' -ErrorAction SilentlyContinue).Count -gt 0) 'running fixture started'
            Must-Fail { Apply-Package $legacyB $p2 $tag2 $true } 'running game blocks update'
        } finally {
            if ($proc -and -not $proc.HasExited) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
        }
    }
    Write-Host "P47_UPDATER_TESTS_OK checks=$passed"
} finally {
    $env:LOCALAPPDATA = $oldLocal
    $env:APPDATA = $oldRoaming
    $env:P47_UPDATER_TEST_FAIL_AFTER = $oldFault
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
}
