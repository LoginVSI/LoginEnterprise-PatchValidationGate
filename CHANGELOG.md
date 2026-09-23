# Changelog

All notable changes to this project are recorded here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

- Pin Pester 5.7.1 in setup and the test runner. An unbounded minimum installed Pester 6, whose filtered-mock behavior broke the existing recovery-lock regression.

- Add an explicit public execution export that omits PR-triggered CI, retains main push checks, and records the transformation. Reject the development repository as an export destination regardless of letter case.
- Document public runner isolation, recovery prerequisites, and secret retirement; correct stale stop-endpoint and local-acceptance statements.
- Allow manual dispatch of hosted offline CI so an initial import with Actions disabled can be verified after repository protections are configured.

- Verified local update, deliberate failure, independent restoration and bounded Continuous Test execution against LE 6.8.6; added sanitized real-response regressions. GitHub acceptance remains pending.
- Capture historical run configuration, expose conservative read-only Windows Installer preflight, and add bounded Continuous Test disable/drain with request deadlines.
- Add pinned-source export preparation for an exact private Actions execution repository without weakening the main-branch restriction.

- Fixed target remoting with configurable HTTP/HTTPS and ports across CLI, adapters, validation, restoration and Actions. HTTPS uses Negotiate with normal certificate validation; legacy HTTP/5985 recovery remains supported.

- Added reviewed v7 and v8-preview static OpenAPI references with explicit provenance and sanitization.
- Aligned candidate overview selection/comparison, native Events, screenshot retrieval and continuous scheduling with v8-preview; added spec-derived regressions.
- Separated customer setup from contributor dependencies and added read-only AI prompts and external-pipeline guidance.
- Removed the public internal handoff document after preserving it privately. Historical copies remain in Git history.

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
- Version call verified against a Login Enterprise 6.8.6 appliance. This was a version call only; end-to-end gate acceptance remains pending.

[Unreleased]: https://github.com/LoginVSI/LoginEnterprise-PatchValidationGate/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/LoginVSI/LoginEnterprise-PatchValidationGate/releases/tag/v0.1.0

## Offline gate implementation (unreleased)

- Added strict results collection, normalization, pure functional policy, byte-verified evidence and allowlisted publication.
- Added pinned MSI update, reversible executable break and noop adapters; explicit credentials, durable identity/target ownership, resume and restoration.
- Added issue reporting, approval provenance checks, simulated promotion, continuous handoff and dispatch-only pinned Actions jobs with artifact transfer.
- Added synthetic evaluator examples, external-boundary full-flow tests, private capture tooling, one read-only explainer skill and reproducible runbooks.
- Removed the PS5.1 process-wide certificate bypass. Untracked generated NUnit output without rewriting history. Fixed ignore entries.
- Added contract extensions documented in contracts.md. Live API acceptance remains pending; no release/tag is created.
