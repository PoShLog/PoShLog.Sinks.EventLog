# PoShLog provides Serilog. The host provides EventLog (System.dll on Desktop,
# System.Diagnostics.EventLog on Core); never load the NuGet platform-neutral stub.
$targetFramework = if ($PSEdition -eq 'Desktop') { 'net462' } else { 'netstandard2.0' }
Add-Type -Path "$PSScriptRoot\lib\$targetFramework\Serilog.Sinks.EventLog.dll" -ErrorAction Stop

# dot source all script files
Get-ChildItem -Path "$PSScriptRoot\functions" -Recurse -File -Filter '*.ps1' | ForEach-Object {
	. $_.FullName

	# Export all functions except internal
	if ($_.FullName -notlike '*\internal\*') {
		Export-ModuleMember $_.BaseName
	}
}
