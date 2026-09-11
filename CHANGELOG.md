# Changelog

All notable changes to this project are recorded here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - Unreleased

### Added

- LEGate PowerShell module with a manifest, one function per file, PowerShell 5.1 compatible.
- `Connect-LEGate`, `Get-LEGateVersion`, `Resolve-LEGateTest`, `Start-LEGateRun`, `Wait-LEGateRun`.
- Private request wrapper over `Invoke-RestMethod` with GET-only retry, ProblemDetails surfacing, and token redaction.
- Private paging helper, structured logging helper with JSON lines mode, UTC ISO 8601 timestamps, and a single source for verdict reason codes.
- Pester 5 unit tests with mocked HTTP, integration tests that skip without an appliance, and a test runner script.
- PSScriptAnalyzer settings with 5.1 compatibility rules and a lint wrapper.
- GitHub Actions `ci.yml` running lint and unit tests in Windows PowerShell 5.1 on a hosted runner.
- Smoke check script, developer setup script, and docs for setup, contributing, security, AI agents, and the three integration contracts.

[Unreleased]: https://github.com/OWNER/REPO/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/OWNER/REPO/releases/tag/v0.1.0
