param(
    [Parameter(Mandatory = $true)][string]$InputPath,
    [Parameter(Mandatory = $true)][string]$OutputPath
)
$ErrorActionPreference = 'Stop'
$game = Join-Path $InputPath 'Projekt-47.exe'
$readme = Join-Path $InputPath 'CITAJ-MA.txt'
if (-not (Test-Path -LiteralPath $game -PathType Leaf) -or -not (Test-Path -LiteralPath $readme -PathType Leaf)) {
    throw 'The verified build artifact is missing a required file.'
}
if ((Get-Item -LiteralPath $game).Length -eq 0) { throw 'The exported game is empty.' }
if (Test-Path -LiteralPath $OutputPath) { throw 'The output directory already exists.' }
New-Item -ItemType Directory -Path $OutputPath | Out-Null
$archive = Join-Path $OutputPath 'Projekt-47-Windows.zip'
Compress-Archive -LiteralPath @($game, $readme) -DestinationPath $archive
$hash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath (Join-Path $OutputPath 'SHA256SUMS.txt') -Value "$hash  Projekt-47-Windows.zip" -Encoding ascii

