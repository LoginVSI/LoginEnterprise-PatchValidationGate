# User setup

The [offline example](../README.md#start-here) needs only a checkout and Windows PowerShell 5.1 or PowerShell 7 on Windows. Pester, PSScriptAnalyzer, Python and PyYAML are contributor tools, not runtime prerequisites. No generated SDK or PSLoginEnterprise module is used.

## Prepare Login Enterprise

Use the official documentation for your installed release. These 6.8 pages were checked for relevant content during this pass; the links do not establish appliance compatibility.

1. Prepare working [launchers](https://docs.loginvsi.com/login-enterprise/6.8/launchers-overview-and-best-practices), accounts and a [connector to the target](https://docs.loginvsi.com/login-enterprise/6.8/connectors-and-universal-web-connector). Reserve a disposable Windows target and an independently recoverable baseline.
2. Configure [application workloads](https://docs.loginvsi.com/login-enterprise/6.8/configuring-applications-for-testing) for Notepad and the demo app, including visible actions. Add them to an existing [application test](https://docs.loginvsi.com/login-enterprise/6.8/configuring-application-testing) named `patch-gate-app`. Workloads must exercise the executable the adapter changes.
3. Configure `patch-gate-continuous` using [continuous testing and notifications](https://docs.loginvsi.com/login-enterprise/6.8/configuring-continuous-testing). Keep scheduling disabled and wait for active sessions to drain before mutations. The gate checks `isEnabled=false` and active sessions for that test. Also exclude unrelated tests and operators from the target.
4. Use [Public API access and System Access Tokens](https://docs.loginvsi.com/login-enterprise/6.8/using-the-public-api) to obtain appropriate access and download the matching OpenAPI export. The documented UI route is Other > Access control > Public API, then the selected API documentation. Retain exports privately for comparison with the [reviewed snapshots](api/README.md). Confirm effective read/start permissions without unrelated administrative access.
5. Learn where to inspect [application results, Events and failure screenshots](https://docs.loginvsi.com/login-enterprise/6.8/viewing-application-testing-results). The [scripting functions reference](https://docs.loginvsi.com/login-enterprise/6.8/scripting-functions-overview) describes custom Events and TakeScreenshot. This gate does not interpret arbitrary custom-event prose or performance timers as functional failure.

The standalone official Managing Notifications and Viewing All Events pages could not be retrieved during this pass. The verified continuous-testing and application-results pages above cover the relevant concepts and link to those pages. Check their availability in the vendor documentation before configuring notifications.

## Configure private inputs

From the repository root, copy the templates once. This block stops if any destination exists:

```powershell
$copies = @{
    'policies/default.policy.json' = 'policies/demo.local.json'
    'examples/changes/app-update.json' = 'examples/changes/demo.local.json'
    'config/response-profile.example.json' = 'config/response-profile.local.json'
}
foreach ($destination in $copies.Values) {
    if (Test-Path -LiteralPath $destination) { throw 'Local configuration exists. Review before replacing it.' }
}
foreach ($source in $copies.Keys) { Copy-Item -LiteralPath $source -Destination $copies[$source] }
```

Edit the policy's required application IDs and test name, and the manifest's installer URLs, SHA-256 hashes, product codes, installation-directory property and before/after versions using verified data. Placeholders deliberately fail preflight. These `*.local.json` files are ignored. Keep independent copies of the manifest and recovery information outside the target.

The example response profile is **spec-derived**, not capture-confirmed. Keep that provenance until the [bootstrap procedure](first-live-capture.md) establishes genuine success/failure/restoration mappings. The live gate rejects unconfirmed profiles; the capture exporter accepts a draft for investigation.

In a private shell without transcription, obtain connection values from your secret manager or use these prompts. Paths must already have appropriate access controls:

```powershell
$env:LE_BASE_URL = Read-Host 'Appliance HTTPS origin, without /publicApi'
$secureToken = Read-Host 'System Access Token' -AsSecureString
$env:LE_API_TOKEN = (New-Object System.Net.NetworkCredential('', $secureToken)).Password
$env:LE_API_VERSION = 'v8-preview'
$env:LE_SKIP_CERT_CHECK = 'false'
$env:LE_TARGET = Read-Host 'Reserved Windows target'
$env:LE_STATE_ROOT = Read-Host 'Shared durable state directory outside checkout'
$env:LE_PRIVATE_ROOT = Read-Host 'Private evidence directory outside checkout'
```

All runners/operators must use the same canonical target and durable state location. Use trusted TLS. PS5.1 rejects certificate skipping; the PS7 exception is appliance-request-only and is not the recommended setup. Never disable GitHub or installer TLS validation. Environment secrets are available to this process and its children; close the shell when finished.

API selection is explicit. Before changing versions, follow the [version assessment procedure](api-notes.md#version-comparison-and-upgrades), including code/profile review and fresh acceptance. A new version string alone does not provide compatibility.

## Run validation after bootstrap

Complete [first private capture and restoration](first-live-capture.md) first. Save a fresh change ID for recovery:

```powershell
$changeId = 'lab-' + [guid]::NewGuid().ToString('N')
$credential = Get-Credential
$gateArgs = @{
    ChangeId = $changeId
    PolicyFile = 'policies/demo.local.json'
    ChangeManifest = 'examples/changes/demo.local.json'
    ResponseProfile = 'config/response-profile.local.json'
    Adapter = 'app-update'
    Credential = $credential
}
& .\scripts\Invoke-Gate.ps1 @gateArgs
$validationExit = $LASTEXITCODE
```

Expect exit 0 for PASS, 1 for FAIL, or 2 for INCONCLUSIVE/orchestration failure. Inspect the new directory under `LE_PRIVATE_ROOT/<changeId>/`: `summary.md`, `verdict.json`, `normalized.json`, integrity manifest and private raw evidence. An unsuccessful command still requires inspection of durable target state. Validation does not approve or promote a change.

After confirming the application run completed, continuous scheduling is disabled and target sessions are drained, restore using the same inputs:

```powershell
& .\scripts\Invoke-Gate.ps1 @gateArgs -Revert
if ($LASTEXITCODE -ne 0) { throw 'Inspect restoration and reporting records before releasing the target.' }
```

Verify restoration independently. Interrupted work follows the [recovery runbook](runbook.md#recovery); do not delete its lease or invent a fresh ID to bypass recovery. For GitHub orchestration, publication and approval prerequisites, continue with the [runbook](runbook.md#github-actions) and [security settings](security.md).
