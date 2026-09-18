# First private capture and restoration

This supervised bootstrap creates the evidence needed to configure the response profile. It does not run Invoke-Gate, approve promotion, start continuous testing or publish artifacts. A completed capture is not live acceptance of the full gate.

## Reserve and prepare the target

1. Establish exclusive operational ownership with the lab owner. Reserve the target for the entire session, prevent other operators and scheduled workflows from using it, and confirm no gate job owns an unresolved lease. Standalone adapter calls below do not acquire the gate lock or create its recovery lease. A workflow concurrency group alone does not exclude manual callers. If exclusive ownership cannot be established, stop here.
2. In the LE UI, stop patch-gate-continuous and wait until it is enabled/idle. Confirm patch-gate-app is also idle with no active target sessions. Keep continuous testing stopped through final verification.
3. Record an independently recoverable VM snapshot or approved baseline, its identifier, the recovery owner and the restore procedure privately. Verify access to that recovery path before mutation. Record the installed executable path/version, working Notepad/demo-app actions and the target association of both LE tests. Do not use the adapter's prospective success as the recovery baseline.
4. Configure examples/changes/demo.local.json from verified installer data, including before/after file versions, HTTPS MSI URLs, hashes, product codes and the supported installation directory property. Confirm both installers respect the dedicated C:\LEGateDemo\<application> path. The break adapter may install the after version before renaming the executable; restoration may reinstall the before version. Preserve both packages independently of the target.
5. Set LE_BASE_URL, LE_API_TOKEN, LE_TARGET and LE_PRIVATE_ROOT privately using trusted TLS. Obtain the matching appliance version/OpenAPI export using the supported appliance UI and retain it privately. Make a new access-controlled session directory outside checkout. Never put secrets in the commands below or a transcript.

## Capture the working baseline

In the LE UI, run the existing patch-gate-app test with a fresh bootstrap baseline name. Observe the configured Notepad and demo-app actions. Wait for a completed successful run, record its actual run ID, and save private UI observations. If it fails, fix the baseline before proceeding to the deliberate break.

Run from the repository root in PowerShell. Prompts ask for real values; no invented run IDs are supplied:

```powershell
$ErrorActionPreference = 'Stop'
$sessionRoot = Join-Path $env:LE_PRIVATE_ROOT ('bootstrap-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($sessionRoot) | Out-Null
$baselineRun = Read-Host 'Completed successful baseline run ID from LE'
pwsh -NoProfile -File scripts/Export-LiveCapture.ps1 -TestRunId $baselineRun -OutputPath (Join-Path $sessionRoot 'baseline-discovery')
$baselineCaptureExit = $LASTEXITCODE
```

Without a response profile, exit 2 and partial private responses are expected. Inspect those responses, request/page traces, and the matching OpenAPI export against every row in [API assumptions](api-assumptions.md). Configure a separate private draft at config/response-profile.local.json using observed selectors, list envelopes, count/offset/termination semantics and session/execution/run relationships. Keep its provenance unconfirmed during discovery. The exporter accepts a draft profile; the gate requires capture-confirmed provenance. Never relabel tests/synthetic/response-profile.json or claim a synthetic fixture was live-confirmed.

```powershell
pwsh -NoProfile -File scripts/Export-LiveCapture.ps1 -TestRunId $baselineRun -OutputPath (Join-Path $sessionRoot 'baseline-mapped') -ResponseProfile config/response-profile.local.json
if ($LASTEXITCODE -ne 0) { throw 'Baseline capture incomplete. Review private evidence before any break.' }
```

If needed, revise the draft from observed evidence and recapture into another new directory. Completion must account for both required applications, all pages and relationships; exporter exit 0 alone does not verify the vendor semantics.

## Apply, capture and restore the deliberate failure

Keep one PowerShell session open. Use the real module adapter function so its structured status can be checked; adapter script exit 0 only means it produced a result document. Run this block only after the baseline and independent recovery prerequisites above are satisfied:

```powershell
Import-Module .\src\LEGate\LEGate.psd1 -Force
$credential = Get-Credential
$change = Get-Content examples/changes/demo.local.json -Raw | ConvertFrom-Json
$adapterArgs = @{
    Adapter = 'break'
    ChangeId = 'bootstrap-' + [guid]::NewGuid().ToString('N')
    Target = $env:LE_TARGET
    Parameters = $change
    Credential = $credential
}
try {
    foreach ($operation in @('apply', 'verify')) {
        $result = Invoke-LEGateChangeAdapter @adapterArgs -Operation $operation
        $result | ConvertTo-Json -Depth 20 | Set-Content (Join-Path $sessionRoot ($operation + '.json'))
        if ($result.status -notin @('succeeded', 'skipped')) { throw 'Adapter failed; recover before further testing.' }
    }
    # In LE: start patch-gate-app with a fresh failure name, observe the app-only
    # failure, wait for completion, and inspect the failed execution/screenshot.
    $failureRun = Read-Host 'Completed deliberate-failure run ID from LE'
    pwsh -NoProfile -File scripts/Export-LiveCapture.ps1 -TestRunId $failureRun -OutputPath (Join-Path $sessionRoot 'failure') -ResponseProfile config/response-profile.local.json
    if ($LASTEXITCODE -ne 0) { throw 'Failure capture incomplete; preserve partial output and restore now.' }
}
finally {
    # Stop/wait in the supported LE UI first if either test has active sessions.
    $idle = Read-Host 'Confirm both tests and target sessions are idle in LE; type IDLE'
    if ($idle -cne 'IDLE') { throw 'Restoration deferred: retain exclusive ownership and use the recovery owner.' }
    $restored = Invoke-LEGateChangeAdapter @adapterArgs -Operation revert
    $restored | ConvertTo-Json -Depth 20 | Set-Content (Join-Path $sessionRoot 'restoration.json')
    if ($restored.status -notin @('succeeded', 'skipped')) { throw 'Restoration failed: preserve diagnostics and use the independent recovery baseline.' }
}
```

A killed process, closed terminal or host failure can bypass finally. The recovery owner must then confirm LE is idle and invoke revert with the saved original manifest/target, or restore the independent baseline. Do not release exclusive ownership based on an interrupted script. Do not rerun apply to repair an uncertain target.

Inspect the failure export privately. Confirm the required demo app failed while login/launcher infrastructure remained healthy, and trace each failed execution to screenshot metadata and nonempty downloaded bytes. If mappings were incomplete, restore first, correct them from retained responses/spec, then recapture the same completed failure run into a new directory. Never edit success JSON to manufacture a failure.

## Independently verify and close the session

On the target, use Explorer file properties or Get-Item on the recorded executable to verify the original file version. Check that the executable is back, no .legate-disabled copy remains, and both applications launch and perform their visible actions. In LE, run patch-gate-app once more, confirm genuine completed success and export that run privately with a fresh output directory. Keep continuous testing stopped.

Record the before/change/restored observations, actual run IDs, capture paths, installer provenance and any snapshot recovery privately. After reviewing the success/failure/restore captures and matching spec, set the private profile's provenance to capture-confirmed and confirmedFrom to those actual evidence references. Resolve remaining API-assumption rows explicitly; absent infrastructure examples remain unverified. This attests to reviewed live mappings, not to full promotion acceptance.

Release ownership only after restoration and the final workload check succeed. The next stage is [live acceptance](live-acceptance.md); manual promotion remains blocked until authoritative approval-time acquisition and correlation are established.
