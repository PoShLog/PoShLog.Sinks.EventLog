# 0001: Load the Event Log sink for the PowerShell edition

Date: 2026-11-03

Status: Proposed

## Context

The v2 extension supports Windows PowerShell 5.1 (.NET Framework) and PowerShell Core alongside PoShLog 2.x. The platform-neutral System.Diagnostics.EventLog assembly from the .NET Standard dependency graph throws PlatformNotSupportedException on Desktop. Core already supplies a working EventLog implementation.

## Decision

Build dependencies for net462 and netstandard2.0, retaining Serilog.Sinks.EventLog 3.1.0. Ship only Serilog.Sinks.EventLog.dll under each framework directory. Select net462 for Desktop and netstandard2.0 for Core. PoShLog supplies Serilog; the PowerShell host supplies EventLog. Propagate assembly loading failures during import.

These framework targets are required by the supported PowerShell hosts, rather than the default .NET 10 application target. Keep the existing PoShLog minimum dependency at 2.0.0.

## Alternatives considered

- Keep the single netstandard2.0 build and drop only the stub: Serilog.Sinks.EventLog for .NET Standard then needs System.Diagnostics.EventLog, which .NET Framework does not provide as a separate assembly.
- Ship the Windows runtime build of System.Diagnostics.EventLog: it targets .NET Core and would conflict with the copy PowerShell 7 already loads.
- Drop Windows PowerShell 5.1 support: 5.1 is the main audience of the v2 line.

## Consequences

Desktop uses the sink's .NET Framework target and System.dll EventLog implementation. Core reuses the host's System.Diagnostics.EventLog assembly without loading a conflicting package copy. The staged module must be verified in fresh processes for both hosts.
