param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$sourceRoot = Join-Path $repoRoot 'src'
$moduleRoot = Join-Path $repoRoot 'out\PoShLog.Sinks.EventLog'

# Refuse stale files rather than accidentally shipping an earlier build's contents.
if ((Test-Path $moduleRoot) -and @(Get-ChildItem $moduleRoot -Force).Count -gt 0) {
    throw "Staging directory must be empty: $moduleRoot"
}

New-Item $moduleRoot -ItemType Directory -Force | Out-Null
foreach ($framework in @('net462', 'netstandard2.0')) {
    $destination = Join-Path $moduleRoot "lib\$framework"
    New-Item $destination -ItemType Directory -Force | Out-Null
    # PoShLog supplies Serilog; the PowerShell host supplies EventLog.
    Copy-Item (Join-Path $sourceRoot "bin\Release\$framework\Serilog.Sinks.EventLog.dll") $destination
}
Copy-Item (Join-Path $sourceRoot 'functions') $moduleRoot -Recurse
foreach ($name in @('PoShLog.Sinks.EventLog.psd1', 'PoShLog.Sinks.EventLog.psm1')) {
    Copy-Item (Join-Path $sourceRoot $name) $moduleRoot
}
foreach ($name in @('README.md', 'CHANGELOG.md')) {
    Copy-Item (Join-Path $repoRoot $name) $moduleRoot
}
Write-Output "Staged module: $moduleRoot"
