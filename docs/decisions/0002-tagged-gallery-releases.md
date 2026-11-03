# 0002: Publish tagged releases through GitHub Actions

Date: 2026-11-03

Status: Proposed

## Context

The standalone EventLog extension needs a repeatable release path for PoShLog 2.x. Tomáš approved tag-triggered PowerShell Gallery releases on 2026-11-03; creating tags and configuring the secret remain separate manual steps.

## Decision

Use a Windows GitHub Actions job for tags matching `v*`. Require the tag version to match the committed manifest, including prerelease metadata, and a matching CHANGELOG heading. Build with the .NET 10 SDK while retaining the host-required net462 and netstandard2.0 targets documented in ADR 0001.

Stage only the two sink assemblies, module files, functions, README and CHANGELOG. Run Pester and staged integration verification in fresh Windows PowerShell 5.1 and PowerShell Core processes, using Gallery PoShLog 2.x. Publish with `Publish-Module` only after all checks pass, using `PSGALLERY_API_KEY`. Missing credentials produce a notice and a successful validation run. Manual dispatch validates and tests only.

## Alternatives considered

- Continue using Azure Pipelines: retain the existing file unchanged, but use GitHub tags for the approved release path.
- Publish from manual dispatch: keep dispatch validation-only to avoid accidental publication from an arbitrary branch.

## Consequences

Tagged releases depend on Gallery availability for CI tooling and PoShLog. Local staging uses the same script without installing Gallery tooling. A nonempty staging destination is rejected to prevent stale files from entering a release.
