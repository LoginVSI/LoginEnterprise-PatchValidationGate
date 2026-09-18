# Contributing

This is a reference implementation, so clarity beats cleverness. Someone should be able to read any file here in one sitting and understand what it does and why.

## Before you start

Read `README.md`, `docs/architecture.md`, `docs/verdict.md`, and `docs/api-notes.md`. The API notes summarize the reviewed OpenAPI snapshot. Update them from that source before adding endpoint calls; keep capture-only uncertainty explicit.

## Branches

Work on a branch off `main`, named for what it does:

- `feature/short-description` for new functionality
- `fix/short-description` for bug fixes
- `docs/short-description` for documentation only
- `chore/short-description` for tooling, CI, and housekeeping

Keep branches short-lived. Rebase on `main` before opening a pull request.

## Commits

Plain messages that say what changed and, if it is not obvious, why. First line under 72 characters, no trailing period. Commit in logical chunks: a helper and its tests together, docs for a feature with the feature. Never mention a hostname, token, customer, or internal URL in a commit message. The repo is public and history is forever.

## Code rules

Windows PowerShell 5.1 is the floor. No ternary operator, no null-coalescing, no `ForEach-Object -Parallel`, no `class` features that 5.1 lacks. The lint settings and a unit test both check for the obvious ones, but the real test is running the suite in 5.1 before you push.

One function per file. The file name is the function name. Public functions live in `src/LEGate/Public/` and are named `Verb-LEGate*` with an approved verb. Private helpers live in `src/LEGate/Private/` and are not exported. Adding a public function means adding it to `FunctionsToExport` in the manifest as well; the module test fails otherwise.

Appliance HTTP uses `Invoke-LEGateRequest`; GitHub HTTP uses the separate fixed-origin helper. Installer download is a separate normal-TLS boundary. All logging goes through `Write-LEGateLog`. Do not call `Write-Host` or `Write-Verbose` directly. All timestamps come from `Get-LEGateUtcNow` and `ConvertTo-LEGateTimestamp`.

Comment-based help on every function: synopsis, description, parameters. Write it the way you would explain the function to a colleague.

## Tests

Tests in `tests/unit/` cover public behavior and failure boundaries, including full flows with only external boundaries replaced. Unit tests mock `Invoke-RestMethod` and never touch the network; they run on a hosted CI runner with no appliance.

A change to behaviour is not done until a test covers it. A bug fix starts with a failing test.

Integration tests in `tests/integration/` may talk to a real appliance. They must skip cleanly when `LE_BASE_URL` and `LE_API_TOKEN` are absent, and they must not start test runs unless the person running them opted in explicitly.

Run everything before you push:

```powershell
.\scripts\Invoke-Lint.ps1
.\tests\Invoke-Tests.ps1
```

## Fixtures

No genuine fixtures are committed yet. `tests/fixtures/` is reserved for reviewed real captures; `tests/synthetic/` holds labeled synthetic inputs. The naming and sanitization rules are in `tests/fixtures/README.md`. In short: no hostnames, no account names, no tokens; review identifying IDs too; keep the shape exactly as the appliance sent it.

Use the [private capture bootstrap](first-live-capture.md) and exporter, which retain page traces and binary evidence. Review sanitized copies separately from originals before proposing any public fixture. Reviewers should inspect fixture diffs line by line.

## Development environment and checks

User scenarios need no development dependencies. Contributors need Pester 5 and PSScriptAnalyzer in both supported shells. Inspect existing installations with `Get-Module -ListAvailable Pester,PSScriptAnalyzer`; use `scripts/Initialize-DevEnvironment.ps1` under your approved installation policy if needed. PS7 lint can discover an existing WindowsPowerShell user installation. Do not weaken organizational execution policy.

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File tests/Invoke-Tests.ps1 -Output Normal
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File scripts/Invoke-Lint.ps1
pwsh -NoProfile -File tests/Invoke-Tests.ps1 -Output Normal
pwsh -NoProfile -File scripts/Invoke-Lint.ps1
```

Pester uses temporary files and registry entries. Private NUnit XML and count summaries go to ignored `tests/results/`; CI publishes count summaries only. Run the synthetic scenario in both shells and inspect its built-in bundle verification. Keep all generated outputs ignored.

Static workflow/skill checks require Python and PyYAML. If not already installed, the following uses an ignored local dependency directory:

```powershell
py -m pip install --target .private/python PyYAML==6.0.3
py scripts/Test-RepositoryArtifacts.py
```

These checks validate YAML, action pins, orchestration guards and skill example hashes. They neither execute Actions nor prove model compliance. The reviewed OpenAPI files are static references and test inputs, not runtime dependencies. Keep their sanitized provenance intact.

## Docs

Keep customer instructions consistent with script parameters and provide expected outcomes. If documentation and code disagree, correct them together. Separate observed results from synthetic examples and spec-derived facts.

`CHANGELOG.md` follows Keep a Changelog. Add a line under Unreleased for anything a user of the module would notice.

## Pull requests

Describe what changed and how you tested it. Link the issue if there is one. CI has to be green. A reviewer will check for 5.1 compatibility, secrets, scope creep, and whether the tests would actually catch a regression.
