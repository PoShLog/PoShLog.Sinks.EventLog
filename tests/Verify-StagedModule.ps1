param(
    [Parameter(Mandatory = $true)]
    [string]$PoShLogManifest,
    [string]$ModuleManifest
)

$ErrorActionPreference = 'Stop'
if (-not $ModuleManifest) {
    $ModuleManifest = Join-Path $PSScriptRoot '..\src\output\PoShLog.Sinks.EventLog\PoShLog.Sinks.EventLog.psd1'
}
Import-Module $PoShLogManifest -Force
if ((Get-Module PoShLog).Version -ne [version]'2.3.0') {
    throw 'Verification requires PoShLog 2.3.0.'
}
$hostEventLog = [System.Diagnostics.EventLog].Assembly.Location
$packagedDlls = @(Get-ChildItem (Join-Path (Split-Path $ModuleManifest) 'lib') -Recurse -Filter '*.dll')
if ($packagedDlls.Count -ne 2 -or @($packagedDlls | Where-Object { $_.Name -ne 'Serilog.Sinks.EventLog.dll' }).Count -ne 0) {
    throw 'The extension must package only the two edition-specific sink assemblies.'
}
Import-Module $ModuleManifest -Force
if ((Get-Module PoShLog.Sinks.EventLog).Version -ne [version]'1.0.1') {
    throw 'The staged module must be version 1.0.1.'
}
if ([System.Diagnostics.EventLog].Assembly.Location -ne $hostEventLog) {
    throw 'The extension replaced the host EventLog implementation.'
}
$sinkAssembly = [Serilog.LoggerConfigurationEventLogExtensions].Assembly
$framework = if ($PSEdition -eq 'Desktop') { 'net462' } else { 'netstandard2.0' }
if ($sinkAssembly.Location -notlike "*\lib\$framework\Serilog.Sinks.EventLog.dll") {
    throw "Unexpected sink assembly: $($sinkAssembly.Location)"
}

$selfLog = New-Object System.IO.StringWriter
[Serilog.Debugging.SelfLog]::Enable([System.IO.TextWriter]$selfLog)
$startTime = Get-Date
$messages = @()
try {
    foreach ($explicitFalse in @($false, $true)) {
        $message = "PoShLog.Sinks.EventLog 1.0.1 verification $PSEdition $([guid]::NewGuid())"
        $messages += $message
        $sinkParameters = @{ Source = 'Application'; LogName = 'Application' }
        if ($explicitFalse) { $sinkParameters.ManageEventSource = $false }
        try {
            New-Logger | Add-SinkEventLog @sinkParameters | Start-Logger
            Write-InfoLog $message
        }
        finally {
            Close-Logger
        }
    }
}
finally {
    [Serilog.Debugging.SelfLog]::Disable()
}
if ($selfLog.ToString()) { throw "Serilog reported a sink failure: $selfLog" }

# A read failure is reported separately; a successful read must contain both writes.
$events = $null
try {
    $events = @(Get-WinEvent -FilterHashtable @{ LogName = 'Application'; ProviderName = 'Application'; StartTime = $startTime.AddSeconds(-1) })
}
catch {
    Write-Warning "Event readback unavailable: $($_.Exception.Message)"
}
if ($null -ne $events) {
    foreach ($message in $messages) {
        if (-not ($events | Where-Object { ($_.Properties.Value -join "`n") -like "*$message*" })) {
            throw "Written event was not found: $message"
        }
    }
    Write-Output "Event readback passed: $($messages.Count) messages."
}
Write-Output "PASS: PowerShell $($PSVersionTable.PSVersion), $PSEdition, PoShLog $((Get-Module PoShLog).Version)."
Write-Output "Sink: $($sinkAssembly.Location)"
Write-Output "EventLog: $hostEventLog"
Write-Output 'Source creation and other administrative paths were not tested.'
