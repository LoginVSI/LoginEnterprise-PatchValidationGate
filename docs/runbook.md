# Runbook

## Offline checks

Run scripts/Invoke-OfflineScenario.ps1, tests/Invoke-Tests.ps1 and scripts/Invoke-Lint.ps1 in each available shell as shown in [setup](setup.md). FullFlow.Tests exercises real orchestration, collectors, normalization, evaluator, exporter, publication, approval parser and handoff while replacing external HTTP/remoting boundaries. Synthetic examples alone are narrower than these tests.

## Configure the disposable lab

1. Create/configure existing LE tests named patch-gate-app and patch-gate-continuous. Both must exercise Notepad and the selected demo application with a visible action. The gate does not create tests.
2. Stop continuous testing in the LE UI and wait for enabled/idle state. No stop endpoint is implemented.
3. Prepare a restorable target with the initial pinned MSI version in C:\LEGateDemo\<application>. Workloads must launch that exact executable. The adapter only supports its validated demo-app path and executable.
4. Copy policies/default.policy.json to policies/demo.local.json, examples/changes/app-update.json to examples/changes/demo.local.json, and the response profile example to config/response-profile.local.json. Configure real application IDs, both MSI versions, HTTPS URLs, SHA-256 checksums, product codes, MSI directory property and observed file versions. Verify these privately from the actual installers. Placeholders are rejected.
5. Capture genuine success/failure responses and configure the small profile from them. Do not change synthetic provenance merely to bypass preflight. See [API assumptions](api-assumptions.md).

Use trusted appliance TLS. Set LE_BASE_URL, LE_API_TOKEN, LE_TARGET, LE_STATE_ROOT and LE_PRIVATE_ROOT privately. LE_API_VERSION optionally overrides v8-preview; revalidate the documented endpoints before changing it. State/evidence directories must be access-controlled, outside checkout for workflows, and shared consistently by all callers. Supply PSCredential for remote execution or explicitly choose -UseCurrentCredentials. Add -Local only for deliberate execution on the target itself. Credentials are never manifest inputs.

## Capture an existing run

After configuring private environment variables:

```powershell
pwsh -NoProfile -File scripts/Export-LiveCapture.ps1 -TestRunId <actual-run-id> -OutputPath <new-private-directory> -ResponseProfile config/response-profile.local.json
```

Angle-bracket values are placeholders, not runnable values. Without ResponseProfile, collection preserves partial responses for profile review. It starts no tests and publishes nothing. Use a new output directory for each capture. Save version/spec and before/change/restore observations privately too.

## Validate and restore

In a PowerShell session:

```powershell
$credential = Get-Credential
.\scripts\Invoke-Gate.ps1 -ChangeId <fresh-id> -PolicyFile policies/demo.local.json -ChangeManifest examples/changes/demo.local.json -ResponseProfile config/response-profile.local.json -Adapter app-update -Credential $credential
```

Use -Adapter break for the deliberate failure demonstration. It renames only the selected demo executable after establishing the desired version. Verify means the intended broken state exists, so LE can observe failure. It does not break login or launcher components. Noop is available with examples/changes/noop.json.

The script exits 0 PASS, 1 FAIL, 2 INCONCLUSIVE or orchestration/reporting failure. Smoke exits remain separate: 0 successful smoke/completed successful run, 1 request/start error, 2 timeout, 3 completed non-success. Smoke success is not gate PASS. Add -ReportIssue with explicit GITHUB_TOKEN and GITHUB_REPOSITORY only when authorized to post. Add -PublicationPath pointing to a new directory to create a sanitized projection. Review it before sharing.

Resume with the same arguments and -Resume only. Exact configuration bytes, target, adapter, mode, test and change identity must match. Resume does not reapply. Fresh demonstrations require fresh IDs and restored state.

After the run is confirmed completed and continuous testing is stopped, repeat the original arguments with -Revert. The adapter restores the prior pinned version/executable and verifies it. Restoration gets a separate private record. An uncertain apply/start stage also requires -RecoveryConfirmed after an operator has checked LE and target state.

## Recovery

Timeout leaves durable ownership in place because LE may still be using the target. Wait or stop using supported LE UI controls, confirm completion/idle, then resume collection or explicitly revert. Never delete the lease to release a possibly active target. A process crash after PUT may leave no run ID; investigate in LE and perform explicit recovery rather than issuing another start.

Failed installer, reboot-required exit, failed restore, or ambiguous version requires operator recovery. Preserve the lease and private diagnostics. Installer timeout is bounded; it is not proof the system has returned to its prior state. Restore the lab snapshot if necessary and document/verify the result before a fresh change.

Policy/profile/manifest mismatch requires the original configuration for recovery. Do not edit state to reuse another change's success. A later continuous or issue failure preserves validation and writes a separate handoff error; investigate before retrying the handoff.

## GitHub Actions

Before dispatch, complete [security settings](security.md). Configure secrets LE_BASE_URL, LE_API_TOKEN, LE_TARGET, TARGET_USER, TARGET_PASSWORD, LE_POLICY_JSON, LE_CHANGE_JSON and LE_RESPONSE_PROFILE_JSON. Configuration JSON materializes at the default *.local.json paths. Dispatch paths must match those files. Variables LE_STATE_ROOT and LE_PRIVATE_ROOT point outside checkout. LE_SKIP_CERT_CHECK uses explicit true/false; the PowerShell 5.1 workflow requires trusted TLS.

Use the canonical demo-lab target alias. All jobs must reach the same durable state store; they do not rely on the same checkout. The workflow downloads and checks exact validation artifacts and keeps later promotion/continuous records separate. Only complete successful PASS validation enables either promotion job; the unselected job being skipped does not block continuous handoff.

Manual mode uses protected promotion-approval. GET review history supplies the actual reviewer. Its documented response lacks approval time, so promotion additionally requires an authoritative timestamp capture supplied privately through LE_APPROVAL_TIME_EVIDENCE. The operator must arrange this before continuing the protected job. Without it, the handoff intentionally fails.

Our time-evidence envelope has kind github-approval-time-evidence, repository, workflowRunId, environment, reviewer, approvedAt (UTC Z), and source (GitHub URL). These must refer to the same approval. This file is an operator trust boundary, not an API-generated proof. Preserve the underlying authoritative capture. Do not use environment created_at/updated_at, observation time, or GITHUB_ACTOR. If no authoritative timestamp is available, leave manual acceptance blocked.

Auto mode records policy as approver after both supported guardrails. Unknown guardrails block it. Promotion is simulated in both modes. The issue closes only after continuous handoff and required reporting succeed.

## Evidence explainer

Give an agent skills/evidence-explainer/SKILL.md and an evidence path, plus a trusted manifest hash if available. It reports the recorded verdict, cites exact fields, distinguishes handoff and synthetic provenance, and suggests investigation without claiming root cause. It cannot execute the pipeline. Worked examples and an adversarial text fixture are included. Structural checks do not establish model compliance.
