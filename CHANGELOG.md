# Changelog

## 1.0.1 — 2026-11-03

### Changes

- Add a tag-triggered GitHub Actions release workflow with version validation and verification on both PowerShell hosts before publishing to the PowerShell Gallery.

### Bug fixes

- Fix Windows PowerShell 5.1 support by loading the .NET Framework Event Log sink. PowerShell Core uses the .NET Standard sink and the host's EventLog implementation.
- Honor `-ManageEventSource $false` and default to disabling event source management by binding the parameter as a boolean.
