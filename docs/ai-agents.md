# Working in this repo as an AI coding agent

This page is for an AI coding agent, or a skill that drives one, that will change code in this repository. `CLAUDE.md` at the root is the short version. This is the long one. Read both, then the four documents below, before touching anything.

## Where the truth lives

| Question | Answer lives in |
|---|---|
| What is this thing and what is it not | `README.md` |
| How the pieces fit and what is deferred | `docs/architecture.md` |
| What PASS, FAIL, and INCONCLUSIVE mean, and the reason codes | `docs/verdict.md` and `Private/Get-LEGateReasonCodes.ps1` |
| Every endpoint path, parameter, and response shape | `docs/api-notes.md` and nothing else |
| The shapes other systems plug into | `docs/contracts.md` |
| Policy structure | `policies/policy.schema.json` |
| How to set up, lint, test, and smoke | `docs/setup.md` |
| Repo conventions | `docs/contributing.md` |
| Secrets and public-repo rules | `docs/security.md` |

When two of these disagree, stop and say so. Do not pick one silently.

## Contracts you are bound by

**PowerShell 5.1.** Every `.ps1`, `.psm1`, and `.psd1` runs on Windows PowerShell 5.1. No ternary, no `??`, no `?.`, no `ForEach-Object -Parallel`, no PowerShell 7 parameters on built-in cmdlets unless the code checks for them first the way `Connect-LEGate` does with `SkipCertificateCheck`. CI runs in 5.1 and will fail the build. A unit test in `tests/unit/Module.Tests.ps1` also scans for the obvious syntax.

**One function per file.** File name equals function name. Public functions in `src/LEGate/Public/`, named `Verb-LEGate*` with an approved verb, listed in `FunctionsToExport` in the manifest. Private helpers in `src/LEGate/Private/`, never exported.

**One HTTP path.** All appliance calls go through `Invoke-LEGateRequest`. It builds the URL from the session, adds the bearer token, retries only GET, surfaces ProblemDetails, and redacts the token. Do not call `Invoke-RestMethod` anywhere else. Do not generate a client from the OpenAPI spec. Do not add the PSLoginEnterprise module.

**One logging path.** All output goes through `Write-LEGateLog` with a level, a message, and optional fields. No `Write-Host`. No direct `Write-Verbose`. Redaction lives inside the log helper, so bypassing it bypasses redaction.

**One clock.** Timestamps come from `Get-LEGateUtcNow` and are formatted by `ConvertTo-LEGateTimestamp` as UTC ISO 8601 with millisecond precision and a `Z` suffix. Tests mock the clock; code that reads `[DateTime]::Now` directly cannot be tested and will be rejected.

**One list of reason codes.** `Get-LEGateReasonCodes` is the source. A test checks it against `docs/verdict.md` and `policies/default.policy.json`. Adding a reason code means changing all three in one commit.

**The evaluator is pure.** When it exists, results and policy go in, a verdict comes out, no network, no clock, no file system. Same inputs, same verdict.

**Timeouts and infrastructure errors are INCONCLUSIVE.** Never FAIL. `Wait-LEGateRun` returns `timedOut = $true` instead of throwing for exactly this reason. Do not change that.

**Writes are never retried.** A retried `PUT /tests/{testId}/start` could start a second run. The idempotency check in `Start-LEGateRun` by `testRunName` is the mechanism that makes re-running a workflow safe. Keep both.

## Things you must never do

- Call an endpoint that `docs/api-notes.md` does not list. If you need one, stop and ask for it to be added to the notes from the appliance spec.
- Guess a response shape. If the notes do not say what a field is called, stop.
- Write `LE_BASE_URL` or `LE_API_TOKEN` to disk, print the token, or put it in an error message. Test output counts.
- Commit a hostname, IP address, token, customer name, account name, or internal URL. This includes fixtures, test data, comments, and commit messages.
- Add a public function without a `tests/unit/{Name}.Tests.ps1` file that mocks `Invoke-RestMethod`.
- Turn a timeout, launcher error, or connection error into FAIL anywhere in the code.
- Deploy, roll back, modify a test, or touch appliance configuration. The gate starts an existing test and reads results. That is its entire write surface.
- Widen scope. If the task says five functions, deliver five. The deferred list in `docs/architecture.md` is deferred on purpose. Ask before pulling anything forward.
- Use em dashes in prose, or write docs that read like a template.

## How to add a function

1. Check `docs/api-notes.md` has the endpoint. If not, stop.
2. Create `src/LEGate/Public/Verb-LEGateNoun.ps1` (or `Private/` for a helper). Comment-based help. Parameters validated. Session typed as `[PSTypeName('LEGate.Session')]`.
3. Call `Invoke-LEGateRequest` for HTTP and `Write-LEGateLog` for output.
4. Add the name to `FunctionsToExport` if public.
5. Write `tests/unit/Verb-LEGateNoun.Tests.ps1`. Mock `Invoke-RestMethod` with `-ModuleName LEGate`. Cover the happy path, the error path, and anything that could leak the token. See `tests/unit/TestHelpers.ps1` for the helpers that build sessions, fake HTTP errors, and paged responses.
6. Run `.\scripts\Invoke-Lint.ps1` and `.\tests\Invoke-Tests.ps1` in Windows PowerShell 5.1. Both must be clean.
7. Add a line to `CHANGELOG.md` under Unreleased.
8. Commit with a plain message. No secrets in the message.

## How to verify your work

```powershell
.\scripts\Invoke-Lint.ps1
.\tests\Invoke-Tests.ps1
```

If an appliance is available and the task calls for it, `.\scripts\Invoke-Smoke.ps1` proves the module against reality. Ask before running the full smoke with `-TestName` and `-ChangeId`, because it starts a real test run.

## When to stop and ask

Stop when the API notes do not cover what you need, when a doc contradicts the code, when a task would need one of the deferred components, when the only way to make a test pass is to weaken it, or when you are about to change a contract in `docs/contracts.md`. A short question costs less than an incorrect gate.
