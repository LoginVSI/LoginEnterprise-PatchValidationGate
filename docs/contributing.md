# Contributing

This is a reference implementation, so clarity beats cleverness. Someone should be able to read any file here in one sitting and understand what it does and why.

## Before you start

Read `README.md`, `docs/architecture.md`, `docs/verdict.md`, and `docs/api-notes.md`. The API notes are the only source for endpoint paths, parameters, and response shapes. If you need an endpoint the notes do not list, add it to the notes first, from the appliance OpenAPI spec, in its own commit.

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

All HTTP goes through `Invoke-LEGateRequest`. Do not call `Invoke-RestMethod` from anywhere else. All logging goes through `Write-LEGateLog`. Do not call `Write-Host` or `Write-Verbose` directly. All timestamps come from `Get-LEGateUtcNow` and `ConvertTo-LEGateTimestamp`.

Comment-based help on every function: synopsis, description, parameters. Write it the way you would explain the function to a colleague.

## Tests

Every public function has a unit test file in `tests/unit/` named `{FunctionName}.Tests.ps1`. Private helpers with any logic get one too. Unit tests mock `Invoke-RestMethod` and never touch the network; they run on a hosted CI runner with no appliance.

A change to behaviour is not done until a test covers it. A bug fix starts with a failing test.

Integration tests in `tests/integration/` may talk to a real appliance. They must skip cleanly when `LE_BASE_URL` and `LE_API_TOKEN` are absent, and they must not start test runs unless the person running them opted in explicitly.

Run everything before you push:

```powershell
.\scripts\Invoke-Lint.ps1
.\tests\Invoke-Tests.ps1
```

## Fixtures

Fixtures in `tests/fixtures/` are real appliance responses, saved as JSON and sanitized. The naming and sanitization rules are in `tests/fixtures/README.md`. In short: no hostnames, no account names, no tokens; ids are fine; keep the shape exactly as the appliance sent it.

To capture one, run the call through the module with `LE_BASE_URL` and `LE_API_TOKEN` set, save the raw object with `ConvertTo-Json -Depth 20`, sanitize by hand, and read the entire file one more time before you commit it. Reviewers should read fixture diffs line by line for the same reason.

## Docs

Docs are written for a person. Short sentences, plain words, no em dashes, no bullet walls where a sentence does the job. If a doc and the code disagree, fix whichever one is wrong in the same pull request.

`CHANGELOG.md` follows Keep a Changelog. Add a line under Unreleased for anything a user of the module would notice.

## Pull requests

Describe what changed and how you tested it. Link the issue if there is one. CI has to be green. A reviewer will check for 5.1 compatibility, secrets, scope creep, and whether the tests would actually catch a regression.
