BeforeAll {
    $sourceRoot = Join-Path $PSScriptRoot '..\src'
}

Describe 'ManageEventSource parameter binding' {
    BeforeAll {
        # Record the actual argument delivered to the sink without managing a real source.
        Add-Type @'
namespace EventLogBindingTests {
    public class LoggerConfiguration { public object WriteTo { get { return this; } } }
    namespace Events { public enum LogEventLevel { Verbose } }
    namespace Sinks.EventLog { public interface IEventIdProvider {} }
    public static class LoggerConfigurationEventLogExtensions {
        public static bool LastManageEventSource;
        public static LoggerConfiguration EventLog(object writeTo, string source,
            string logName, string machineName, bool manageEventSource, string template,
            System.IFormatProvider provider, Events.LogEventLevel level,
            Sinks.EventLog.IEventIdProvider eventIdProvider) {
            LastManageEventSource = manageEventSource;
            return (LoggerConfiguration)writeTo;
        }
    }
}
'@
        $functionText = Get-Content (Join-Path $sourceRoot 'functions\sinks\Add-SinkEventLog.ps1') -Raw
        . ([scriptblock]::Create($functionText.Replace('Serilog.', 'EventLogBindingTests.')))
    }

    It 'declares a boolean parameter' {
        (Get-Command Add-SinkEventLog).Parameters['ManageEventSource'].ParameterType | Should -Be ([bool])
    }

    It 'defaults to false at the sink boundary' {
        [EventLogBindingTests.LoggerConfigurationEventLogExtensions]::LastManageEventSource = $true
        [EventLogBindingTests.LoggerConfiguration]::new() | Add-SinkEventLog -Source Application | Out-Null
        [EventLogBindingTests.LoggerConfigurationEventLogExtensions]::LastManageEventSource | Should -BeFalse
    }

    It 'passes explicit false unchanged' {
        [EventLogBindingTests.LoggerConfigurationEventLogExtensions]::LastManageEventSource = $true
        [EventLogBindingTests.LoggerConfiguration]::new() | Add-SinkEventLog -Source Application -ManageEventSource $false | Out-Null
        [EventLogBindingTests.LoggerConfigurationEventLogExtensions]::LastManageEventSource | Should -BeFalse
    }

    It 'passes explicit true unchanged' {
        [EventLogBindingTests.LoggerConfigurationEventLogExtensions]::LastManageEventSource = $false
        [EventLogBindingTests.LoggerConfiguration]::new() | Add-SinkEventLog -Source Application -ManageEventSource $true | Out-Null
        [EventLogBindingTests.LoggerConfigurationEventLogExtensions]::LastManageEventSource | Should -BeTrue
    }
}

Describe 'Edition-specific assembly loading' {
    BeforeAll {
        # Replace host variables so both edition branches can be exercised in either host.
        $moduleText = Get-Content (Join-Path $sourceRoot 'PoShLog.Sinks.EventLog.psm1') -Raw
        $loader = [scriptblock]::Create($moduleText.Replace('$PSEdition', '$TestEdition').Replace('$PSScriptRoot', '$TestModuleRoot'))
        $TestModuleRoot = $sourceRoot
    }

    BeforeEach {
        Mock Add-Type {}
        Mock Get-ChildItem { @() }
    }

    It 'loads only the Framework sink on Desktop' {
        $TestEdition = 'Desktop'
        & $loader
        Should -Invoke Add-Type -Times 1 -Exactly -ParameterFilter {
            $Path -eq "$TestModuleRoot\lib\net462\Serilog.Sinks.EventLog.dll" -and $ErrorAction -eq 'Stop'
        }
        Should -Invoke Add-Type -Times 1 -Exactly
    }

    It 'loads only the Standard sink on Core, leaving the host EventLog assembly intact' {
        $TestEdition = 'Core'
        & $loader
        Should -Invoke Add-Type -Times 1 -Exactly -ParameterFilter {
            $Path -eq "$TestModuleRoot\lib\netstandard2.0\Serilog.Sinks.EventLog.dll" -and $ErrorAction -eq 'Stop'
        }
        Should -Invoke Add-Type -Times 1 -Exactly
    }

    It 'fails import when the selected sink cannot load' {
        $TestEdition = 'Desktop'
        Mock Add-Type { throw 'Sink load failed' }
        { & $loader } | Should -Throw '*Sink load failed*'
    }
}
