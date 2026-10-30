# Interactive Windows installer/updater. Requires Windows PowerShell 5.1 or PowerShell 7.
# This changes only packaged game files in the selected install directory.
# Godot user:// saves and unrelated files are deliberately never touched.
param(
    [string]$InstallPath,
    [string]$ArchivePath,
    [string]$ChecksumPath,
    [string]$ReleaseTag,
    [switch]$Yes,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$gameFiles = @('Projekt-47.exe', 'CITAJ-MA.txt')
$metadataName = '.p47-install.json'
$workName = '.p47-update'
$headers = @{ 'User-Agent' = 'Projekt-47-updater'; 'Accept' = 'application/vnd.github+json' }

function Confirm-P47([string]$question) {
    if ($Yes) { return $true }
    $reply = Read-Host "$question [a/N]"
    return $reply -match '^(?i:a|ano|y|yes)$'
}

function Get-InstalledTag([string]$folder) {
    $path = Join-Path $folder $metadataName
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    try {
        $data = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        if ($data.schema -eq 1 -and $data.tag -match '^demo-[0-9]+-[0-9]+$') {
            return [string]$data.tag
        }
    } catch {
        Write-Warning 'Metadáta inštalácie sa nedajú prečítať; verzia je neznáma.'
    }
    return $null
}

function Restore-P47Transaction([string]$folder) {
    $work = Join-Path $folder $workName
    $journal = Join-Path $work 'transaction.json'
    if (-not (Test-Path -LiteralPath $journal -PathType Leaf)) { return }
    $tx = Get-Content -LiteralPath $journal -Raw | ConvertFrom-Json
    if ($tx.schema -ne 1) { throw 'Neznámy formát transakcie; obnova bola zastavená.' }
    foreach ($name in @($gameFiles) + @($metadataName)) {
        $wasPresent = $tx.existed.PSObject.Properties[$name]
        if ($null -eq $wasPresent -or $wasPresent.Value -isnot [bool]) {
            throw "Neúplný záznam obnovy: $name"
        }
        if ($wasPresent.Value -and -not (Test-Path -LiteralPath (Join-Path (Join-Path $work 'backup') $name) -PathType Leaf)) {
            throw "Chýba záloha $name; automatická obnova bola zastavená."
        }
    }
    foreach ($name in @($gameFiles) + @($metadataName)) {
        $dest = Join-Path $folder $name
        if ($tx.existed.PSObject.Properties[$name].Value) {
            Copy-Item -LiteralPath (Join-Path (Join-Path $work 'backup') $name) -Destination $dest -Force
        } elseif (Test-Path -LiteralPath $dest -PathType Leaf) {
            Remove-Item -LiteralPath $dest -Force
        }
    }
    Remove-Item -LiteralPath $work -Recurse -Force
    Write-Host 'Obnovená pôvodná inštalácia po prerušenej alebo neúspešnej aktualizácii.'
}

function Assert-P47Stopped {
    # Conservative: if any instance is running, do not risk replacing its executable.
    if (@(Get-Process -Name 'Projekt-47' -ErrorAction SilentlyContinue).Count -gt 0) {
        throw 'Projekt-47 je spustený. Uložte hru, ukončite ju a skúste aktualizáciu znova.'
    }
}

function Get-ReleaseInfo {
    if ([bool]$ArchivePath -ne [bool]$ChecksumPath) {
        throw 'Miestny archív a súbor SHA256SUMS.txt treba zadať spoločne.'
    }
    if ($ArchivePath) {
        if ($ReleaseTag -notmatch '^demo-[0-9]+-[0-9]+$') {
            throw 'Pri miestnom balíku zadajte -ReleaseTag demo-CISLO-CISLO.'
        }
        if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf) -or
            -not (Test-Path -LiteralPath $ChecksumPath -PathType Leaf)) {
            throw 'Archív alebo kontrolný súčet neexistuje.'
        }
        return [pscustomobject]@{
            tag = $ReleaseTag
            archive = $ArchivePath
            checksum = $ChecksumPath
            offline = $true
        }
    }
    if ($ReleaseTag) { throw '-ReleaseTag je určený len pre miestny archív.' }
    $releases = @(Invoke-RestMethod -Uri 'https://api.github.com/repos/Wondris404/Projekt-47/releases?per_page=100' -Headers $headers)
    $release = $releases | Where-Object {
        -not $_.draft -and $_.tag_name -match '^demo-[0-9]+-[0-9]+$' -and
        @($_.assets | Where-Object { $_.name -eq 'Projekt-47-Windows.zip' }).Count -eq 1 -and
        @($_.assets | Where-Object { $_.name -eq 'SHA256SUMS.txt' }).Count -eq 1
    } | Sort-Object -Property published_at -Descending | Select-Object -First 1
    if (-not $release) { throw 'Na GitHube zatiaľ nie je dostupné kompatibilné vydanie.' }
    $prefix = 'https://github.com/Wondris404/Projekt-47/releases/download/' + $release.tag_name + '/'
    $archiveUrl = ($release.assets | Where-Object { $_.name -eq 'Projekt-47-Windows.zip' }).browser_download_url
    $checksumUrl = ($release.assets | Where-Object { $_.name -eq 'SHA256SUMS.txt' }).browser_download_url
    if ($archiveUrl -cne ($prefix + 'Projekt-47-Windows.zip') -or
        $checksumUrl -cne ($prefix + 'SHA256SUMS.txt')) {
        throw 'Súbory vydania nie sú na očakávanej oficiálnej adrese.'
    }
    return [pscustomobject]@{
        tag = [string]$release.tag_name
        archive = $archiveUrl
        checksum = $checksumUrl
        offline = $false
    }
}

