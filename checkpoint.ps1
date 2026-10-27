param([switch]$Once, [switch]$RotationTest)
& (Join-Path $PSScriptRoot "tools\checkpoint.ps1") @PSBoundParameters
exit $LASTEXITCODE
