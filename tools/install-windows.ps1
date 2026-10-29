param(
    [string]$InstallPath = (Join-Path $env:LOCALAPPDATA ("Projekt-47\demo-" + [guid]::NewGuid().ToString('N'))),
    [string]$ArchivePath,
    [string]$ChecksumPath
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ([bool]$ArchivePath -ne [bool]$ChecksumPath) {
    throw 'Pre miestnu instalaciu treba zadat archiv aj kontrolny sucet.'
}
if (Test-Path -LiteralPath $InstallPath) {
    throw "Cielovy priecinok uz existuje: $InstallPath. Vyberte novy priecinok."
}

if (-not $ArchivePath) {
    $headers = @{ 'User-Agent' = 'Projekt-47-installer'; 'Accept' = 'application/vnd.github+json' }
    $releases = @(Invoke-RestMethod -Uri 'https://api.github.com/repos/Wondris404/Projekt-47/releases?per_page=100' -Headers $headers)
    $release = $releases | Where-Object {
        -not $_.draft -and $_.tag_name -match '^demo-[0-9]+-[0-9]+$' -and
        @($_.assets | Where-Object { $_.name -eq 'Projekt-47-Windows.zip' }).Count -eq 1 -and
        @($_.assets | Where-Object { $_.name -eq 'SHA256SUMS.txt' }).Count -eq 1
    } | Select-Object -First 1
    if (-not $release) {
        throw 'Verejny instalacny balik este nie je zverejneny. Skuste to neskor.'
    }
    $zipUrl = ($release.assets | Where-Object { $_.name -eq 'Projekt-47-Windows.zip' }).browser_download_url
    $sumUrl = ($release.assets | Where-Object { $_.name -eq 'SHA256SUMS.txt' }).browser_download_url
    $prefix = 'https://github.com/Wondris404/Projekt-47/releases/download/' + $release.tag_name + '/'
    if ($zipUrl -ne ($prefix + 'Projekt-47-Windows.zip') -or $sumUrl -ne ($prefix + 'SHA256SUMS.txt')) {
        throw 'Adresa vydania sa nezhoduje s oficialnym repozitarom.'
    }
    New-Item -ItemType Directory -Path $InstallPath -ErrorAction Stop | Out-Null
    $ArchivePath = Join-Path $InstallPath 'Projekt-47-Windows.zip'
    $ChecksumPath = Join-Path $InstallPath 'SHA256SUMS.txt'
    Write-Host "Stahujem vydanie $($release.tag_name)..."
    Invoke-WebRequest -UseBasicParsing -Uri $zipUrl -OutFile $ArchivePath -Headers $headers
    Invoke-WebRequest -UseBasicParsing -Uri $sumUrl -OutFile $ChecksumPath -Headers $headers
} else {
    if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf) -or -not (Test-Path -LiteralPath $ChecksumPath -PathType Leaf)) {
        throw 'Archiv alebo kontrolny sucet neexistuje.'
    }
}

$checksumText = Get-Content -LiteralPath $ChecksumPath -Raw
$matches = [regex]::Matches($checksumText, '(?im)^([a-f0-9]{64})[ \t]+\*?Projekt-47-Windows\.zip[ \t]*\r?$')
if ($matches.Count -ne 1) { throw 'Kontrolny sucet nema ocakavany format.' }
$actual = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash
if ($actual -ne $matches[0].Groups[1].Value) { throw 'Kontrolny sucet archivu nesuhlasi; instalacia sa zastavila.' }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $ArchivePath).Path)
try {
    $expected = @('Projekt-47.exe', 'CITAJ-MA.txt')
    $entries = @($archive.Entries)
    if ($entries.Count -ne 2 -or @($entries | Where-Object { $_.FullName -notin $expected }).Count -ne 0 -or
        @($entries | Where-Object { $_.FullName -eq 'Projekt-47.exe' }).Count -ne 1 -or
        @($entries | Where-Object { $_.FullName -eq 'CITAJ-MA.txt' }).Count -ne 1 -or
        @($entries | Where-Object { $_.Length -gt 4294967296 }).Count -ne 0) {
        throw 'Obsah archivu nezodpoveda ocakavanemu hernemu baliku.'
    }
    if (-not (Test-Path -LiteralPath $InstallPath)) {
        New-Item -ItemType Directory -Path $InstallPath -ErrorAction Stop | Out-Null
    }
    foreach ($entry in $entries) {
        $destination = Join-Path $InstallPath $entry.FullName
        $out = [System.IO.File]::Open($destination, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write)
        try {
            $source = $entry.Open()
            try { $source.CopyTo($out) } finally { $source.Dispose() }
        } finally { $out.Dispose() }
    }
} finally { $archive.Dispose() }

Write-Host "Hra je nainstalovana v: $InstallPath"
Write-Host "Spustite: $(Join-Path $InstallPath 'Projekt-47.exe')"