function Compare-DemoTags([string]$installed, [string]$available) {
    if ($installed -notmatch '^demo-([0-9]+)-([0-9]+)$' -or
        $available -notmatch '^demo-([0-9]+)-([0-9]+)$') { return -1 }
    $a = [regex]::Match($installed, '^demo-([0-9]+)-([0-9]+)$')
    $b = [regex]::Match($available, '^demo-([0-9]+)-([0-9]+)$')
    $firstA = [long]::Parse($a.Groups[1].Value)
    $firstB = [long]::Parse($b.Groups[1].Value)
    if ($firstA -lt $firstB) { return -1 }
    if ($firstA -gt $firstB) { return 1 }
    $secondA = [long]::Parse($a.Groups[2].Value)
    $secondB = [long]::Parse($b.Groups[2].Value)
    if ($secondA -lt $secondB) { return -1 }
    if ($secondA -gt $secondB) { return 1 }
    return 0
}

function Verify-And-Extract([string]$zipPath, [string]$sumPath, [string]$stage) {
    $sumText = Get-Content -LiteralPath $sumPath -Raw
    $hits = [regex]::Matches($sumText, '(?im)^([a-f0-9]{64})[ \t]+\*?Projekt-47-Windows\.zip[ \t]*\r?$')
    if ($hits.Count -ne 1) { throw 'SHA256SUMS.txt má neplatný formát.' }
    $actual = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash
    if ($actual -ine $hits[0].Groups[1].Value) {
        throw 'Nesprávny SHA-256: archív bol odmietnutý bez zmeny hry.'
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $zipPath).Path)
    try {
        $entries = @($archive.Entries)
        if ($entries.Count -ne 2 -or @($entries | Where-Object {
            $_.FullName -cnotin $gameFiles -or $_.Length -eq 0 -or $_.Length -gt 4294967296
        }).Count -gt 0) {
            throw 'Archív obsahuje nečakané súbory, prázdne súbory alebo neplatnú cestu.'
        }
        foreach ($name in $gameFiles) {
            if (@($entries | Where-Object { $_.FullName -ceq $name }).Count -ne 1) {
                throw "Archív neobsahuje presne jeden $name."
            }
        }
        foreach ($entry in $entries) {
            # Fixed allowlist prevents ZIP-slip, nested paths and unexpected deletions.
            $dest = Join-Path $stage $entry.FullName
            $out = [System.IO.File]::Open($dest, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write)
            try {
                $source = $entry.Open()
                try { $source.CopyTo($out) } finally { $source.Dispose() }
            } finally { $out.Dispose() }
        }
    } finally { $archive.Dispose() }
}

