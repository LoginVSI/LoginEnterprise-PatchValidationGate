# Local setup

You need a Windows machine with Windows PowerShell 5.1. PowerShell 7 works too, but 5.1 is the floor and CI runs there, so test on it before you push.

## Install the tooling

From the repo root:

```powershell
.\scripts\Initialize-DevEnvironment.ps1
```

That installs Pester 5 and PSScriptAnalyzer for the current user if they are missing, and prints which environment variables are set. It does not touch anything machine-wide.

If the script stops with a message that PowerShellGet could not be loaded, the machine's Windows PowerShell has a PowerShellGet that lacks a matching PackageManagement, which happens on hosts where PowerShell 7 was installed over an older setup. The fix that needs no admin rights is to download the modules from PowerShell 7 into the Windows PowerShell user module folder, then rerun the script:

```powershell
# in pwsh
$dest = "$HOME\Documents\WindowsPowerShell\Modules"
Save-Module -Name Pester -Path $dest
Save-Module -Name PSScriptAnalyzer -Path $dest
```

Run the lint, test, and smoke scripts from a normal Windows PowerShell console, not from a shell spawned by PowerShell 7, so that folder is on the module path.

## Environment variables

The module never reads a config file for credentials. Everything comes from the environment.

| Variable | Required | What it is |
|---|---|---|
| `LE_BASE_URL` | for smoke and integration | Appliance base URL, for example `https://appliance.example.test`. No trailing path. |
| `LE_API_TOKEN` | for smoke and integration | A system access token. See below for the role it needs. |
| `LE_TEST_NAME` | optional | Exact application test name. The integration tests resolve it if set. |
| `LE_SKIP_CERT_CHECK` | optional | Set to `1` when the appliance has a self-signed certificate. Lab use only. |
| `LEGATE_LOG_FORMAT` | optional | Set to `json` to get one JSON object per log line. |

Set them for the current session only:

```powershell
$env:LE_BASE_URL = 'https://appliance.example.test'
$env:LE_API_TOKEN = '<token>'
```

Do not put them in a profile that gets committed, a `.env` file inside the repo, or a script. The `.gitignore` excludes `.env` and `*.local.ps1` as a safety net, not as an invitation.

## Creating a least-privilege token

The module authenticates with a Login Enterprise system access token sent as `Authorization: Bearer`. Create the token in the appliance web console under the configuration area for system access tokens, attached to a role you create for the gate. The exact click path depends on the appliance version, so follow the appliance documentation for the steps.

What matters is the role scope. Everything in this repo works with a role that can:

- read tests (to resolve an application test by name and read its thresholds)
- read test runs and their results (to poll a run and, later, pull sessions, executions, events, and screenshots)
- start a test (the one write, `PUT /tests/{testId}/start`)

Nothing here needs to create, edit, or delete tests, manage accounts or launchers, or change appliance settings. If the role editor lets you scope reads to a subset of tests, scope it to the tests the gate uses.

Treat the token like a password. Rotate it if it ends up in a log, a screenshot, or a chat message.

## Run the smoke check

Version call only. This is the first thing to run against a new appliance:

```powershell
.\scripts\Invoke-Smoke.ps1
```

Full check. Resolves the test, starts a run tagged with the change id, waits, and prints the outcome:

```powershell
.\scripts\Invoke-Smoke.ps1 -TestName 'Your Application Test' -ChangeId 'CHG-2026-0911-01'
```

Running it twice with the same change id does not start a second run. The module finds the run whose `testRunName` matches and waits on that one. The raw run lands in `evidence/CHG-2026-0911-01/run.json`.

Exit codes: 0 succeeded, 1 an error was thrown, 2 the run did not finish inside the wait budget, 3 the run finished with a result other than `successful`. Add `-SkipCertificateCheck` for a lab appliance.

## Run lint

```powershell
.\scripts\Invoke-Lint.ps1
```

Runs PSScriptAnalyzer over `src`, `scripts`, and `tests` with the settings in `PSScriptAnalyzerSettings.psd1`. Exits 1 on any warning or error. The compatibility rules are there to catch PowerShell 7 syntax before CI does.

## Run the tests

Unit tests only, no appliance needed:

```powershell
.\tests\Invoke-Tests.ps1
```

Unit plus integration. The integration suite skips itself when `LE_BASE_URL` or `LE_API_TOKEN` is missing:

```powershell
.\tests\Invoke-Tests.ps1 -Integration
```

Results are written to `tests/results/pester.xml`.