# Detect stable and historical GUID-based installers; never scan or edit unrelated folders.
$base = Join-Path $env:LOCALAPPDATA 'Projekt-47'
$stable = Join-Path $base 'game'
$found = @()
if (Test-Path -LiteralPath (Join-Path $stable 'Projekt-47.exe') -PathType Leaf) {
    $found += $stable
}
if (Test-Path -LiteralPath $base -PathType Container) {
    $found += @(Get-ChildItem -LiteralPath $base -Directory | Where-Object {
        $_.Name -match '^demo-[0-9a-f]{32}$' -and
        (Test-Path -LiteralPath (Join-Path $_.FullName 'Projekt-47.exe') -PathType Leaf)
    } | ForEach-Object { $_.FullName })
}
if (-not $InstallPath) {
    if ($found.Count -eq 1) {
        $InstallPath = $found[0]
    } elseif ($found.Count -gt 1) {
        Write-Host 'Našlo sa viac inštalácií Projekt-47:'
        for ($i = 0; $i -lt $found.Count; $i++) {
            $tag = Get-InstalledTag $found[$i]
            if (-not $tag) { $tag = 'neznáma' }
            Write-Host (" [{0}] {1} (verzia {2})" -f ($i + 1), $found[$i], $tag)
        }
        if ($Yes) { throw 'Viac inštalácií. Zadajte explicitne -InstallPath.' }
        $choice = Read-Host 'Zvoľte číslo inštalácie (Enter = zrušiť)'
        $chosen = 0
        if (-not [int]::TryParse($choice, [ref]$chosen) -or $chosen -lt 1 -or $chosen -gt $found.Count) {
            throw 'Nebola vybraná platná inštalácia.'
        }
        $InstallPath = $found[$chosen - 1]
    } else {
        $InstallPath = $stable
    }
}
$InstallPath = [IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($InstallPath))
$gamePath = Join-Path $InstallPath 'Projekt-47.exe'
$existing = Test-Path -LiteralPath $gamePath -PathType Leaf
if (Test-Path -LiteralPath $InstallPath -PathType Container) {
    $work = Join-Path $InstallPath $workName
    if (Test-Path -LiteralPath $work) {
        $owned = Join-Path $work '.managed'
        if (-not (Test-Path -LiteralPath $owned -PathType Leaf)) {
            throw 'Pracovný priečinok má neznámy pôvod. Zastavujem, aby sa nevymazali cudzie dáta.'
        }
        if (Test-Path -LiteralPath (Join-Path $work 'transaction.json') -PathType Leaf) {
            Assert-P47Stopped
            Restore-P47Transaction $InstallPath
        } else {
            Remove-Item -LiteralPath $work -Recurse -Force
        }
    }
}
$existing = Test-Path -LiteralPath $gamePath -PathType Leaf
if ((Test-Path -LiteralPath $InstallPath) -and -not $existing) {
    throw "Po obnove chýba Projekt-47.exe alebo zvolený priečinok nie je inštaláciou: $InstallPath"
}
$installedTag = if ($existing) { Get-InstalledTag $InstallPath } else { $null }
Write-Host "Priečinok: $InstallPath"
Write-Host ("Inštalovaná verzia: " + $(if ($existing) { if ($installedTag) { $installedTag } else { 'neznáma (starší inštalátor)' } } else { 'hra nie je nainštalovaná' }))
$release = Get-ReleaseInfo
Write-Host "Dostupná verzia: $($release.tag)"
if ($existing -and $installedTag -and -not $Force) {
    $comparison = Compare-DemoTags $installedTag $release.tag
    if ($comparison -ge 0) {
        Write-Host 'Aktualizácia nie je potrebná. Pre opravu rovnakej verzie použite -Force.'
        return
    }
}
if (-not (Confirm-P47 $(if ($existing) { "Aktualizovať Projekt-47 na $($release.tag)?" } else { "Nainštalovať Projekt-47 ($($release.tag))?" }))) {
    Write-Host 'Bez zmien.'
    return
}
Assert-P47Stopped
$madeFolder = $false
if (-not $existing) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    $madeFolder = $true
}
$work = Join-Path $InstallPath $workName
if (Test-Path -LiteralPath $work) { throw 'Prebieha iná aktualizácia alebo ostal neobnovený pracovný priečinok.' }
New-Item -ItemType Directory -Path $work | Out-Null
Set-Content -LiteralPath (Join-Path $work '.managed') -Value 'Projekt-47 updater v1' -Encoding ascii
$stage = Join-Path $work 'stage'
$backup = Join-Path $work 'backup'
New-Item -ItemType Directory -Path $stage, $backup | Out-Null
$transactionStarted = $false
try {
    if ($release.offline) {
        $zipPath = $release.archive
        $sumPath = $release.checksum
    } else {
        $zipPath = Join-Path $work 'Projekt-47-Windows.zip'
        $sumPath = Join-Path $work 'SHA256SUMS.txt'
        Write-Host "Sťahujem $($release.tag) z oficiálneho GitHub Release..."
        Invoke-WebRequest -UseBasicParsing -Uri $release.archive -OutFile $zipPath -Headers $headers
        Invoke-WebRequest -UseBasicParsing -Uri $release.checksum -OutFile $sumPath -Headers $headers
    }
    Verify-And-Extract $zipPath $sumPath $stage
    $changed = @()
    $hashes = @{}
    foreach ($name in $gameFiles) {
        $newHash = (Get-FileHash -LiteralPath (Join-Path $stage $name) -Algorithm SHA256).Hash.ToLowerInvariant()
        $hashes[$name] = $newHash
        $oldPath = Join-Path $InstallPath $name
        if (-not (Test-Path -LiteralPath $oldPath -PathType Leaf)) {
            $changed += $name
            Write-Host "[NOVÝ] $name"
        } elseif ((Get-FileHash -LiteralPath $oldPath -Algorithm SHA256).Hash -ine $newHash) {
            $changed += $name
            Write-Host "[ZMENA] $name"
        } else {
            Write-Host "[BEZ ZMENY] $name"
        }
    }
    $metadata = [ordered]@{
        schema = 1
        tag = $release.tag
        installed_at_utc = [DateTime]::UtcNow.ToString('o')
        files = $hashes
    }
    $metadata | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $stage $metadataName) -Encoding UTF8
    $existed = [ordered]@{}
    foreach ($name in @($gameFiles) + @($metadataName)) {
        $oldPath = Join-Path $InstallPath $name
        $existed[$name] = Test-Path -LiteralPath $oldPath -PathType Leaf
        if ($existed[$name]) {
            Copy-Item -LiteralPath $oldPath -Destination (Join-Path $backup $name)
        }
    }
    $tx = [ordered]@{ schema = 1; existed = $existed }
    $journalTemp = Join-Path $work 'transaction.tmp'
    $tx | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $journalTemp -Encoding UTF8
    Move-Item -LiteralPath $journalTemp -Destination (Join-Path $work 'transaction.json')
    $transactionStarted = $true
    Assert-P47Stopped
    $written = 0
    foreach ($name in $changed) {
        Copy-Item -LiteralPath (Join-Path $stage $name) -Destination (Join-Path $InstallPath $name) -Force
        $written++
        # Deterministic fault injection used by the isolated updater CI test.
        if ($env:P47_UPDATER_TEST_FAIL_AFTER -eq "$written") { throw 'Simulované zlyhanie aktualizácie.' }
    }
    Copy-Item -LiteralPath (Join-Path $stage $metadataName) -Destination (Join-Path $InstallPath $metadataName) -Force
    foreach ($name in $gameFiles) {
        if ((Get-FileHash -LiteralPath (Join-Path $InstallPath $name) -Algorithm SHA256).Hash -ine $hashes[$name]) {
            throw "Po aktualizácii sa nezhoduje obsah: $name"
        }
    }
    # Commit is complete; remove the recovery journal before cleaning temporary files.
    Remove-Item -LiteralPath (Join-Path $work 'transaction.json') -Force
    $transactionStarted = $false
    Remove-Item -LiteralPath $work -Recurse -Force
    Write-Host "Hotovo. Verzia: $($release.tag). Uložené hry ani ostatné dáta sa nemenili."
    Write-Host "Spustiť: $gamePath"
} catch {
    $failure = $_
    if ($transactionStarted) {
        try {
            Restore-P47Transaction $InstallPath
        } catch {
            Write-Warning "Automatická obnova zlyhala: $_. Záloha zostáva v $work."
        }
    } elseif (Test-Path -LiteralPath $work) {
        Remove-Item -LiteralPath $work -Recurse -Force
    }
    throw $failure
}
